# Fresh-install testing

Agent-generated; human reviewed.
Verify `workspaceconfig` bootstraps cleanly on a "fresh Ubuntu" without reinstalling anything.
Goal: clone, source, bootstrap, checkhealth, all inside a disposable rootfs.
Run this before landing bootstrap-facing changes: new tools, `*-deps.yml` edits, `deps/scripts/setup/*`, README install instructions.
The same flow runs in CI as `.github/workflows/fresh-install.yml`, extended with the `update-docs.sh --check` readme gate as its last step.

## Why bwrap, not a VM

multipass = real Ubuntu but ~GBs + snap install; docker/podman absent.
`bwrap` was already there + unprivileged userns works → zero host installs.

The sandbox proves bootstrap logic, not system behavior: there is no display, no systemd, no real root, no non-root uids.
`-f` full-desktop installs and anything needing a session bus are out of scope; `-t` is the tested target.

## Rootfs + sandbox setup

Use the ubuntu-base tarball matching the repo's target release (currently 26.04):

```shell
mkdir -p /tmp/freshtest/rootfs && cd /tmp/freshtest
wget https://cdimage.ubuntu.com/ubuntu-base/releases/26.04.1/release/ubuntu-base-26.04.1-base-amd64.tar.gz
tar -xpf ubuntu-base-*-base-amd64.tar.gz -C rootfs
```

Two shims, each working around a "not a real system" gap:

```shell
# apt's _apt user can't seteuid inside a userns → run downloads as root
echo 'APT::Sandbox::User "root";' > rootfs/etc/apt/apt.conf.d/99bwrap-sandbox
# no sudo package in the base image; you're already fake-root → passthrough.
# Do NOT apt-install real sudo: on hosts enforcing
# apparmor_restrict_unprivileged_userns, container root has no
# CAP_DAC_OVERRIDE, and dpkg can't reopen the mode-000 .dpkg-new files
# it creates for the sudoers files (unpack dies EACCES).
# The shim covers bootstrap's `sudo apt install` calls.
printf '#!/bin/sh\nexec "$@"\n' > rootfs/usr/local/bin/sudo && chmod +x rootfs/usr/local/bin/sudo
```

Reusable launcher.
The repo is bind-mounted read-only so container clones always get host HEAD.
`--clearenv` keeps host vars from leaking (a leaked `CONFIGROOT` once made the whole test point at the host install):

```shell
# /tmp/freshtest/bwrap-run.sh
#!/bin/sh
bwrap --unshare-user --uid 0 --gid 0 \
  --bind /tmp/freshtest/rootfs / \
  --dev /dev --proc /proc --tmpfs /dev/shm \
  --dev-bind-try /dev/pts /dev/pts \
  --ro-bind /etc/resolv.conf /etc/resolv.conf \
  --ro-bind /etc/hosts /etc/hosts \
  --ro-bind "$HOME/workspaceconfig" /mnt/hostrepo \
  --clearenv --setenv HOME /root \
  --setenv PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  --setenv TERM xterm-256color --setenv LANG C.UTF-8 \
  --die-with-parent /bin/bash "$@"
```

## The test script: literally the documented user path

Place at `rootfs/mnt/inside-test.sh` so it is visible inside the sandbox:

```shell
#!/bin/bash
set -x
apt-get update -qq && apt-get install -y --no-install-recommends \
  git curl ca-certificates gcc python3 python3-venv python3-pip tar xz-utils make locales
# no ssh client/keys in the rootfs: rewrite git@ submodule URLs to https
git config --global url."https://github.com/".insteadOf "git@github.com:"
# fresh clone of HEAD, never your working tree (deps/ pollution hides bugs)
git clone file:///mnt/hostrepo wc && cd wc
source sourceme/sourceme.sh            # README order: bootstrap needs this env
./bootstrap.sh -t -y
./checkhealth.sh
```

```shell
nohup /tmp/freshtest/bwrap-run.sh /mnt/inside-test.sh > /tmp/freshtest/bootstrap.log 2>&1 &
tail -f /tmp/freshtest/bootstrap.log
```

Expect the full run to take a while: verilator and gtkwave compile from source.

## Sandbox limitations: expected noise, not repo bugs

Hosts with `kernel.apparmor_restrict_unprivileged_userns=1` (`/etc/apparmor.d/bwrap-userns-restrict`) let bwrap create the userns but stack every child under the `unpriv_bwrap` profile, which denies all capabilities.
Two fallout mechanisms:

- **Only uid/gid 0 is mapped.**
  `chown` to service users fails EINVAL.
  `dbus` postinst dies on `dpkg-statoverride` for `dbus-daemon-launch-helper` → packages depending on a system bus (libpam-systemd, dconf, gtk-common, …) stay "not fully installed".
  Files still unpack, so *build* deps work.
  Treat "N not fully installed" after a gtk dep install as noise.
- **No CAP_DAC_OVERRIDE.**
  Files created mode-000/0440 can't be reopened even by their owner → packages shipping restrictive modes (sudo) fail at *unpack*.
  Don't install them; shim instead.

Also benign: `posix_openpt EACCES` ("Can not write log") and `chown root:adm term.log failed` apt warnings.

## Reading the failures (each one was a real bug)

| Symptom in log | Root cause | Fix |
|---|---|---|
| "using `master` instead of pinned revision" | `git -C $CONFIGROOT ls-tree` resolves pathspec inside `config/`; `awk $2` is the string `commit` | `-C $CONFIGROOT/..`, `awk $3` |
| every submodule "skipped", then nothing built | `-y` never forwarded to `bash`-delegated scripts → prompt reads EOF → "n" | `bootstrap_script ... $(yes_flag)` |
| submodule fetch prompts + wayland apt deps in `-t` mode | `fetch-repos` ran `ensure_tool` incl. dep checks | fetch-only; deps stay per-tool in bootstrap |
| "installed." after `autoconf: error` | `popd` as last stmt masks rc | capture rc before popd |
| BOOTSTRAP_EXIT=0 despite errors | `set -uo pipefail` lacks `-e`; child `FAILED_TOOLS` dies with subprocess | parent records `\|\| FAILED_TOOLS+=(...)` → exit 1 |
| tar `Cannot change ownership` | fake-root chowns to archive uid | `tar --no-same-owner` |
| nvim wrapper 404: `deps/neovim/bin/nvim` missing | tarball left `nvim-linux-x86_64/` nested | flatten iff exactly 1 top dir |
| `git@` submodules fail, `https` ones work | no ssh client/keys in rootfs | `url."https://github.com/".insteadOf "git@github.com:"` |
| `unable to open '...dpkg-new': Permission denied` | no CAP_DAC_OVERRIDE under `unpriv_bwrap`; dpkg can't reopen mode-000 temp files | harness: don't install pkgs with restrictive file modes |
| `dpkg-statoverride: ... Invalid argument`, unconfigured cascade | chown to unmapped service uid/gid | expected noise; see "Sandbox limitations" |
| `qutebrowser --version` fails despite offscreen | `qutebrowser-deps.yml` lists build deps only; QtWebEngine runtime libs absent on minimal systems | repo gap, not harness |

## Verify mechanisms, not vibes: headless probes

```shell
# does :buffer work on a terminal window? would the picker's "main" pick it?
nvim --headless -u NONE -c "luafile probe.lua"
# nvr editor roundtrip: does --remote-wait unblock on :q?
nvim --listen /tmp/nv --headless & nvr --servername /tmp/nv -cc split \
  --remote-wait +'set bufhidden=wipe' /tmp/f & echo "waited rc=$?"
# qutebrowser without a display, as container root:
QT_QPA_PLATFORM=offscreen QTWEBENGINE_CHROMIUM_FLAGS=--no-sandbox \
  qutebrowser --version
```

## Idempotency: run bootstrap twice

Re-run `./bootstrap.sh -t -y` inside the container; every submodule, tarball, and tool must say `already present, skipping`.
Caught edalize reinstalling forever: `tool_check` looked for `bin/edalize` but it's a library → check `envs/main/bin/python -c 'import edalize'` instead.

## Adding tools = iterate the dep list

New builds surface one missing apt dep per attempt: run, read, add, repeat (gtkwave needed `gperf` → `gobject-introspection`+`libgirepository1.0-dev` → `desktop-file-utils`).
Pin sha256 of the file actually served, not the one a release page shows.
Qt smoke tests need `QT_QPA_PLATFORM=offscreen` headless.

## Finish: healthcheck as executable documentation

`checkhealth.sh` codifies "done": env vars set, submodules at pinned shas, binaries on PATH, real `--version` runs, nvim starts clean.
Green bar for `-t`: all `ok`, wayland tools `warn`, and at most the qutebrowser `--version` fail, which needs a display (or the offscreen env above + its runtime libs) by design.

## Harness vs product

All shims live in `/tmp/freshtest/`; every real fix goes into the repo or `deps/scripts` upstream.
Re-enter anytime: `bwrap-run.sh -c 'cd /root/wc && bash -l'`.

# bubblewrap (bwrap) tricks

Daemonless containers: run a foreign rootfs with nothing but `bwrap` + a
ubuntu-base tarball. Great for "fresh install" testing without a VM.

## Minimal fresh-Ubuntu sandbox

```shell
# get a rootfs (matches an official release point)
wget https://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/ubuntu-base-24.04.5-base-amd64.tar.gz
mkdir rootfs && tar -xpf ubuntu-base-*-base-amd64.tar.gz -C rootfs

bwrap \
  --unshare-user --uid 0 --gid 0 \
  --bind rootfs / \
  --dev /dev --proc /proc --tmpfs /dev/shm \
  --dev-bind-try /dev/pts /dev/pts \
  --ro-bind /etc/resolv.conf /etc/resolv.conf \
  --ro-bind ~/myrepo /mnt/hostrepo \
  --clearenv \
  --setenv HOME /root \
  --setenv PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  --die-with-parent \
  /bin/bash -l
```

- `--unshare-user` gives a fake uid 0 inside (mapped to your real uid outside).
- Network is shared unless you `--unshare-net` — binding the host
  `resolv.conf`/`hosts` makes apt/git work.
- `--clearenv` + `--setenv` prevents host env leaking in (a stray exported
  `CONFIGROOT` broke an entire test run once — sanitize).

## apt inside a userns: `_apt` sandbox fails

apt drops to the `_apt` user for downloads; seteuid fails in a single-uid
userns (`seteuid 42 failed`). Fix once in the rootfs:

```shell
echo 'APT::Sandbox::User "root";' > rootfs/etc/apt/apt.conf.d/99bwrap-sandbox
```

## tar as fake-root: `Cannot change ownership` errors

`tar -x` run as uid 0 (even fake) tries to chown files to the archive's
recorded uid → `Cannot change ownership to uid 1001` → nonzero exit.
Same thing bites real root on a foreign system. Fix at the source:

```shell
tar --no-same-owner -xf archive.tar.gz -C dest/
```

## sudo doesn't exist in a minimal rootfs

You're already "root" — shim it:

```shell
printf '#!/bin/sh\nexec "$@"\n' > rootfs/usr/local/bin/sudo
chmod +x rootfs/usr/local/bin/sudo
```

## Caveats

- ssh-agent/keys aren't inside → `git@` submodule URLs fail. Test with
  `git config --global url."https://github.com/".insteadOf "git@github.com:"`
  for public repos.
- Processes share the host pid ns — `pgrep` sees them.

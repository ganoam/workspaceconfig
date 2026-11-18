# Git submodule workflows

## Adding submodules

Adding submodules (optionally with a branch specified

```shell
git submodule add -b dev git@github.com:Koalemo/dwl.git deps/dwl
git -C deps/dwl checkout 67249b41dbe2fdfa7d1a6c106fcd98a4ab6fc476
```
## Removing submodules


```shell
 Unregister and empty the submodule working tree
git submodule deinit -f uvm-verilator

# Remove the gitlink and .gitmodules entry (both get staged)
git rm -f uvm-verilator

# Remove the leftover clone data inside .git
rm -rf .git/modules/uvm-verilator
   ```


## Spase git checkout

Done for opentitan dependency.

https://stackoverflow.com/questions/45688121/how-to-do-submodule-sparse-checkout-with-git

```shell
# Initialize main repo (if needed)
git init

# Checkout the to-be submodule
# I did not find a way to add submodule in 1 step without checking out
git clone --depth=1 --no-checkout git@example.com:username/some-repo.git path/some-repo

# Add as a submodule
git submodule add git@example.com:username/some-repo.git path/some-repo

# Move the .git dir from path/some-repo/.git into parent repo's .git
git submodule absorbgitdirs

# Note there is no "submodule.sub.sparsecheckout" key
git -C path/some-repo config core.sparseCheckout true

# This pattern determines which files within some-repo.git get checked out.
# Note quoted wildcards to avoid their expansion by shell
echo 'foo/*'  >> .git/modules/path/some-repo/info/sparse-checkout

# Actually do the checkout
git submodule update --force --checkout sub
```


## Switching branches
To switch the branch an existing submodule tracks, update its branch setting in .gitmodules and re-checkout:

```shell
git config -f .gitmodules submodule.deps/dwl.branch <new-branch>
git submodule sync -- deps/dwl
cd deps/dwl
git fetch origin
git checkout <new-branch>
cd -
git add .gitmodules deps/dwl
git commit -m "Switch dwl submodule to <new-branch>"
```
## How to update a submodule


```shell
cd deps/<submodule>
git fetch origin
git checkout <new-commit-or-branch-tip>
cd -
git add deps/<submodule>   # stages the new gitlink (commit pointer)
git commit -m "Bump <submodule> to <new-commit>"
```

## How to update all submodules

```shell
git submodule update --remote --[merge|rebase]
git add -- $(git config --file .gitmodules --get-regexp path | awk '{print $2}')
git commit -m "Bump submodules to latest upstream"
```
## How to change the url of a submodule

```shell
git config -f .gitmodules submodule.<path>.url <new-url>
git submodule sync -- <path>
git -C <path> fetch origin
```

## Pull latest changes for all git submodules

```shell
git submodule update --recursive --remote
```


## `git config --file .gitmodules`

| Action | Command |
|---|---|
| **List all entries** | `git config --file .gitmodules --list` or `--get-regexp .` |
| **Get one value** | `git config --file .gitmodules submodule.<name>.<key>` |
| **Set/update a value** | `git config --file .gitmodules submodule.<name>.<key> <value>` |
| **Unset a value** | `git config --file .gitmodules --unset submodule.<name>.<key>` |
| **Remove a whole section** | `git config --file .gitmodules --remove-section submodule.<name>` |
| **Query by regex across all entries** | `git config --file .gitmodules --get-regexp <pattern>` |

### Common keys per `submodule.<name>` section

- `url` — remote URL
- `path` — checkout location relative to repo root
- `branch` — tracked branch, used by `git submodule update --remote`
- `update` — update mode (`checkout`, `rebase`, `merge`, `none`)
- `ignore` — what `git status`/`git diff` ignore for that submodule (`all`, `dirty`, `untracked`, `none`)
- `shallow` — whether to do shallow clones

### Important caveat

Editing `.gitmodules` only changes the **declared intent** - it does not by itself update the actual checked-out submodule or the local `.git/config` copy. After any edit, you generally need:

```shell
git submodule sync   # propagate .gitmodules changes into .git/config
git add .gitmodules
git commit
```

This mirrors exactly what you did earlier for the branch-switch case: edit `.gitmodules`'s `branch` field, run `git submodule sync`, then checkout and commit.

## Add subdirectories from another repo into this repo, with history, but as part of the new repo not a submodule


Step 1: Install git-filter-repo

```shell
pip install git-filter-repo
````
Step 2: Clone OpenTitan to a temporary location

```shell
cd /tmp
git clone https://github.com/lowRISC/opentitan.git opentitan-temp
cd opentitan-temp
```

Step 3: Extract the directories you want

Based on what I see, you likely want  util/uvmdvgen  and possibly  hw/dv . Here's how to extract them:

> IMPORTANT: filter-repo is destructive.
> everything except the specified paths will be lost.
> Do it only in a separate clone

```shell
# Extract util/uvmdvgen with full history
git filter-repo --path util/uvmdvgen --path util/uvmdvgen.py
```

Step 4: Merge into your repo

```shell
cd /home/ng/code/dv

# Add the filtered repo as a remote
git remote add opentitan-filtered /tmp/opentitan-temp
git fetch opentitan-filtered

# Merge it into your repo
git merge opentitan-filtered/main --allow-unrelated-histories

# Potentially rebase to get rid of the merge commit, if applicable
git rebase origin/master

# Move to desired location if needed
mkdir -p third_party/opentitan
git mv util third_party/opentitan/
git mv hw third_party/opentitan/

# Commit the reorganization
git commit -m "Reorganize OpenTitan imports into third_party/"
```
Step 5: Clean up

```shell
git remote remove opentitan-filtered
rm -rf /tmp/opentitan-temp
```

## Find first commit by author and move all own commits to top of history

```shell
# All own commits, oldest first
git log --author='ganoam' --oneline --reverse

# SHA of first own commit
FIRST=$(git rev-list --reverse --author='ganoam' HEAD | head -1)

# Reorder: rebase starting before first own commit
git branch backup-before-reorder          # safety net
git rebase -i ${FIRST}^
```

Pitfall: if the first own commit is the *root* commit (e.g. upstream
history was merged in later via `--allow-unrelated-histories`), `${FIRST}^`
does not exist -> `fatal: invalid upstream`. Rebase the whole history
instead:

```shell
git rebase -i --root
```

Note: `--root` linearizes history -- merge commits (incl. the
unrelated-histories merge) are flattened. Use `--rebase-merges` to keep them.

### Auto-move own commits to the bottom of the todo list

`GIT_SEQUENCE_EDITOR` runs on the todo file before/instead of an editor.
This script moves all `pick` lines authored by you to the end (commits
apply top-to-bottom -> yours end up newest):

```shell
cat > /tmp/mine-last.sh <<'EOF'
#!/bin/bash
awk '
  /^pick/ {
    cmd = "git log -1 --format=%ae " $2
    cmd | getline a; close(cmd)
    if (a == "ganoam.github@gmail.com") { mine = mine $0 ORS; next }
  }
  { print }
  END { printf "%s", mine }
' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
EOF
chmod +x /tmp/mine-last.sh

GIT_SEQUENCE_EDITOR=/tmp/mine-last.sh git rebase -i --root
```

Variant -- annotate instead of auto-move (appends `# <author>` to each
`pick` line, then opens your normal editor; trailing `#` text is ignored):

```shell
cat > /tmp/annotate-todo.sh <<'EOF'
#!/bin/bash
awk '
  /^pick/ {
    cmd = "git log -1 --format=%an " $2
    cmd | getline a; close(cmd)
    $0 = $0 "    # " a
  }
  { print }
' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
exec "${EDITOR:-vi}" "$1"
EOF
chmod +x /tmp/annotate-todo.sh

GIT_SEQUENCE_EDITOR=/tmp/annotate-todo.sh git rebase -i --root
```

### "Waiting for your editor to close the file..." hangs

The script exits instantly; that hint line stays on screen while git
silently *replays* commits -- a full-history `--root` rebase takes a long
time. Check progress from another terminal:

```shell
ps aux | grep -E "git (rebase|cherry-pick|am)" | grep -v grep
wc -l .git/rebase-merge/done .git/rebase-merge/git-rebase-todo
tail -3 .git/rebase-merge/done      # last entry = where it currently is
```

If `.git/rebase-merge/done` keeps growing: just wait. If it stopped, the
last line is where it stalled (probably a conflict). If `ps` shows a real
editor (`vi`, `nano`, ...) the script errored and git fell back to the
default editor -- `Ctrl-C`, `git rebase --abort`, debug the script
standalone first.

Other caveats:
- Conflicts likely where upstream commits touched same files.
  `git rebase --continue` / `--abort` (restores backup state).
- Every SHA after the rebase start point is rewritten -> force-push if published.
- Own commits depending on later upstream content may not reorder
  cleanly; then rebase upstream first and cherry-pick own commits on top.

Verify afterwards:

```shell
git log --format='%an %s' | uniq -c   # own commits = contiguous block on top
```

Note: reordering is cosmetic -- future merges from the upstream remote
re-interleave history. `git log --author=<me>` / `git shortlog` already
give a "my work" view without rewriting anything.

## Rename a branch

```shell
git branch -m local private
```

## Push a branch as 'master' to a named remote (set upstream)

```shell
git push -u private private:master
```

## Delete a branch on a remote

```shell
git push private --delete local
```

Fails if it is the remote's default branch ("refusing to delete the
current branch") -- change the default on GitHub (Settings -> Branches)
or leave the branch.

## Point a repo's hooks at a directory (shared, auto-updating hooks)

```shell
git config core.hooksPath <dir>
```

Relative paths resolve against the worktree top-level. Missing dir ->
silently NO hooks run (check the dir exists when setting).

## Vendor only a subdirectory of another repo (git subtree)

`git subtree add --prefix=X <repo> <ref>` vendors the WHOLE repo, not
the subdir. Split the subdir out upstream first:

```shell
cd <source-repo>
git subtree split --prefix=<subdir> -b split-<name>
cd <target-repo>
git subtree add --prefix=<subdir> <source-repo> split-<name> --squash
```

## Update a vendored subtree

Split is a snapshot: it does not track upstream. Re-split, then pull:

```shell
cd <source-repo>
git subtree split --prefix=<subdir> -b split-<name>   # regenerate
cd <target-repo>
git subtree pull --prefix=<subdir> <source-repo> split-<name> --squash
```

Local edits can go back upstream: `git subtree push --prefix=<subdir>
<repo> <branch>`.

## Bump a submodule to its tracked branch tip

```shell
git submodule update --remote <path>
git add <path> && git commit
```

Requires `submodule.<path>.branch` set in `.gitmodules`.

## Caution: subtree vs. submodule when you need upstream tracking

Subtree copies are static snapshots. They never track upstream; every
update means re-split + `subtree pull`, and each pull adds squash/merge
noise to your history. For content that must stay current, prefer a
submodule instead: the parent repo tracks only the gitlink, so even a
full checkout confines the noise to the subdir. Sparse checkout inside
a submodule is cosmetic only and not committed (per-clone state in
`.git/modules/<name>/info/sparse-checkout`).

## Worktrees: second checkout of the same repo

```shell
git worktree add /tmp/wt master      # checkout branch at a new path
git worktree list                    # show registered worktrees
git worktree remove --force /tmp/wt  # delete worktree + registry entry
git worktree prune                   # drop registry entries whose dir is gone
```

One branch, one worktree: a branch cannot be checked out twice.
`rm -rf` on a worktree dir leaves a stale registry entry in
`.git/worktrees/` -> "already used by worktree at <gone path>" on the
next `worktree add`. Fix: `git worktree prune` (registry, not the
filesystem, is what the branch-pin check consults).

## Navigate a merge commit's parents

M has two parents. ^ picks one, ~ walks first-parent steps:

```shell
git log --oneline M^1    # = M^, my tip at merge time
git log --oneline M^^    # = M^1^1, one before that on my side
git log --oneline M^2    # merged-in tip
git log --oneline M^2^   # one down the merged-in line (also: M^2~2 etc)
git merge-base M^1 M^2   # where the two lines diverged
```

## Read history around merges

```shell
git log --graph --oneline
```

The one command that makes merge topology legible.

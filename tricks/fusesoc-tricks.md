# FuseSoC tricks

## Virtual cores (provider pattern)

A core can *depend on a name no real core has*. The virtual VLNV is a
slot/contract; any core that fills it declares `virtual:` with the same
string.

Consumer side -- depends on the virtual name:

```yaml
# bus_params_pkg.core
filesets:
  files_dv:
    depend:
      - lowrisc:virtual_constants:top_pkg   # the slot, not a real core
```

Provider side -- has a concrete `name:`, lists the virtual name under
`virtual:`:

```yaml
# top_pkg.core
name: "lowrisc:earlgrey_constants:top_pkg"   # concrete identity
virtual:
  - lowrisc:virtual_constants:top_pkg        # the slot it fills
```

The `virtual:` entry must be the *virtual* name (what consumers write
in `depend:`), NOT another concrete name. Both sides must match
string-exactly or the dep is unresolvable ("depends on missing
packages" / "was ignored because it depends on missing packages" --
watch for `... was ignored` lines in the resolver dump, they point at
the core with the unsatisfiable child).

### Which provider wins?

- **One provider in cores-root** -> selected automatically.
- **Several providers visible** -> the solver picks one
  deterministically; the consumer cannot influence it.
- **Pin a provider** -> a higher-level core depends on the *concrete*
  VLNV directly; once in the dep set it satisfies the virtual
  requirement too. E.g. upstream `lowrisc:systems:top_earlgrey` deps on
  `lowrisc:earlgrey_constants:top_pkg` by name.

Mental model: virtual name = interface, provider = config. The IP
declares the interface; whoever owns the build supplies the config.
Unit-level DV typically ships a stub provider (dummy top_pkg) as the
only candidate so IP sims are top-agnostic.

## Resolver errors read bottom-up

`Conflicting requirements` dumps list the failing chain. The LAST
requirement in a chain is the actual missing/unresolvable VLNV;
intermediate `X was ignored because it depends on missing packages`
marks cores that exist but have a broken child.

## gen_flist vs fusesoc cores-root scope

`fusesoc` also reads `~/.config/fusesoc/fusesoc.conf` library paths
(e.g. a whole `~/code` root, so sibling repos' cores are visible).
`gen_flist.py` only scans `--cores-root` (default `.`). Different
resolution results between the two usually mean a provider lives in a
sibling repo -- pass it explicitly:

```shell
gen_flist.py --cores-root . --cores-root ~/code/opentitan ...
```

(Trade-off: emitted filelist then points into the external tree.)

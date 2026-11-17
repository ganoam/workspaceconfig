# LazyVerilog tricks

## Project discovery: lazyverilog.toml is the root marker

The *server* resolves the project, not the editor. On every `didOpen` it
walks up from the file's directory to the nearest `lazyverilog.toml`.
No toml above the file -> no project -> `Config{}` defaults: no filelist,
no incdirs, lint/compilation off. `` `include "uvm_macros.svh" `` /
`` `include "dv_macros.svh" `` then resolve nowhere and the buffer looks
half-dead (no diagnostics either, not even errors about it).

This was the tb.sv failure: hw-commons had `vcode.f` but no
`lazyverilog.toml` pointing at it. A `.f` on disk is invisible until a
toml names it.

Do NOT set `root_dir`/`root_markers` editor-side. The plugin sends none
(`vim.lsp.start` with nil root); `root_markers` in `setup()` is ignored
with a warning. One client serves all SV buffers across projects.

## Minimal setup

`lazyverilog.toml` at the repo root (anywhere above the RTL):

```toml
[design]
vcode = "vcode.f"          # filelist path, relative to this toml
define = ["UVM"]           # preprocessor defines for all design files

[lint]
enable = true

[format]
enable_format_on_save = true
```

The `.f` filelist — paths relative to the filelist itself:

```text
hw/ip/stream_reg/rtl/stream_reg.sv
hw/ip/stream_reg/dv/tb.sv
-f deps/other_list.f                     # nested filelist
+incdir+hw/dv/sv/dv_utils                # where dv_macros.svh lives
+incdir+${UVM_HOME}/src                  # env vars expand
${UVM_HOME}/src/uvm_pkg.sv               # list the pkg, not every .svh
```

- `+incdir+<a>+<b>` adds several dirs; `//`/`#` comments; other
  `+flag`/`-flag` lines are ignored.
- `include` resolution searches the `+incdir+` paths only. Listing the
  header file itself in the `.f` is not what makes it includable.
- UVM/dv pattern: `uvm_pkg.sv` in the filelist + its `src/` on an incdir;
  dv_macros likewise just needs its dir on an incdir (the tb `include`s it).
- `${VAR}` unset -> left as written (silent miss). The editor must be
  started with the env set.

## Generating vcode.f with gen_flist.py

`vcode.f` is produced from FuseSoC core metadata, not hand-maintained:

```shell
~/workspaceconfig/deps/scripts/bin/gen_flist.py --target=sim toplevels.list > vcode.f
```

- `toplevels.list` — one top-level core VLNV per line
  (e.g. `ganoam:dv:stream_reg_sim:0.1`). The script emits the union of
  all files across those cores' dependency trees: source paths plus the
  `+incdir+` lines UVM/dv headers resolve through (absolute paths).
- `--cores-root` defaults to `.` — repeat it for cores in sibling repos
  (`--cores-root . --cores-root ~/code/opentitan`). `gen_flist.py` does
  not read `~/.config/fusesoc/fusesoc.conf` library paths.
- Rerun when the core deps change; then confirm `lazyverilog.toml` still
  names it via `[design] vcode = "vcode.f"`.

## What the toml gates (per file, via nearest config)

| Section | Effect |
|---|---|
| `[design]` | filelist + defines -> cross-file index (gd, refs, AutoInst, completion) |
| `[lint] enable` | off -> no lint diagnostics, `:Lint`/`:LintAll` quiet |
| `[compilation] background_compilation` | default **false**; on -> semantic (elaboration) diagnostics, one slang Compilation per filelist |
| `[format] enable_format_on_save` | gates the plugin's BufWritePre `lsp.buf.format` |
| `[inlay_hint]` / `[folding] enable` | server-side switches for the per-keystroke requests |

Saving `lazyverilog.toml` inside nvim -> `BufWritePost` notifies the
server (`didChangeConfiguration` naming the file). External edits are
picked up by the server's own freshness window — no watcher needed.

## Gotchas

- File under no toml = no diagnostics at all. "Silent server" usually
  means missing toml, not a crash — check `:LspInfo` for the
  `lazyverilog` client, then look above the file for the config.
- Wrong filetype = no LSP attach, looks identical to a dead server.
  Plugin maps `.sv/.svh/.v/.vh`; verify `&ft` is `systemverilog`/`verilog`.
- Folding + inlay hints each cost one whole-file request per `didChange`.
  On big files / shared HPC nodes: `[folding] enable = false` or
  `setup({ folding = false })` (and `inlay_hints = false`) plugin-side.
- Binary resolution order: `cmd` opt -> `lazyverilog-lsp` on `$PATH` ->
  managed `stdpath("data")/lazyverilog/bin/` (auto-download, sha256
  checked; `linux-*-static` fallback if `ldd` reports missing libs).
- nvim-lint's `fusesoc_verilator` also runs on `BufWritePost` for SV
  filetypes — two independent diagnostic sources can report on save.

# snacks.nvim tricks

## Picker opens files in the wrong window (terminal buffers)

`Snacks.picker` resolves a "main" window for the jump target via
`picker.opts.main` → `snacks/picker/core/main.lua`. Default:
`{ float=false, file=true, current=false }`.

`file=true` filters out windows whose buffer has `buftype ~= ""` — so
invoking the picker from a `:terminal` split silently jumps to the
most-recently-used *file* window. Fix:

```lua
picker = {
  enabled = true,
  main = { file = false },   -- current window may be a non-file buffer
},
```

(`main = { current = true }` takes the window unconditionally — even
floats. `file=false` keeps floats excluded.)

## Filter a picker to terminal buffers only

Buffer items expose `item.buftype`; every picker accepts a generic filter:

```lua
Snacks.picker.buffers({
  title = "Terminal Buffers",
  hidden = true,  -- include unlisted bufs (snacks/floaterm hide theirs)
  filter = { filter = function(item) return item.buftype == "terminal" end },
})
```

`filter.filter(item, filter):boolean` — applied via
`ctx.filter:filter(items)` inside finders (`core/filter.lua`).

## Reloading / live-patching

Picker opts are read fresh at picker creation — patch the live config
without a full reload:

```vim
:lua Snacks.config.picker.main = { file = false }
```

Proper reload: `:Lazy reload snacks.nvim`.

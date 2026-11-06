return {
  "mfussenegger/nvim-lint",
  config = function()

    local sarif_parser = require('lint.parser').for_sarif({ source = 'verilator' })
    local parser = require('lint.parser')

    -- Fallback: parse raw verilator output, e.g.
    --   %Error: rtl/foo.sv:12:9: syntax error, unexpected ...
    --   %Warning-WIDTH: rtl/foo.sv:20:5: Operator ADD expects ...
    local function verilator_parser(output, bufnr, cwd)
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return {}
      end
      local buffer_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':p')

      -- verilator's relative paths are relative to the build dir, not cwd
      local build_dir = output:match("Entering directory '(.-)'") or cwd

      local sev_map = {
        Error   = vim.diagnostic.severity.ERROR,
        Warning = vim.diagnostic.severity.WARN,
        Info    = vim.diagnostic.severity.INFO,
      }

      local diagnostics = {}
      for line in vim.gsplit(output, '\n', true) do
        -- %Error: file:lnum:col: msg   /   %Warning-CODE: file:lnum:col: msg
        -- (leading "ERROR: " prefixes from fusesoc are fine, match isn't anchored)
        local sev, code, file, lnum, col, msg =
        line:match('%%(%a+)%-?(%w*):%s*([^:]+):(%d+):(%d+):%s*(.+)')

        if sev and file then
          -- fnamemodify ':p' resolves ../ segments against build_dir
          local path = vim.fn.fnamemodify(build_dir .. '/' .. file, ':p')
          if vim.fs.normalize(path) == vim.fs.normalize(buffer_path) then
            table.insert(diagnostics, {
              lnum = math.max(tonumber(lnum) - 1, 0),
              col  = math.max(tonumber(col) - 1, 0),
              severity = sev_map[sev] or vim.diagnostic.severity.ERROR,
              message = msg,
              code = code ~= '' and code or nil,
              source = 'verilator',
            })
          end
        else
          -- position-less lines, e.g. "%Error: Verilator internal fault, ..."
          local sev2, msg2 = line:match('%%(%a+)%-?%w*:%s*(.+)')
          if sev2 and not msg2:match('^%S+:%d+:%d+:') then
            table.insert(diagnostics, {
              lnum = 0, col = 0,
              severity = sev_map[sev2] or vim.diagnostic.severity.ERROR,
              message = msg2,
              source = 'verilator',
            })
          end
        end
      end
      return diagnostics
    end

    -- the lint Makefile runs `verilator --lint-only`: everything is on
    -- stdout, no .sarif is written. keep the raw output of the last run.
    local last_output
    -- content + dir of a .sarif if a run ever produces one
    local last_sarif_content
    local last_sarif_dir

    -- collect results for every file in the sarif, not just the linted
    -- buffer (nvim-lint's for_sarif parser filters to bufnr)
    local function sarif_to_qf_items(content, dir, want)
      local ok, data = pcall(vim.json.decode, content)
      if not ok or type(data) ~= 'table' then return {} end
      local items = {}
      for _, run in ipairs(data.runs or {}) do
        for _, res in ipairs(run.results or {}) do
          local loc = res.locations and res.locations[1]
            and res.locations[1].physicalLocation
          if loc and want[res.level] then
            local uri = loc.artifactLocation and loc.artifactLocation.uri or ''
            local fname = uri:gsub('^file://', '')
            if not vim.startswith(fname, '/') then
              fname = vim.fn.fnamemodify(dir .. '/' .. fname, ':p')
            end
            local region = loc.region or {}
            table.insert(items, {
              filename = fname,
              lnum = region.startLine or 1,
              col = region.startColumn or 1,
              text = (res.message and res.message.text) or '',
              type = res.level == 'error' and 'E' or 'W',
            })
          end
        end
      end
      return items
    end

    -- same %Error/%Warning-CODE scan as verilator_parser, but keeps every
    -- file in the run instead of filtering to the linted buffer
    local function output_to_qf_items(output, cwd, want)
      local build_dir = output:match("Entering directory '(.-)'") or cwd
      local items = {}
      for line in vim.gsplit(output, '\n', true) do
        local sev, code, file, lnum, col, msg =
          line:match('%%(%a+)%-?(%w*):%s*([^:]+):(%d+):(%d+):%s*(.+)')
        if sev and file and want[sev:lower()] then
          local fname = file:sub(1, 1) == '/' and file
            or vim.fn.fnamemodify(build_dir .. '/' .. file, ':p')
          table.insert(items, {
            filename = fname,
            lnum = tonumber(lnum),
            col = tonumber(col),
            text = (code ~= '' and code .. ' ' or '') .. msg,
            type = sev == 'Error' and 'E' or 'W',
          })
        end
      end
      return items
    end

    local function lint_to_qf(want, label)
      local items = {}
      if last_sarif_content then
        items = sarif_to_qf_items(last_sarif_content, last_sarif_dir, want)
      elseif last_output then
        items = output_to_qf_items(last_output, vim.fn.getcwd(), want)
      end
      vim.fn.setqflist({}, ' ', {
        title = 'fusesoc_verilator: ' .. label,
        items = items,
      })
      vim.cmd('botright copen')
    end

    vim.keymap.set('n', '<leader>le',
      function() lint_to_qf({ error = true }, 'errors') end,
      { desc = 'fusesoc lint: load errors into quickfix' })
    vim.keymap.set('n', '<leader>lw',
      function() lint_to_qf({ warning = true }, 'warnings') end,
      { desc = 'fusesoc lint: load warnings into quickfix' })

    require('lint').linters.fusesoc_verilator = {
      name = 'fusesoc_linter',
      cmd = 'fusesoc',
      args = { 'run',  '--no-export',  '--target=lint', '--setup', '--build',
        function()
          return  vim.g.fusesoc_target
        end,}, -- or whatever build/lint target
      stdin = false,
      append_fname = false,
      stream = 'both',
      ignore_exitcode = true, -- fusesoc/verilator likely exit non-zero on lint errors

      parser = function(output, bufnr, cwd)
        vim.notify("fusesoc_verilator: done") -- print output to notification

        last_output = output
        local dir = output:match("Entering directory '(.-)'")
        last_sarif_content = nil

        if dir then
          local sarif_path = vim.fn.glob(dir .. '/*.sarif')
          if vim.fn.filereadable(sarif_path) == 1 then
            last_sarif_dir = vim.fn.fnamemodify(sarif_path, ':h')
            last_sarif_content = table.concat(vim.fn.readfile(sarif_path), '\n')
            return sarif_parser(last_sarif_content, bufnr, cwd)
          end
        end
        -- fallback: no sarif -> parse verilator's own output
        return verilator_parser(output, bufnr, cwd)

      end,
    }

    require('lint').linters_by_ft.verilog = { 'fusesoc_verilator' }
    require('lint').linters_by_ft.systemverilog = { 'fusesoc_verilator' }

    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      callback = function()

        -- try_lint without arguments runs the linters defined in `linters_by_ft`
        -- for the current filetype
        require("lint").try_lint()
      end,
    })
  end

}


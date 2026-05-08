require "nvchad.autocmds"

pcall(vim.api.nvim_del_user_command, "TSInstallAll")
vim.api.nvim_create_user_command("TSInstallAll", function()
  local spec = require("lazy.core.config").plugins["nvim-treesitter"]
  local opts = type(spec.opts) == "table" and spec.opts or {}
  local languages = opts.ensure_installed or {}
  local ts = require "nvim-treesitter"
  local installed = {}
  for _, lang in ipairs(ts.get_installed()) do
    installed[lang] = true
  end

  local missing = vim.tbl_filter(function(lang)
    return not installed[lang]
  end, languages)

  if #missing == 0 then
    vim.notify(
      "All configured treesitter parsers are already installed. Use :TSUpdate to refresh them.",
      vim.log.levels.INFO
    )
    return
  end

  if type(ts.install) == "function" then
    vim.notify("Installing missing treesitter parsers: " .. table.concat(missing, ", "), vim.log.levels.INFO)
    local result = ts.install(missing)
    if result and type(result.wait) == "function" then
      result:wait(300000)
    end
    vim.notify("TSInstallAll completed", vim.log.levels.INFO)
    return
  end

  local plugin_dir = (spec.dir or ""):gsub("\\", "/")
  local payload = vim.json.encode(missing)
  local script = string.format(
    "local langs = vim.json.decode(%q); require('nvim-treesitter.configs').setup{}; require('nvim-treesitter.install').ensure_installed_sync(langs)",
    payload
  )
  vim.notify("Installing missing treesitter parsers: " .. table.concat(missing, ", "), vim.log.levels.INFO)
  local result = vim.system({
    vim.v.progpath,
    "--headless",
    "-u",
    "NONE",
    "--cmd",
    "set rtp+=" .. plugin_dir,
    "+lua " .. script,
    "+qa",
  }, { text = true }):wait()

  local output = table.concat(vim.tbl_filter(function(value)
    return type(value) == "string" and value ~= ""
  end, { result.stdout, result.stderr }), "\n")

  if output ~= "" then
    vim.notify(output, result.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
  end

  if result.code == 0 then
    vim.notify("TSInstallAll completed", vim.log.levels.INFO)
  else
    vim.notify("TSInstallAll failed in compatibility mode", vim.log.levels.ERROR)
  end
end, {})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("UserMarkdownOptions", { clear = true }),
  pattern = "markdown",
  callback = function(args)
    local bufnr = args.buf
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.spell = true

    if vim.bo[bufnr].buftype == "nofile" then
      -- LSP hover/signature previews use markdown in scratch buffers.
      -- Avoid the treesitter conceal path there because it is the only
      -- remaining buffer type that has been triggering the markdown crash.
      vim.opt_local.conceallevel = 0
      vim.opt_local.concealcursor = ""
      pcall(vim.treesitter.stop, bufnr)
      return
    end

    vim.opt_local.conceallevel = 2
    vim.opt_local.concealcursor = "nc"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("UserRazorHighlighting", { clear = true }),
  pattern = { "razor", "cshtml" },
  callback = function(args)
    local ok = pcall(vim.treesitter.start, args.buf, "razor")

    if not ok then
      vim.bo[args.buf].syntax = "html"
      pcall(vim.treesitter.start, args.buf, "html")
    end
  end,
})

vim.api.nvim_create_autocmd({ "BufAdd", "BufEnter", "BufWinEnter" }, {
  group = vim.api.nvim_create_augroup("UserRoslynVirtualHtml", { clear = true }),
  pattern = "*__virtual.html",
  callback = function(args)
    if vim.bo[args.buf].filetype == "html" then
      return
    end

    vim.bo[args.buf].filetype = "html"
    pcall(vim.api.nvim_exec_autocmds, "FileType", {
      buffer = args.buf,
      modeline = false,
    })
  end,
})

do
  local ok, stl_utils = pcall(require, "nvchad.stl.utils")

  if ok then
    stl_utils.lsp = function()
      if not rawget(vim, "lsp") then
        return ""
      end

      local bufnr = stl_utils.stbufnr()
      local names = {}
      local seen = {}

      for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
        if not seen[client.name] then
          seen[client.name] = true
          table.insert(names, client.name)
        end
      end

      if #names == 0 then
        return ""
      end

      table.sort(names)

      return (vim.o.columns > 100 and "   LSP ~ " .. table.concat(names, ",") .. " ") or "   LSP "
    end
  end
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "LspAttach", "LspDetach" }, {
  group = vim.api.nvim_create_augroup("UserStatuslineLspRefresh", { clear = true }),
  callback = function()
    vim.cmd.redrawstatus()
  end,
})

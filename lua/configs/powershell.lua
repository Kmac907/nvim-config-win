local nvchad_lsp = require "nvchad.configs.lspconfig"
local paths = require "configs.paths"
local util = require "lspconfig.util"

local M = {}

function M.setup()
  if #vim.api.nvim_list_uis() == 0 then
    pcall(vim.api.nvim_del_augroup_by_name, "powershell.nvim-filetype")
    return
  end

  local bundle_path = paths.mason_package "powershell-editor-services"
  if not bundle_path then
    vim.schedule(function()
      vim.notify("powershell-editor-services is not installed yet", vim.log.levels.WARN)
    end)
    return
  end

  local capabilities = vim.deepcopy(nvchad_lsp.capabilities)
  local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
  if ok_cmp then
    capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
  end

  require("powershell").setup {
    bundle_path = bundle_path,
    shell = paths.executable "pwsh" or "pwsh",
    capabilities = capabilities,
    on_attach = function(client, bufnr)
      nvchad_lsp.on_attach(client, bufnr)
      vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
    end,
    root_dir = function(bufnr)
      local fname = vim.api.nvim_buf_get_name(bufnr)
      return util.root_pattern(".git", ".editorconfig", "PSScriptAnalyzerSettings.psd1")(fname) or vim.fs.dirname(fname)
    end,
  }
end

return M

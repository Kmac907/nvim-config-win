return {
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
  },
  {
    "navarasu/onedark.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("onedark").setup {
        style = "darker",
      }
    end,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "User FilePost",
    opts = {
      indent = { char = "│", highlight = "IblChar" },
      scope = {
        enabled = true,
        char = "│",
        highlight = "IblScopeChar",
        show_start = true,
        show_end = true,
        include = {
          node_type = {
            powershell = {
              "class_statement",
              "class_method_definition",
              "statement_block",
              "function_statement",
            },
            razor = {
              "razor_block",
              "razor_compound_using",
              "razor_if",
              "razor_else_if",
              "razor_else",
              "razor_switch",
              "razor_switch_case",
              "razor_switch_default",
              "razor_for",
              "razor_foreach",
              "razor_while",
              "razor_do_while",
              "razor_try",
              "razor_catch",
              "razor_finally",
              "razor_lock",
              "razor_section",
            },
          },
        },
        exclude = {
          -- `ibl` scope follows Treesitter lexical scope, not visual indent blocks.
          -- Keep Python excluded; enable Lua so the active scope guide is visible here.
          language = { "python" },
        },
      },
      exclude = {
        filetypes = {
          "help",
          "lazy",
          "mason",
          "NvimTree",
          "Trouble",
          "alpha",
          "dashboard",
          "notify",
          "toggleterm",
        },
        buftypes = { "terminal", "nofile" },
      },
    },
    config = function(_, opts)
      local function get_razor_scope_node(bufnr)
        local ok_parser, parser = pcall(vim.treesitter.get_parser, bufnr)
        if not ok_parser or parser:lang() ~= "razor" then
          return nil
        end

        local win = bufnr == vim.api.nvim_get_current_buf() and 0 or require("ibl.utils").get_win(bufnr)
        if not win then
          return nil
        end

        local scope = require "ibl.scope"
        local range = scope.get_cursor_range(win)
        local node = parser:named_node_for_range(range, { bufnr = bufnr })
        local include_types = opts.scope.include.node_type.razor or {}

        while node and node:byte_length() > 0 do
          if vim.tbl_contains(include_types, node:type()) then
            return node
          end

          node = node:parent()
        end

        return nil
      end

      local function configure_ibl_for_razor(bufnr)
        require("ibl").setup_buffer(bufnr, {
          scope = {
            injected_languages = false,
          },
        })
      end

      local function apply_ibl_colors()
        vim.api.nvim_set_hl(0, "IblChar", { fg = "#d79921" })
        vim.api.nvim_set_hl(0, "IblScopeChar", { fg = "#458588" })

        for i = 1, 7 do
          vim.api.nvim_set_hl(0, "@ibl.scope.underline." .. i, {
            sp = "#458588",
            underline = true,
          })
        end
      end

      dofile(vim.g.base46_cache .. "blankline")

      apply_ibl_colors()

      local hooks = require "ibl.hooks"
      require("ibl").setup(opts)
      do
        local scope = require "ibl.scope"
        local original_get = scope.get

        scope.get = function(bufnr, config)
          local node = original_get(bufnr, config)

          if node or not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype ~= "razor" then
            return node
          end

          return get_razor_scope_node(bufnr)
        end
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("UserIblRazorScope", { clear = true }),
        pattern = { "razor", "cshtml" },
        callback = function(args)
          configure_ibl_for_razor(args.buf)
        end,
      })

      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == "razor" then
          configure_ibl_for_razor(bufnr)
        end
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("UserIblColors", { clear = true }),
        callback = apply_ibl_colors,
      })

      dofile(vim.g.base46_cache .. "blankline")
      apply_ibl_colors()
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = require "configs.conform",
  },
  {
    "neovim/nvim-lspconfig",
    event = "User FilePost",
    config = function()
      require "configs.lspconfig"
    end,
  },
  {
    "seblyng/roslyn.nvim",
    ft = { "cs", "razor", "cshtml" },
    dependencies = {
      "neovim/nvim-lspconfig",
    },
    config = function()
      require("configs.dotnet").setup_roslyn()
    end,
  },
  {
    "GustavEikaas/easy-dotnet.nvim",
    cmd = { "Dotnet" },
    ft = { "cs", "csproj", "fsproj", "sln", "slnx", "razor", "cshtml", "props" },
    init = function()
      vim.filetype.add {
        extension = {
          razor = "razor",
          cshtml = "razor",
        },
      }
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "mfussenegger/nvim-dap",
      "seblyng/roslyn.nvim",
    },
    config = function()
      require("configs.dotnet").setup_easy_dotnet()
    end,
  },
  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    opts = require "configs.mason",
  },
  {
    "williamboman/mason-lspconfig.nvim",
    lazy = false,
    dependencies = { "williamboman/mason.nvim" },
    config = function() end,
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    lazy = false,
    dependencies = { "williamboman/mason.nvim" },
    config = function() end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    branch = "main",
    build = ":TSUpdate",
    opts = require "configs.treesitter",
    config = function(_, opts)
      require("nvim-treesitter").setup(opts)
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
  {
    "TheLeoP/powershell.nvim",
    ft = { "ps1", "psm1", "psd1" },
    dependencies = { "neovim/nvim-lspconfig", "mfussenegger/nvim-dap" },
    config = function()
      require("configs.powershell").setup()
    end,
  },
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require "configs.lint"
    end,
  },
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
  },
  {
    "folke/todo-comments.nvim",
    event = "BufReadPost",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "GustavEikaas/easy-dotnet.nvim" },
    opts = function(_, opts)
      return require("configs.dotnet").extend_cmp(opts)
    end,
  },
  {
    "ray-x/guihua.lua",
    lazy = true,
  },
  {
    "ray-x/go.nvim",
    ft = { "go", "gomod", "gowork", "gotmpl" },
    dependencies = {
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = require "configs.go",
    config = function(_, opts)
      require("go").setup(opts)
    end,
  },
  {
    "mrcjkb/rustaceanvim",
    version = "^5",
    ft = { "rust" },
    init = function()
      require("configs.rust").setup()
    end,
  },
  {
    "saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },
  {
    "linux-cultist/venv-selector.nvim",
    branch = "v1",
    cmd = { "VenvSelect", "VenvSelectCached" },
    enabled = function()
      return vim.fn.executable "fd" == 1 or vim.fn.executable "fdfind" == 1
    end,
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-telescope/telescope.nvim",
      "mfussenegger/nvim-dap-python",
    },
    opts = require "configs.python",
  },
  {
    "mfussenegger/nvim-dap",
    lazy = false,
    dependencies = {
      "nvim-neotest/nvim-nio",
      "rcarriga/nvim-dap-ui",
      "jay-babu/mason-nvim-dap.nvim",
      "theHamsta/nvim-dap-virtual-text",
      "leoluz/nvim-dap-go",
      "mfussenegger/nvim-dap-python",
    },
    config = function()
      require "configs.dap"
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "nvim-neotest/nvim-nio" },
    opts = {},
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function() end,
  },
  {
    "theHamsta/nvim-dap-virtual-text",
    opts = {},
  },
  {
    "leoluz/nvim-dap-go",
    ft = "go",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function() end,
  },
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function() end,
  },
  {
    "nvim-neotest/neotest",
    cmd = { "Neotest", "NeotestRun", "NeotestSummary" },
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "fredrikaverpil/neotest-golang",
      "nvim-neotest/neotest-python",
      "rouge8/neotest-rust",
    },
    config = function()
      require "configs.test"
    end,
  },
}

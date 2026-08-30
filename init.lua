-- ============================================================================
-- Neovim Configuration
-- ============================================================================
-- A modern Neovim setup with Lazy plugin manager, LSP support, and custom keybindings
-- Author: Milan
-- Last Updated: 2025-06-25

-- ============================================================================
-- BASIC SETTINGS
-- ============================================================================
-- Set up fundamental Neovim options for better editing experience

-- Indentation settings
vim.cmd("set expandtab")      -- Use spaces instead of tabs
vim.cmd("set tabstop=2")      -- Number of visual spaces per TAB
vim.cmd("set softtabstop=2")  -- Number of spaces in tab when editing
vim.cmd("set shiftwidth=2")   -- Number of spaces to use for autoindent

-- System integration
vim.cmd("set clipboard+=unnamedplus")  -- Use system clipboard

-- Leader key configuration
vim.g.mapleader = " "  -- Set space as the leader key for custom shortcuts

-- ============================================================================
-- PLUGIN MANAGER SETUP (LAZY.NVIM)
-- ============================================================================
-- Bootstrap Lazy plugin manager if it's not already installed

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- Use latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ============================================================================
-- PLUGIN CONFIGURATION
-- ============================================================================
-- Define all plugins to be installed and managed by Lazy

local plugins = {
  -- ========================================
  -- COLORSCHEME
  -- ========================================
  { 
    "catppuccin/nvim", 
    name = "catppuccin", 
    priority = 1000,  -- Load early to ensure colorscheme is available
    config = function()
      require("catppuccin").setup()
      vim.cmd.colorscheme("catppuccin")
    end
  },

  -- ========================================
  -- FUZZY FINDER
  -- ========================================
  {
    "nvim-telescope/telescope.nvim", 
    tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")
      
      -- Keybindings for Telescope
      vim.keymap.set("n", "<C-f>", builtin.find_files, { desc = "Find files" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep search" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Find help tags" })
    end
  },

  -- ========================================
  -- SYNTAX HIGHLIGHTING
  -- ========================================
  {
    "nvim-treesitter/nvim-treesitter",
    -- "main" is a full incompatible rewrite that needs Neovim 0.12+ and a
    -- different config API. "master" keeps the classic setup()/ensure_installed
    -- API below and is kept around upstream specifically for compatibility.
    branch = "master",
    build = ":TSUpdate",
    config = function()
      local config = require("nvim-treesitter.configs")
      config.setup({
        -- Languages to install syntax highlighting for
        ensure_installed = { "lua", "javascript", "typescript", "python", "html", "css", "json" },
        
        -- Enable syntax highlighting
        highlight = { enable = true },
        
        -- Enable smart indentation
        indent = { enable = true },
        
        -- Auto-install missing parsers
        auto_install = true,
      })
    end
  },

  -- ========================================
  -- FILE EXPLORER
  -- ========================================
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- File icons
      "MunifTanjim/nui.nvim",        -- UI components
    },
    config = function()
      require("neo-tree").setup({
        -- Close neo-tree when opening a file
        event_handlers = {
          {
            event = "file_open_requested",
            handler = function()
              require("neo-tree.command").execute({ action = "close" })
            end
          }
        },
        
        -- Filesystem settings
        filesystem = {
          follow_current_file = {
            enabled = true,         -- Find and focus current file
            leave_dirs_open = true, -- Keep directories open
          },
          hijack_netrw_behavior = "open_default", -- Replace netrw
          use_libuv_file_watcher = true,          -- Auto-refresh on file changes
          filtered_items = {
            visible = true,         -- Show hidden/filtered files instead of just a count
            hide_dotfiles = false,
            hide_gitignored = false,
          },
        },
        
        -- Window settings
        window = {
          position = "left",
          width = 30,
          mapping_options = {
            noremap = true,
            nowait = true,
          },
        },
      })
      
      -- Keybinding for Neo-tree
      vim.keymap.set("n", "<C-n>", ":Neotree filesystem reveal left<CR>",
        { desc = "Toggle Neo-tree file explorer", silent = true })
    end
  },

  -- ========================================
  -- KEYBINDING HELP / DISCOVERABILITY
  -- ========================================
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")
      wk.setup({})
      -- Label the leader-key groups used below so the popup reads clearly
      wk.add({
        { "<leader>f", group = "Find (Telescope)" },
        { "<leader>b", group = "Buffer" },
        { "<leader>g", group = "Git" },
      })
      -- Press <leader>h any time to see every available leader keybinding
      vim.keymap.set("n", "<leader>h", function()
        wk.show({ global = true })
      end, { desc = "Show keybinding help" })
    end
  },

  -- ========================================
  -- LSP + AUTOCOMPLETION
  -- ========================================
  -- mason.nvim installs language servers for you; nvim-lspconfig wires them
  -- up to Neovim's built-in LSP client; nvim-cmp adds the completion popup.
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    config = function()
      require("mason-lspconfig").setup({
        -- Common, lightweight servers installed automatically on first run
        ensure_installed = { "lua_ls", "pyright", "ts_ls", "html", "cssls", "jsonls" },
      })
    end
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Keybindings that apply once a language server attaches to a buffer
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_attach_keymaps", { clear = true }),
        callback = function(args)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = args.buf, desc = "Go to definition" })
          vim.keymap.set("n", "gr", vim.lsp.buf.references, { buffer = args.buf, desc = "List references" })
          vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = args.buf, desc = "Show hover docs" })
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = args.buf, desc = "Rename symbol" })
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = args.buf, desc = "Code action" })
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { buffer = args.buf, desc = "Previous diagnostic" })
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { buffer = args.buf, desc = "Next diagnostic" })
        end,
      })

      -- Neovim 0.11+ LSP config API: vim.lsp.config()/vim.lsp.enable() replaces
      -- the old lspconfig[server].setup({...}) pattern (nvim-lspconfig is
      -- removing that in v3.0.0). nvim-lspconfig is still needed as a plugin
      -- here since it ships the default per-server configs these calls apply.
      vim.lsp.config("*", { capabilities = capabilities })
      vim.lsp.enable({ "lua_ls", "pyright", "ts_ls", "html", "cssls", "jsonls" })
    end
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }),
      })
    end
  },

  -- ========================================
  -- GIT INTEGRATION
  -- ========================================
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        on_attach = function(bufnr)
          local gs = require("gitsigns")
          vim.keymap.set("n", "]c", gs.next_hunk, { buffer = bufnr, desc = "Next git hunk" })
          vim.keymap.set("n", "[c", gs.prev_hunk, { buffer = bufnr, desc = "Previous git hunk" })
          vim.keymap.set("n", "<leader>gp", gs.preview_hunk, { buffer = bufnr, desc = "Preview git hunk" })
          vim.keymap.set("n", "<leader>gb", gs.blame_line, { buffer = bufnr, desc = "Git blame line" })
        end,
      })
    end
  },

  -- ========================================
  -- AUTO-CLOSE BRACKETS/QUOTES
  -- ========================================
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
    end
  },

  -- ========================================
  -- STATUS LINE
  -- ========================================
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      -- catppuccin/nvim registers its lualine theme as "catppuccin-nvim",
      -- not "catppuccin" (that name doesn't exist and silently falls back
      -- to "auto"). This variant follows whichever flavour is active.
      require("lualine").setup({
        options = { theme = "catppuccin-nvim" },
      })
    end
  },
}

-- ============================================================================
-- PLUGIN INITIALIZATION
-- ============================================================================
-- Initialize Lazy plugin manager with our plugin configuration

local lazy_opts = {
  -- UI settings for the plugin manager
  ui = {
    border = "rounded",
  },
  -- None of the plugins above need LuaRocks, so skip installing/checking for
  -- it entirely. Without this, :checkhealth shows a scary-looking red X for
  -- missing luarocks/hererocks even though it's completely harmless.
  rocks = {
    enabled = false,
  },
  -- Performance optimizations
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
}

require("lazy").setup(plugins, lazy_opts)

-- ============================================================================
-- ADDITIONAL KEYBINDINGS
-- ============================================================================
-- Custom keybindings for improved workflow

-- General editor shortcuts
vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save file" })
vim.keymap.set("n", "<leader>q", ":q<CR>", { desc = "Quit" })
vim.keymap.set("n", "<leader>x", ":x<CR>", { desc = "Save and quit" })

-- Buffer navigation
vim.keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bp", ":bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })

-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- ============================================================================
-- EDITOR ENHANCEMENTS
-- ============================================================================
-- Additional settings for better editing experience

-- Line numbers
vim.opt.number = true         -- Show line numbers
vim.opt.relativenumber = true -- Show relative line numbers

-- Search settings
vim.opt.ignorecase = true     -- Ignore case in search
vim.opt.smartcase = true      -- Case-sensitive if uppercase letters present
vim.opt.hlsearch = true       -- Highlight search results
vim.opt.incsearch = true      -- Show search matches as you type

-- Visual settings
vim.opt.termguicolors = true  -- Enable 24-bit RGB colors
vim.opt.signcolumn = "yes"    -- Always show sign column
vim.opt.wrap = false          -- Don't wrap lines
vim.opt.scrolloff = 8         -- Keep 8 lines above/below cursor
vim.opt.sidescrolloff = 8     -- Keep 8 columns left/right of cursor

-- File handling
vim.opt.backup = false        -- Don't create backup files
vim.opt.writebackup = false   -- Don't create backup while editing
vim.opt.swapfile = false      -- Don't create swap files
vim.opt.undofile = true       -- Enable persistent undo

-- Split settings
vim.opt.splitbelow = true     -- Open horizontal splits below
vim.opt.splitright = true     -- Open vertical splits to the right

-- ============================================================================
-- AUTO COMMANDS
-- ============================================================================
-- Automatic actions for various events

-- Highlight yanked text briefly
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight yanked text",
  group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
})

-- Remove trailing whitespace on save
-- Uses keeppatterns (doesn't clobber the last search) and saves/restores the
-- cursor position and window view, so it doesn't jump you around on save.
vim.api.nvim_create_autocmd("BufWritePre", {
  desc = "Remove trailing whitespace",
  group = vim.api.nvim_create_augroup("trim_whitespace", { clear = true }),
  pattern = "*",
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- ============================================================================
-- STATUS LINE
-- ============================================================================
-- Handled by lualine.nvim (configured in the plugin list above)

-- ============================================================================
-- FINAL MESSAGE
-- ============================================================================
print("🚀 Neovim configuration loaded successfully!")
print("📖 Press <leader>h for help, where leader = Space")

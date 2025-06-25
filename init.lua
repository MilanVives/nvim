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
if not vim.loop.fs_stat(lazypath) then
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
  }
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
vim.api.nvim_create_autocmd("BufWritePre", {
  desc = "Remove trailing whitespace",
  group = vim.api.nvim_create_augroup("trim_whitespace", { clear = true }),
  pattern = "*",
  command = [[%s/\s\+$//e]],
})

-- ============================================================================
-- STATUS LINE
-- ============================================================================
-- Simple custom statusline

vim.opt.laststatus = 2  -- Always show statusline
vim.opt.statusline = table.concat({
  " %f",          -- File path
  " %m",          -- Modified flag
  " %r",          -- Readonly flag
  "%=",           -- Right align
  " %y",          -- File type
  " %{&ff}",      -- File format
  " %{&fenc}",    -- File encoding
  " %l:%c",       -- Line:Column
  " %p%%",        -- Percentage through file
  " "
})

-- ============================================================================
-- FINAL MESSAGE
-- ============================================================================
print("🚀 Neovim configuration loaded successfully!")
print("📖 Press <leader>h for help, where leader = Space")

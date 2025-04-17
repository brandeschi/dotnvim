-- Bootstrap Config/Lazy
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local is_bootstrapped = false
if not vim.loop.fs_stat(lazypath) then
  is_bootstrapped = true
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Netrw
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
vim.g.netrw_browse_split = 4
vim.g.netrw_altv = 1
vim.g.netrw_winsize = 30

-- Set configs
local set = vim.opt
vim.g.mapleader = " "

set.clipboard = "unnamed"
set.formatoptions = set.formatoptions + "c,r,o"
set.nrformats = set.nrformats + "alpha"
set.makeprg = "build.bat"
set.tabstop = 2
set.softtabstop = 2
set.shiftwidth = 2
set.expandtab = true
set.completeopt = { "menu", "menuone" }
set.pumheight = 5
set.mouse = "a"
set.termguicolors = false
set.guicursor = "n:blinkwait1blinkon500-blinkoff500-Cursor,i:blinkon0-iCursor"
-- set.guifont = "Code New Roman:h14"
set.guifont = "Input:h12"
set.number = true
set.autoindent = true
set.smartindent = true
set.relativenumber = true
set.wrap = false
set.showmode = false
set.cursorline = true
set.incsearch = true
set.hlsearch = false
set.ignorecase = false
set.showmatch = true
set.signcolumn = "yes"
set.fileencoding = "utf-8"
set.splitbelow = true
set.splitright = true
set.scrolloff = 8
set.sidescrolloff = 8
vim.g.cursorhold_updatetime = 100

vim.diagnostic.disable()

local wrap = function(func, ...)
  local args = { ... }
  return function()
    func(unpack(args))
  end
end

-- Plugins
require("lazy").setup({
  {
    'brandeschi/medieval.nvim',
    lazy = false,
    priority = 1000,
    dev = true,
    config = function()
      vim.cmd("colorscheme medieval")
    end,
  },
  {
    'neovim/nvim-lspconfig',
    config = function()
      -- TODO: Figure out if we want 'cmp_nvim_lsp'
      -- local capabilities = require("cmp_nvim_lsp").default_capabilities()
      local on_attach = function(client, bufnr)
        local nmap = function(keys, func, desc)
          if desc then
            desc = 'LSP: ' .. desc
          end
          vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
        end

        nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
        nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

        nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
        nmap('gs', '<cmd>vs <bar> lua vim.lsp.buf.definition()<CR>', '[G]oto [S]plit Definition')
        nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
        nmap('gI', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
        nmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
        nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
        nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

        -- See `:help K` for why this keymap
        nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
        nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

        -- Lesser used LSP functionality
        nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
        nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
        nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
        nmap('<leader>wl', function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, '[W]orkspace [L]ist Folders')


        -- Use when formatting is figured out
        -- if client.supports_method("textDocument/formatting") then
        --   vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
        --   vim.api.nvim_create_autocmd("BufWritePre", {
        --   group = augroup,
        --   buffer = bufnr,
        --   callback = function()
        --   vim.lsp.buf.format()
        --   end,

        -- Create a command `:Format` local to the LSP buffer
        vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
          vim.lsp.buf.format()
        end, { desc = 'Format current buffer with LSP' })

        -- Disable diags for clangd since it sucks at unity builds currently
        if client.name == 'clangd' then
          set.makeprg = ".\\build %:p:h"
        end
      end

      local handlers = {
        ["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = 'rounded' }),
        ["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = 'rounded' }),
      }

      local lsps = {
        lua_ls = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
            diagnostics = {
              enable = true,
              globals = { 'vim', 'use' },
            }
          }
        },
        clangd = {
          cmd = {
            "clangd",
            "--background-index",
            "--pch-storage=memory",
            "--all-scopes-completion",
            "--pretty",
            "--header-insertion=never",
            "-j=4",
            "--function-arg-placeholders",
            "--completion-style=detailed"
          },
        },
      }

      -- local test_table = {
      --   lua_ls = {
      --     on_init = function(client)
      --       if client.workspace_folders then
      --         local path = client.workspace_folders[1].name
      --         if path ~= vim.fn.stdpath('config') and (vim.loop.fs_stat(path..'/.luarc.json') or vim.loop.fs_stat(path..'/.luarc.jsonc')) then
      --           return
      --         end
      --       end
      --
      --       client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
      --         runtime = {
      --           -- Tell the language server which version of Lua you're using
      --           -- (most likely LuaJIT in the case of Neovim)
      --           version = 'LuaJIT'
      --         },
      --         -- Make the server aware of Neovim runtime files
      --         workspace = {
      --           checkThirdParty = false,
      --           library = {
      --             vim.env.VIMRUNTIME
      --             -- Depending on the usage, you might want to add additional paths here.
      --             -- "${3rd}/luv/library"
      --             -- "${3rd}/busted/library",
      --           }
      --         }
      --       })
      --     end,
      --     Lua = {
      --       workspace = { checkThirdParty = false },
      --       telemetry = { enable = false },
      --       diagnostics = {
      --         enable = true,
      --         globals = { 'vim', 'use' },
      --       }
      --     }
      --   },
      -- }


      -- TODO: do all the things in a loop?
      -- for key, val in pairs(test_table) do
      --   print(key)
      --   print('b')
      --   print(vim.tbl_keys(val))
      --   print('a')
      --   if type(val) == "function" then
      --     print("this a func")
      --   end
      -- end
      for lsp_name, value in pairs(lsps) do
        require("lspconfig")[lsp_name].setup {
          on_attach = on_attach,
          handlers = handlers,
          settings = lsps[lsp_name]
        }
      end
    end,

  },
  {
    'nvim-treesitter/nvim-treesitter',
    config = function()
      local ts_status_ok, treesitter = pcall(require, "nvim-treesitter.configs")
      if not ts_status_ok then
        return
      end
      treesitter.setup {
        -- A list of parser names, or "all"
        ensure_installed = { "c", "cpp", "lua", "vim" },
        -- Install parsers synchronously (only applied to `ensure_installed`)
        sync_install = false,
        -- Automatically install missing parsers when entering buffer
        auto_install = false,
        -- List of parsers to ignore installing (for "all")
        ignore_install = { "" },
        highlight = {
          -- `false` will disable the whole extension
          enable = true,
          -- list of language that will be disabled
          disable = { "" },
          -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
          -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
          -- Using this option may slow down your editor, and you may see some duplicate highlights.
          -- Instead of true it can also be a list of languages
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        }
      }
    end
  },
  {
    'nvim-telescope/telescope.nvim',
    lazy = true,
    cmd = "Telescope",
    config = function()
      local telescope_status_ok, telescope = pcall(require, "telescope")
      if not telescope_status_ok then
        return
      end
      telescope.setup {
        defaults = {
          prompt_prefix = " ",
          selection_caret = " ",
          path_display = { "smart" },
          pickers = {
            find_files = {
              theme = "dropdown"
            }
          },
        },
      }
    end
  },
  { 'numToStr/Comment.nvim', config = true },
  {
    'lewis6991/gitsigns.nvim',
    lazy = false,
    config = function()
      local gitsigns_status_ok, gitsigns = pcall(require, "gitsigns")
      if not gitsigns_status_ok then
        return
      end
      require('gitsigns').setup {}
    end
  },
  { 'windwp/nvim-autopairs', config = true },
  {
    'folke/todo-comments.nvim',
    lazy = true,
    event = "VeryLazy",
    config = function()
      local todo_status_ok, todo = pcall(require, "todo-comments")
      if not todo_status_ok then
        return
      end
      todo.setup({
        signs = true,      -- show icons in the signs column
        sign_priority = 8, -- sign priority
        -- keywords recognized as todo comments
        keywords = {
          FIX = {
            icon = " ", -- icon used for the sign, and in search results
            color = "error", -- can be a hex color, or a named color (see below)
            alt = { "FIXME", "BUG", "FIXIT", "ISSUE" }, -- a set of other keywords that all map to this FIX keywords
            -- signs = false, -- configure signs for some keywords individually
          },
          TODO = { icon = " ", color = "todo" },
          IMPORTANT = { icon = " ", color = "important" },
          HACK = { icon = " ", color = "warning" },
          WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
          PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
          NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
          TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
        },
        gui_style = {
          fg = "NONE",         -- The gui style to use for the fg highlight group.
          bg = "BOLD",         -- The gui style to use for the bg highlight group.
        },
        merge_keywords = true, -- when true, custom keywords will be merged with the defaults
        -- highlighting of the line containing the todo comment
        -- * before: highlights before the keyword (typically comment characters)
        -- * keyword: highlights of the keyword
        -- * after: highlights after the keyword (todo text)
        highlight = {
          multiline = true,                -- enable multine todo comments
          multiline_pattern = "^.",        -- lua pattern to match the next multiline from the start of the matched keyword
          multiline_context = 10,          -- extra lines that will be re-evaluated when changing a line
          before = "",                     -- "fg" or "bg" or empty
          keyword = "wide",                -- "fg", "bg", "wide", "wide_bg", "wide_fg" or empty. (wide and wide_bg is the same as bg, but will also highlight surrounding characters, wide_fg acts accordingly but with fg)
          after = "fg",                    -- "fg" or "bg" or empty
          pattern = [[.*<(KEYWORDS)\s*:]], -- pattern or table of patterns, used for highlightng (vim regex)
          comments_only = true,            -- uses treesitter to match keywords in comments only
          max_line_len = 400,              -- ignore lines longer than this
          exclude = {},                    -- list of file types to exclude highlighting
        },
        -- list of named colors where we try to extract the guifg from the
        -- list of highlight groups or use the hex color if hl not found as a fallback
        colors = {
          error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
          warning = { "DiagnosticWarning", "WarningMsg", "#FBBF24" },
          info = { "DiagnosticInfo", "#2563EB" },
          hint = { "DiagnosticHint", "#10B981" },
          default = { "Identifier", "#7C3AED" },
          test = { "Identifier", "#FF00FF" },
          todo = { "", "#F87953" },
          important = { "", "#FFD700" }
        },
        search = {
          command = "rg",
          args = {
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
          },
          -- regex that will be used to match keywords.
          -- don't replace the (KEYWORDS) placeholder
          pattern = [[\b(KEYWORDS):]], -- ripgrep regex
          -- pattern = [[\b(KEYWORDS)\b]], -- match without the extra colon. You'll likely get false positives
        },
      })
    end
  },
  {
    "ray-x/lsp_signature.nvim",
    event = "InsertEnter",
    opts = { floating_window = false },
    config = function(_, opts)
      require("lsp_signature").setup(opts)
    end,
  },
}, {
  defaults = { lazy = false, version = nil },
  dev = { path = "C:/dev" },
  checker = { enabled = false },
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
if is_bootstrapped then
  require('lazy').sync()
end

-- When we are bootstrapping a configuration, it doesn't
-- make sense to execute the rest of the init.lua.
--
-- You'll need to restart nvim, and then it will work.
if is_bootstrapped then
  print '=================================='
  print '    Plugins are being installed'
  print '    Wait until Lazy completes,'
  print '       then restart nvim'
  print '=================================='
  return
end

-- Keybindings
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }
keymap({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Normal Mode Binds --
keymap('n', '<Leader>/', 'gcc', { remap = true, silent = true })
keymap('n', '<C-h>', '<C-W>h', opts)
keymap('n', '<C-j>', '<C-W>j', opts)
keymap('n', '<C-k>', '<C-W>k', opts)
keymap('n', '<C-l>', '<C-W>l', opts)
keymap('n', '<Leader>\\', '<C-W>|', opts)
keymap('n', '<Leader>=', '<C-W>=', opts)
keymap('n', '<C-s>', '<CMD>w<CR>', opts)

keymap('n', '<Leader>wr', '<C-W>r', opts)
keymap("n", "<Leader>e", vim.cmd.Lex, opts)
keymap('n', 'n', 'nzzzv')
keymap('n', 'N', 'Nzzzv')

-- Buffers / Tabs
keymap("n", "<Leader>tn", "<CMD>tabnew<CR>", opts)
keymap("n", "<Leader>tt", "<CMD>tabnext<CR>", opts)
-- Delete Tab
keymap("n", "<Leader>tc", "<CMD>tabclose<CR>", opts)

-- GitSigns
keymap("n", "<Leader>n", ":silent Gitsigns next_hunk<CR>", opts)

-- Telescope
-- keymap("n", "<Leader>ff", "<cmd>lua require('telescope.builtin').find_files(require('telescope.themes').get_dropdown{ previewer = false, winblend = 20 })<CR>", opts)
keymap("n", "<leader>ff",
  "<cmd>lua require'telescope.builtin'.find_files(require('telescope.themes').get_dropdown({ previewer = false, borderchars = {{ '─', '│', '─', '│', '┌', '┐', '┘', '└'}, prompt = {'─', '│', ' ', '│', '┌', '┐', '│', '│'}, results = {'─', '│', '─', '│', '├', '┤', '┘', '└'}, preview = { '─', '│', '─', '│', '┌', '┐', '┘', '└'},}, prompt_title = false }))<cr>"
  , opts)
keymap("n", "<Leader>gg",
  "<cmd>lua require'telescope.builtin'.live_grep(require('telescope.themes').get_dropdown({ previewer = false, borderchars = {{ '─', '│', '─', '│', '┌', '┐', '┘', '└'}, prompt = {'─', '│', ' ', '│', '┌', '┐', '│', '│'}, results = {'─', '│', '─', '│', '├', '┤', '┘', '└'}, preview = { '─', '│', '─', '│', '┌', '┐', '┘', '└'},}, prompt_title = false }))<cr>"
  , opts)
keymap("n", "<Leader>gs", "<cmd>Telescope grep_string<CR>", opts)

-- C-bindings
keymap('n', '<Leader>cs', ':ClangdSwitchSourceHeader<CR>', opts)
-- Build cmd -- Need to get this to find the build.bat file and run it!
keymap('n', '<Leader>bb', '<CMD>make<CR>', opts)
-- Run EXE
keymap('n', '<Leader>br', ':silent !C:\\dev\\exec %:p:h<CR>', opts)
-- Launch debugger
keymap('n', '<Leader>ld', ':silent !devenv<CR>', opts)

-- Visual Mode Binds --
keymap('v', '<Leader>/', 'gc', { remap = true, silent = true })
keymap('v', '<', '<gv', opts)
keymap('v', '>', '>gv', opts)

-- Move text up and down
keymap("v", "J", ":m '>+1<CR>gv=gv")
keymap("v", "K", ":m '<-2<CR>gv=gv")

-- Keep paste/delete buffer clean
keymap("x", "<leader>p", [["_dP]])
keymap({ "n", "v" }, "<leader>y", [["+y]])
keymap("n", "<leader>Y", [["+Y]])
keymap({ "n", "v" }, "<leader>d", [["_d]])

-- Neovide
if vim.g.neovide then
  vim.api.nvim_set_keymap('v', '<sc-c>', '"+y', { noremap = true })
  vim.api.nvim_set_keymap('n', '<sc-v>', 'l"+P', { noremap = true })
  vim.api.nvim_set_keymap('v', '<sc-v>', '"+P', { noremap = true })
  vim.api.nvim_set_keymap('c', '<sc-v>', '<C-o>l<C-o>"+<C-o>P<C-o>l', { noremap = true })
  vim.api.nvim_set_keymap('i', '<sc-v>', '<ESC>l"+Pli', { noremap = true })
  vim.api.nvim_set_keymap('t', '<sc-v>', '<C-\\><C-n>"+Pi', { noremap = true })

  vim.api.nvim_set_keymap('n', '<F11>', ":let g:neovide_fullscreen = !g:neovide_fullscreen<CR>", {})
end

-- Autocmds
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  callback = function()
    if not vim.o.binary and vim.o.filetype ~= 'diff' then
      local current_view = vim.fn.winsaveview()
      vim.cmd([[keeppatterns %s/\s\+$//e]])
      vim.fn.winrestview(current_view)
    end
  end,
})

-- Statusline
-- TODO: Create modes with icons instead
local modes = {
  ["n"] = "NORMAL",
  ["no"] = "NORMAL",
  ["v"] = "VISUAL",
  ["V"] = "VISUAL LINE",
  [""] = "VISUAL BLOCK",
  ["s"] = "SELECT",
  ["S"] = "SELECT LINE",
  [""] = "SELECT BLOCK",
  ["i"] = "INSERT",
  ["ic"] = "INSERT",
  ["R"] = "REPLACE",
  ["Rv"] = "VISUAL REPLACE",
  ["c"] = "COMMAND",
  ["cv"] = "VIM EX",
  ["ce"] = "EX",
  ["r"] = "PROMPT",
  ["rm"] = "MOAR",
  ["r?"] = "CONFIRM",
  ["!"] = "SHELL",
  ["t"] = "TERMINAL",
}

local function mode()
  local current_mode = vim.api.nvim_get_mode().mode
  return string.format(" %s ", modes[current_mode]):upper()
end
local function update_mode_colors()
  local current_mode = vim.api.nvim_get_mode().mode
  local mode_color = "%#StatusLine#"
  if current_mode == "n" then
    mode_color = "%#StatusLine#"
  elseif current_mode == "i" or current_mode == "ic" then
    mode_color = "%#StatusLineInsert#"
  elseif current_mode == "v" or current_mode == "V" or current_mode == "" then
    mode_color = "%#StatusLineVisual#"
  elseif current_mode == "R" then
    mode_color = "%#StatusLineReplace#"
  elseif current_mode == "c" then
    mode_color = "%#StatusLineCmdLine#"
  end
  return mode_color
end
local function filepath()
  local fpath = vim.fn.fnamemodify(vim.fn.expand "%", ":~:.:h")
  if fpath == "" or fpath == "." then
    return " "
  end

  return string.format(" %%<%s/", fpath)
end
local function filename()
  local fname = vim.fn.expand "%:t"
  if fname == "" then
    return ""
  end
  return fname .. " "
end
local vcs = function()
  local git_info = vim.b.gitsigns_status_dict
  if not git_info or git_info.head == "" then
    return ""
  end
  local added = git_info.added and ("%#GitSignsAdd#+" .. git_info.added .. " ") or ""
  local changed = git_info.changed and ("%#GitSignsChange#~" .. git_info.changed .. " ") or ""
  local removed = git_info.removed and ("%#GitSignsDelete#-" .. git_info.removed .. " ") or ""
  if git_info.added == 0 then
    added = ""
  end
  if git_info.changed == 0 then
    changed = ""
  end
  if git_info.removed == 0 then
    removed = ""
  end
  return table.concat {
    added,
    changed,
    removed,
    " ",
    "%#GitSignsAdd# ",
    git_info.head,
    " %#Normal#",
  }
end

-- Build statusline
Statusline = {}

Statusline.active = function()
  return table.concat {
    "%#Statusline#",
    update_mode_colors(),
    mode(),
    "%#Normal# ",
    vcs(),
    filepath(),
    filename(),
    "%{&modified?'●':''}%=col %c | %p%% | %L lines",
  }
end

function Statusline.inactive()
  return " %F"
end

vim.api.nvim_create_augroup("StatusLine", {})
vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
  group = "StatusLine",
  callback = function()
    vim.opt_local.statusline = "%!v:lua.Statusline.active()"
  end
})
vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
  group = "StatusLine",
  callback = function()
    vim.opt_local.statusline = "%!v:lua.Statusline.inactive()"
  end
})

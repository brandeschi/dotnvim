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
set.tabstop = 4
set.softtabstop = 4
set.shiftwidth = 4
set.expandtab = true
set.completeopt = { "menu", "menuone" }
set.mouse = "a"
set.guicursor = ""
set.guifont = "JetBrainsMono NF:h16"
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
set.termguicolors = true
set.scrolloff = 8
set.sidescrolloff = 8
vim.g.cursorhold_updatetime = 100

-- Diag Config
vim.diagnostic.config({
    virtual_text = false,
})

local wrap = function(func, ...)
    local args = { ... }
    return function()
        func(unpack(args))
    end
end
-- Diagnostic keymaps
vim.keymap.set('n', '<Leader>ne', vim.diagnostic.goto_prev)
vim.keymap.set('n', '<Leader>pe', vim.diagnostic.goto_next)
vim.keymap.set('n', 'gl', wrap(vim.diagnostic.open_float, { border = 'rounded' }))
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)

-- Plugins
require("lazy").setup({
    {
        'brandeschi/medieval.nvim',
        lazy = false,
        priority = 1000,
        config = function()
            vim.cmd("colorscheme medieval")
        end,
    },
    'nvim-lua/plenary.nvim', -- Useful lua functions used by lots of plugins
    'neovim/nvim-lspconfig',
    'williamboman/mason.nvim',
    {
        'williamboman/mason-lspconfig.nvim',
        lazy = true,
        config = function()
            --  Add any additional override configuration in the following tables. They will be passed to
            --  the `settings` field of the server config. You must look up that documentation yourself.
            local servers = {
                -- pyright = {},
                -- rust_analyzer = {},
                tsserver = {},
                clangd = {},
                lua_ls = {
                    Lua = {
                        workspace = { checkThirdParty = false },
                        telemetry = { enable = false },
                        diagnostics = {
                            enable = true,
                            globals = { 'vim', 'use' },
                        }
                    },
                },
            }
            --  This function gets run when an LSP connects to a particular buffer.
            local on_attach = function(client, bufnr)
                -- NOTE: Remember that lua is a real programming language, and as such it is possible
                -- to define small helper and utility functions so you don't have to repeat yourself
                -- many times.
                --
                -- In this case, we create a function that lets us more easily define mappings specific
                -- for LSP related items. It sets the mode, buffer and description for us each time.
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

                -- Create a command `:Format` local to the LSP buffer
                vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
                    vim.lsp.buf.format()
                end, { desc = 'Format current buffer with LSP' })

                -- Disable diags for clangd since it sucks at unity builds currently
                if client.name == 'clangd' then
                    vim.diagnostic.disable()
                end
                if client.name == 'tsserver' then
                    vim.cmd("setl tabstop=2")
                    vim.cmd("setl softtabstop=2")
                    vim.cmd("setl shiftwidth=2")
                end
            end
            local handlers = {
                ["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = 'rounded' }),
                ["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = 'rounded' }),
            }

            require('mason-lspconfig').setup {
                ensure_installed = vim.tbl_keys(servers),
            }
            -- local capabilities = require('cmp_nvim_lsp').default_capabilities()
            require('mason-lspconfig').setup_handlers {
                function(server_name)
                    require('lspconfig')[server_name].setup({
                        -- capabilities = capabilities,
                        on_attach = on_attach,
                        settings = servers[server_name],
                        handlers = handlers,
                    })
                end,
            }
        end
    },
    'jose-elias-alvarez/null-ls.nvim',
    'jay-babu/mason-null-ls.nvim',
    {
        'rest-nvim/rest.nvim',
        lazy = true,
        config = function()
            require("rest-nvim").setup({
                -- Open request results in a horizontal split
                result_split_horizontal = false,
                -- Keep the http file buffer above|left when split horizontal|vertical
                result_split_in_place = false,
                -- Skip SSL verification, useful for unknown certificates
                skip_ssl_verification = false,
                -- Encode URL before making request
                encode_url = true,
                -- Highlight request on run
                highlight = {
                    enabled = true,
                    timeout = 150,
                },
                result = {
                    -- toggle showing URL, HTTP info, headers at top the of result window
                    show_url = true,
                    show_http_info = true,
                    show_headers = true,
                    -- executables or functions for formatting response body [optional]
                    -- set them to false if you want to disable them
                    formatters = {
                        json = "jq",
                        html = function(body)
                            return vim.fn.system({ "tidy", "-i", "-q", "-" }, body)
                        end
                    },
                },
                -- Jump to request line on run
                jump_to_request = false,
                env_file = '.env',
                custom_dynamic_variables = {},
                yank_dry_run = true,
            })
        end
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
                ensure_installed = { "c", "cpp", "lua", "rust", "vim", "help" },

                -- Install parsers synchronously (only applied to `ensure_installed`)
                sync_install = false,

                -- Automatically install missing parsers when entering buffer
                auto_install = true,

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
    { 'antoinemadec/FixCursorHold.nvim', lazy = true }, -- This is needed to fix lsp doc highlight
    {
        'nvim-lualine/lualine.nvim',
        lazy = true,
        config = function()
            local ll_status_ok, lualine = pcall(require, "lualine")
            if not ll_status_ok then
                return
            end
            local lsp_active = {
                function()
                    local msg = 'No Active Lsp'
                    local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
                    local clients = vim.lsp.get_active_clients()
                    if next(clients) == nil then
                        return msg
                    end
                    for _, client in ipairs(clients) do
                        local filetypes = client.config.filetypes
                        if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
                            return client.name
                        end
                    end
                    return msg
                end,
                icon = ' LSP:',
            }
            local mode = {
                "mode",
                fmt = function(str)
                    if str == "NORMAL" then
                        return ""
                    elseif str == "INSERT" then
                        return ""
                    elseif str == "VISUAL" or "VISUAL-LINE" or "VISUAL-BLOCK" then
                        return ""
                    elseif str == "COMMAND" then
                        return ""
                    else
                        return "-- " .. str .. " --"
                    end
                end,
                -- padding = 2
            }
            local branch = {
                "branch",
                icons_enabled = true,
                icon = "",
            }
            local location = {
                "location",
                padding = 1,
            }
            -- cool function for progress
            local progress = function()
                local current_line = vim.fn.line(".")
                local total_lines = vim.fn.line("$")
                local line_ratio = current_line / total_lines
                local percent = math.floor(line_ratio * 100)
                return percent .. "%%"
            end
            local spaces = function()
                return "  " .. vim.api.nvim_buf_get_option(0, "shiftwidth")
            end

            lualine.setup({
                options = {
                    icons_enabled = true,
                    theme = "auto",
                    component_separators = '|',
                    section_separators = { left = '', right = '' },
                    disabled_filetypes = { "alpha", "dashboard", "NvimTree", "Outline" },
                    always_divide_middle = true,
                },
                sections = {
                    lualine_a = { branch },
                    lualine_b = { mode },
                    lualine_c = { "filename" },
                    lualine_x = { lsp_active, spaces },
                    lualine_z = { location, progress },
                },
                inactive_sections = {
                    lualine_a = {},
                    lualine_b = {},
                    lualine_c = {},
                    lualine_x = {},
                    lualine_y = {},
                    lualine_z = {},
                },
                tabline = {},
                extensions = {},
            })
        end
    },
    { 'numToStr/Comment.nvim',           lazy = true, config = true },
    {
        'lewis6991/gitsigns.nvim',
        lazy = true,
        config = function()
            local gitsigns_status_ok, gitsigns = pcall(require, "gitsigns")
            if not gitsigns_status_ok then
                return
            end
            gitsigns.setup {
                signs = {
                    add = { hl = "GitSignsAdd", text = "▎", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
                    change = {
                        hl = "GitSignsChange",
                        text = "▎",
                        numhl = "GitSignsChangeNr",
                        linehl = "GitSignsChangeLn"
                    },
                    delete = {
                        hl = "GitSignsDelete",
                        text = "契",
                        numhl = "GitSignsDeleteNr",
                        linehl = "GitSignsDeleteLn"
                    },
                    topdelete = {
                        hl = "GitSignsDelete",
                        text = "契",
                        numhl = "GitSignsDeleteNr",
                        linehl = "GitSignsDeleteLn"
                    },
                    changedelete = {
                        hl = "GitSignsChange",
                        text = "▎",
                        numhl = "GitSignsChangeNr",
                        linehl = "GitSignsChangeLn"
                    },
                },
                signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
                numhl = false,     -- Toggle with `:Gitsigns toggle_numhl`
                linehl = false,    -- Toggle with `:Gitsigns toggle_linehl`
                word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
                watch_gitdir = {
                    interval = 1000,
                    follow_files = true,
                },
                attach_to_untracked = true,
                current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
                current_line_blame_opts = {
                    virt_text = true,
                    virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
                    delay = 500,
                    ignore_whitespace = false,
                },
                current_line_blame_formatter_opts = {
                    relative_time = false,
                },
                sign_priority = 6,
                update_debounce = 100,
                status_formatter = nil, -- Use default
                -- max_file_length = 40000,
                preview_config = {
                    -- Options passed to nvim_open_win
                    border = "single",
                    style = "minimal",
                    relative = "cursor",
                    row = 0,
                    col = 1,
                },
                yadm = {
                    enable = false,
                },
            }
        end
    },
    { 'windwp/nvim-autopairs', config = true },
    {
        'folke/todo-comments.nvim',
        lazy = true,
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
                        icon = " ",                              -- icon used for the sign, and in search results
                        color = "error",                            -- can be a hex color, or a named color (see below)
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
                    fg = "NONE",       -- The gui style to use for the fg highlight group.
                    bg = "BOLD",       -- The gui style to use for the bg highlight group.
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
        "hrsh7th/nvim-cmp",
        -- load cmp on InsertEnter
        event = "InsertEnter",
        -- these dependencies will only be loaded when cmp loads
        -- dependencies are always lazy-loaded unless specified otherwise
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
        },
        config = function()
            local has_words_before = function()
                unpack = unpack or table.unpack
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                return col ~= 0 and
                    vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
            end
            local cmp = require('cmp')
            cmp.setup({
                preselect = cmp.PreselectMode.Item,
                window = {
                    completion = cmp.config.window.bordered(),
                },
                mapping = {
                    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-f>'] = cmp.mapping.scroll_docs(4),
                    ['<C-e>'] = cmp.mapping.abort(),
                    -- Tab that brings up the menu only when I hit tab
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if has_words_before() and not cmp.visible() then
                            cmp.select_next_item()
                            cmp.complete()
                        elseif has_words_before() then
                            cmp.select_next_item()
                        else
                            fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
                        end
                    end, { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visable() then
                            cmp.select_prev_item()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                },
                sources = cmp.config.sources({
                    { name = 'nvim_lsp' },
                }, {
                    { name = 'buffer' },
                })
            })
        end,
    },

    -- Other themes
    { 'AlexvZyl/nordic.nvim',  lazy = true,  config = true },
}, {
    defaults = { lazy = false, version = nil },
    checker = { enabled = true },
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

keymap('n', '<Leader>wr', '<C-W>r', opts)
keymap("n", "<Leader>e", ":Lex<CR>", opts)

-- Rest.nvim
keymap("n", "<Leader>rr", "<CMD>lua require('rest-nvim').run()<CR>", opts)

-- Buffers / Tabs
keymap("n", "<Leader>tn", "<CMD>tabnew<CR>", opts)
keymap("n", "<Leader>tt", "<CMD>tabnext<CR>", opts)
-- Delete Tab
keymap("n", "<Leader>tc", "<CMD>tabclose<CR>", opts)

-- GitSigns
keymap("n", "<Leader>n", ":silent Gitsigns next_hunk<CR>", opts)

-- TODO: Expand how I use this
--
-- Telescope
keymap("n", "<Leader>ff", "<cmd>Telescope find_files<CR>", opts)
keymap("n", "<Leader>gg", "<cmd>Telescope live_grep<CR>", opts)
keymap("n", "<Leader>gs", "<cmd>Telescope grep_string<CR>", opts)

-- C-bindings
keymap('n', '<Leader>cs', ':ClangdSwitchSourceHeader<CR>', opts)
-- Build cmd -- Need to get this to find the build.bat file and run it!
keymap('n', '<Leader>bb', ':!.\\build %:p:h<CR>', opts)
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

-- keymap('v', 'p', '"_dP', opts)
-- Keep paste/delete buffer clean
keymap("x", "<leader>p", [["_dP]])
keymap({ "n", "v" }, "<leader>y", [["+y]])
keymap("n", "<leader>Y", [["+Y]])
keymap({ "n", "v" }, "<leader>d", [["_d]])

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

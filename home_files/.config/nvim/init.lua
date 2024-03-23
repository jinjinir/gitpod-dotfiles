-- Daryl's Personal init.lua config for neovim (in cases where I cannot use emacs :(

-- lazy.nvim package manager
-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' ' -- Make sure to set `mapleader` before lazy so your mappings are correct
vim.g.maplocalleader = ' '

-- autoformat on save based on lsp
vim.cmd [[autocmd BufWritePre * lua vim.lsp.buf.format()]]

-- [[ Install `lazy.nvim` plugin manager ]]
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
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

-- vim api configs start
vim.api.nvim_create_autocmd({ "FileType" }, {
        group = vim.api.nvim_create_augroup("edit_text", { clear = true }),
        pattern = { "gitcommit", "markdown", "txt" },
        desc = "Enable spell checking and text wrapping for certain filetypes",
        callback = function()
                vim.opt_local.wrap = true
                vim.opt_local.spell = true
        end,
})

-- Harpoon keymaps
vim.keymap.set('n', '<leader>ms', ":Telescope harpoon marks<CR>",
        { desc = 'Telescope Harpoon [M]arks [S]earch' })

vim.api.nvim_set_keymap("n", "<leader>mm",
        ":lua require('harpoon.mark').add_file()<CR>",
        { noremap = true, desc = 'Harpoon Set [M]arks' })

vim.api.nvim_set_keymap("n", "<leader>mq",
        ":lua require('harpoon.ui').toggle_quick_menu()",
        { noremap = true, desc = 'Harpoon [Q]uick Menu' })

vim.api.nvim_create_user_command("ToggleESLint", function()
        require("null-ls").toggle("eslint")
end, {})
-- vim api configs end

-- [[ Configure plugins ]]
-- NOTE: Here is where you install your plugins.
--  You can configure plugins using the `config` key.
--
--  You can also configure plugins after the setup call,
--    as they will be available in your neovim runtime.
require('lazy').setup({
        -- NOTE: First, some plugins that don't require any configuration

        -- Git related plugins
        {
                'tpope/vim-fugitive',
                event = "VeryLazy",
        },
        {
                'tpope/vim-rhubarb',
                event = "VeryLazy",
        },
        -- Primagen plugins
        {
                "ThePrimeagen/harpoon",
                dependencies = { "nvim-lua/plenary.nvim" },
                event = "VimEnter",
                branch = "harpoon2",
        },
        {
                'ThePrimeagen/git-worktree.nvim',
                event = "VeryLazy",
        },
        -- Detect tabstop and shiftwidth automatically
        {
                'tpope/vim-sleuth',
                event = "VeryLazy",
        },
        -- Undo Tree
        {
                'mbbill/undotree',
                event = "VeryLazy",
                vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle)
        },
        -- NOTE: This is where your plugins related to LSP can be installed.
        --  The configuration is done below.
        -- Search for lspconfig to find it below.
        {
                -- LSP Configuration & Plugins
                'neovim/nvim-lspconfig',
                event = { "BufReadPost" },
                dependencies = {
                        -- Automatically install LSPs to stdpath for neovim
                        'williamboman/mason.nvim',
                        'williamboman/mason-lspconfig.nvim',
                        -- Install none-ls for diagnostics, code actions,
                        -- and formatting
                        "nvimtools/none-ls.nvim",

                        -- Useful status updates for LSP
                        -- NOTE: `opts = {}` is the same as calling
                        -- `require('fidget').setup({})`
                        {
                                "j-hui/fidget.nvim",
                                tag = "legacy",
                                event = { "BufEnter" },
                        },
                        -- Additional lua configuration, makes nvim stuff amazing!
                        'folke/neodev.nvim',
                },
        },
        {
                -- Autocompletion
                'hrsh7th/nvim-cmp',
                event = { "BufReadPost", "BufNewFile" },
                dependencies = {
                        -- Snippet Engine & its associated nvim-cmp source
                        'L3MON4D3/LuaSnip',
                        'saadparwaiz1/cmp_luasnip',
                        -- Adds LSP completion capabilities
                        'hrsh7th/cmp-nvim-lsp',
                        'hrsh7th/cmp-path',
                        -- Adds a number of user-friendly snippets
                        'rafamadriz/friendly-snippets',
                        "hrsh7th/cmp-buffer",
                        "onsails/lspkind.nvim",
                },
        },
        -- Useful plugin to show you pending keybinds.
        {
                'folke/which-key.nvim',
                event = "VeryLazy",
                opts = {}
        },
        {
                -- Adds git related signs to the gutter,
                -- as well as utilities for managing changes
                'lewis6991/gitsigns.nvim',
                event = "VeryLazy",
                opts = {
                        -- See `:help gitsigns.txt`
                        signs = {
                                add = { text = '+' },
                                change = { text = '~' },
                                delete = { text = '_' },
                                topdelete = { text = '‾' },
                                changedelete = { text = '~' },
                        },
                        on_attach = function(bufnr)
                                local gs = package.loaded.gitsigns
                                local function map(mode, l, r, opts)
                                        opts = opts or {}
                                        opts.buffer = bufnr
                                        vim.keymap.set(mode, l, r, opts)
                                end

                                -- Navigation
                                map({ 'n', 'v' }, ']c', function()
                                        if vim.wo.diff then
                                                return ']c'
                                        end
                                        vim.schedule(function()
                                                gs.next_hunk()
                                        end)
                                        return '<Ignore>'
                                end, { expr = true, desc = 'Jump to next hunk' })

                                map({ 'n', 'v' }, '[c', function()
                                        if vim.wo.diff then
                                                return '[c'
                                        end
                                        vim.schedule(function()
                                                gs.prev_hunk()
                                        end)
                                        return '<Ignore>'
                                end, { expr = true, desc = 'Jump to previous hunk' })

                                -- Actions
                                -- visual mode
                                map('v', '<leader>hs', function()
                                        gs.stage_hunk { vim.fn.line '.',
                                                vim.fn.line 'v' }
                                end, { desc = 'stage git hunk' })

                                map('v', '<leader>hr', function()
                                        gs.reset_hunk { vim.fn.line '.',
                                                vim.fn.line 'v' }
                                end, { desc = 'reset git hunk' })

                                -- normal mode
                                map('n', '<leader>hs', gs.stage_hunk,
                                        { desc = 'git stage hunk' })

                                map('n', '<leader>hr', gs.reset_hunk,
                                        { desc = 'git reset hunk' })

                                map('n', '<leader>hS', gs.stage_buffer,
                                        { desc = 'git Stage buffer' })

                                map('n', '<leader>hu', gs.undo_stage_hunk,
                                        { desc = 'undo stage hunk' })

                                map('n', '<leader>hR', gs.reset_buffer,
                                        { desc = 'git Reset buffer' })

                                map('n', '<leader>hp', gs.preview_hunk,
                                        { desc = 'preview git hunk' })

                                map('n', '<leader>hb', function()
                                        gs.blame_line { full = false }
                                end, { desc = 'git blame line' })

                                map('n', '<leader>hd', gs.diffthis,
                                        { desc = 'git diff against index' })

                                map('n', '<leader>hD', function()
                                        gs.diffthis '~'
                                end, { desc = 'git diff against last commit' })

                                -- Toggles
                                map('n', '<leader>tb',
                                        gs.toggle_current_line_blame,
                                        { desc = 'toggle git blame line' })

                                map('n', '<leader>td', gs.toggle_deleted,
                                        { desc = 'toggle git show deleted' })

                                -- Text object
                                map({ 'o', 'x' }, 'ih',
                                        ':<C-U>Gitsigns select_hunk<CR>',
                                        { desc = 'select git hunk' })
                        end,
                },
        },
        {
                'windwp/nvim-autopairs',
                event = "InsertEnter",
                opts = {} -- this is equalent to setup({}) function
        },
        -- Theme from Catppuccin
        {
                "catppuccin/nvim",
                config = function()
                        require("catppuccin").setup({
                                integrations = {
                                        cmp = true,
                                        gitsigns = true,
                                        harpoon = true,
                                        illuminate = true,
                                        indent_blankline = {
                                                enabled = false,
                                                scope_color = "sapphire",
                                                colored_indent_levels = false,
                                        },
                                        mason = true,
                                        native_lsp = { enabled = true },
                                        notify = true,
                                        nvimtree = true,
                                        neotree = true,
                                        symbols_outline = true,
                                        telescope = true,
                                        treesitter = true,
                                        treesitter_context = true,
                                },
                        })
                        vim.cmd.colorscheme("catppuccin-macchiato")
                        -- Hide all semantic highlights until upstream issues are resolved (https://github.com/catppuccin/nvim/issues/480)
                        for _, group in ipairs(vim.fn.getcompletion("@lsp", "highlight")) do
                                vim.api.nvim_set_hl(0, group, {})
                        end
                end,
        },
        -- Neotree
        {
                "nvim-neo-tree/neo-tree.nvim",
                event = "VeryLazy",
                branch = "v3.x",
                dependencies = {
                        "nvim-lua/plenary.nvim",
                        "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
                        "MunifTanjim/nui.nvim",
                        "3rd/image.nvim",              -- Optional image support in preview window: See `# Preview Mode` for more information
                }
        },
        {
                "epwalsh/obsidian.nvim",
                event = "VeryLazy",
                version = "*", -- recommended, use latest release instead of latest commit
                lazy = true,
                ft = "markdown",
                -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
                -- event = {
                --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
                --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/**.md"
                --   "BufReadPre path/to/my-vault/**.md",
                --   "BufNewFile path/to/my-vault/**.md",
                -- },
                dependencies = {
                        -- Required.
                        "nvim-lua/plenary.nvim",

                        -- see below for full list of optional dependencies 👇
                },
                opts = {
                        workspaces = {
                                {
                                        name = "personal",
                                        path = "~/vaults/personal",
                                },
                                {
                                        name = "work",
                                        path = "~/vaults/work",
                                },
                        },

                        -- see below for full list of options 👇
                },
        },
        -- Flash - similar to vim sneak or evilsnipe
        {
                "folke/flash.nvim",
                event = "VeryLazy",
                ---@type Flash.Config
                opts = {},
                -- stylua: ignore
                keys = {
                        {
                                "s",
                                mode = { "n", "x", "o" },
                                function() require("flash").jump() end,
                                desc = "Flash"
                        },
                        {
                                "S",
                                mode = { "n", "x", "o" },
                                function() require("flash").treesitter() end,
                                desc = "Flash Treesitter"
                        },
                        {
                                "r",
                                mode = "o",
                                function() require("flash").remote() end,
                                desc = "Remote Flash"
                        },
                        {
                                "R",
                                mode = { "o", "x" },
                                function() require("flash").treesitter_search() end,
                                desc = "Treesitter Search"
                        },
                        {
                                "<c-s>",
                                mode = { "c" },
                                function() require("flash").toggle() end,
                                desc = "Toggle Flash Search"
                        },
                },
        },
        -- Surround nvim configuration
        {
                "kylechui/nvim-surround",
                version = "*", -- Use for stability;
                -- omit to use `main` branch for the latest features
                event = "VeryLazy",
                config = function()
                        -- Configuration here, or leave empty to use defaults
                        require("nvim-surround").setup({
                        })
                end
        },
        -- chatgpt ai assistant
        {
                "jinjinir/ChatGPT.nvim",
                event = "VeryLazy",
                config = function()
                        require("chatgpt").setup()
                end,
                dependencies = {
                        "MunifTanjim/nui.nvim",
                        "nvim-lua/plenary.nvim",
                        "nvim-telescope/telescope.nvim"
                }
        },
        -- Markdown preview install without yarn or npm
        {
                "iamcco/markdown-preview.nvim",
                cmd = { "MarkdownPreviewToggle", "MarkdownPreview",
                        "MarkdownPreviewStop" },
                ft = { "markdown" },
                build = function() vim.fn["mkdp#util#install"]() end,
        },
        -- Set lualine as statusline
        {
                "nvim-lualine/lualine.nvim",
                event = "VeryLazy",
                config = function()
                        -- TODO commented because of breaking changes in lualine
                        -- local harpoon = require("harpoon.mark")

                        local function truncate_branch_name(branch)
                                if not branch or branch == "" then
                                        return ""
                                end

                                -- Match the branch name to the specified format
                                local _, _, ticket_number = string.find(branch,
                                        "skdillon/sko%-(%d+)%-")

                                -- If the branch name matches the format,
                                -- display sko-{ticket_number},
                                -- otherwise display the full branch name
                                if ticket_number then
                                        return "sko-" .. ticket_number
                                else
                                        return branch
                                end
                        end

                        local function harpoon_component()
                                local total_marks = harpoon.get_length()

                                if total_marks == 0 then
                                        return ""
                                end

                                local current_mark = "—"

                                local mark_idx = harpoon.get_current_index()
                                if mark_idx ~= nil then
                                        current_mark = tostring(mark_idx)
                                end

                                return string.format("󱡅 %s/%d", current_mark,
                                        total_marks)
                        end

                        require("lualine").setup({
                                options = {
                                        theme = "catppuccin",
                                        globalstatus = true,
                                        component_separators = {
                                                left = "",
                                                right = ""
                                        },
                                        section_separators = {
                                                left = "█",
                                                right = "█"
                                        },
                                },
                                sections = {
                                        lualine_b = {
                                                {
                                                        "branch",
                                                        icon = "",
                                                        fmt = truncate_branch_name
                                                },
                                                harpoon_component,
                                                "diff",
                                                "diagnostics",
                                        },
                                        lualine_c = {
                                                { "filename", path = 1 },
                                        },
                                        lualine_x = {
                                                "filetype",
                                        },
                                },
                        })
                end,
        },
        {
                -- Add indentation guides even on blank lines
                'lukas-reineke/indent-blankline.nvim',
                event = "BufEnter",
                -- Enable `lukas-reineke/indent-blankline.nvim`
                -- See `:help ibl`
                main = 'ibl',
                opts = {},
        },

        -- "gc" to comment visual regions/lines
        {
                'numToStr/Comment.nvim',
                event = "VeryLazy",
                opts = {}
        },

        -- replace noice.nvim with dressing, nvim notify, and wilder
        {
                "rcarriga/nvim-notify",
                event = "VeryLazy",
                config = function()
                        local notify = require("notify")

                        local filtered_message = { "No information available" }

                        -- Override notify function to filter out messages
                        --@diagnostic disable-next-line: duplicate-set-field
                        vim.notify = function(message, level, opts)
                                local merged_opts = vim.tbl_extend("force", {
                                        on_open = function(win)
                                                local buf = vim.api.nvim_win_get_buf(win)
                                                vim.api.nvim_buf_set_option(buf,
                                                        "filetype", "markdown")
                                        end,
                                }, opts or {})

                                for _, msg in ipairs(filtered_message) do
                                        if message == msg then
                                                return
                                        end
                                end
                                return notify(message, level, merged_opts)
                        end

                        -- Update colors to use catpuccino colors
                        vim.cmd([[
        highlight NotifyERRORBorder guifg=#ed8796
        highlight NotifyERRORIcon guifg=#ed8796
        highlight NotifyERRORTitle  guifg=#ed8796
        highlight NotifyINFOBorder guifg=#8aadf4
        highlight NotifyINFOIcon guifg=#8aadf4
        highlight NotifyINFOTitle guifg=#8aadf4
        highlight NotifyWARNBorder guifg=#f5a97f
        highlight NotifyWARNIcon guifg=#f5a97f
        highlight NotifyWARNTitle guifg=#f5a97f
        ]])
                end,
        },
        {
                "stevearc/dressing.nvim",
                event = "VeryLazy",
                config = function()
                        require("dressing").setup()
                end,
        },
        {
                "gelguy/wilder.nvim",
                keys = {
                        ":",
                        "/",
                        "?",
                },
                dependencies = {

                        "catppuccin/nvim",
                },
                config = function()
                        local wilder = require("wilder")
                        local macchiato =
                            require("catppuccin.palettes").get_palette("macchiato")

                        -- Create a highlight group for the popup menu
                        local text_highlight =
                            wilder.make_hl("WilderText", { { a = 1 },
                                    { a = 1 },
                                    { foreground = macchiato.text } })
                        local mauve_highlight =
                            wilder.make_hl("WilderMauve", { { a = 1 },
                                    { a = 1 },
                                    { foreground = macchiato.mauve } })

                        -- Enable wilder when pressing :, / or ?
                        wilder.setup({ modes = { ":", "/", "?" } })

                        -- Enable fuzzy matching for commands and buffers
                        wilder.set_option("pipeline", {
                                wilder.branch(
                                        wilder.cmdline_pipeline({
                                                fuzzy = 1,
                                        }),
                                        wilder.vim_search_pipeline({
                                                fuzzy = 1,
                                        })
                                ),
                        })

                        wilder.set_option(
                                "renderer",
                                wilder.popupmenu_renderer(wilder.popupmenu_border_theme({
                                        highlighter = wilder.basic_highlighter(),
                                        highlights = {
                                                default = text_highlight,
                                                border = mauve_highlight,
                                                accent = mauve_highlight,
                                        },
                                        pumblend = 5,
                                        min_width = "100%",
                                        min_height = "25%",
                                        max_height = "25%",
                                        border = "rounded",
                                        left = { " ", wilder.popupmenu_devicons() },
                                        right = { " ", wilder.popupmenu_scrollbar() },
                                }))
                        )
                end,
        },
        {
                "RRethy/vim-illuminate",
                lazy = true,
                config = function()
                        require("illuminate").configure({
                                under_cursor = false,
                                filetypes_denylist = {
                                        "DressingSelect",
                                        "Outline",
                                        "TelescopePrompt",
                                        "alpha",
                                        "harpoon",
                                        "toggleterm",
                                        "neo-tree",
                                        "Spectre",
                                        "reason",
                                },
                        })
                end,
        },
        -- oil.nvim: a better netrw
        -- {
        --   "stevearc/oil.nvim",
        --   opts = {},
        --   -- Optional dependencies
        --   dependencies = { "nvim-tree/nvim-web-devicons" },
        --   config = function()
        --     require("oil").setup({
        --       keymaps = {
        --         ["g?"] = "actions.show_help",
        --         ["<CR>"] = "actions.select",
        --         ["<C-\\>"] = "actions.select_vsplit",
        --         ["<C-enter>"] = "actions.select_split", -- this is used to navigate left
        --         ["<C-t>"] = "actions.select_tab",
        --         ["<C-p>"] = "actions.preview",
        --         ["<C-c>"] = "actions.close",
        --         ["<C-r>"] = "actions.refresh",
        --         ["-"] = "actions.parent",
        --         ["_"] = "actions.open_cwd",
        --         ["`"] = "actions.cd",
        --         ["~"] = "actions.tcd",
        --         ["gs"] = "actions.change_sort",
        --         ["gx"] = "actions.open_external",
        --         ["g."] = "actions.toggle_hidden",
        --       },
        --       use_default_keymaps = false,
        --     })
        --   end,
        -- },
        -- trouble.nvim : show the troubles the code is causing
        {
                "folke/trouble.nvim",
                event = "VeryLazy",
                dependencies = { "nvim-tree/nvim-web-devicons" },
                opts = {
                        -- your configuration comes here
                        -- or leave it empty to use the default settings
                        -- refer to the configuration section below
                },
                -- Lua
                vim.keymap.set("n", "<leader>xx",
                        function() require("trouble").toggle() end,
                        { desc = '[XX] Toggle Trouble' }),
                vim.keymap.set("n", "<leader>xw",
                        function() require("trouble").toggle("workspace_diagnostics") end,
                        { desc = '[X] [W]orkspace' }),
                vim.keymap.set("n", "<leader>xd",
                        function() require("trouble").toggle("document_diagnostics") end,
                        { desc = '[X] [D]iagnostics' }),
                vim.keymap.set("n", "<leader>xq",
                        function() require("trouble").toggle("quickfix") end,
                        { desc = '[X] [Q]uickfix' }),
                vim.keymap.set("n", "<leader>xl",
                        function() require("trouble").toggle("loclist") end,
                        { desc = '[X] Loclist' }),
                -- TODO find out what this does
                vim.keymap.set("n", "gR",
                        function() require("trouble").toggle("lsp_references") end,
                        { desc = '[X] LSP [R]eferences' }),
        },
        -- Fuzzy Finder (files, lsp, etc)
        {
                'nvim-telescope/telescope.nvim',
                branch = '0.1.x',
                dependencies = {
                        'nvim-lua/plenary.nvim',
                        -- Fuzzy Finder Algorithm which requires local dependencies to be built.
                        -- Only load if `make` is available. Make sure you have the system
                        -- requirements installed.
                        {
                                'nvim-telescope/telescope-fzf-native.nvim',
                                -- NOTE: If you are having trouble with this
                                -- installation, refer to the README for
                                -- telescope-fzf-native for more instructions.
                                build = 'make',
                                cond = function()
                                        return vim.fn.executable 'make' == 1
                                end,
                        },
                },
        },
        {
                -- Highlight, edit, and navigate code
                'nvim-treesitter/nvim-treesitter',
                dependencies = {
                        'nvim-treesitter/nvim-treesitter-textobjects',
                },
                build = ':TSUpdate',
        },
        -- lazy.nvim
        -- Start from kickstart nvim repo
        -- NOTE: Next Step on Your Neovim Journey: Add/Configure additional
        -- "plugins" for kickstart. These are some example plugins that I've
        -- included in the kickstart repository. Uncomment any of the lines
        -- below to enable them.
        -- require 'kickstart.plugins.autoformat',
        -- require 'kickstart.plugins.debug',

        -- NOTE: The import below can automatically add your own plugins,
        -- configuration, etc from `lua/custom/plugins/*.lua`
        -- You can use this folder to prevent any conflicts with this init.lua
        -- if you're interested in keeping up-to-date with whatever is in the
        -- kickstart repo. Uncomment the following line and add your plugins to
        -- `lua/custom/plugins/*.lua` to get going.
        --
        --    For additional information see:
        -- https://github.com/folke/lazy.nvim#-structuring-your-plugins
        -- { import = 'custom.plugins' },
        -- Stop from kickstart nvim repo
}, {})
-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!

-- Set highlight on search
vim.o.hlsearch = true

-- Make line numbers default
vim.wo.number = true

-- Make line relative numbers default
vim.wo.relativenumber = true

-- Enable mouse mode
vim.o.mouse = 'a'

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.o.clipboard = 'unnamedplus'

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menu,menuone,noselect'

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

-- confirm to save changes before exiting
vim.o.confirm = true

-- use spaces instead of tabs
vim.o.expandtab = true

-- use rg instead of grep
vim.o.grepprg = "rg --vimgrep --smart-case --"

-- preview incremental substitute
vim.o.inccommand = "nosplit"

-- minimal number of screenlines to keep above and below the cursor
vim.wo.scrolloff = 4

-- round indent
vim.o.shiftround = true

--show tabs; 0 never, 1 if at least 2 tabs, 2 always
vim.o.showtabline = 1

-- minimal number of screenlines to keep above and below the cursor
vim.wo.sidescrolloff = 6

-- inserts indents automatically
vim.o.smartindent = true

-- force all horizontal splits to go below current window
vim.o.splitbelow = true

-- force all vertical splits to go to the right of the current window
vim.o.splitright = true

-- set case is ignored when completing file names and directories
vim.o.wildignorecase = true

-- set colorcolumn to 80 characters
vim.o.colorcolumn = "80"

-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'",
        { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'",
        { expr = true, silent = true })

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev,
        { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next,
        { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float,
        { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist,
        { desc = 'Open diagnostics list' })

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight',
        { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
        callback = function()
                vim.highlight.on_yank()
        end,
        group = highlight_group,
        pattern = '*',
})

-- [[ Configure Telescope ]]
-- See `:help telescope` and `:help telescope.setup()`
require('telescope').setup {
        defaults = {
                mappings = {
                        i = {
                                ['<C-u>'] = false,
                                ['<C-d>'] = false,
                        },
                },
        },
}

-- Enable telescope fzf native, if installed
pcall(require('telescope').load_extension, 'fzf')

-- Telescope live_grep in git root
-- Function to find the git root directory based on the current buffer's path
local function find_git_root()
        -- Use the current buffer's path as the starting point for the git search
        local current_file = vim.api.nvim_buf_get_name(0)
        local current_dir
        local cwd = vim.fn.getcwd()
        -- If the buffer is not associated with a file, return nil
        if current_file == '' then
                current_dir = cwd
        else
                -- Extract the directory from the current file's path
                current_dir = vim.fn.fnamemodify(current_file, ':h')
        end

        -- Find the Git root directory from the current file's path
        local git_root =
            vim.fn.systemlist('git -C ' .. vim.fn.escape(current_dir, ' ') .. ' rev-parse --show-toplevel')
            [1]
        if vim.v.shell_error ~= 0 then
                print 'Not a git repository. Searching on current working directory'
                return cwd
        end
        return git_root
end

-- Custom live_grep function to search in git root
local function live_grep_git_root()
        local git_root = find_git_root()
        if git_root then
                require('telescope.builtin').live_grep {
                        search_dirs = { git_root },
                }
        end
end

vim.api.nvim_create_user_command('LiveGrepGitRoot', live_grep_git_root, {})

-- See `:help telescope.builtin`
vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles,
        { desc = '[?] Find recently opened files' })
vim.keymap.set('n', '<leader><space>', require('telescope.builtin').buffers,
        { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>/', function()
        -- You can pass additional configuration to telescope to change theme, layout, etc.
        require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                winblend = 10,
                previewer = false,
        })
end, { desc = '[/] Fuzzily search in current buffer' })

local function telescope_live_grep_open_files()
        require('telescope.builtin').live_grep {
                grep_open_files = true,
                prompt_title = 'Live Grep in Open Files',
        }
end

vim.keymap.set('n', '<leader>s/', telescope_live_grep_open_files,
        { desc = '[S]earch [/] in Open Files' })
vim.keymap.set('n', '<leader>ss', require('telescope.builtin').builtin,
        { desc = '[S]earch [S]elect Telescope' })
vim.keymap.set('n', '<leader>gf', require('telescope.builtin').git_files,
        { desc = 'Search [G]it [F]iles' })
vim.keymap.set('n', '<leader>sf', require('telescope.builtin').find_files,
        { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags,
        { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string,
        { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep,
        { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sG', ':LiveGrepGitRoot<cr>',
        { desc = '[S]earch by [G]rep on Git Root' })
vim.keymap.set('n', '<leader>sd', require('telescope.builtin').diagnostics,
        { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', require('telescope.builtin').resume,
        { desc = '[S]earch [R]esume' })

-- Git Worktree setup
require('git-worktree').setup()
require('telescope').load_extension('git_worktree')
vim.keymap.set('n', '<leader>gws',
        "<CMD>lua require('telescope').extensions.git_worktree.git_worktrees()<CR>",
        { desc = '[G]it [W]orktree [S]earch' })
vim.keymap.set('n', '<leader>gwc',
        "<CMD>lua require('telescope').extensions.git_worktree.create_git_worktree()<CR>",
        { desc = '[G]it [W]orktree [C]reate' })



-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter`
-- Defer Treesitter setup after first render to improve startup time of
-- 'nvim {filename}'
vim.defer_fn(function()
        require('nvim-treesitter.configs').setup {
                -- Add languages to be installed here that you want installed
                -- for treesitter
                ensure_installed = {
                        'bash',
                        'c',
                        'cmake',
                        'cpp',
                        'css',
                        'dockerfile',
                        'go',
                        'html',
                        'javascript',
                        'json',
                        'jsonc',
                        'lua',
                        'markdown',
                        'markdown_inline',
                        'python',
                        'regex',
                        'rust',
                        'terraform',
                        'tsx',
                        'typescript',
                        'vim',
                        'vimdoc',
                },

                -- Autoinstall languages that are not installed. Defaults to
                -- false (but you can change for yourself!)
                auto_install = true,
                autotag = {
                        enable = true,
                },

                highlight = { enable = true },
                indent = { enable = true },
                incremental_selection = {
                        enable = true,
                        keymaps = {
                                init_selection = '<c-space>',
                                node_incremental = '<c-space>',
                                scope_incremental = '<c-s>',
                                node_decremental = '<M-space>',
                        },
                },
                textobjects = {
                        select = {
                                enable = true,
                                -- Automatically jump forward to textobj,
                                -- similar to targets.vim
                                lookahead = true,
                                keymaps = {
                                        -- You can use the capture groups
                                        -- defined in textobjects.scm
                                        ['aa'] = '@parameter.outer',
                                        ['ia'] = '@parameter.inner',
                                        ['af'] = '@function.outer',
                                        ['if'] = '@function.inner',
                                        ['ac'] = '@class.outer',
                                        ['ic'] = '@class.inner',
                                },
                        },
                        move = {
                                enable = true,
                                -- whether to set jumps in the jumplist
                                set_jumps = true,
                                goto_next_start = {
                                        [']m'] = '@function.outer',
                                        [']]'] = '@class.outer',
                                },
                                goto_next_end = {
                                        [']M'] = '@function.outer',
                                        [']['] = '@class.outer',
                                },
                                goto_previous_start = {
                                        ['[m'] = '@function.outer',
                                        ['[['] = '@class.outer',
                                },
                                goto_previous_end = {
                                        ['[M'] = '@function.outer',
                                        ['[]'] = '@class.outer',
                                },
                        },
                        swap = {
                                enable = true,
                                swap_next = {
                                        ['<leader>a'] = '@parameter.inner',
                                },
                                swap_previous = {
                                        ['<leader>A'] = '@parameter.inner',
                                },
                        },
                },
        }
end, 0)

-- [[ Configure LSP ]]
--  This function gets run when an LSP connects to a particular buffer.
local on_attach = function(_, bufnr)
        -- NOTE: Remember that lua is a real programming language, and as such
        --it is possible to define small helper and utility functions so you
        -- don't have to repeat yourself many times.
        -- In this case, we create a function that lets us more easily define
        -- mappings specific for LSP related items. It sets the mode, buffer
        -- and description for us each time.
        local nmap = function(keys, func, desc)
                if desc then
                        desc = 'LSP: ' .. desc
                end

                vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
        end

        nmap('<leader>rn', vim.lsp.buf.rename,
                '[R]e[n]ame')
        nmap('<leader>ca', vim.lsp.buf.code_action,
                '[C]ode [A]ction')
        nmap('gd', require('telescope.builtin').lsp_definitions,
                '[G]oto [D]efinition')
        nmap('gr', require('telescope.builtin').lsp_references,
                '[G]oto [R]eferences')
        nmap('gI', require('telescope.builtin').lsp_implementations,
                '[G]oto [I]mplementation')
        nmap('<leader>D', require('telescope.builtin').lsp_type_definitions,
                'Type [D]efinition')
        nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols,
                '[D]ocument [S]ymbols')
        nmap('<leader>ws',
                require('telescope.builtin').lsp_dynamic_workspace_symbols,
                '[W]orkspace [S]ymbols')

        -- See `:help K` for why this keymap
        nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
        nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

        -- Lesser used LSP functionality
        nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
        nmap('<leader>wa', vim.lsp.buf.add_workspace_folder,
                '[W]orkspace [A]dd Folder')
        nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder,
                '[W]orkspace [R]emove Folder')
        nmap('<leader>wl', function()
                print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, '[W]orkspace [L]ist Folders')

        -- Create a command `:Format` local to the LSP buffer
        vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
                vim.lsp.buf.format()
        end, { desc = 'Format current buffer with LSP' })
end

-- document existing key chains
require('which-key').register {
        ['<leader>c'] = { name = '[C]ode', _ = 'which_key_ignore' },
        ['<leader>d'] = { name = '[D]ocument', _ = 'which_key_ignore' },
        ['<leader>g'] = { name = '[G]it', _ = 'which_key_ignore' },
        ['<leader>h'] = { name = 'Git [H]unk', _ = 'which_key_ignore' },
        ['<leader>m'] = { name = 'Harpoon [M]arks', _ = 'which_key_ignore' },
        ['<leader>r'] = { name = '[R]ename', _ = 'which_key_ignore' },
        ['<leader>s'] = { name = '[S]earch', _ = 'which_key_ignore' },
        ['<leader>t'] = { name = '[T]oggle', _ = 'which_key_ignore' },
        ['<leader>u'] = { name = '[U]ndo Tree', _ = 'which_key_ignore' },
        ['<leader>w'] = { name = '[W]orkspace', _ = 'which_key_ignore' },
        ['<leader>x'] = { name = '[X]Trouble', _ = 'which_key_ignore' },
}

-- register which-key VISUAL mode
-- required for visual <leader>hs (hunk stage) to work
require('which-key').register({
        ['<leader>'] = { name = 'VISUAL <leader>' },
        ['<leader>h'] = { 'Git [H]unk' },
}, { mode = 'v' })

-- mason-lspconfig requires that these setup functions are called in this order
-- before setting up the servers.
require('mason').setup()
require('mason-lspconfig').setup()

-- Enable the following language servers
-- Feel free to add/remove any LSPs that you want here. They will automatically
-- be installed.
-- Add any additional override configuration in the following tables. They will
-- be passed to the `settings` field of the server config. You must look up that
-- documentation yourself.
-- If you want to override the default filetypes that your language server will
-- attach to you can define the property 'filetypes' to the map in question.
local servers = {
        -- clangd = {},
        gopls = {},
        -- pyright = {},
        -- rust_analyzer = {},
        -- tsserver = {},
        bashls = {},
        dockerls = {},
        html = { filetypes = { 'html', 'twig', 'hbs' } },
        jsonls = {},
        marksman = {},
        tailwindcss = {},
        terraformls = {},
        -- commented yamlls as it's throwing errors
        -- yamlls = {},
        lua_ls = {
                Lua = {
                        workspace = { checkThirdParty = false },
                        telemetry = { enable = false },
                        -- NOTE: toggle below to ignore Lua_LS's noisy
                        --`missing-fields` warnings
                        -- diagnostics = { disable = { 'missing-fields' } },
                },
        },
}

-- Setup neovim lua configuration
require('neodev').setup()

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- Ensure the servers above are installed
local mason_lspconfig = require 'mason-lspconfig'

mason_lspconfig.setup {
        ensure_installed = vim.tbl_keys(servers),
}

mason_lspconfig.setup_handlers {
        function(server_name)
                require('lspconfig')[server_name].setup {
                        capabilities = capabilities,
                        on_attach = on_attach,
                        settings = servers[server_name],
                        filetypes = (servers[server_name] or {}).filetypes,
                }
        end,
}

-- [[ Configure nvim-cmp ]]
-- See `:help cmp`
local cmp = require 'cmp'
local luasnip = require 'luasnip'
require('luasnip.loaders.from_vscode').lazy_load()
luasnip.config.setup {}

cmp.setup {
        snippet = {
                expand = function(args)
                        luasnip.lsp_expand(args.body)
                end,
        },
        completion = {
                completeopt = 'menu,menuone,noinsert',
        },
        mapping = cmp.mapping.preset.insert {
                ['<C-n>'] = cmp.mapping.select_next_item(),
                ['<C-p>'] = cmp.mapping.select_prev_item(),
                ['<C-d>'] = cmp.mapping.scroll_docs(-4),
                ['<C-f>'] = cmp.mapping.scroll_docs(4),
                ['<C-Space>'] = cmp.mapping.complete {},
                ['<CR>'] = cmp.mapping.confirm {
                        behavior = cmp.ConfirmBehavior.Replace,
                        select = true,
                },
                ['<Tab>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                                cmp.select_next_item()
                        elseif luasnip.expand_or_locally_jumpable() then
                                luasnip.expand_or_jump()
                        else
                                fallback()
                        end
                end, { 'i', 's' }),
                ['<S-Tab>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                                cmp.select_prev_item()
                        elseif luasnip.locally_jumpable(-1) then
                                luasnip.jump(-1)
                        else
                                fallback()
                        end
                end, { 'i', 's' }),
        },
        sources = {
                { name = 'nvim_lsp' },
                { name = 'path' },
                { name = "buffer",  max_item_count = 5 }, -- text within current buffer
                { name = 'luasnip' },
                { name = "copilot" },                     -- Copilot suggestions
        },
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et

-- from autocmds.lua
local api = vim.api

--- Remove all trailing whitespace on save
local TrimWhiteSpaceGrp = api.nvim_create_augroup("TrimWhiteSpaceGrp",
        { clear = true })
api.nvim_create_autocmd("BufWritePre", {
        command = [[:%s/\s\+$//e]],
        group = TrimWhiteSpaceGrp,
})

vim.api.nvim_create_autocmd("BufEnter", {
        callback = function()
                vim.opt.formatoptions:remove({ "c", "r", "o" })
        end,
        desc = "Disable New Line Comment",
})

api.nvim_create_autocmd("Filetype", {
        pattern = "mail",
        callback = function()
                vim.opt.textwidth = 0
                vim.opt.wrapmargin = 0
                vim.opt.wrap = true
                vim.opt.linebreak = true
                vim.opt.columns = 80
                vim.opt.colorcolumn = "80"
        end,
        desc = "wrap words 'softly' (no carriage return) in mail buffer",
})

api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = { "*.typ" },
        callback = function()
                vim.api.nvim_command("set filetype=typst")
        end,
        desc = "detect typst filetype",
})

-- https://github.com/hashicorp/terraform-ls/blob/main/docs/USAGE.md
-- expects a terraform filetype and not a tf filetype
api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = { "*.tf" },
        callback = function()
                vim.api.nvim_command("set filetype=terraform")
        end,
        desc = "detect terraform filetype",
})

api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = "terraform-vars",
        callback = function()
                vim.api.nvim_command("set filetype=hcl")
        end,
        desc = "detect terraform vars",
})

api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        group = vim.api.nvim_create_augroup("FixTerraformCommentString",
                { clear = true }),
        callback = function(ev)
                vim.bo[ev.buf].commentstring = "# %s"
        end,
        pattern = { "*tf" },
        desc = "fix terraform and hcl comment string",
})

api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        group = vim.api.nvim_create_augroup("FixNixCommentString",
                { clear = true }),
        callback = function(ev)
                vim.bo[ev.buf].commentstring = "# %s"
        end,
        pattern = { "*.nix" },
        desc = "fix nix comment string",
})

api.nvim_create_autocmd("BufReadPost", {
        callback = function()
                local mark = vim.api.nvim_buf_get_mark(0, '"')
                local lcount = vim.api.nvim_buf_line_count(0)
                if mark[1] > 0 and mark[1] <= lcount then
                        pcall(vim.api.nvim_win_set_cursor, 0, mark)
                end
        end,
        desc = "go to last loc when opening a buffer",
})

api.nvim_create_autocmd("FileType", {
        pattern = {
                "dap-float",
                "fugitive",
                "help",
                "man",
                "notify",
                "null-ls-info",
                "qf",
                "PlenaryTestPopup",
                "startuptime",
                "tsplayground",
                "spectre_panel",
        },
        callback = function(event)
                vim.bo[event.buf].buflisted = false
                vim.keymap.set("n", "q", "<cmd>close<cr>", {
                        buffer = event.buf,
                        silent = true
                })
        end,
        desc = "close certain windows with q",
})

api.nvim_create_autocmd("FileType", {
        pattern = "man",
        command = [[nnoremap <buffer><silent> q :quit<CR>]]
})

api.nvim_create_autocmd(
        "FileType",
        {
                pattern = { "NeoGitStatus" },
                command = [[setlocal list!]],
                desc = "disable list option in certain filetypes"
        }
)

local cursorGrp = api.nvim_create_augroup("CursorLine", { clear = true })
api.nvim_create_autocmd({ "InsertLeave", "WinEnter" }, {
        pattern = "*",
        command = "set cursorline",
        group = cursorGrp,
        desc = "show cursor line only in active window",
})

api.nvim_create_autocmd(
        { "InsertEnter", "WinLeave" },
        { pattern = "*", command = "set nocursorline", group = cursorGrp }
)

api.nvim_create_autocmd(
        { "BufRead", "BufNewFile" },
        -- { pattern = { "*.txt", "*.md", "*.tex" },
        -- command = [[setlocal spell<cr> setlocal spelllang=en,de<cr>]] }
        {
                pattern = { "*.txt", "*.org", "*.md", "*.tex", "*.typ" },
                callback = function()
                        vim.opt.spell = true
                        vim.opt.spelllang = "en"
                end,
                desc = "Enable spell checking for certain file types",
        }
)
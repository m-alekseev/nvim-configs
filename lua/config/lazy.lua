-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out,                            "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

local function find_python_venv()
	local venv_path = vim.fn.getcwd() .. "/.venv/bin/python"
	if vim.fn.filereadable(venv_path) == 1 then
		return venv_path
	else
		return nil
	end
end


-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- General Settings
-- vim.opt.tabstop = 4
-- vim.opt.shiftwidth = 4
-- vim.opt.expandtab = true
vim.opt.number = true
-- vim.opt.relativenumber = false
-- vim.opt.autoindent = true
-- vim.opt.smartindent = true
-- vim.opt.wrap = false
-- vim.opt.termguicolors = false
-- vim.opt.ignorecase = true

-- Keybindings
vim.keymap.set("n", "<leader>ff", ":Telescope find_files<CR>")
vim.keymap.set("n", "<leader>fg", ":Telescope live_grep<CR>")
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>")
vim.keymap.set("n", "<leader>f", ":lua vim.lsp.buf.format()<CR>")                -- Format with Ruff
vim.keymap.set("n", "<leader>d", ":lua vim.diagnostic.open_float()<CR>")         -- Show diagnostics
vim.keymap.set("n", "<leader>db", ":lua require('dap').toggle_breakpoint()<CR>") -- Toggle breakpoint
vim.keymap.set("n", "<leader>dc", ":lua require('dap').continue()<CR>")          -- Start debugging
vim.keymap.set("n", "<leader>do", ":lua require('dap').step_over()<CR>")         -- Step over
vim.keymap.set("n", "<leader>di", ":lua require('dap').step_into()<CR>")         -- Step into
vim.keymap.set("n", "<leader>du", ":lua require('dapui').toggle()<CR>")          -- Toggle debug UI

-- Setup lazy.nvim
local status_ok, err = pcall(require("lazy").setup, {
	spec = {
		{
			"vhyrro/luarocks.nvim",
			priority = 1000, -- Very high priority is required, luarocks.nvim should run as the first plugin in your config.
			config = true,
		},
		-- Theme
		{
			"Mofiqul/dracula.nvim", -- Modern Dracula theme
			priority = 1000, -- Ensure it loads early
			config = function()
				require("dracula").setup({
					transparent_bg = false, -- Enable transparent background
					italic_comments = true, -- Use italic for comments
				})
				vim.cmd([[colorscheme dracula]])
			end,
		},
		-- UI Enhancements
		{
			"nvim-lualine/lualine.nvim", -- Statusline
			dependencies = { "nvim-tree/nvim-web-devicons" }, -- Icons
			config = function()
				require("lualine").setup({
					options = {
						theme = "dracula",
						section_separators = { left = "", right = "" },
						component_separators = { left = "", right = "" },
					},
				})
			end,
		},
		-- File Explorer
		{
			"nvim-tree/nvim-tree.lua",
			dependencies = { "nvim-tree/nvim-web-devicons" },
			config = function()
				require("nvim-tree").setup({
					on_attach = function(bufnr)
						local api = require("nvim-tree.api")
						api.config.mappings.default_on_attach(bufnr)
						vim.keymap.set("n", "l", api.node.open.edit,
							{ buffer = bufnr, desc = "Open Folder or File" })
						vim.keymap.set("n", "h", api.node.navigate.parent_close,
							{ buffer = bufnr, desc = "Close Folder" })
					end,
				})
			end,
		},

		-- Fuzzy Finder
		{
			"nvim-telescope/telescope.nvim",
			dependencies = { "nvim-lua/plenary.nvim" },
			config = function()
				require("telescope").setup()
			end,
		},

		-- Syntax Highlighting
		{
			"nvim-treesitter/nvim-treesitter",
			build = ":TSUpdate",
			config = function()
				require("nvim-treesitter.configs").setup({
					ensure_installed = { "python", "lua", "vim", "vimdoc" },
					highlight = { enable = true },
					indent = { enable = true },
				})
			end,
		},
		-- Commenting Plugin
		{
			"numToStr/Comment.nvim", -- Commenting plugin
			config = function()
				require("Comment").setup({
					padding = true, -- Add a space after the comment symbol
					sticky = true, -- Keep cursor position when toggling comments
					mappings = {
						basic = true, -- Enable basic keybindings (e.g., `gcc`, `gbc`)
						extra = true, -- Enable extended keybindings (e.g., `gc`, `gb`)
					},
					ignore = "^$", -- Ignore empty lines when commenting
					toggler = {
						line = "<leader>/", -- Toggle comments for a single line
						block = "<leader>b", -- Toggle block comments (optional)
					},
					opleader = {
						line = "<leader>/", -- Operator-pending mode for lines
						block = "<leader>b", -- Operator-pending mode for blocks
					},
				})
			end,
		},
		-- LSP and Autocompletion
		{
			"neovim/nvim-lspconfig",
			dependencies = {
				"williamboman/mason.nvim",
				"williamboman/mason-lspconfig.nvim",
				"hrsh7th/nvim-cmp", -- Autocompletion framework
				"hrsh7th/cmp-nvim-lsp", -- LSP source for nvim-cmp
				"L3MON4D3/LuaSnip", -- Snippet engine
				"saadparwaiz1/cmp_luasnip", -- Snippets source for nvim-cmp
			},
			config = function()
				local lspconfig = require("lspconfig")
				local capabilities = require("cmp_nvim_lsp").default_capabilities()
				capabilities.textDocument.semanticTokens = true

				-- Setup Mason-LSPConfig
				require("mason-lspconfig").setup({
					ensure_installed = { "pyright", "lua_ls" }, -- Automatically install these LSP servers
				})

				-- Automatically configure installed LSP servers
				require("mason-lspconfig").setup_handlers({
					function(server_name)
						lspconfig[server_name].setup({
							capabilities = capabilities,
						})
					end,
				})

				-- Special Configuration for Pyright
				lspconfig.pyright.setup({
					capabilities = capabilities,
					settings = {
						python = {
							pythonPath = find_python_venv() or "python",
							analyis = {
								autoSearchPaths = true,
								diagnosticMode = "workspace", -- Enable workspace-wide diagnostics
								useLibraryCodeForTypes = true,
							},
						},
					},
				})

				-- lspconfig.gopls.setup({
				-- 	capabilities = capabilities,
				-- 	settings = {
				-- 		gopls = {
				-- 			analyses = {
				-- 				unusedparams = true,
				-- 				shadow = true,
				-- 			},
				-- 			staticcheck = true, -- Enable staticcheck for additional linting
				-- 			completeUnimported = true, -- Autocomplete unimported packages
				-- 			usePlaceholders = true, -- Use placeholders for function parameters
				-- 		},
				-- 	},
				-- })

				-- Autocompletion setup
				local cmp = require("cmp")
				cmp.setup({
					snippet = {
						expand = function(args)
							require("luasnip").lsp_expand(args.body)
						end,
					},
					sources = cmp.config.sources({
						{ name = "nvim_lsp" },
						{ name = "luasnip" },
					}),
					mapping = cmp.mapping.preset.insert({
						-- Navigate completions
						["<C-j>"] = cmp.mapping.select_next_item({
							behavior = cmp.SelectBehavior
							    .Select
						}),
						["<C-k>"] = cmp.mapping.select_prev_item({
							behavior = cmp.SelectBehavior
							    .Select
						}),
						-- Confirm completion with Tab or Enter
						["<Tab>"] = cmp.mapping.confirm({ select = true }), -- Confirm with Tab
						["<CR>"] = cmp.mapping.confirm({ select = true }), -- Confirm with Enter
						-- Other default mappings
						["<C-b>"] = cmp.mapping.scroll_docs(-4),
						["<C-f>"] = cmp.mapping.scroll_docs(4),
						["<C-Space>"] = cmp.mapping.complete(), -- Trigger completion menu
					}),
				})
			end,
		},

		-- Formatting and Linting with Mason and Null-LS
		{
			"jose-elias-alvarez/null-ls.nvim",
			dependencies = { "nvim-lua/plenary.nvim" }, -- Add plenary.nvim as a dependency
			config = function()
				local null_ls = require("null-ls")
				null_ls.setup({
					sources = {
						null_ls.builtins.formatting.ruff, -- Use Ruff for formatting
						null_ls.builtins.diagnostics.ruff, -- Use Ruff for linting
					},
				})
			end,
		},
		{
			"jayp0521/mason-null-ls.nvim", -- Bridge Mason and Null-LS
			dependencies = {
				"williamboman/mason.nvim",
				"jose-elias-alvarez/null-ls.nvim",
			},
			config = function()
				require("mason-null-ls").setup({
					ensure_installed = { "ruff" }, -- Automatically install these formatters/linters
				})
			end,
		},

		-- Debugging
		{
			"mfussenegger/nvim-dap", -- Core DAP plugin
			dependencies = {
				"rcarriga/nvim-dap-ui", -- UI for DAP
				"jayp0521/mason-nvim-dap.nvim", -- Bridge Mason and nvim-dap
			},
			config = function()
				-- Configure nvim-dap
				local dap = require("dap")
				dap.adapters.python = {
					type = "executable",
					command = "python",
					args = { "-m", "debugpy.adapter" },
				}
				dap.configurations.python = {
					{
						type = "python",
						request = "launch",
						name = "Launch file",
						program = "${file}", -- Debug the current file
						pythonPath = find_python_venv() or "python"
					},
					{
						type = "python",
						request = "launch",
						name = "Launch file with arguments",
						program = "${file}",
						args = function()
							local input = vim.fn.input("Enter arguments: ")
							return vim.split(input, " ")
						end,
						pythonPath = find_python_venv() or "python"
					},
				}

				-- Configure nvim-dap-ui
				require("dapui").setup()

				-- Automatically open/close DAP UI
				local dapui = require("dapui")
				dap.listeners.after.event_initialized["dapui_config"] = function()
					dapui.open()
				end
				dap.listeners.before.event_terminated["dapui_config"] = function()
					dapui.close()
				end
				dap.listeners.before.event_exited["dapui_config"] = function()
					dapui.close()
				end
			end,
		},
		{ "nvim-neotest/nvim-nio" },
		{
			"jayp0521/mason-nvim-dap.nvim", -- Bridge Mason and nvim-dap
			dependencies = {
				"williamboman/mason.nvim",
				"mfussenegger/nvim-dap",
			},
			config = function()
				require("mason-nvim-dap").setup({
					ensure_installed = { "debugpy" }, -- Ensure debugpy is installed
				})
			end,
		},
		{
			"tpope/vim-fugitive", -- Git integration
		},
		{
			"lewis6991/gitsigns.nvim",
			config = function()
				require("gitsigns").setup({
					signs = {
						add = { text = "+" }, -- Green "+" for added lines
						change = { text = "~" }, -- Blue "~" for modified lines
						delete = { text = "-" }, -- Red "-" for deleted lines
						topdelete = { text = "‾" }, -- Red "‾" for deleted lines at the top of a file
						changedelete = { text = "~" }, -- Blue "~" for lines that are both modified and deleted
					},
					signcolumn = true, -- Ensure signs are displayed in the sign column
				})
			end,
		},
		-- Mason: Plugin Manager for LSP Servers, DAPs, Linters, and Formatters
		{
			"williamboman/mason.nvim",
			config = function()
				require("mason").setup()
			end,
		},
		{
			"williamboman/mason-lspconfig.nvim",
			dependencies = { "williamboman/mason.nvim" },
			config = function()
				require("mason-lspconfig").setup()
			end,
		},
		{
			"linux-cultist/venv-selector.nvim",
			dependencies = {
				"neovim/nvim-lspconfig",
				"mfussenegger/nvim-dap", "mfussenegger/nvim-dap-python", --optional
				{ "nvim-telescope/telescope.nvim", branch = "0.1.x", dependencies = { "nvim-lua/plenary.nvim" } },
			},
			lazy = false,
			branch = "regexp",
			config = function()
				require("venv-selector").setup({
					name = ".venv", -- Default virtual environment folder name
					auto_refresh = true, -- Automatically detect and switch .venv
					search_workspace = true, -- Search for .venv in the workspace
					search_parent_dir = false, -- Don't search parent directories
				})
			end,
		},
		{
			"folke/trouble.nvim",
			opts = {},
			cmd = "Trouble",
			modes = {
				preview_float = {
					mode = "diagnostics",
					preview = {
						type = "float",
						relative = "editor",
						border = "rounded",
						title = "Preview",
						title_pos = "center",
						position = { 0, -2 },
						size = { width = 0.3, height = 0.3 },
						zindex = 200,
					},
				},
			},
			keys = {
				{
					"<leader>xx",
					"<cmd>Trouble diagnostics toggle<cr>",
					desc = "Diagnostics (Trouble)",
				},
				{
					"<leader>xX",
					"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
					desc = "Buffer Diagnostics (Trouble)",
				},
				{
					"<leader>cs",
					"<cmd>Trouble symbols toggle focus=false<cr>",
					desc = "Symbols (Trouble)",
				},
				{
					"<leader>cl",
					"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
					desc = "LSP Definitions / references / ... (Trouble)",
				},
				{
					"<leader>xL",
					"<cmd>Trouble loclist toggle<cr>",
					desc = "Location List (Trouble)",
				},
				{
					"<leader>xQ",
					"<cmd>Trouble qflist toggle<cr>",
					desc = "Quickfix List (Trouble)",
				},
			},
		},
		{
			"akinsho/toggleterm.nvim",
			config = function()
				require("toggleterm").setup({
					size = 10,
					open_mapping = [[<C-\>]],
					direction = "horizontal",
					float_opts = {
						border = "curved",
					},
				})

				-- Custom terminal command with .venv activation
				local Terminal = require("toggleterm.terminal").Terminal
				local function get_venv_activate_cmd()
					local cwd = vim.fn.getcwd()
					local venv_path = cwd .. "/.venv/bin/activate"
					if vim.fn.filereadable(venv_path) == 1 then
						return "source " .. venv_path .. " && $SHELL"
					else
						return "$SHELL"
					end
				end

				-- Define a custom terminal with .venv activation
				local venv_terminal = Terminal:new({
					cmd = get_venv_activate_cmd(),
					direction = "horizontal",
					size = 10,
				})

				-- Keybindings for toggling terminals
				vim.keymap.set("n", "<leader>tt", function()
					venv_terminal:toggle()
				end, { desc = "Toggle Horizontal Terminal with .venv Activation" })

				vim.keymap.set("n", "<leader>tv", "<cmd>ToggleTerm direction=vertical<CR>",
					{ desc = "Toggle Vertical Terminal" })
				vim.keymap.set("n", "<leader>tf", "<cmd>ToggleTerm direction=float<CR>",
					{ desc = "Toggle Floating Terminal" })
				vim.keymap.set("t", "<esc>", "<C-\\><C-n>", { desc = "Exit Terminal Mode" })

				-- Optional: Define multiple terminals
				local python_terminal = Terminal:new({
					cmd = "python",
					direction = "float",
					count = 2,
				})

				vim.keymap.set("n", "<leader>tp", function()
					python_terminal:toggle()
				end, { desc = "Toggle Python REPL" })
			end,
		},
	},
	-- Configure any other settings here. See the documentation for more details.
	install = { colorscheme = { "dracula" } },
	checker = { enabled = true }, -- Automatically check for plugin updates
})

if not status_ok then
	vim.api.nvim_err_writeln("Failed to load lazy.nvim: " .. err)
end

-- LSP Keybindings
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		-- Go to Definition
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = ev.buf, desc = "[G]oto [D]efinition" })

		-- Show Hover Information
		vim.keymap.set("n", "gh", vim.lsp.buf.hover, { buffer = ev.buf, desc = "Show Hover Information" })

		-- Find References
		vim.keymap.set("n", "gr", vim.lsp.buf.references, { buffer = ev.buf, desc = "Find References" })

		-- Rename Symbol
		vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, { buffer = ev.buf, desc = "Rename Symbol" })

		-- Code Actions (e.g., quick fixes)
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = ev.buf, desc = "Code Actions" })

		-- Format on Save
		vim.api.nvim_create_autocmd("BufWritePre", {
			buffer = ev.buf,
			callback = function()
				if vim.lsp.buf.server_ready() then
					vim.lsp.buf.format({ async = false })
				end
			end,
		})
	end,
})

-- Keybindings for copying to system clipboard
vim.keymap.set("v", "<leader>y", '"+y', { desc = "Copy selection to system clipboard" })
vim.keymap.set("n", "<leader>Y", '"+yy', { desc = "Copy line to system clipboard" })

-- Keybinding for pasting from system clipboard
vim.keymap.set("n", "<leader>p", '"+p', { desc = "Paste from system clipboard" })
vim.keymap.set("v", "<leader>P", '"+P', { desc = "Paste from system clipboard in visual mode" })
-- Keybindings for venv-selector.nvim
vim.keymap.set("n", "<leader>vs", ":VenvSelect<CR>", { desc = "Select Virtual Environment" })
vim.keymap.set("n", "<leader>vc", ":VenvSelectCached<CR>", { desc = "Select Cached Virtual Environment" })
vim.keymap.set("n", "<leader>vr", ":VenvRefresh<CR>", { desc = "Refresh Virtual Environment Selection" })
-- Keybindings for navigating between windows
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Keybindings for resizing windows
vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase window height" })
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>", { desc = "Decrease window height" })
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })

-- Keybinding to equalize window sizes
vim.keymap.set("n", "<leader>=", "<C-w>=", { desc = "Equalize window sizes" })
vim.opt.mouse = "a" -- Enable mouse support for all modes

local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
	error("This plugins requires nvim-telescope/telescope.nvim")
end

local plugin_base_directory = vim.fn.fnamemodify(require("plenary.debug_utils").sourced_filepath(), ":h:h:h:h")

local python_package_docs = function(opts)
	local url = require("net.url")
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local finders = require("telescope.finders")
	local pickers = require("telescope.pickers")
	local entry_display = require("telescope.pickers.entry_display")
	local conf = require("telescope.config").values

	local displayer = entry_display.create({
		separator = "▏",
		items = {
			{ width = 15 },
			{ width = 20 },
			{ remaining = true },
		},
	})

	pickers.new({}, {
		prompt_title = "python package documentation",
		finder = finders.new_oneshot_job({
			"python3",
			plugin_base_directory .. "/python/print_documentation_urls.py",
		}, {
			entry_maker = function(entry)
				local parts = vim.fn.split(entry, ";")
				return {
					url = parts[3],
					display = function()
						return displayer(parts)
					end,
					ordinal = entry,
				}
			end,
		}),
		previewer = nil,
		sorter = conf.generic_sorter({}),
		attach_mappings = function(_, _)
			actions.select_default:replace(function(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				if selection == nil then
					return
				end
				actions.close(prompt_bufnr)

				if opts.search then
					-- duckduckgo search for the rest
					local u = url.parse("http://duckduckgo.com/")
					u.query.q = "\\" .. opts.search .. " site:" .. selection.url
					vim.fn["netrw#BrowseX"](tostring(u), 0)
				else
					vim.fn["netrw#BrowseX"](selection.url, 0)
				end
			end)
			return true
		end,
	}):find()
end

return telescope.register_extension({ exports = { python_docs = python_package_docs } })

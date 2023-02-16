local H = {}

-- Default documentation targets ----------------------------------------------
H.input = function()
	-- Search in current and recursively in other directories for files with
	-- 'lua' extension
	local res = {}
	for _, dir_glob in ipairs({ ".", "lua/**", "after/**", "colors/**", "lua/builtin/**" }) do
		local files = vim.fn.globpath(dir_glob, "*.lua", false, true)

		-- Use full paths
		files = vim.tbl_map(function(x)
			return vim.fn.fnamemodify(x, ":p")
		end, files)

		-- Put 'init.lua' first among files from same directory
		table.sort(files, function(a, b)
			if vim.fn.fnamemodify(a, ":h") == vim.fn.fnamemodify(b, ":h") then
				if vim.fn.fnamemodify(a, ":t") == "init.lua" then
					return true
				end
				if vim.fn.fnamemodify(b, ":t") == "init.lua" then
					return false
				end
			end

			return a < b
		end)
		table.insert(res, files)
	end

	return vim.tbl_flatten(res)
end

return H

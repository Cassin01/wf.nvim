local function open_win(buf, height, row_offset, opts, cursor)
	local conf_ = {
		width = opts.style.width,
		relative = "editor",
		anchor = "NW",
		style = "minimal",
		border = opts.style.border,
		title = "ff",
		title_pos = "center",
		noautocmd = true,
	}
	local conf = vim.fn.extend(conf_, {
		height = height,
		row = vim.o.lines - height - row_offset - 1,
		col = vim.o.columns - conf_.width,
	})
	return vim.api.nvim_open_win(buf, cursor or false, conf)
end

local function gen_obj(row_offset, opts, cursor, buftype)
	local buf = vim.api.nvim_create_buf(false, true)
	local height = vim.api.nvim_buf_line_count(buf)
	local win = open_win(buf, height, row_offset, opts, cursor)
	vim.api.nvim_win_set_option(win, "winhl", "Normal:WFNormal,FloatBorder:WFFloatBorder")
	vim.api.nvim_win_set_option(win, "wrap", false)
	vim.api.nvim_buf_set_option(buf, "buftype", buftype)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "buflisted", false)
	return buf, win
end

return { gen_obj = gen_obj }

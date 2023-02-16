local util = require("wf.util")
local rev = util.array_reverse
local match_from_front = util.match_from_front
local fill_spaces = util.fill_spaces
local group = require("wf.group")
local output_obj_which = require("wf.output_obj_which")
local _update_output_obj = require("wf.output")._update_output_obj
local prompt_counter_update = require("wf.prompt_counter").update
local ns_wf_output_obj_fuzzy = vim.api.nvim_create_namespace("wf_output_obj_fuzzy")

-- core filtering flow
local core = function(choices_obj, groups_obj, which_obj, fuzzy_obj, output_obj, opts)
	-- filter with fuzzy match
	local fuzzy_line = vim.api.nvim_buf_get_lines(fuzzy_obj.buf, 0, -1, true)[1]
	local matches_obj, poss = (function()
		if fuzzy_line == "" then
			return choices_obj
		else
			local obj = vim.fn.matchfuzzypos(choices_obj, fuzzy_line, { key = "text" })
			local poss = obj[2]
			return rev(obj[1]), rev(poss)
		end
	end)()

	-- filter with which key match
	local which_line = vim.api.nvim_buf_get_lines(which_obj.buf, 0, -1, true)[1]
	local which_matches_obj = (function()
		local obj = {}
		for lnum, match in ipairs(matches_obj) do
			if match_from_front(match.key, which_line) then
				match["lnum"] = lnum
				table.insert(obj, match)
			end
		end
		return obj
	end)()

	-- integrate groups
	local folded_obj = vim.api.nvim_get_current_buf() == which_obj.buf
			and group.integrate(which_matches_obj, groups_obj, #which_line)
		or which_matches_obj

	-- sorter
	local endup_obj = (function()
		if opts.sorter == nil then
			return folded_obj
		else
			return opts.sorter(folded_obj)
		end
	end)()

	-- return early  without drawing if determined
	-- when narrowed down to one, return it
	if
		which_line ~= ""
		and #endup_obj == 1
		and (opts.behavior.skip_back_duplication or endup_obj[1].key == which_line)
	then
		return endup_obj[1].id, endup_obj[1].text
	end

	-- take out info's
	local function meta_key(sub)
		if string.match(sub, "^<") == "<" then
			local till = sub:match("^<[%w%-]+>")
			if till ~= nil then
				return #till
			end
		end
		return vim.fn.strwidth(string.match(sub, "."))
	end

	-- local ids = {}
	local texts = {}
	local match_posses = {}
	for _, match in ipairs(endup_obj) do
		-- table.insert(ids, { id = match.id, key = match.key })
		local sub = string.sub(match.key, 1 + #which_line, opts.prefix_size + #which_line)

		local str = fill_spaces(sub == "" and "<CR>" or sub, opts.prefix_size)
		local desc = (function()
			if vim.api.nvim_get_current_buf() == which_obj.buf then
				return output_obj_which:add(
					output_obj.buf,
					#texts,
					opts.output_obj_which_mode_desc_format(match),
					opts.prefix_size + 6
				)
			else
				return match.text
			end
		end)()
		local text = string.format(" %s %s %s", str, opts.style.icons.separator, desc)

		table.insert(texts, text)

		local till_len = meta_key(sub)
		table.insert(match_posses, { match.lnum, till_len })
	end

	-- update output_obj
	local _row_offset = vim.o.cmdheight + (vim.o.laststatus > 0 and 1 or 0) + opts.style.input_win_row_offset
	_update_output_obj(
		output_obj,
		texts,
		vim.o.lines,
		_row_offset + opts.style.input_win_row_offset,
		opts,
		endup_obj,
		which_obj,
		fuzzy_obj,
		which_line
	)

	-- highlight fuzzy matches
	if vim.api.nvim_get_current_buf() == fuzzy_obj.buf then
		for i, match_pos in ipairs(match_posses) do
			if poss ~= nil then
				for _, v in ipairs(poss[match_pos[1]]) do
					vim.api.nvim_buf_add_highlight(
						output_obj.buf,
						ns_wf_output_obj_fuzzy,
						"WFFuzzy",
						i - 1,
						v + opts.prefix_size + 6,
						v + opts.prefix_size + 7
					)
				end
			end
		end
	end

	-- highlight which matches
	if vim.api.nvim_get_current_buf() == which_obj.buf then
		output_obj_which:place(output_obj.buf)
	else
		output_obj_which:clear(output_obj.buf)
	end

	-- update prompt counter
	prompt_counter_update(which_obj, fuzzy_obj, #choices_obj, #which_matches_obj)

	-- -- when narrowed down to one, return it
	-- if which_line == "" then
	--     return nil
	-- else
	--     if #ids == 1 and ids[1].key == which_line then
	--         return ids[1].id
	--     elseif opts.behavior.skip_back_duplication and #ids == 1 then
	--         return ids[1].id
	--     else
	--         return nil
	--     end
	-- end
end

return { core = core }

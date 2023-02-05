local util = require("wf.util")

local plug_name = "wf_nvim"
local full_name = (function(hash)
    return plug_name .. hash
end)("309240")

local augname_leave_check = "wf_leave_check"
local augname_skip_front_duplicate = "wf_skip_front_duplicate"
local _g = util.aug(full_name)
-- local input_win_row_offset = 3 -- shift up output-window's row with input-window's height
local sign_group_prompt = full_name .. "prompt"
local sign_group_which = full_name .. "which"

-- util
local function bmap(buf, mode, key, f, desc, _opt)
    util.bmap(buf, mode, key, f, "[" .. plug_name .. "] " .. desc, _opt)
end

local function row_offset()
    return vim.o.cmdheight + (vim.o.laststatus > 0 and 1 or 0)
end

return {
    plug_name = plug_name,
    full_name = full_name,
    augname_leave_check = augname_leave_check,
    augname_skip_front_duplicate = augname_skip_front_duplicate,
    _g = _g,
    bmap = bmap,
    sign_group_prompt = sign_group_prompt,
    sign_group_which = sign_group_which,
    row_offset = row_offset,
}

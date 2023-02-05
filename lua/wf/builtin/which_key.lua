local util = require("wf.util")
local extend = util.extend
local ingect_deeply = util.ingect_deeply
local rt = util.rt
local feedkeys = util.feedkeys
local secret_key = util.secret_key
local get_mode = util.get_mode
local select = require("wf").select
local full_name = require("wf.static").full_name

local modes = {
    n = "normal",
    v = "visual",
    x = "visual and select",
    s = "select",
    o = "operator pending",
    l = "langmap",
    c = "command",
    t = "terminal",
}

local function _get_gmap(mode)
    local keys = vim.api.nvim_get_keymap(mode)
    local choices = {}
    for _, val in ipairs(keys) do
        if not string.match(val.lhs, "^<Plug>") then
            local lhs = string.gsub(val.lhs, " ", "<Space>")
            choices[lhs] = val.desc or val.rhs
        end
    end
    return choices
end

local function _get_bmap(buf, mode)
    local keys = vim.api.nvim_buf_get_keymap(buf, mode)
    local choices = {}
    for _, val in ipairs(keys) do
        if not string.match(val.lhs, "^<Plug>") then
            local lhs = val.lhs
            lhs = string.gsub(lhs, " ", "<Space>")
            choices[lhs] = val.desc or val.rhs .. " [buf]" --or val.rhs
        end
    end
    return choices
end

local function which_key(opts)
    local core = function()
        local buf = vim.api.nvim_get_current_buf()
        local win = vim.api.nvim_get_current_win()
        local mode = get_mode()
        local mode_shortname = mode:sub(1,1)
        if modes[mode_shortname] == nil then
            print("Not support mode: " .. mode_shortname)
        end
        local g = _get_gmap("n")
        local b = _get_bmap(buf, "n")
        local choices = extend(g, b)
        local count = vim.api.nvim_get_vvar("count")

        opts = opts or { text_insert_in_advance = "" }
        opts["text_insert_in_advance"] =
        string.gsub(opts["text_insert_in_advance"], "<Leader>", vim.g["mapleader"] or [[\]])
        local _opts = {
            title = "Which Key",
            text_insert_in_advance = "",
            -- key_group_dict = vim.fn.luaeval("_G.__kaza.prefix"),
        }
        local opts_ = ingect_deeply(_opts, opts)

        select(choices, opts_, function(_, lhs)
            local rhs = vim.fn.maparg(rt(lhs), mode_shortname, false, true)
            if type(rhs["callback"]) == "function" then
                rhs["callback"]()
                if rhs.silent == 0 then
                    vim.api.nvim_echo({{rhs.lhsraw, "Normal"}}, false, {})
                end
            else
                feedkeys(lhs, count,{ win = win, buf = buf, mode = mode }, false)
            end
        end)
    end
    return core
end

return which_key

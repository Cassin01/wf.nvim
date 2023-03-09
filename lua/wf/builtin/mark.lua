local select = require("wf").select
local util = require("wf.util")
local path_from_head = util.path_from_head
local feedkeys = util.feedkeys
local get_mode = util.get_mode
local format_length = util.format_length
local cell = require("wf.cell")

local labels = {
  ["^"] = "Last position of cursor in insert mode",
  ["."] = "Last change in current buffer",
  ['"'] = "Last exited current buffer",
  ["0"] = "In last file edited",
  ["'"] = "Back to line in current buffer where jumped from",
  ["`"] = "Back to position in current buffer where jumped from",
  ["["] = "To beginning of previously changed or yanked text",
  ["]"] = "To end of previously changed or yanked text",
  ["<"] = "To beginning of last visual selection",
  [">"] = "To end of last visual selection",
}

---@tag wf.builtin.mark
---@param opts? WFOptions
local function mark(opts)
  local function _mark()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    local mode = get_mode()
    local mlist = {}
    for _, m in ipairs(vim.fn.getmarklist(buf)) do
      table.insert(mlist, m)
    end
    for _, m in ipairs(vim.fn.getmarklist()) do
      table.insert(mlist, m)
    end
    local minfo = {}
    local choice = {}
    setmetatable(choice, { __type = "cells" })
    for _, m in pairs(mlist) do
      local line = (function()
        local lines = vim.fn.getbufline(m.pos[1], m.pos[2])
        if lines and lines[1] then
          return lines[1]
        else
          return ""
        end
      end)()
      -- local index = string.sub(m.mark, 2, 2)
      local index = m.mark
      m["line"] = format_length(line, 40)
      minfo[index] = m
      table.insert(choice, cell.new(index, index, m.file, "key"))
    end

    local _opts = {
      prefix_size = 2,
      title = "Mark",
      behavior = {
        skip_front_duplication = true,
        skip_back_duplication = true,
      },
      style = {
        width = vim.o.columns,
      },
      output_obj_which_mode_desc_format = function(c)
        local key = c.key
        local m = minfo[key]
        local ret = {}
        local pos = string.format("%3d, %3d", m.pos[2], m.pos[3])
        table.insert(ret, { pos, "Comment" })
        table.insert(ret, { " " .. m.line, "String" })
        if m["file"] ~= nil then
          local fpath = path_from_head(m.file)
          table.insert(ret, { " " .. fpath, "WFWhichDesc" })
        end
        if labels[key:sub(2, 2)] ~= nil then
          table.insert(ret, { " " .. labels[key:sub(2, 2)], "Comment" })
        end
        return ret
      end,
    }
    opts = opts or {}
    for k, v in pairs(opts) do
      _opts[k] = v
    end
    if table.maxn(mlist) == 0 then
      vim.api.nvim_echo({
        { "No buffers to switch to.", "ErrorMsg" },
        { " @wf.builtin.buffer", "Comment" },
      }, false, {})
      return
    end
    select(choice, _opts, function(_, lhs)
      feedkeys(lhs, 0, { win = win, buf = buf, mode = mode }, true)
    end)
  end

  return _mark
end

return mark

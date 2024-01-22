local util = require("wf.util")
local extend = util.extend
local ingect_deeply = util.ingect_deeply
local rt = util.rt
-- local feedkeys = util.feedkeys
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
      choices[lhs] = val.desc or val.rhs or tostring(val.callback) .. " [buf]" --or val.rhs
    end
  end
  return choices
end

local function feedkeys(lhs, count, caller, noremap)
  local caller_mode = caller.mode:sub(1, 1)
  -- check if the current state is the same as the caller's state
  if
    caller.win == vim.api.nvim_get_current_win()
    and caller.buf == vim.api.nvim_get_current_buf()
    and caller_mode == get_mode():sub(1, 1)
  then
    local rhs = vim.fn.maparg(rt(lhs), caller_mode, false, true)
    if type(rhs["callback"]) == "function" then
      if count and count ~= 0 then
        for _ = 1, count do
          rhs["callback"]()
        end
      else
        rhs["callback"]()
      end
      if rhs.silent == 0 then
        vim.api.nvim_echo({ { rhs.lhsraw, "Normal" } }, false, {})
      end
    else
      if count and count ~= 0 then
        lhs = count .. lhs
      end
      vim.api.nvim_feedkeys(rt(lhs), noremap and "n" or "m", false)
    end
  else
    print("caller mode: ", caller_mode, "\n", "mode: ", get_mode():sub(1, 1))
    print("which-key: mode is not n or i")
  end
end

local function leader()
  local ml = vim.g["mapleader"]
  vim.notify("k" .. ml .. "k")
  vim.api.nvim_echo({"f" .. ml .. "f"}, true, {})
  if ml ~= nil then
    if ml == " " then
      return "<Space>"
    else
      return "hoge"
    end
  else
    return [[\]]
  end
end

---@tag wf.builtin.which_key
---@param opts? WFOptions
local function which_key(opts)
  local core = function()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    local mode = get_mode()
    local mode_shortname = mode:sub(1, 1)
    if modes[mode_shortname] == nil then
      print("Which Key does not support mode: " .. mode_shortname)
      return
    end
    local g = _get_gmap(mode_shortname)
    local b = _get_bmap(buf, mode_shortname)
    local choices = extend(g, b)
    local count = vim.api.nvim_get_vvar("count")

    opts = opts or { text_insert_in_advance = "" }
    -- Upper case
    opts["text_insert_in_advance"] =
      string.gsub(opts["text_insert_in_advance"], "<Leader>", leader())
    -- Lower case
    opts["text_insert_in_advance"] =
      string.gsub(opts["text_insert_in_advance"], "<leader>", leader())
    local _opts = {
      title = "Which Key",
      text_insert_in_advance = "",
    }
    local opts_ = ingect_deeply(_opts, opts)

    select(choices, opts_, function(_, lhs)
      -- local rhs = vim.fn.maparg(rt(lhs), mode_shortname, false, true)
      -- print("selected")
      -- if type(rhs["callback"]) == "function" then
      --     rhs["callback"]()
      --     if rhs.silent == 0 then
      --         vim.api.nvim_echo({ { rhs.lhsraw, "Normal" } }, false, {})
      --     end
      -- else
      feedkeys(lhs, count, { win = win, buf = buf, mode = mode }, false)
      -- end
    end)
  end
  return core
end

return which_key

local M = {}

M.secret_key = "Ƿ"

function M.array_reverse(x)
  local n, m = #x, #x / 2
  for i = 1, m do
    x[i], x[n - i + 1] = x[n - i + 1], x[i]
  end
  return x
end

-- Inject obj into org
-- @param org: table
-- @param obj: table
function M.ingect_deeply(org, obj)
  for k, v in pairs(obj) do
    if vim.fn.has_key(org, k) then
      if type(org[k]) == "table" and not vim.tbl_islist(org[k]) then
        org[k] = M.ingect_deeply(org[k], v)
      else
        org[k] = v
      end
    end
  end
  return org
end

function M.cmd(name, f, opt)
  opt = (opt or {})
  opt["force"] = true
  vim.api.nvim_create_user_command(name, f, opt)
end

function M.aug(group)
  vim.api.nvim_create_augroup(group, { clear = true })
end

function M.au(group, event, callback, opt_)
  local opt = vim.fn.extend(opt_ or {}, { callback = callback, group = group })
  return vim.api.nvim_create_autocmd(event, opt)
end

function M.rt(str)
  return vim.api.nvim_replace_termcodes(str, true, false, true)
end

function M.get_mode()
  local mode = vim.api.nvim_get_mode().mode
  mode = mode:gsub(M.rt("<C-V>"), "v")
  mode = mode:gsub(M.rt("<C-S>"), "s")
  return mode:lower()
end

function M.bmap(buf, mode, key, f, desc, _opt)
  local opt = { callback = f, noremap = true, silent = true, desc = desc, nowait = true }
  opt = M.extend(_opt or {}, opt)
  if type(mode) == "table" then
    for _, v in pairs(mode) do
      vim.api.nvim_buf_set_keymap(buf, v, key, "", opt)
    end
  elseif type(mode) == "string" then
    vim.api.nvim_buf_set_keymap(buf, mode, key, "", opt)
  end
end

-- Extend dictionary
function M.extend(a, b)
  for k, v in pairs(b) do
    a[k] = v
  end
  return a
end

function M.fill_spaces(str, len)
  local res = ""
  for c in str:gmatch(".") do
    if vim.fn.strwidth(res .. c) > len then
      break
    end
    res = res .. c
  end
  for _ = 1, len - vim.fn.strwidth(res) do
    res = res .. " "
  end
  return res
end

function M.format_length(str, len)
  local ret = string.sub(str, 1, len)
  return M.fill_spaces(ret, len)
end

function M.match_from_front(str, patt)
  if string.len(str) < string.len(patt) then
    return false
  end
  for i = 1, patt:len() do
    if string.sub(str, i, i) ~= string.sub(patt, i, i) then
      return false
    end
  end
  return true
end

local function _escape(c)
  return c == [[\]] and [[\\]] or c
end

function M.match_from_front_ignore_case(str, patt)
  if string.len(str) < string.len(patt) then
    return false
  end
  for i = 1, patt:len() do
    local c = string.sub(str, i, i)
    local p = string.sub(patt, i, i)
    if vim.api.nvim_eval([["]] .. _escape(c) .. [[" ==? "]] .. _escape(p) .. [["]]) == 0 then
      return false
    end
  end
  return true
end

function M.match_from_tail(str, patt)
  if string.len(str) < string.len(patt) then
    return false
  end
  for i = 1, patt:len() do
    if string.sub(str, -i, -i) ~= string.sub(patt, -i, -i) then
      return false
    end
  end
  return true
end

function M.replace_nth(str, n, old, new)
  if n <= #str and str:sub(n, n) == old then
    return str:sub(1, n - 1) .. new .. str:sub(n + 1)
  end
  return str
end

-- usage
-- async_print = run(print)
-- async_print("hello world")
function M.async(callback)
  local function run(...)
    local args = { ... }
    local handle
    handle = vim.loop.new_async(vim.schedule_wrap(function()
    -- handle = vim.loop.new_async(function()
      if #args > 0 then
        callback(unpack(args))
      else
        callback()
      end
      if not handle:is_closing() then
        handle:close()
      end
    end))
    handle:send()
    return handle
  end
  return run
end

-- for nvim-web-devicons
function M.gen_highlight(name, color)
  local ext = name:match("^.*%.(.*)$") or ""
  local hlname = "WFDevicon" .. ext
  if pcall(vim.api.nvim_get_hl_by_name, hlname, false) then
    return hlname
  else
    vim.api.nvim_set_hl(0, hlname, { fg = color })
    return hlname
  end
end

-- builtin plugin
function M.path_from_head(name, depth)
  depth = depth or 2
  local d = 0
  local cs = ""
  for i = #name, 1, -1 do
    local c = name:sub(i, i)
    if c == "/" then
      d = d + 1
    end
    if d >= depth then
      break
    end
    cs = c .. cs
  end
  return cs
end

-- @param current: buf, win, mode
function M.feedkeys(lhs, count, current, noremap)
  local mode_shortname = current.mode:sub(1, 1)
  local rhs = vim.fn.maparg(M.rt(lhs), mode_shortname, false, true)
  -- local _feedkeys = vim.schedule_wrap(function()
  local _feedkeys = function()
    -- if type(rhs["callback"]) == "function" then
    --   print("_callback")
    --   print(vim.inspect(vim.api.nvim_get_mode()))
    --   rhs["callback"]()
    --   if rhs.silent == 0 then
    --     vim.api.nvim_echo({ { rhs.lhsraw, "Normal" } }, false, {})
    --   end
    -- else
    --   vim.api.nvim_feedkeys(M.rt(lhs), noremap and "n" or "m", false)
    -- end
      vim.api.nvim_feedkeys(M.rt(lhs), noremap and "n" or "m", false)
  end
  local mode = current.mode
  if
    current.win == vim.api.nvim_get_current_win()
    and current.buf == vim.api.nvim_get_current_buf()
  then
    local current_mode = vim.fn.mode()
    if count and count ~= 0 then
      lhs = count .. lhs
    end
    -- if current_mode == "i" then
    --   -- feed CTRL-O again i called from CTRL-O
    --   if mode == "nii" or mode == "nir" or mode == "niv" or mode == "vs" then
    --     print("temporally stopinsert from @util")
    --     vim.api.nvim_feedkeys(M.rt("<C-O>"), "n", false)
    --   else
    --     print("stopinsert from @util")
    --     vim.cmd("stopinsert")
    --     -- stopinert()
    --     -- vim.api.nvim_feedkeys(M.rt("<Esc>"), "n", false)
    --   end

    --   -- feed the keys with remap
    --   -- vim.api.nvim_feedkeys(M.rt(lhs), noremap and "n" or "m", false)
    --   _feedkeys()
    -- elseif current_mode == "n" then
      if mode == "n" then
        -- vim.api.nvim_feedkeys(M.rt(lhs), noremap and "n" or "m", false)
        _feedkeys()
      end
    -- else
    --   print("current mode: ", current_mode, "\n", "mode: ", mode)
    --   print("which-key: mode is not n or i")
    -- end
  end
end

return M

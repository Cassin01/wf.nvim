local full_name = require("wf.static").full_name

-- usage
-- async_print = run(print)
-- async_print("hello world")
local function async(callback)
    local handle
    handle = vim.loop.new_async(vim.schedule_wrap(function()
      local ret = callback()
      print(vim.g[full_name .. "#text_insert_in_advance"])
      local text_insert_in_advance = vim.g[full_name .. "#text_insert_in_advance"]
      local which_obj_buf = vim.g[full_name .. "#which_obj_buf"]
      if text_insert_in_advance ~= nil and which_obj_buf ~= nil then
        vim.api.nvim_buf_set_lines(which_obj_buf, 0, -1, true, { text_insert_in_advance .. ret })
      else
        vim.g[full_name .. "#char_insert_in_advance"] = ret
      end
      if not handle:is_closing() then
        handle:close()
      end
    end))
    handle:send()
    return handle
end

local function settimeout(timeout, callback)
  local timer = vim.loop.new_timer()
  timer:start(timeout, 0, function()
    timer:stop()
    timer:close()
    callback()
  end)
  return timer
end

local function input()
  repeat
  until vim.fn.getchar(1) ~= 0
  return vim.fn.nr2char(vim.fn.getchar())
end

local function init()
  local handler = async(input)
  settimeout(1000, function()
    if not handler:is_closing() then
      handler:close()
      vim.schedule(function()
        vim.cmd("startinsert!")
      end)
    end
  end)
end

return {input = init}

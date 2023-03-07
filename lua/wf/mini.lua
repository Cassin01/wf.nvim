local H = {}

local _swallow = function(dir_glob)
  local files = vim.fn.globpath(dir_glob, "*.lua", false, true)
  files = vim.tbl_map(function(x)
    return vim.fn.fnamemodify(x, ":p")
  end, files)

  return files
end

H.custom_input = function()
  local res = {}
  for _, dir_glob in ipairs({
    "lua/wf/init.lua",
    "lua/wf/setup/**",
    "lua/wf/builtin/**",
    "lua/wf/types.lua",
  }) do
    if string.match(dir_glob, ".+%.lua$") then
      table.insert(res, vim.fn.fnamemodify(dir_glob, ":p"))
    else
      table.insert(res, _swallow(dir_glob))
    end
  end
  return vim.tbl_flatten(res)
end

return H

local select = require("wf").select
local registers = [[*+"-:.%/#=_abcdefghijklmnopqrstuvwxyz0123456789]]
local labels = {
  ['"'] = "last deleted, changed, or yanked content", -- "delet,chang,yank", -- "last deleted, changed, or yanked content",
  ["0"] = "last yank", -- "last yank",
  ["-"] = "deleted or changed content smaller than one line",
  ["."] = "last inserted text", -- "last inserted text",
  ["%"] = "name of the current file",
  [":"] = "most recent executed command",
  ["#"] = "alternate buffer",
  ["="] = "result of an expression",
  ["+"] = "synchronized with the system clipboard",
  ["*"] = "synchronized with the selection clipboard",
  ["_"] = "black hole",
  ["/"] = "last search pattern",
}
local types = {
  ["v"] = "c",
  ["V"] = "l",
  [""] = "u",
}

---@tag builtin.register
---@param opts? table
local function register(opts)
  local function _register()
    local choices = {}
    for i = 1, #registers, 1 do
      local key = registers:sub(i, i)
      local ok, value = pcall(vim.fn.getreg, key, 1)
      if ok then
        value = vim.fn.substitute(value, "[[:cntrl:]]", "", "g")
        value = vim.fn.substitute(value, "\n", "", "g")
        if #value > 0 then
          choices[key] = value
        end
      end
    end

    local _opts = {
      title = "Registers",
      output_obj_which_mode_desc_format = function(c)
        local t = (types[vim.fn.getregtype(c.key)] or "b")
        local s = (labels[c.key] or "") .. " "
        return { { t .. " ", "Type" }, { c.text .. " ", "WFWhichDesc" }, { s, "Comment" } }
      end,
      prefix_size = 1,
      style = {
        width = vim.o.columns,
      },
    }
    opts = opts or {}
    for k, v in pairs(opts) do
      _opts[k] = v
    end
    select(choices, _opts, function(_, lhs)
      local cmd = [[normal! "]] .. lhs .. "p"
      vim.cmd(cmd)
    end)
  end

  return _register
end

return register

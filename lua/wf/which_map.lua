local plug_name = require("wf.static").plug_name

local function ctrl(c)
  return "<C-" .. c .. ">"
end

local function ctrl_shift(c)
  return "<C-S-" .. c .. ">"
end

local function meta(c)
  return "<M-" .. c .. ">"
end

local function alt(c)
  return "<A-" .. c .. ">"
end

local function map(buf, list)
  local function bmap(key, send, desc)
    vim.api.nvim_buf_set_keymap(buf, "i", key, "", {
      callback = function()
        return send
      end,
      nowait = true,
      noremap = true,
      silent = true,
      expr = true,
      desc = "[" .. plug_name .. "]" .. desc,
    })
  end

  for _, v in ipairs(list) do
    bmap(v, v, "send as if typed keys")
  end
end

local function map_list_gen(black_dict)
  local list = {}
  for i = 1, 26 do
    local c = string.char(i + 64)
    if not black_dict[ctrl(c)] then
      table.insert(list, ctrl(c))
    end
    if not black_dict[ctrl_shift(c)] then
      table.insert(list, ctrl_shift(c))
    end
    if not black_dict[meta(c)] then
      table.insert(list, meta(c))
    end
    if not black_dict[alt(c)] then
      table.insert(list, alt(c))
    end
  end
  return list
end

local function setup(buf, black_list)
  local black_dict = {
    ["<C-I>"] = true,
    ["<C-H>"] = true,
    ["<C-M>"] = true,
  }
  for _, name in ipairs(black_list) do
    black_dict[name:upper()] = true
  end
  local map_list = map_list_gen(black_dict)
  table.insert(map_list, "<C-@>")
  table.insert(map_list, "<Space>")
  table.insert(map_list, "<Tab>")
  table.insert(map_list, "[")
  table.insert(map_list, "{")
  table.insert(map_list, "(")
  -- table.insert(map_list, "<lt>")
  map(buf, map_list)
  return map_list
end

return { setup = setup }

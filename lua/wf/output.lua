local static = require("wf.static")
local plug_name = static.plug_name
local row_offset_ = static.row_offset
local gen_obj = require("wf.common").gen_obj

-- generate output object(buf and win)
local function output_obj_gen(opts)
  local style = opts.style
  local buf, win = gen_obj(
    row_offset_() + style.input_win_row_offset + style.input_win_row_offset,
    opts,
    false,
    "nofile",
    style.borderchars.top[2]
  )
  vim.api.nvim_buf_set_option(buf, "filetype", plug_name .. "output")
  local wcnf = vim.api.nvim_win_get_config(win)
  vim.api.nvim_win_set_config(
    win,
    vim.fn.extend(wcnf, {
      border = style.borderchars.top,
      -- title_pos = "center",
      -- title = style.borderchars.top[2],
    })
  )
  return { buf = buf, win = win }
end

return { output_obj_gen = output_obj_gen }

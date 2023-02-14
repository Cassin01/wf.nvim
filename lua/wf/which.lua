local gen_obj = require("wf.common").gen_obj
local row_offset = require("wf.static").row_offset
local static = require("wf.static")
local _g = static._g
local au = require("wf.util").au

local function input_obj_gen(opts, cursor)
  local buf, win = gen_obj(row_offset(), opts, cursor, "prompt")

  au(_g, "BufEnter", function()
    local _, _ = pcall(function()
      -- turn off the completion
      require("cmp").setup.buffer({ enabled = false })
    end)
  end, { buffer = buf })

  vim.fn.prompt_setprompt(buf, opts.style.icons.which_prompt)
  local wcnf = vim.api.nvim_win_get_config(win)
  vim.api.nvim_win_set_config(
    win,
    vim.fn.extend(wcnf, { title_pos = "center", title = opts.style.borderchars.center[2] })
  )
  return { buf = buf, win = win, name = " Which Key " }
end

return { input_obj_gen = input_obj_gen }

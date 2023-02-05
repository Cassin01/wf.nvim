local gen_obj = require("wf.common").gen_obj
local static = require("wf.static")
local row_offset = static.row_offset
local _g = static._g
local au = require("wf.util").au

local function input_obj_gen(opts, cursor)
    local _row_offset = row_offset() + opts.style.input_win_row_offset
    local buf, win = gen_obj(_row_offset, opts, cursor)

    au(_g, "BufEnter", function()
        local _, _ = pcall(function()
            -- turn off the completion
            require("cmp").setup.buffer({ enabled = false })
        end)
    end, { buffer = buf })

    local wcnf = vim.api.nvim_win_get_config(win)
    vim.api.nvim_win_set_config(
        win,
        vim.fn.extend(wcnf, { title = opts.style.borderchars.bottom[2] })
    )
    return { buf = buf, win = win, name = " Fuzzy Finder " }
end

return { input_obj_gen = input_obj_gen }

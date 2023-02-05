local M = {}
local default_width = 60
function M.new(theme)
    local themes = {
        default = {
            border = "rounded",
            borderchars = {
                top = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
                center = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
                bottom = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
            },
            icons = {
                separator = "➜", -- symbol used between a key and it's label
                fuzzy_prompt = "> ",
                which_prompt = "> ",
            },
            input_win_row_offset = 3, -- shift up output-window's row with input-window's height
            width = vim.o.columns > default_width * 2 and default_width
                or math.ceil(vim.o.columns * 0.5),
        },
        space = {
            border = "rounded",
            borderchars = {
                top = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
                center = { "╭", "─", "╮", "│", "┤", "─", "├", "│" },
                bottom = { "", "", "", "│", "╯", "─", "╰", "│" },
            },
            icons = {
                separator = "➜", -- symbol used between a key and it's label
                fuzzy_prompt = "> ",
                which_prompt = "> ",
            },
            input_win_row_offset = 3, -- shift up output-window's row with input-window's height
            width = vim.o.columns > default_width * 2 and default_width
                or math.ceil(vim.o.columns * 0.5),
        },
        chad = {
            border = "solid",
            borderchars = {
                top = { " ", " ", " ", " ", " ", " ", " ", " " },
                center = { " ", " ", " ", " ", " ", " ", " ", " " },
                bottom = { " ", " ", " ", " ", " ", " ", " ", " " },
            },
            icons = {
                separator = "   ", -- symbol used between a key and it's label (strdisplaywidth = 3)
                fuzzy_prompt = " ",
                which_prompt = " ",
            },
            input_win_row_offset = 3, -- shift up output-window's row with input-window's height
            width = vim.o.columns > default_width * 2 and default_width
                or math.ceil(vim.o.columns * 0.5),
        },
    }
    return themes[theme] or themes["default"]
end

return M

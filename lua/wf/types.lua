---@alias WFTheme "default"|"space"|"chad"

---@class hl_group string Highlight group name, e.g. "ErrorMsg"

---@class WFkeymaps
---@field escape string
---@field toggle string

---@class WFHighlight
---@field WFNormal hl_group
---@field WFFloatBorder hl_group
---@field WFFloatBorderFocus hl_group
---@field WFComment hl_group
---@field WFWhichRem hl_group
---@field WFWhichOn hl_group
---@field WFFuzzy hl_group
---@field WFFuzzyPrompt hl_group
---@field WFFocus hl_group
---@field WFFreeze hl_group
---@field WFWhichObjCounter hl_group
---@field WFWhichDesc hl_group
---@field WFSeparator hl_group
---@field WFGroup hl_group
---@field WFWhichUnique hl_group
---@field WFExpandable hl_group
---@field WFTitleOutput hl_group
---@field WFTitleWhich hl_group
---@field WFTitleFuzzy hl_group
---@field WFTitleFreeze hl_group

---@class WFConfig
---@field theme? WFTheme
---@field highlight? WFHighlight
---@field builtin_keymaps WFkeymaps

---@class WFBehavior
---@field skip_front_duplication boolean
--- Example:
--- When there are two lines:
--- `|123k123`
--- `|123l123`
--- then the prefix match is skipped:
--- `123|k123`
--- `123|l123`
---@field skip_back_duplication boolean
--- Example:
--- When there are two lines:
--- `123`
--- `123k|j`
--- At this time, the candidate is uniquely determined, so confirm the candidate before pressiong `j`.

---@class Cell
---@field key string
---@field id string
---@field text string
---@field type "key"|"group"

---@class Chunks
---A list of [text, hl_group] arrays, each representing a text chunk with specified highlight. hl_group element can not be omitted for not
--highlight.

---@class WFStyle
---@field border string
---Style of window border. This can either be a string or an array.
---:h nvim_open_win
---@field borderchars table @field top center bottom
---The array will specifify the eight chars building up the border in a clockwise fashion starting with the top-left corner.
---:h nvim_open_win
---@field icons table @field separator fuzzy_prompt which_prompt
---@field input_win_row_offset number The width for shift up output-window's row with input-window's height.
---@width number a width for windows

---@class WFOptions
---@field title string?
---@field selector "which"|"fuzzy"
---@field text_insert_in_advance string
---@field key_group_dict table
---@usage key_group_dict = { "<leader>l"="vimtex", "<leader>e"="conjure" }
---@field prefix_size number
---@field sorter function
---@field behavior WFBehavior
---@field output_obj_which_mode_desc_format fun(match_obj:Cell[]):Chunks
---@field style WFStyle

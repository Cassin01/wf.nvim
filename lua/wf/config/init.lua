local full_name = require("wf.static").full_name
local style = require("wf.config.style").new(vim.g[full_name .. "#theme"] or "default")

-- Default configuration
local _opts = {
  title = nil,
  selector = "which",
  text_insert_in_advance = "",
  key_group_dict = {},
  prefix_size = 7,
  sorter = require("wf.sorter").which,
  behavior = {
    skip_front_duplication = false,
    skip_back_duplication = false,
  },
  output_obj_which_mode_desc_format = function(match_obj)
    local desc = match_obj.text
    local front = desc:match("^%[[%l%u%d%s%-%.]+%]")
    if front == nil then
      if match_obj.type == "group" then
        return { { match_obj.text, "WFWhichDesc" }, { " +", "WFExpandable" } }
      else
        return { { match_obj.text, "WFWhichDesc" } }
      end
    end
    local back = desc:sub(#front + 1)
    if match_obj.type == "group" then
      return { { front, "WFGroup" }, { back, "WFWhichDesc" }, { " +", "WFExpandable" } }
    else
      return { { front, "WFGroup" }, { back, "WFWhichDesc" } }
    end
  end,
  style = style,
}

return _opts

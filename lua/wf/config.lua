local Wf = {}

--- Your plugin configuration with its default values.
---
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
Wf.options = {
    -- Prints useful logs about what event are triggered, and reasons actions are executed.
    debug = false,
}

--- Define your wf setup.
---
---@param options table Module config table. See |Wf.options|.
---
---@usage `require("wf").setup()` (add `{}` with your |Wf.options| table)
function Wf.setup(options)
    Wf.options = vim.tbl_deep_extend("keep", options or {}, Wf.options)

    return Wf.options
end

return Wf

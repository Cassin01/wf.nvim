-- You can use this loaded variable to enable conditional parts of your plugin.
if _G.WfLoaded then
    return
end

_G.WfLoaded = true

vim.api.nvim_create_user_command("Wf", function()
    require("wf").toggle()
end, {})

local D = require("wf.util.debug")
local M = require("wf.util.map")

-- internal methods
local Wf = {}

-- state
local S = {
    -- Boolean determining if the plugin is enabled or not.
    enabled = false,
}

--- Toggle the plugin by calling the `enable`/`disable` methods respectively.
function Wf.toggle()
    if S.enabled then
        Wf.disable()

        return false
    end

    Wf.enable()

    return true
end

--- A method to enable your plugin.
function Wf.enable()
    if S.enabled then
        return
    end

    S.enabled = true
end

--- A method to disable your plugin.
function Wf.disable()
    if not S.enabled then
        return
    end

    -- reset the state
    S = {
        enabled = false,
    }
end

return { Wf, S }

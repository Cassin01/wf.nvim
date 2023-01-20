local Wf = {}

-- Toggle the plugin by calling the `enable`/`disable` methods respectively.
function Wf.toggle()
    -- when the config is not set to the global object, we set it
    if Wf.config == nil then
        Wf.config = require("wf.config").options
    end
    local main = require("wf.main")

    -- the internal toggle method tell us if the plugin was enabled or disabled.
    -- this allows us to init/reset the global object.
    if main[1].toggle() then
        Wf.internal = {
            toggle = main[1].toggle,
            enable = main[1].enable,
            disable = main[1].disable,
        }
    else
        Wf.internal = {
            toggle = nil,
            enable = nil,
            disable = nil,
        }
    end

    Wf.state = main[2]
end

-- starts Wf and set internal functions and state.
function Wf.enable()
    local main = require("wf.main")

    main[1].enable()

    Wf.state = main[2]
    Wf.internal = {
        toggle = main[1].toggle,
        enable = main[1].enable,
        disable = main[1].disable,
    }
end

-- disables Wf and reset internal functions and state.
function Wf.disable()
    local main = require("wf.main")

    main[1].disable()

    Wf.state = main[2]
end

-- setup Wf options and merge them with user provided ones.
function Wf.setup(opts)
    Wf.config = require("wf.config").setup(opts)
end

_G.Wf = Wf

return Wf

local match_from_front = require("wf.util").match_from_front_ignore_case
local cell = require("wf.cell")

local function new(group_dict)
    local obj = {}
    for k, v in pairs(group_dict) do
        table.insert(obj, cell.new(-1, k, v, "group"))
    end
    return obj
end

local function integrate(matched_objs, groups_obj, input_len)
    local new_group_objs_dict = {}
    local new_matched_objs = {}
    for _, matched_obj in ipairs(matched_objs) do
        local new_group_obj = nil
        for _, group_obj in ipairs(groups_obj) do
            local group_obj_key_len = #group_obj.key
            if
                group_obj_key_len > input_len
                and group_obj_key_len < #matched_obj.key
                and match_from_front(matched_obj.key, group_obj.key)
            then
                if new_group_obj == nil then
                    new_group_obj = group_obj
                else
                    if #new_group_obj.key > #group_obj.key then
                        new_group_obj = group_obj
                    end
                end
            end
        end

        if new_group_obj ~= nil then
            new_group_objs_dict[new_group_obj.key] = new_group_obj
        else
            table.insert(new_matched_objs, matched_obj)
        end
    end
    for _, group_obj in pairs(new_group_objs_dict) do
        table.insert(new_matched_objs, group_obj)
    end
    return new_matched_objs
end

return { integrate = integrate, new = new }

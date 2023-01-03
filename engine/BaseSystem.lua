local util = require 'engine.util'
local Object = require 'lib.classic'

local BaseSystem = Object:extend()

BaseSystem.createFilter = function (group_name)
    return {
        [group_name] = {
            filter = function (e)
                return util.contains(e.systems, group_name)
            end
        }
    }
end

function BaseSystem:validateEntity(e)
    if _G.DEBUG then
        if self.validator and not self.validator(e).ok then
            local err = '[' .. self.group_name .. '] objects must follow mishape schema.'
                .. '\n\t entity class_name: ' .. e.class_name
            error(err)
        end
    end
end

return BaseSystem
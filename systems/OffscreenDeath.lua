local vars = require 'vars'
local BaseSystem = require 'engine.BaseSystem'
local mishape = require 'lib.mishape'

local GROUP_NAME = 'offscreen_death'

local OffscreenDeath = BaseSystem:extend()
OffscreenDeath.group = BaseSystem.createFilter(GROUP_NAME)

function OffscreenDeath:init()
    self.group_name = GROUP_NAME
    self.validator = mishape({
        speed = 'number',
        vector = { x = 'number', y = 'number' }
    })
end

function OffscreenDeath:addToGroup(group_name, e)
    if group_name == GROUP_NAME then
        self:validateEntity(e)
    end
end

function OffscreenDeath:update()
    for _, e in ipairs(self.pool.groups[GROUP_NAME].entities) do
        if
            e.x > vars.gw
            or e.x + e.width < 0
            or e.y > vars.gh
            or e.y + e.height < 0
        then
            e.dead = true
        end
    end
end

return OffscreenDeath
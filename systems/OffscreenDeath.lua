local vars = require 'vars'
local Object = require 'lib.classic'

local GROUP_NAME = 'projectile'

local group = {
    [GROUP_NAME] = {
        filter = { 'speed', 'vector' }
    }
}

local OffscreenDeath = Object:extend()

function OffscreenDeath:init()
end

function OffscreenDeath:update(dt)
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

return {
    system = OffscreenDeath,
    group = group
}
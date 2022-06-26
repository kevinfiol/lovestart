local util = require 'engine.util'
local vars = require 'vars'
local Object = require 'lib.classic'
local mishape = require 'lib.mishape'

local GROUP_NAME = 'offscreen_death'
local VALIDATOR = mishape({
    speed = 'number',
    vector = { x = 'number', y = 'number' }
})

local group = {
    [GROUP_NAME] = {
        filter = function (e)
            return util.contains(e.systems, GROUP_NAME)
        end
    }
}

local OffscreenDeath = Object:extend()

function OffscreenDeath:init()
end

function OffscreenDeath:addToGroup(group_name, e)
    if group_name == GROUP_NAME then
        if _G.DEBUG then
            if not VALIDATOR(e).ok then
                local err = '[' .. GROUP_NAME .. '] objects must follow mishape schema.'
                    .. '\n\t entity class_name: ' .. e.class_name
                error(err)
            end
        end
    end
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
    GROUP_NAME = GROUP_NAME,
    system = OffscreenDeath,
    group = group
}
local lume = require 'lib.lume'
local Object = require 'lib.classic'
local Enum = require 'enum'

local GROUP_NAME = 'physics'

local group = {
    [GROUP_NAME] = {
        filter = {
            'x',
            'y',
            'vel',
            'accel',
            'max_vel',
            'drag',
            'angle',
            'angular_vel'
        }
    }
}

local Physics = Object:extend()

function Physics:init()
end

function Physics:update(dt)
    if dt == 0 then return end
    for _, e in ipairs(e.pool.groups[GROUP_NAME].entities) do
        -- update velocity
        e.vel.x = e.vel.x + e.accel.x * dt
        e.vel.y = e.vel.y + e.accel.y * dt

        -- update max velocity
        if math.abs(e.vel.x) > e.max_vel.x  then
            e.vel.x = e.max_vel.x * lume.sign(e.vel.x)
        end

        if math.abs(e.vel.y) > e.max_vel.x  then
            e.vel.y = e.max_vel.y * lume.sign(e.vel.y)
        end

        -- update position
        e.x = e.x + e.vel.x * dt
        e.y = e.y + e.vel.y * dt

        -- update drag
        if e.accel.x == 0 and e.drag.x > 0 then
            local sign = lume.sign(e.vel.x)
            e.vel.x = e.vel.x - e.drag.x * dt * sign
            if (e.vel.x < 0) ~= (sign < 0) then
                e.vel.x = 0
            end
        end

        if e.accel.y == 0 and e.drag.y > 0 then
            local sign = lume.sign(e.vel.y)
            e.vel.y = e.vel.x - e.drag.y * dt * sign
            if (e.vel.y < 0) ~= (sign < 0) then
                e.vel.y = 0
            end
        end

        -- update angle
        e.angle = e.angle + e.angular_vel * dt
    end
end

return {
    system = Physics,
    group = group
}
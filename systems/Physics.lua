local Enum = require 'enum'
local Rectangle = require 'engine.Rectangle'
local lume = require 'lib.lume'
local BaseSystem = require 'engine.BaseSystem'
local mishape = require 'lib.mishape'

local GROUP_NAME = Enum.System.Physics

local Physics = BaseSystem:extend()
Physics.group = BaseSystem.createFilter(GROUP_NAME)

function Physics:init()
    self.group_name = GROUP_NAME
    self.validator = mishape({
        x = 'number',
        y = 'number',
        angle = 'number',
        angular_vel = 'number',
        vel = { x = 'number', y = 'number' },
        accel = { x = 'number', y = 'number' },
        max_vel = { x = 'number', y = 'number' },
        drag = { x = 'number', y = 'number' },
        last = 'object'
    })
end

function Physics:addToGroup(group_name, e)
    if group_name == GROUP_NAME then
        self:validateEntity(e)

        if not e.last then
            e.last = Rectangle(e.x, e.y, e.width, e.height)
        end
    end
end

function Physics:update(dt)
    if dt == 0 then return end
    for _, e in ipairs(self.pool.groups[GROUP_NAME].entities) do
        -- store last position
        -- e.last is an instance of Rectangle
        e.last:set(e.x, e.y, e.width, e.height)

        -- update velocity
        e.vel.x = e.vel.x + e.accel.x * dt
        e.vel.y = e.vel.y + e.accel.y * dt

        -- check max velocity
        if math.abs(e.vel.x) > e.max_vel.x  then
            e.vel.x = e.max_vel.x * lume.sign(e.vel.x)
        end

        if math.abs(e.vel.y) > e.max_vel.y  then
            e.vel.y = e.max_vel.y * lume.sign(e.vel.y)
        end

        -- update position
        e.x = e.x + e.vel.x * dt
        e.y = e.y + e.vel.y * dt

        -- check drag
        if e.accel.x == 0 and e.drag.x > 0 then
            local sign = lume.sign(e.vel.x)
            e.vel.x = e.vel.x - e.drag.x * dt * sign
            if (e.vel.x < 0) ~= (sign < 0) then
                e.vel.x = 0
            end
        end

        if e.accel.y == 0 and e.drag.y > 0 then
            local sign = lume.sign(e.vel.y)
            e.vel.y = e.vel.y - e.drag.y * dt * sign
            if (e.vel.y < 0) ~= (sign < 0) then
                e.vel.y = 0
            end
        end

        -- update angle
        e.angle = e.angle + e.angular_vel * dt
    end
end

return Physics
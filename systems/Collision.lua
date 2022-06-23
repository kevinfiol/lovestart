local lume = require 'lib.lume'
local Enum = require 'enum'
local shash = require 'lib.shash'
local Object = require 'lib.classic'

local GROUP_NAME = 'collision'
local CLASS = Enum.Collision.Class

local collisions

local ignores = {
    [CLASS.Player] = { CLASS.Wall },
    [CLASS.Wall] = {}
}

local group = {
    [GROUP_NAME] = {
        filter = {
            'collision',
            'last'
        }
    }
}

local properties = {}

local function wasVerticallyAligned(a, b)
    return a.last.y < b.last.y + b.height
        and a.last.y + a.height > b.last.y
end

local function wasHorizontallyAligned(a, b)
    return a.last.x < b.last.x + b.width
        and a.last.x + a.width > b.last.x
end

local Collision = Object:extend()

function Collision:init()
    collisions = shash.new(64)
end

function Collision:addToGroup(group_name, e)
    if group_name == GROUP_NAME then
        -- init entity properties only visible to this system
        properties[e] = { has_collided = false }

        -- add to spatial hash
        collisions:add(e, e.x, e.y, e.width, e.height)

        p(e.collision.class)
    end
end

function Collision:removeFromGroup(group_name, e)
    if group_name == GROUP_NAME then
        properties[e] = nil
        collisions:remove(e)
    end
end

function Collision:update(dt)
    local entities = self.pool.groups[GROUP_NAME].entities

    for _, e in ipairs(entities) do
        collisions:update(e, e.x, e.y, e.width, e.height)
    end

    for _, e in ipairs(entities) do
        local overlaps = false

        collisions:each(e, function(o)
            overlaps = true
            local collide = not e.collision.immovable and lume.find(ignores[e.collision.class]) == nil
            local side = nil

            if wasVerticallyAligned(e, o) then
                if e.x + e.width / 2 < o.x + o.width / 2 then
                    -- right collision
                    if collide then
                        e.x = e.x - (e.x + e.width - o.x)
                    end
                elseif e.x + e.width / 2 > o.x + o.width / 2 then
                    -- left collision
                    if collide then
                        e.x = e.x + (o.x + o.width - e.x)
                    end
                end

                -- after collision has been resolved (and maybe corrected) get side
                if e.x + e.width == o.x then
                    side = 'right'
                elseif e.x == o.x + o.width then
                    side = 'left'
                end
            elseif wasHorizontallyAligned(e, o) then
                if e.y + e.height / 2 < o.y + o.height / 2 then
                    -- bottom collision
                    if collide then
                        e.y = e.y - (e.y + e.height - o.y)
                    end
                elseif e.y + e.height / 2 > o.y + o.height / 2 then
                    -- top collision
                    if collide then
                        e.y = e.y + (o.y + o.height - e.y)
                    end
                end

                if e.y + e.height == o.y then
                    side = 'bottom'
                elseif e.y == o.y + o.height then
                    side = 'top'
                end
            end

            if not properties[e].has_collided and side then
                properties[e].has_collided = true
                if e.collision.events and e.collision.events[o.collision.class] then
                    e.collision.events[o.collision.class](o, side)
                end
            end
        end)

        if not overlaps then
            properties[e].has_collided = false
        end
    end
end

return {
    system = Collision,
    group = group
}
local util = require 'engine.util'
local mishape = require 'lib.mishape'
local shash = require 'lib.shash'
local Object = require 'lib.classic'
local Enum = require 'enum'

local GROUP_NAME = 'collision'
local CLASS = Enum.Collision.Class
local VALIDATOR = mishape({
    collision = {
        class = 'string',
        immovable = 'boolean|nil',
        events = 'object|nil',
        touching = 'object|nil'
    },
    last = 'object|nil'
})

local group = {
    [GROUP_NAME] = {
        filter = function (e)
            return util.contains(e.systems, GROUP_NAME)
        end
    }
}

-- spatial hash
local collisions

-- collision class ignores
-- by default, all classes collide with other classes
local ignores = {
    [CLASS.Player] = {},
    [CLASS.Wall] = {}
}

-- essentially a weakMap holding properties for each entity,
-- but only in the scope of this module
-- reduces property pollution in entities
local entity_props = {}

local function isTouching(a, b)
    return a.x + a.width >= b.x
        and a.x <= b.x + b.width
        and a.y + a.height >= b.y
        and a.y <= b.y + b.height
end

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
        if _G.DEBUG then
            if not VALIDATOR(e).ok then
                local err = '[' .. GROUP_NAME .. '] objects must follow mishape schema.'
                    .. '\n\t entity class_name: ' .. e.class_name
                error(err)
            end
        end

        if not e.last then
            -- monkey-patch it in in the case that the entity is not using the `physics` system
            -- in this case, the entity is most likely an `immovable`
            e.last = { x = e.x, y = e.y }
        end

        if not e.touching then
            e.touching = {}
        end

        -- init entity properties only visible to this system
        entity_props[e] = { has_collided = false }

        -- add to spatial hash
        collisions:add(e, e.x, e.y, e.width, e.height)

        p(e.collision.class)
    end
end

function Collision:removeFromGroup(group_name, e)
    if group_name == GROUP_NAME then
        entity_props[e] = nil
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
            local collide = not e.collision.immovable
                and not util.contains(ignores[e.collision.class], o.collision.class)
            local side = nil

            if wasVerticallyAligned(e, o) then
                if e.x + e.width / 2 < o.x + o.width / 2 then
                    -- right collision
                    if collide then
                        e.x = e.x - (e.x + e.width - o.x)
                    end

                    side = 'right'
                elseif e.x + e.width / 2 > o.x + o.width / 2 then
                    -- left collision
                    if collide then
                        e.x = e.x + (o.x + o.width - e.x)
                    end

                    side = 'left'
                end
            elseif wasHorizontallyAligned(e, o) then
                if e.y + e.height / 2 < o.y + o.height / 2 then
                    -- bottom collision
                    if collide then
                        e.y = e.y - (e.y + e.height - o.y)
                    end

                    side = 'bottom'
                elseif e.y + e.height / 2 > o.y + o.height / 2 then
                    -- top collision
                    if collide then
                        e.y = e.y + (o.y + o.height - e.y)
                    end

                    side = 'top'
                end
            end

            if not entity_props[e].has_collided and side then
                entity_props[e].has_collided = true
                if e.collision.events and e.collision.events[o.collision.class] then
                    e.collision.events[o.collision.class](o, side)
                end
            end
        end)

        if not overlaps then
            entity_props[e].has_collided = false
        end
    end
end

return {
    GROUP_NAME = GROUP_NAME,
    system = Collision,
    group = group
}
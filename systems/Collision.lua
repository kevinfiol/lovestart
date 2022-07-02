local util = require 'engine.util'
local Rectangle = require 'engine.Rectangle'
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
        touching = 'object|nil',
        transparent = 'object|nil'
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
    [CLASS.Wall] = { CLASS.Wall }
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
            e.last = Rectangle(e.x, e.y, e.width, e.height)
        end

        if not e.collision.touching then
            e.collision.touching = {}
        end

        if not e.collision.transparent then
            -- by default, solid on all sides
            e.collision.transparent = {
                top = false,
                bottom = false,
                left = false,
                right = false
            }
        end

        -- init entity properties only visible to this system
        entity_props[e] = {
            has_collided = false,
            inside_of = {}
        }

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

        if e.x ~= e.last.x then
            e.collision.touching.right = nil
            e.collision.touching.left = nil
        end

        if e.y ~= e.last.y then
            e.collision.touching.bottom = nil
            e.collision.touching.top = nil
        end

        for o, v in pairs(entity_props[e].inside_of) do
            -- check if still inside of other object
            if not isTouching(e, o) then
                entity_props[e].inside_of[o] = nil
            end
        end
    end

    for _, e in ipairs(entities) do
        -- local overlaps = false

        collisions:each(e, function(o)
            -- overlaps = true

            local side = nil
            local collide =
                not entity_props[e].inside_of[o] and
                not e.collision.immovable and
                not util.contains(ignores[e.collision.class], o.collision.class)

            if wasVerticallyAligned(e, o) then
                if e.last:middleX() < o.last:middleX() then
                    -- right collision
                    if e.collision.transparent.right or o.collision.transparent.left then
                        entity_props[e].inside_of[o] = true
                        collide = false
                    end

                    if collide then
                        e.x = e.x - (e.x + e.width - o.x)
                        e.collision.touching.right = true
                    end

                    side = 'right'
                elseif e.last:middleX() > o.last:middleX() then
                    -- left collision
                    if e.collision.transparent.left or o.collision.transparent.right then
                        entity_props[e].inside_of[o] = true
                        collide = false
                    end

                    if collide then
                        e.x = e.x + (o.x + o.width - e.x)
                        e.collision.touching.left = true
                    end

                    side = 'left'
                end
            elseif wasHorizontallyAligned(e, o) then
                if e.last:middleY() < o.last:middleY() then
                    -- bottom collision
                    if e.collision.transparent.bottom or o.collision.transparent.top then
                        entity_props[e].inside_of[o] = true
                        collide = false
                    end

                    if collide then
                        e.y = e.y - (e.y + e.height - o.y)
                        e.collision.touching.bottom = true
                    end

                    side = 'bottom'
                elseif e.last:middleY() > o.last:middleY() then
                    -- top collision
                    if e.collision.transparent.top or o.collision.transparent.bottom then
                        entity_props[e].inside_of[o] = true
                        collide = false
                    end

                    if collide then
                        e.y = e.y + (o.y + o.height - e.y)
                        e.collision.touching.top = true
                    end

                    side = 'top'
                end
            end

            -- if not entity_props[e].has_collided and side then
            --     entity_props[e].has_collided = true
            --     if e.collision.events and e.collision.events[o.collision.class] then
            --         e.collision.events[o.collision.class](o, side)
            --     end
            -- end
        end)

        -- if not overlaps then
        --     entity_props[e].has_collided = false
        -- end
    end
end

return {
    GROUP_NAME = GROUP_NAME,
    system = Collision,
    group = group
}
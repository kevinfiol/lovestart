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

local function isVerticallyAligned(a, b)
    return a.y < b.y + b.height
        and a.y + a.height > b.y
end

local function isHorizontallyAligned(a, b)
    return a.x < b.x + b.width
        and a.x + a.width > b.x
end

local function isOverlapping(a, b)
    return a.x + a.width >= b.x
        and a.x <= b.x + b.width
        and a.y + a.height >= b.y
        and a.y <= b.y + b.height
end

local function isTouching(a, b)
    if isVerticallyAligned(a, b) then
        return a.x + a.width >= b.x - 1
            and a.x <= b.x + b.width + 1
    elseif isHorizontallyAligned(a, b) then
        return a.y + a.height >= b.y - 1
            and a.y <= b.y + b.height + 1
    end

    return false
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
        -- add 1px border to detect when "touching"
        collisions:add(e, e.x + 1, e.y + 1, e.width + 1, e.height + 1)
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
        -- update spatial hash
        -- add 1px border to detect when "touching"
        collisions:update(e, e.x + 1, e.y + 1, e.width + 1, e.height + 1)

        for side, o in pairs(e.collision.touching) do
            if e.collision.class == 'PLAYER' and o ~= nil and not isTouching(e, o) then
                e.collision.touching[side] = nil
            end
        end

        for o, v in pairs(entity_props[e].inside_of) do
            -- check if still inside of other object
            if not isOverlapping(e, o) then
                entity_props[e].inside_of[o] = nil
            end
        end
    end

    for _, e in ipairs(entities) do
        local overlaps = false

        collisions:each(e, function(o)
            if not overlaps then
                overlaps = true
            end

            local side = nil

            local shouldCollide = not (
                entity_props[e].inside_of[o] or
                e.collision.immovable or
                util.contains(ignores[e.collision.class], o.collision.class)
            )

            if isVerticallyAligned(e.last, o.last) then
                if e.last:middleX() < o.last:middleX() then
                    -- right collision
                    if e.collision.transparent.right or o.collision.transparent.left then
                        entity_props[e].inside_of[o] = true
                        shouldCollide = false
                    end

                    if shouldCollide then
                        e.x = e.x - (e.x + e.width - o.x)
                    end

                    side = 'right'
                elseif e.last:middleX() > o.last:middleX() then
                    -- left collision
                    if e.collision.transparent.left or o.collision.transparent.right then
                        entity_props[e].inside_of[o] = true
                        shouldCollide = false
                    end

                    if shouldCollide then
                        e.x = e.x + (o.x + o.width - e.x)
                    end

                    side = 'left'
                end

                -- check if touching
                if (e.x + e.width) == o.x then
                    e.collision.touching.right = o
                elseif e.x == (o.x + o.width) then
                    e.collision.touching.left = o
                end
            elseif isHorizontallyAligned(e.last, o.last) then
                if e.last:middleY() < o.last:middleY() then
                    -- bottom collision
                    if e.collision.transparent.bottom or o.collision.transparent.top then
                        entity_props[e].inside_of[o] = true
                        shouldCollide = false
                    end

                    if shouldCollide then
                        e.y = e.y - (e.y + e.height - o.y)
                    end

                    side = 'bottom'
                elseif e.last:middleY() > o.last:middleY() then
                    -- top collision
                    if e.collision.transparent.top or o.collision.transparent.bottom then
                        entity_props[e].inside_of[o] = true
                        shouldCollide = false
                    end

                    if shouldCollide then
                        e.y = e.y + (o.y + o.height - e.y)
                    end

                    side = 'top'
                end

                -- check if touching
                if (e.y + e.height) == (o.y) then
                    e.collision.touching.bottom = o
                elseif e.y == (o.y + o.height) then
                    e.collision.touching.top = o
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
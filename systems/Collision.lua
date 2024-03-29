local util = require 'engine.util'
local Rectangle = require 'engine.Rectangle'
local mishape = require 'lib.mishape'
local shash = require 'lib.shash'
local System = require 'engine.System'
local Enum = require 'enum'

local GROUP_NAME = 'collision'
local CLASS = Enum.Collision.Class

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

local Collision = System:extend()
Collision.group = System.createFilter(GROUP_NAME)

function Collision:init()
  collisions = shash.new(64)

  self.group_name = GROUP_NAME
  self.validator = mishape({
    last = 'object|nil',
    [GROUP_NAME] = {
      class = 'string',
      immovable = 'boolean|nil',
      events = 'object|nil',
      touching = 'object|nil',
      transparent = 'object|nil'
    }
  })
end

function Collision:addToGroup(group_name, e)
  if group_name == GROUP_NAME then
    self:validateEntity(e)

    if not e.last then
      -- monkey-patch it in in the case that the entity is not using the `physics` system
      -- in that case, the entity is most likely an `immovable`
      e.last = Rectangle(e.x, e.y, e.width, e.height)
    end

    if not e[GROUP_NAME].touching then
      e[GROUP_NAME].touching = {}
    end

    if not e[GROUP_NAME].transparent then
      -- by default, solid on all sides
      e[GROUP_NAME].transparent = {
        top = false,
        bottom = false,
        left = false,
        right = false
      }
    end

    -- init entity properties only visible to this system
    entity_props[e] = {
      has_collided = {
        top = false,
        bottom = false,
        left = false,
        right = false
      },
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

    for side, o in pairs(e[GROUP_NAME].touching) do
      if o ~= nil and not isTouching(e, o) then
        e[GROUP_NAME].touching[side] = nil
        entity_props[e].has_collided[side] = false
      end
    end

    for o, _ in pairs(entity_props[e].inside_of) do
      -- check if still inside of other object
      if not isOverlapping(e, o) then
        entity_props[e].inside_of[o] = nil
      end
    end
  end

  for _, e in ipairs(entities) do
    collisions:each(e, function(o)
      if util.contains(ignores[e[GROUP_NAME].class], o[GROUP_NAME].class) then
        -- ignore
        return
      end

      local side = nil
      local shouldCollide = not (entity_props[e].inside_of[o] or e[GROUP_NAME].immovable)

      if isVerticallyAligned(e.last, o.last) then
        if e.last:middleX() < o.last:middleX() then
          -- right collision
          if e[GROUP_NAME].transparent.right or o[GROUP_NAME].transparent.left then
            entity_props[e].inside_of[o] = true
            shouldCollide = false
          end

          if shouldCollide then
            e.x = e.x - (e.x + e.width - o.x)
          end

          side = 'right'
        elseif e.last:middleX() > o.last:middleX() then
          -- left collision
          if e[GROUP_NAME].transparent.left or o[GROUP_NAME].transparent.right then
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
          e[GROUP_NAME].touching.right = o
        elseif e.x == (o.x + o.width) then
          e[GROUP_NAME].touching.left = o
        end
      elseif isHorizontallyAligned(e.last, o.last) then
        if e.last:middleY() < o.last:middleY() then
          -- bottom collision
          if e[GROUP_NAME].transparent.bottom or o[GROUP_NAME].transparent.top then
            entity_props[e].inside_of[o] = true
            shouldCollide = false
          end

          if shouldCollide then
            e.y = e.y - (e.y + e.height - o.y)
          end

          side = 'bottom'
        elseif e.last:middleY() > o.last:middleY() then
          -- top collision
          if e[GROUP_NAME].transparent.top or o[GROUP_NAME].transparent.bottom then
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
          e[GROUP_NAME].touching.bottom = o
        elseif e.y == (o.y + o.height) then
          e[GROUP_NAME].touching.top = o
        end
      end

      if side and not entity_props[e].has_collided[side] then
        entity_props[e].has_collided[side] = true
        if e[GROUP_NAME].events and e[GROUP_NAME].events[o[GROUP_NAME].class] then
          e[GROUP_NAME].events[o[GROUP_NAME].class](o, side)
        end
      end
    end)
  end
end

return Collision
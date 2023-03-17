local Object = require 'lib.classic'
local nata = require 'lib.nata'
local lume = require 'lib.lume'

local Area = Object:extend()

local function shouldRemove(entity)
  return entity.dead
end

local function onRemove(entity)
  if entity.destroy then
    entity:destroy()
  end
end

function Area:new(...)
  local args = {...}
  local groups = {}
  local systems = {}

  for _, system in ipairs(args) do
    groups = lume.merge(groups, system.group)
    table.insert(systems, system)
  end

  self.pool = nata.new({
    groups = groups,
    systems = {
      nata.oop(),
      unpack(systems)
    }
  })

  -- destroys dead entities
  self.pool:on('remove', onRemove)
end

function Area:update(dt)
  self.pool:flush()
  self.pool:emit('update', dt)

  -- define when to remove entities
  self.pool:remove(shouldRemove)
end

function Area:draw()
  self.pool:emit('draw')
end

function Area:destroy()
  for _, entity in ipairs(self.pool.entities) do
    entity:destroy()
  end

  self.pool = nil
end

function Area:queue(entities)
  for _, entity in pairs(entities) do
    self.pool:queue(entity)
  end
end

return Area
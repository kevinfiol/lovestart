local Rectangle = require 'engine.Rectangle'
local mishape = require 'lib.mishape'

local Entity = Rectangle:extend()

Entity.static = {
    noop = function() end
}

function Entity:new(class_name, area, x, y, width, height)
    Entity.super.new(self, x, y, width, height)
    self.class_name = class_name
    self.area = area
    self.systems = {}
    self.dead = false
end

function Entity:update(dt)
end

function Entity:draw()
end

function Entity:destroy()
    self.dead = true
    self.area = nil

    for k, _ in pairs(self) do
        self[k] = nil
    end
end

-- debug methods
function Entity:schema(schema, custom_map)
    if not _G.DEBUG then return end
    local validator = mishape(schema, custom_map)

    local res = validator(self)
    if not res.ok then
        local error_string = '[mishape]: Schema Errors have occured:\n\t'
        for _, v in ipairs(res.errors) do
            error_string = error_string .. v .. '\n\t'
        end

        error(error_string)
    end
end

return Entity
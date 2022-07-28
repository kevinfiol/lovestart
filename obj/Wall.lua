local Entity = require 'engine.Entity'
local Enum = require 'enum'

local Wall = Entity:extend()

function Wall:new(area, x, y, opts)
    opts = opts or {}
    Wall.super.new(self, 'WALL', area, x, y, opts.width, opts.height)

    self.systems = { 'collision' }
    self.collision = {
        class = Enum.Collision.Class.Wall,
        immovable = true
    }

    self:schema({
        x = 'number',
        y = 'number',
        width = 'number',
        height = 'number',
        collision = {
            class = 'string',
            immovable = 'boolean'
        }
    })
end

function Wall:update(dt)
end

function Wall:draw()
    love.graphics.rectangle(
        'line',
        self.x,
        self.y,
        self.width,
        self.height
    )
end

return Wall

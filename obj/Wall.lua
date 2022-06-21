local GameObject = require 'engine.GameObject'
local Enum = require 'enum'

local Wall = GameObject:extend()

function Wall:new(area, x, y, opts)
    opts = opts or {}
    Wall.super.new(self, area, x, y)

    self.collision = { class = Enum.Collision.Class.Wall }
    self.width = opts.width
    self.height = opts.height

    self:schema({
        x = 'number',
        y = 'number',
        width = 'number',
        height = 'number',
        collision = {
            class = 'string'
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

function Wall:destroy()
    self.width = nil
    self.height = nil
    self.collision = nil
    Wall.super.destroy(self)
end

return Wall

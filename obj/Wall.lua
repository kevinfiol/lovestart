local GameObject = require 'engine.GameObject'
local Enum = require 'enum'

local Wall = GameObject:extend()

function Wall:new(area, x, y, opts)
    opts = opts or {}
    Wall.super.new(self, area, x, y, opts.width, opts.height)

    self.collision = {
        class = Enum.Collision.Class.Wall,
        immovable = true
    }

    self.last = { x = x, y = y }

    self:schema({
        x = 'number',
        y = 'number',
        width = 'number',
        height = 'number',
        last = {
            x = 'number',
            y = 'number'
        },
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

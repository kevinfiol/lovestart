local baton = require 'lib.baton'
local Enum = require 'enum'
local GameObject = require 'engine.GameObject'
local utils = require 'engine.utils'

local Player = GameObject:extend()

local SPEED = 300
local WIDTH = 20
local HEIGHT = 20

function Player:new(area, x, y, opts)
    opts = opts or {}
    opts.width = opts.width or WIDTH
    opts.height = opts.height or HEIGHT
    Player.super.new(self, area, x, y, opts.width, opts.height)

    self.collision = {
        class = Enum.Collision.Class.Player,
        events = {
            [Enum.Collision.Class.Wall] = utils.bind(self, self.onWallCollision)
        }
    }

    self.vel = { x = 0, y = 0 }
    self.accel = { x = 0, y = 0 }
    self.max_vel = { x = 200, y = 200 }
    self.drag = { x = 800, y = 800 }
    self.last = { x = x, y = y }
    self.angle = 0
    self.angular_vel = 0

    self.input = baton.new({
        controls = {
            left = { 'key:left', 'key:a' },
            right = { 'key:right', 'key:d' },
            up = { 'key:up', 'key:w' },
            down = { 'key:down', 'key:s' }
        }
    })

    self:schema({
        collision = {
            class = 'string'
        }
    })
end

function Player:update(dt)
    Player.super.update(self, dt)

    if self.input then
        self.input:update()
        self:move()
    end
end

function Player:draw()
    love.graphics.rectangle(
        'line',
        self.x,
        self.y,
        self.width,
        self.height
    )
end

function Player:move()
    if self.input:down('right') then
        self.accel.x = SPEED
    elseif self.input:down('left') then
        self.accel.x = -SPEED
    else
        self.accel.x = 0
    end

    if self.input:down('up') then
        self.accel.y = -SPEED
    elseif self.input:down('down') then
        self.accel.y = SPEED
    else
        self.accel.y = 0
    end
end

function Player:onWallCollision(wall, side)
    print('hit ' .. wall.collision.class .. ' at ' .. side)
end

return Player
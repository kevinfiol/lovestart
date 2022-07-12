local baton = require 'lib.baton'
local Enum = require 'enum'
local Entity = require 'engine.Entity'
local Rectangle = require 'engine.Rectangle'
local util = require 'engine.util'

local Player = Entity:extend()

local SPEED = 300
local WIDTH = 20
local HEIGHT = 20

function Player:new(area, x, y, opts)
    opts = opts or {}
    opts.width = opts.width or WIDTH
    opts.height = opts.height or HEIGHT
    Player.super.new(self, 'PLAYER', area, x, y, opts.width, opts.height)

    self.systems = { 'physics', 'collision' }
    self.vel = { x = 0, y = 0 }
    self.accel = { x = 0, y = 400 }
    self.max_vel = { x = 200, y = 800 }
    self.drag = { x = 800, y = 800 }
    self.angle = 0
    self.angular_vel = 0
    self.last = Rectangle(self.x, self.y, self.width, self.height)
    self.collision = {
        class = Enum.Collision.Class.Player,
        events = {
            [Enum.Collision.Class.Wall] = util.bind(self, self.onWallCollision)
        }
    }

    self.grounded = false

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
            class = 'string',
            events = 'object'
        }
    })
end

function Player:update(dt)
    Player.super.update(self, dt)

    if self.input then
        self.input:update()
        self:move(dt)
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

function Player:move(dt)
    if self.input:down('right') then
        self.x = self.x - SPEED * dt
    elseif self.input:down('left') then
        self.x = self.x + SPEED * dt
    end
end

function Player:onWallCollision(wall, side)
    if side == 'bottom' then
        self.grounded = true;
        self.accel.y = 0;
    end
end

return Player
local baton = require 'lib.baton'
local Enum = require 'enum'
local Entity = require 'engine.Entity'
local Rectangle = require 'engine.Rectangle'
local util = require 'engine.util'

local Player = Entity:extend()

local SPEED = 130
local WIDTH = 20
local HEIGHT = 20
local GRAVITY = 400
local JUMP_VEL = -400

function Player:new(area, x, y, opts)
    opts = opts or {}
    opts.width = opts.width or WIDTH
    opts.height = opts.height or HEIGHT
    Player.super.new(self, 'PLAYER', area, x, y, opts.width, opts.height)

    self.systems = { 'physics', 'collision' }
    self.vel = { x = 0, y = 0 }
    self.accel = { x = 0, y = GRAVITY }
    self.max_vel = { x = 200, y = 800 }
    self.drag = { x = 800, y = 800 }
    self.angle = 0
    self.angular_vel = 0
    self.last = Rectangle(self.x, self.y, self.width, self.height)
    self.collision = {
        class = Enum.Collision.Class.Player
    }

    self.grounded = false

    self.input = baton.new({
        controls = {
            left = { 'key:left', 'key:a' },
            right = { 'key:right', 'key:d' },
            jump = { 'key:c' }
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

    if self.collision.touching.bottom then
        local o = self.collision.touching.bottom
        if o.class_name == 'WALL' then
            if not self.grounded then
                self.grounded = true
                self.accel.y = 0
            end
        end
    else
        if self.grounded then
            self.grounded = false
            self.accel.y = GRAVITY
        end
    end

    if self.input then
        self.input:update()
        self:move(dt)
        self:jump()
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
    if self.input:down('left') then
        self.x = self.x - SPEED * dt
    elseif self.input:down('right') then
        self.x = self.x + SPEED * dt
    end
end

function Player:jump()
    if not self.grounded then
        return
    end

    if self.input:pressed('jump') then
        self.vel.y = JUMP_VEL
    end
end

function Player:onWallCollision(wall, side)
    if side == 'bottom' then
        self.grounded = true;
        self.accel.y = 0;
    end
end

return Player
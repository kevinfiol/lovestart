local lume = require 'lib.lume'
local baton = require 'lib.baton'
local vars = require 'vars'
local Enum = require 'enum'

local GameObject = require 'engine.GameObject'
local Paddle = require 'obj.Paddle'
local Ball = require 'obj.Ball'

local Player = Paddle:extend()

function Player:new(area, x, y, opts)
    opts = opts or {}
    Player.super.new(self, area, x, y, opts)

    self.collision = { class = Enum.Collision.Class.Player }
    self.input = baton.new({
        controls = {
            shoot = { 'mouse:1' }
        }
    })

    self.shootBall = opts.shootBall or GameObject.static.noop

    self:schema({
        input = 'table',
        shootBall = 'function',
        collision = {
            class = 'string'
        }
    })
end

function Player:update(dt)
    Player.super.update(self, dt)
    self.y = (vars.mouse.y / vars.sy) - self.height / 2

    self.input:update()
    self:shoot()
end

function Player:draw()
    Player.super.draw(self)
end

function Player:shoot()
    if self.input:pressed('shoot') then
        local x = self.x + self.width
        local y = self.y + (self.height / 2) - (Ball.static.HEIGHT / 2)
        local vx, vy = lume.vector(0, 1)
        self.shootBall(x, y, { x = vx, y = vy })
    end
end

function Player:destroy()
    self.input = nil
    Player.super.destroy(self)
end

return Player
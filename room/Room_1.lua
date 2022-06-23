local vars = require 'vars'
local lume = require 'lib.lume'
local Object = require 'lib.classic'
local Area = require 'engine.Area'

local Walls = require 'obj.Walls'
local Player = require 'obj.Player'

local OffscreenDeath = require 'systems.OffscreenDeath'
local Physics = require 'systems.Physics'
local Collision = require 'systems.Collision'

local Room_1 = Object:extend()

-- local FONT = love.graphics.newFont('assets/fonts/m5x7.ttf', 16)
-- FONT:setFilter('nearest', 'nearest')

function Room_1:new()
    self.area = Area(
        lume.merge(
            OffscreenDeath.group,
            Physics.group,
            Collision.group
        )
    , {
        OffscreenDeath.system,
        Physics.system,
        Collision.system
    })

    self.walls = Walls(self.area)
    self.canvas = love.graphics.newCanvas(vars.gw, vars.gh)

    local player = Player(self.area, 10, 10)

    self.area:queue({
        player
    })
end

function Room_1:update(dt)
    if self.area then
        self.area:update(dt)

        if self.ball then
            self.enemy:setPosition({ y = self.ball.y })
        end
    end
end

function Room_1:draw()
    if self.area then
        love.graphics.setCanvas(self.canvas)
        love.graphics.clear()

        -- draw begin
        -- _G.camera:attach(0, 0, vars.gw, vars.gh)
        self.area:draw()
        -- _G.camera:detach()

        -- love.graphics.setFont(FONT)
        -- love.graphics.print(vars.score.p1, vars.gw - (vars.gw - 20), vars.gh / 14)
        -- love.graphics.print(vars.score.p2, vars.gw - 30, vars.gh / 14)

        -- draw end
        love.graphics.setCanvas()
        love.graphics.draw(self.canvas, 0, 0, 0, vars.sx, vars.sy)
    end
end

function Room_1:destroy()
    self.canvas:release()
    self.canvas = nil

    self.walls:destroy()

    self.area:destroy()
    self.area = nil
end

return Room_1
local Object = require 'lib.classic'
local Wall = require 'obj.Wall'
local vars = require 'vars'

local Walls = Object:extend()

function Walls:new(area)
  self.area = area

  self.area:queue({
    Wall(area, { x = 175, y = 50, width = 100, height = 1 }),
    Wall(area, { x = vars.gw, y = 0, width = 1, height = vars.gh }), -- right
    Wall(area, { x = 0, y = 0, width = 1, height = vars.gh }), -- left
    Wall(area, { x = 0, y = 0, width = vars.gw, height = 1 }), -- top
    Wall(area, { x = 0, y = vars.gh, width = vars.gw, height = 1 }) -- bottom
  })
end

function Walls:destroy()
  self.area = nil
end

return Walls

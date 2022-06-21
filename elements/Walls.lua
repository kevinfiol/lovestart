local Object = require 'lib.classic'
local Wall = require 'obj.Wall'
local vars = require 'vars'

local Walls = Object:extend()

function Walls:new(area)
    self.area = area

    self.area:queue({
        -- Wall(area, vars.gw, 0, { width = 1, height = vars.gh }), -- right
        -- Wall(area, 0, 0, { width = 1, height = vars.gh }), -- left
        Wall(area, 0, 0, { width = vars.gw, height = 1 }), -- top
        Wall(area, 0, vars.gh, { width = vars.gw, height = 1 }) -- bottom
    })
end

function Walls:destroy()
    self.area = nil
end

return Walls

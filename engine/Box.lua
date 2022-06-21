local Object = require 'lib.classic'

local Box = Object:extend()

function Box:new(x, y, width, height)
    self.x = x or 0
    self.y = y or 0
    self.width = width or 0
    self.height = height or 0
end

-- function Box:getPosition()

return Box
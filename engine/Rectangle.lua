local Object = require 'lib.classic'

local Rectangle = Object:extend()

function Rectangle:new(x, y, width, height)
  self.x = x or 0
  self.y = y or 0
  self.width = width or 0
  self.height = height or 0
end

function Rectangle:getPosition()
  return self.x, self.y
end

function Rectangle:set(x, y, width, height)
  self.x = x or self.x
  self.y = y or self.y
  self.width = width or self.width
  self.height = height or self.height
end

function Rectangle:left(left)
  if left then self.x = left end
  return self.x
end

function Rectangle:right(right)
  if right then self.x = right - self.width end
  return self.x + self.width
end

function Rectangle:top(top)
  if top then self.y = top end
  return self.y
end

function Rectangle:bottom(bottom)
  if bottom then self.y = bottom - self.height end
  return self.y + self.height
end

function Rectangle:middleX(middle)
  if middle then self.x = middle - self.width / 2 end
  return self.x + self.width / 2
end

function Rectangle:middleY(middle)
  if middle then self.y = middle - self.height / 2 end
  return self.y + self.height / 2
end

function Rectangle:middle()
  return (self.x + self.width / 2), (self.y + self.height / 2)
end

function Rectangle:overlaps(o)
  return o.x + o.width > self.x and o.x < self.x + self.width and
    o.y + o.height > self.y and o.y < self.y + self.height
end

return Rectangle
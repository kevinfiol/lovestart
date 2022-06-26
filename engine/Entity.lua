local Object = require 'lib.classic'
local mishape = require 'lib.mishape'

local Entity = Object:extend()

Entity.static = {
    noop = function() end
}

function Entity:new(class_name, area, x, y, width, height)
    self.class_name = class_name
    self.area = area
    self.systems = {}
    self.x, self.y = x, y
    self.width = width or 1
    self.height = height or 1
    self.dead = false
end

function Entity:update(dt)
end

function Entity:draw()
end

function Entity:destroy()
    self.dead = true
    self.area = nil

    for k, _ in pairs(self) do
        self[k] = nil
    end
end

function Entity:getPosition()
    return self.x, self.y
end

function Entity:setPosition(pos)
    if pos.x then self.x = pos.x end
    if pos.y then self.y = pos.y end
end

function Entity:left(left)
    if left then self.x = left end
    return self.x
end

function Entity:right(right)
    if right then self.x = right - self.width end
    return self.x + self.width
end

function Entity:top(top)
    if top then self.y = top end
    return self.y
end

function Entity:bottom(bottom)
    if bottom then self.y = bottom - self.height end
    return self.y + self.height
end

function Entity:middleX(middle)
    if middle then self.x = middle - self.width / 2 end
    return self.x + self.width / 2
end

function Entity:middleY(middle)
    if middle then self.y = middle - self.height / 2 end
    return self.y + self.height / 2
end

function Entity:middle()
    return (self.x + self.width / 2), (self.y + self.height / 2)
end

function Entity:overlaps(o)
    return o.x + o.width > self.x and o.x < self.x + self.width and
        o.y + o.height > self.y and o.y < self.y + self.height
end

function Entity:reject(o)
    if not self:overlaps(o) then return end
    local diff_x = self:middleX() - o:middleX()
    local diff_y = self:middleY() - o:middleY()

    if math.abs(diff_x) > math.abs(diff_y) then
        if diff_x > 0 then
            o:left(self:right())
        else
            o:right(self:left())
        end
    else
        if diff_y > 0 then
            o:top(self:bottom())
        else
            o:bottom(self:top())
        end
    end
end

-- debug methods
function Entity:schema(schema, custom_map)
    if not _G.DEBUG then return end
    local validator = mishape(schema, custom_map)

    local res = validator(self)
    if not res.ok then
        local error_string = '[mishape]: Schema Errors have occured:\n\t'
        for _, v in ipairs(res.errors) do
            error_string = error_string .. v .. '\n\t'
        end

        error(error_string)
    end
end

return Entity
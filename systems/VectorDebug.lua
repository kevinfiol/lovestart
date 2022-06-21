local Object = require 'lib.classic'

local GROUP_NAME = 'vectored'

local group = {
    filter = { 'vector' }
}

local VectorDebug = Object:extend()

local LINE_MAGNITUDE = 20

function VectorDebug:init()
end

function VectorDebug:update(dt)
end

function VectorDebug:draw()
    for _, e in ipairs(self.pool.groups[GROUP_NAME].entities) do
        local x, y = e:middle()
        love.graphics.line(x, y, (x + e.vector.x * LINE_MAGNITUDE), (y + e.vector.y * LINE_MAGNITUDE))
    end
end

return {
    system = VectorDebug,
    group = group
}
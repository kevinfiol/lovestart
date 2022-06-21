require 'global'
local vars = require 'vars'
local RoomManager = require 'engine.RoomManager'
local baton = require 'lib.baton'

local cursor
local rooms
local debug_input

local function resize(s)
    love.window.setMode(s * vars.gw, s * vars.gh)
    vars.sx, vars.sy = s, s
end

function init()
    rooms:goToRoom('Room_1')
end

function love.load()
    if arg[#arg] == "-debug" then
        require("mobdebug").start()
    end

    if _G.DEBUG then
        debug_input = baton.new({
            controls = {
                reset = { 'key:r' }
            }
        })
    end

    -- initialize room manager
    rooms = RoomManager()

    -- default cursor
    cursor = love.mouse.newCursor('assets/sprite/crosshair.png', 16 / vars.sx, 16 / vars.sy)
    love.mouse.setCursor(cursor)

    -- scale window
    resize(2)

    -- init mouse position
    vars.mouse.x, vars.mouse.y = love.mouse.getPosition()

    -- adjust filter mode and line style for pixelated look
    love.graphics.setDefaultFilter('nearest', 'nearest')
    love.graphics.setLineStyle('rough')

    init()
end

function love.update(dt)
    if _G.DEBUG then
        -- file hotswap
        require('lib.lurker').update()
        debug_input:update()

        if debug_input:pressed('reset') then
            init()
        end
    end

    if rooms.current_room then
        rooms.current_room:update(dt)
    end

    _G.camera:update(dt)
    vars.mouse.x, vars.mouse.y = love.mouse.getPosition()
end

function love.draw()
    if rooms.current_room then
        rooms.current_room:draw()
    end
end

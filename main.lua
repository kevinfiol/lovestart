require 'global'
local vars = require 'vars'
local RoomManager = require 'engine.RoomManager'
local baton = require 'lib.baton'

---@type love.Cursor
local cursor
---@type RoomManager
local rooms

local debug_input

---@param s number
local function resize(s)
    love.window.setMode(s * vars.gw, s * vars.gh)
    vars.sx, vars.sy = s, s
end

local function init()
    rooms:goToRoom('Room_1')
end

function love.load()
    if arg[#arg] == "-debug" then
        require("mobdebug").start()
    end

    if _G.DEBUG then
        debug_input = baton.new({
            controls = {
                reset = { 'key:r' },
                boxes = { 'key:1' }
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
        local lurker = require 'lib.lurker'
        lurker.update()

        -- will call init after every swap
        lurker.postswap = init

        -- debug controls
        debug_input:update()
        if debug_input:pressed('reset') then
            init()
        end

        if debug_input:pressed('boxes') then
            if _G.DEBUG_BOXES == nil then
                _G.DEBUG_BOXES = true
            else
                _G.DEBUG_BOXES = not _G.DEBUG_BOXES
            end
        end
    end

    if rooms.current_room then
        rooms.current_room:update(dt)
    end

    _G.camera:update(dt)
    vars.mouse.x, vars.mouse.y = love.mouse.getPosition()
end

function love.draw()
    if _G.DEBUG then
        love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
        love.graphics.print('RAM (in mB): ' .. collectgarbage('count') / 1000, 10, 30)
    end
    if rooms.current_room then
        rooms.current_room:draw()
    end
end

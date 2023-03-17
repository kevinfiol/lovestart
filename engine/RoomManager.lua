local Object = require 'lib.classic'

---@class RoomManager @parent class
---@field private current_room table|nil
local RoomManager = Object:extend()
local ROOM_DIR = 'room'

function RoomManager:new()
  self.current_room = nil
end

---@param room_type string
---@vararg any[]
function RoomManager:goToRoom(room_type, ...)
  self:destroyCurrentRoom()
  ---@type table
  local roomClass = require(ROOM_DIR .. '.' .. room_type)
  self.current_room = roomClass(...)
end

function RoomManager:destroyCurrentRoom()
  if self.current_room and self.current_room.destroy then
    self.current_room:destroy()
    self.current_room = nil
  end
end

return RoomManager

local function noop() end

-- _G.DEBUG = false
_G.DEBUG = true

local Camera = require 'lib.camera'
_G.camera = Camera()

-- cli debugger
_G.debugger = _G.DEBUG and require 'lib.debugger' or noop

-- logger
_G.log = _G.DEBUG and require 'lib.log' or noop

-- print helper
local inspect = require 'lib.inspect'
p = _G.DEBUG and function(t)
  if type(t) == 'table' then
    print(inspect(t))
  else
    print(t)
  end
end or noop

-- typeok type checker (lib/typeok)
local typeok = require 'lib.typeok'
types = _G.DEBUG and function(t, map)
  if not DEBUG then return end
  local res = typeok(t, map)
  if not res.ok then
    local error_string = '[typeok]: Type Errors have occured:\n\t'
    for _, v in ipairs(res.errors) do
      error_string = error_string .. v .. '\n\t'
    end

    error(error_string)
  end
end or noop
local Object = require 'lib.classic'

local System = Object:extend()

System.createFilter = function (group_name)
  return {
    [group_name] = {
      filter = { group_name }
    }
  }
end

function System:validateEntity(e)
  if _G.DEBUG then
    if self.validator and not self.validator(e).ok then
      local err = '[' .. self.group_name .. '] objects must follow mishape schema.'
        .. '\n\t entity class_name: ' .. e.class_name
      error(err)
    end
  end
end

return System
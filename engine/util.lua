if not _G then _G = {} end
_G.global_type_table = nil

local type_name = function(o)
  if _G.global_type_table == nil then
    _G.global_type_table = {}
      for k,v in pairs(_G) do
      _G.global_type_table[v] = k
    end
  _G.global_type_table[0] = "table"
  end
  return _G.global_type_table[getmetatable(o) or 0] or "Unknown"
end

local count_all = function(f)
  local seen = {}
  local count_table
  count_table = function(t)
    if seen[t] then return end
      f(t)
    seen[t] = true
    for k,v in pairs(t) do
      if type(v) == "table" then
      count_table(v)
      elseif type(v) == "userdata" then
      f(v)
      end
  end
  end
  count_table(_G)
end

local type_count = function()
  local counts = {}
  local enumerate = function (o)
    local t = type_name(o)
    counts[t] = (counts[t] or 0) + 1
  end
  count_all(enumerate)
  return counts
end

return {
  contains = function(list, val)
    for _, v in ipairs(list) do
      if v == val then return true end
    end

    return false
  end,

  bind = function(x, fn)
    return function(...)
      local args = {...}
      return fn(x, (table.unpack or unpack)(args))
    end
  end,

  random = function(min, max)
    return love.math.random() * (max - min) + min
  end,

  collectGarbage = function()
    print("Before collection: " .. collectgarbage("count")/1024)
    collectgarbage()
    print("After collection: " .. collectgarbage("count")/1024)
    print("Object count: ")
    local counts = type_count()
    for k, v in pairs(counts) do print(k, v) end
    print("-------------------------------------")
  end,

  pushRotate = function(x, y, r)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(r or 0)
    love.graphics.translate(-x, -y)
  end,

  pushRotateScale = function(x, y, r, sx, sy)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(r or 0)
    love.graphics.scale(sx or 1, sy or sx or 1)
    love.graphics.translate(-x, -y)
  end
}
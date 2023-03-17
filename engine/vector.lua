local vector = {}
vector.__index = vector

-- could also use lume.angle + lume.vector
function vector.getUnitVector(x1, y1, x2, y2)
  local v = { x = (x2 - x1), y = (y2 - y1) }
  local magnitude = math.sqrt((v.x * v.x) + (v.y * v.y))
  v.x = v.x / magnitude
  v.y = v.y / magnitude
  return v
end

function vector.normalize(v)
  local magnitude = math.sqrt((v.x * v.x) + (v.y * v.y))
  local x = v.x / magnitude
  local y = v.y / magnitude
  return { x = x, y = y }
end

function vector.add(a, b)
  return { x = a.x + b.x, y = a.y + b.y }
end

function vector.sub(a, b)
  return { x = a.x - b.x, y = a.y - b.y }
end

function vector.dot(a, b)
  local na = vector.normalize(a)
  return (na.x * b.x) + (na.y * b.y)
end

-- not sure if this is right
function vector.reflect(v, normal)
  local d = vector.dot(v, normal)
  local x = v.x - (2 * d * normal.x)
  local y = v.y - (2 * d * normal.y)
  return { x = x, y = y }
end

return vector
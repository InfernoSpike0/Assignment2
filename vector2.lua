-- vector2.lua
-- Simple 2D vector utility module

local vector2 = {}

function vector2.new(x, y)
    return { x = x or 0, y = y or 0 }
end

function vector2.add(a, b)
    return { x = a.x + b.x, y = a.y + b.y }
end

function vector2.sub(a, b)
    return { x = a.x - b.x, y = a.y - b.y }
end

function vector2.mul(v, scalar)
    return { x = v.x * scalar, y = v.y * scalar }
end

function vector2.len(v)
    return math.sqrt(v.x * v.x + v.y * v.y)
end

function vector2.normalize(v)
    local length = vector2.len(v)
    if length == 0 then
        return { x = 0, y = 0 }
    else
        return { x = v.x / length, y = v.y / length }
    end
end

function vector2.copy(v)
    return { x = v.x, y = v.y }
end

function vector2.tostring(v)
    return "(" .. string.format("%.2f", v.x) .. ", " .. string.format("%.2f", v.y) .. ")"
end


-- NEW 
function vector2.dot(a, b)
    return a.x * b.x + a.y * b.y
end

function vector2.reflect(v, n)
    local dot = vector2.dot(v, n)
    return vector2.sub(v, vector2.mul(n, 2 * dot))
end

return vector2

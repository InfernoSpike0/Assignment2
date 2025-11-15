-- debugging.lua
-- Toggleable debug visualization for vectors, normals, collision boxes, angles
local vec2 = require("vector2")
local dbg = {}

dbg.enabled = true -- Set to true to enable debug drawing

function dbg.toggle()
    dbg.enabled = not dbg.enabled
end

function dbg.drawPlatforms(platforms)
    if not dbg.enabled then return end

    for _, plat in ipairs(platforms) do
        for _, edge in ipairs(plat.edges) do
            -- Draw edge color-coded by tag
            if edge.bounce then
                love.graphics.setColor(1, 0.4, 0.4) -- red = bounce
            elseif edge.wallJump then
                love.graphics.setColor(0.4, 0.7, 1.0) -- blue = wall jump
            else
                love.graphics.setColor(0.6, 0.6, 0.6)
            end

            love.graphics.line(edge.a.x, edge.a.y, edge.b.x, edge.b.y)

            -- Draw normals
            local mid = vec2.mul(vec2.add(edge.a, edge.b), 0.5)
            local normalEnd = vec2.add(mid, vec2.mul(edge.normal, 10))
            love.graphics.setColor(1, 1, 0)
            love.graphics.line(mid.x, mid.y, normalEnd.x, normalEnd.y)

            -- Arrowhead for normal
            local arrowDir = vec2.mul(edge.normal, 6)
            local perp = vec2.new(-arrowDir.y, arrowDir.x)
            local left = vec2.sub(normalEnd, vec2.mul(perp, 0.3))
            local right = vec2.add(normalEnd, vec2.mul(perp, 0.3))
            love.graphics.line(normalEnd.x, normalEnd.y, left.x, left.y)
            love.graphics.line(normalEnd.x, normalEnd.y, right.x, right.y)
        end
    end
end

function dbg.drawPlayerState(p)
    if not dbg.enabled then return end

    love.graphics.setColor(1, 1, 0)
    love.graphics.print("Grounded: " .. tostring(p.isGrounded), 10, 100)
    love.graphics.print("Can Wall Jump: " .. tostring(p.canWallJump), 10, 125)
    love.graphics.print("Can Bounce: " .. tostring(p.canBounce), 10, 140)
    love.graphics.print("hasDash: " .. tostring(p.hasDash), 10, 165)

    -- Draw wall normal if available
    if p.wallNormal then
        local base = vec2.add(p.position, vec2.mul(p.size, 0.5))
        local tip = vec2.add(base, vec2.mul(p.wallNormal, 20))
        love.graphics.setColor(1, 0.5, 1)
        love.graphics.line(base.x, base.y, tip.x, tip.y)
    end

    -- Draw player velocity vector
    dbg.drawVector(
        p.position.x + p.size.x/2,
        p.position.y + p.size.y/2,
        p.velocity,
        0.7,
        {1, 0, 0},
        "Velocity"
    )

end
-- Draw a vector with an arrow starting at (x,y) pointing in direction vec (vector2)
function dbg.drawVector(x, y, vec, scale, color, label)
    if not dbg.enabled then return end

    local len = math.sqrt(vec.x * vec.x + vec.y * vec.y)
    if len == 0 then return end

    --local scale = 50 -- length scale for display
    local endX = x + vec.x * scale
    local endY = y + vec.y * scale

    love.graphics.setColor(color[1], color[2], color[3], 1)
    love.graphics.setLineWidth(2)
    love.graphics.line(x, y, endX, endY)

    -- Arrowhead
    local angle = math.atan2(vec.y, vec.x)
    local arrowSize = 6
    local arrowAngle = math.pi / 6
    local leftX = endX - arrowSize * math.cos(angle - arrowAngle)
    local leftY = endY - arrowSize * math.sin(angle - arrowAngle)
    local rightX = endX - arrowSize * math.cos(angle + arrowAngle)
    local rightY = endY - arrowSize * math.sin(angle + arrowAngle)

    love.graphics.line(endX, endY, leftX, leftY)
    love.graphics.line(endX, endY, rightX, rightY)

    if label then
        love.graphics.print(label, endX + 5, endY + 5)
    end
end

-- Draw axis-aligned bounding box (AABB)
function dbg.drawAABB(aabb, color)
    if not dbg.enabled then return end

    love.graphics.setColor(color[1], color[2], color[3], 0.4)
    love.graphics.rectangle("fill", aabb.x, aabb.y, aabb.w, aabb.h)
    love.graphics.setColor(color[1], color[2], color[3], 1)
    love.graphics.rectangle("line", aabb.x, aabb.y, aabb.w, aabb.h)
end

-- Draw a circle (center + radius)
function dbg.drawCircle(circle, color)
    if not dbg.enabled then return end

    love.graphics.setColor(color[1], color[2], color[3], 0.4)
    love.graphics.circle("fill", circle.x, circle.y, circle.r)
    love.graphics.setColor(color[1], color[2], color[3], 1)
    love.graphics.circle("line", circle.x, circle.y, circle.r)
end

-- Draw an angle arc at (x, y) from startAngle to endAngle in radians
function dbg.drawAngleArc(x, y, radius, startAngle, endAngle, color)
    if not dbg.enabled then return end

    local segments = 20
    love.graphics.setColor(color[1], color[2], color[3], 0.7)
    local prevX, prevY
    for i = 0, segments do
        local t = i / segments
        local angle = startAngle + t * (endAngle - startAngle)
        local px = x + radius * math.cos(angle)
        local py = y + radius * math.sin(angle)
        if i > 0 then
            love.graphics.line(prevX, prevY, px, py)
        end
        prevX, prevY = px, py
    end
end

return dbg

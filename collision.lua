local vec2 = require("vector2")
local M = {}

local function pointInPolygon(p, vertices)
    local x, y = p.x, p.y
    local inside = false

    local j = #vertices
    for i = 1, #vertices do
        local xi, yi = vertices[i].x, vertices[i].y
        local xj, yj = vertices[j].x, vertices[j].y

        local intersect = ((yi > y) ~= (yj > y)) and
                          (x < (xj - xi) * (y - yi) / (yj - yi + 0.000001) + xi)

        if intersect then inside = not inside end
        j = i
    end

    return inside
end

function M.resolvePolygonCollisions(p, platforms)
    local padding = 0.1

    -- Player AABB corners
    local corners = {
        vec2.new(p.position.x, p.position.y),
        vec2.new(p.position.x + p.size.x, p.position.y),
        vec2.new(p.position.x, p.position.y + p.size.y),
        vec2.new(p.position.x + p.size.x, p.position.y + p.size.y)
    }

    local totalPush = vec2.new(0, 0)
    local pushCount = 0
    local grounded = false

    -- Track strongest bounce and wall jump normals
    local bounceNormal = nil
    local bounceDot = 1
    local wallJumpNormal = nil
    local wallJumpDot = 1
    p.canBounce = false
    for _, plat in ipairs(platforms) do
        for _, corner in ipairs(corners) do
            if pointInPolygon(corner, plat.points) then
                local maxPenetration = -math.huge
                local bestPush = nil
                local bestNormal = nil
                local bestBounce = false
                local bestWallJump = false

                for _, edge in ipairs(plat.edges) do
                    local n = vec2.new(edge.normal.x, edge.normal.y)
                    local toCorner = vec2.sub(corner, edge.a)
                    local dist = vec2.dot(toCorner, n)

                    if dist > maxPenetration then
                        maxPenetration = dist
                        bestPush = vec2.mul(n, dist + padding)
                        bestNormal = n
                        bestBounce = edge.bounce
                        bestWallJump = edge.wallJump
                       
                    end
                end

                if bestPush then
                    totalPush = vec2.add(totalPush, bestPush)
                    pushCount = pushCount + 1

                    -- Ground detection (normal close to up)
                    local up = vec2.new(0, -1)
                    local angle = math.acos(vec2.dot(vec2.normalize(bestNormal), up))
                    if angle < math.rad(45) then
                        grounded = true
                    end

                    -- Track bounce edge with most horizontal direction
                    if bestBounce then
                        local d = math.abs(vec2.dot(vec2.normalize(bestNormal), up))
                        if d < bounceDot then
                            bounceDot = d
                            bounceNormal = bestNormal
                        end
                    end

                    -- Track wall jump edge
                    if bestWallJump then
                        local d = math.abs(vec2.dot(vec2.normalize(bestNormal), up))
                        if d < wallJumpDot then
                            wallJumpDot = d
                            wallJumpNormal = bestNormal
                        end
                    end
                end
            end
        end
    end

    -- Apply collision response
    if pushCount > 0 then
        local avgPush = vec2.mul(totalPush, 1 / pushCount)
        p.position = vec2.sub(p.position, avgPush)

        local pushNormal = vec2.normalize(avgPush)
        local intoSurface = vec2.dot(p.velocity, pushNormal)

        local up = vec2.new(0, -1)
        local angle = math.acos(vec2.dot(pushNormal, up))

        -- Ground stops downward motion
        if grounded and p.velocity.y > 0 then
            p.velocity.y = 0
        end

        if grounded then
            p.isGrounded = true
        end

        -- Bounce off walls/ceilings
        if bounceNormal and vec2.dot(p.velocity, bounceNormal) < 0 then
            p.canBounce = true
            local normal = vec2.normalize(bounceNormal)
            local reflected = vec2.reflect(p.velocity, normal)
            p.velocity = vec2.mul(reflected, 0.7)
    
            if math.abs(p.velocity.x) < 10 then
                    p.velocity.x = 0
            end
        end
    end

    -- Wall jump detection
    if wallJumpNormal then
        p.canWallJump = true
        p.wallNormal = wallJumpNormal
    end
end

return M

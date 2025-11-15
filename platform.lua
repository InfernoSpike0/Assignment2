local platforms = {}

 function platforms.createPolygonPlatform(pointList, edgeFlags)
    local platform = {
        points = pointList,
        edges = {}
    }

    for i = 1, #pointList do
        local a = pointList[i]
        local b = pointList[i % #pointList + 1]

        local dx, dy = b.x - a.x, b.y - a.y
        local len = math.sqrt(dx * dx + dy * dy)
        local normal = {x = -dy / len, y = dx / len}

        local edge = {
            a = a,
            b = b,
            normal = normal,
            bounce = edgeFlags and edgeFlags[i] == "bounce",
            wallJump = edgeFlags and edgeFlags[i] == "wallJump"
        }

        table.insert(platform.edges, edge)
    end

    table.insert(platforms, platform)
end

function platforms.draw()
    for _, plat in ipairs(platforms) do
        love.graphics.setColor(0.3, 0.3, 0.3)
        --love.graphics.rectangle("fill", plat.x, plat.y, plat.w, plat.h)
        local vertexList = {}
        for _, pt in ipairs(plat.points) do
            table.insert(vertexList, pt.x)
            table.insert(vertexList, pt.y)
        end

        -- Draw filled polygon
        love.graphics.setColor(0.2, 0.2, 0.2, 1)
        love.graphics.polygon("fill", vertexList)

        -- Draw polygon outline
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.setLineWidth(2)
        love.graphics.polygon("line", vertexList)
    end

end


return platforms
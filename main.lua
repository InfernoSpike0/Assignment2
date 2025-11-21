local player    = require("player")
local platforms = require("platform")
local collision = require("collision")
local vec2      = require("vector2")
local dbg       = require("debugging") 
local sprite    = require("sprite")
local chicken   = require("chicken")
local camera    = require("camera")

function love.load()
    love.window.setTitle("Step 9: Camera")
    love.window.setMode(800, 600)

    player.load()

    -- load chicken sprites
    chicken.loadAssets()
    chicken.spawn(500, 550 - 64)
    chicken.spawn(650, 550 - 64)


    -- sloped platform
    platforms.createPolygonPlatform({
        {x=100, y=600 - 4*64},
        {x=300, y=600 - 2*64},
        {x=500, y=600 - 2*64},
        {x=500, y=600 - 4*64}},
        {
            "sticky", nil, "bounce", nil
        }
    )

    -- ground platform
    platforms.createPolygonPlatform({
        {x=0,   y=600},
        {x=800, y=600},
        {x=800, y=550},
        {x=0,   y=550}},
        {
            nil, "bounce", nil, "bounce"
        }
    )
end

function love.keypressed(key)
    if key == "f1" then
        dbg.enabled = not dbg.enabled
    elseif key == "e" then
    player.fireBullet()
elseif key == "r" or key == "m" then
    player.fireMissile()
elseif key == "t" then
    player.setTarget(chicken.list)
    
    end
end


-- update everything here
function love.update(dt)
    -- update the player based on time elapsed
    player.update(dt, platforms, collision.resolvePolygonCollisions)

    local screenWidth, screenHeight = love.graphics.getDimensions()

    -- camera target = player center
    local target = vec2.add(player.position, vec2.mul(player.size, 0.5))
    camera.centerOn(target, screenWidth, screenHeight)
    -- (later you can switch this to camera.checkDeadzone if needed)

    -- update all chickens (AI + lasers)
    chicken.updateAll(dt, player)
end

function love.draw()
    -- world space
    camera.attach()
        platforms.draw()
        player.draw()

        -- chicken enemies + their eye lasers + debug FOV
        chicken.drawAll()

        dbg.drawPlatforms(platforms)
        dbg.drawPlayerState(player)
    camera.detach()

    -- screen space (UI)
    love.graphics.print("Step 9: Camera ", 10, 10)
end

--[[
Challenge Tasks
-- 1. fix the target position in love.update to center the camera on the player
-- 2. try changing the target position dynamically to scroll the camera until the player sprite is at the edge of the screen
-- 3. create a 'deadzone' rectangle in the center of the screen where the player can move without moving the camera
--    when the player moves outside this rectangle, move the camera to keep the player inside it
--       e.g. deadzone = {x=200, y=100}  -- width and height of deadzone rectangle centered on screen
--    use camera.checkDeadzone(target, deadzone, screenWidth, screenHeight) to implement this
--    you will need to implement camera.checkDeadzone in camera.lua
--    usage: e.g. camera.checkDeadzone(target, {x=200, y=100}, screenWidth, screenHeight)
--    use this instead of camera.centerOn in love.update
-- 4. add zoom in/out functionality to the camera (change camera.scale) based on player input
--]]

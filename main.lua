local player = require("player")
local platforms = require("platform")
local collision = require("collision")
local vec2 = require("vector2")
local dbg = require("debugging") -- Go to debugging.lua to switch on/off
local sprite = require("sprite")

-- Look for comments with "--> DO SOMETHING HERE" and complete the tasks within camera.lua and main.lua
-- NEW:
local camera = require("camera")

-----------------------------------------------
function love.load()
    love.window.setTitle("Step 9: Camera")
    love.window.setMode(800, 600)
    player.load()

    platforms.createPolygonPlatform({
        {x=100, y=600 - 4*64},
        {x=300, y=600 - 2*64},
        {x=500, y=600 - 2*64},
        {x=500, y=600 - 4*64}},
        {
            "sticky",nil, "bounce",nil
        }
    )

    platforms.createPolygonPlatform({
        {x=0, y=600},
        {x=800, y=600},
        {x=800, y=550},
        {x=0, y=550}},
        {
            nil, "bounce", nil, "bounce"
        }
    )

end

function love.keypressed(key)
    if key == "f1" then
        dbg.enabled = not dbg.enabled
    end
end

-- update everything here
function love.update(dt)
    -- update the player based on time elapsed
    player.update(dt, platforms, collision.resolvePolygonCollisions)

    local screenWidth, screenHeight = love.graphics.getDimensions()

    -- update the camera
    -- center the camera on the player position
    --     e.g. camera.centerOn(player.position, screenWidth, screenHeight)
    -- to center the player in the screen, we need to offset by half the player size
    -- so the player is in the center of the screen, not the top-left corner

    --> DO SOMETHING HERE
    -- define a target position for the camera to follow
    -- usually this is the player position offset by half the player size
    -- so the player is in the center of the screen, not the top-left corner
    --> target = PlayerPosition + 0.5 * PlayerSize

    target = vec2.new(0,0)  --< fix this!!!!
    target = vec2.add(player.position, vec2.mul(player.size, 0.5)) --<< correct

    -- set the camera to center on the target
    -- this is sometimes called the "look-at" point
    camera.centerOn(target,  screenWidth, screenHeight)
    
end


function love.draw()
    
    -- attach the camera
    -- anything drawn between attach/detach will be transformed by the camera
    -- anything outside will be drawn in screen space (like UI)
    camera.attach()
        -- Draw everything in GameWorld coordinates here 

        platforms.draw()  -- draw the platforms 
        player.draw()     -- draw the player 

        dbg.drawPlatforms(platforms)
        dbg.drawPlayerState(player)
    camera.detach()

    -- Draw everything in Screen space coordinates (pixels) here
    -- UI elements here (like health, score)
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
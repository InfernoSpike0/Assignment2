-- camera.lua

-- This file defines a simple camera system for 2D games using Love2D.
-- The camera can be moved and scaled, and it modifies the drawing coordinates accordingly.
-- It provides functions to set the camera position, center on a target, and attach/detach the camera transformations.
-- The camera is used in main.lua to follow the player character.

local camera = {
    position = { x = 0, y = 0 },
    scale = 1
}

function camera.setPosition(x, y)
    camera.position.x = x
    camera.position.y = y
end

function camera.centerOn(target, screenWidth, screenHeight)
    camera.position.x = target.x - screenWidth / 2
    camera.position.y = target.y - screenHeight / 2
end

function camera.attach()
    love.graphics.push()
    love.graphics.scale(camera.scale)
    love.graphics.translate(-camera.position.x, -camera.position.y)
end

function camera.detach()
    love.graphics.pop()
end


function camera.setScale(s)
    camera.scale = s
end

--> DO SOMETHING HERE
-- implement a deadzone check function for the camera
-- this function will adjust the camera position if the target moves outside a defined deadzone rectangle
-- deadzone is defined by its width and height, centered on the screen
-- usage: camera.checkDeadzone(target, deadzone, screenWidth, screenHeight)
-- e.g. camera.checkDeadzone(target, {x=200, y=100}, screenWidth, screenHeight)
--      this means that the camera moves only if the target moves outside a 400x200 rectangle centered on the screen
function camera.checkDeadzone(target, deadzone, screenWidth, screenHeight)
    -- Calculate the camera bounds
    local camLeft = camera.position.x + deadzone.x
    local camRight = camera.position.x + screenWidth - deadzone.x
    local camTop = camera.position.y + deadzone.y
    local camBottom = camera.position.y + screenHeight - deadzone.y
 
    -- Adjust camera position if target is outside the deadzone\
    -- this is the implementation of the deadzone logic for the y-axis
    if target.y < camTop then
        camera.position.y = target.y - deadzone.y
    elseif target.y > camBottom then
        camera.position.y = target.y - (screenHeight - deadzone.y)
    end

    --> DO SOMETHING HERE
    -- implement the deadzone logic for the x-axis
end

return camera

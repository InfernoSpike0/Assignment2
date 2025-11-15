local vec2 = require("vector2")
local sprite = require("sprite")

local player = {
    position = vec2.new(100, 100),
    size = vec2.new(64, 64),
    velocity = vec2.new(0, 0),
    acceleration = vec2.new(0,0),
    isGrounded = false,
    canWallJump = false,
    wallNormal = nil,
    jumping = false,
    animations = {},
    currentAnim = nil,

    --New
    hasDash = true,
    isDashing = false,
    dashDuration = 1, -- uptime
    savedVelocity = 0,
    dashCooldown = 1 -- downtime
}

local GRAVITY = vec2.new(0, 800)
local JUMP_FORCE = 400
local WALL_JUMP_FORCE = 400
local ACCEL = 2000

function player.load()
    local idleSprite = sprite.loadSprite("assets/idle.png", 64, 64)
    local runSprite = sprite.loadSprite("assets/run.png", 64, 64)

    player.animations.idle = sprite.newAnimation(idleSprite, 0.2)
    player.animations.run = sprite.newAnimation(runSprite, 0.1)
    player.currentAnim = player.animations.idle
end

function player.handleInput(dt)
    local speed = 200
    local moveInput = vec2.new(0, 0)

    if player.isGrounded then
        if (love.keyboard.isDown("left")) or (love.keyboard.isDown("a")) then
            player.velocity.x = -speed
            moveInput.x = moveInput.x - 1
        elseif (love.keyboard.isDown("right")) or (love.keyboard.isDown("d")) then
            player.velocity.x = speed
            moveInput.x = moveInput.x + 1
        else
            player.velocity.x = 0
        end
    end
    
        local desiredAccel = vec2.mul(moveInput, ACCEL)
    player.acceleration.x = desiredAccel.x

    if love.keyboard.isDown("space") then
        if player.isGrounded and not player.jumping then
            player.velocity.y = -JUMP_FORCE
            player.jumping = true
        elseif player.canWallJump then
            local away = vec2.mul(vec2.normalize(player.wallNormal), -1)
            local jumpDir = vec2.normalize(vec2.add(away, vec2.new(0, -1)))
            player.velocity = vec2.mul(jumpDir, -WALL_JUMP_FORCE)
            player.position = vec2.add(player.position, vec2.mul(away, 2))
            player.jumping = true
        end
    else
        player.jumping = false
    end

    --New
    if love.keyboard.isDown("lshift") and player.hasDash and not player.isDashing then
    player.isDashing = true
    player.hasDash = false
    player.dashDuration = 0.15
    player.dashCooldown = 0.8
    player.savedVelocity = player.velocity.x

    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        player.velocity.x = 800
        player.velocity.y = 0
    elseif love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        player.velocity.x = -800
        player.velocity.y = 0
    end
end

end

function player.update(dt, platforms, resolveFn)
    player.handleInput(dt)

    player.velocity = vec2.add(player.velocity, vec2.mul(GRAVITY, dt))
    player.position = vec2.add(player.position, vec2.mul(player.velocity, dt))

    player.isGrounded = false
    player.canWallJump = false
    player.wallNormal = nil

    --if not player.isGrounded then
        resolveFn(player, platforms)
    --end

    -- Animation update
    if math.abs(player.velocity.x) > 5 then
        player.currentAnim = player.animations.run
    else
        player.currentAnim = player.animations.idle
    end

    sprite.updateAnimation(player.currentAnim, dt)

    --New
    if player.isDashing then
        player.dashDuration = player.dashDuration - dt

    if player.dashDuration <= 0 then
        player.isDashing = false
        player.velocity.x = player.savedVelocity
    end

    return
end

-- cooldown logic
if not player.hasDash then
    player.dashCooldown = player.dashCooldown - dt
    if player.dashCooldown <= 0 then
        player.hasDash = true
    end
end

end

function player.draw()
    local flip = player.velocity.x < 0
    love.graphics.setColor(1,1,1)
    sprite.drawAnimation(player.currentAnim, player.position.x, player.position.y, flip)
end

return player

--Scrap - Stuff I wasn't ready to throw away as I made changes
--if (hasDash == true) and ((love.keyboard.isDown("left")) or (love.keyboard.isDown("a"))) then
--elseif (hasDash == true) and ((love.keyboard.isDown("right")) or (love.keyboard.isDown("d"))) then
local vec2   = require("vector2")
local sprite = require("sprite")
local camera = require("camera")  

local player = {
    position      = vec2.new(100, 100),
    size          = vec2.new(64, 64),
    velocity      = vec2.new(0, 0),
    acceleration  = vec2.new(0, 0),
    isGrounded    = false,
    canWallJump   = false,
    wallNormal    = nil,
    jumping       = false,
    animations    = {},
    currentAnim   = nil,

    -- ATTACK / TARGET STATE
    facing        = 1,      
    bullets       = {},     
    missiles      = {},    
    explosions    = {},     
    missileTarget = nil,    
    targetRay     = nil,    

    -- DASH
    hasDash       = true,
    isDashing     = false,
    dashDuration  = 1,
    savedVelocity = 0,
    dashCooldown  = 1
}

local GRAVITY         = vec2.new(0, 800)
local JUMP_FORCE      = 400
local WALL_JUMP_FORCE = 400
local ACCEL           = 2000

-- LOAD

function player.load()
    local idleSprite = sprite.loadSprite("assets/idle.png", 64, 64)
    local runSprite  = sprite.loadSprite("assets/run.png", 64, 64)

    player.animations.idle = sprite.newAnimation(idleSprite, 0.2)
    player.animations.run  = sprite.newAnimation(runSprite, 0.1)
    player.currentAnim      = player.animations.idle
end


-- INPUT

function player.handleInput(dt)
    local speed     = 200
    local moveInput = vec2.new(0, 0)

    if player.isGrounded and not player.isDashing then
        if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
            player.velocity.x = -speed
            moveInput.x       = moveInput.x - 1
            player.facing     = -1
        elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then
            player.velocity.x =  speed
            moveInput.x       = moveInput.x + 1
            player.facing     =  1
        else
            player.velocity.x = 0
        end
    end

    local airControl   = player.isGrounded and 1.0 or 0.75
    local desiredAccel = vec2.mul(moveInput, ACCEL * airControl)
    player.acceleration.x = desiredAccel.x

    -- Jump / wall jump
    if love.keyboard.isDown("space") then
        if player.isGrounded and not player.jumping then
            player.velocity.y = -JUMP_FORCE
            player.jumping    = true
        elseif player.canWallJump then
            local away    = vec2.mul(vec2.normalize(player.wallNormal), -1)
            local jumpDir = vec2.normalize(vec2.add(away, vec2.new(0, -1)))
            player.velocity = vec2.mul(jumpDir, -WALL_JUMP_FORCE)
            player.position = vec2.add(player.position, vec2.mul(away, 2))
            player.jumping  = true
        end
    else
        player.jumping = false
    end

    -- Dash (Celeste-style)
    if love.keyboard.isDown("lshift") and player.hasDash and not player.isDashing then
        player.isDashing    = true
        player.hasDash      = false
        player.dashDuration = 0.15
        player.dashCooldown = 1.85

        if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
            player.velocity.x    = 800
            player.velocity.y    = 0
            player.savedVelocity = 400
        elseif love.keyboard.isDown("left") or love.keyboard.isDown("a") then
            player.velocity.x    = -800
            player.velocity.y    = 0
            player.savedVelocity = -400
        end
    end
end


-- UPDATE

function player.update(dt, platforms, resolveFn)
    player.handleInput(dt)

    -- physics integration
    player.velocity = vec2.add(player.velocity, vec2.mul(GRAVITY, dt))
    player.position = vec2.add(player.position, vec2.mul(player.velocity, dt))

    player.isGrounded = false
    player.canWallJump= false
    player.wallNormal = nil

    resolveFn(player, platforms)

    -- Animation update
    if math.abs(player.velocity.x) > 5 then
        player.currentAnim = player.animations.run
    else
        player.currentAnim = player.animations.idle
    end
    sprite.updateAnimation(player.currentAnim, dt)

    -- Dash timing
    if player.isDashing then
        player.dashDuration = player.dashDuration - dt
        if player.dashDuration <= 0 then
            player.isDashing = false
            player.velocity.x = player.savedVelocity
        end
    end

    -- Dash cooldown logic
    if not player.hasDash then
        player.dashCooldown = player.dashCooldown - dt
        if player.dashCooldown <= 0 then
            player.hasDash = true
        end
    end

    
    -- UPDATE TARGET RAY TO MOVE WITH MOVING ENEMY
    
    if player.missileTarget and player.targetRay then
        local center = vec2.add(player.position, vec2.mul(player.size, 0.5))
        player.targetRay.start = center

        if player.missileTarget.type == "enemy"
           and player.missileTarget.enemy then
            local e = player.missileTarget.enemy
            local eCenter = vec2.add(e.position, vec2.mul(e.size, 0.5))
            player.targetRay.finish = eCenter
        elseif player.missileTarget.type == "point"
           and player.missileTarget.point then
            player.targetRay.finish = player.missileTarget.point
        end
    end

   
    -- BULLETS: straight towards cursor point
    
    for i = #player.bullets, 1, -1 do
        local b = player.bullets[i]
        b.pos  = vec2.add(b.pos, vec2.mul(b.vel, dt))
        b.life = b.life - dt
        if b.life <= 0 then
            table.remove(player.bullets, i)
        end
    end

    
    -- MISSILES: accelerate, clamp speed, home to target
   
    for i = #player.missiles, 1, -1 do
        local m = player.missiles[i]

        local desiredDir = m.forward
        local targetPos  = nil

        if player.missileTarget then
            if player.missileTarget.type == "enemy"
                and player.missileTarget.enemy then
                local e = player.missileTarget.enemy
                targetPos = vec2.add(e.position, vec2.mul(e.size, 0.5))
            elseif player.missileTarget.type == "point"
                and player.missileTarget.point then
                targetPos = player.missileTarget.point
            end
        end

        if targetPos then
            desiredDir = vec2.normalize(vec2.sub(targetPos, m.pos))
        end

        -- accelerate in desired direction
        m.vel = vec2.add(m.vel, vec2.mul(desiredDir, m.accel * dt))

        -- clamp speed
        local speed = vec2.len(m.vel)
        if speed > m.maxSpeed then
            m.vel = vec2.mul(vec2.normalize(m.vel), m.maxSpeed)
        end

        m.pos  = vec2.add(m.pos, vec2.mul(m.vel, dt))
        m.life = m.life - dt

        local exploded = false
        if targetPos and vec2.len(vec2.sub(targetPos, m.pos)) < 12 then
            exploded = true
        end
        if m.life <= 0 then
            exploded = true
        end

        if exploded then
            table.insert(player.explosions, {
                pos  = vec2.copy(m.pos),
                life = 0.3
            })
            table.remove(player.missiles, i)
        end
    end

   
    -- MISSILE EXPLOSIONS
    
    for i = #player.explosions, 1, -1 do
        local ex = player.explosions[i]
        ex.life = ex.life - dt
        if ex.life <= 0 then
            table.remove(player.explosions, i)
        end
    end
end


-- HELPER: mouse in WORLD coordinates

local function getWorldMouse()
    local mx, my = love.mouse.getPosition()
    -- camera translates by -camera.position, so world = screen + camera.position
    return vec2.new(mx + camera.position.x, my + camera.position.y)
end


-- ATTACK FUNCTIONS

-- BULLET: weak, straight towards cursor
function player.fireBullet()
    local center = vec2.add(player.position, vec2.mul(player.size, 0.5))
    local mouse  = getWorldMouse()
    local dir    = vec2.normalize(vec2.sub(mouse, center))

    -- fallback if mouse exactly on player
    if vec2.len(dir) == 0 then
        dir = vec2.new(player.facing, 0)
    end

    local muzzleOffset = 30
    local startPos     = vec2.add(center, vec2.mul(dir, muzzleOffset))
    local speed        = 600

    table.insert(player.bullets, {
        pos  = startPos,
        vel  = vec2.mul(dir, speed),
        life = 1.2
    })
end

-- MISSILE: forward towards cursor, then homes on target if set
function player.fireMissile()
    local center = vec2.add(player.position, vec2.mul(player.size, 0.5))
    local mouse  = getWorldMouse()
    local dir    = vec2.normalize(vec2.sub(mouse, center))

    if vec2.len(dir) == 0 then
        dir = vec2.new(player.facing, 0)
    end

    local startPos = vec2.add(center, vec2.mul(dir, 40))

    local missile = {
        pos      = startPos,
        vel      = vec2.mul(dir, 150),
        forward  = dir,
        accel    = 500,
        maxSpeed = 700,
        life     = 3.0
    }
    table.insert(player.missiles, missile)
end

-- TARGETING: click/T to lock onto an enemy under cursor, or a point
function player.setTarget(enemies)
    enemies = enemies or {}

    local center   = vec2.add(player.position, vec2.mul(player.size, 0.5))
    local mousePos = getWorldMouse()

    local bestEnemy = nil
    local bestDist  = math.huge
    local selectRadius = 32  -- how close mouse must be to enemy

    -- choose enemy closest to cursor
    for _, e in ipairs(enemies) do
        local eCenter = vec2.add(e.position, vec2.mul(e.size, 0.5))
        local dist    = vec2.len(vec2.sub(eCenter, mousePos))
        if dist < selectRadius and dist < bestDist then
            bestDist  = dist
            bestEnemy = e
        end
    end

    local targetPos

    if bestEnemy then
        -- moving enemy target: missiles recompute each frame
        player.missileTarget = { type = "enemy", enemy = bestEnemy }
        targetPos = vec2.add(bestEnemy.position, vec2.mul(bestEnemy.size, 0.5))
    else
        -- no enemy clicked: lock onto world point at cursor
        player.missileTarget = { type = "point", point = mousePos }
        targetPos = mousePos
    end

    player.targetRay = {
        start  = center,
        finish = targetPos
    }
end


-- DRAW

function player.draw()
    -- use facing so idle keeps last horizontal direction
    local flip = player.facing < 0
    love.graphics.setColor(1,1,1)
    sprite.drawAnimation(player.currentAnim, player.position.x, player.position.y, flip)

    -- BULLETS
    love.graphics.setColor(1, 1, 0)
    for _, b in ipairs(player.bullets) do
        love.graphics.circle("fill", b.pos.x, b.pos.y, 4)
    end

    -- MISSILES: rectangle base + triangle tip (directional)
    love.graphics.setColor(0.4, 1.0, 1.0)
    for _, m in ipairs(player.missiles) do
        local angle = math.atan2(m.vel.y, m.vel.x)
        love.graphics.push()
        love.graphics.translate(m.pos.x, m.pos.y)
        love.graphics.rotate(angle)

        local baseLen = 18
        local baseH   = 6
        love.graphics.rectangle("fill", -baseLen, -baseH / 2, baseLen, baseH)
        love.graphics.polygon("fill",
            0, -baseH,
            0,  baseH,
            10, 0
        )

        love.graphics.pop()
    end

    -- TARGET RAY + TARGET MARKER (circle)
    if player.targetRay then
        local s = player.targetRay.start
        local f = player.targetRay.finish

        love.graphics.setColor(0, 1, 0, 0.7)
        love.graphics.setLineWidth(2)
        love.graphics.line(s.x, s.y, f.x, f.y)

        love.graphics.setColor(0, 1, 0, 0.4)
        love.graphics.circle("fill", f.x, f.y, 8)
        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.circle("line", f.x, f.y, 8)
    end

    -- MISSILE EXPLOSIONS
    for _, ex in ipairs(player.explosions) do
        local t      = ex.life / 0.3
        local radius = 20 * t
        love.graphics.setColor(1, 0.5, 0, 0.5 * t)
        love.graphics.circle("fill", ex.pos.x, ex.pos.y, radius)
    end
end

return player

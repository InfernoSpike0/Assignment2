local vec2   = require("vector2")
local sprite = require("sprite")
local dbg    = require("debugging")

local chicken = {
    list       = {},
    lasers     = {},
    sprites    = {},
    laserImage = nil,
    laserOrigin = { x = 0, y = 0 }
}


-- ASSETS
function chicken.loadAssets()
    -- idle and run sprite sheets
    local idleSheet = sprite.loadSprite("assets/idle3.png", 64, 64)
    local runSheet  = sprite.loadSprite("assets/run2.png", 64, 64)

    chicken.sprites.idle = idleSheet
    chicken.sprites.run  = runSheet

    -- laser sprite 
    chicken.laserImage = love.graphics.newImage("assets/ChickenBlast.png")
    chicken.laserOrigin.x = chicken.laserImage:getWidth()  / 2
    chicken.laserOrigin.y = chicken.laserImage:getHeight() / 2
end


-- SPAWN

function chicken.spawn(x, y)
    local e = {}

    e.position   = vec2.new(x, y)
    e.size       = vec2.new(64, 64)
    e.velocity   = vec2.new(0, 0)
    e.direction  = vec2.new(1, 0)    

   
    e.hp         = 5

    -- ground-locked Y so chickens don't float
    e.groundY = y

    -- patrol range (so they don't walk off-screen)
    e.patrolRadius = 150
    e.patrolMinX   = x - e.patrolRadius
    e.patrolMaxX   = x + e.patrolRadius

    -- vision
    e.viewRadius = 250
    e.viewAngle  = math.rad(60)

    -- behaviours / state
    e.state = (math.random() < 0.5) and "IDLE" or "WANDER"
    e.behaviour = nil    

    -- wandering parameters
    e.moveSpeed            = 80
    e.wanderTimer          = 0
    e.wanderChangeInterval = 1.5 + math.random() * 1.5

    -- animations
    e.animations = {}
    e.animations.idle = sprite.newAnimation(chicken.sprites.idle, 0.2)
    e.animations.run  = sprite.newAnimation(chicken.sprites.run,  0.12)
    e.currentAnim     = e.animations.idle

    -- shooting
    e.fireCooldown = 0
    e.fireRate     = 0.4

    table.insert(chicken.list, e)
end


-- VISION

local function canSeePlayer(e, player)
    local playerCenter = vec2.add(player.position, vec2.mul(player.size, 0.5))
    local enemyCenter  = vec2.add(e.position,     vec2.mul(e.size,   0.5))

    local toPlayer = vec2.sub(playerCenter, enemyCenter)
    local distance = vec2.len(toPlayer)

    -- 1. radius
    if distance > e.viewRadius then return false end

    -- 2. angle
    local dirNorm = vec2.normalize(e.direction)
    local tpNorm  = vec2.normalize(toPlayer)

    local dot = vec2.dot(dirNorm, tpNorm)
    dot = math.max(-1, math.min(1, dot))
    local angle = math.acos(dot)

    return angle <= e.viewAngle * 0.5
end

local function pickTriggeredBehaviour(e)
    local r = math.random()
    if r < 1/3 then
        e.behaviour = "B1" -- rotate & shoot
    elseif r < 2/3 then
        e.behaviour = "B2" -- rotate, move towards & shoot
    else
        e.behaviour = "B3" -- rotate away & move away
    end
    e.state = "TRIGGERED"
end


-- LASERS FROM EYES 

local function shootLaser(e)
    local center = vec2.add(e.position, vec2.mul(e.size, 0.5))

    -- eye offset tuned for idle3/run2
    local eyeOffset = { x = 8, y = -6 }
    local facingRight = e.direction.x >= 0
    local eyePos = {
        x = center.x + (facingRight and eyeOffset.x or -eyeOffset.x),
        y = center.y + eyeOffset.y
    }

    local dir   = vec2.normalize(e.direction)
    local speed = 500
    local angle = math.atan2(dir.y, dir.x)

    table.insert(chicken.lasers, {
        pos   = eyePos,
        vel   = vec2.mul(dir, speed),
        life  = 0.6,
        angle = angle
    })
end

function chicken.updateLasers(dt)
    for i = #chicken.lasers, 1, -1 do
        local l = chicken.lasers[i]
        l.pos  = vec2.add(l.pos, vec2.mul(l.vel, dt))
        l.life = l.life - dt

        -- TODO: collision vs player/world

        if l.life <= 0 then
            table.remove(chicken.lasers, i)
        end
    end
end

function chicken.drawLasers()
    if not chicken.laserImage then return end

    love.graphics.setColor(1, 1, 1, 1)
    for _, l in ipairs(chicken.lasers) do
        love.graphics.draw(
            chicken.laserImage,
            l.pos.x, l.pos.y,
            l.angle,
            1, 1,
            chicken.laserOrigin.x, chicken.laserOrigin.y
        )
    end
end


-- PER-ENEMY UPDATE

local function updateEnemy(e, dt, player)
    -- vision & trigger
    local sees = canSeePlayer(e, player)
    if sees and e.state ~= "TRIGGERED" then
        pickTriggeredBehaviour(e)
    elseif (not sees) and e.state == "TRIGGERED" then
        e.state = "WANDER"
        e.behaviour = nil
    end

    if e.state == "IDLE" then
        -- stays put, only animates
        e.velocity.x, e.velocity.y = 0, 0

    elseif e.state == "WANDER" then
        -- smooth wandering: change direction occasionally
        e.wanderTimer = e.wanderTimer + dt
        if e.wanderTimer >= e.wanderChangeInterval then
            e.wanderTimer = 0
            e.wanderChangeInterval = 1.5 + math.random() * 1.5
            e.direction.x = (math.random() < 0.5) and -1 or 1
        end

        -- horizontal only, locked to ground
        e.velocity.x = e.direction.x * e.moveSpeed
        e.velocity.y = 0

        -- bounce off patrol edges
        if e.position.x < e.patrolMinX then
            e.position.x = e.patrolMinX
            e.direction.x = 1
            e.velocity.x  = math.abs(e.velocity.x)
        elseif e.position.x > e.patrolMaxX then
            e.position.x = e.patrolMaxX
            e.direction.x = -1
            e.velocity.x  = -math.abs(e.velocity.x)
        end

    elseif e.state == "TRIGGERED" then
        local playerCenter = vec2.add(player.position, vec2.mul(player.size, 0.5))
        local enemyCenter  = vec2.add(e.position,     vec2.mul(e.size,   0.5))
        local toPlayer = vec2.sub(playerCenter, enemyCenter)
        local towards  = vec2.normalize(toPlayer)

        -- always aim at player for FOV + lasers
        e.direction = towards

        -- horizontal movement only
        local horizontalDir = (playerCenter.x >= enemyCenter.x) and 1 or -1

        if e.behaviour == "B1" then
            -- Aim & shoot, no movement
            e.velocity.x, e.velocity.y = 0, 0

        elseif e.behaviour == "B2" then
            -- Aim & move towards (horizontally)
            e.velocity.x = horizontalDir * e.moveSpeed * 1.3
            e.velocity.y = 0

        elseif e.behaviour == "B3" then
            -- Aim away & move away (horizontally)
            e.velocity.x = -horizontalDir * e.moveSpeed * 1.5
            e.velocity.y = 0
        end

        -- shoot while triggered
        e.fireCooldown = e.fireCooldown - dt
        if e.fireCooldown <= 0 then
            shootLaser(e)
            e.fireCooldown = e.fireRate
        end
    end

    -- move
    e.position = vec2.add(e.position, vec2.mul(e.velocity, dt))

    -- lock to ground so they never float up/down
    e.position.y = e.groundY

    -- safety clamp so they don't leave patrol band entirely
    if e.position.x < e.patrolMinX then
        e.position.x = e.patrolMinX
    elseif e.position.x > e.patrolMaxX then
        e.position.x = e.patrolMaxX
    end

    -- animation: idle vs run
    if math.abs(e.velocity.x) > 2 or math.abs(e.velocity.y) > 2 then
        e.currentAnim = e.animations.run
    else
        e.currentAnim = e.animations.idle
    end
    sprite.updateAnimation(e.currentAnim, dt)
end


-- DRAW ENEMY (sprite + geometry + debug)

local function drawEnemy(e)
    local flip = e.direction.x < 0

  
    -- MAIN LOOK: sprite + geometry primitives
    
    love.graphics.setColor(1,1,1)
    sprite.drawAnimation(e.currentAnim, e.position.x, e.position.y, flip)

    -- extra geometry: glowing circle under feet
    local center = vec2.add(e.position, vec2.mul(e.size, 0.5))
    love.graphics.setColor(1, 1, 0, 0.3)
    love.graphics.circle("fill", center.x, center.y + e.size.y * 0.25, 10)
    love.graphics.setColor(1, 0.8, 0.1, 1)
    love.graphics.circle("line", center.x, center.y + e.size.y * 0.25, 10)

    -- small rectangle "backpack" on chicken
    love.graphics.setColor(0.2, 0.8, 1.0, 0.6)
    love.graphics.rectangle("fill",
        e.position.x + 16, e.position.y + 10,
        10, 14
    )

   
    -- DEBUG VIEW (bounds, direction, view cone)
    
    if not dbg.enabled then return end

    -- AABB bounds
    love.graphics.setColor(0, 1, 1, 0.4)
    love.graphics.rectangle("line", e.position.x, e.position.y, e.size.x, e.size.y)

    -- color by behaviour/state
    local col = {1,1,1}
    if e.state == "IDLE" then
        col = {0,0,1}
    elseif e.state == "WANDER" then
        col = {0,1,0}
    elseif e.state == "TRIGGERED" then
        if e.behaviour == "B1" then
            col = {1,1,0}   -- yellow
        elseif e.behaviour == "B2" then
            col = {1,0.5,0} -- orange
        elseif e.behaviour == "B3" then
            col = {1,0,0}   -- red
        else
            col = {1,0,0}
        end
    end

    -- FOV polygon
    local baseAngle = math.atan2(e.direction.y, e.direction.x)
    local half      = e.viewAngle * 0.5
    local a1        = baseAngle - half
    local a2        = baseAngle + half
    local r         = e.viewRadius

    love.graphics.setColor(col[1], col[2], col[3], 0.25)
    love.graphics.polygon("fill",
        center.x, center.y,
        center.x + math.cos(a1)*r, center.y + math.sin(a1)*r,
        center.x + math.cos(a2)*r, center.y + math.sin(a2)*r
    )

    -- direction vector
    love.graphics.setColor(col[1], col[2], col[3], 1)
    love.graphics.line(
        center.x, center.y,
        center.x + e.direction.x * 40,
        center.y + e.direction.y * 40
    )
end


-- UPDATE WITH DAMAGE/HP/EXPLOSIONS

function chicken.updateAll(dt, player)
    local bullets  = player.bullets  or {}
    local missiles = player.missiles or {}

    -- iterate backwards so we can remove chickens
    for ei = #chicken.list, 1, -1 do
        local e = chicken.list[ei]

        updateEnemy(e, dt, player)

        -- simple AABB for hits
        local ex, ey = e.position.x, e.position.y
        local ew, eh = e.size.x,    e.size.y

       
        -- BULLET DAMAGE (weak)
        
        for bi = #bullets, 1, -1 do
            local b = bullets[bi]
            if b.pos.x > ex and b.pos.x < ex + ew and
               b.pos.y > ey and b.pos.y < ey + eh then

                e.hp = e.hp - 1
                table.remove(bullets, bi)

                if e.hp <= 0 then
                    -- clear targeting if this was the target
                    if player.missileTarget
                        and player.missileTarget.type == "enemy"
                        and player.missileTarget.enemy == e then
                        player.missileTarget = nil
                        player.targetRay = nil
                    end
                    table.remove(chicken.list, ei)
                    e = nil
                    break
                end
            end
        end

        if e == nil then
            -- this chicken was killed by a bullet
            goto continue_chicken
        end

        
        -- MISSILE DAMAGE (stronger, with explosion)
        
        for mi = #missiles, 1, -1 do
            local m = missiles[mi]
            local mx, my = m.pos.x, m.pos.y

            if mx > ex and mx < ex + ew and
               my > ey and my < ey + eh then

                e.hp = e.hp - 2

                -- spawn explosion at missile hit position
                table.insert(player.explosions, {
                    pos  = vec2.copy(m.pos),
                    life = 0.3
                })

                table.remove(missiles, mi)

                if e.hp <= 0 then
                    if player.missileTarget
                        and player.missileTarget.type == "enemy"
                        and player.missileTarget.enemy == e then
                        player.missileTarget = nil
                        player.targetRay = nil
                    end
                    table.remove(chicken.list, ei)
                    e = nil
                    break
                end
            end
        end

        ::continue_chicken::
    end

    chicken.updateLasers(dt)
end

function chicken.drawAll()
    for _, e in ipairs(chicken.list) do
        drawEnemy(e)
    end
    chicken.drawLasers()
end

return chicken

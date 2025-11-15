-- sprite.lua
local sprite = {}

function sprite.loadSprite(imagePath, frameWidth, frameHeight)
    local image = love.graphics.newImage(imagePath)
    local quads = {}
    local imgWidth, imgHeight = image:getDimensions()

    for y = 0, imgHeight - frameHeight, frameHeight do
        for x = 0, imgWidth - frameWidth, frameWidth do
            table.insert(quads, love.graphics.newQuad(x, y, frameWidth, frameHeight, imgWidth, imgHeight))
        end
    end

    return {
        image = image,
        quads = quads
    }
end

function sprite.newAnimation(spriteData, frameDuration)
    return {
        sprite = spriteData,
        duration = frameDuration,
        time = 0,
        frame = 1
    }
end

function sprite.updateAnimation(anim, dt)
    anim.time = anim.time + dt
    if anim.time >= anim.duration then
        anim.time = anim.time - anim.duration
        anim.frame = anim.frame + 1
        if anim.frame > #anim.sprite.quads then
            anim.frame = 1
        end
    end
end

function sprite.drawAnimation(anim, x, y, flip)
    local sx = 1
    local ox =  0 --anim.sprite.quads[anim.frame]:getViewport() / 2 
    if flip then 
        sx = -1 
        _,_,ox,_ = anim.sprite.quads[anim.frame]:getViewport()
    end
   -- local ox = flip and anim.sprite.quads[anim.frame]:getViewport() / 2 or 0
    love.graphics.draw(anim.sprite.image, anim.sprite.quads[anim.frame], x, y, 0, sx, 1, ox, 0)
end

return sprite

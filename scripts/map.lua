local sti = require 'libraries/sti'

local map = {}

function map:load(player)

    -- Load a map exported from Tiled.
    self.map = sti('tilemap/map.lua')

    -- Create a custom layer for players & enemies
    self.map:addCustomLayer('Sprite Layer', 5)

    -- Create a custom layer for items on the ground
    self.map:addCustomLayer('Item Layer', 4)

    -- TODO: This probably belongs inside player class.
    local spriteLayer = self.map.layers['Sprite Layer']
    spriteLayer.sprites = {
        player = {
            image = love.graphics.newImage('pictures/player.png')
        }
    }

    -- Set player position to spawn point when map is loaded.
    for _, object in pairs(self.map.objects) do
        if object.name == 'Player' then
            player.x = math.floor(object.x/64)
            player.y = math.floor(object.y/64)
        end
    end

    -- Create update callback for sprite layer
    -- since layer contains moving pieces.
    function spriteLayer:update(dt)
        for _, sprite in pairs(spriteLayer.sprites) do
           -- TODO: This will move all sprites based on player x, y
            sprite.x = player.x * 64
            sprite.y = player.y * 64
        end
    end

    -- Create draw callback for sprite layer
    function spriteLayer:draw()
        for _, sprite in pairs(self.sprites) do
            local x = sprite.x
            local y = sprite.y
            love.graphics.draw(sprite.image, x, y)
        end
    end
end

-- takes *player* for x and y coords
-- takes *zoom* for scale factor (also applied to overlays like FoV)
function map:draw(player, sx, sy)
    -- Translate world so player is always centered

    local tx = (player.x * 64) - ((love.graphics.getWidth()/sx) / 2) + 32
    local ty = (player.y * 64) - ((love.graphics.getHeight()/sy) / 2) + 32

    self.map:draw(-tx, -ty, sx, sy)
end

function map:update(dt)
    self.map:update(dt)
end

return map

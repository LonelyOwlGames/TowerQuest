local lume = require 'libraries.lume'
local map = require 'scripts.map'
local Physics = require 'scripts.physics'
local Controller = require 'scripts.controller'
local Camera = require 'libraries.Camera'

local State = {}

State.gameScreen = {}
State.characterScreen = {}
State.inventoryScreen = {}

----------------------------------------------
-- Game Screen
----------------------------------------------

-- drawFogOfWar(STI map, object player, scale zoom)
-- Overlays black tiles based on tile light property
-- Translates based on player x and y coordinates.
function State.gameScreen:drawFogOfWar()
    love.graphics.push()
    -- Loop through all tiles, and overlay a rectangle
    --love.graphics.scale(map.scaleX, map.scaleY) -- Apply same scale as map
    for i, _ in pairs(map.map.tileInstances) do
        for _, tile in pairs(map.map.tileInstances[i]) do
            if tile.node then
                
                local light = tile.light
                if light then
                    love.graphics.setColor(light.r/255, light.g/255, light.b/255, light.a/255)
                    love.graphics.rectangle('fill', tile.x, tile.y, 64, 64)
                    love.graphics.setColor(1,1,1,1)
                end
            end
            if tile.seen then
                --love.graphics.printf(tostring(tile.seen), tile.x + 32, tile.y + 32, 400)
            end
            -- if tile.node.light and tile.node.distance then -- If node has been processed correctly
            --     love.graphics.setColor(tile.node.light.r/255, tile.node.light.g/255, tile.node.light.b/255, tile.node.light.a/255)
            --     love.graphics.rectangle('fill', tile.x, tile.y, 64, 64)
            --     love.graphics.setColor(1,1,1,1)
            --
            --     -- DEBUG --
            --     -- Draw tile alpa
            --     -- if tile.node.previous then
            --     -- love.graphics.printf(tile.node.distance, tile.x + 32, tile.y + 32, 400)
            --     -- end
            --     --love.graphics.printf(#tile.neighbors, tile.x - tx + 32, tile.y - ty + 42, 400)
            -- end
            -- 
        end
    end
    love.graphics.pop()
end

-- drawMinimapOverlay (STI map, object player)
-- Draw colored rectangles at every tile x, y based on
-- tile.seen property set during dijkstra node gen.
function State.gameScreen:drawMinimapOverlay(player)
    love.graphics.push()
        -- Scale down to keep consistent size arguments.
        love.graphics.scale(0.05 * self.camera.scale, 0.05 * self.camera.scale)
        for i, _ in pairs(map.map.tileInstances) do
            for _, tile in pairs(map.map.tileInstances[i]) do
                if tile.seen then -- if tile's visibility has been modified
                    if tile.layer.name == 'wall' then
                        love.graphics.setColor(1, 0.5, 0.5, 0.8)
                    elseif tile.layer.name == 'floor' then
                        love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
                    end

                    love.graphics.rectangle('fill', tile.x, tile.y, 64, 64)
                end
            end
        end

        -- Extra flavor for drawing player on minimap
        love.graphics.setColor(0.5, 0.6, 1, 0.9)
        love.graphics.rectangle('fill', player.x * 64, player.y * 64, 64, 64)
        love.graphics.setColor(1,1,1,1)
        love.graphics.rectangle('fill', player.x * 64, player.y * 64, 64, 64)
    love.graphics.pop()
end

-- This is ideally called once game has "started" - ONCE.
function State.gameScreen:init()
    -- Initialize player object
    self.playerInfo = require('scripts/class/playerClass')(5,3)

    -- Initialize Camera
    self.camera = Camera()
    self.camera.scale = 1.5
    self.camera:setFollowStyle('NO_DEADZONE')
    -- self.camera:setDeadzone(love.graphics.getWidth()/2 - 200, love.graphics.getHeight()/2 - 200, 200, 200)
    self.camera:setFollowLerp(0.1)

    Physics:init()

    -- Register player as physics object
    Physics:registerPlayer(self.playerInfo)

    -- Load map with player data
    map:load(self.playerInfo)

    -- Register map into physics engine.
    Physics:registerMap(map.map)

    -- Canvas to be used for game
    self.canvas = love.graphics.newCanvas()

    -- Initialize mouse controller system
    Controller:init(self.playerInfo)
end

function State.gameScreen:enter(old_state)
end

function State.gameScreen:resize()
    map:updateScale()
end

-- This function may be called from external game states
-- to continue drawing game while in other menus.
function State.gameScreen:draw()
    self.camera:attach()
        map:draw(self.camera, self.playerInfo)
        self:drawFogOfWar()
        love.graphics.setColor(0.5,1,0.5,0.8)
        love.graphics.rectangle('line', self.playerInfo.sprite.x, self.playerInfo.sprite.y, 64, 64)
        love.graphics.setColor(1,1,1,0.8)
        love.graphics.rectangle('line', self.playerInfo.x*64, self.playerInfo.y*64, 64, 64)
        love.graphics.setColor(1,1,1,1)
        Controller:draw()
    self.camera:detach()
    
    self.camera:draw()

    self:drawMinimapOverlay(self.playerInfo)

    love.graphics.printf('FPS: ' .. love.timer.getFPS(), love.graphics.getWidth() - 300, 20, 400)
    love.graphics.printf('Texture Memory: ' .. math.floor(love.graphics.getStats().texturememory/1000000) .. 'mb', love.graphics.getWidth() - 300, 40, 400)
    love.graphics.printf('Draw Calls: ' .. math.floor(love.graphics.getStats().drawcalls), love.graphics.getWidth() - 300, 60, 400)
    love.graphics.printf('Garbage: ' .. collectgarbage('count'), love.graphics.getWidth() - 300, 80, 400)
    love.graphics.printf('Physic Nodes: ' .. #Physics.nodes, love.graphics.getWidth() - 300, 100, 400)
end

-- :update Called when gameScreen is at top of stack.
function State.gameScreen:update(dt)
    map:update(dt, self.playerInfo)
    Physics:update(dt)
    Controller:update(dt, self.camera)

    self.camera:update(dt)
    self.camera:follow(self.playerInfo.sprite.x + 32, self.playerInfo.sprite.y + 32)
end

-- Called only when gameScreen is at top of stack.
function State.gameScreen:keypressed(key)
    self.playerInfo:handleKeybinds(key)

    if key == 'e' then
        self.camera:shake(8, 1, 60)
    end

    if key == 'r' then
        self.camera:flash(0.05, {1,0.2,0.2,1})
    end

    if key == 't' then
        self.camera:fade(1, {0,0,0,1})
    end

    if key == 'p' then
        Physics:generateDijkstraMap()
    end

    if key == 'x' then
        self.playerInfo.viewDistance = self.playerInfo.viewDistance + 1
    end
end

function State.gameScreen:mousepressed(x, y, button)
    Controller:mousepressed(x, y, button)
end

---------------------------------------------------------
-- Inventory Screen
---------------------------------------------------------

function State.inventoryScreen:init()

end

function State.inventoryScreen:enter(old_state, playerInfo)

end

function State.inventoryScreen:mousepressed(x, y, button)

end

function State.inventoryScreen:update(dt)

end

function State.inventoryScreen:draw()

end



return State

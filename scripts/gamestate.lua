local lume = require 'libraries.lume'
local map = require 'scripts.map'
local Physics = require 'scripts.physics'

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
local function drawFogOfWar(map, player, sx, sy)
    love.graphics.push()

    local tx = (player.x * 64) - ((love.graphics.getWidth()/sx) / 2) + 32
    local ty = (player.y * 64) - ((love.graphics.getHeight()/sy) / 2) + 32

    -- Loop through all tiles, and overlay a rectangle
    love.graphics.scale(sx, sy) -- Apply same scale as map
    for i, _ in pairs(map.tileInstances) do
        for _, tile in pairs(map.tileInstances[i]) do
            if tile.light and tile.distance then -- If node has been processed correctly
                love.graphics.setColor(0,0,0,(tile.light/255))
                love.graphics.rectangle('fill', tile.x - tx, tile.y - ty, 64, 64)
                love.graphics.setColor(1,1,1,1)
            end
        end
    end
    love.graphics.pop()
end

-- drawMinimapOverlay (STI map, object player)
-- Draw colored rectangles at every tile x, y based on
-- tile.seen property set during dijkstra node gen.
local function drawMinimapOverlay(map, player, sx, sy)
    love.graphics.push()
        -- Scale down to keep consistent size arguments.
        love.graphics.scale(0.1 * sx, 0.1 * sy)
        for i, _ in pairs(map.tileInstances) do
            for _, tile in pairs(map.tileInstances[i]) do
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
    self.playerInfo = require('scripts/class/playerClass')()

    -- Register player as physics object
    Physics:registerPlayer(self.playerInfo)

    -- Load map with player data
    map:load(self.playerInfo)

    -- Register map into physics engine.
    Physics:registerMap(map.map)

    -- Canvas to be used for game
    self.canvas = love.graphics.newCanvas()
end

function State.gameScreen:enter(old_state)
end

-- This function may be called from external game states
-- to continue drawing game while in other menus.
function State.gameScreen:draw()
    local zoom = 1.5
    local sx = love.graphics.getWidth()/1920 * zoom
    local sy = love.graphics.getHeight()/1080 * zoom

    love.graphics.setCanvas(self.canvas)
        love.graphics.clear()
        map:draw(self.playerInfo, sx, sy)
        drawFogOfWar(map.map, self.playerInfo, sx, sy)
        drawMinimapOverlay(map.map, self.playerInfo, sx, sy)
    love.graphics.setCanvas()

    --love.graphics.translate(offsetx*2, offsety)
    --love.graphics.scale(sx, sy)
    love.graphics.draw(self.canvas)
end

-- :update Called when gameScreen is at top of stack.
function State.gameScreen:update(dt)
   map:update(dt)
end

-- Called only when gameScreen is at top of stack.
function State.gameScreen:keypressed(key)
    self.playerInfo:move(key)
    self.playerInfo:handleKeybinds(key)
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

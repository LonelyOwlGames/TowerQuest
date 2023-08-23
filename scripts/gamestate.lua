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
function State.gameScreen:init()
    -- Initialize player object
    self.playerInfo = require('scripts/class/playerClass')(22,9)

    -- Initialize Camera
    self.camera = Camera()
    self.camera.scale = 0.5
    self.camera:setFollowStyle('NO_DEADZONE')
    -- self.camera:setDeadzone(love.graphics.getWidth()/2 - 200, love.graphics.getHeight()/2 - 200, 200, 200)
    self.camera:setFollowLerp(0.1)

    map:init()

    Physics:init()

    -- Register player as physics object
    Physics:registerPlayer(self.playerInfo)

    -- Canvas to be used for game
    self.canvas = love.graphics.newCanvas()

    -- Initialize mouse controller system
    Controller:init(self.playerInfo)
end

function State.gameScreen:enter(old_state)
end

function State.gameScreen:resize()
end

-- This function may be called from external game states
-- to continue drawing game while in other menus.
function State.gameScreen:draw()
    self.camera:attach()
        map:draw()
        -- love.graphics.setColor(0.5,1,0.5,0.8)
        -- love.graphics.rectangle('line', self.playerInfo.sprite.x, self.playerInfo.sprite.y, 64, 64)
        -- love.graphics.setColor(1,1,1,0.8)
        -- love.graphics.rectangle('line', self.playerInfo.x*64, self.playerInfo.y*64, 64, 64)
        -- love.graphics.setColor(1,1,1,1)
        Controller:draw()
    self.camera:detach()
    
    self.camera:draw()

    -- [DEBUG] Text --
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf('FPS: ' .. love.timer.getFPS(), love.graphics.getWidth() - 300, 20, 400)
    love.graphics.printf('Texture Memory: ' .. math.floor(love.graphics.getStats().texturememory/1000000) .. 'mb', love.graphics.getWidth() - 300, 40, 400)
    love.graphics.printf('Draw Calls: ' .. math.floor(love.graphics.getStats().drawcalls), love.graphics.getWidth() - 300, 60, 400)
    love.graphics.printf('Garbage: ' .. collectgarbage('count'), love.graphics.getWidth() - 300, 80, 400)

    if Physics.debugText then
        love.graphics.printf('Debug Timer: ' .. Physics.debugText, love.graphics.getWidth() - 300, 120, 400)
    end

end

-- :update Called when gameScreen is at top of stack.
function State.gameScreen:update(dt)
    Physics:update(dt)
    Controller:update(dt, self.camera)
    map:update(dt)

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

    if key == 'space' then
        map:reload()
    end

    if key == 'n' then
        ProcGen:reset()
    end

    if key == 'x' then
        self.playerInfo.viewDistance = self.playerInfo.viewDistance + 1
    end
end

function State.gameScreen:mousepressed(x, y, button)
    Controller:mousepressed(x, y, button)
end

function State.gameScreen:wheelmoved(x, y)
    self.camera.scale = self.camera.scale + (y*0.1)
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

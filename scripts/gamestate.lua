local lume = require 'libraries.lume'
local map = require 'scripts.map'
local Physics = require 'scripts.physics'
-- local Controller = require 'scripts.controller'
local Camera = require 'libraries.Camera'
local Cinema = require 'scripts.cinema'

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

    self.cinema = Cinema()
    self.cinema:createNewCamera({name = 'player'})
    self.cinema:createNewCamera({name = 'UI'})
    self.cinema:createNewCamera({name = 'debug'})
    self.cinema:debugPreset('debug')

    self.cinema:attach('debug', function(args) 
        map:draw()
    end)

    self.cinema:attach('UI', function(args)
        local progress = args.progress
        local roomsLoaded = args.roomsLoaded
        local position = args.position


        local width = love.graphics.getWidth()/3
        local height = 50

        if progress > 0 and progress <= 100 then
            love.graphics.setColor(0.2,0.2,0.2,0.8)
            love.graphics.rectangle('fill', love.graphics.getWidth() /2 - 200, love.graphics.getHeight() - 100, width, height)
            love.graphics.setColor(0.5,1,0.7,0.5)
            love.graphics.rectangle('fill', love.graphics.getWidth() / 2 - 195, love.graphics.getHeight() - 95, (width-10)*(progress), height - 10)
            love.graphics.printf(roomsLoaded, love.graphics.getWidth() / 2 - 195, love.graphics.getHeight() - 50, 400)
        end
    end)

    self.cinema:setArg('UI', 'progress', 1)
    self.cinema:setArg('UI', 'roomsLoaded', 2)

    -- Initialize Camera
    -- self.camera = Camera()
    -- self.camera.scale = 0.5
    -- self.camera:setFollowStyle('NO_DEADZONE')
    -- self.camera:setFollowLerp(0.1)

    map:init()

    Physics:init()

    -- Register player as physics object
    Physics:registerPlayer(self.playerInfo)

    -- Canvas to be used for game
    self.canvas = love.graphics.newCanvas()

    -- Initialize mouse controller system
    -- Controller:init(self.playerInfo)
end

function State.gameScreen:enter(old_state)
end

function State.gameScreen:resize()
end

local function test()
    map:draw()
end
-- This function may be called from external game states
-- to continue drawing game while in other menus.
function State.gameScreen:draw()

    self.cinema:draw('debug')
    --
    -- self.cinema:setCameraProperty('UI', 'active', true)
    -- self.cinema:attach('UI', function()
    --     love.graphics.setColor(1,1,1,1)
    --     love.graphics.printf('FPS: ' .. love.timer.getFPS(), love.graphics.getWidth() - 300, 20, 400)
    --     love.graphics.printf('Texture Memory: ' .. math.floor(love.graphics.getStats().texturememory/1000000) .. 'mb', love.graphics.getWidth() - 300, 40, 400)
    --     love.graphics.printf('Draw Calls: ' .. math.floor(love.graphics.getStats().drawcalls), love.graphics.getWidth() - 300, 60, 400)
    --     love.graphics.printf('Garbage: ' .. math.floor(collectgarbage('count')/1000) .. 'kb', love.graphics.getWidth() - 300, 80, 400)
    -- end)
    --
    
    self.cinema:draw('UI')
    
end

-- :update Called when gameScreen is at top of stack.
local progress = 0 -- temporary
local roomsLoaded = 0
function State.gameScreen:update(dt)
    Physics:update(dt)
    map:update(dt, self.cinema)

    local test = love.thread.getChannel('load'):pop()

    if test then
        progress = test[1]/test[2]
        roomsLoaded = test[3] or roomsLoaded
    end

    self.cinema:setArg('UI', 'progress', progress)
    self.cinema:setArg('UI', 'roomsLoaded', roomsLoaded)

    self.cinema:update(dt)
end

-- Called only when gameScreen is at top of stack.
function State.gameScreen:keypressed(key)
    self.playerInfo:handleKeybinds(key)

end

function State.gameScreen:mousepressed(x, y, button)
    -- Controller:mousepressed(x, y, button)
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

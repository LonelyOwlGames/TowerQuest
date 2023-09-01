local lume = require 'libraries.lume'
local map = require 'scripts.map'
local Physics = require 'scripts.physics'
-- local Controller = require 'scripts.controller'
local Camera = require 'libraries.Camera'
local Cinema = require 'scripts.cinema'
local Console = require 'scripts.console'

local State = {}

State.gameScreen = {}
State.characterScreen = {}
State.inventoryScreen = {}

local font = love.graphics.newFont('fonts/ZeroCool.ttf', 26)
local font_small = love.graphics.newFont('fonts/ZeroCool.ttf', 18)

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
    self.cinema:createNewCamera({name = 'console'})
    self.cinema:debugPreset('debug')

    Console:load()

    self.cinema:attach('debug', function(args) 
        map:draw()
    end)

    self.cinema:setPosition('debug', 4150, 3020)
    self.cinema:enableDrag('debug')
    self.cinema:setCameraProperty('debug', 'scale', 0.15)
    self.cinema:enableScrolling('debug')

    self.cinema:attach('console', function(args)
        Console:draw()
    end)

    Console.enabled = false
    self.cinema:toggle('console')


    self.cinema:attach('UI', function(args)
        local progress = args.progress
        local roomsLoaded = args.roomsLoaded
        local state = args.state

        local stats_roomsLoaded = args.stats_roomsLoaded
        local stats_roomsDeleted = args.stats_roomsDeleted
        local stats_tilesCreated = args.stats_tilesCreated
        local stats_tilesDeleted = args.stats_tilesDeleted
        local stats_doorsCreated = args.stats_doorsCreated

        local barText = love.graphics.newText(font, state)

        local width = love.graphics.getWidth()/3
        local height = 30

        if progress > 0 and progress <= 100 then
            love.graphics.setColor(0,0,0,.5)
            love.graphics.rectangle('fill', love.graphics.getWidth() /2 - width/2, love.graphics.getHeight() - 100, width, height)
            love.graphics.setColor(0.5,1*progress,0.7,0.8)
            if args.state == '~ Dungeon Complete! ~'then
                love.graphics.setColor(math.random(0,0.2),math.random(0.8,1),math.random(0,0.2),1)
            end
            love.graphics.rectangle('fill', 5 + love.graphics.getWidth() / 2 - width/2, love.graphics.getHeight() - 95, (width-10)*(progress), height - 10)
            love.graphics.setColor(1,1,1,1)
            love.graphics.draw(barText, love.graphics.getWidth() / 2 - barText:getWidth()/2, love.graphics.getHeight() - 145)
            love.graphics.printf('Loaded: ' .. roomsLoaded .. ' rooms total.', 3 + love.graphics.getWidth() / 2 - width/2, love.graphics.getHeight() - 50, 400)
        end

        love.graphics.printf('FPS: ' .. love.timer.getFPS(), love.graphics.getWidth() - 300, 20, 400)
        love.graphics.printf('Texture Memory: ' .. math.floor(love.graphics.getStats().texturememory/1000000) .. 'mb', love.graphics.getWidth() - 300, 40, 400)
        love.graphics.printf('Draw Calls: ' .. math.floor(love.graphics.getStats().drawcalls), love.graphics.getWidth() - 300, 60, 400)
        love.graphics.printf('Garbage: ' .. math.floor(collectgarbage('count')/1000) .. 'kb', love.graphics.getWidth() - 300, 80, 400)

        local statsTitle = love.graphics.newText(font_small, 'Dungeon Statistics')
        local roomsLoadedText = love.graphics.newText(font_small, 'Rooms Loaded Initially: ' .. stats_roomsLoaded)
        local roomsDeletedText = love.graphics.newText(font_small, 'Rooms Deleted: ' .. stats_roomsDeleted)
        local roomsInDungeonText = love.graphics.newText(font_small, 'Rooms In Dungeon: ' .. stats_roomsLoaded - stats_roomsDeleted)

        local tilesCreatedText = love.graphics.newText(font_small, 'Tiles Created Initially: ' .. stats_tilesCreated)
        local tilesDeletedText = love.graphics.newText(font_small, 'Tiles Deleted: ' .. stats_tilesDeleted)
        local tilesInDungeonText = love.graphics.newText(font_small, 'Tiles In Dungeon: ' .. stats_tilesCreated - stats_tilesDeleted)

        local doorsCreatedText = love.graphics.newText(font_small, 'Doors Created Initially: ' .. stats_doorsCreated)
        
        love.graphics.setColor(0.3,0.5,0.8,0.8)
        love.graphics.draw(statsTitle, 20, 20)
        love.graphics.setColor(1,1,1,0.8)
        love.graphics.draw(roomsLoadedText, 20, 40)
        love.graphics.draw(roomsDeletedText, 20, 60)
        love.graphics.draw(roomsInDungeonText, 20, 80)

        love.graphics.draw(tilesCreatedText, 20, 160)
        love.graphics.draw(tilesDeletedText, 20, 180)
        love.graphics.draw(tilesInDungeonText, 20, 200)

        love.graphics.draw(doorsCreatedText, 20, 220)



    end)

    self.cinema:setArg('UI', 'progress', 1)
    self.cinema:setArg('UI', 'roomsLoaded', 1)

    map:init()

    Physics:init()

    -- Register player as physics object
    Physics:registerPlayer(self.playerInfo)

    -- Canvas to be used for game
    self.canvas = love.graphics.newCanvas()

    -- Controller:init(self.playerInfo)
end

function State.gameScreen:enter(old_state)
end

function State.gameScreen:mousemoved(x, y, d, x)
    self.cinema:mouseMoved(x,y,d,x)
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
    --         -- end)
    --
    
    self.cinema:draw('UI')

    self.cinema:draw('console')
end

-- These are persistent values that will eventually
-- be instantiated inside a class. For now, they're here
-- until we try generating multiple maps.
local progress = 0 -- temporary
local roomsLoaded = 0
local stats_roomsLoaded = 0
local stats_roomsDeleted = 0

local stats_tilesCreated = 0
local stats_tilesDeleted = 0

local stats_doorsCreated = 0
local stats_doorsRemoved = 0
function State.gameScreen:update(dt)
    Physics:update(dt)
    map:update(dt, self.cinema)

    local load = love.thread.getChannel('load'):pop()
    local stats = love.thread.getChannel('stats'):pop()
    local stats_tiles = love.thread.getChannel('stats_tiles'):pop()
    local console = love.thread.getChannel('console'):pop()

    if load then
        self.cinema:setArg('UI', 'state', load[1])
        progress = load[2]/load[3]
        roomsLoaded = load[2] or roomsLoaded
    end

    if stats then
        stats_roomsLoaded = stats.roomsLoaded or stats_roomsLoaded
        stats_roomsDeleted = stats.roomsDeleted or stats_roomsDeleted
        if stats.tilesDeleted then
            stats_tilesDeleted = stats_tilesDeleted + stats.tilesDeleted
        end
        if stats.tilesCreated then
            stats_tilesCreated = stats_tilesCreated + stats.tilesCreated
        end

        if stats.doorsCreated then
            stats_doorsCreated = stats_doorsCreated + stats.doorsCreated
        end
    end

    if stats_tiles then
        if stats_tiles.tilesCreated then
            stats_tilesCreated = stats_tilesCreated + stats_tiles.tilesCreated
        end
    end

    self.cinema:setArg('UI', 'stats_roomsLoaded', stats_roomsLoaded)
    self.cinema:setArg('UI', 'stats_roomsDeleted', stats_roomsDeleted)

    self.cinema:setArg('UI', 'stats_tilesCreated', stats_tilesCreated)
    self.cinema:setArg('UI', 'stats_tilesDeleted', stats_tilesDeleted)
    self.cinema:setArg('UI', 'stats_doorsCreated', stats_doorsCreated)

    self.cinema:setArg('UI', 'progress', progress)
    self.cinema:setArg('UI', 'roomsLoaded', roomsLoaded)

    self.cinema:update(dt)

    if console then
        Console:push(console)
    end
end

-- Called only when gameScreen is at top of stack.
function State.gameScreen:keypressed(key)
    self.playerInfo:handleKeybinds(key)

    if key == '`' then
        self.cinema:toggle('console')
        Console.enabled = not Console.enabled
    end
end

function State.gameScreen:mousepressed(x, y, button)
    -- Controller:mousepressed(x, y, button)
end

function State.gameScreen:wheelmoved(x, y)
    if not Console.enabled then
        self.cinema:wheelmoved(x,y)
    else
        Console:scroll(x, y)
    end
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

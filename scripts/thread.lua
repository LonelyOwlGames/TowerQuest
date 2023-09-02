local threadCode =
[[
require('love')
require('love.timer')

local dungeonClass = require 'scripts.class.dungeonClass'
local Themes = require 'scripts.prefabs.generationThemes'

local count = 0
local total = 0

-- NOTE: love.timer.sleep() between steps to yield and allow the
-- main thread to process changes (catch up). Until I figure out
-- synchronization later on (make steps pend changes, not operations)

local Dungeon = dungeonClass(Themes.test)
while Dungeon:getNumberOfRooms() < Dungeon.maxDensity do
    Dungeon:buildDungeon()

    local changes = Dungeon:serializeChanges()
    local numberOfRooms = Dungeon:getNumberOfRooms()

    love.thread.getChannel('load'):push({'Generating Dungeon', numberOfRooms, Dungeon.maxDensity})
    love.thread.getChannel('info'):push({'add', changes})
end

love.timer.sleep(2) -- Yield for changes

count = 0
total = Dungeon:getNumberOfRooms()
for _, room in pairs(Dungeon.listOfRooms) do
    count = count + 1
    Dungeon:removeBadHallways(room)

    local changes = Dungeon:serializeChanges()

    love.thread.getChannel('load'):push({'Removing Bad Rooms', count, total})
    love.thread.getChannel('info'):push({'remove', changes})
end

love.timer.sleep(2) -- Yield for changes

count = 0
total = Dungeon:getNumberOfRooms()
for _, room in pairs(Dungeon.listOfRooms) do
    count = count + 1
    Dungeon:_resolveOverlaps(room)

    local changes = Dungeon:serializeChanges()

    love.thread.getChannel('load'):push({'Adding Doorways', count, total})
    love.thread.getChannel('info'):push({'update', changes})
end

love.timer.sleep(1) -- Yield for changes

print('start flood')

for n = 1, 15 do
    Dungeon:generateChasm()
end

local changes = Dungeon:serializeChanges()
love.thread.getChannel('load'):push({'Flooded', 1, 1})
love.thread.getChannel('info'):push({'update', changes})


love.timer.sleep(2)

Dungeon:wallInChasms()

local changes = Dungeon:serializeChanges()
love.thread.getChannel('load'):push({'Added walls to flood', 1, 1})
love.thread.getChannel('info'):push({'add', changes})

print('end flood')


local analyzeData = Dungeon:analyzeMapConnectivity()
Dungeon.changes = {}

count = 0
total = #analyzeData
while (count < total) do
    count = count + 1
    
    table.insert(Dungeon.changes, analyzeData[count])
    local changes = Dungeon:serializeChanges('tile')

    love.thread.getChannel('load'):push({'Loading Room Analysis', count, total})
    love.thread.getChannel('info'):push({'update', changes})
end
]]

return threadCode


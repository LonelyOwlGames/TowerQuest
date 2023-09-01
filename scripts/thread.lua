local threadCode =
[[
require('love')
require('love.timer')

local dungeonClass = require 'scripts.class.dungeonClass'

local count = 0
local total = 0

local Dungeon = dungeonClass()
while Dungeon:getNumberOfRooms() < Dungeon.maxDensity do
    Dungeon:buildDungeon()

    local changes = Dungeon:serializeChanges()

    local numberOfRooms = Dungeon:getNumberOfRooms()

    love.thread.getChannel('load'):push({'Generating Dungeon', numberOfRooms, Dungeon.maxDensity})

    love.thread.getChannel('info'):push({'add', changes})
end

count = 0
total = Dungeon:getNumberOfRooms()

for _, room in pairs(Dungeon.listOfRooms) do
    count = count + 1
    Dungeon:_resolveOverlaps(room)

    local changes = Dungeon:serializeChanges()

    love.thread.getChannel('load'):push({'Adding Doorways', count, total})
    love.thread.getChannel('info'):push({'update', changes})
end

count = 0
total = Dungeon:getNumberOfRooms()
for _, room in pairs(Dungeon.listOfRooms) do
    count = count + 1
    Dungeon:removeBadHallways(room)

    local changes = Dungeon:serializeChanges()

    love.thread.getChannel('load'):push({'Removing Bad Rooms', count, total})
    love.thread.getChannel('info'):push({'remove', changes})
end

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


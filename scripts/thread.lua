local threadCode = 
[[
require('love')
require('love.timer')

local Dungeon = require 'scripts.class.dungeonClass'

local debugDraw = true
local preview = true

local newDungeon = Dungeon()
while newDungeon.numberOfRooms < newDungeon.maxDensity do
    local changes = newDungeon:buildDungeon(preview) 
    -- love.thread.getChannel('load'):push({newDungeon.numberOfRooms, newDungeon.maxDensity, newDungeon.numberOfRooms})
    love.thread.getChannel('load'):push({'Generating Dungeon', newDungeon.numberOfRooms, newDungeon.maxDensity})

    if changes then
        love.thread.getChannel('info'):push({'room', changes, (newDungeon.numberOfRooms/newDungeon.maxDensity)})
    end
end

local listOfRooms = {}
for _, room in pairs(newDungeon.listOfRooms) do
    table.insert(listOfRooms, room)
end

for n = 1, #listOfRooms do
    local room = listOfRooms[n]
    local overlappingData = newDungeon:_resolveOverlappingWalls(room)
end

local count = 0
while (count < newDungeon.numberOfRooms) do
    count = count + 1

    local change = newDungeon:serializeChanges('room')
    love.thread.getChannel('load'):push({'Handling Wall Overlap', count, newDungeon.numberOfRooms})
    love.thread.getChannel('info'):push({'room', change})
end

local analyzeData = newDungeon:analyzeMapConnectivity()
newDungeon.changes = {}

-- To make this tile. change newDungeon.numberOfRooms to #analyzeData
-- and change 'room' to 'tile'. Then comment out room code after count code.
count = 0
while (count < #analyzeData) do
    count = count + 1
    
    -- local room = listOfRooms[count]
    -- table.insert(newDungeon.changes, room)
    

    table.insert(newDungeon.changes, analyzeData[count])
    local changes = newDungeon:serializeChanges('tile')

    love.thread.getChannel('load'):push({'Loading Room Analysis', count, #analyzeData})
    love.thread.getChannel('info'):push({'tile', changes})
end



-- local serialized = newDungeon:serialize(newDungeon)
-- love.thread.getChannel('load'):push({'done', 1, 1})
]]

return threadCode


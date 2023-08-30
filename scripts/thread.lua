local threadCode = 
[[
require('love')
require('love.timer')

local Dungeon = require 'scripts.class.dungeonClass'

local debugDraw = true
local preview = true
local count = 0
local total = 0

local newDungeon = Dungeon()
while newDungeon:getNumberOfRooms() < newDungeon.maxDensity do
    local changes = newDungeon:buildDungeon(preview) 
    local numberOfRooms = newDungeon:getNumberOfRooms()
    -- love.thread.getChannel('load'):push({numberOfRooms, newDungeon.maxDensity, numberOfRooms}) 
    love.thread.getChannel('load'):push({'Generating Dungeon', numberOfRooms, newDungeon.maxDensity})

    if changes then
        love.thread.getChannel('info'):push({'room', changes, (numberOfRooms/newDungeon.maxDensity)})
    end
end
--
-- local listOfRooms = {}
-- for _, room in pairs(newDungeon.listOfRooms) do
--     table.insert(listOfRooms, room)
-- end
--
-- count = 0
-- total = newDungeon:getNumberOfRooms()
-- while (count < total) do
--     count = count + 1
--
--     newDungeon:removeBadHallways(listOfRooms[count])
--     local numberOfRooms = newDungeon:getNumberOfRooms()
--
--     local change = newDungeon:serializeChanges('room')
--     love.thread.getChannel('load'):push({'Removing Deadend Hallways', count, numberOfRooms})
--     love.thread.getChannel('info'):push({'room', change})
-- end
--
-- -- for n = 1, #listOfRooms do
-- --     local room = listOfRooms[n]
-- --     local overlappingData = newDungeon:_resolveOverlappingWalls(room)
-- -- end
-- --
--
-- count = 0
-- total = #newDungeon.overlappingTiles
-- love.thread.getChannel('console'):push('Number of rooms to process doors on: ' .. total)
-- while (count < total) do
--     count = count + 1
--     
--     newDungeon:_resolveOverlappingWalls(newDungeon.overlappingTiles[count], count)
--
--     local change = newDungeon:serializeChanges('tile')
--     love.thread.getChannel('load'):push({'Handling Wall Overlap', count, total})
--     love.thread.getChannel('info'):push({'tile', change})
-- end
--
-- local analyzeData = newDungeon:analyzeMapConnectivity()
-- newDungeon.changes = {}
--
-- -- To make this tile. change newDungeon.numberOfRooms to #analyzeData
-- -- and change 'room' to 'tile'. Then comment out room code after count code.
-- count = 0
-- total = #analyzeData
-- while (count < total) do
--     count = count + 1
--     
--     -- local room = listOfRooms[count]
--     -- table.insert(newDungeon.changes, room)
--     
--
--     table.insert(newDungeon.changes, analyzeData[count])
--     local changes = newDungeon:serializeChanges('tile')
--
--     love.thread.getChannel('load'):push({'Loading Room Analysis', count, total})
--     love.thread.getChannel('info'):push({'tile', changes})
-- end
--
-- local serialized = newDungeon:serialize(newDungeon)
-- love.thread.getChannel('load'):push({'done', 1, 1})
]]

return threadCode


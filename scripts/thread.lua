local threadCode = 
[[
require('love')
require('love.timer')

local Dungeon = require 'scripts.class.dungeonClass'

local preview = true

local newDungeon = Dungeon()
while newDungeon.numberOfRooms < newDungeon.maxDensity do
    local changes = newDungeon:buildDungeon(preview) 
    love.thread.getChannel('load'):push({newDungeon.numberOfRooms, newDungeon.maxDensity, newDungeon.numberOfRooms})

    if changes then
        love.thread.getChannel('info'):push({'room', changes, (newDungeon.numberOfRooms/newDungeon.maxDensity)})
    end
end

local count = 0
while (count < newDungeon.maxDensity) do
    count = count + 1

    local changes = newDungeon:handleDoorConnections(count)
    love.thread.getChannel('load'):push({count, newDungeon.maxDensity})

    local serialized = newDungeon:serialize(newDungeon)
    love.thread.getChannel('info'):push({'tile', changes})
end

count = 0
while (count < 5000) do
    count = count + 1
    local changes = newDungeon:analyzeMapConnectivity()

    love.thread.getChannel('info'):push({'tile', changes})
end

local serialized = newDungeon:serialize(newDungeon)
love.thread.getChannel('info'):push({'done'})
]]

return threadCode


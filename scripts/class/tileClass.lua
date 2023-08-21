--- Tile Class.
-- Core object of map generation and the world.
-- Stores and contains all relevent information
-- a tile may need... so a lot.
-- @module tileClass.lua
-- @author Lonely Owl Games

-- Class declaration.
local Class = require 'libraries.hump.class'
local tileClass = Class{}

local id = 0

--- Initialize new tile instance
function tileClass:init()
    id = id + 1
    self.id = id

    self.roomId = nil
    self.room = nil

    self.localNeighbors = {} -- Neighbors inside room.
    self.worldNeighbors = {} -- Neighbors in dungeon

    self.x = 0
    self.y = 0
    self.type = 'empty'
end

--- Set tileObject.type dynamically.
-- Methods such as this allow more dynamic
-- functionality later on.
-- @param type tile Type (e.g, 'floor')
function tileClass:setType(type)
    self.type = type

    return self
end

--- set tileObject.x and tileObject.y dynamically
-- @param x
-- @param y
function tileClass:setPosition(x, y)
    self.x = x
    self.y = y

    return self
end

--- Set tile Object roomid
-- @param room
function tileClass:setRoom(room)
    self.roomId = room.id
    self.room = room
    return self
end

--- Called by tileObject clean function.
-- When a tile is marked dirty, call this function to
-- update tileObject.worldNeighbors table with updated
-- tiles. Since dirty tiles are new, or moved.
function tileClass:updateLocalNeighbors()
    self.localNeighbors = {}

    for y = 1, #self.room.tiles do
        for x = 1, #self.room.tiles[y] do
            local room = self.room.tiles

            if x == self.x and y == self.y then
                if room[y-1] and room[y-1][x] then
                    table.insert(self.localNeighbors, {tile = room[y-1][x], direction = 'north'})
                end

                if room[y+1] and room[y+1][x] then
                    table.insert(self.localNeighbors, {tile = room[y+1][x], direction = 'south'})
                end

                if room[y] and room[y][x+1] then
                    table.insert(self.localNeighbors, {tile = room[y][x+1], direction = 'east'})
                end

                if room[y] and room[y][x-1] then
                    table.insert(self.localNeighbors, {tile = room[y][x-1], direction = 'west'})
                end
            end
        end
    end
end

--- Called by tileObject clean function.
-- When a tile is marked dirty, call this function to
-- update tileObject.worldNeighbors table with updated
-- tiles. Since dirty tiles are new, or moved.
function tileClass:updateWorldNeighbors()
    self.worldNeighbors = {}

    if not self.room then return end
    if not self.room.dungeon then return end
    if not self.room.dungeon.tiles then return end

    local dungeon = self.room.dungeon.tiles


    for y = 1, #self.room.tiles do
        for x = 1, #self.room.tiles[y] do
            if x == self.x and y == self.y then
                if dungeon[y-1] and dungeon[y-1][x] then
                    table.insert(self.worldNeighbors, {tile = dungeon[y-1][x], direction = 'north'})
                end

                if dungeon[y+1] and dungeon[y+1][x] then
                    table.insert(self.worldNeighbors, {tile = dungeon[y+1][x], direction = 'south'})
                end

                if dungeon[y] and dungeon[y][x+1] then
                    table.insert(self.worldNeighbors, {tile = dungeon[y][x+1], direction = 'east'})
                end

                if dungeon[y] and dungeon[y][x-1] then
                    table.insert(self.worldNeighbors, {tile = dungeon[y][x-1], direction = 'west'})
                end
            end
        end
    end
end

--- Returns table of neighbors based on type filter
-- Return a table of either local or world neighbors, based
-- on filter parameter provided for tile 'type'. Might add
-- more functionality here in future.
-- @tparam boolean world true/false if localNeighbors or not.
-- @param filter tileObject type
function tileClass:getNeighborsFilter(world, filter)
    if not filter then assert(filter, 'No filter provided to getNeighborsFilter call') end

    local t
    local neighbors = {}

    if world then t = self.localNeighbors end
    if not world then t = self.worldNeighbors end

    for _, data in pairs(t) do
        if data.tile:getType(filter) then
            table.insert(neighbors, {tile = data.tile, direction = data.direction})
        end
    end

    return neighbors
end

--- Returns type of tile Object
-- @return type of tile
function tileClass:getType(compare)
    if compare then return self.type == compare end
    return self.type
end

--- Returns position of tile Object
-- @return (x,y) position of tile.
function tileClass:getPosition()
    return self.x, self.y
end

--- Builder function for tiles.
-- Uses Builder pattern with type argument for tile object
-- @param room
-- @param x
-- @param y
-- @param type
-- @return self for chaining function calls
function tileClass:createTile(room, x, y, type)
    self:setType(type)
    self:setPosition(x,y)
    self:setRoom(room)

    return self
end

--- Builder function for floor ti
-- Clean dirty tiles, obviously.
-- @return self for chaining function calls
function tileClass:setDirty()
    self:clean()
    return self
end

--- Clean dirty tiles by reassigning key valus
-- @return self for chaining function calls
function tileClass:clean()
    self:updateLocalNeighbors()
    self:updateWorldNeighbors()
    return self
end

return tileClass

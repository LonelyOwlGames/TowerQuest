--- Dungeon Class.
-- This class handles the function and behavior of a dungeon.
-- A dungeon is considered a collections of rooms and tiles
-- that the player can traverse. Only one dungeon can exist
-- at a time.
-- @module dungeonClass.lua
-- @author Lonely Owl Games

-- Class declaration.
local Class = require 'libraries.hump.class'
local roomClass = require 'scripts.class.roomClass'
local tileClass = require 'scripts.class.tileClass'
local dungeonClass = Class{}

local id = 0

--- Initialize new tile instance
function dungeonClass:init(width, height)
    id = id + 1
    self.id = id

    self.width = width or 50
    self.height = height or 50

    -- Create map buffer of empty tiles.
    self.tiles = roomClass():createRoomBuffer(self.width, self.height, 'black')

    self.listOfRooms = {}
    self.listOfTiles = {} -- Maybe?
end

--- Method for looking up room by ID
-- Used when tiles or rooms don't otherwise
-- have a reference for a specific room.
-- @param roomId room id of desired room.
-- @return room Object reference
function dungeonClass:lookupRoom(roomId)
    for _, room in pairs(self.listOfRooms) do
        if room.id == roomId then
            return room
        end
    end

    error('Unable to find roomId in lookup table')
end

--- Generate a randomly sized room.
-- Some parameters control the randomness, rendering
-- it more of an "authored" procedural generation.
-- @treturn table room
function dungeonClass:generateRandomRoom()
    local room = roomClass()

    room:generateCircleRoom(9)
    -- room:generateSquareRoom(5,5)

    return room
end

--- Does supplied room fit into the dungeon at x,y.
-- Checks whether the room parameter will fit into
-- the current dungeon based on its tiles.
-- @tparam table room
-- @param x
-- @param y
-- @treturn boolean success
function dungeonClass:isValidRoomPlacement(room, x, y)
    x = math.floor(x)
    y = math.floor(y)

    local overlappingWallCount = 0
    local overlappingFloorCount = 0

    for ry = 1, #room.tiles do
        for rx = 1, #room.tiles[ry] do
            -- Return false if tile does not exist
            if not self.tiles[y + ry] then return false end
            if not self.tiles[y + ry][x + rx] then return false end

            local targetTile = self.tiles[y + ry][x + rx]
            local roomTile = room.tiles[ry][rx]

            if roomTile:getType('wall') then
                if targetTile:getType('wall') then
                    roomTile:setProperty('isOverlappingWall', true)
                    overlappingWallCount = overlappingWallCount + 1
                end
            end

            if roomTile:getType('floor') then
                if targetTile:getType('floor') or targetTile:getType('wall') then
                    overlappingFloorCount = overlappingFloorCount + 1
                end
            end
        end
    end

    if overlappingWallCount > 0 and overlappingFloorCount == 0 then
        return true
    else
        return false
    end
end


--- Copy room tiles onto the map.
-- We virtually check locations for the room to fit.
-- Once we found a fitting location. We "copy" the room
-- onto that position on the map.
-- @tparam table room
-- @param x
-- @param y
function dungeonClass:copyRoomIntoDungeon(room, x, y)
    x = math.floor(x)
    y = math.floor(y)

    for ry = 1, #room.tiles do
        for rx = 1, #room.tiles[ry] do
            -- In case we didn't check valid room placement:
            if not self.tiles[y + ry] then error('Invalid room placement: y-axis') end
            if not self.tiles[y + ry][x + rx] then error('Invalid room placement: x-axis') end

            local targetTile = self.tiles[y + ry][x + rx]
            local roomTile = room.tiles[ry][rx]

            targetTile:setPosition(roomTile:getPosition())
            targetTile:setType(roomTile:getType())
        end
    end

    room.dungeon = self

    -- Since we manipulated tile positions, mark room as dirty
    room:setDirty()

    table.insert(self.listOfRooms, room)
end

--- Builder method for dungeon generation.
-- recursively creates rooms, and adds them to
-- the current dungeon.
-- @treturn table mapData A 2D array (table) full of tiles.
function dungeonClass:buildDungeon()
    local room = self:generateRandomRoom()

    self:copyRoomIntoDungeon(room, 5, 5)

    return self.tiles
end

return dungeonClass


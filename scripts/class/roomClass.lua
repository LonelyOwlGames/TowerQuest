--- Room Class.
-- Used in Procedural generation. Contains methods using
-- the Builder design pattern to stitch together rooms
-- that are procedurally generated.
-- @module roomClass.lua
-- @author Lonely Owl Games

-- Class declaration.
local Class = require 'libraries.hump.class'
local tileClass = require 'scripts.class.tileClass'
local roomClass = Class{}

local id = 0
function roomClass:init()
    self.tiles = {}

    self.dungeon = nil -- Reference to dungeon

    id = id + 1
    self.id = id
end

-- Rooms are comprised of a 2D table called .tiles.
-- sorted by [y] then [x] value. Each value in an 
-- index is a reference to a 'tile' object.

--- Helper function for room buffers.
-- Room buffers are a 2D array of empty tiles
-- the room is built on. This is required for
-- neighboring tiles to be calculated.
-- @param width
-- @param height
-- @param type (optional) for edge case behavior
function roomClass:createRoomBuffer(width, height, type)
    local buffer = {}
    type = type or 'empty'

    for y = 1, height do
        buffer[y] = {}
        for x = 1, width do
            local tile = tileClass():createTile(self, x, y, type)
            buffer[y][x] = tile
        end
    end

    return buffer
end

--- Set all tiles in room to dirty.
-- This is needed, because if we set tiles to dirty
-- while they're being created / moved. Then the subsequent
-- calls to neighboring tiles, etc will not have proper
-- references to other tiles.
function roomClass:setDirty()
    for y = 1, #self.tiles do
        for x = 1, #self.tiles[y] do
            self.tiles[y][x]:setDirty()
        end
    end
end

--- Returns room width in tiles.
-- @treturn int width
function roomClass:getRoomWidth()
end
--- Returns room height in tiles
-- @treturn int height
function roomClass:getRoomHeight()
end

--- Returns position in world.
-- Returns a new list of tiles that have
-- offsets applied to their respective x & y values.
-- @treturn table room
function roomClass:getPositionInWorld()
end

--- Generate a square room
-- @param width
-- @param height
function roomClass:generateSquareRoom(width, height)
    self.tiles = self:createRoomBuffer(width + 2, height + 2) -- Reset interal buffer

    -- Build a 1 tile border for walls.
    for y = 2, #self.tiles - 1 do
        for x = 2, #self.tiles[y] - 1 do
            local tile = tileClass():createTile(self, x, y, 'floor')

            self.tiles[y][x] = tile
        end
    end

    self:addWallsToRoom()

    return self.tiles
end

--- Generate a circular room
-- @param radius
function roomClass:generateCircleRoom(radius)
    if radius % 2 == 0 then -- Needs to be a division of 2 for good circles
        radius = radius / 2
    else
        radius = (radius+1) / 2
    end

    local width = radius * 2 + 3
    local height = radius * 2 + 3

    self.tiles = self:createRoomBuffer(width, height)

    local centerX = math.floor(radius) + 2
    local centerY = math.floor(radius) + 2

    for y = 1, #self.tiles - 1 do
        for x = 1, #self.tiles[y] - 1 do
            local distance = (x - centerX)^2 + (y - centerY)^2 - radius^2
            local max = math.sqrt(radius)
            local tile = tileClass():createTile(self, x, y, 'floor')

            if distance < max then
                self.tiles[y][x] = tile
            end
        end
    end

    self:addWallsToRoom()

    return self.tiles
end

--- Private function for CA Room generation.
-- Executes one "step" of Cellular Automata
-- generation with the provided parameters.
-- @tparam table room
-- @param birthLimit
-- @param deathLimit
local function _doStep(room, birthLimit, deathLimit)
end

--- Generate a room using Cellular Automata.
-- Configurable with optional args.
-- @param width (minimum 15)
-- @param height (minimum 15)
-- @param args (optional) birthLimit, deathLimit, startAliveChance, steps.
function roomClass:generateCARoom(width, height, args)
end

--- Combines specified room with current room.
-- If (ox, oy) is given, the room being added will
-- be offset by that amount. Otherwise it's centered.
-- @tparam table room room
-- @param ox
-- @param oy
function roomClass:combineWith(room, ox, oy)
    return room
end

--- Randomly adds doors a room.
-- Based on cardinal direction of walls in room.
function roomClass:addDoorsToRoom()
end

--- Fills in wall tiles around floor tiles.
-- Set 'empty' tiles with 'floor' neighbors as walls.
function roomClass:addWallsToRoom()
    local oldRoom = self.tiles

    self:setDirty() -- Clean tiles before checking neighbors

    for y = 1, #oldRoom do
        for x = 1, #oldRoom[y] do
            local tile = oldRoom[y][x]

            if tile and tile:getType('empty') then
                for _, data in pairs(tile.localNeighbors) do
                    local neighbor = data.tile

                    if neighbor:getType('floor') then
                        tile:setType('wall')
                        break
                    end
                end
            end
        end
    end
end




return roomClass

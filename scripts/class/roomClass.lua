--- Room Class.
-- Used in Procedural generation. Contains methods using
-- the Builder design pattern to stitch together rooms
-- that are procedurally generated.
-- @module roomClass.lua
-- @author Lonely Owl Games

-- Class declaration.
local Class = require 'libraries.hump.class'
local tileClass = require 'scripts.class.tileClass'
local CA = require 'scripts.class.cellular'
local roomClass = Class{}

local id = 0
function roomClass:init()
    self.tiles = {}

    self.dungeon = nil -- Reference to dungeon

    id = id + 1
    self.id = id

    self.x = 1
    self.y = 1
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
-- @treturn table buffer A 2D array of tile objects
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
-- @treturn object room for chaining functions
function roomClass:setDirty()
    for y = 1, #self.tiles do
        for x = 1, #self.tiles[y] do
            self.tiles[y][x]:setDirty()
        end
    end

    return self
end

function roomClass:setPosition(x, y)
    self.x = x
    self.y = y

    for oldy = 1, #self.tiles do
        for oldx = 1, #self.tiles[oldy] do
            local tile = self.tiles[oldy][oldx]

            tile:setWorldPosition(x + oldx, y + oldy)
        end
    end

    return self
end

--- Returns room width in tiles.
-- by iterating over ever [y] value and then
-- pushing the largest x value to the top of a 
-- stack to pop out. Then calculations based on world pos
-- @tparam boolean excludeEmpties whether count empty tiles
-- @treturn int width
function roomClass:getRoomWidth(excludeEmpties)
    local counts = {}
    local width

    -- Add tiles (x) value to table to sort
    for y = 1, #self.tiles do
        for x = 1, #self.tiles[y] do
            if excludeEmpties then
                if not self.tiles[y][x]:getType('empty') then
                    table.insert(counts, x)
                end
            else
                table.insert(counts, x)
            end
        end
    end

    -- Push largest x (width) value to top
    table.sort(counts, function(a,b) return a > b end)

    -- Pop largest x value
    width = counts[1]

    -- See where the room is in the world
    local roomXPos, _ = self:getPositionInWorld()

    -- Subtract world position by largest x value to get width
    -- if self.dungeon then
    --     return width
    -- else
    --     return width - roomXPos + 1
    -- end
    return width - roomXPos + 1
end

--- Returns room height in tiles
-- if empties are excluded, we need to loop through entire
-- 2D array to find non-empty tiles. Then sort over their 
-- y-values to determine the largest value relative to world pos.
-- @tparam boolean excludeEmpties from search
-- @treturn int height
function roomClass:getRoomHeight(excludeEmpties)
    local height

    if excludeEmpties then
        local counts = {}

        for y = 1, #self.tiles do
            for x = 1, #self.tiles[y] do
                if not self.tiles[y][x]:getType('empty') then
                    table.insert(counts, y)
                end
            end
        end

        table.sort(counts, function(a,b) return a > b end)

        height = counts[1]
    else
        height = #self.tiles
    end

    -- See where the room is in the world
    local _, roomYPos = self:getPositionInWorld()

    -- Subtract world Y position by room Y position for height
    -- if self.dungeon then
    --     return height
    -- else
    --     return height - roomYPos + 1
    -- end
    return height - roomYPos + 1
end

function roomClass:getRoomDimensions(excludeEmpties)
    return self:getRoomWidth(excludeEmpties), self:getRoomHeight(excludeEmpties)
end

--- Returns position in world.
-- Returns a new list of tiles that have
-- offsets applied to their respective x & y values.
-- @return (x,y) x & y position in world.
function roomClass:getPositionInWorld()
    return self.x, self.y
    -- local listOfXTiles = {}
    -- local listOfYTiles = {}
    --
    -- for y = 1, #self.tiles do
    --     for x = 1, #self.tiles[y] do
    --         local tile = self.tiles[y][x]
    --
    --         if not tile:getType('empty') then
    --             table.insert(listOfXTiles, tile.wx)
    --             table.insert(listOfYTiles, tile.wy)
    --         end
    --     end
    -- end
    --
    -- table.sort(listOfXTiles, function(a,b) return a < b end)
    -- table.sort(listOfYTiles, function(a,b) return a < b end)
    --
    -- return listOfXTiles[1], listOfYTiles[1]
end

--- Generate a square room
-- @param width
-- @param height
-- @treturn object room for chaining functions
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

    return self
end

--- Generate a circular room
-- @param radius
-- @treturn object room for chaining functions
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

    return self
end

function roomClass:generateCARoom(width, height)
    local birthLimit = 4
    local deathLimit = 4
    local startAliveChance = 50
    local steps = 5

    local CAMap = CA()
    local map = CAMap:generateCAMap(width, height, birthLimit, deathLimit, startAliveChance, steps)
    local listOfFloorTiles = {}

    if not map then assert(map, 'Invalid map for CA room generation') return end

    for y = 1, #map do
        for x = 1, #map[y] do
            if map[y][x]:getType('floor') then
                table.insert(listOfFloorTiles, map[y][x])
            end
        end
    end

    -- Pick a random floor tile
    local pickRandomTile = listOfFloorTiles[math.random(1, #listOfFloorTiles)]

    -- If map is garbage, generate a new room.
    if not pickRandomTile then return self:generateCARoom(width, height) end

    -- Flood fill that tile, return table of filled tiles
    local fill = CAMap:floodFill(map, pickRandomTile)

    local room = roomClass():createRoomFromTable(width, height, fill)

    room:addWallsToRoom()

    return room
end

function roomClass:setTile(x, y, type)
    self.tiles[y][x]:setType(type)
end

-- Needs to return 2D array of self.tiles
function roomClass:getSerializedRoomTiles()
    local serializeTileData = {}

   for y = 1, #self.tiles do
        for x = 1, #self.tiles[y] do
            local sid = self.tiles[y][x]:serialize()


            serializeTileData[sid] = self.tiles[y][x].serializeData
        end
    end

    return serializeTileData
end


-- dungeon ->
--  roomid -> data{
--                 tileId -> data
--                 tileId -> data
--                 tileId -> data
--  roomid -> data{
--                 tileId -> data
--                 tileId -> data
--                 tileId -> data

function roomClass:getTile(x, y)
    if self.tiles[y] and self.tiles[y][x] then
        return self.tiles[y][x]
    else
        return false
    end
end

--- Combines specified room with current room.
-- If (ox, oy) is given, the room being added will
-- be offset by that amount. Otherwise it's centered.
-- @tparam object room to combine with
-- @param ox x displacement from center
-- @param oy y displacement from center
-- @treturn object room
function roomClass:combineWith(room, ox, oy)
    local maxWidth = math.max(self:getRoomWidth(), room:getRoomWidth())
    local maxHeight = math.max(self:getRoomHeight(), room:getRoomHeight())

    local x1, y1 = self:getPositionInWorld()
    local x2, y2 = room:getPositionInWorld()

    local startX = math.min(x1, x2)
    local startY = math.min(x2, y2)

    local buffer = roomClass():generateSquareRoom(maxWidth - 2, maxHeight - 2)

    for y = 1, #buffer.tiles do
        for x = 1, #buffer.tiles[y] do
            buffer.tiles[y][x]:setType('empty')
        end
    end

    local rooms = {self, room}
    for _, r in pairs(rooms) do
        local cx = math.floor(maxWidth/2) - math.floor(r:getRoomWidth()/2)
        local cy = math.floor(maxHeight/2) - math.floor(r:getRoomHeight()/2)

        for x = startX, maxWidth do
            for y = startY, maxHeight do
                local tile = r:getTile(x, y)
                local target = buffer:getTile(x + cx, y + cy)

                if tile and target then
                    if tile:getType('floor') then
                        target:setType(tile:getType())
                    end

                    if tile:getType('wall') then
                        if target:getType('empty') then
                            target:setType(tile:getType())
                        end
                    end
                end
            end
        end
    end

    self.tiles = buffer.tiles

    return self
end

--- Randomly adds doors a room.
-- Based on cardinal direction of walls in room.
function roomClass:addDoorsToRoom()

    for y = 1, #self.tiles do
        for x = 1, #self.tiles[y] do
            local tile = self.dungeon.tiles[y][x]

            if tile:getType('wall') then
                if tile:hasProperty('isOverlappingWall') then
                    local neighbors = tile.localNeighbors
                    error('adddoorstoroom')
                    print(#neighbors)
                end
            end
        end
    end
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

--- Creates a room object from a list of tiles
-- Needed because some generation algorithms
-- like CA will output its result into a single
-- dimension table instead of a 2D array of tiles.
-- @param width
-- @param height
-- @param table to convert into 2D array
function roomClass:createRoomFromTable(width, height, table)
    self.tiles = self:createRoomBuffer(width, height, 'empty')

    for _, tile in pairs(table) do
        if self.tiles[tile.y] and self.tiles[tile.y][tile.x] then
            self.tiles[tile.y][tile.x]:setType(tile:getType())
        end
    end

    return self
end

-- dungeon ->
--  roomid -> data{
--                 tileId -> data
--                 tileId -> data
--                 tileId -> data
--  roomid -> data{
--                 tileId -> data
--                 tileId -> data
--                 tileId -> data


-- Tiles in Room are Serialized by {key = {tileData}}
function roomClass:serialize()
    local serializeTileData = self:getSerializedRoomTiles()

    self.serializeData = {}
    self.serializeData.tiles = serializeTileData
    self.serializeData.x = self.x
    self.serializeData.y = self.y
    self.serializeData.id = self.id
    self.serializeData.dungeon = self.dungeon

    return self.serializeData
end


return roomClass
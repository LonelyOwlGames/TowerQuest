---- Implements Room Objects for room accretion. Room objects are
-- containers of tile data, with special behavior for generation.
--
-- @classmod Room
-- @author LonelyOwl
-- @usage Room() 
-- @copyright Creative Commons Attribution 4.0 International License

--- List of data structures contained within.
--
-- @field x (int) x world position of room. (top left corner)
-- @field y (int) y world position of room. (top left corner)
-- @field dungeon (int) id of dungeon the room belongs to.
-- @field connectedRooms (table) a list of connected rooms indexed by id.
-- @field tiles (table) List of tile objects in room.
-- @field tileCache (table) 2D array of tile ids indexed by local x, y position.

local Class = require 'libraries.hump.class'
local tileClass = require 'scripts.class.tileClass'
local CA = require 'scripts.class.cellular'
local Hallway = require 'scripts.prefabs.hallways'
local Room = Class{}

function Room:init()
    self.tiles = {}

    self.dungeon = nil -- Reference to dungeon

    self.x = 1
    self.y = 1

    self.children = {}

    self.type = ''

    self.tileCache = {}

    self.connectedRooms = {}
    self.connections = {}
end

--- Creates a room buffer (hash map) for tile manipulation.
-- @lfunction Room:_createRoomBuffer
function Room:_createRoomBuffer(width, height, type)
    local buffer = {}
    type = type or 'empty'

    for y = 1, height do
        buffer[y] = {}
        self.tileCache[y] = {}
        for x = 1, width do
            local tile = tileClass():createTile(self, x, y, type)
            self.tileCache[y][x] = {}
            buffer[y][x] = tile
        end
    end

    return buffer
end

--- Set world position of room, and update tile (wx, wy) positions.
function Room:setPosition(x, y)
    self.x = x
    self.y = y

    for oldy = 1, #self.tiles do
        self.tileCache[oldy + y] = {}
        for oldx = 1, #self.tiles[oldy] do
            self.tileCache[oldy + y][oldx + x] = {}

            local tile = self.tiles[oldy][oldx]

            self.tileCache[y + tile.y][x + tile.x] = tile
            tile:setWorldPosition(x + tile.x, y + tile.y)
        end
    end

    return self
end

--- A function for pushing ids to Room.connectedRooms
-- @lfunction Room:connectTo
function Room:connectTo(id)
    -- self.connectedRooms[#self.connectedRooms] = id
    table.insert(self.connectedRooms, id)
end

--- Return room width by largest x-value of contained tiles.
-- @tparam boolean excludeEmpties whether to include empty tiles in calculation.
function Room:getRoomWidth(excludeEmpties)
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
    local roomXPos, _ = self:getPosition()

    return width - roomXPos + 1
end

--- Return room height by largest h-value of contained tiles.
-- @tparam boolean excludeEmpties whether to include empty tiles in calculation.
function Room:getRoomHeight(excludeEmpties)
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
    local _, roomYPos = self:getPosition()

    return height - roomYPos + 1
end

--- A function for getting width & height.
-- @see getRoomWidth
-- @see getRoomHeight
-- @tparam boolean excludeEmpties whether empty tiles should be counted.
function Room:getRoomDimensions(excludeEmpties)
    local height = #self.tiles
    local width = 0

    for y = 1, #self.tiles do
        for _ = 1, #self.tiles[y] do
            width = #self.tiles[y]
            break
        end
    end

    return width, height

    -- return self:getRoomWidth(excludeEmpties), self:getRoomHeight(excludeEmpties)
end

--- A function for getting the (x, y) position of a room. 
-- @see setPosition
function Room:getPosition()
    return self.x, self.y
end

--- Generate a square room
function Room:generateSquareRoom(width, height)
    self.tiles = self:_createRoomBuffer(width + 2, height + 2) -- Reset interal buffer

    -- Build a 1 tile border for walls.
    for y = 2, #self.tiles - 1 do
        self.tileCache[y] = {}
        for x = 2, #self.tiles[y] - 1 do
            local tile = tileClass():createTile(self, x, y, 'floor')

            self.tiles[y][x] = tile
            self.tileCache[x] = {}
        end
    end

    self.type = 'square'
    self:addWallsToRoom()

    return self
end

--- Generate a circular room given a radius.
function Room:generateCircleRoom(radius)
    if radius % 2 == 0 then -- Needs to be a division of 2 for good circles
        radius = radius / 2
    else
        radius = (radius+1) / 2
    end

    local width = radius * 2 + 3
    local height = radius * 2 + 3

    self.tiles = self:_createRoomBuffer(width, height)

    local centerX = math.floor(radius) + 2
    local centerY = math.floor(radius) + 2

    for y = 1, #self.tiles - 1 do
        self.tileCache[y] = {}
        for x = 1, #self.tiles[y] - 1 do
            local distance = (x - centerX)^2 + (y - centerY)^2 - radius^2
            local max = math.sqrt(radius)
            local tile = tileClass():createTile(self, x, y, 'floor')

            if distance < max then
                self.tileCache[y][x] = tile.id
                self.tiles[y][x] = tile
            end
        end
    end

    self.type = 'circle'
    self:addWallsToRoom()

    return self
end

-- Where list is a table indexed by y, x and true / false
function Room:generateChasm(width, height)
    local args = {}
    args.birthLimit = 5
    args.deathLimit = 4
    args.startAliveChance = 40
    args.steps = 3

    local chasm = self:generateCARoom(width, height, args)

    if not chasm then error('Failed to generate chasm in roomClass') end

    for y = 1, #chasm.tiles do
        for x = 1, #chasm.tiles[y] do
            if chasm.tiles[y][x].type == 'floor' then
                chasm.tiles[y][x].type = 'chasm'
            end

            if chasm.tiles[y][x].type == 'wall' then
                chasm.tiles[y][x].type = 'edge'
            end
        end
    end

    self.type = 'chasm'

    return chasm
end

function Room:applyWallsToChasm(dungeon)
    for y = 1, #self.tiles do
        for x = 1, #self.tiles[y] do
            local tile = self.tiles[y][x]
            local wx, wy = tile.wx, tile.wy

            if tile.type == 'edge' then
                local up = dungeon:_getTile(wx, wy-1)
                local down = dungeon:_getTile(wx, wy+1)
                local left = dungeon:_getTile(wx-1, wy)
                local right = dungeon:_getTile(wx+1, wy)

                if not up then
                    local new = tileClass():createTile(self, x, y-1, 'wall')
                    new.wx = wx
                    new.wy = wy
                    dungeon:_addTile(wx, wy-1, new)
                end

                if not down then
                    local new = tileClass():createTile(self, x, y+1, 'wall')
                    new.wx = wx
                    new.wy = wy
                    dungeon:_addTile(wx, wy+1, new)
                end

                if not left then
                    local new = tileClass():createTile(self, x-1, y, 'wall')
                    new.wy = wy
                    new.wx = wx
                    dungeon:_addTile(wx-1, wy, new)
                end

                if not right then
                    local new = tileClass():createTile(self, x+1, y, 'wall')
                    new.wx = wx
                    new.wy = wy
                    dungeon:_addTile(wx+1, wy, new)
                end
            end
        end
    end
end


--- Generate a Cellular Automata blob
function Room:generateCARoom(width, height, ...)
    local args = {...}
    args.birthLimit = args.birthLimit or 4
    args.deathLimit = args.deathLimit or 4
    args.startAliveChance = args.startAliveChance or 50
    args.steps = args.steps or 5

    local CAMap = CA()
    local map = CAMap:generateCAMap(width, height, args.birthLimit, args.deathLimit, args.startAliveChance, args.steps)
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

    local room = Room():createRoomFromTable(width, height, fill)

    self.type = 'blob'
    room:addWallsToRoom()

    return room
end

--- Set the type of a tile at local x, y position
function Room:setTile(x, y, type)
    self.tiles[y][x]:setType(type)
end

--- Iterates over all tiles inside room, and serializes those tiles for output. 
function Room:getSerializedRoomTiles()
    local serializeTileData = {}

   for y = 1, #self.tiles do
        for x = 1, #self.tiles[y] do
            local sid = self.tiles[y][x]:serialize()

            serializeTileData[sid] = self.tiles[y][x].serializeData
        end
    end

    return serializeTileData
end

--- Returns a tile Object based on local (x, y) position. 
function Room:getTile(x, y)
    if self.tiles[y] and self.tiles[y][x] then
        return self.tiles[y][x]
    else
        return false
    end
end

--- Returns a tile Object based on world (x, y) position
function Room:getTileByWorld(wx, wy)
    -- convert world to local
    local roomX, roomY = self:getPosition()
    local x = wx - roomX
    local y = wy - roomY

    if self.tiles[y] and self.tiles[y][x] then
        return self.tiles[y][x]
    end
end

-- TODO: Reimplement offset parameters.
--- Combines specified room with current room.
-- If (ox, oy) is given, the room being added will
-- be offset by that amount. Otherwise it's centered.
function Room:combineWith(room, ox, oy)
    local maxWidth = math.max(self:getRoomWidth(), room:getRoomWidth())
    local maxHeight = math.max(self:getRoomHeight(), room:getRoomHeight())

    local x1, y1 = self:getPosition()
    local x2, y2 = room:getPosition()

    local startX = math.min(x1, x2)
    local startY = math.min(x2, y2)

    local buffer = Room():generateSquareRoom(maxWidth - 2, maxHeight - 2)

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

--- Populate tile neighbors on tile Object for later reference.
function Room:setNeighbors()
    for y = 1, #self.tiles do
        for x = 1, #self.tiles[y] do
            local tile = self.tiles[y][x]
            tile.neighbors = {}

            if self.tiles[y-1] and self.tiles[y-1][x] then -- UP
                table.insert(tile.neighbors, {tile = self.tiles[y-1][x], direction = 'north'})
            end

            if self.tiles[y+1] and self.tiles[y+1][x] then -- DOWN
                table.insert(tile.neighbors, {tile = self.tiles[y+1][x], direction = 'south'})
            end

            if self.tiles[y] and self.tiles[y][x+1] then -- RIGHT
                table.insert(tile.neighbors, {tile = self.tiles[y][x+1], direction = 'east'})
            end

            if self.tiles[y] and self.tiles[y][x-1] then
                table.insert(tile.neighbors, {tile = self.tiles[y][x-1], direction = 'west'})
            end
        end
    end
end

--- Iterates over every tile in a room, and assigns empty cells
-- to wall cells if they're neighbored by floor cells.
function Room:addWallsToRoom()
    local oldRoom = self.tiles

    self:setNeighbors()
    -- self:setDirty() -- Clean tiles before checking neighbors

    for y = 1, #oldRoom do
        for x = 1, #oldRoom[y] do
            local tile = oldRoom[y][x]

            if tile and tile:getType('empty') then
                for _, data in pairs(tile.neighbors) do
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

--- Used after a room is generated. Set the roomid property of all
-- tiles in the room to the corresponding room.
function Room:assignRoomIds(id)
    for y = 1, #self.tiles do
        for x = 1, #self.tiles do
            if self.tiles[y][x] then
                self.tiles[y][x].roomid = id
            end
        end
    end
end

--- Creates a room object from a list of tiles.
-- Needed because some generation algorithms
-- like CA will output its result into a single
-- dimension table instead of a 2D array of tiles.
function Room:createRoomFromTable(width, height, table)
    self.tiles = self:_createRoomBuffer(width, height, 'empty')

    for _, tile in pairs(table) do
        if self.tiles[tile.y] and self.tiles[tile.y][tile.x] then
            self.tileCache[tile.y][tile.x] = tile.id
            self.tiles[tile.y][tile.x]:setType(tile:getType())
        end
    end

    return self
end

function Room:loadHallwayFromPrefab(data)
    local prefab = Hallway[data.type]

    self.tiles = self:_createRoomBuffer(prefab.width, prefab.height, 'empty')

    for y = 1, prefab.height do
        for x = 1, prefab.width do
            if self.tiles[y][x] then
                if prefab.map[y][x] == 2 then
                    self.tiles[y][x].type = 'door'
                end

                if prefab.map[y][x] == 1 then
                    self.tiles[y][x].type = 'floor'
                end

                if prefab.map[y][x] == 3 then
                    self.tiles[y][x].type = 'wall'
                end

                if prefab.map[y][x] == 4 then
                    self.tiles[y][x].type = 'ignore'
                end
            end
        end
    end

    self.type = 'hallway'

    return self
end

function Room:delete()
    local tileCount = 0

    for i = #self, 1, -1 do
        self[i] = nil
    end

    self = nil

    love.thread.getChannel('stats'):push({tilesDeleted = tileCount})
end

--- Serialization of room, and tiles consequentially.
-- Serialization data: {key = id, value = {serializedTileData}}
function Room:serialize()
    local serializeTileData = self:getSerializedRoomTiles()

    self.serializeData = {}
    self.serializeData.tiles = serializeTileData
    self.serializeData.x = self.x
    self.serializeData.y = self.y
    self.serializeData.id = self.id
    -- self.serializeData.dungeon = self.dungeon

    return self.serializeData
end


return Room

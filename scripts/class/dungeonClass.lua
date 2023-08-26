--- Implements dungeon generation by room accretion method.
--
-- @classmod Dungeon
-- @author LonelyOwl
-- @usage Dungeon():buildDungeon(width, height)
-- @copyright Creative Commons Attribution 4.0 International License

--- List of data structures contained within.
-- Any array that serves the purpose of a cache is simply a
-- list of ids indexed by ids. So tileCache is simply an array
-- conntaining tile id's indexed by (x, y) position.
--
-- @field width (int) width of dungeon in tiles.
-- @field height (int) height of dungeon in tiles.
-- @field id (int) a unique identifier for rooms.
-- @field roomCount (int) a count of rooms generated successfully.
-- @field tileCache (table) 2D array of room id's indexed by x, and y values.
-- @field sleep (float) value for slowing down generation for visualization.

local Class = require 'libraries.hump.class'
local roomClass = require 'scripts.class.roomClass'
local bitser = require 'libraries.bitser'
local CA = require 'scripts.class.cellular'
local dungeonClass = Class{}

--- Generates a unique UUID for rooms.
local function _createUUID()
    local uuid = ''
    local chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
    for i = 1, 30 do
        local l = math.random(1, #chars)
        uuid = uuid .. string.sub(chars, l, l)
    end
    return uuid
end

function dungeonClass:init(width, height)
    self.id = 1
    self.numberOfRooms = 0
    self.first = true

    -- self.width = math.floor(width)
    -- self.height = math.floor(height)
    self.maxDensity = 20 -- % to fill. (max ~70-80%)

    self.width = self.maxDensity*20
    self.height = self.maxDensity*20

    self.sleep = 0.01

    self.tileCache = {}
    for y = 1, self.height do
        self.tileCache[y] = {}
        for x = 1, self.width do
            self.tileCache[y][x] = false
        end
    end

    self.listOfRooms = {}


    self.changes = {} -- experiment with changes stack
end

--- Generates a random pre-authored room.
-- @lfunction dungeonClass:generateRoom
function dungeonClass:_generateRandomRoom()
    local select = math.random(1,10)
    local r

    if select == 1 then -- Horizontal rectangle
        r = roomClass():generateSquareRoom(math.random(3,4), math.random(6,7))
    elseif select == 2 then -- Vertical rectangle
        r = roomClass():generateSquareRoom(math.random(6,7), math.random(3,4))
    elseif select == 3 then -- Cross or L rectangles
        local a = roomClass():generateSquareRoom(math.random(2,4), math.random(6,8))
        local b = roomClass():generateSquareRoom(math.random(6,8), math.random(2,4))
        r = a:combineWith(b, math.random(-1,1),math.random(-1,1))
    elseif select == 4 then -- Square + circle
        local a = roomClass():generateSquareRoom(math.random(2,4), math.random(2,4))
        local b = roomClass():generateCircleRoom(math.random(3,6))
        r = a:combineWith(b, math.random(-1,1),math.random(-1,1))
    elseif select == 5 then -- double circle + square
        local a = roomClass():generateCircleRoom(math.random(4,6))
        local b = roomClass():generateCircleRoom(math.random(4,8))
        local c = roomClass():generateSquareRoom(math.random(6,8), math.random(2,4))
        r = a:combineWith(b, math.random(-1,1), math.random(-1,1))
        r = r:combineWith(c, math.random(-2,2), math.random(-2,2))
    elseif select == 6 then -- CA blob + square
        local a = roomClass():generateCARoom(10, 10)
        local b = roomClass():generateSquareRoom(math.random(4,8), math.random(4,8))
        r = a:combineWith(b, math.random(-1,1), math.random(-1,1))
    elseif select == 7 then -- big CA blob
        r = roomClass:generateCARoom(20,20)
    elseif select == 8 then -- two small CA blobs
        local a = roomClass():generateCARoom(10,10)
        local b = roomClass():generateCARoom(10,10)
        r = a:combineWith(b, 0, 0)
    elseif select == 9 then -- big circle
        r = roomClass():generateCircleRoom(math.random(8,12))
    elseif select == 10 then -- big t
        local a = roomClass():generateSquareRoom(math.random(6,8), math.random(10,12))
        local b = roomClass():generateSquareRoom(math.random(10,12), math.random(6,8))
        r = a:combineWith(b, math.random(-2,2), math.random(-2,2))
    end

    r.id = _createUUID()
    r:assignRoomIds(r.id)

    return r
end


-- FIXME: Current issue is that as more rooms are added to the dungeon, we
-- are returning rooms that have no candidates for connection. But we still
-- iterate over all the possible stops. Big O mothafucka.
-- Need to track connectedness
-- [FIXED] I think this is fixed now. Will return once lag is sorted. Not laging issue.

--- Returns a random room Object from dungeonClass.listOfRooms.
-- @lfunction dungeonClass:_getRandomRoom
function dungeonClass:_getRandomRoom()
    local rooms = {}

    for _, room in pairs(self.listOfRooms) do
        if #room.connectedRooms <= 1 then -- At 2, starts slowing at around 30 rooms
            table.insert(rooms, room)
        end
    end

    return rooms[math.random(1, #rooms)]
end

--- Retrieve a tile Object from a Room id.
-- @lfunction dungeonClass:_getTileByRoomID
function dungeonClass:_getTile(wx, wy, targetRoomID)
    if targetRoomID then
        local targetRoom = self.listOfRooms[targetRoomID]
        local roomTileCache = targetRoom.tileCache

        if roomTileCache[wy] and roomTileCache[wy][wx] then return roomTileCache[wy][wx] end
    end

    if not targetRoomID then
        local targetRoomID = self.tileCache[wy][wx]
        local targetRoomTiles = self:_getRoomByID(targetRoomID)

        if targetRoomTiles then
            local roomTileCache = targetRoomTiles.tileCache

            if roomTileCache [wy] and roomTileCache[wy][wx] then return roomTileCache[wy][wx] end
        end
    end

    return false
end

--- "Throw" a generated room at the dungeon. If it is 
--a valid placement, place the room into the dungeon.
-- @lfunction dungeonClass:_throwRoomAtDungeon
function dungeonClass:_throwRoomAtDungeon(room)
    local roomWidth, roomHeight = room:getRoomDimensions()

    local targetRoom = self:_getRandomRoom()
    local rx, ry = targetRoom:getPosition()
    local rw, rh = targetRoom:getRoomDimensions()


    -- Start scanning top left corner
    local startX = rx - roomWidth
    local startY = ry - roomHeight

    local endX = rx + rw + roomWidth
    local endY = ry + rh + roomHeight

    -- When a room is selected, try all possible sides before discarding
    for y = startY - 5, endY*3 do
        for x = startX - 5, endX*3 do
            if self:_isValidRoomPlacement(room, x, y, targetRoom) then
                self:_addRoom(room, x, y)
                return true
            end
        end
    end

    return false
end

--- Check if room placement at (x, y) is valid.
-- @lfunction dungeonClass:_isValidRoomPlacement
function dungeonClass:_isValidRoomPlacement(room, x, y, target)
    x = math.floor(x)
    y = math.floor(y)

    local overlappingWallCount = 0
    local overlappingFloorCount = 0
    local listOfConnectedWalls = {}

    local targetRoomID = target.id

    for ry = 1, #room.tiles do
        for rx = 1, #room.tiles[ry] do

            -- TODO: This is needed because of the tileCache initializing.
            -- If tilecache could be initialized with negative x,y values then
            -- we could remove this.

            -- Return false if any single tile it outside map bounds.
            if (x + rx) <= 0 or (x + rx) >= self.width then return false end
            if (y + ry) <= 0 or (y + ry) >= self.height then return false end

            local roomTile = room.tiles[ry][rx]

            -- Retrieve tile data from room we're attaching too.
            local targetedTileRoomID = self.tileCache[y + ry][x + rx] -- <- returns roomid now 
            local targetedTile = self:_getTile(x + rx, y + ry, targetedTileRoomID)


            -- Check where we would place our tile, and see what is there.
            if targetedTileRoomID then
                if roomTile:getType('wall') then
                    if targetedTile and targetedTile:getType('wall') then
                        table.insert(listOfConnectedWalls, {roomTile, targetedTile})
                        overlappingWallCount = overlappingWallCount + 1
                    else
                        overlappingFloorCount = overlappingFloorCount + 1
                    end
                else
                    overlappingFloorCount = overlappingFloorCount + 1
                end
            end
        end
    end

    if overlappingWallCount > 0 and overlappingFloorCount == 0 then
        room.connectedWallTiles = listOfConnectedWalls
        return true
    else
        return false
    end
end

--- Place room into dungeon at (x,y), assign the room a UUID.
-- @lfunction dungeonClass:_addRoom
function dungeonClass:_addRoom(roomToAdd, x, y)
    -- Set's all tiles world position to new position
    local addedRoom = roomToAdd:setPosition(x, y)
    addedRoom.id = _createUUID()
    addedRoom:assignRoomIds(addedRoom.id)

    -- Add room tiles to dungoen tileCache for quicker generation
    for ry = 1, #roomToAdd.tiles do
        for rx = 1, #roomToAdd.tiles[ry] do
            -- self.tileCache[ry + y][rx + x] = addedRoom.id
            -- insert so that it places duplicates
            if not roomToAdd.tiles[ry][rx]:getType('empty') then
                -- table.insert(self.tileCache[ry + y], rx + x, addedRoom.id)
                self.tileCache[ry + y][rx + x] = addedRoom.id
            end
        end
    end

    -- Add room to list of rooms in dungeon
    self.listOfRooms[addedRoom.id] = addedRoom
    self.numberOfRooms = self.numberOfRooms + 1
    table.insert(self.changes, addedRoom)
end

function dungeonClass:serializeChanges(type)
    local data = {}
    
    if type == 'room' then
        local room = self.changes[1]

        if room then
            table.remove(self.changes, 1)

            local roomData = room:serialize()

            data[room.id] = roomData
        end

        if data and room then
            return bitser.dumps(data)
        else
            return false
        end
    elseif type == 'tile' then
        local tile = self.changes[1]

        if tile then
            table.remove(self.changes, 1)

            -- local tileData = tile:serialize()
            tile:serialize()
            local tileData = tile.serializeData

            data[tile.id] = tileData
        end

        if data and tile then
            return bitser.dumps(data)
        else
            return false
        end
    end
end


function dungeonClass:serialize()
   local data = {}
    for _, room in pairs(self.listOfRooms) do
        local roomData = room:serialize() -- Returns room.serializeData containing tile.serializeData's
        data[room.id] = roomData
    end

    return bitser.dumps(data)
end

--- Returns room Object based on ID.
-- @lfunction dungeonClass:_getRoomByID
function dungeonClass:_getRoomByID(id)
    return self.listOfRooms[id]
end

--- Resolve overlapping wall conflicts, and place doors.
-- @lfunction dungeonClass:_resolveOverlappingWalls
function dungeonClass:_resolveOverlappingWalls(room)
    local connectedRoomIDs = {} 

    if not room.connectedWallTiles then return end

    -- Based on how dungeon generation works, connected wall tiles are the only
    -- tiles that overlap and need to be resolved
    for _, conflictingTiles in pairs(room.connectedWallTiles) do
        local wall1 = conflictingTiles[1]
        local wall2 = conflictingTiles[2]
        wall1.roomid = wall1.roomid or 'no id'
        wall2.roomid = wall2.roomid or 'no id'

        -- Wall 1 is always in room, wall2 is connecting room

        -- Discard wall 2's in favor of wall 1's
            wall1:setType('door')
            wall2:setType('empty') -- no delete function yet?

        -- Added wall 2's room as a connected room
            room:connectTo(wall2.roomid)

        -- local wx, wy = wallTile:getWorldPosition()
        -- local tile = room:getTileByWorld(wx, wy)
        --
        -- tile:setType('empty')
    end
end

-- TODO: Fix door implementation and corner door pruning as a whole.
--- Iterate over door locations, and prune bad doors.
-- @lfunction dungeonClass:handleDoorConnections
function dungeonClass:handleDoorConnections(index)
    love.timer.sleep(self.sleep/2)

    local rooms = {}
    for id, room in pairs(self.listOfRooms) do
        table.insert(rooms, room)
    end

    local room = rooms[index]
    local doorsInRoom = {}

    for y = 1, #room.tiles do
        for x = 1, #room.tiles[y] do
            if room.tiles[y][x]:getType('door') then
                table.insert(doorsInRoom, room.tiles[y][x])
            end
        end
    end

    local selectRandom = math.random(1, #doorsInRoom)
    for n = 1, #doorsInRoom do
        if doorsInRoom[n].id ~= doorsInRoom[selectRandom].id then
            doorsInRoom[n]:setType('wall')
            table.insert(self.changes, doorsInRoom[n])
        end
    end

    -- table.insert(self.changes, doo)
    return self:serializeChanges('tile')
end

function dungeonClass:_floodFillTile(start, list)
    if not start then return end
    if start._analyzed then return end

    list = list or {}

    start._analyzed = true
    table.insert(list, start)

    local x = start.wx
    local y = start.wy

    local up = self:_getTile(x, y-1)
    local down = self:_getTile(x, y+1)
    local left = self:_getTile(x-1, y)
    local right = self:_getTile(x+1, y)

    if up and up.getType then
        if not up:getType('wall') and not up._analyzed then
            self:_floodFillTile(up, list)
            -- self:analyzeMapConnectivity(up)
        end
    end

    if down and down.getType then
        if not down:getType('wall') and not down._analyzed then
            -- self:analyzeMapConnectivity(down)
            self:_floodFillTile(down, list)
        end
    end

    if left and left.getType then
        if not left:getType('wall') and not left._analyzed then
            -- self:analyzeMapConnectivity(left)
            self:_floodFillTile(left, list)
        end
    end

    if right and right.getType then
        if not right:getType('wall') and not right._analyzed then
            -- self:analyzeMapConnectivity(right)
            self:_floodFillTile(right, list)
        end
    end

    start:setType('fill')

    -- Spit out flooded tile to :analyzeMapConnectivity
    -- everytime we call this function
    return list
end

function dungeonClass:analyzeMapConnectivity(start)
    -- love.timer.sleep(self.sleep/2)

    if not start then
        local rooms = {}
        for _, room in pairs(self.listOfRooms) do
            table.insert(rooms, room)
        end

        local room = rooms[1]

        if room then
            for y = 1, #room.tiles do
                for x = 1, #room.tiles[y] do
                    if room.tiles[y][x]:getType('floor') then
                        if not start and math.random(1,2) == 2 then
                            start = room.tiles[y][x]
                            break
                        end
                    end
                end
            end
        end
    end

    local list = self:_floodFillTile(start) or {}

    -- if tile then
    for _, tile in pairs(list) do
        table.insert(self.changes, tile)
        -- return self:serializeChanges('tile')
    end

    return self:serializeChanges('tile')
end

--- Starts dungeon generation.
-- @usage Dungeon():buildDungeon()
function dungeonClass:buildDungeon()
    if self.first then
        local startingRoom = self:_generateRandomRoom()
        self:_addRoom(startingRoom, 1, 1)
        self.first = false

        local changes = self:serializeChanges('room')
        return changes
    end

    local room = self:_generateRandomRoom()
    self:_throwRoomAtDungeon(room)

    -- Place potential doors on new room where overlapping walls exist.
    self:_resolveOverlappingWalls(room)

    -- Intentionally slow down recursion
    love.timer.sleep(self.sleep)


    return self:serializeChanges('room')
end

return dungeonClass


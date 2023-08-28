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

-- Lua GEMS says this is faster for large iterators.
local math = math
local floor = math.floor
local random = math.random
local abs = math.abs
local huge = math.huge

local table = table
local remove = table.remove
local sort = table.sort
local insert = table.insert



--- Generates a unique UUID for rooms.
local function _createUUID()
    local uuid = ''
    local chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
    for i = 1, 30 do
        local l = random(1, #chars)
        uuid = uuid .. string.sub(chars, l, l)
    end
    return uuid
end

function dungeonClass:init(width, height)
    self.id = 1
    self.numberOfRooms = 0
    self.numberOfDoors = 0
    self.numberOfTiles = 0
    self.first = true

    self.maxDensity = 50 -- % to fill. (max ~70-80%)

    local ratio = self.maxDensity / 20

    -- TODO: Need an algorithm for pre-determining width & height based on density.
    self.width = self.maxDensity*2
    self.height = self.maxDensity*2

    self.startx = 1
    self.starty = 1

    self.sleep = 0.1

    self.tileCache = {}
    for y = self.starty, self.height do
        self.tileCache[y] = {}
        for x = self.startx, self.width do
            self.tileCache[y][x] = false
        end
    end

    self.listOfRooms = {} -- index -> room Object
    self.listOfRoomsIndex = {} -- id -> index

    self.roomHistory = {}

    self.changes = {} -- experiment with changes stack
end

--- Generates a random pre-authored room.
-- @lfunction dungeonClass:generateRoom
function dungeonClass:_generateRandomRoom()
    local select = random(1,10)
    local r

    if select == 1 then -- Horizontal rectangle
        r = roomClass():generateSquareRoom(random(3,4), random(6,7))
    elseif select == 2 then -- Vertical rectangle
        r = roomClass():generateSquareRoom(random(6,7), random(3,4))
    elseif select == 3 then -- Cross or L rectangles
        local a = roomClass():generateSquareRoom(random(2,4), random(6,8))
        local b = roomClass():generateSquareRoom(random(6,8), random(2,4))
        r = a:combineWith(b, random(-1,1),random(-1,1))
    elseif select == 4 then -- Square + circle
        local a = roomClass():generateSquareRoom(random(2,4), random(2,4))
        local b = roomClass():generateCircleRoom(random(3,6))
        r = a:combineWith(b, random(-1,1),random(-1,1))
    elseif select == 5 then -- double circle + square
        local a = roomClass():generateCircleRoom(random(4,6))
        local b = roomClass():generateCircleRoom(random(4,8))
        local c = roomClass():generateSquareRoom(random(6,8), random(2,4))
        r = a:combineWith(b, random(-1,1), random(-1,1))
        r = r:combineWith(c, random(-2,2), random(-2,2))
    elseif select == 6 then -- CA blob + square
        local a = roomClass():generateCARoom(10, 10)
        local b = roomClass():generateSquareRoom(random(4,8), random(4,8))
        r = a:combineWith(b, random(-1,1), random(-1,1))
    elseif select == 7 then -- big CA blob
        r = roomClass:generateCARoom(20,20)
    elseif select == 8 then -- two small CA blobs
        local a = roomClass():generateCARoom(10,10)
        local b = roomClass():generateCARoom(10,10)
        r = a:combineWith(b, 0, 0)
    elseif select == 9 then -- big circle
        r = roomClass():generateCircleRoom(random(8,12))
    elseif select == 10 then -- big t
        local a = roomClass():generateSquareRoom(random(6,8), random(10,12))
        local b = roomClass():generateSquareRoom(random(10,12), random(6,8))
        r = a:combineWith(b, random(-2,2), random(-2,2))
    end

    r.id = _createUUID()
    r:assignRoomIds(r.id)

    return r
end

local function sortByConnections(a,b)
    return #a.connectedRooms < #b.connectedRooms
end

--- Returns a random room Object from dungeonClass.listOfRooms.
-- @lfunction dungeonClass:_getRandomRoom
function dungeonClass:_getRandomRoom(attempts, backStep) --PERF: Hash Maps Only
    backStep = backStep or 0

    -- Sort rooms by least connected rooms.
    sort(self.roomHistory, sortByConnections)

    -- If we need to step back, pop the top.
    if backStep > 0 then
        for n = 1, backStep do
            remove(self.roomHistory, n)
        end
    end

    -- Return popped value.
    return self.roomHistory[1]
end

--- For performance. Returns listOfRooms index based on roomid
function dungeonClass:_getRoomIndex(roomid) --PERF: Hash maps only
    return self.listOfRoomsIndex(roomid)
end


--- Retrieve a tile Object from a Room id.
-- @lfunction dungeonClass:_getTileByRoomID
function dungeonClass:_getTile(wx, wy, targetRoomID) -- PERF: Hash maps only
    if wx <= self.startx or wx >= self.width then return false end

    if wy <= self.starty or wy >= self.height then return false end

    if targetRoomID then
        local targetRoom = self.listOfRooms[targetRoomID]
        local roomTileCache = targetRoom.tileCache

        if roomTileCache[wy] and roomTileCache[wy][wx] then return roomTileCache[wy][wx] end
    end

    if not targetRoomID then
        targetRoomID = self.tileCache[wy][wx]
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
function dungeonClass:_throwRoomAtDungeon(room, attempts, mod)
    attempts = attempts or 0

    local roomWidth, roomHeight = room:getRoomDimensions()
    local targetRoom = self:_getRandomRoom(attempts, mod)


    local rx, ry = targetRoom:getPosition()
    local rw, rh = targetRoom:getRoomDimensions()

    -- Start scanning top left corner
    local startX = rx - roomWidth - 1
    local startY = ry - roomHeight - 1

    -- TODO: This should not be necessary...
    -- Likely a problem with :getPosition() or :getRoomWidth()
    local multi = (3 + floor(attempts/10))

    local endX = rx + rw + 1 + roomWidth*multi
    local endY = ry + rh + 1 + roomHeight*multi

    -- When a room is selected, try all possible sides before discarding
    for y = startY, endY do
        for x = startX, endX do
            if self:_isValidRoomPlacement(room, x, y, targetRoom) then
                targetRoom:connectTo(room.id)
                targetRoom.children = room.children + 1 or 1
                self:_addRoom(room, x, y)
                return true
            end
        end
    end
    
    -- Generate a new room to throw again.
    local newRoom = self:_generateRandomRoom()
    local attemptsAtTarget = 30

    -- If the room doesn't fit, throw a new generated room at it.
    if attempts < attemptsAtTarget then
        return self:_throwRoomAtDungeon(newRoom, attempts + 1)
    else -- If 10 new rooms don't fit, we go back step back 1 room and try again.
        local backSteps = attempts - attemptsAtTarget
        return self:_throwRoomAtDungeon(newRoom, attempts + 1, backSteps)
    end
end

--- Check if room placement at (x, y) is valid.
-- @lfunction dungeonClass:_isValidRoomPlacement
function dungeonClass:_isValidRoomPlacement(room, x, y, target)
    x = floor(x)
    y = floor(y)

    local overlappingWallCount = 0
    local overlappingFloorCount = 0
    local listOfConnectedWalls = {}

    for ry = 1, #room.tiles do
        for rx = 1, #room.tiles[ry] do
            if (x) <= self.starty or (x + rx) >= self.width then return false end
            if (y) <= self.startx or (y + ry) >= self.height then return false end

            local roomTile = room.tiles[ry][rx]

            -- Retrieve tile data from room we're attaching too.
            local targetedTileRoomID = self.tileCache[y + ry][x + rx] -- <- returns roomid now 
            local targetedTile = self:_getTile(x + rx, y + ry)


            -- Check where we would place our tile, and see what is there.
            if targetedTileRoomID then
                if not targetedTile then return false end

                if roomTile:getType('wall') and targetedTile:getType('wall') and targetedTileRoomID == target.id then
                    insert(listOfConnectedWalls, {roomTile, targetedTile})
                    overlappingWallCount = overlappingWallCount + 1
                end

                if roomTile:getType('floor') and not targetedTile:getType('empty') then
                    overlappingFloorCount = overlappingFloorCount + 1
                    return false -- Exits quicker, more efficient.
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
function dungeonClass:_addRoom(roomToAdd, x, y, customID)
    -- Set's all tiles world position to new position
    local addedRoom = roomToAdd:setPosition(x, y)
    addedRoom.id = customID or _createUUID()
    addedRoom:assignRoomIds(addedRoom.id)

    -- Add room tiles to dungoen tileCache for quicker generation
    for ry = 1, #roomToAdd.tiles do
        for rx = 1, #roomToAdd.tiles[ry] do
            if not roomToAdd.tiles[ry][rx]:getType('empty') then
                self.tileCache[ry + y][rx + x] = addedRoom.id
            end
        end
    end

    self.numberOfRooms = self.numberOfRooms + 1

    -- Add room to list of rooms in dungeon
    self.listOfRooms[addedRoom.id] = addedRoom
    self.listOfRoomsIndex[self.numberOfRooms] = addedRoom.id

    -- Cannot add directly due to roomHistory containing nils.
    insert(self.roomHistory, addedRoom)

    self.changes[1] = addedRoom
end

function dungeonClass:serializeChanges(type)
    local data = {}
    
    if type == 'room' then
        local room = self.changes[1]

        if room then
            remove(self.changes, 1)

            local roomData = room:serialize()

            -- data[room.id] = roomData
            insert(data, roomData)
        end

        if data and room then
            return bitser.dumps(data)
        else
            return false
        end
    elseif type == 'tile' then
        if #self.changes > 1 then
            local tile
            for _, change in pairs(self.changes) do
                tile = change

                if tile then
                    tile:serialize()
                    local tileData = tile.serializeData

                    insert(data, tileData)
                end
            end

            if data and tile then
                return bitser.dumps(data)
            else
                return false
            end

        else
            local tile = self.changes[1]

            if tile then
                remove(self.changes, 1)

                tile:serialize()
                local tileData = tile.serializeData

                insert(data, tileData)
            end

            if data and tile then
                return bitser.dumps(data)
            else
                return false
            end
        end
    end
end

--- Returns room Object based on ID.
-- @lfunction dungeonClass:_getRoomByID
function dungeonClass:_getRoomByID(id)
    return self.listOfRooms[id]
end

--- Resolve overlapping wall conflicts, and place doors.
-- @lfunction dungeonClass:_resolveOverlappingWalls
function dungeonClass:_resolveOverlappingWalls(room)
    if not room.connectedWallTiles then return end

    local select = random(1, #room.connectedWallTiles)

    -- Based on how dungeon generation works, connected wall tiles are the only
    -- tiles that overlap and need to be resolved
    for n, conflictingTiles in pairs(room.connectedWallTiles) do
        local wall1 = conflictingTiles[1]
        local wall2 = conflictingTiles[2]
        wall1.roomid = wall1.roomid or 'no id'
        wall2.roomid = wall2.roomid or 'no id'

        -- Wall 1 is always in room, wall2 is connecting room
        -- Discard wall 2's in favor of wall 1's
        if select == n then
            wall1.type = 'door'
            wall2.type = 'empty'
        else
            wall1.type = 'wall'
            wall2.type = 'empty'
        end

        self.numberOfDoors = self.numberOfDoors + 1
    end

    insert(self.changes, room)
end

function dungeonClass:_getAllTilesAsNodes()
    local grid = {}

    for y = 1, #self.tileCache do
        for x = 1, #self.tileCache[y] do
            local tile = self:_getTile(x, y)

            if tile then
                insert(grid, tile)
                self.numberOfTiles = self.numberOfTiles + 1
            end
        end
    end

    return grid
end

--- Return an array of tiles neighbors, unsorted.
function dungeonClass:_getTileNeighbors(node)
    local neighbors = {}

    local up = self:_getTile(node.wx, node.wy - 1)
    local down = self:_getTile(node.wx, node.wy + 1)
    local left = self:_getTile(node.wx - 1, node.wy)
    local right = self:_getTile(node.wx + 1, node.wy)

    if up then insert(neighbors, up) end
    if down then insert(neighbors, down) end
    if left then insert(neighbors, left) end
    if right then insert(neighbors, right) end

    return neighbors
end

function dungeonClass:_getMapValue(node)
    if node.type == 'wall' then
        return huge
    else
        return 1
    end
end

function dungeonClass:_manhattanDistance(nodeA, nodeB, costOfMove)
    local dx, dy = nodeA.wx - nodeB.wx, nodeA.wy - nodeB.wy
    return (costOfMove or 1) * (abs(dx) + abs(dy))
end

function dungeonClass:_dijkstra(source)
    local listOfNodes = self:_getAllTilesAsNodes()

    for _, node in pairs(listOfNodes) do
        node.distance = huge
        node.previous = nil
    end

    -- source.distance = 0
    listOfNodes[1].distance = 0
    sort(listOfNodes, function(a,b) return a.distance < b.distance end)

    while (#listOfNodes > 0) do

        -- Just for visual loading
        local test_count = ((self.numberOfTiles)-(floor(#listOfNodes)))*10
        local test_max = self.numberOfTiles
        if test_count < test_max then
            love.thread.getChannel('load'):push({'Analyzing Tiles (Dijkstra)', test_count, test_max})
        end

        local currentNode = listOfNodes[1]
        -- listOfNodes[1] = {}
        remove(listOfNodes, 1)

        insert(self.changes, source)

        if currentNode.distance == huge then break end

        local neighbors = self:_getTileNeighbors(currentNode)
        for _, neighborNode in pairs(neighbors) do
            local costOfMoveToNeighborNode = self:_getMapValue(neighborNode)
            local distanceToNeighborNode = self:_manhattanDistance(currentNode, neighborNode, costOfMoveToNeighborNode)
            local alt = currentNode.distance + distanceToNeighborNode

            if alt < neighborNode.distance then
                neighborNode.distance = alt
                neighborNode.previous = currentNode
                sort(listOfNodes, function(a,b) return a.distance < b.distance end)
            end
        end
    end
end

function dungeonClass:_floodFillTile(start, list)
    if not start then return end
    if start._analyzed then return end

    list = list or {}

    start._analyzed = true
    insert(list, start)

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

function dungeonClass:drawDebug()
    for _, room in pairs(self.listOfRooms) do
        for y = 1, #room.tiles do
            for x = 1, #room.tiles[y] do
                local tile = room.tiles[y][x]

                if tile and tile.distance then
                    love.graphics.rectangle('line', tile.wx, tile.wy, 64, 64)
                end
            end
        end
    end
end

local function _getTileFromStart(dungeon)
    local room = dungeon.listOfRooms['start']

    for y = 1, #room.tiles do
        for x = 1, #room.tiles[y] do
            if random(1,2) == 2 then
                return room.tiles[y][x]
            end
        end
    end
end

function dungeonClass:analyzeMapConnectivity()
    local start = _getTileFromStart(self)

    self:_dijkstra(start)

    -- Need to return a number of tiles processed by dijkstra
    local listOfNodes = {}
    for _, room in pairs(self.listOfRooms) do
        for y = 1, #room.tiles do
            for x = 1, #room.tiles[y] do
                local tile = room.tiles[y][x]

                if tile and tile.distance and not tile:getType('wall') then
                    tile:setType('fill')
                    insert(listOfNodes, tile)
                end
            end
        end
    end

    sort(listOfNodes, function(a,b) return a.distance < b.distance end)
    return listOfNodes
end

--- Starts dungeon generation.
-- @usage Dungeon():buildDungeon()
function dungeonClass:buildDungeon()
    if self.first then
        local startingRoom = self:_generateRandomRoom()
        self:_addRoom(startingRoom, 15, 15, 'start')
        self.roomHistory[1] = startingRoom
        self.first = false

        local changes = self:serializeChanges('room')
        return changes
    end

    local room = self:_generateRandomRoom()
    self:_throwRoomAtDungeon(room)

    -- Place potential doors on new room where overlapping walls exist.
    -- self:_resolveOverlappingWalls(room)

    -- Intentionally slow down recursion
    -- love.timer.sleep(self.sleep)


    -- collectgarbage('collect')
    return self:serializeChanges('room')
end

return dungeonClass


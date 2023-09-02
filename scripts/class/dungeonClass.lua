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


--- Shortcut for printing to runtime console.
local function printc(text)
    return love.thread.getChannel('console'):push(text)
end

--- Generates a unique UUID for rooms.
local function _createUUID()
    local uuid = ''
    local chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
    for _ = 1, 50 do
        local l = random(1, #chars)
        uuid = uuid .. string.sub(chars, l, l)
    end
    return uuid
end

function dungeonClass:init(theme)
    self.id = 1
    self.first = true
    self.theme = theme
    self.overlappingTiles = {}

    self.maxDensity = theme.rooms -- % to fill. (max ~70-80%)

    self.width = theme.dungeonWidth
    self.height = theme.dungeonHeight

    self.startx = 1
    self.starty = 1

    self.sleep = 0.0

    self.tileCache = {}
    for y = self.starty, self.height do
        self.tileCache[y] = {}
        for x = self.startx, self.width do
            self.tileCache[y][x] = false
        end
    end

    self.listOfRooms = {} -- index = roomid -> room object
    self.roomHistory = {} -- index = int -> room object

    self.stats = {}

    self.changes = {} -- experiment with changes stack
end

--- Read shape data from theme, and output room object.
-- @lfunction dungeonClass:_createRoom
function dungeonClass:_createRoom(data)
    if data.shape == 'square' then
        local w1, w2 = data.w[1], data.w[2] or data.w[1]
        local h1, h2 = data.h[1], data.h[2] or data.h[1]
        return roomClass():generateSquareRoom(random(w1, w2), random(h1, h2))
    elseif data.shape == 'circle' then
        local r1, r2 = data.r[1], data.r[2] or data.r[1]
        return roomClass():generateCircleRoom(random(r1, r2))
    elseif data.shape == 'hallway' then
        return roomClass():loadHallwayFromPrefab(data)
    elseif data.shape == 'cellauto' then
        local w1, w2 = data.w[1], data.w[2] or data.w[1]
        local h1, h2 = data.h[1], data.h[2] or data.h[1]
        return roomClass():generateCARoom(random(w1, w2), random(h1,h2))
    end
end

--- Generates a random pre-authored room.
-- @lfunction dungeonClass:generateRoom
function dungeonClass:_generateRandomRoom()
    local theme = self.theme
    local room

    local roomType = theme.types[math.random(1, #theme.types)]
    local roomWeight = roomType.weight
    local chance = random(1, 100)

    if chance > roomWeight then return self:_generateRandomRoom() end

    if roomType.shape == 'combine' then
        local roomA = self:_createRoom(roomType.combine[1])
        local roomB = self:_createRoom(roomType.combine[2])
        room = roomA:combineWith(roomB, roomType.offset[1], roomType.offset[2])
    else
        room = self:_createRoom(roomType)
    end

    room.id = _createUUID()
    room:assignRoomIds(room.id)

    return room
end


--- Sort room by (newest) room added.
local function sortByConnections(a,b)
    return #a.children < #b.children
end

--- Sort room by (oldest) room added.
local function sortByConnectionsCenter(a,b)
    return #a.children > #b.children
end

--- Returns a random room Object from dungeonClass.listOfRooms.
-- @lfunction dungeonClass:_getRandomRoom
function dungeonClass:_getRandomRoom(attempts, backStep) -- FIXME: Issue #12
    backStep = backStep or 0

    local sortType
    if self.theme.spanType ~= 'center' then
        sortType = sortByConnectionsCenter
    else
        sortType = sortByConnections
    end

    sort(self.roomHistory, sortType)

    return self.roomHistory[backStep + 1]
end

--- Retrieve a tile Object from tileCache.
-- @lfunction dungeonClass:_getTileByRoomID
function dungeonClass:_getTile(x, y)
    if x <= self.startx or x >= self.width then return false end
    if y <= self.starty or y >= self.height then return false end

    if self.tileCache[y] and self.tileCache[y][x] then
        if self.tileCache[y][x] ~= false then
            return self.tileCache[y][x]
        end
    end

    return false
end

--- "Throw" a generated room at the dungeon. If it is 
--a valid placement, place the room into the dungeon.
-- @lfunction dungeonClass:_throwRoomAtDungeon
function dungeonClass:_throwRoomAtDungeon(room, attempts, mod) -- FIXME: Issue #12
    attempts = attempts or 0

    local roomWidth, roomHeight = room:getRoomDimensions()
    local targetRoom = self:_getRandomRoom(attempts, mod)

    if not targetRoom then
        local newRoom = self:_generateRandomRoom()
        return self:_throwRoomAtDungeon(newRoom, 1)
    end

    -- Don't connect hallways to hallways
    if room.type == 'hallway' and targetRoom.type == 'hallway' then
        local newRoom = self:_generateRandomRoom()
        return self:_throwRoomAtDungeon(newRoom, attempts + 1)
    end

    -- Get starting positions from target room.
    local rx, ry = targetRoom:getPosition()
    local rw, rh = targetRoom.width, targetRoom.height

    -- Start scanning top left corner
    local startX = rx - roomWidth*2
    local startY = ry - roomHeight*2

    -- End scanning at room + newRoom width & height
    local endX = rx + roomWidth*2
    local endY = ry + roomHeight*2

    -- Scan
    for y = startY, endY do
        for x = startX, endX do
            if self:_isValidRoomPlacement(room, x, y, targetRoom) then
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
    local overlappingWallCount = 0
    local overlappingTiles = {}

    for ry = 1, #room.tiles do
        for rx = 1, #room.tiles[ry] do
            if (x) <= self.startx or (x + rx) >= self.width then return false end
            if (y) <= self.starty or (y + ry) >= self.height then return false end

            local roomTile = room.tiles[ry][rx]

            -- Retrieve tile data from room we're attaching too.
            local targetedTile = self:_getTile(x + rx, y + ry)


            -- Check where we would place our tile, and see what is there.
            if targetedTile then
                local targetRoomID = targetedTile.roomid

                -- These three returns prevent rooms being placed too closely to hallways.
                if roomTile:getType('wall') and targetedTile.type == 'ignore' then return false end
                if roomTile:getType('floor') and targetedTile.type == 'ignore' then return false end
                if roomTile:getType('ignore') and targetedTile.type ~= 'empty' then return false end

                -- Check for overlaps on rooms that are not target room.
                if roomTile:getType('floor') and not targetedTile:getType('empty') then return false end
                if roomTile:getType('wall') and targetedTile.type == 'wall' and targetRoomID ~= target.id then return false end
                if roomTile:getType('wall') and targetedTile.type == 'floor' then return false end

                -- Count overlapping walls of room we're attaching to.
                if roomTile:getType('wall') and targetedTile.type == 'wall' and targetRoomID == target.id then
                    overlappingWallCount = overlappingWallCount + 1
                    insert(overlappingTiles, {roomTile, targetedTile})
                end

                -- Count overlapping walls on doors to room we're attaching to.
                if roomTile:getType('wall') and targetedTile.type == 'door' and targetRoomID == target.id then
                    overlappingWallCount = overlappingWallCount + 1
                    insert(overlappingTiles, {roomTile, targetedTile})
                end

                -- Count door to walls overlap when attaching a hallway to a room.
                if roomTile:getType('door') and targetedTile.type == 'wall' and targetRoomID == target.id then
                    overlappingWallCount = overlappingWallCount + 1
                    insert(overlappingTiles, {roomTile, targetedTile})
                end
            end
        end
    end

    if overlappingWallCount >= 3 then
        insert(target.children, room)

        room.parent = target
        room._overlap = overlappingTiles

        return true
    else
        return false
    end
end

function dungeonClass:_updateTile(x, y, newTile)
    self.tileCache[y][x] = newTile
    insert(self.changes, newTile)
end

function dungeonClass:_checkForDoorPlacement(tile)
    local neighbors = self:_getTileNeighbors(tile)

    local up = neighbors[1] or false
    local down = neighbors[2] or false
    local left = neighbors[3] or false
    local right = neighbors[4] or false

    if #neighbors == 4 then
        if up and up.type == 'floor' then
            if down and down.type == 'floor' then
                return true
            end
        end

        if left and left.type == 'floor' then
            if right and right.type == 'floor' then
                return true
            end
        end
    end

    return false
end

function dungeonClass:_resolveOverlaps(room)
    love.timer.sleep(self.sleep)

    if room.id == 'start' then return end

    -- List of room._overlap index's for good doors.
    local doorCandidates = {}

    -- Add good candidates to list
    for key, data in pairs(room._overlap) do
        local tile = data[1]
        local isGoodDoor = self:_checkForDoorPlacement(tile)

        if isGoodDoor then
            insert(doorCandidates, key)
        end
    end

    -- Choose a random door from list of candidates
    local select = doorCandidates[math.random(1, #doorCandidates)]

    local hasDoor = false
    for n = 1, #room._overlap do
        local target = self.listOfRooms[room._overlap[n][2].roomid]
        local parent = self.listOfRooms[room._overlap[n][1].roomid]

        if target.type == 'hallway' then hasDoor = true end
        if parent and parent.type == 'hallway' then hasDoor = true end
    end

    if not hasDoor then
        for n = 1, #room._overlap do
            local t1, t2 = room._overlap[n][1], room._overlap[n][2]

            if n == select then
                t1.type = 'door'
                self:_resolveCornerDoors(t1)
            else
                t1.type = 'wall'
            end

            insert(self.changes, t1)
        end
    else -- Resolve overlaps for rooms that have doors differently.
        for n = 1, #room._overlap do
            local t1, t2 = room._overlap[n][1], room._overlap[n][2]

            if t2.type == 'door' then
                t1.type = 'door'
                self:_resolveCornerDoors(t1)
                insert(self.changes, t1)
            elseif t1.type == 'door' then
                t1.type = 'door'
                self:_resolveCornerDoors(t1)
                insert(self.changes, t1)
            else
                t1.type = 'wall'
                insert(self.changes, t1)
            end
        end
    end
end

--- Add a tile at location, removes any tileCache reference at index
function dungeonClass:_addTile(x, y, tile)
    self.tileCache[y][x] = tile
    insert(self.changes, tile)
end

--- Place room into dungeon at (x,y), assign the room a UUID.
-- @lfunction dungeonClass:_addRoom
function dungeonClass:_addRoom(roomToAdd, x, y, customID)
    local addedRoom = roomToAdd:setPosition(x, y)
    addedRoom.id = customID or _createUUID()
    addedRoom.type = roomToAdd.type
    addedRoom:assignRoomIds(addedRoom.id)

    local tileCount = 0
    local height = #addedRoom.tiles
    local width = 0

    for ry = 1, #addedRoom.tiles do
        for rx = 1, #addedRoom.tiles[ry] do
            width = #addedRoom.tiles[ry]

            if not addedRoom.tiles[ry][rx]:getType('empty') then
                self:_updateTile(rx + x, ry + y, addedRoom.tiles[ry][rx])

                tileCount = tileCount + 1
            end
        end
    end

    -- Scrape width & height data from copy
    addedRoom.width = width
    addedRoom.height = height

    -- Add room to list of rooms in dungeon
    self.listOfRooms[addedRoom.id] = addedRoom

    -- Cannot add directly due to roomHistory containing nils.
    insert(self.roomHistory, addedRoom)

    love.thread.getChannel('stats'):push({roomsLoaded = self:getNumberOfRooms(), tilesCreated = tileCount})
    love.thread.getChannel('console'):push('Added room: ' .. addedRoom.id .. ' at position: (' .. addedRoom.x .. ',' .. addedRoom.y .. ') with type: ' .. addedRoom.type)
end

--- Serialize the dungeonClass.changes table, and push changes.
-- All serialization is pushed on tile-by-tile basis.
function dungeonClass:serializeChanges()
    local data = {}

    local tile
    for _, change in pairs(self.changes) do
        tile = change

        tile:serialize()

        insert(data, tile.serializeData)
    end

    self.changes = {}

    return bitser.dumps(data)
end

--- Swaps floor tiles to wall tiles adjacent to corner doors.
-- Needed for circle & cellular automata rooms.
function dungeonClass:_resolveCornerDoors(tile)
    local neighbors = self:_getTileNeighbors(tile)

    local up = neighbors[1] or false
    local down = neighbors[2] or false
    local left = neighbors[3] or false
    local right = neighbors[4] or false

    -- Add walls to north/south doors.
    if #neighbors == 4 then
        if up and up.type == 'floor' then
            if down and down.type == 'floor' then
                if left and left.type == 'floor' then
                    left.type = 'wall'
                    self:_updateTile(left.wx, left.wy, left)
                end

                if right and right.type == 'floor' then
                    right.type = 'wall'
                    self:_updateTile(right.wx, right.wy, right)
                end
            end
        end

        if left and left.type == 'floor' then
            if right and right.type == 'floor' then
                if up and up.type == 'floor' then
                    up.type = 'wall'
                    self:_updateTile(up.wx, up.wy, up)
                end

                if down and down.type == 'floor' then
                    down.type = 'wall'
                    self:_updateTile(down.wx, down.wy, down)
                end
            end
        end
    end
end

--- A function to return a list of tiles for Dijkstra mapping.
function dungeonClass:_getAllTilesAsNodes()
    local grid = {}

    for y = 1, #self.tileCache do
        for x = 1, #self.tileCache[y] do
            local tile = self:_getTile(x, y)

            -- Only process tiles that are considered "floors"
            if tile and tile ~= nil and tile.type ~= 'ignore' and tile.type ~= 'empty' then
                if tile.type ~= 'edge' and tile.type ~= 'chasm' then
                    insert(grid, tile)
                end
            end
        end
    end

    return grid
end

--- Return an array of tiles neighbors, unsorted.
-- @lfunction dungeonClass:_getTileNeighbors
function dungeonClass:_getTileNeighbors(node)
    local neighbors = {}

    local up = self:_getTile(node.wx, node.wy - 1)
    local down = self:_getTile(node.wx, node.wy + 1)
    local left = self:_getTile(node.wx - 1, node.wy)
    local right = self:_getTile(node.wx + 1, node.wy)

    if up and up.type ~= 'empty' and up.type ~= 'edge' and up.type ~= 'chasm' then insert(neighbors, up) end
    if down and down.type ~= 'empty' and down.type ~= 'edge' and down.type ~= 'chasm' then insert(neighbors, down) end
    if left and left.type ~= 'empty' and left.type ~= 'edge' and left.type ~= 'chasm' then insert(neighbors, left) end
    if right and right.type ~= 'empty' and right.type ~= 'edge' and right.type ~= 'chasm' then insert(neighbors, right) end

    return neighbors
end

--- Returns the cost to move to specified node
-- @lfunction dungeonClass:_getMapValue
function dungeonClass:_getMapValue(node)
    if node.type == 'wall' then
        return huge
    elseif node.type == 'door' then
        return 10
    else
        return 1
    end
end

--- Uses the Manhattan Distance formula for returning cost.
-- Used in Dijkstra mapping.
-- @lfunction dungeonClass:_manhattanDistance
function dungeonClass:_manhattanDistance(nodeA, nodeB, costOfMove)
    local dx, dy = nodeA.wx - nodeB.wx, nodeA.wy - nodeB.wy
    return (costOfMove or 1) * (abs(dx) + abs(dy))
end

--- Implements Dijkstra path algorithm.
-- @lfunction dungeonClass:_dijkstra
function dungeonClass:_dijkstra(source)
    local listOfNodes = self:_getAllTilesAsNodes()

    for _, node in pairs(listOfNodes) do
        node.distance = huge
        node.previous = nil
    end

    source.distance = 0
    sort(listOfNodes, function(a,b) return a.distance < b.distance end)

    while (#listOfNodes > 0) do
        local currentNode = listOfNodes[1]
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

--- (Deprecated) basic flood fill algorithm. Not in use currently.
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
        end
    end

    if down and down.getType then
        if not down:getType('wall') and not down._analyzed then
            self:_floodFillTile(down, list)
        end
    end

    if left and left.getType then
        if not left:getType('wall') and not left._analyzed then
            self:_floodFillTile(left, list)
        end
    end

    if right and right.getType then
        if not right:getType('wall') and not right._analyzed then
            self:_floodFillTile(right, list)
        end
    end

    start:setType('fill')

    return list
end

--- Returns a random floor tile from the "starting" room.
-- @lfunction _getTileFromStart
local function _getTileFromStart(dungeon)
    local room = dungeon.listOfRooms['start']

    for y = 1, #room.tiles do
        for x = 1, #room.tiles[y] do
            if room.tiles[y][x].type == 'floor' then
                if random(1,2) == 2 then
                    return room.tiles[y][x]
                end
            end
        end
    end
end

--- Analyzes the map by visualizing a Dijkstra node map.
-- @function dungeonClass:analyzeMapConnectivity
function dungeonClass:analyzeMapConnectivity()
    local start = _getTileFromStart(self)

    self:_dijkstra(start)

    local listOfNodes = {}
    for _, room in pairs(self.listOfRooms) do
        for y = 1, #room.tiles do
            for x = 1, #room.tiles[y] do
                local tile = room.tiles[y][x]

                if tile and tile.distance and not tile:getType('wall') then
                    insert(listOfNodes, tile)
                end
            end
        end
    end

    sort(listOfNodes, function(a,b) return a.distance < b.distance end)
    return listOfNodes
end

--- Returns an int value of # of rooms.
-- Since rooms are indexed by ID, need to re-iterate every time.
-- @function dungeonClass:getNumberOfRooms
function dungeonClass:getNumberOfRooms()
    local count = 0

    for _, _ in pairs(self.listOfRooms) do
        count = count + 1
    end

    return count
end

--- Deletes a room by removing tiles individually.
-- Removes tile index from dungeonClass.tileCache
-- @function dungeonClass:deleteRoom
function dungeonClass:deleteRoom(room)
    local doorCount = 0
    local tileCount = 0

    for y = 1, #room.tiles do
        for x = 1, #room.tiles[y] do
            local wx, wy = room.tiles[y][x].wx, room.tiles[y][x].wy

            if room.tiles[y][x].type == 'door' then doorCount = doorCount + 1 end
            if room.tiles[y][x].type ~= 'empty' then tileCount = tileCount + 1 end
            self.tileCache[wy][wx] = false

            insert(self.changes, room.tiles[y][x])

            room.tiles[y][x] = nil
        end
    end

    self.listOfRooms[room.id] = nil
    room:delete()
end

--- Iterate over hallways, delete those without any children.
-- No children indicate the hallway is a deadend.
-- @function dungeonClass:removeBadHallways
function dungeonClass:removeBadHallways(room)
    love.timer.sleep(self.sleep)

    if room.type == 'hallway' then
        if #room.children == 0 and room.id ~= 'start' then
            printc('Deleting bad hallway at (' .. room.x .. ',' .. room.y .. ') room id: ' .. room.id)
            self:deleteRoom(room)
            room.parent._dirty = true
        end
    end

    love.thread.getChannel('stats'):push({roomsDeleted = (self.maxDensity - self:getNumberOfRooms())})
end

function dungeonClass:_isValidChasmPlacement(room, x, y)
    x = floor(x)
    y = floor(y)

    local overlappingWreathCount = 0
    local overlappingFillCount = 0

    for ry = 1, #room.tiles do
        for rx = 1, #room.tiles[ry] do
            if (x) <= self.startx or (x + rx) >= self.width then return false end
            if (y) <= self.starty or (y + ry) >= self.width then return false end

            local targetTile = self:_getTile(x + rx, y + ry)
            local curTile = room.tiles[ry][rx]

            if targetTile and curTile then
                if curTile.type == 'edge' and targetTile.type == 'wall' then
                    overlappingWreathCount = overlappingWreathCount + 1
                end

                if curTile.type == 'chasm' and targetTile.type ~= 'empty' then
                    overlappingFillCount = overlappingFillCount + 1
                end
            end
        end
    end
    
    if overlappingWreathCount >= 8 and overlappingFillCount < 8 then
        return true
    end

    return false
end

local abc = math.random(1,1)

function dungeonClass:generateChasm()
    local width = math.random(10, 25)
    local height = math.random(10, 25)

    local listOfPositions = {}
    for x = 1, self.width - width do
        for y = 1, self.height - height do
            insert(listOfPositions, {x = x, y = y})
        end
    end


    local chasm = roomClass():generateChasm(width, height)
    chasm.type = 'chasm' -- TODO: Issue #15 None of the rooms are instantiating with proper types.

    for _ = 1, #listOfPositions do
        local select = listOfPositions[random(1, #listOfPositions)]


        if self:_isValidChasmPlacement(chasm, select.x, select.y) then
            self:_addRoom(chasm, select.x, select.y)
            return
        end
    end
end

function dungeonClass:wallInChasms()
    for _, room in pairs(self.listOfRooms) do
        if room.type == 'chasm' then
            room:applyWallsToChasm(self)
        end
    end
end

--- Starts dungeon generation.
-- @usage Dungeon():buildDungeon()
function dungeonClass:buildDungeon()
    if self.first then
        local startingRoom = self:_generateRandomRoom()

        -- Don't generate a hallway to start.
        if startingRoom.type == 'hallway' then return self:buildDungeon() end

        self:_addRoom(startingRoom, 55, 35, 'start')

        self.roomHistory[1] = startingRoom
        self.first = false

        return -- Exit first placement.
    end

    local room = self:_generateRandomRoom()
    self:_throwRoomAtDungeon(room)


    -- Intentionally slow down recursion
    love.timer.sleep(self.sleep)
end

return dungeonClass


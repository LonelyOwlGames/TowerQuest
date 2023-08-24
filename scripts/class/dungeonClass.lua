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
local bitser = require 'libraries.bitser'
local dungeonClass = Class{}

local function _createUUID()
    local uuid = ''
    local chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
    for i = 1, 30 do
        local l = math.random(1, #chars)
        uuid = uuid .. string.sub(chars, l, l)
    end
    return uuid
end

--- Initialize new tile instance
function dungeonClass:init(width, height)
    self.id = 1
    self.numberOfRooms = 0

    self.width = math.floor(width)
    self.height = math.floor(height)
    self.maxDensity = 25 -- % to fill. (max ~70-80%)

    self.sleep = 0.3


    self.tileCache = {}
    for y = 1, self.height do
        self.tileCache[y] = {}
        for x = 1, self.width do
            self.tileCache[y][x] = false
        end
    end

    -- Create map buffer of empty tiles.
    -- self.tiles = roomClass():createRoomBuffer(self.width, self.height, 'empty')

    self.listOfRooms = {}
end

--- Generate a randomly sized room.
-- Some parameters control the randomness, rendering
-- it more of an "authored" procedural generation.
-- @treturn object room
function dungeonClass:generateRandomRoom()
    local select = math.random(1,4) -- TODO: seeing some overlap on higher r's
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

    return r
end

--- Returns a ratio of floor tiles to wall tiles
-- Used to determine how dense the dungeon is during
-- dungeon generation.
function dungeonClass:getDensity()
    local numberOfRooms = self.numberOfRooms
    return numberOfRooms
end

--- Small accessor function.
-- simply returns a random room from dungeons listOfRooms
function dungeonClass:getRandomRoom()
    -- local r = self.listOfRooms[math.min(#self.listOfRooms, #self.listOfRooms - hops)]
    local rooms = {}
    for id, room in pairs(self.listOfRooms) do
        table.insert(rooms, room)
    end

    -- return rooms[math.random(1, #rooms)]
    return rooms[#rooms]
    -- return rooms[1]
end

function dungeonClass:getRoomTile(x, y, targetRoomID)
    local targetRoom = self.listOfRooms[targetRoomID]
    -- for _, room in pairs(self.listOfRooms) do
    --     if room.id == targetRoomID then
    --         targetRoom = room
    --     end
    -- end

    if targetRoom then
        for ty = 1, #targetRoom.tiles do
            for tx = 1, #targetRoom.tiles[ty] do
                local wx, wy = targetRoom.tiles[ty][tx]:getWorldPosition()

                if wx == x and wy == y then
                    return targetRoom.tiles[ty][tx]
                end
            end
        end
    end

    return false
end

-- If target room is given, then only search target rooms tiles
function dungeonClass:getTile(wx, wy, targetRoom)
    for _, room in pairs(self.listOfRooms) do
       for y = 1, #room.tiles do
            for x = 1, #room.tiles[y] do
                local tx, ty  = room.tiles[y][x]:getWorldPosition()

                if wx == tx and wy == ty then
                    return room.tiles[y][x]
                end
            end
        end
    end
end

--- "Throw" the generated room at the dungeon
-- We essentially throw the room at the dungeon until
-- it sticks. If it sticks, we copy it into the dungeon.
-- @tparam object room
function dungeonClass:throwRoomAtDungeon(room)
    local roomWidth = room:getRoomWidth()
    local roomHeight = room:getRoomHeight()

    local targetRoom = self:getRandomRoom()
    local rx, ry = targetRoom:getPositionInWorld()
    local rw, rh = targetRoom:getRoomDimensions()

    -- Start scanning top left corner
    local startX = rx - roomWidth
    local startY = ry - roomHeight

    local endX = rx + rw + roomWidth
    local endY = ry + rh + roomHeight

    endX = endX*3
    endY = endY*3

    -- When a room is selected, try all possible sides before discarding
    for y = startY, endY do
        for x = startX, endX do
            if self:isValidRoomPlacement(room, x, y, targetRoom) then
                self:addRoom(room, x, y)
                return true
            end
        end
    end

    return false
end

--- Does supplied room fit into the dungeon at x,y.
-- Checks whether the room parameter will fit into
-- the current dungeon based on its tiles.
-- @tparam table room
-- @param x
-- @param y
-- @param target
-- @treturn boolean success
function dungeonClass:isValidRoomPlacement(room, x, y, target)
    x = math.floor(x)
    y = math.floor(y)

    local overlappingWallCount = 0
    local overlappingFloorCount = 0
    local overlappingEmptyCount = 0
    local listOfConnectedRoomIDs = {}
    local listOfConnectedWalls = {}

    local targetRoomID = target.id

    for ry = 1, #room.tiles do
        for rx = 1, #room.tiles[ry] do

            -- Return false if any single tile it outside map bounds
            if (x + rx) <= 0 or (x + rx) >= self.width then return false end
            if (y + ry) <= 0 or (y + ry) >= self.height then return false end

            -- local roomTile = room.tiles[ry][rx]
            -- local targetRoomTile = target:getTileByWorld(rx + x, ry + y)
            -- local targetWorldTile = self.tileCache[y + ry][x + rx]

            local roomTile = room.tiles[ry][rx]
            local targetedTileRoomID = self.tileCache[y + ry][x + rx] -- <- returns roomid now 

            local targetedTile = self:getRoomTile(x + rx, y + ry, targetedTileRoomID)

            if roomTile:getType('wall') then
                if targetedTile and targetedTile:getType('wall') then
                    -- listOfConnectedRoomIDs[targetedTileRoomID] = targetedTile
                    table.insert(listOfConnectedWalls, {roomTile, targetedTile})
                    overlappingWallCount = overlappingWallCount + 1
                end
            end

            if roomTile:getType('floor') then
                if targetedTile then
                    if targetedTile:getType('floor') or targetedTile:getType('wall') then
                        overlappingFloorCount = overlappingFloorCount + 1
                    end
                end
            end


        end
    end

    if overlappingWallCount > 0 and overlappingFloorCount == 0 then
        -- for id, tile in pairs(listOfConnectedRoomIDs) do
        --     if tile then
        --         room.connectedRooms[id] = tile 
        --     end
        -- end
        room.connectedWallTiles = listOfConnectedWalls

        return true
    else
        return false
    end
end

-- check if room is overlapping other rooms at x, y
function dungeonClass:isOverlappingRoom(room, x, y, excludeID)
    for ry = 1, #room.tiles do
        for rx = 1, #room.tiles[ry] do
            local tile = room.tiles[ry][rx]
            local targetTile = self:getTile(x + rx, y + ry)

            if not tile:getType('empty') then
                if targetTile and not targetTile:getType('empty') then
                    if targetTile.roomId == excludeID then
                        -- do nothing
                    else
                        return true
                    end
                end
            end
        end
    end

    return false
end


function dungeonClass:addRoom(roomToAdd, x, y)
    -- Set's all tiles world position to new position
    local addedRoom = roomToAdd:setPosition(x, y)
    addedRoom.id = _createUUID()

    -- Add room tiles to dungoen tileCache for quicker generation
    for ry = 1, #roomToAdd.tiles do
        for rx = 1, #roomToAdd.tiles[ry] do
            self.tileCache[ry + y][rx + x] = addedRoom.id
        end
    end



    -- Add room to list of rooms in dungeon
    self.listOfRooms[addedRoom.id] = addedRoom

    for rid, room in pairs(self.listOfRooms) do
        -- print('key = [' .. rid .. ']. room.id = ' .. room.id ..' .. (x,y) = ' .. room.x, room.y)
    end
end

function dungeonClass:serialize(instance)
   local data = {}
    for _, room in pairs(self.listOfRooms) do
        local roomData = room:serialize() -- Returns room.serializeData containing tile.serializeData's
        data[room.id] = roomData
    end

    -- Let's look at serialize data... lol
    -- for _,b in pairs(data) do
    --     for _,d in pairs(b) do
    --         if type(d) == 'table' then
    --             for _,f in pairs(d) do
    --                 for g,h in pairs(f) do
    --                     print(g,h)
    --                 end
    --             end
    --         end
    --     end
    -- end

    local binary_data = bitser.dumps(data)
    return binary_data
end

function dungeonClass:getRoomByID(id)
    return self.listOfRooms[id]
end

function dungeonClass:connectRoomsTogether()
    for _, room in pairs(self.listOfRooms) do
        local id = room.id
        
    end
end

function dungeonClass:checkForDoorPlacement(room)
    local connectedRoomIDs = {} 

    if not room.connectedWallTiles then return end

    -- Walltile is the overlapping wall tile
    -- Need to resolve conflicts here
    for _, conflictingTiles in pairs(room.connectedWallTiles) do
        local wall1 = conflictingTiles[1]
        local wall2 = conflictingTiles[2]

        wall1:setType('door')
        wall2:setType('empty')

        -- local wx, wy = wallTile:getWorldPosition()
        -- local tile = room:getTileByWorld(wx, wy)
        --
        -- tile:setType('empty')
    end
end

function dungeonClass:doorTest(index)
    local changes = {}

    love.timer.sleep(self.sleep/2)

    -- for _, room in pairs(self.listOfRooms) do
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
        for n = 2, #doorsInRoom do
            doorsInRoom[n]:setType('wall')
            changes[doorsInRoom[n].id] = true
            -- table.insert(changes, doorsInRoom[n].id)
        end
    return changes
end

function dungeonClass:test()
    for _, room in pairs(self.listOfRooms) do
        for y = 1, #room.tiles do
            for x = 1, #room.tiles[y] do
                room.tiles[y][x]:setType('wall')
            end
        end
    end
end

--- Builder method for dungeon generation.
-- recursively creates rooms, and adds them to
-- the current dungeon.
local first = true
function dungeonClass:buildDungeon()
    if first then
        local startingRoom = self:generateRandomRoom()
        self:addRoom(startingRoom, 1, 1)
        first = false
    end

    local room = self:generateRandomRoom()
    self:throwRoomAtDungeon(room)

    -- update number of rooms
    self.numberOfRooms = 0
    for _, room in pairs(self.listOfRooms) do
        self.numberOfRooms = self.numberOfRooms + 1
    end

    -- self:connectRoomsTogether()

    -- Place potential doors on new room
    self:checkForDoorPlacement(room)

    -- Remove doors with 3 floor tiles in dungeon


    love.timer.sleep(self.sleep)


    return self
end

return dungeonClass


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


local id = 0

--- Initialize new tile instance
function dungeonClass:init(width, height)
    id = id + 1
    self.id = id

    self.loadPercent = 0

    self.width = width or 50
    self.height = height or 50
    self.maxDensity = 2.8 -- % to fill. (max ~70-80%)

    -- Create map buffer of empty tiles.
    -- self.tiles = roomClass():createRoomBuffer(self.width, self.height, 'empty')

    self.listOfRooms = {}
end

--- Generate a randomly sized room.
-- Some parameters control the randomness, rendering
-- it more of an "authored" procedural generation.
-- @treturn object room
function dungeonClass:generateRandomRoom()
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


    return r
end

--- Returns a ratio of floor tiles to wall tiles
-- Used to determine how dense the dungeon is during
-- dungeon generation.
function dungeonClass:getDensity()
    local fullCells = 0

    for _, room in pairs(self.listOfRooms) do
        for y = 1, #room.tiles do
            for x = 1, #room.tiles[y] do
                if not room.tiles[y][x]:getType('empty') then
                    fullCells = fullCells + 1
                end
            end
        end
    end

    return fullCells/(self.width * self.height)
end

--- Small accessor function.
-- simply returns a random room from dungeons listOfRooms
function dungeonClass:getRandomRoom()
    local hops = math.random(0,4)
    -- local r = self.listOfRooms[math.random(1, #self.listOfRooms)]
    local r = self.listOfRooms[math.min(#self.listOfRooms, #self.listOfRooms - hops)]
    return r
end

function dungeonClass:getRoomTile(x, y, targetRoomID)
    local targetRoom

    for _, room in pairs(self.listOfRooms) do
        if room.id == targetRoomID then
            targetRoom = room
        end
    end

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

endX = endX*2
endY = endY*2

    -- When a room is selected, try all possible sides before discarding
    for x = startX, endX do
        for y = startY, endY do
            if self:isValidRoomPlacement(room, x, y, targetRoom.id) then
                    room:addConnectedRoom(targetRoom.id)
                    self:addRoom(room, x, y)
                    return true
                -- return true
            end
        end
    end

    -- Discard room
    -- return false
    return false
end

--- Does supplied room fit into the dungeon at x,y.
-- Checks whether the room parameter will fit into
-- the current dungeon based on its tiles.
-- @tparam table room
-- @param x
-- @param y
-- @treturn boolean success
function dungeonClass:isValidRoomPlacement(room, x, y, targetRoomID)
    x = math.floor(x)
    y = math.floor(y)

    local overlappingWallCount = 0
    local overlappingFloorCount = 0

    for ry = 1, #room.tiles do
        for rx = 1, #room.tiles[ry] do

            -- Return false if any single tile it outside map bounds
            -- if (x + rx) <= 0 or (x + rx) >= self.width then return false end
            -- if (y + ry) <= 0 or (y + ry) >= self.height then return false end

            -- local targetTile = self.tiles[y + ry][x + rx]
            -- local targetTile = self:getTile(x + rx, y + ry)
            local targetTile = self:getRoomTile(x + rx, y + ry, targetRoomID)
            local otherTile = self:getTile(x + rx, y + ry)
            local roomTile = room.tiles[ry][rx]

            -- If there is another room tile at location that matches targetRoomID
            if targetTile then 
                if roomTile:getType('wall') then
                    if targetTile:getType('wall') then
                        overlappingWallCount = overlappingWallCount + 1
                    end
                end

                if roomTile:getType('floor') then
                    if targetTile:getType('floor') or targetTile:getType('wall') then
                        overlappingFloorCount = overlappingFloorCount + 1
                    end
                end
            else
                if otherTile then
                    if roomTile:getType('wall') and otherTile:getType('wall') then
                        -- its ok :)
                    else
                        -- NOT OKAY
                        return false
                    end
                end
            end

            -- Check if any tiles at this position overlap other rooms

            
        end
    end

    if overlappingWallCount > 0 and overlappingFloorCount == 0 then
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

function dungeonClass:addRoom(room, x, y)
    -- Set's all tiles world position to new position
    room:setPosition(x, y)

    -- Add room to list of rooms in dungeon
    table.insert(self.listOfRooms, room)
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
    for key, room in pairs(self.listOfRooms) do
        if room.id == id then
            return self.listOfRooms[key]
        end
    end
end

function dungeonClass:connectRoomsTogether()
    for _, room in pairs(self.listOfRooms) do
        local id = room.id
        
    end
end

function dungeonClass:checkForDoorPlacement(room)
    for _, room in pairs(self.listOfRooms) do
        -- print('roomid: ' .. room.id .. ' has ' .. #room.connectedRooms .. ' connected rooms')
    end
    for y = 1, #room.tiles do
        for x = 1, #room.tiles do
            local tile = room.tiles[y][x]

            for _, id in pairs(room.connectedRooms) do
            end

            if tile and tile:getType('wall') then

            end
            -- if tile:getProperty('isOverlappingWall') then
                -- tile:setType('door')
            -- end
        end
    end
end

--- Builder method for dungeon generation.
-- recursively creates rooms, and adds them to
-- the current dungeon.
local steps = 0
function dungeonClass:buildDungeon()
    if #self.listOfRooms < 1 then
        local startingRoom = self:generateRandomRoom()
        self:addRoom(startingRoom, 10, 10)
    end

    local room = self:generateRandomRoom()
    self:throwRoomAtDungeon(room)

    self:connectRoomsTogether()

    self:checkForDoorPlacement(room)

    love.timer.sleep(0.1)

    return self
end

return dungeonClass


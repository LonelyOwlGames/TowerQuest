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
local CA = require 'scripts.class.cellular'
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
-- @treturn object room reference
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

function dungeonClass:getRandomWall()
    local walls = {}

    for y = 1, #self.tiles do
        for x = 1, #self.tiles[y] do
            if self.tiles[y][x]:getType('wall') then
                table.insert(walls, self.tiles[y][x])
            end
        end
    end

    return walls[math.random(1, #walls)]
end


function dungeonClass:getRandomRoom()
    return self.listOfRooms[math.random(1, #self.listOfRooms)]
end

--- "Throw" the generated room at the dungeon
-- We essentially throw the room at the dungeon until
-- it sticks. If it sticks, we copy it into the dungeon.
-- @tparam object room
function dungeonClass:throwRoomAtDungeon(room)
    local roomWidth = room:getRoomWidth()
    local roomHeight = room:getRoomHeight()

    local dungeonWidth = self.width
    local dungeonHeight = self.height

    local xBoundary = dungeonWidth - roomWidth - 1
    local yBoundary = dungeonHeight - roomHeight - 1

    local targetRoom = self:getRandomRoom()
    local rx, ry = targetRoom:getPositionInWorld()
    local rw, rh = targetRoom:getRoomDimensions()

    -- Start scanning top left corner
    local startX = rx - roomWidth
    local startY = ry - roomHeight

    local endX = rx + rw
    local endY = ry + rh

    -- print(targetRoom.id, startX, startY, endX, endY)
    for y = startY, endY do
        for x = startX, endX do
            local ox = x - roomWidth - 1
            local oy = y - roomHeight - 1

            if self:isValidRoomPlacement(room, x, y) then
                self:copyRoomIntoDungeon(room, x, y)
                return true
            end
        end
    end


    return false
end
--- Returns a ratio of floor tiles to wall tiles
-- Used to determine how dense the dungeon is during
-- dungeon generation.
function dungeonClass:getFullToEmptyRatio()
    local fullCells = 0
    local emptyCells = 0

    for y = 1, #self.tiles do
        for x = 1, #self.tiles[y] do
            if self.tiles[y][x]:getType('black') then
                emptyCells = emptyCells + 1
            else
                fullCells = fullCells + 1
            end
        end
    end

    return fullCells/emptyCells
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
            if not self.tiles[y + ry] then error('Invalid room placement: y-axis .. ' .. y + ry) end
            if not self.tiles[y + ry][x + rx] then error('Invalid room placement: x-axis .. ' .. x + rx) end

            local targetTile = self.tiles[y + ry][x + rx]
            local roomTile = room.tiles[ry][rx]

            -- Don't copy over empty 'buffer' tiles
            if not roomTile:getType('empty') then
                targetTile:setPosition(x + rx, y + ry)
                targetTile:setType(roomTile:getType())
            end


            -- Because of how references work in lua
            -- I need to retroactively set positions of
            -- room tiles to match their new position.
            -- Which fucking sucks.
            roomTile:setPosition(x + rx, y + ry)
            room.dungeon = self -- Tell room it's inside a dungeon
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
local steps = 0
function dungeonClass:buildDungeon()
    if #self.listOfRooms < 1 then
        local startingRoom = self:generateRandomRoom()
        self:copyRoomIntoDungeon(startingRoom, 20, 20)
    end

    local function _step()
        local room = self:generateRandomRoom()
        self:throwRoomAtDungeon(room)
    end

    for i = 1, 20 do
        _step()
    end

    local density = 8

    -- while (#self.listOfRooms <= math.min(density, 25)) do
    --     failsafe = failsafe + 1
    --     local room = self:generateRandomRoom()
    --     local success = self:throwRoomAtDungeon(room)
    --
    --     if failsafe > 100 then print('broke failsafe') break end
    --     if not success then
    --         if #self.listOfRooms <= density then
    --             -- error('Throwing Dungeon ran out of Tries before Density')
    --             self:init() -- Reset local tiles
    --             self:buildDungeon()
    --             break
    --         else
    --             break -- good room
    --         end
    --     end
    --
    -- end


    return self
end

return dungeonClass


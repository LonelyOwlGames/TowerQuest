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
local lume = require 'libraries.lume'
local Timer = require 'libraries.hump.timer'
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
    self.maxDensity = 0.5 -- % to fill. (max ~70-80%)

    -- Create map buffer of empty tiles.
    self.tiles = roomClass():createRoomBuffer(self.width, self.height, 'black')

    self.tileCache = {}
    for y = 1, self.height do
        self.tileCache[y] = {}
        for x = 1, self.width do
            self.tileCache[y][x] = {}
        end
    end

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


function dungeonClass:getRandomRoom()
    return self.listOfRooms[math.random(1, #self.listOfRooms)]
end

function dungeonClass:getTile(wx, wy)
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
    local startX = rx - roomWidth - 5
    local startY = ry - roomHeight - 5

    local endX = rx + rw + 5
    local endY = ry + rh + 5


    for x = startX, endX do
        for y = startY, endY do

            -- if x == 8 and y == 0 then 
            --     if self:isValidRoomPlacement(room, x, y) then
            --         self:addRoom(room, x, y)
            --     end
            --     return
            -- end
            
            if self:isValidRoomPlacement(room, x, y) then
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
-- @treturn boolean success
function dungeonClass:isValidRoomPlacement(room, x, y)
    x = math.floor(x)
    y = math.floor(y)

    local overlappingWallCount = 0
    local overlappingFloorCount = 0

    for ry = 1, #room.tiles do
        for rx = 1, #room.tiles[ry] do

            -- Return false if any single tile it outside map bounds
            if (x + rx) <= 0 or (x + rx) >= self.width then return false end
            if (y + ry) <= 0 or (y + ry) >= self.height then return false end

            -- local targetTile = self.tiles[y + ry][x + rx]
            local targetTile = self:getTile(x + rx, y + ry)
            local roomTile = room.tiles[ry][rx]

            -- If there is another room tile at location
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
            end -- If the tile is empty
        end
    end

    if overlappingWallCount > 0 and overlappingFloorCount == 0 then
        return true
    else
        return false
    end
end

function dungeonClass:addRoom(room, x, y)
    -- Set's all tiles world position to new position
    room:setPosition(x, y)

    table.insert(self.listOfRooms, room)

    -- print('last: ' .. x .. ' ' .. y)

    for i = 1, #room.tiles do
        for j = 1, #room.tiles[i] do
            if not room.tiles[i][j]:getType('empty') then
                --FIXME: Remove after done debugging
                -- if not self.tileCache[y + i] then return end
                -- if not self.tileCache[y + i][x + j] then return end
                self.tileCache[y + i][x + j] = room
            end
        end
    end
end



--- Copy room tiles onto the map.
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

                -- targetTile:setPosition(x + rx, y + ry)
                -- targetTile:setType(roomTile:getType())
                -- targetTile:setDirty()
            end


            -- Because of how references work in lua
            -- I need to retroactively set positions of
            -- room tiles to match their new position.
            -- Which fucking sucks.
            roomTile:setPosition(x + rx, y + ry)
            roomTile:setProperty('dungeon', self)
        end
    end

    room.dungeon = self

    -- Since we manipulated tile positions, mark room as dirty
    room:setDirty()

    table.insert(self.listOfRooms, room)
end

function dungeonClass:serialize(instance)
    -- local grid = {}

    -- for _, room in pairs(self.listOfRooms) do
    --     for y = 1, #room.tiles do
    --         for x = 1, #room.tiles[y] do
    --             table.insert(grid, room.tiles[y][x]:serialize())
    --         end
    --     end
    -- end
    --
    --
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

function dungeonClass:update(dt)
    print('d')
end

function dungeonClass:addRoomIntoDungeon()
    -- local density = self:getDensity()

    -- if density < self.maxDensity then
        local room = self:generateRandomRoom()
        self:throwRoomAtDungeon(room)
    -- end

    self.loadPercent = self:getDensity()

    return self:getLoadPercent()
end

--- Builder method for dungeon generation.
-- recursively creates rooms, and adds them to
-- the current dungeon.
-- @treturn table mapData A 2D array (table) full of tiles.
local steps = 0
function dungeonClass:buildDungeon()
    if #self.listOfRooms < 1 then
        local startingRoom = self:generateRandomRoom()
        self:addRoom(startingRoom, 0, 0)
    end

    self:addRoomIntoDungeon()



    -- for i = 1, 10 do
    --     _step()
    --     self:addLoadPercent(10)
    --     love.timer.sleep(0.1)
    -- end
    --
    -- for _, room in pairs(self.listOfRooms) do
    --     room:addDoorsToRoom()
    -- end

    -- for y = 1, #self.tiles do
        -- for x = 1, #self.tiles[y] do
            -- self.tiles[y][x]:setType('door')
        -- end
    -- end

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

function dungeonClass:addLoadPercent(percent)
    self.loadPercent = self.loadPercent + percent
end

function dungeonClass:getLoadPercent()
    return self.loadPercent
end

return dungeonClass


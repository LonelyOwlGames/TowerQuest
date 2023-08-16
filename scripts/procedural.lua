local lume = require 'libraries.lume'

local ProcGen = {}

-- Steps
-- 1. Generate Room
--  => Rectangle (done)
--  => Overlapping Rectangles (done)
--  => Overlapping Circles (done)
--  => Cellular Automata (done)
--  => Random Shape
-- 2. Assign Doors
--  => 4 cardinal faces of room
--  => Randomly add hallway
-- 3. Place Room in Map
--  => First room is random
--  => Corresponding rooms link up to current rooms based on door.
-- 3. Fill map with rooms
--  => Based on room connecting with doors and not overlapping
-- 4. Connect rooms with shared wall tiles
--  => Retrieve floor tiles
--  => Calculate distance between two floor tiles
--  => Wall tiles with greatest distance between two floor tiles will be a door

local function _createCell(args)

    local cell = {
        x = args.x or assert(args.x, 'Tried to _createCell(args) without x parameter'),
        y = args.y or assert(args.y, 'Tried to _createCell(args) without y parameter'),
        type = args.type or 'floor',
        gid = args.gid or 0
    }

    return cell
end

-- width, height parameters are maximums.
local function _generateSquareRoom(width, height)
    local cells = {}

    for y = 1, height do
        cells[y] = {} 
        for x = 1, width do
            cells[y][x] = _createCell({x = x, y = y, type = 'floor'})
        end
    end

    return cells
end

local function _generateCircleRoom(radius)
    local cells = {}
    local list = {}
    
    local bufferX = radius*3
    local bufferY = radius*3

    local centerX = math.floor(bufferX / 2) + 1
    local centerY = math.floor(bufferY / 2) + 1

    for y = 1, bufferY do
        cells[y] = {}
        for x = 1, bufferX do
            cells[y][x] = _createCell({x = x, y = y, type = 'empty'})
            table.insert(list, {x = x, y = y})
        end
    end

    for _, point in pairs(list) do
        local distance = (point.x-centerX)^2 + (point.y-centerY)^2 - radius^2
        local max = math.sqrt(radius)

        if distance < max then
            cells[point.y][point.x].type = 'floor'
        end
    end

    return cells
end

local function _getCell(room, x, y, filter)
    if room[y] then

        if room[y][x] then
            if filter then 
                if room[y][x].type == filter then
                    return room[y][x]
                else
                    return false
                end
            end

            return room[y][x]
        end
    end

    return false
end

local function _getNeighborCount(room, cell, filter)
    local count = 0
    if _getCell(room, cell.x, cell.y - 1, filter) then count = count + 1 end
    if _getCell(room, cell.x, cell.y + 1, filter) then count = count + 1 end
    if _getCell(room, cell.x + 1, cell.y, filter) then count = count + 1 end
    if _getCell(room, cell.x - 1, cell.y, filter) then count = count + 1 end
    return count
end

local function _getNeighbors(room, cell, filter)
    local neighbors = {
    up = _getCell(room, cell.x, cell.y - 1, filter),
    down = _getCell(room, cell.x, cell.y + 1, filter),
    left = _getCell(room, cell.x - 1, cell.y, filter),
    right = _getCell(room, cell.x + 1, cell.y, filter)
    }

    return neighbors
end

local function _generateCARoomStep(oldGrid, birthLimit, deathLimit)
    local newGrid = {}

    for y = 1, #oldGrid do
        newGrid[y] = {}
        for x = 1, #oldGrid[y] do
            newGrid[y][x] = {}
        end
    end

    local function _countAliveNeighbors(grid, tx, ty)
        local count = 0

        for i = -1, 1 do
            for j = -1, 1 do
                local nx = tx + i
                local ny = ty + j

                if (i == 0) and (j == 0) then
                    -- Do nothing
                elseif (nx <= 0) or (ny <= 0) or (nx >= #grid[1]) or (ny >= #grid) then
                    count = count + 1 -- off edge of map
                elseif grid[ny][nx] then
                        count = count + 1
                end
            end
        end
        return count
    end

    for y = 1, #oldGrid do
        for x = 1, #oldGrid[y] do
            local nbs = _countAliveNeighbors(oldGrid, x, y)

            if oldGrid[y][x] then
                if nbs < deathLimit then
                    newGrid[y][x] = false
                else
                    newGrid[y][x] = true
                end
            else
                if nbs > birthLimit then
                    newGrid[y][x] = true
                else
                    newGrid[y][x] = false
                end
            end
        end
    end

    return newGrid
end


-- Generate a room with a fixed width and height using Cellular Automata
local function _generateCARoom(width, height, birthLimit, deathLimit, steps)
    local cells = {}
    local grid = {}

    for y = 1, height do
        cells[y] = {}
        grid[y] = {}
        for x = 1, width do
            cells[y][x] = _createCell({x = x, y = y, type = 'empty'})
            grid[y][x] = math.random(0,100) <= 40 -- Chance to start alive
        end
    end

    for i = 1, steps do
        grid = _generateCARoomStep(grid, birthLimit, deathLimit)
    end

    for y = 1, #grid do
        for x = 1, #grid[y] do
            local cell = grid[y][x]

            if cell then
                cells[y][x].type = 'wall'
            else
                cells[y][x].type = 'floor'
            end

        end
    end
    
    return cells
end

local function _pullRoomFromCAGrid(grid)
    local listOfFloorTiles = {}

    -- Rip floor cells from Cellular Automata grid
    for y = 1, #grid do
        for x = 1, #grid[y] do
            if grid[y][x].type == 'floor' then
                table.insert(listOfFloorTiles, grid[y][x])
            end
        end
    end

    local start = listOfFloorTiles[math.random(1, #listOfFloorTiles)]
    start.connected = true
    listOfFloorTiles = {start}
    

    -- Recurisvely walk through list until empty, marking tiles
    while #listOfFloorTiles > 0 do
        local current = listOfFloorTiles[1]
        table.remove(listOfFloorTiles, 1)

        local neighbors = _getNeighbors(grid, current)
        
        if neighbors.up and neighbors.up.type == 'floor' and not neighbors.up.connected then
            neighbors.up.connected = true
            table.insert(listOfFloorTiles, neighbors.up)
        end

        if neighbors.down and neighbors.down.type == 'floor' and not neighbors.down.connected then
            neighbors.down.connected = true
            table.insert(listOfFloorTiles, neighbors.down)
        end

        if neighbors.left and neighbors.left.type == 'floor' and not neighbors.left.connected then
            neighbors.left.connected = true
            table.insert(listOfFloorTiles, neighbors.left)
        end

        if neighbors.right and neighbors.right.type == 'floor' and not neighbors.right.connected then
            neighbors.right.connected = true
            table.insert(listOfFloorTiles, neighbors.right)
        end
    end

    for y = 1, #grid do
        for x = 1, #grid[y] do
            if grid[y][x].connected then
                grid[y][x].type = 'floor'
            elseif grid[y][x] then
                grid[y][x].type = 'empty'
            end
        end
    end

    return grid
end

local function _getRoomWidth(room)
    local counts = {}
    for y = 1, #room do
        table.insert(counts, #room[y])
    end

    table.sort(counts, function(a,b) return a > b end)

    return counts[1]
end

local function _getRoomHeight(room)
    return #room
end

-- Overlap two rooms on center
local function _combineRoom(roomA, roomB, randomOffset)
    local rooms = {roomA, roomB}

    -- Create a buffer for new room total width * height
    local bufferX = (_getRoomWidth(roomA) + _getRoomWidth(roomB) + 5)/2 + 5 + randomOffset
    local bufferY = (_getRoomHeight(roomA) + _getRoomHeight(roomB) + 5)/2 + 5 + randomOffset

    -- Create empty 2D array for rooms to be moved around on
    local newRoom = {}
    for y = 1, bufferY do
        newRoom[y] = {}
        for x = 1, bufferX do
            newRoom[y][x] = _createCell({x = x, y = y, type = 'empty'})
        end
    end

    for _, room in pairs(rooms) do

        -- Place roomA in center
        local ax = math.floor(bufferX/2)
        local ay = math.floor(bufferY/2)

        local aox = ax - (math.floor(_getRoomWidth(room)/2)) + math.random(1, randomOffset)
        local aoy = ay - (math.floor(_getRoomHeight(room)/2)) + math.random(1, randomOffset)

        -- Copy roomA tiles onto center coords
        for y = 1, #room do
            for x = 1, #room[y] do
                local cell = room[y][x]

                cell.x = x + aox
                cell.y = y + aoy

                newRoom[cell.y][cell.x] = cell
            end
        end
    end

    return newRoom
end


local function _addDoorsToRoom(room)
    local cells = {}
    local foundTop = false
    local foundLeft = false
    local foundRight = false
    local foundBot = false


    for y, _ in pairs(room) do
        for _, cell in pairs(room[y]) do
            if cell.type ~= 'empty' then
                table.insert(cells, cell)
            end
        end
    end

    for _, cell in ipairs(cells) do
        local neighbors = _getNeighbors(room, cell, 'floor')

        if not neighbors.up and neighbors.down and not foundTop then
            if math.random(1,4) == 4 then
                local target = room[cell.y-1][cell.x]
                if _getNeighborCount(room, target, 'floor') == 1 then
                    target.type = 'door'
                    foundTop = true
                end
            end
        end

        if not neighbors.right and neighbors.left and not foundRight then
            if math.random(1,4) == 4 then
                local target = room[cell.y][cell.x+1]
                if _getNeighborCount(room, target, 'floor') == 1 then
                    target.type = 'door'
                    foundRight = true
                end
            end
        end

        if not neighbors.left and neighbors.right and not foundLeft then
            if math.random(1,4) == 4 then
                local target = room[cell.y][cell.x-1]
                if _getNeighborCount(room, target, 'floor') == 1 then
                    target.type = 'door'
                    foundLeft = true
                end
            end
        end

        if not neighbors.down and neighbors.up and not foundBot then
            if math.random(1,4) == 4 then
                local target = room[cell.y + 1][cell.x]
                if _getNeighborCount(room, target, 'floor') == 1 then
                    target.type = 'door'
                    foundBot = true
                end
            end
        end
    end
end

-- Empty tiles that have 1-2 neighboring floor tiles
local function _addWallsToRoom(room)
    local walls = {}

    for y = 1, #room do
        for x = 1, #room[y] do
            if room[y][x] then
                if room[y][x].type == 'empty' then
                    local cell = room[y][x]
                    local neighbors = _getNeighborCount(room, cell, 'floor')

                    if neighbors > 0 then
                        cell.type = 'wall'
                    end
                
                end
            end
        end
    end

end

function ProcGen:generateRoom()
    local square = _generateSquareRoom(math.random(3,6), math.random(8,12))
    local circle = _generateCircleRoom(math.random(2,4))

    -- circle = _combineRoom(circle, square)
    -- circle = _combineRoom(circle, room2)
    -- _addDoorsToRoom(circle)

    --local cells = _generateCARoom(20,20, 4, 3, 10) 
    --cells = _pullRoomFromCAGrid(cells)

    local cells

    cells = _combineRoom(circle, square, math.random(1,4))
    _addDoorsToRoom(cells)
    _addWallsToRoom(cells)

    return cells
end



function ProcGen:createNewMap()
    local mapData = self:generateRoom()

    return mapData
end

return ProcGen

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
--

-- A *grid* is a binary 2D array with x, y coordinates and 0, 1 value based on if it exists

local function _createCell(args)

    local cell = {
        x = args.x or assert(args.x, 'Tried to _createCell(args) without x parameter'),
        y = args.y or assert(args.y, 'Tried to _createCell(args) without y parameter'),
        type = args.type or 'floor',
        gid = args.gid or 0
    }

    return cell
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

-- Returns lowest x & y position in a grid array
local function _getGridOffsets(grid)
    local listOfXNodes = {}
    local listOfYNodes = {}

    for _, node in pairs(grid) do
        if node.type == 'floor' then
            table.insert(listOfXNodes, node.x)
            table.insert(listOfYNodes, node.y)
        end
    end

    table.sort(listOfXNodes, function(a,b) return a < b end)
    table.sort(listOfYNodes, function(a,b) return a < b end)

    return listOfXNodes[1], listOfYNodes[1]
end

-- Grid needs to be a one dimension array of x, y values
local function _getGridDimensions(grid, ox, oy)
    local listOfXNodes = {}
    local listOfYNodes = {}

    ox = ox or 0
    oy = oy or 0

    for _, node in pairs(grid) do
        table.insert(listOfXNodes, node.x - ox)
        table.insert(listOfYNodes, node.y - oy)
    end

    -- Sort table where largest value is at first index
    table.sort(listOfXNodes, function(a,b) return a > b end)
    table.sort(listOfYNodes, function(a,b) return a > b end)

    return listOfXNodes[1], listOfYNodes[1]
end

local function _convertGridToCells(grid, ox, oy)
    local cells = {}

    ox = ox or 0
    oy = oy or 0

    local xBound, yBound = _getGridDimensions(grid, ox, oy)

    for y = 1, yBound do
        cells[y] = {}
        for x = 1, xBound do
            cells[y][x] = _createCell({x = x, y = y, type = 'empty'})
        end
    end

    for _, node in pairs(grid) do
        node.x = node.x - ox
        node.y = node.y - oy
        if cells[node.y][node.x] and node.type then
            cells[node.y][node.x].type = node.type
        end
    end

    return cells
end

-- Index list of nodes in grid table. Return if valid, and meets filter.
local function _getNode(grid, x, y, filter)
    for _, node in pairs(grid) do
        if node.x == x and node.y == y then
            if filter and node.type == filter then
                return node
            elseif not filter then
                return node
            else
                return false
            end
        end
    end
end

local function _getNodeNeighborCount(grid, node, filter)
    local count = 0
    if _getNode(grid, node.x, node.y - 1, filter) then count = count + 1 end
    if _getNode(grid, node.x, node.y + 1, filter) then count = count + 1 end
    if _getNode(grid, node.x + 1, node.y, filter) then count = count + 1 end
    if _getNode(grid, node.x - 1, node.y, filter) then count = count + 1 end
    return count
end

local function _getNeighbors(grid, node, filter)
    local neighbors = {

    up = _getNode(grid, node.x, node.y - 1, filter),
    down = _getNode(grid, node.x, node.y + 1, filter),
    left = _getNode(grid, node.x - 1, node.y, filter),
    right = _getNode(grid, node.x + 1, node.y, filter)
    }

    return neighbors
end


-- width, height parameters are maximums.
function ProcGen:generateSquareRoom(width, height)
    local grid = {}

    for y = 1, height do
        for x = 1, width do
            table.insert(grid, {x = x, y = y, type = 'floor'})
        end
    end

    local cells = _convertGridToCells(grid)

    return cells
end

function ProcGen:generateCircleRoom(radius)
    local grid = {}

    local hyperSpaceX = radius * 2 + 1
    local hyperSpaceY = radius * 2 + 1

    local centerX = math.floor(hyperSpaceX/ 2) + 1
    local centerY = math.floor(hyperSpaceY/ 2) + 1

    -- Create an empty hyperSpace to iterate over
    for y = 1, hyperSpaceY do
        for x = 1, hyperSpaceX do
            table.insert(grid, {x = x, y = y})
        end
    end

    for _, point in pairs(grid) do
        local distance = (point.x-centerX)^2 + (point.y-centerY)^2 - radius^2
        local max = math.sqrt(radius)

        if distance < max then
            point.type = 'floor' 
        end
    end

    local cells = _convertGridToCells(grid)

    return cells
end

local function _generateCARoomStep(oldHyperSpace, birthLimit, deathLimit)
    local newHyperSpace = {}

    -- Copy size of old space to new space
    for y = 1, #oldHyperSpace do
        newHyperSpace[y] = {}
        for x = 1, #oldHyperSpace[y] do
            newHyperSpace[y][x] = {}
        end
    end

    local function _countAliveNeighbors(hyperSpace, tx, ty)
        local count = 0
        -- Loop to all eight neighboring nodes
        for i = -1, 1 do
            for j = -1, 1 do
                local nx = tx + i
                local ny = ty + j

                -- If node == start then do nothing
                if (i == 0) and (j == 0) then
                    -- Do nothing
                elseif (nx <= 0) or (ny <= 0) or (nx >= #hyperSpace[1]) or (ny >= #hyperSpace) then
                    count = count + 1 -- off edge of map
                elseif hyperSpace[ny][nx] then
                    count = count + 1 -- count alive node
                end
            end
        end

        return count
    end

    for y = 1, #oldHyperSpace do
        for x = 1, #oldHyperSpace[y] do
            local nbs = _countAliveNeighbors(oldHyperSpace, x, y)

            if oldHyperSpace[y][x] then
                if nbs < deathLimit then
                    newHyperSpace[y][x] = false
                else
                    newHyperSpace[y][x] = true
                end
            else
                if nbs > birthLimit then
                    newHyperSpace[y][x] = true
                else
                    newHyperSpace[y][x] = false
                end
            end
        end
    end

    return newHyperSpace
end


-- Generate a room with a fixed width and height using Cellular Automata
function ProcGen:generateCARoom(width, height, birthLimit, deathLimit, startAliveChance, steps)
    if not birthLimit then birthLimit = 4 end
    if not deathLimit then deathLimit = 4 end
    if not startAliveChance then startAliveChance = 50 end
    if not steps then steps = 10 end

    local hyperSpace = {}

    -- Create a hyperSpace to virtually manipulate
    for y = 1, height do
        hyperSpace[y] = {}
        for x = 1, width do
            hyperSpace[y][x] = math.random(1,100) > startAliveChance
        end
    end

    -- Iterate steps x amount of times
    for i = 1, steps do
        hyperSpace = _generateCARoomStep(hyperSpace, birthLimit, deathLimit)
    end

    -- Convert hyperspace to Grid for output
    local grid = {}
    for y = 1, #hyperSpace do
        for x = 1, #hyperSpace[y] do
            if hyperSpace[y][x] then
                table.insert(grid, {x = x, y = y, type = 'wall'})
            else
                table.insert(grid, {x = x, y = y, type = 'floor'})
            end
        end
    end

    -- Convert grid to cells for mapData
    local cells = _convertGridToCells(grid)
    
    return grid
end

function ProcGen:floodFill(grid, startNode, list)
    startNode._filled = true
    list = list or {}
    table.insert(list, startNode)
    local neighbors = _getNeighbors(grid, startNode, 'floor')

    if neighbors.up then if not neighbors.up._filled then self:floodFill(grid,neighbors.up, list) end end
    if neighbors.down then if not neighbors.down._filled then self:floodFill(grid,neighbors.down, list) end end
    if neighbors.left then if not neighbors.left._filled then self:floodFill(grid,neighbors.left, list) end end
    if neighbors.right then if not neighbors.right._filled then self:floodFill(grid,neighbors.right, list) end end

    return list
end


local function _pullRoomFromCAGrid(grid)
    local listOfFloorTiles = {}

    for _, node in pairs(grid) do
        if node.type == 'floor' then
            table.insert(listOfFloorTiles, node)
        end
    end

    local randomNode = listOfFloorTiles[math.random(1, #listOfFloorTiles)]

    local fill = ProcGen:floodFill(grid, randomNode)

    -- Need to get offset to properly rip cells from grid
    local fx, fy = _getGridOffsets(fill)
    fx = fx - 1
    fy = fy - 1

    local cells = _convertGridToCells(fill,fx,fy)


    return cells
end

-- Overlap two rooms on center
local function _combineRoom(roomA, roomB, randomOffset)
    local rooms = {roomA, roomB}
    print(randomOffset)
    -- Create a buffer for new room total width * height
    -- local bufferX = math.max(_getRoomWidth(roomA), _getRoomWidth(roomB)) 
    -- local bufferY = math.max(_getRoomHeight(roomA), _getRoomHeight(roomB)) 
    local bufferX = 25
    local bufferY = 25 

    -- print('roomA width & height: ', _getRoomWidth(roomA) .. ' ' .. _getRoomHeight(roomA))
    -- print('roomA width & height: ', _getRoomWidth(roomB) .. ' ' .. _getRoomHeight(roomB))
    -- print('hyperSpace width & height: ', bufferX .. ' ' .. bufferY)
    

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
        local ax = math.floor(bufferX/2) - math.floor(_getRoomWidth(room)/2)
        local ay = math.floor(bufferY/2) - math.floor(_getRoomHeight(room)/2)

        -- Apply x & y offset
        local aox = math.random(-randomOffset, randomOffset)
        local aoy = math.random(-randomOffset, randomOffset)

        -- Copy roomA tiles onto center coords
        for y = 1, #room do
            for x = 1, #room[y] do
                local cell = room[y][x]

                cell.x = x + ax + aox
                cell.y = y + ay + aoy

                newRoom[cell.y][cell.x] = cell
            end
        end
    end

    -- Revisit if pruning is necessary
    -- Prune empty tiles to shrink hyperSpace
    -- local listOfYPositions = {}
    -- local listOfXPositions = {}
    --
    -- for y = 1, #newRoom do
    --     for x = 1, #newRoom[y] do
    --         local cell = newRoom[y][x]
    --         
    --         if cell.type ~= 'empty' then
    --             table.insert(listOfYPositions, y)
    --             table.insert(listOfXPositions, x)
    --         end
    --     end
    -- end
    --
    -- table.sort(listOfXPositions, function(a,b) return a > b end)
    -- table.sort(listOfYPositions, function(a,b) return a > b end)
    --
    -- local hyperWidth = listOfXPositions[1] - listOfXPositions[#listOfXPositions] + 1
    -- local hyperHeight = listOfYPositions[1] - listOfYPositions[#listOfYPositions] + 1
    --
    -- local hyper = {}
    -- for y = 1, hyperHeight do
    --     hyper[y] = {}
    --     for x = 1, hyperWidth do
    --         hyper[y][x] = _createCell({x = x, y = y, type = 'empty'})
    --     end
    -- end
    --
    -- for y = 1, #newRoom do
    --     for x = 1, #newRoom[y] do
    --         if newRoom[y][x].type == 'floor' then
    --             local cell = newRoom[y][x]
    --             -- newRoom[y][x].type = 'empty'
    --
    --             local newx = cell.x - math.floor(bufferX/2) + (math.floor(hyperWidth/2))
    --             local newy = cell.y - math.floor(bufferY/2) + (math.floor(hyperHeight/2))
    --
    --             if newRoom[newy] then
    --                 if newRoom[newy][newx] then
    --                     newRoom[newy][newx].type = 'floor'
    --                 end
    --             end
    --
    --         end
    --         -- if newRoom[y][x].type == 'floor' then
    --         --     local newX = bufferX - hyperWidth - x
    --         --     local newY = bufferY - hyperHeight - y
    --         --
    --         --     if hyper[newY] then
    --         --         if hyper[newY][newX] then
    --         --             hyper[newY][newX].type = 'floor'
    --         --         end
    --         --     end
    --         -- end
    --     end
    -- end

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
                print(cell.x, cell.y + 1)
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

function ProcGen:generateRoom(random)
    local cells = {}


    -- cells = self:generateCircleRoom(math.random(3,15))
    cells = self:generateSquareRoom(math.random(1,15),math.random(1,15))
    -- cells = self:generateCARoom(20,20)
    -- cells = _pullRoomFromCAGrid(cells)
    -- cells = _convertGridToCells(cells)

    return cells
end

function ProcGen:generateDungeon()

    local dungeon = {}


    -- for now
    dungeon = self:generateRoom()

    return dungeon
end



function ProcGen:createNewMap()
    local mapData = self:generateDungeon()

    return mapData
end

return ProcGen

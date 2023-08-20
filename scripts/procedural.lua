local lume = require 'libraries.lume'
local Prefab = require 'scripts.prefabs'
local Room = require 'scripts.class.roomClass'

local test = Room()

-- And finally, one last Git test

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
        elseif not node.type then
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

    for y = 1, yBound + 2 do
        cells[y] = {}
        for x = 1, xBound + 2 do
            cells[y][x] = _createCell({x = x, y = y, type = 'empty'})
        end
    end

    for _, node in pairs(grid) do
        node.x = node.x - ox + 1
        node.y = node.y - oy + 1
        if cells[node.y] and cells[node.y][node.x] then
            cells[node.y][node.x] = node
        else
            error()
        end
        -- if cells[node.y][node.x] and node.type then
            -- cells[node.y][node.x].type = node.type
            -- if cells[node.y][node.x].doorDirection then
            --     cells[node.y][node.x].doorDirection = node.doorDirection
            -- end
        -- end
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

local function _getNeighbors(grid, node, filter)
    local neighbors = {

    up = _getNode(grid, node.x, node.y - 1, filter),
    down = _getNode(grid, node.x, node.y + 1, filter),
    left = _getNode(grid, node.x - 1, node.y, filter),
    right = _getNode(grid, node.x + 1, node.y, filter)
    }

    return neighbors
end

-- Get's number of neighbors that meet filter criteria (or floor)
local function _getNeighborCountByCell(cells, cell, filter)
    local count = 0
    local x = cell.x
    local y = cell.y
    filter = filter or 'floor'

    if cells[y] and cells[y][x+1] and cells[y][x+1].type == filter then count = count + 1 end
    if cells[y] and cells[y][x-1] and cells[y][x-1].type == filter then count = count + 1 end
    if cells[y+1] and cells[y+1][x] and cells[y+1][x].type == filter then count = count + 1 end
    if cells[y-1] and cells[y-1][x] and cells[y-1][x].type == filter then count = count + 1 end

    return count
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
            table.insert(grid, {x = x, y = y, type = 'empty'})
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

local function _generateCAMap(width, height, birthLimit, deathLimit, startAliveChance, steps)
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


function ProcGen:generateCARoom(width, height, birthLimit, deathLimit, startAliveChance, steps)

    -- Generate a room with a fixed width and height using Cellular Automata
    if not birthLimit then birthLimit = 4 end
    if not deathLimit then deathLimit = 4 end
    if not startAliveChance then startAliveChance = 50 end
    if not steps then steps = 5 end

    local grid = _generateCAMap(width, height, birthLimit, deathLimit, startAliveChance, steps)
    local listOfFloorTiles = {}

    for _, node in pairs(grid) do
        if node.type == 'floor' then
            table.insert(listOfFloorTiles, node)
        end
    end

    -- Failsafe in case generated CA map is garbage
    if #listOfFloorTiles == 0 then return self:generateCARoom(width, height, birthLimit, deathLimit, startAliveChance, steps) end

    local randomNode = listOfFloorTiles[math.random(1, #listOfFloorTiles)]

    -- TODO: randomNode appears to fail if map is too small?
    -- Need to quality check CA map to determine if map is bigger than x
    -- if not randomNode then return self:generateCARoom(width, height) end

    local fill = ProcGen:floodFill(grid, randomNode)
    
    if #fill <= 16 then return self:generateCARoom(width, height, birthLimit, deathLimit, startAliveChance, steps) end

    -- Need to get offset to properly rip cells from grid
    local fx, fy = _getGridOffsets(fill)
    fx = fx - 1
    fy = fy - 1

    local cells = _convertGridToCells(fill,fx,fy)


    return cells
end

-- Overlap two rooms on center
local function _combineRoom(roomA, roomB, randomX, randomY)
    local rooms = {roomA, roomB}

    -- Arbitrary 2D array size to permit room combining
    local bufferX = 50
    local bufferY = 50

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
        -- This offsets room's 'centered' position to create overlapping
        -- rooms such as T rooms, L rooms, etc.
        local aox = math.floor(randomX)
        local aoy = math.floor(randomY)

        if _ > 1 then
            aox = -math.floor(randomX)
            aoy = -math.floor(randomY)
        end

        -- Copy roomA tiles onto center coords + offset amounts
        for y = 1, #room do
            for x = 1, #room[y] do
                local cell = room[y][x]
                local nx = x + ax + aox
                local ny = y + ay + aoy
                
                if cell.type == 'floor' then
                    newRoom[ny][nx].type = 'floor'
                end

                if cell.type == 'door' then
                    newRoom[ny][nx].type = 'door'
                end

                if cell.type == 'wall' then
                    if newRoom[ny][nx].type == 'empty' then
                        newRoom[ny][nx].type = 'wall'
                    end
                end
            end
        end
    end
    
    -- Now we must take out table full of cells, and convert it to a grid.
    -- Using a grid, we can calculate how much we need to move the entire room
    -- left and up in order to prune excess empty tiles.
    --------------------------------------------------------------------------
    local grid = {}

    -- Copy combined room cells into a new grid
    for y = 1, #newRoom do
        for x = 1, #newRoom[y] do
            if newRoom[y][x].type ~= 'empty' then
                table.insert(grid, newRoom[y][x])
            end
        end
    end

    -- Get distance from x=1, y=1. Then subtract 1 to add a 1 tile border.
    -- That border of empty cells is needed for calculating walls & doors.
    local ox, oy = _getGridOffsets(grid)
    ox = ox - 1
    oy = oy - 1

    -- Using new found offsets, convert grid back to cells with correct size
    newRoom = _convertGridToCells(grid, ox, oy)

    return newRoom
end

-- Empty tiles that have 1-2 neighboring floor tile
function ProcGen:addWallsToRoom(room)
    local newRoom = room

    for y = 1, #room do
        for x = 1, #room[y] do
            local cell = room[y][x]

            if cell and cell.type == 'empty' then
                local neighborCount = _getNeighborCountByCell(room, cell, 'floor')

                if neighborCount > 0 then
                    newRoom[y][x].type = 'wall'
                end
            end
        end
    end

    room = newRoom
end

function ProcGen:addDoorsToRoom(room)
    local northDoorCandidates = {}
    local southDoorCandidates = {}
    local eastDoorCandidates = {}
    local westDoorCandidates = {}

    -- Chance of placing a door is higher closer to the center
    local roomWidth = _getRoomWidth(room)


    for y = 1, #room do
        for x = 1, #room[y] do
            local cell = room[y][x]

            local xBound = 100-(((math.abs((roomWidth/2)-x+1))*roomWidth))
            local yBound = (100-((math.abs((#room/2)-y))*#room))

            if cell.type == 'wall' then
                if not room[y-1] then 
                    if room[y][x+1] and room[y][x+1].type == 'wall' then
                        if room[y][x-1] and room[y][x-1].type == 'wall' then 
                            table.insert(northDoorCandidates, cell)
                        end
                    end
                end

                if not room[y+1] then
                    if room[y][x+1] and room[y][x+1].type == 'wall' then
                        if room[y][x-1] and room[y][x-1].type == 'wall' then
                            table.insert(southDoorCandidates, cell)
                        end
                    end
                end

                if not room[y][x+1] then 
                    if room[y+1] and room[y+1][x].type == 'wall' then
                        if room[y-1] and room[y-1][x].type == 'wall' then
                            table.insert(eastDoorCandidates, cell)
                        end
                    end
                end

                if not room[y][x-1] then
                    if room[y+1] and room[y+1][x].type == 'wall' then
                        if room[y-1] and room[y-1][x].type == 'wall' then
                            table.insert(westDoorCandidates, cell)
                        end
                    end
                end
            end
        end
    end

    local function _randomDoorSelection(listOfDoors, direction)
        for n = 1, #listOfDoors do
            local total = #listOfDoors
            local selection = listOfDoors[math.random(1,total)]
            local chance = math.floor((n/total)*100)

            if math.random(1,100) < chance + 10 then
                selection.type = 'door'
                selection.doorDirection = direction
                break
            end
        end
    end

    _randomDoorSelection(northDoorCandidates, 'north')
    _randomDoorSelection(southDoorCandidates, 'south')
    _randomDoorSelection(eastDoorCandidates, 'east')
    _randomDoorSelection(westDoorCandidates, 'west')
end

-- Generates a dungeon full of squares
function ProcGen:generateRoomForGridDungeon(ratio)

    local cells = {}

    local size = math.floor(ratio / 15)
    size = size + (size / 2)
    size = math.floor(size)
    print(size)
    cells = self:generateSquareRoom(math.random(4,10 - size), math.random(4,10 - size))

    return cells
end

local function _loadFromPrefab(name, index)
    if not Prefab[name] then assert(name, 'Incorrect Prefab Name for _loadFromPrefab') end
    if index > #Prefab[name] then assert(index, 'Incorrect index value for Prefab') end

    local grid = Prefab[name][index]
    local cells = {}

    for y = 1, #grid do
        cells[y] = {}
        for x = 1, #grid[y] do
            cells[y][x] = {}

            if grid[y][x] == 0 then
                cells[y][x] = _createCell({x = x, y = y, type = 'empty'})
            elseif grid[y][x] == 1 then
                cells[y][x] = _createCell({x = x, y = y, type = 'floor'})
            elseif grid[y][x] == 2 then
                cells[y][x] = _createCell({x = x, y = y, type = 'wall'})
            elseif grid[y][x] == 3 then
                cells[y][x] = _createCell({x = x, y = y, type = 'door'})
            end
        end
    end

    return cells    
end

-- Generates a dungeon full of random sized rooms
function ProcGen:generateRoom(ratio)
    local cells = {}

    self.debugText = ratio

    if ratio < 20 then -- Big rooms
        local r = math.random(1, 4)

        if r == 1 then
            local a = self:generateSquareRoom(10,5)
            local b = self:generateSquareRoom(5,10)
            local c = self:generateCircleRoom(5)
            cells = _combineRoom(a,b, math.random(-1,1), math.random(-1,1))
            cells = _combineRoom(cells, c, math.random(-2, 2), math.random(-2, 2))
        elseif r == 2 then
            local a = self:generateCARoom(20, 15)
            cells = a
        elseif r == 3 then
            local a = self:generateCircleRoom(math.random(4,6))
            local b = self:generateCircleRoom(math.random(2,4))
            cells = _combineRoom(a,b, math.random(-3,2), math.random(-3,2))
        elseif r == 4 then
            local a = self:generateCARoom(20,20)
            cells = a
        end
    elseif ratio >= 20 then
        local r = math.random(1, 5)

        if r == 1 then
            local a = self:generateSquareRoom(3,5)
            local b = self:generateSquareRoom(5,3)
            local c = self:generateCircleRoom(3)
            cells = _combineRoom(a,b, math.random(-1,1), math.random(-1,1))
            cells = _combineRoom(cells, c, math.random(-1, 1), math.random(-1, 1))
        elseif r == 2 then
            local a = self:generateSquareRoom(math.random(3,7), math.random(2,4))
            local b = self:generateSquareRoom(math.random(2,4), math.random(3,7))
            cells = _combineRoom(a,b, math.random(-1, 1), math.random(-1, 1))
        elseif r == 3 then
            local a = self:generateCircleRoom(3)
            local b = self:generateSquareRoom(math.random(10,12), math.random(2,4))
            local c = self:generateSquareRoom(math.random(2,4), math.random(10,12))

            if math.random(1, 100) > 50 then
                cells = _combineRoom(a,b,0,0)
            else
                cells = _combineRoom(a,c,0,0)
            end
        elseif r == 4 then
            local a = self:generateCARoom(15,15)
            cells = a
        elseif r == 5 then
            local a = self:generateCARoom(12,12)
            cells = a
        end
    end

    self:addWallsToRoom(cells)

    return cells
end

local function _convertCellsToGrid(cells)
    local grid = {}

    for y = 1, #cells do
        for x = 1, #cells[y] do
            -- table.insert(grid, {x = x, y = y, type = cells[y][x].type, doorDirection = cells[y][x].doorDirection})
            table.insert(grid, cells[y][x])
        end
    end

    return grid
end

local function _copyRoomIntoDungeon(room, dungeon, x, y)
    local listOfRoomCells = {}

    x = math.floor(x)
    y = math.floor(y)

    for _, node in pairs(room) do
        if node.type ~= 'empty' then
            dungeon[y + node.y][x + node.x] = node
            table.insert(listOfRoomCells, node)
        end
    end

    return listOfRoomCells
end

local function _doesRoomFitIntoDungeon(room, dungeon, x, y, direction)
    x = math.floor(x)
    y = math.floor(y)

    -- if direction == 'north' then y = y - 2 end
    -- if direction == 'south' then y = y + 2 end
    -- if direction == 'west' then x = x - 2 end
    -- if direction == 'east' then x = x + 2 end

    local overlappingWalls = {}
    local overlappingFloorCount = 0

    for _, node in pairs(room) do
        local nx = x + node.x
        local ny = y + node.y
        local target

        -- If location is off the map, return false
        if dungeon[ny] and dungeon[ny][nx] then
            target = dungeon[ny][nx]
        end

        if target then
            -- Compare room 'Wall' tiles to dungeon tiles.
            if node.type == 'wall' then

                -- If a wall tile in our room is overlapping a wall tile in the dungeon
                -- Count how many overlap to determine if it fits well
                if target.type == 'wall' then
                    node._isOverlappingWall = true
                    table.insert(overlappingWalls, node)
                else
                    node._isOverlappingWall = false
                end
            end

            -- Now cycle through the floor tiles to determine if they are overlapping
            -- any other floor tiles in the map. Since walls can overlap, we ignore that.
            if node.type == 'floor' then
                if target.type == 'floor' or target.type == 'wall' then
                    overlappingFloorCount = overlappingFloorCount + 1
                end
            end
        end
    end

    -- If enough walls overlap, check if any other cells overlap in the dungeon
    if #overlappingWalls > 0 and overlappingFloorCount == 0 then
        return true
    else
        return false
    end

end

function ProcGen:addHallway(room)
    -- Step 1: find door
    local doors = {}
    local grid = {}

    for y = 1, #room do
        for x = 1, #room[y] do
            if room[y][x].type == 'door' then
                table.insert(doors, {x = x, y = y, doorDirection = room[y][x].doorDirection})
            end
        end
    end


    -- Pick a random door
    local select = math.random(1, #doors)
    local door = doors[select]
    local direction = door.doorDirection
    local steps = math.random(3, 6)

    local DIR = {
        ['north'] = {0, -1},
        ['south'] = {0, 1},
        ['east'] = {1, 0},
        ['west'] = {-1, 0}
    }

    local x, y = door.x, door.y
    for i = 1, steps do
        x = x + DIR[direction][1]
        y = y + DIR[direction][2]

        table.insert(grid, {x = x, y = y, type = 'floor'})
    end

    local ox, oy = _getGridOffsets(grid)
    ox = ox - 1
    oy = oy - 1
            
    return _combineRoom(room, grid)
end

function ProcGen:placeRandomRoom(room, dungeon, totalAttempts)


    -- Need to code a room generator function
    -- that takes in a "size" probability parameter
    -- so we can start with large size dungeons and slower add
    -- smaller and smaller ones until 50% of the map is floor tiles
    --
    local roomGrid = _convertCellsToGrid(room)
    local roomWidth, roomHeight = _getRoomWidth(room), _getRoomHeight(room)
    local dungeonWidth, dungeonHeight = _getRoomWidth(dungeon), _getRoomHeight(dungeon)

    assert(roomWidth, 'ProcGen:placeRandomRoom | Did not give function proper room. Check generateRoom function.')
    assert(roomHeight, 'ProcGen:placeRandomRoom | Did not give function proper room. Check generateRoom function.')

    local xBoundary = dungeonWidth - roomWidth - 1
    local yBoundary = dungeonHeight - roomHeight - 1

    
    local tries = 100

    -- Attempt 10 positions, then generate new room.
    for n = 1, tries do
        local x = math.random(1, xBoundary)
        local y = math.random(1, yBoundary)

        if _doesRoomFitIntoDungeon(roomGrid, dungeon, x, y) then
            local newRoom = _copyRoomIntoDungeon(roomGrid, dungeon, x, y)
            return newRoom
        end

        if n >= tries then
            return false
        end
    end
end



function ProcGen:placeRoomInDungeon(room, dungeon, first, x, y, attempts)
    local roomGrid = _convertCellsToGrid(room)
    local roomWidth, roomHeight = _getRoomWidth(room), _getRoomHeight(room)
    local dungeonWidth, dungeonHeight = _getRoomWidth(dungeon), _getRoomHeight(dungeon)

    local limit = dungeonWidth * dungeonHeight


    if first then
        for _, grid in pairs(roomGrid) do
            _copyRoomIntoDungeon(roomGrid, dungeon, dungeonWidth/2 - roomWidth/2, dungeonHeight/2 - roomHeight/2)
            return table.insert(self.listOfRooms, room)
        end

        return
    end

    local x = 1
    local y = 1

    for n = 1, limit do
        if x + roomWidth > dungeonWidth then
            y = y + 1
            if y + roomHeight > dungeonHeight then
                break
            end
        end

        x = n - ((y-1)*(dungeonWidth-roomWidth))

        -- x & y are pointers to locations in dungeon map.
        -- They cannot exceed bounds of room size.
        --
        -- Step 1. Look for a door.
        if dungeon[y][x].type == 'door' then

            -- Step 2. Fit room to door
            for _, node in pairs(roomGrid) do
                if node.type == 'door' then
                    local ox = x - node.x
                    local oy = y - node.y
                    local roomDoorDirection = node.doorDirection
                    local direction = dungeon[y][x].doorDirection

                    if direction == 'north' and roomDoorDirection == 'south' then
                        if _doesRoomFitIntoDungeon(roomGrid, dungeon, ox, oy, direction) then
                            _copyRoomIntoDungeon(roomGrid, dungeon, ox, oy)
                            table.insert(self.listOfRooms, room)
                            return
                        end
                    end

                    if direction == 'south' and roomDoorDirection == 'north' then
                        if _doesRoomFitIntoDungeon(roomGrid, dungeon, ox, oy, direction) then
                            _copyRoomIntoDungeon(roomGrid, dungeon, ox, oy)
                            table.insert(self.listOfRooms, room)
                            return
                        end
                    end

                    if direction == 'east' and roomDoorDirection == 'west' then
                        if _doesRoomFitIntoDungeon(roomGrid, dungeon, ox, oy, direction) then
                            _copyRoomIntoDungeon(roomGrid, dungeon, ox, oy)
                            table.insert(self.listOfRooms, room)
                            return
                        end
                    end

                    if direction == 'west' and roomDoorDirection == 'east' then
                        if _doesRoomFitIntoDungeon(roomGrid, dungeon, ox, oy, direction) then
                            _copyRoomIntoDungeon(roomGrid, dungeon, ox, oy)
                            table.insert(self.listOfRooms, room)
                            return
                        end
                    end
                end
            end
        end

    end
end

function ProcGen:removeExcessDoors(dungeon)
    for y = 1, #dungeon do
        for x = 1, #dungeon[y] do
            local cell = dungeon[y][x]

            if cell.type == 'door' then
                local count = 0
                if not dungeon[y + 1] or dungeon[y + 1][x].type == 'wall' then count = count + 1 end
                if not dungeon[y - 1] or dungeon[y - 1][x].type == 'wall' then count = count + 1 end
                if not dungeon[y][x + 1] or dungeon[y][x + 1].type == 'wall' then count = count + 1 end
                if not dungeon[y][x - 1] or dungeon[y][x - 1].type == 'wall' then count = count + 1 end

                
                if count >= 3 then
                    cell.type = 'wall'
                    -- cell.type = 'wall'
                end
            end
        end
    end
end

function ProcGen:setEmptiesToWalls(dungeon)
    for y = 1, #dungeon do
        for x = 1, #dungeon[y] do
            local cell = dungeon[y][x]

            if cell.type == 'empty' then
                cell.type = 'wall'
            end
        end
    end
end

function ProcGen:reset()
    self.dungeon = nil
end

-- function ProcGen:floodFill(grid, startNode, list)
--     startNode._filled = true
--     list = list or {}
--     table.insert(list, startNode)
--     local neighbors = _getNeighbors(grid, startNode, 'floor')
--
--     if neighbors.up then if not neighbors.up._filled then self:floodFill(grid,neighbors.up, list) end end
--     if neighbors.down then if not neighbors.down._filled then self:floodFill(grid,neighbors.down, list) end end
--     if neighbors.left then if not neighbors.left._filled then self:floodFill(grid,neighbors.left, list) end end
--     if neighbors.right then if not neighbors.right._filled then self:floodFill(grid,neighbors.right, list) end end
--
--     return list
-- end
--
-- ONLY FOR MAZE GENERATION SINCE IT JUMPS 2
local function _getNeighborsByCell(cells, start)
    local list = {}
    local x = start.x
    local y = start.y

    if cells[y+1] and cells[y+1][x] then table.insert(list, cells[y+1][x]) end
    if cells[y-1] and cells[y-1][x] then table.insert(list, cells[y-1][x]) end
    if cells[y] and cells[y][x+1] then table.insert(list, cells[y][x+1]) end
    if cells[y] and cells[y][x-1] then table.insert(list, cells[y][x-1]) end

    return list
end

function ProcGen:generateHallways(dungeon, start)
    local function _flood(grid, start)
        local stack = {}
        start._visited = true
        table.insert(stack, start)

        while (#stack > 0) do
            -- Pop current node from stack
            local r = math.random(1, #stack)
            local current = stack[r]
            table.remove(stack, r)


            local neighbors = _getNeighborsByCell(grid, current)

            -- If the current cell has any unvisited neighbors, push back to stack
            local unvisitedNeighbors = {}
            for n = 1, #neighbors do
                local neighbor = neighbors[n]
                if not neighbor._visited then
                    table.insert(unvisitedNeighbors, neighbor)
                end
            end

            if #unvisitedNeighbors ~= 0 then
                table.insert(stack, 1, current)
            


                -- Choose one of the unvisited neighbors
                -- local select = unvisitedNeighbors[math.random(1, #unvisitedNeighbors)]
                local select = unvisitedNeighbors[math.random(1, #unvisitedNeighbors)]

                local x = current.x
                local y = current.y

                -- Remove the wall between the current and selected cell
                if select.direction == 'north' then
                    dungeon[y - 1][x].type = 'floor'
                elseif select.direction == 'south' then
                    dungeon[y + 1][x].type = 'floor'
                elseif select.direction == 'east' then
                    dungeon[y][x + 1].type = 'floor'
                elseif select.direction == 'west' then
                    dungeon[y][x - 1].type = 'floor'
                end

                -- Mark the selected cell as visited and push it to the stack
                select._visited = true
                select.type = 'floor'
                table.insert(stack, select)
            end


        end

    end

    _flood(dungeon, start)
end

local function _removeBadDoorsFromDungeon(dungeon)
    for y = 1, #dungeon do
        for x = 1, #dungeon[y] do
            if dungeon[y][x].type == 'door' then
                local door = dungeon[y][x]

                local up = dungeon[y-1][x]
                local down = dungeon[y+1][x]
                local left = dungeon[y][x-1]
                local right = dungeon[y][x+1]

                local count = 0
                if up and up.type == 'floor' then count = count + 1 end
                if down and down.type == 'floor' then count = count + 1 end
                if left and left.type == 'floor' then count = count + 1 end
                if right and right.type == 'floor' then count = count + 1 end

                if up and up.type == 'empty' then count = 0 end
                if down and down.type == 'empty' then count = 0 end
                if left and left.type == 'empty' then count = 0 end
                if right and right.type == 'empty' then count = 0 end

                if count ~= 2 then
                    door.type = 'wall'
                end
            end
        end
    end
end


function ProcGen:generateDungeon()
    -- local dungeon = dungeon or {}

    local width, height = 75, 50

    self.dungeon = nil
    if self.dungeon == nil then
        self.dungeon = {}

        for y = 1, height do
            self.dungeon[y] = {}
            for x = 1, width do
                self.dungeon[y][x] = _createCell({x = x, y = y, type = 'empty'})
            end
        end
    end

    local function _getFloorToWallRatio(dungeon)
        local floorCells = 0
        local wallCells = 0

        for y = 1, #dungeon do
            for x = 1, #dungeon[y] do
                if dungeon[y][x].type == 'empty' then
                    wallCells = wallCells + 1
                elseif dungeon[y][x].type == 'floor' then
                    floorCells = floorCells + 1
                end
            end
        end
        

        return math.floor((floorCells / wallCells)*100)
    end

    -- self.dungeon = self:generateRoom(10)


    local success
    self.rooms = {}

    -- if _getFloorToWallRatio(self.dungeon) == 0 then
    --     local startingRoom = self:generateRoom(10)
    --     startingRoom = _convertCellsToGrid(startingRoom)
    --     _copyRoomIntoDungeon(startingRoom, self.dungeon, 10, 10)
    -- else
    --     for i = 1, 10 do
    --         local ratio = _getFloorToWallRatio(self.dungeon)
    --         local room = self:generateRoom(ratio)
    --         success = self:placeRandomRoom(room, self.dungeon)
    --     end
    -- end
    local startingRoom = self:generateRoom(10)
    startingRoom = _convertCellsToGrid(startingRoom)
    startingRoom = _copyRoomIntoDungeon(startingRoom, self.dungeon, 10,10)
    table.insert(self.rooms, startingRoom)
    
    local density = 20
    while (#self.rooms <= math.min(density, 25)) do
        local ratio = _getFloorToWallRatio(self.dungeon)

        local room = self:generateRoom(ratio)
        success = self:placeRandomRoom(room, self.dungeon)


        if not success then
            if #self.rooms <= density - 2 then
                self:generateDungeon()
            else
                break
            end
        else
            table.insert(self.rooms, success)
        end
    end

    -- _removeBadDoorsFromDungeon(self.dungeon)

    for _, data in pairs(self.rooms) do
        for _, node in pairs(data) do
            if node._isOverlappingWall then
                self.dungeon[node.y][node.x].type = 'door'
            end
        end
    end

    return self.dungeon
end


function ProcGen:createNewMap()
    local mapData = self:generateDungeon()

    return mapData
end

return ProcGen

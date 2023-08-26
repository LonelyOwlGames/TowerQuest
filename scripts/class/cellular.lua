--- Cellular Automata Class.
-- Sets up and generates a CA map based
-- on parameters provided. Later exported into
-- roomClass for procedural room generation. But also
-- may be used for Cellular Automata caves.
-- @module cellular.lua
-- @author Lonely Owl Games

local Class = require 'libraries.hump.class'
local tileClass = require 'scripts.class.tileClass'
-- local roomClass = require 'scripts.class.roomClass'

local CA = Class{}

function CA:countAliveNeighbors(hyperSpace, x, y)
    local count = 0

    -- Iterate over all eight neighboring tiles.
    for i = -1, 1 do
        for j = -1, 1 do
            local nx = x + i
            local ny = y + j

            if (i == 0) and (j == 0) then
                -- center tile, do nothing
            elseif (nx <= 0) or (ny <= 0) or (nx >= #hyperSpace[1]) or (ny >= #hyperSpace) then
                count = count + 1 -- Off edge of map
            elseif hyperSpace[ny][nx] then
                count = count + 1 -- count alive
            end
        end
    end

    return count
end

function CA:doStep(oldHyperSpace, args)
    local newHyperSpace = {}

    -- Copy bounds of old hyperSpace to new hyperSpace
    for y = 1, #oldHyperSpace do
        newHyperSpace[y] = {}
        for x = 1, #oldHyperSpace[y] do
            newHyperSpace[y][x] = {}
        end
    end

    for y = 2, #oldHyperSpace do
        for x = 2, #oldHyperSpace[y] do
            local nbs = self:countAliveNeighbors(oldHyperSpace, x, y)

            if oldHyperSpace[y][x] then
                if nbs < args.deathLimit then
                    newHyperSpace[y][x] = false
                else
                    newHyperSpace[y][x] = true
                end
            else
                if nbs > args.birthLimit then
                    newHyperSpace[y][x] = true
                else
                    newHyperSpace[y][x] = false
                end
            end
        end
    end

    return newHyperSpace
end

function CA:generateCAMap(width, height, ...)
    local args = {...} -- Default parameters for decent map
    args.birthLimit = args.birthLimit or 4
    args.deathLimit = args.deathLimit or 3
    args.startAliveChance = args.startAliveChance or 38
    args.steps = args.steps or 10

    local hyperSpace = {}

    -- Create buffer
    for y = 1, height do
        hyperSpace[y] = {}
        for x = 1, width do
            hyperSpace[y][x] = math.random(1,100) < args.startAliveChance
        end
    end

    -- Iterate CA steps based on args
    for _ = 1, args.steps do
        hyperSpace = self:doStep(hyperSpace, args)
    end

    local map = {}

    if not hyperSpace then assert(hyperSpace, 'No CA map in hyper') return end

    -- Convert hyperSpace into mapData
    for y = 1, #hyperSpace do
        map[y] = {}
        for x = 1, #hyperSpace[y] do
            if hyperSpace[y][x] then
                map[y][x] = tileClass():createTile(false, x, y, 'wall')
            else
                map[y][x] = tileClass():createTile(false, x, y, 'floor')
            end
        end
    end

    return map
end

--- Recursively flood fill tile from start
-- For every neighbor not flooded, call _floodFill
-- until no more unfilled neighbors exist.
-- @param map
-- @param start tile to start on
-- @param list for recursion
function CA:floodFill(map, start, list)
    start._filled = true
    list = list or {}
    table.insert(list, start)

    local x = start.x
    local y = start.y

    if map[y-1] and map[y-1][x] and not map[y-1][x]:getType('wall') and not map[y-1][x]._filled then
        self:floodFill(map, map[y-1][x], list)
    end

    if map[y+1] and map[y+1][x] and not map[y+1][x]:getType('wall') and not map[y+1][x]._filled then
        self:floodFill(map, map[y+1][x], list)
    end

    if map[y] and map[y][x+1] and not map[y][x+1]:getType('wall') and not map[y][x+1]._filled then
        self:floodFill(map, map[y][x+1], list)
    end

    if map[y] and map[y][x-1] and not map[y][x-1]:getType('wall') and not map[y][x-1]._filled then
        self:floodFill(map, map[y][x-1], list)
    end

    return list
end

-- function CA:generateCARoom(width, height)
--     local birthLimit = 4
--     local deathLimit = 4
--     local startAliveChance = 50
--     local steps = 5
--
--     local map = self:generateCAMap(width, height, birthLimit, deathLimit, startAliveChance, steps)
--     local listOfFloorTiles = {}
--
--     if not map then assert(map, 'Invalid map for CA room generation') return end
--
--     for y = 1, #map do
--         for x = 1, #map[y] do
--             if map[y][x]:getType('floor') then
--                 table.insert(listOfFloorTiles, map[y][x])
--             end
--         end
--     end
--
--     -- Pick a random floor tile
--     local pickRandomTile = listOfFloorTiles[math.random(1, #listOfFloorTiles)]
--
--     -- If map is garbage, generate a new room.
--     if not pickRandomTile then return self:generateCARoom(width, height) end
--
--     -- Flood fill that tile, return table of filled tiles
--     local fill = _floodFill(map, pickRandomTile)
--
--     local room = roomClass():createRoomFromTable(width, height, fill)
--
--     room:addWallsToRoom()
--
--     return room
-- end
--
--

return CA

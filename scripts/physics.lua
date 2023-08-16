local lume = require 'libraries.lume'
local Lighting = require 'scripts.lighting'
local Physics = {}

Physics.listOfNodes = {}

function Physics:init()
    Lighting:init(self)
end

-- Register player as physics object separately
function Physics:registerPlayer(player)
    self.playerInfo = player
end

function Physics:registerMap(map)
    self.mapInfo = map

    -- Once map is loaded, we generate first dijkstra map.
    self:generateDijkstraMap()
end

-- Return true or false if movement should be processed
function Physics:checkCollisionAtDestination(destX, destY)
    local destinationTile = self:getTile(destX, destY)

    if not destinationTile then return true end

    if destinationTile.distance == math.huge then
        if destinationTile.hasObject then
            local object = destinationTile.hasObject

            if object.onCollision then
                return object.onCollision(collider)
            end
        end

        return true
    end
    return false
end

function Physics:moveTo(object, destX, destY)

    local startNode = self:getNode(object.x, object.y)
    local endNode = self:getNode(destX, destY)

    if not startNode then return end
    if not endNode then return end
    if not endNode.previous then return end

    if #object.moveQueue > 0 then return end

    local path = self:findPath(endNode, startNode, 30)

    for _, moveData in lume.ripairs(path) do
        destX = moveData.x
        destY = moveData.y

        
        -- local collision = self:checkCollisionAtDestination(destX, destY)

        -- if collision then
        --     print('collided')
        --     return
        -- end

        object.x = destX
        object.y = destY

        -- Sprite always lags behind physical object
        table.insert(object.moveQueue, {x = destX, y = destY}) 
    end


    -- self:generateDijkstraMap()
end

-- Called every :update
function Physics:processMoves()
    local playerMoveQueue = self.playerInfo.moveQueue

    -- Process move at top of heap first.
    local moveData = playerMoveQueue[1]

    if moveData then
        local xVelocity
        local yVelocity
        
        -- Target x & y position
        local tx = moveData.x*64
        local ty = moveData.y*64

        local speed = 8

        if tx > self.playerInfo.sprite.x then
            xVelocity = speed
        elseif tx < self.playerInfo.sprite.x then
            xVelocity = -speed
        end

        if ty > self.playerInfo.sprite.y then
            yVelocity = speed
        elseif ty < self.playerInfo.sprite.y then
            yVelocity = -speed
        end

        if xVelocity then
            self.playerInfo.sprite.x = self.playerInfo.sprite.x + xVelocity
        end

        if yVelocity then
            self.playerInfo.sprite.y = self.playerInfo.sprite.y + yVelocity
        end

        if self.playerInfo.sprite.x == tx and self.playerInfo.sprite.y == ty then
            self:generateDijkstraMap(tx/64, ty/64)
            table.remove(playerMoveQueue, 1)
            Lighting:calculateVisibility(self:getNode(self.playerInfo.x, self.playerInfo.y))
        end
    end
end

function Physics:findPath(start, goal, maximumCost)
    local path = {{x = start.x, y = start.y}}
    local previous = start
    local oldPrevious = start

    local actualCost = 0
    maximumCost = maximumCost or math.huge

    repeat
    oldPrevious = previous
    previous = previous.previous

    if not previous then return start end

    local costOfMove = (oldPrevious.distance - previous.distance)

    if actualCost + costOfMove > maximumCost then
        path = {{x = goal.x, y = goal.y}}
        break
    else
        actualCost = actualCost + costOfMove
        table.insert(path, {x = previous.x, y = previous.y})
    end
    until previous == goal

    return path, actualCost
end


-- Returns a list {tile, object} from tiles with objects on them.
-- function Physics:findTilesWithObjects()
--     if not self.nodes then return false end -- if nodes aren't generated.
--
--     local list = {}
--     for _, object in pairs(self.mapInfo.objects) do
--         if self.nodes[object.x/64] then
--             if self.nodes[object.x/64][(object.y/64)-1] then
--                 table.insert(list, {tile = self.nodes[object.x/64][(object.y/64)-1],obj = object})
--             end
--         end
--     end
--
--     return list
-- end

-- After we generate node map, we go back and
-- set the tile.distance of a tile that has an object
-- on it to the sum of both the tile.distance and object.
-- function Physics:processNodesWithObjects()
--     local list = self:findTilesWithObjects()
--
--     for _, data in pairs(list) do -- {tile, object}
--
--         -- Create a link to the object on the tile.
--         data.tile.hasObject = data.obj
--     end
-- end

function Physics:createNode(x, y, tileObject, dist)
    local node = {
        x = x,
        y = y,
        distance = dist or 0,
        light = {},
        tileObject = tileObject or nil,
    }

    return node
end

function Physics:generateNodeMap(player)
    self.nodes = {}

    local center_x = player.x
    local center_y = player.y

    -- Limit the tiles processed to those visible on screen
    local limit = math.floor((love.graphics.getWidth()/64)/2.6)

    -- Insert valid tile references
    for k, _ in pairs(self.mapInfo.tileInstances) do
        for _, tile in pairs(self.mapInfo.tileInstances[k]) do
            local x, y = tile.x/64, tile.y/64

            if x > center_x - limit and x < center_x + limit then
                if y > center_y - limit and y < center_y + limit then
                    self.nodes[x] = self.nodes[x] or {}
                    self.nodes[x][y] = self:createNode(x, y, tile)
                    tile.node = self.nodes[x][y]

                    Lighting:initializeNodeLight(tile)
                    -- tile.light = tile.light or {}
                    -- tile.light.r = tile.light.r or 0
                    -- tile.light.g = tile.light.g or 0
                    -- tile.light.b = tile.light.b or 0
                    -- tile.light.a = tile.light.a or 255
                    -- tile.light.flicker = tile.light.flicker or 0
                end
            end
        end
    end
end

function Physics:getNode(x, y)
    return self.nodes[x] and self.nodes[x][y]
end

function Physics:getAllNodes()
    local listOfNodes = {}

    for x, _ in pairs(self.nodes) do
        for _, node in pairs(self.nodes[x]) do
            if node then
                table.insert(listOfNodes, node)

            end
        end
    end

    return listOfNodes
end

function Physics:distance(nodeA, nodeB, costOfMove)
    local dx, dy = nodeA.x - nodeB.x, nodeA.y - nodeB.y
    return (costOfMove or 1) * (math.abs(dx) + math.abs(dy))
end

function Physics:getMapValue(node)
    if node.tileObject.layer.name == 'wall' then
        return math.huge
    else
        return 1
    end
end

function Physics:generateDijkstraMap(custom_x, custom_y)
    local x = custom_x or self.playerInfo.x
    local y = custom_y or self.playerInfo.y

    -- Generate nodes from tiles based on player position
    self:generateNodeMap(self.playerInfo)

    local currentTile = self.nodes[x][y]

    -- Assign node values using Dijsktra algorithm
    self:dijkstra(currentTile, self.playerInfo)
end

local cardinalVectors = {{x = 0, y = -1}, {x = -1, y = 0}, {x = 1, y = 0}, {x = 0, y = 1}}
function Physics:getNeighbors(n)
    local neighbors = {}

    for _, axis in ipairs(cardinalVectors) do
        local x, y = n.x + axis.x, n.y + axis.y
        table.insert(neighbors, self:getNode(x, y))
    end

    return neighbors
end

function Physics:dijkstra(source, player)
    self.debug = love.timer.getTime()
    
    local listOfNodes = self:getAllNodes() -- Get list of all nodes
    for _, node in ipairs(listOfNodes) do
        node.distance = math.huge
        node.previous = nil
    end


    self.debugText = #listOfNodes
    source.distance = 0
    table.sort(listOfNodes, function(nodeA, nodeB) return nodeA.distance < nodeB.distance end)


    while (#listOfNodes > 0) do

        -- Pop first node in heap to currentNode
        local currentNode = listOfNodes[1]
        table.remove(listOfNodes, 1)



        if currentNode.distance == math.huge then break end

        -- Process distance weights for all cardinal neighbors.
        -- Since source is not a neighbor, it will have no previous
        -- Once every neighbor is calculated, sort listOfNods to push
        -- unprocessed nodes to top of stack to be popped.
        local neighbors = self:getNeighbors(currentNode)
        for _, neighborNode in ipairs(neighbors) do
            local costOfMoveToNeighborNode = self:getMapValue(neighborNode)
            local distanceToNeighborNode = self:distance(currentNode, neighborNode, costOfMoveToNeighborNode)
            local alt = currentNode.distance + distanceToNeighborNode

            Lighting:calculateNodeLight(neighborNode, player.viewDistance) 

            if alt < neighborNode.distance then
                neighborNode.distance = alt
                neighborNode.previous = currentNode
                table.sort(listOfNodes, function(nodeA, nodeB) return nodeA.distance < nodeB.distance end)
            end
        end
    end

    collectgarbage()

    -- self.debugText = self.debug - love.timer.getTime()
    self.debug = 0
    
end

function Physics:update(dt)
    self:processMoves()
end

return Physics


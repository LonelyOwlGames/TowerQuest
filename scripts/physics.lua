local lume = require 'libraries.lume'
local Physics = {}

Physics.listOfNodes = {}


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

    local path = self:findPath(endNode, startNode)

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
        end
    end
end

function Physics:findPath(start, goal, maximumCost)
    local path = {{x = start.x, y = start.y}}
    local previous, oldPrevious = start

    local actualCost = 0
    maximumCost = maximumCost or math.huge

    repeat
    oldPrevious = previous
    previous = previous.previous

    if not previous then return start end

    local costOfMove = (oldPrevious.distance - previous.distance)
    
    if actualCost + costOfMove > maximumCost then
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

function Physics:generateNodeMap(center_x, center_y)
    self.nodes = {}

    -- Insert valid tile references
    for k, _ in pairs(self.mapInfo.tileInstances) do
        for _, tile in pairs(self.mapInfo.tileInstances[k]) do
            local x, y = tile.x/64, tile.y/64
            
            if x > center_x - 10 and x < center_x + 10 then
                if y > center_y - 10 and y < center_y + 10 then
                    self.nodes[x] = self.nodes[x] or {}
                    self.nodes[x][y] = self:createNode(x, y, tile)
                    tile.node = self.nodes[x][y]

                    tile.light = tile.light or {}
                    tile.light.r = tile.light.r or 0
                    tile.light.g = tile.light.g or 0
                    tile.light.b = tile.light.b or 0
                    tile.light.a = tile.light.a or 255
                    tile.light.flicker = tile.light.flicker or 0
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

-- function Physics:flicker(node, dt)
--     node.light.flicker = node.light.flicker + dt
--
--     if node.light.flicker > node.light.tick then
--         node.light.r = math.random(200,250)
--         node.light.g = math.random(80,110)
--         node.light.b = math.random(0,15)
--         node.light.a = 25
--     end
--
--     node.light.tick = math.random(0.2,0.8) 
-- end

-- function Physics:flickerInit(node)
--     node.light.flicker = 0
--     node.light.tick = 0
--     table.insert(self.listOfFlickeringTiles, node)
-- end
--
-- function Physics:processListOfTorches()
--     self.listOfTorches = {}
--     self.listOfFlickeringTiles = {}
--
--     for x, _ in pairs(self.nodes) do
--         for _, node in pairs(self.nodes[x]) do
--             if node.id and node.seen and node.gid == 97 then
--                 table.insert(self.listOfTorches, node)
--                 self:flickerInit(node) 
--
--                 for _, neighborNode in pairs(node.neighbors) do
--                     if neighborNode.y >= node.y and neighborNode.seen then
--                         self:flickerInit(neighborNode) 
--
--                         for _, neighborNeighborNode in pairs(neighborNode.neighbors) do
--                             if neighborNeighborNode.y >= node.y and neighborNeighborNode.seen then
--                                 self:flickerInit(neighborNeighborNode) 
--                             end
--                         end
--                     end
--                 end
--             end
--         end
--     end
-- end
--
-- function Physics:updateFlickeringLights(dt)
--     for _, node in pairs(self.listOfFlickeringTiles) do
--         self:flicker(node, dt)
--     end
-- end
--
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
--     if node.layer.name == "wall" then
--         return math.huge
--     elseif node.hasObject and node.hasObject.name == 'door' then
--         if not node.hasObject.properties.isDoorOpen then
--             return math.huge
--         else
--             return basic
--         end
--     elseif node.layer.name == 'entities' then
--         return math.huge
--     else
--         return basic
--     end
-- end
end
--
function Physics:lightByAdjacentNodes(node)
    -- BUG: For some reason having a floor underneath a wall tile causes node.light to be nil.

    local light = node.tileObject.light

    light.a = 255

    local average = 0
    local averageCount = 0

    local neighbors = self:getNeighbors(node)
    if neighbors then
        for i = 1, #neighbors do
            if neighbors[i].tileObject.layer.name == 'floor' and neighbors[i].tileObject.seen then
                average = average + neighbors[i].tileObject.light.a
                averageCount = averageCount + 1
            end
        end

        average = average/averageCount
    end
    
    if averageCount == 0 then average = 255 end
    light.a = (math.floor(average))
    -- Since walls (or non-floors) are handled exclusively,
    -- we need to also handle .seen property here.
    if light.a < (255) then
        node.tileObject.seen = true
    end
end

function Physics:lightUpWallNodes()
    for x, _ in pairs(self.nodes) do
        for y, node in pairs(self.nodes[x]) do
            if node.tileObject.light then
                
                if node.tileObject.layer.name == 'wall' then
                    Physics:lightByAdjacentNodes(node)
                end
            end
        end
    end


    for _, node in pairs(self.listOfNodes) do
        -- BUG: For some reason having a floor underneath a wall tile causes node.light to be nil.
        if not node.light then print(node.x/64, node.y/64) error('Found wall with floor underneath. Fix in Tiled.') end

       
        -- If node is not a floor, then light by adjacent floor lighting
        if node.layer.name == 'wall' and node.light.a >= 51 then
            lightByAdjacentNodes(node)
        end

        if node.hasObject then
            lightByAdjacentNodes(node)
        end
    end
end


function Physics:generateDijkstraMap(custom_x, custom_y)
    local x = custom_x or self.playerInfo.x
    local y = custom_y or self.playerInfo.y

    self:generateNodeMap(x, y)

    local currentTile = self.nodes[x][y]

    self:dijkstra(currentTile)
    -- self:processNodesWithObjects()

    -- Special calculation for lighting on wall tiles.
    self:lightUpWallNodes()
    -- self:processListOfTorches()
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

function Physics:dijkstra(source)
    local listOfNodes = self:getAllNodes() -- Get list of all nodes
    for _, node in ipairs(listOfNodes) do
        node.distance = math.huge
        node.previous = nil
    end

    source.distance = 0
    table.sort(listOfNodes, function(nodeA, nodeB) return nodeA.distance < nodeB.distance end)


    while (#listOfNodes > 0) do
        local currentNode = listOfNodes[1]
        table.remove(listOfNodes, 1)

        -- If distance < 15, adjust lighting. If distance < 11, mark tile as "seen" for minimap
        if currentNode.distance < 10 then
            currentNode.tileObject.light.a = math.max(currentNode.tileObject.light.a + (currentNode.distance-math.random(25,75)), 25)
            if currentNode.distance < 9 then
                currentNode.tileObject.seen = true
            end
        end

		-- If node is not proceesed, break. (straggler nodes along edges)
        if currentNode.distance == math.huge then break end

        local neighbors = self:getNeighbors(currentNode)
        for _, neighborNode in ipairs(neighbors) do
            local costOfMoveToNeighborNode = self:getMapValue(neighborNode)
            local distanceToNeighborNode = self:distance(currentNode, neighborNode, costOfMoveToNeighborNode)
            local alt = currentNode.distance + distanceToNeighborNode

            if alt < neighborNode.distance then
                neighborNode.distance = alt
                neighborNode.previous = currentNode
                table.sort(listOfNodes, function(nodeA, nodeB) return nodeA.distance < nodeB.distance end)
            end
        end
    end
end

function Physics:update(dt)
    -- self:updateFlickeringLights(dt)
    self:processMoves()
end



return Physics


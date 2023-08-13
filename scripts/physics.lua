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
function Physics:checkCollisionAtDestination(collider)
    local x, y = collider.x, collider.y
    local destinationTile = self:getTile(x, y)
    if destinationTile.distance > 10 then
        if destinationTile.hasObject then
            local object = destinationTile.hasObject

            if object.onCollision then
                object.onCollision(collider)
                return true
            end

            if object.properties.isDoor then
                object.properties.isDoorOpen = true
                return false
            end
        end

        return true
    end
end

function Physics:moveTo(object, x, y)
    local oldx, oldy = object.x, object.y

    object.x = x
    object.y = y

    -- If collision occurs, revert change
    if Physics:checkCollisionAtDestination(object) then
        object.x = oldx
        object.y = oldy
    end

    self:generateDijkstraMap()
end

function Physics:move(object, direction)
    -- Save current x, y to revert if move fails.
    local oldx, oldy = object.x, object.y

    if direction == 'up' then
        object.y = object.y - 1
    end

    if direction == 'down' then
        object.y = object.y + 1
    end

    if direction == 'left' then
        object.x = object.x - 1
    end

    if direction == 'right' then
        object.x = object.x + 1
    end

    -- Check collision at destination
    if self:checkCollisionAtDestination(object) then
        object.x = oldx
        object.y = oldy
    end


    self:generateDijkstraMap()
    -- Do turn
end

-- Returns a list {tile, object} from tiles with objects on them.
function Physics:findTilesWithObjects()
    if not self.nodes then return false end -- if nodes aren't generated.

    local list = {}
    for _, object in pairs(self.mapInfo.objects) do
        if self.nodes[object.x/64] then
            if self.nodes[object.x/64][(object.y/64)-1] then
                table.insert(list, {tile = self.nodes[object.x/64][(object.y/64)-1],obj = object})
            end
        end
    end

    return list
end

-- After we generate node map, we go back and
-- set the tile.distance of a tile that has an object
-- on it to the sum of both the tile.distance and object.
function Physics:processNodesWithObjects()
    local list = self:findTilesWithObjects()

    for _, data in pairs(list) do -- {tile, object}

        -- Create a link to the object on the tile.
        data.tile.hasObject = data.obj
    end
end

function Physics:generateNodeMap(center_x, center_y)
    self.nodes = {}
    self.listOfNodes = {}

    -- Only run calculations on 20x20 grid to save CPUI
    for x=(center_x - 10), (center_x + 10) do
        self.nodes[x] = {}
        for y=(center_y - 10), (center_y + 10) do
            self.nodes[x][y] = {}
        end
    end

    -- Insert valid tile references
    for k, _ in pairs(self.mapInfo.tileInstances) do
        for _, tile in pairs(self.mapInfo.tileInstances[k]) do
            if self.nodes[tile.x/64] then
                if self.nodes[tile.x/64][tile.y/64] then
                    if tile.layer.name == "floor" or tile.layer.name == "wall" then
                        self.nodes[tile.x/64][tile.y/64] = tile
                        table.insert(self.listOfNodes, tile)
                    end
                end
            end
        end
    end
end

function Physics:getTile(tx, ty)
    if self.nodes[tx] then
        if self.nodes[tx][ty] then
            if self.nodes[tx][ty].id then
                return self.nodes[tx][ty]
            end
        end
    end

    return false
end

function Physics:generateNodeNeighbors()
    for x, _ in pairs(self.nodes) do
        for y, node in pairs(self.nodes[x]) do
            if node.id then
                node.neighbors = {}

                local up = self:getTile(x, y-1)
                local down = self:getTile(x, y+1)
                local left = self:getTile(x-1, y)
                local right = self:getTile(x+1, y)

                if up then table.insert(node.neighbors, up) end
                if down then table.insert(node.neighbors, down) end
                if left then table.insert(node.neighbors, left) end
                if right then table.insert(node.neighbors, right) end
            end
        end
    end
end

function Physics:getAllNodes()
    local nodes = {}
    for x, _ in pairs(self.nodes) do
        for _, node in pairs(self.nodes[x]) do
            if node.id then
                table.insert(nodes, node)

                -- Initialize light on all nodes
                node.light = node.light or 255
            end
        end
    end

    return nodes
end

function Physics:distance(nodeA, nodeB, cost)
    return 1 + cost
end

function Physics:getMapValue(node)
    local basic = 1
    if node.layer.name == "wall" then
        return math.huge
    elseif node.hasObject and node.hasObject.name == 'door' then
        if not node.hasObject.properties.isDoorOpen then
            return math.huge
        else
            return basic
        end
    else
        return basic
    end
end

local function lightByAdjacentNodes(node, modifier)
    -- Set starting opacity to black
    local opacity = 255

    if node.neighbors then
        for i = 1, #node.neighbors do
            if node.neighbors[i].layer.name == 'floor' then
                opacity = opacity + (node.neighbors[i].light) - math.random(150,200)
            end
        end
    end

    node.light = opacity

    -- Since walls (or non-floors) are handled exclusively,
    -- we need to also handle .seen property here.
    if node.light < (255) then
        -- If the node's light has been modified, it's seen.
        node.seen = true
    end
end

function Physics:lightUpWallNodes()
    for _, node in pairs(self.listOfNodes) do
        
        -- If node is not a floor, then light by adjacent floor lighting
        if node.layer.name == 'wall' then
            lightByAdjacentNodes(node, 0)
        end

        if node.hasObject then
            lightByAdjacentNodes(node, 75)
        end
    end
end


function Physics:generateDijkstraMap()
    local x, y = self.playerInfo.x, self.playerInfo.y
    self:generateNodeMap(x, y)
    self:generateNodeNeighbors()

    local currentTile = self.nodes[x][y]

    self:dijkstra(currentTile)
    self:processNodesWithObjects()

    -- Special calculation for lighting on wall tiles.
    self:lightUpWallNodes()
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
        if currentNode.distance < 15 then
            currentNode.light = math.max(currentNode.light + (currentNode.distance-math.random(25,75)), 0)
            if currentNode.distance < 11 then
                currentNode.seen = true
            end
        end

		-- If node is not proceesed, break. (straggler nodes along edges)
        if currentNode.distance == math.huge then break end

        local neighbors = currentNode.neighbors
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

return Physics


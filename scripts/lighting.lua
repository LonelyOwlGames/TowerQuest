local lume = require 'libraries.lume'
local Lighting = {}

function Lighting:init(physics)

    -- Initialize physics module
    self.Physics = physics

    self.listOfLightNodes = {}

    self.lightNodeMap = {}
    self.lightNodeMap[97] = {
        name = 'Torch',
        radius = 4,
        yLocked = true,
        color = {
            r = 200,
            g = 80,
            b = 0,
            a = 25
        }
    }
end

function Lighting:flicker(node, dt)
    local tile = node.tileObject

    tile.light.flicker = tile.light.flicker + dt

    if tile.light.flicker > tile.light.tick then
        tile.light.r = math.random(200,250)
        tile.light.g = math.random(80,110)
        tile.light.b = math.random(0,15)
        tile.light.a = 25
    end

    tile.light.tick = math.random(0.2,0.8) 
end

function Lighting:flickerInit(node)
    local tile = node.tileObject

    tile.light.flicker = 0
    tile.light.tick = 0
    table.insert(self.listOfFlickeringTiles, node)
end

function Lighting:processListOfTorches()
    self.listOfTorches = {}
    self.listOfFlickeringTiles = {}

    -- for x, _ in pairs(self.nodes) do
    --     for _, node in pairs(self.nodes[x]) do
    --         local tile = node.tileObject
    --         if tile.seen and tile.gid == 97 then
    --             table.insert(self.listOfTorches, node)
    --             self:flickerInit(node)
    --
    --
    --             -- local neighbors = self:getNeighbors(node)
    --             
    --             -- for _, neighborNode in pairs(neighbors) do
    --             --     if neighborNode.y >= node.y then 
    --             --         self:flickerInit(neighborNode)
    --             --
    --             --         local neighborNeighbors = self:getNeighbors(neighborNode)
    --             --         for _, neighborNeighborNode in pairs(neighborNeighbors) do
    --             --             if neighborNeighborNode.y >= node.y then
    --             --                 self:flickerInit(neighborNeighborNode)
    --             --             end
    --             --         end
    --             --     end
    --             -- end
    --         end
    --     end
    -- end
end

function Lighting:updateFlickeringLights(dt)
    for _, node in pairs(self.listOfFlickeringTiles) do
        self:flicker(node, dt)
    end
end

function Lighting:calculateNodeLightByAdjacent(node)
    local light = node.tileObject.light


    local average = 0
    local averageCount = 0

    local neighbors = self.Physics:getNeighbors(node)
    if neighbors then
        for i = 1, #neighbors do
            if not (neighbors[i].tileObject.layer.name == 'wall') and neighbors[i].tileObject.seen then
                average = average + neighbors[i].tileObject.light.a
                averageCount = averageCount + 1
            end
        end

        average = average/averageCount
    end

    -- Set lightmap opacity based on neighboring node opacity average
    if averageCount == 0 then average = 255 end
    light.a = (math.floor(average))

    -- Assign 'seen' property to tiles manually
    if light.a < (255) then
        node.tileObject.seen = true
    end
end

function Lighting:calculateVisibility(node)
    local tile = node.tileObject

    local tx, ty = node.tileObject.x, node.tileObject.y

    for i = 1, 360 do
        local ox, oy = tx + 0.5, ty + 0.5
        local rad = math.rad(i)
        local rx, ry = math.cos(rad), math.sin(rad)

        for i = 1, 12 do
            local target

            if self.Physics.nodes[math.floor(ox/64)] then
                if self.Physics.nodes[math.floor(ox/64)][math.floor(oy/64)] then
                    target = self.Physics.nodes[math.floor(ox/64)][math.floor(oy/64)]
                end
            end
            if target then 
                    
            local targetTile = target.tileObject
            
            targetTile.light.a = 150
            end
            ox = ox + rx
            oy = oy + ry
        end
    end
            

end


function Lighting:calculateNodeLight(node, viewDistance)





    if true then return end
    local light = node.tileObject.light
    local litAlpha = 50
    local seenAlpha = 150
    local unSeenAlpha = 255
    local currentAlpha = light.a
    local amount = 0.1

    if node.distance < viewDistance + 4 then
        light.a = lume.lerp(currentAlpha, litAlpha, amount*2)
        node.tileObject.seen = true
    end

    if node.distance > viewDistance and node.distance < viewDistance + 4 then
        if node.tileObject.seen then
            light.a = lume.lerp(currentAlpha, seenAlpha, amount)
        else
            light.a = lume.lerp(currentAlpha, unSeenAlpha, amount)
        end
    end

    if node.tileObject.layer.name == 'wall' then
        self:calculateNodeLightByAdjacent(node)
    end


    -- If a new exists that should behave as a lightNode, and is visible to the player
    -- insert it into listOfLightNodes to be processed and rendered. (Only if not already added)
    if self.lightNodeMap[node.tileObject.gid] and node.tileObject.seen then
        self:buildLightSource(node)
    end
end

function Lighting:getNodesInRadius(source, radius)

end

-- Called on source nodes of light sources
function Lighting:buildLightSource(node)


end


function Lighting:initializeNodeLight(tile)
    tile.light = tile.light or {}
    tile.light.r = tile.light.r or 0
    tile.light.g = tile.light.g or 0
    tile.light.b = tile.light.b or 0
    tile.light.a = tile.light.a or 255
    tile.light.flicker = tile.light.flicker or 0
end


function Lighting:update()

end

return Lighting

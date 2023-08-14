local lume = require 'libraries.lume'
local Lighting = {}

function Lighting:init(physics)

    -- Initialize physics module
    self.Physics = physics
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

    light.a = 255

    local average = 0
    local averageCount = 0

    local neighbors = self.Physics:getNeighbors(node)
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

function Lighting:lightUpWallNodes()
    for x, _ in pairs(self.nodes) do
        for y, node in pairs(self.nodes[x]) do
            if node.tileObject.light then
                
                if node.tileObject.layer.name == 'wall' then
                    Physics:lightByAdjacentNodes(node)
                end
            end
        end
    end
end

function Lighting:calculateNodeLight(node, viewDistance)
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
    -- Since walls are set to math.huge, we have to calculate them separately
end





function Lighting:processCalculateLighting()

end

function Lighting:update()

end

return Lighting

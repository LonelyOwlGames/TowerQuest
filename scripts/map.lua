local sti = require 'libraries/sti'
local bitser = require 'libraries.bitser'
local ProcGen = require 'scripts.procedural'
local Dungeon = require 'scripts.class.dungeonClass'

local map = {}

-------------------------------------------------------------------
-- This system is responsible for recieving generated map data
-- and translating it into a visual and physical map.
-------------------------------------------------------------------
require('love.math')

local threadCode = [[
    require('love')
    local Dungeon = require 'scripts.class.dungeonClass'
    require('love.timer')

    local preview = true
    local width, height = ...

    local newDungeon = Dungeon(width/22, height/22)
    while newDungeon:getDensity() < newDungeon.maxDensity do
        newDungeon:buildDungeon(preview) 
        love.thread.getChannel('load'):push({newDungeon:getDensity(), newDungeon.maxDensity, newDungeon.numberOfRooms})

        local serialized = newDungeon:serialize(newDungeon)
        love.thread.getChannel('info'):push({serialized, 'dungeon', (newDungeon.numberOfRooms/newDungeon.maxDensity)})
    end

    count = 0
    while (count < newDungeon.maxDensity) do
        count = count + 1
        local changes = newDungeon:doorTest(count)
        love.thread.getChannel('load'):push({count, newDungeon.maxDensity})
        
        local serialized = newDungeon:serialize(newDungeon)
        love.thread.getChannel('info'):push({serialized, 'doors', changes})
    end

   
    local serialized = newDungeon:serialize(newDungeon)

    love.thread.getChannel('info'):push({serialized, 'done'})

]]

local thread
local timer = 0

function map:init()
    self.tileSize = 64
    self.tileset = love.graphics.newImage('tilemap/Tileset.png')

    local tile = love.graphics.newQuad(0 * self.tileSize, 0 * self.tileSize, self.tileSize, self.tileSize, self.tileset:getWidth(), self.tileset:getHeight())

    self.spriteBatch = love.graphics.newSpriteBatch(self.tileset, 25 * 23)
    self.spriteBatchLayer = love.graphics.newSpriteBatch(self.tileset, 25 * 23)

    self.thread = love.thread.newThread(threadCode)
    self.thread:start(love.graphics.getWidth(), love.graphics.getHeight())

    self.spriteBatchBackground = love.graphics.newSpriteBatch(self.tileset, 25 * 23)

    for y = 1, 300 do
        for x = 1, 300 do
            local quad = self:_createTile({type = 'wall'})
            
            self.spriteBatchBackground:add(quad, x*64, y*64)
        end
    end
            
end

-- Passing cinema right now, need to decouple later
function map:update(dt, cinema)
    timer = timer + dt
    local info = love.thread.getChannel('info'):pop()


    if info and info[2] == 'dungeon' then
        local scale = math.max(0.3, math.min(0.5/(info[3]*2), 1.5))
        -- cinema:setCameraProperty('debug', 'scale', scale)
        cinema:smoothScale('debug', scale)
        self.changes = {}
        self.oldMapData = self.mapData
        self.mapData = info[1]
        self.stage = 'dungeon'
        self:load(cinema)
        self.changes = {}
    end

    if info and info[2] == 'doors' then
        self.stage = 'doors'
        for key, value in pairs(info[3]) do
            self.changes[key] = value
        end
        self.oldMapData = self.mapData
        self.mapData = info[1]
        self:load()
        cinema:panToPosition('debug', {25*64,15*64})
    end

    if info and info[2] == 'done' then
        self.changes = {}
        self:load()
    end
end

function map:load(cinema)

    if self.mapData and self.oldMapData then
        if self.stage == 'dungeon' then
            local oldTiles = {}
            local newTiles = {}

            local data = bitser.loads(self.mapData)

            for _, room in pairs(data) do
                for _, tile in pairs(room.tiles) do
                    table.insert(newTiles, tile)
                end
            end

            local data = bitser.loads(self.oldMapData)

            for _, room in pairs(data) do
                for _, tile in pairs(room.tiles) do
                    table.insert(oldTiles, tile)
                end
            end

            table.sort(oldTiles, function(a,b) return a.id < b.id end)
            table.sort(newTiles, function(a,b) return a.id < b.id end)

            -- Treat each table as a stack.
            -- Pop top element and compare.
            -- If the top element does not match, sent
            -- new tiles pop to changed stack
            -- then pop another tile from new tiles
            -- once they both match, discard both
            -- and pop more
            local function findChanges(oldTile)
                if #oldTiles <= 0 then return end

                local newTile
                if not oldTile then
                    oldTile = oldTiles[1]
                    newTile = newTiles[1]

                    table.remove(oldTiles, 1)
                    table.remove(newTiles, 1)
                else
                    newTile = newTiles[1]
                    table.remove(newTiles,1)
                end

                if oldTile.id == newTile.id then
                    findChanges() -- no changes
                end

                if oldTile.id ~= newTile.id then
                    -- table.insert(changes, newTile)
                    self.changes[newTile.id] = true
                    findChanges(oldTile)
                end
            end

            if self.stage == 'dungeon' then
                findChanges()
            end
        end
    end

    if self.mapData then
        self.spriteBatch:clear()
        local data = bitser.loads(self.mapData)

        for roomid, room in pairs(data) do
            for _, tile in pairs(room.tiles) do
                local quad = self:_createTile(tile)
                local tx, ty = tile.wx, tile.wy

                -- Jesus christ I'm a fucking wizard
                if tile.type ~= 'empty' then --and tile.type ~= 'door' then
                    if self.changes[tile.id] then
                        -- cinema:setCameraProperty('debug', 'x', tile.x*64) 
                        if cinema and self.stage == 'dungeon' then
                            cinema:panToPosition('debug', {tile.wx*64, tile.wy*64})
                        end

                        
                        if self.stage == 'dungeon' then
                        self.spriteBatch:setColor(0.2,0.8,0.2,0.8)
                        elseif self.stage == 'doors' then
                        self.spriteBatch:setColor(1,0.3,0.1,1)
                        end
                    else
                        self.spriteBatch:setColor(1,1,1,1)
                    end

                    local id = self.spriteBatch:add(quad, tx*64, ty*64)
                end
            end
        end
    end
end

function map:reload()
end

local shaderCode = [[
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 pixel = Texel(texture, texture_coords);

    // Define artificial lighting color
    vec3 lightColor = vec3(1.0, 1.0, 0.8); // Adjust the light color as needed

    // Calculate the distance from the center of the screen
    vec2 screenCenter = vec2(1920 / 2.0, 1080 / 2.0);
    float distanceToCenter = distance(screen_coords, screenCenter);

    // Apply atmospheric coloring based on the distance to the center
    vec3 atmosphericColor = mix(vec3(0.0, 0.0, 0.0), vec3(0.9, 0.7, 0.7), distanceToCenter / (1920 / 2.0));

    // Apply artificial lighting by combining the original color with the light color
    pixel.rgb = mix(pixel.rgb, lightColor, 0.005); // Adjust the lighting intensity (0.5) as needed

    // Apply atmospheric coloring
    pixel.rgb += atmosphericColor/4;

    return pixel * color;
}]]
local shader = love.graphics.newShader(shaderCode)

local progress = 0
local roomsLoaded = 0
function map:draw()

    love.graphics.clear()
    -- Draw map outline
    -- love.graphics.rectangle('line', -200, -400, 64*50, 64*50)

    love.graphics.setShader(shader)
    love.graphics.setColor(1,1,1,0.5)
    love.graphics.draw(self.spriteBatchBackground, -1280, -1280)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(self.spriteBatch)
    love.graphics.draw(self.spriteBatchLayer)
    love.graphics.setShader()

end

local GID = {
    ['floor'] = 25,
    ['wall'] = 4,
    ['empty'] = 40,
    ['door'] = 8,
    ['room'] = 22,
    ['black'] = 112,
}

function map:_createTile(tile)
    local gid = GID[tile.type] or assert(tile.type, 'map: _createTile | tile missing type property')

    -- Convert GID to spriteBatch x & y coordinates.
    local line = math.floor(gid/25)
    local x = gid - (line * 25)
    local y = line

    -- Create a Quad based on tile data for rendering spritebatch
    local quad = love.graphics.newQuad(x*64, y*64, 64, 64, self.tileset:getWidth(), self.tileset:getHeight())

    return quad
end

return map

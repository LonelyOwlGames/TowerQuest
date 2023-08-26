local sti = require 'libraries/sti'
local bitser = require 'libraries.bitser'
local ProcGen = require 'scripts.procedural'
local Dungeon = require 'scripts.class.dungeonClass'
local threadCode = require 'scripts.thread'

local map = {}

-------------------------------------------------------------------
-- This system is responsible for recieving generated map data
-- and translating it into a visual and physical map.
-------------------------------------------------------------------
require('love.math')


local thread
local timer = 0

function map:init()
    self.tileSize = 64
    self.tileset = love.graphics.newImage('tilemap/Tileset.png')

    self.spriteBatch = love.graphics.newSpriteBatch(self.tileset, 25 * 24)
    self.spriteBatchBackground = love.graphics.newSpriteBatch(self.tileset, 25 * 23)

    self.thread = love.thread.newThread(threadCode)
    self.thread:start()

    self.changes = {}
    self.previousChanges = {}

    -- Initialize background tilemap
    for y = -150, 300 do
        for x = -150, 300 do
            local quad = self:_createTile({type = 'wall'})

            self.spriteBatchBackground:add(quad, x*64, y*64)
        end
    end
end

-- Passing cinema right now, need to decouple later
function map:update(dt, cinema)
    timer = timer + dt

    local info = love.thread.getChannel('info'):pop()

    -- Executed when a change is popped from the stack.
    if info and info[2] then
        if info then
            local data = bitser.loads(info[2])

            for _, change in pairs(data) do
                table.insert(self.changes, {type = info[1], data = change})
            end

            self:load()
        end

        cinema:setArg('UI', 'state', 'Generating..')
        cinema:setCameraProperty('debug', 'scale', 0.1)
    end

    if info and info[1] == 'done' then
        -- error('done')
    end

    -- Iterate over list of previous changes, and change tile color one at a time.
    if #self.previousChanges > 0 then
        for i = 1, #self.previousChanges / 10 + 2 do
            local change = self.previousChanges[i]
            table.remove(self.previousChanges, i)

            if change then 
                self.spriteBatch:setColor(1,1,1,1)
                self.spriteBatch:set(change.id, change.quad, change.tile.wx*64, change.tile.wy*64)
            end
        end
    end
end

function map:load()
    if #self.changes > 0 then
        local changes = self.changes[1]
        table.remove(self.changes, 1)

        if changes.type == 'room' then
            for _, tile in pairs(changes.data.tiles) do
                local quad = self:_createTile(tile)
                local tx, ty = tile.wx, tile.wy

                if tile.type ~= 'empty' then
                    self.spriteBatch:setColor(0,0,0,0.3)

                    local id = self.spriteBatch:add(quad, tx*64, ty*64)
                    table.insert(self.previousChanges, {id = id, quad = quad, tile = tile})
                end
            end
        end

        if changes.type == 'tile' then
            local quad = self:_createTile(changes.data)
            local tx, ty = changes.data.wx, changes.data.wy

            -- if changes.data.type ~= 'empty' then
                self.spriteBatch:setColor(1,0,0,1)

                local id = self.spriteBatch:add(quad, tx*64, ty*64)
                table.insert(self.previousChanges, {id = id, quad = quad, tile = changes.data})
            -- end
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

function map:draw()

    love.graphics.clear()
    love.graphics.setShader(shader)
    love.graphics.setColor(1,1,1,0.5)
    love.graphics.draw(self.spriteBatchBackground, -1280, -1280)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(self.spriteBatch)
    love.graphics.setShader()

end

local GID = {
    ['floor'] = 25,
    ['wall'] = 4,
    ['empty'] = 40,
    ['door'] = 8,
    ['room'] = 22,
    ['black'] = 112,
    ['fill'] = 325,
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

local sti = require 'libraries/sti'
local ProcGen = require 'scripts.procedural'

local map = {}

-------------------------------------------------------------------
-- This system is responsible for recieving generated map data
-- and translating it into a visual and physical map.
-------------------------------------------------------------------

function map:init()

    self.tileSize = 64
    self.tileset = love.graphics.newImage('tilemap/Tileset.png')

    local tile = love.graphics.newQuad(0 * self.tileSize, 0 * self.tileSize, self.tileSize, self.tileSize, self.tileset:getWidth(), self.tileset:getHeight())

    self.spriteBatch = love.graphics.newSpriteBatch(self.tileset, 25 * 23)

    local mapData = ProcGen:createNewMap()

    self:load(mapData)
end

function map:load(mapData)
    for y = 1, #mapData do
        for x = 1, #mapData[y] do
            if mapData[y][x] and mapData[y][x].type ~= 'empty' then
                local tile = self:_createTile(mapData[y][x])

                self.spriteBatch:add(tile, x*64, y*64)
            end

            if mapData[y][x] and mapData[y][x].type == 'empty' then
                mapData[y][x].type = 'empty'
                local tile = self:_createTile(mapData[y][x])

                self.spriteBatch:add(tile, x*64, y*64)
            end
        end
    end
end

function map:reload()
    local mapData = ProcGen:createNewMap()

    self.spriteBatch:clear()
    self:load(mapData)
end

function map:update(dt)

end

function map:draw()
    love.graphics.draw(self.spriteBatch, -200, -400)
end

local GID = {
    ['floor'] = 25,
    ['wall'] = 4,
    ['empty'] = 40,
    ['door'] = 8,
    ['room'] = 22,
}

function map:_createTile(cell)
    local gid = GID[cell.type] or assert(cell.type, 'map: _createTile | cell missing type property')

    -- Convert GID to spriteBatch x & y coordinates.
    local line = math.floor(gid/25)
    local x = gid - (line * 25)
    local y = line

    -- Create a Quad based on cell data for rendering spritebatch
    local quad = love.graphics.newQuad(x*64, y*64, 64, 64, self.tileset:getWidth(), self.tileset:getHeight())

    return quad
end

return map

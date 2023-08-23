local sti = require 'libraries/sti'
local bitser = require 'libraries.bitser'
local ProcGen = require 'scripts.procedural'
local Dungeon = require 'scripts.class.dungeonClass'

local map = {}

-- CourseScene
-- -Door
-- EventSystem
-- PlayerClass
-------------------------------------------------------------------
-- This system is responsible for recieving generated map data
-- and translating it into a visual and physical map.
-------------------------------------------------------------------
require('love.math')

local threadCode = [[
    require('love')
    local Dungeon = require 'scripts.class.dungeonClass'
    require('love.timer')


    local min, max = ...
    local newDungeon = Dungeon()
    while newDungeon:getDensity() < newDungeon.maxDensity do
        newDungeon:buildDungeon() 
        love.thread.getChannel('load'):push({newDungeon:getDensity(), newDungeon.maxDensity})
    end

   
    local serialized = newDungeon:serialize(newDungeon)

    love.thread.getChannel('info'):push(serialized)

]]

local thread
local timer = 0

function map:init()
    self.tileSize = 64
    self.tileset = love.graphics.newImage('tilemap/Tileset.png')

    local tile = love.graphics.newQuad(0 * self.tileSize, 0 * self.tileSize, self.tileSize, self.tileSize, self.tileset:getWidth(), self.tileset:getHeight())

    self.spriteBatch = love.graphics.newSpriteBatch(self.tileset, 25 * 23)

    self.thread = love.thread.newThread(threadCode)
    self.thread:start()
end

function map:update(dt)
    timer = timer + dt
    local info = love.thread.getChannel('info'):pop()

    if info and not self.mapData then
        self.mapData = info
        self:load()
    end
end

function map:load(mapData)
    -- mapData
    -- -- [roomId] = tiles
    --         [tiles] = {
    --                  [tileId] = data
    --                  }
    --             
    if self.mapData then
        local data = bitser.loads(self.mapData)

        for roomid, room in pairs(data) do
            for _, tile in pairs(room.tiles) do
                local x = tile.x
                local y = tile.y

                local quad = self:_createTile(tile)
                local tx, ty = tile.wx, tile.wy

                if tile.type ~= 'empty' then
                    self.spriteBatch:add(quad, tx*64, ty*64)
                end
            end
        end
    end

    -- if false then
    --     for _, room in pairs(mapData.listOfRooms) do
    --         for y = 1, #room.tiles do
    --             for x = 1, #room.tiles[y] do
    --                 local tile = room.tiles[y][x]
    --                 local quad = self:_createTile(tile)
    --                 local tx, ty = tile:getWorldPosition()
    --                 
    --                 if not tile:getType('empty') then
    --                     self.spriteBatch:add(quad, tx*64, ty*64)
    --                 end
    --             end
    --         end
    --     end
    -- end
end

function map:reload()
    -- self.mapData = self.Dungeon:buildDungeon()
    --
    -- self.spriteBatch:clear()
    -- self:load(self.mapData)
end

local progress = 0
function map:draw()
    love.graphics.draw(self.spriteBatch, -200, -400)

    local test = love.thread.getChannel('load'):pop()

    if test then
        progress = math.floor(math.min(test[1]*10/test[2]*10,100))
    end

    if progress > 0 and progress <= 100 then
        love.graphics.rectangle('fill', love.graphics.getWidth() /2 - 200, love.graphics.getHeight() - 100, 1000, 50)
        love.graphics.setColor(0.5,1,0.7,1)
        love.graphics.rectangle('fill', love.graphics.getWidth() / 2 - 195, love.graphics.getHeight() - 95, (1000/100)*progress, 50)
    end

    if false then
        for _, room in pairs(self.mapData.listOfRooms) do
            for y = 1, #room.tiles do
                for x = 1, #room.tiles[y] do
                    local tile = room.tiles[y][x]
                    -- love.graphics.rectangle('fill', x*64 - 200, y*64 - 400, 64, 64)
                    if not tile:getType('empty') then
                    love.graphics.printf(tile:getType(), tile.wx*64 - 200, tile.wy*64 - 400, 400)
                    end
                end
            end
        end
        love.graphics.setColor(0.1, 0.1, 0.1, 0.1)
        love.graphics.rectangle('fill', -200, -400, 50*64, 50*64)
        -- for y = 1, #self.mapData.tiles do
        --     for x = 1, #self.mapData.tiles[y] do
        --         love.graphics.printf(self.mapData.tiles[y][x].roomId, x*64 - 200, y*64 - 400, 400)
        --     end
        -- end
    end
end

local GID = {
    ['floor'] = 25,
    ['wall'] = 4,
    ['empty'] = 40,
    ['door'] = 8,
    ['room'] = 22,
    ['black'] = 112,
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

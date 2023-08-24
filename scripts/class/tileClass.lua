--- Tile Class.
-- Core object of map generation and the world.
-- Stores and contains all relevent information
-- a tile may need... so a lot.
-- @module tileClass.lua
-- @author Lonely Owl Games

-- Class declaration.
local Class = require 'libraries.hump.class'
local lume = require 'libraries.lume'
local tileClass = Class{}


local function _createUUID()
    local uuid = ''
    local chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
    for i = 1, 30 do
        local l = math.random(1, #chars)
        uuid = uuid .. string.sub(chars, l, l)
    end
    return uuid
end

--- Initialize new tile instance
function tileClass:init()
    self.id = _createUUID()

    self.roomid = nil
    -- self.room = nil
    self.dungeon = nil

    -- self.localNeighbors = {} -- Neighbors inside room.
    -- self.worldNeighbors = {} -- Neighbors in dungeon

    self.x = 0
    self.y = 0

    self.wx = 0
    self.wy = 0

    self.type = 'empty'
end

--- Set tileObject.type dynamically.
-- Methods such as this allow more dynamic
-- functionality later on.
-- @param type tile Type (e.g, 'floor')
function tileClass:setType(type)
    self.type = type

    return self
end

--- set tileObject.x and tileObject.y dynamically
-- @param x
-- @param y
function tileClass:setLocalPosition(x, y)
    self.x = x
    self.y = y

    return self
end

function tileClass:setWorldPosition(x, y)
    self.wx = x
    self.wy = y

    return self
end

function tileClass:setProperty(property, value)
    self[property] = value
end

function tileClass:hasProperty(property)
    if self[property] then return true else return false end
end

function tileClass:getProperty(property)
    if self:hasProperty(property) then
        return self[property]
    end
end

--- Returns table of neighbors based on type filter
-- Return a table of either local or world neighbors, based
-- on filter parameter provided for tile 'type'. Might add
-- more functionality here in future.
-- @tparam boolean world true/false if localNeighbors or not.
-- @param filter tileObject type
function tileClass:getNeighborsFilter(world, filter)
    if not filter then assert(filter, 'No filter provided to getNeighborsFilter call') end

    local t
    local neighbors = {}

    if world then t = self.localNeighbors end
    if not world then t = self.worldNeighbors end

    for _, data in pairs(t) do
        if data.tile:getType(filter) then
            table.insert(neighbors, {tile = data.tile, direction = data.direction})
        end
    end

    return neighbors
end

--- Returns type of tile Object
-- @return type of tile
function tileClass:getType(compare)
    if compare then return self.type == compare end
    return self.type
end

--- Returns position of tile Object
-- @return (x,y) position of tile.
function tileClass:getLocalPosition()
    return self.x, self.y
end

function tileClass:getWorldPosition()
    return self.wx, self.wy
end

--- Builder function for tiles.
-- Uses Builder pattern with type argument for tile object
-- @param room
-- @param x
-- @param y
-- @param type
-- @return self for chaining function calls
function tileClass:createTile(room, x, y, type)
    self:setType(type)
    self:setLocalPosition(x,y)
    -- self:setWorldPosition(x,y)

    if room then
        self.roomid = room.id
    end

    return self
end

--- Builder function for floor ti
-- Clean dirty tiles, obviously.
-- @return self for chaining function calls
function tileClass:setDirty()
    self:clean()
    return self
end

--- Clean dirty tiles by reassigning key valus
-- @return self for chaining function calls
function tileClass:clean()
    -- self:updatePosition()
    -- self:updateLocalNeighbors()
    -- self:updateWorldNeighbors()
    -- self:updateProperties()
    return self
end

-- dungeon ->
--  roomid -> data{
--                 tileId -> data
--                 tileId -> data
--                 tileId -> data
--  roomid -> data{
--                 tileId -> data
--                 tileId -> data
--                 tileId -> data


-- Initialize tile object, then immediately deserialize to assign
-- properties
function tileClass:deserialize(...)
    local args = {...}

    for key, data in pairs(args) do
        self[key] = data
    end

    return self
end

function tileClass:serialize()
    local t = {}
    
    for key, data in pairs(self) do
        if key ~= 'neighbors' then
            t[key] = data
        end
    end

    self.serializeData = t

    return self.id
end

return tileClass

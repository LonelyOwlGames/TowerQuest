--- Implements tile Objects which are data containers for important
-- map information need for room generation and room accretion.
--
-- @classmod Tile
-- @author LonelyOwl
-- @usage Tile() 
-- @copyright Creative Commons Attribution 4.0 International License

--- List of data structures contained within.
--
-- @field id (string) Unique id for every tile created.
-- @field roomid (string) Unique id of the room the tile belongs to.
-- @field dungeon (string) Unique id of the dungeon the tile belongs to.
-- @field x (int) local room position of tile.
-- @field y (int) local room position of tile.
-- @field wx (int) world position of tile.
-- @field wy (int) world position of tile.
-- @field type (string) tile type used for discerning.

local Class = require 'libraries.hump.class'
local Tile = Class{}

--- Create unique id string for tiles created.
local function _createUUID()
    local uuid = ''
    local chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
    for i = 1, 30 do
        local l = math.random(1, #chars)
        uuid = uuid .. string.sub(chars, l, l)
    end
    return uuid
end

function Tile:init()
    self.id = _createUUID()

    self.roomid = nil
    self.dungeon = nil
    self.neighbors = {}

    self.x = 0
    self.y = 0

    self.wx = 0
    self.wy = 0

    self.type = 'empty'
end

--- Accessor function for setting tile type.
function Tile:setType(type)
    self.type = type
    return self
end

--- Accessor function for setting tile's position in room.
function Tile:setLocalPosition(x, y)
    self.x = x
    self.y = y

    return self
end

--- Accessor function for setting tile's position in world.
function Tile:setWorldPosition(x, y)
    self.wx = x
    self.wy = y

    return self
end

--- Accessor function for setting any property of a tile.
function Tile:setProperty(property, value)
    self[property] = value
end

--- Returns a boolean on whether a tile has the specified property or not.
function Tile:hasProperty(property)
    if self[property] then return true else return false end
end

--- Returns the specified property value defined, or false.
function Tile:getProperty(property)
    if self:hasProperty(property) then
        return self[property]
    else
        return false
    end
end

--- Accessor function to return a tiles type.
-- @param compare if comparison is given, return boolean instead.
function Tile:getType(compare)
    if compare then return self.type == compare end
    return self.type
end

--- Returns local room position of a tile.
function Tile:getLocalPosition()
    return self.x, self.y
end

--- Returns the world position of a tile.
function Tile:getWorldPosition()
    return self.wx, self.wy
end

--- Builder function for tile instances. Only accepts local (x,y) values.
-- @usage Tile():createTile(object room, int x, int y, string type)
function Tile:createTile(room, x, y, type)
    self:setType(type)
    self:setLocalPosition(x,y)

    if room then
        self.roomid = room.id
    end

    return self
end

--- Not implemented.
function Tile:deserialize(...)
    local args = {...}

    for key, data in pairs(args) do
        self[key] = data
    end

    return self
end

--- Called by room serialize method, or directly. Serializes
-- tile data by generating an array without any userData values.
function Tile:serialize()
    local t = {}

    for key, data in pairs(self) do
        if key ~= 'neighbors' then
            t[key] = data
        end
    end

    self.serializeData = t

    return self.id
end

return Tile

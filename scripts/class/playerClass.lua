local Class = require 'libraries/hump.class'
local Physics = require 'scripts.physics'

local playerClass = Class{}

function playerClass:init(x, y)
    self.sprite = self.sprite or {}

    self.x = self.x or x
    self.y = self.y or y

    self.sprite.image = self.sprite.image or nil
    self.sprite.x = self.sprite.x or self.x*64
    self.sprite.y = self.sprite.y or self.y*64

    self.hp = self.hp or 100
    self.mana = self.mana or 100
    self.name = self.name or 'Default Name'

    self.inventory = self.inventory or {}
    self.inventoryMax = 29

    self.moveQueue = {}
end

function playerClass:move(tileX, tileY)
    Physics:moveTo(self, tileX, tileY)
end

function playerClass:handleKeybinds(key)
    if key == 'f2' then
        love.window.setFullscreen(not love.window.getFullscreen())
    end
end


return playerClass

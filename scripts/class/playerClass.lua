local Class = require 'libraries/hump.class'
local Physics = require 'scripts.physics'

local playerClass = Class{}

function playerClass:init()
    self.sprite = self.sprite or nil

    self.x = self.x or 0
    self.y = self.y or 0

    self.hp = self.hp or 100
    self.mana = self.mana or 100
    self.name = self.name or 'Default Name'

    self.inventory = self.inventory or {}
    self.inventoryMax = 29
end

function playerClass:move(key)
    if key == 'd' then
        Physics:move(self, 'right')
    end

    if key == 'a' then
        Physics:move(self, 'left')
    end

    if key == 'w' then
        Physics:move(self, 'up')
    end

    if key == 's' then
        Physics:move(self, 'down')
    end
end

function playerClass:handleKeybinds(key)
    if key == 'f2' then
        love.window.setFullscreen(not love.window.getFullscreen())
    end
end


return playerClass

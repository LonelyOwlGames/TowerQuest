
-- Initialize shorthand love functions --
lg = love.graphics
li = love.image
lw = love.window
-----------------------------------------

local Gamestate = require 'libraries/hump.gamestate'
local State = require 'scripts/gamestate'
local game = {}

function love.load()
  -- Initialize player object from class
  Gamestate.registerEvents()
  Gamestate.switch(State.gameScreen)
end

function love.draw()
end

function love.keypressed(key)
  if key == 'escape' then
    love.event.quit()
  end
end

function love.update()

end
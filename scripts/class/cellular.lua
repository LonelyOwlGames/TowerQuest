--- Cellular Automata Class.
-- Sets up and generates a CA map based
-- on parameters provided. Later exported into
-- roomClass for procedural room generation. But also
-- may be used for Cellular Automata caves.
-- @module cellular.lua
-- @author Lonely Owl Games

local Class = require 'libraries.hump.class'

local CA = Class{}

function CA:countAliveNeighbors(hyperSpace, x, y)
end

function CA:doStep(oldHyperSpace, ...)
    local args = {...}
end

-- TODO: pick up here
function CA:generateCAMap(width, height, ...)
    local args = {...}
    args.birthLimit = args.birthLimit or 4
    args.deathLimit = args.deathLimit or 2
    args.startAliveChance = args.startAliveChance or 50
    args.steps = args.steps or 5

end




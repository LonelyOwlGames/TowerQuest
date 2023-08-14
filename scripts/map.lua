local sti = require 'libraries/sti'

local map = {}

function map:load(player)
    -- Load a map exported from Tiled.
    self.map = sti('tilemap/map.lua')

    -- Instead of using Tiled Properties in the GUI
    -- we instantiate properties manually to suite our needs here.
    for _, object in pairs(self.map.objects) do
        if object.name == 'door' then
            object.properties.isDoor = true
            object.properties.isDoorOpen = false

            object.onCollision = function(collider)
                object.properties.isDoorOpen = true
                self:replaceTile(object, 26)

                if object.properties.isDoorOpen then
                    return false
                else
                    return true
                end
            end
        end

        if object.name == 'doorLocked' then
            object.properties.isDoor = true
            object.properties.isDoorOpen = false
            object.properties.isDoorLocked = true
            object.properties.key = 'door'

            object.onCollision = function(collider)
                error('Need to program key functionality')
            end
        end
    end
end

function map:replaceTile(object, newid)
    local instance = false
    for _, ti in pairs(self.map.tileInstances[object.gid]) do
        if ti.x == object.x and ti.y == (object.y-64) then
            instance = ti
            break
        end
    end

    if instance ~= false then
        local new_tile = self.map.tiles[newid]
        instance.batch:set(instance.id, new_tile.quad, instance.x, instance.y)
    end
end


function map:draw(camera, player)
    self.map:draw()
end

-- TODO: Translate calculation can be moved to turnsystem callback since
-- it really isn't needed every frame (since player position won't ever change outside
-- of the turnsystem)
function map:update(dt, playerInfo)
    self.map:update(dt) 
end

return map

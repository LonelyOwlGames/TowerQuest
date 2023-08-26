--- A cinematographer class for camera function.
-- Manages all the unique cameras in the game. Interfaces with the
-- camera library.
-- @classmod Cinema

local Class = require 'libraries.hump.class'
local Camera = require 'libraries.Camera'
local lume = require 'libraries.lume'

local Cinema = Class{}

--- Class constructor
function Cinema:init()

    self.listOfCameras = {}

    -- local playerCamera = Camera()
    -- playerCamera.scale = 0.5
    -- playerCamera:setFollowStyle('NO_DEADZONE')
    -- playerCamera:setFollowLerp(0.1)
end

--- Creates a new camera object.
function Cinema:createNewCamera(...)
    local args = {...}
    args[1].name = args[1].name or 'Default'

    local camera = Camera()
    camera.active = true
    camera.drawCalls = {}

    self.listOfCameras[args[1].name] = camera
end

function Cinema:setCameraProperty(cameraName, property, value)
    local camera = self.listOfCameras[cameraName]

    camera[property] = value
end

function Cinema:panToPosition(cameraName, x, y)
    local camera = self.listOfCameras[cameraName]
    self:setArg(cameraName, 'panTarget', {x,y})
end

function Cinema:setCameraFollow(cameraName, x, y)
    local camera = self.listOfCameras[cameraName]
    camera:follow(x, y)
end

function Cinema:turnOn(cameraName)
    local camera = self.listOfCameras[cameraName]
    camera.active = true
end

function Cinema:turnOff(cameraName)
    local camera = self.listOfCameras[cameraName]
    camera.active = false
end

function Cinema:toggle(cameraName)
    local camera = self.listOfCameras[cameraName]
    camera.active = not camera.active
end

function Cinema:attach(cameraName, func)
    local camera = self.listOfCameras[cameraName]
    camera.drawCallback = func
    -- table.insert(camera.drawCalls, func)
end

function Cinema:setArg(cameraName, argName, value)
    local camera = self.listOfCameras[cameraName]
    if not camera.args then camera.args = {} end
    camera.args[argName] = value
end

function Cinema:smoothScale(cameraName, scale)
    local camera = self.listOfCameras[cameraName]
    local oldScale = camera.scale
    local newScale = scale

    if not camera.args then camera.args = {} end
    camera.args.smoothScale = {oldScale, newScale}
end

function Cinema:setCameraShader(cameraName, shader)
    local camera = self.listOfCameras[cameraName]
    if not camera.args then camera.args = {} end

    camera.args.shader = shader
end

function Cinema:update(dt)
    for _, camera in pairs(self.listOfCameras) do
        if camera.active then
            camera:update(dt)

            if camera.args then 
                if camera.args.panTarget then
                    camera:follow(camera.args.panTarget[1][1], camera.args.panTarget[1][2])
                end

                if camera.args.smoothScale then
                    local old = camera.args.smoothScale[1]
                    local new = camera.args.smoothScale[2]
                    local factor = lume.lerp(old, new, 0.5)

                    if not camera.scale ~= newScale then
                        if camera.scale < factor then
                            camera.scale = camera.scale + 0.001
                        else
                            camera.scale = camera.scale - 0.001
                        end
                    end
                end
            end
        end
    end

    -- if player then maybe follow :follow?
end

function Cinema:draw(cameraName)
    local camera = self.listOfCameras[cameraName]

    if camera.active then
        camera:attach()
            love.graphics.setColor(1,1,1,1)
            camera.drawCallback(camera.args)
        camera:detach()
    end
end

function Cinema:debugPreset(cameraName)
    local camera = self.listOfCameras[cameraName]
    camera.scale = 1.5
    camera.x = camera.x + love.graphics.getWidth()
    camera.y = camera.y + love.graphics.getHeight()
    camera:setFollowLerp(0.01)
    camera:setFollowStyle('TOPDOWN')
end

return Cinema


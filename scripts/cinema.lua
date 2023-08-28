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

function Cinema:setPosition(cameraName, x, y)
    local camera = self.listOfCameras[cameraName]
    camera.x = x
    camera.y = y
end

function Cinema:panToPosition(cameraName, wx, wy, speed)
    -- local camera = self.listOfCameras[cameraName]
    self:setArg(cameraName, 'panTarget', {x = wx*64,y = wy*64, speed = speed})
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

function Cinema:smoothScale(cameraName, scale, factor)
    local camera = self.listOfCameras[cameraName]
    local oldScale = camera.scale
    local newScale = scale

    if not camera.args then camera.args = {} end
    camera.args.smoothScale = {oldScale, newScale, factor}
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
                    camera:follow(camera.args.panTarget.x, camera.args.panTarget.y)

                    local speed = camera.args.panTarget.speed
                    local mod = 1000
                    local value = speed / mod

                    camera:setFollowLerp(value)

                    if camera.args.smoothScale then
                        camera:setFollowLerp(value / (camera.scale/4))
                    end

                    -- Fixes the fence issue with x and y values not being on even numbers.
                    local first, second
                    if (camera.x + (100/camera.scale)) > (camera.args.panTarget.x) then
                            camera.follow_lerp_x = 1
                            camera.x = math.floor(camera.x)
                            first = true
                    end
                    if camera.y + (100/camera.scale) > camera.args.panTarget.y then
                            camera.follow_lerp_y = 1
                            camera.y = math.floor(camera.y)
                            second = true
                    end

                    if first and second then

                            camera.args.panTarget = false
                    end
                end

                if camera.args.smoothScale then
                    local old = camera.args.smoothScale[1]
                    local new = camera.args.smoothScale[2]
                    local speed = camera.args.smoothScale[3]/2
                    local factor = lume.lerp(camera.scale, new, 0.5)

                    if camera.scale > new then
                        if camera.scale < new then
                            camera.scale = camera.scale + (speed * 0.1)*factor
                        else
                            camera.scale = camera.scale - (speed*factor*0.1)*factor
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
    camera.scale = 2.5
    camera.x = camera.x + love.graphics.getWidth()
    camera.y = camera.y + love.graphics.getHeight() + 200
    -- camera:setFollowLerp(0.01)
    camera:setFollowStyle('LOCKON')
end

return Cinema


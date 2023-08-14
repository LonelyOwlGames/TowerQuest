local Controller = {}


function Controller:init(player)
    self.x = self.x or 0
    self.y = self.y or 0

    self.tileX = 0
    self.tileY = 0

    self.player = player
end

function Controller:mousepressed(x, y, button)
    if button == 1 then
        self.player:move(self.tileX, self.tileY)
    end
end

function Controller:update(dt, camera)
    local mx, my = camera:toWorldCoords(love.mouse.getPosition())

    self.tileX = math.floor(mx/64)
    self.tileY = math.floor(my/64)
end

function Controller:draw()
    love.graphics.push()
        love.graphics.setColor(0.1,0.1,0.3,0.2)
        love.graphics.rectangle('fill', self.tileX*64, self.tileY*64, 64, 64)
    love.graphics.pop()
end

return Controller

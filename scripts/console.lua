local Console = {}

function Console:load()
    self.messages = {} -- stack
    self.backlog = {}
    self.width = love.graphics.getWidth()/2
    self.height = love.graphics.getHeight()/1.5

    self.x = love.graphics.getWidth()/2 - self.width/2
    self.y = love.graphics.getHeight()/2 - self.height/2

    self.enabled = true

    self.title_x = self.x
    self.title_y = self.y
    self.title_w = self.width
    self.title_h = 20
end

function Console:update(dt)
    if love.mouse.isDown(1) then
        local mx, my = love.mouse.getPosition()

    end

end

function Console:scroll(x, y)
    if y == 1 then -- scroll up
        -- Pop first, insert at last
        local pop = self.messages[1]
        table.insert(self.backlog, pop)
        table.remove(self.messages, 1)
    end

    if y == -1 and #self.backlog > 0 then --scroll down
        local push = self.backlog[#self.backlog]
        table.insert(self.messages, 1, push)
        table.remove(self.backlog, #self.backlog)
    end
end

function Console:draw()
        love.graphics.setColor(0,0,0,0.4)
        love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)

        -- Header
        love.graphics.setColor(0.2,0.5,0.2,0.8)
        love.graphics.rectangle('fill', self.title_x, self.title_y, self.title_w, self.title_h)

        love.graphics.setColor(1, 0.5, 0.2, 1)
        love.graphics.printf('X', self.x + self.width - 15, self.title_y + 3, 400)

        -- 46 maximum lines
        for n = 1, math.min(46, #self.messages) do
            local text = self.messages[n]

            love.graphics.printf(text, self.x + 5, self.y + self.height - 10 - (n*15), 800)
        end
end

function Console:push(text)
    table.insert(self.messages, 1, text)
end


return Console


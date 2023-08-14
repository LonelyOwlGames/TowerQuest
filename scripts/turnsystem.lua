local TurnSystem = {}

function TurnSystem:init()
    self.stack = {}
    self.totalTurns = 0
end

-- Registers an object (character) into the turn system.
function TurnSystem:registerObject(object)
    table.insert(self.stack, object)
end

function TurnSystem:removeObject(object)
    for k, v in pairs(self.stack) do
        if v == object then
            table.remove(self.stack, k)
        end
    end
end

-- Returns whether it's this object's turn or not.
function TurnSystem:isTurn(object)
    return (self.stack[1] == object)
end

function TurnSystem:useTurn(object)
    if self:isTurn(object) then
        table.remove(self.stack, 1)
        table.insert(self.stack, object)
    end

    self.totalTurns = self.totalTurns + 1

    -- Notify object that turn has ended
    if object.onTurnEnd then object:onTurnEnd() end

    -- Notify next object in turn, turn has started
    if self.stack[1].onTurnStart then self.stack[1]:onTurnStart() end

end

return TurnSystem


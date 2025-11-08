-- This module ONLY knows how to make a model perform a melee attack.
-- It doesn't know what a "Goblin" is. It doesn't know about health.
local MeleeAttack = {}

-- Simple server-side melee: after a brief telegraph, apply 1 damage
local TELEGRAPH = 0.3
local DAMAGE = 1

function MeleeAttack.Execute(attackerModel, target)
    if not attackerModel or not target then return end
    local targetHum = target:FindFirstChildOfClass("Humanoid")
    if not targetHum or targetHum.Health <= 0 then return end

    task.delay(TELEGRAPH, function()
        if targetHum and targetHum.Health > 0 then
            targetHum:TakeDamage(DAMAGE)
        end
    end)
end

return MeleeAttack

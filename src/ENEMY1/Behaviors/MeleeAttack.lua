-- This module ONLY knows how to make a model perform a melee attack.
-- It doesn't know what a "Goblin" is. It doesn't know about health.
local MeleeAttack = {}

function MeleeAttack.Execute(attackerModel, target)
	-- 'attackerModel' is the enemy's character model in the workspace
	-- 'target' is the player's character model
	
	print(attackerModel.Name .. " is attacking " .. target.Name .. " with a melee swing!")
	
	-- In a real game, you would:
	-- 1. Play an animation on the attackerModel
	-- 2. Detect a hit (e.g., raycast, .Touched)
	-- 3. If hit, deal damage to the target
end

return MeleeAttack
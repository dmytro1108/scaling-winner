local Behaviors = script.Parent.Parent.Behaviors

local GoblinConfig = {
	Name = "Goblin",
	Model = game.ServerStorage.EnemyModels.Goblin,

	-- Stats
	Health = 100,
	WalkSpeed = 14,

	-- Behaviors
	AttackBehavior = require(Behaviors.MeleeAttack),

	-- NEW: Spawning Data
	SpawnWeight = 10 -- Goblins are "10" rarity
}

return GoblinConfig
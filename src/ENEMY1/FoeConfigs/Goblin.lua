local Behaviors = script.Parent.Parent.Behaviors
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local function ensureEnemyModel(modelName)
	local enemyModels = ServerStorage:FindFirstChild("EnemyModels")
	if not enemyModels then
		enemyModels = Instance.new("Folder")
		enemyModels.Name = "EnemyModels"
		enemyModels.Parent = ServerStorage
	end

	local existing = enemyModels:FindFirstChild(modelName)
	if existing then
		return existing
	end

	local newModel
	local ok, description = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(1)
	end)
	if ok and description then
		local success, createdModel = pcall(function()
			return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
		end)
		if success and createdModel then
			newModel = createdModel
		end
	end

	if not newModel then
		newModel = Instance.new("Model")
		newModel.Name = modelName

		local humanoid = Instance.new("Humanoid")
		humanoid.Parent = newModel

		local rootPart = Instance.new("Part")
		rootPart.Name = "HumanoidRootPart"
		rootPart.Size = Vector3.new(2, 2, 1)
		rootPart.Anchored = false
		rootPart.Parent = newModel
		newModel.PrimaryPart = rootPart
	end

	newModel.Name = modelName
	newModel.Parent = enemyModels
	return newModel
end

local GoblinConfig = {
	Name = "Goblin",
	Model = ensureEnemyModel("Goblin"),

	-- Stats
	Health = 100,
	WalkSpeed = 14,

	-- Behaviors
	AttackBehavior = require(Behaviors.MeleeAttack),

	-- NEW: Spawning Data
	SpawnWeight = 10 -- Goblins are "10" rarity
}

return GoblinConfig

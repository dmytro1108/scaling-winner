-- HealthBroadcaster Script

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get the remote event for broadcasting health updates
local HealthChanged = ReplicatedStorage.HealthModules.HealthRemotes:WaitForChild("HealthChanged")

-- This function sets up the health monitoring for a player's character
local function setupCharacterHealth(character, player)
	local humanoid = character:WaitForChild("Humanoid")
	if not humanoid then return end

	-- Immediately send the player their starting health
	HealthChanged:FireClient(player, humanoid.Health, humanoid.MaxHealth)

	-- Connect to the HealthChanged event of the Humanoid
	humanoid.HealthChanged:Connect(function(newHealth)
		-- When health changes, tell the specific player's client
		HealthChanged:FireClient(player, newHealth, humanoid.MaxHealth)
	end)
end

-- Monitor when players are added to the game
Players.PlayerAdded:Connect(function(player)
	-- Monitor when the player's character spawns (or respawns)
	player.CharacterAdded:Connect(function(character)
		setupCharacterHealth(character, player)
	end)
end)
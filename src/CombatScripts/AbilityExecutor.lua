-- ServerScriptService.CombatScripts.AbilityExecutor
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RequestAbilityRemote = ReplicatedStorage.CombatModules.CombatRemotes.RequestAbility
local AbilityController = require(ReplicatedStorage.CombatModules.AbilityController)
local AbilityList = require(ReplicatedStorage.CombatModules.AbilityList)
-- local PlayerStatsManager = require(...) -- You would require your module for stats

RequestAbilityRemote.OnServerEvent:Connect(function(player, abilityName)

	-- 1. Security: Does the ability exist?
	local abilityData = AbilityList[abilityName]
	if not abilityData then
		return 
	end

	-- 2. State Check: Is the player alive, not stunned, etc?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (humanoid and humanoid.Health > 0) then
		return
	end

	-- 3. Cooldown Check (Server-side)
	if AbilityController:IsOnCooldown(player, abilityName) then
		return
	end

	-- 4. Cost Check (Stub)
	-- local hasCost = PlayerStatsManager:UseStamina(player, abilityData.Cost)
	-- if not hasCost then
	--     print("[Debug] Request denied: Not enough stamina/cost.")
	--     return
	-- end

	-- All checks passed. Execute the ability.
	AbilityController:Use(player, abilityName)
end)
-- AuraExecutor Script (REVISED for Drain Rate)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AuraConfig = require(ReplicatedStorage.AuraModules:WaitForChild("AuraPrinciplesConfig"))
local PrincipleStateChange = ReplicatedStorage.AuraModules.AuraRemotes:WaitForChild("AuraPrincipleStateChange")

local playerAura = {}
local playerCooldowns = {}

-- Listen for "Began" and "Ended" states from the client
PrincipleStateChange.OnServerEvent:Connect(function(player, principleName, state)
	local character = player.Character
	if not character then return end

	local principleData = AuraConfig.Principles[principleName]
	if not principleData then return end

	if state == "Began" then
		-- Check cooldown and initial cost
		if tick() < (playerCooldowns[player.UserId][principleName] or 0) then return end
		if playerAura[player.UserId] < principleData.AuraCost then return end

		playerAura[player.UserId] -= principleData.AuraCost
		character:SetAttribute("ActivePrinciple", principleName)

	elseif state == "Ended" then
		-- Only stop the principle if it's the one currently active
		if character:GetAttribute("ActivePrinciple") == principleName then
			character:SetAttribute("ActivePrinciple", "None")
			playerCooldowns[player.UserId][principleName] = tick() + principleData.Cooldown
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	playerAura[player.UserId] = 200
	playerCooldowns[player.UserId] = {}

	player.CharacterAdded:Connect(function(character)
		character:SetAttribute("ActivePrinciple", "None")
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerAura[player.UserId] = nil
	playerCooldowns[player.UserId] = nil
end)


-- A SINGLE, EFFICIENT LOOP TO HANDLE AURA DRAIN FOR ALL PLAYERS
task.spawn(function()
	while task.wait(1) do -- Runs once per second
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			if not character or not playerAura[player.UserId] then continue end

			local activePrinciple = character:GetAttribute("ActivePrinciple")

			-- If a principle is active, drain aura
			if activePrinciple and activePrinciple ~= "None" then
				local principleData = AuraConfig.Principles[activePrinciple]
				local drain = principleData.DrainRate

				playerAura[player.UserId] -= drain

				-- If aura runs out, forcibly stop the principle
				if playerAura[player.UserId] <= 0 then
					playerAura[player.UserId] = 0
					character:SetAttribute("ActivePrinciple", "None")
				end
			end
		end
	end
end)
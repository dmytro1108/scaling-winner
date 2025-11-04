-- SkillExecutor Script (UPDATED for UI Sync & Regeneration)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- CONFIGURATION --
local MAX_STAMINA = 100
local STAMINA_REGEN_RATE = 5 -- Stamina points per second

-- Corrected paths
local SkillConfig = require(ReplicatedStorage.StaminaModules:WaitForChild("SkillConfig"))
local SkillEvent = ReplicatedStorage.StaminaModules.StaminaRemotes:WaitForChild("SkillEvent")
local StaminaChanged = ReplicatedStorage.StaminaModules.StaminaRemotes:WaitForChild("StaminaChanged") -- NEW remote

-- A server-side table to track player stamina
local playerStamina = {}

-- NEW FUNCTION: A centralized way to modify stamina and notify the client
local function updateStamina(player, newStaminaValue)
	local clampedValue = math.clamp(newStaminaValue, 0, MAX_STAMINA)
	playerStamina[player.UserId] = clampedValue

	-- Fire the event to this specific player so their UI can update
	StaminaChanged:FireClient(player, clampedValue)
end

-- MODIFIED: When a skill is used, call our new function
SkillEvent.OnServerEvent:Connect(function(player, requestedSkillName)
	local skillData = SkillConfig.Skills[requestedSkillName]
	if not skillData then return end

	local currentStamina = playerStamina[player.UserId]
	local cost = skillData.StaminaCost

	if currentStamina and currentStamina >= cost then
		-- Use our new function to handle the change
		updateStamina(player, currentStamina - cost)

		-- === EXECUTE SKILL LOGIC ===
		if requestedSkillName == "Dash" then
			local character = player.Character
			if character and character:FindFirstChild("HumanoidRootPart") then
				local hrp = character.HumanoidRootPart
				local push = Instance.new("BodyVelocity")
				push.MaxForce = Vector3.new(math.huge, 0, math.huge)
				push.Velocity = hrp.CFrame.LookVector * 100
				push.Parent = hrp
				game.Debris:AddItem(push, 0.2)
			end
		end
		-- =========================
	end
end)


Players.PlayerAdded:Connect(function(player)
	-- Set the initial stamina and tell the client what it is
	updateStamina(player, MAX_STAMINA)
end)

Players.PlayerRemoving:Connect(function(player)
	playerStamina[player.UserId] = nil
end)


-- NEW: Stamina Regeneration Loop
task.spawn(function()
	while task.wait(1) do -- This loop runs once every second
		for _, player in ipairs(Players:GetPlayers()) do
			if playerStamina[player.UserId] and playerStamina[player.UserId] < MAX_STAMINA then
				local currentStamina = playerStamina[player.UserId]
				-- Regenerate stamina and update the client
				updateStamina(player, currentStamina + STAMINA_REGEN_RATE)
			end
		end
	end
end)
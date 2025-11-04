local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- CONFIGURATION --
local BASE_WALK_SPEED = 16
local SPRINT_WALK_SPEED = 36
local STAMINA_DRAIN_RATE = 10 -- Stamina points per second
local STAMINA_DRAIN_TICK = 0.1 -- How often to drain (every 0.1s)
local DRAIN_PER_TICK = STAMINA_DRAIN_RATE * STAMINA_DRAIN_TICK
local MIN_STAMINA_TO_SPRINT = 1 -- Player needs at least this much to start

-- REMOTES --
local Remotes = ReplicatedStorage.StaminaModules.StaminaRemotes
local SprintBegan = Remotes:WaitForChild("SprintBegan")
local SprintEnded = Remotes:WaitForChild("SprintEnded")

-- We must access the Stamina system from your other script.
-- ⚠️ IMPORTANT: This assumes 'SkillExecutor' is in ServerScriptService.
-- If not, you must require its 'updateStamina' function via a ModuleScript.
-- For this example, I will DUPLICATE the relevant functions.
-- A better design would be a shared StaminaManager ModuleScript.

-- === START: LOGIC DUPLICATED FROM YOUR SkillExecutor ===
-- In a superior architecture, this would be a single ModuleScript
local MAX_STAMINA = 100
local StaminaChanged = Remotes:WaitForChild("StaminaChanged")
local playerStamina = {} -- This server script will 'own' the stamina data

local function updateStamina(player, newStaminaValue)
	local clampedValue = math.clamp(newStaminaValue, 0, MAX_STAMINA)
	playerStamina[player.UserId] = clampedValue
	StaminaChanged:FireClient(player, clampedValue)
end
-- === END: DUPLICATED LOGIC ===

-- This table tracks the active drain loop for each player
local sprintingPlayers = {}

-- This loop runs *per player* only when they are sprinting
local function sprintLoop(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		sprintingPlayers[player] = false -- Stop loop if humanoid is missing
		return
	end

	while sprintingPlayers[player] == true do
		local currentStamina = playerStamina[player.UserId]

		if currentStamina > 0 then
			updateStamina(player, currentStamina - DRAIN_PER_TICK)
		else
			-- Out of stamina, force stop
			sprintingPlayers[player] = false -- This will end the loop
			humanoid.WalkSpeed = BASE_WALK_SPEED
			-- We don't need to fire SprintEnded, as the client already thinks it's sprinting.
			-- We just need to stop the server effects.
		end

		task.wait(STAMINA_DRAIN_TICK)
	end
end

-- EVENT HANDLERS --
SprintBegan.OnServerEvent:Connect(function(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	-- Prevent starting a new loop if one is active or not enough stamina
	if sprintingPlayers[player] or playerStamina[player.UserId] < MIN_STAMINA_TO_SPRINT then
		return 
	end

	sprintingPlayers[player] = true
	humanoid.WalkSpeed = SPRINT_WALK_SPEED

	-- Start the dedicated drain loop for this player
	task.spawn(sprintLoop, player)
end)

SprintEnded.OnServerEvent:Connect(function(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")

	-- Mark the player as "not sprinting" so their loop stops
	sprintingPlayers[player] = false 

	if humanoid then
		humanoid.WalkSpeed = BASE_WALK_SPEED
	end
end)

-- Handle initialization and cleanup
Players.PlayerAdded:Connect(function(player)
	-- Initialize stamina (DUPLICATED LOGIC)
	updateStamina(player, MAX_STAMINA)

	player.CharacterAdded:Connect(function(character)
		-- Reset speed on new character
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.WalkSpeed = BASE_WALK_SPEED

		humanoid.Died:Connect(function()
			-- Force stop sprint on death
			sprintingPlayers[player] = false
		end)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	-- Cleanup
	playerStamina[player.UserId] = nil
	sprintingPlayers[player] = nil
end)


-- === START: Stamina Regeneration (MOVED from SkillExecutor) ===
-- This logic should only exist in ONE SCRIPT. Move it here.
-- Delete the regeneration loop from 'SkillExecutor'
local STAMINA_REGEN_RATE = 5 -- Stamina points per second

task.spawn(function()
	while task.wait(1) do -- This loop runs once every second
		for _, player in ipairs(Players:GetPlayers()) do
			if playerStamina[player.UserId] and playerStamina[player.UserId] < MAX_STAMINA then

				-- CRITICAL FIX: Do not regenerate stamina while sprinting
				if not sprintingPlayers[player] then
					local currentStamina = playerStamina[player.UserId]
					updateStamina(player, currentStamina + STAMINA_REGEN_RATE)
				end

			end
		end
	end
end)
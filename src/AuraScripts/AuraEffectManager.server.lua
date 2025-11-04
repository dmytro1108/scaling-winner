-- AuraEffectManager Script

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EffectsConfig = require(ReplicatedStorage.AuraModules:WaitForChild("AuraEffectsConfig"))

-- ================== EFFECT HANDLERS ==================
-- These functions contain the logic for each principle.

local EffectHandlers = {}

-- TEN: Applies/removes a damage reduction attribute
function EffectHandlers.ApplyTen(character, isActive)
	if isActive then
		local reduction = EffectsConfig.Ten.DamageReduction
		character:SetAttribute("DamageReduction", reduction)
		print("Ten Shield active for " .. character.Name .. " (" .. reduction * 100 .. "% reduction)")
	else
		character:SetAttribute("DamageReduction", nil) -- Remove the attribute
	end
end

-- REN: Applies/removes a damage multiplier attribute
function EffectHandlers.ApplyRen(character, isActive)
	if isActive then
		local multiplier = EffectsConfig.Ren.DamageMultiplier
		character:SetAttribute("DamageMultiplier", multiplier)
		print("Ren active for " .. character.Name .. " (" .. multiplier .. "x damage)")
	else
		character:SetAttribute("DamageMultiplier", nil) -- Remove the attribute
	end
end

-- ZETSU: Makes the player's character and name tag invisible to others
function EffectHandlers.ApplyZetsu(character, isActive)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if isActive then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None -- Hide name tag
		character:SetAttribute("InZetsu", true) -- Flag for client-side invisibility
		print("Zetsu active for " .. character.Name)
	else
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer -- Show name tag
		character:SetAttribute("InZetsu", nil)
	end
end


-- ================== CORE LOGIC ==================

-- This function is the central hub that runs when a player's aura state changes
local function onAuraStateChanged(character)
	local oldState = character:GetAttribute("PreviousAuraState") or "None"
	local newState = character:GetAttribute("ActivePrinciple") or "None"

	if oldState == newState then return end -- No actual change

	-- Deactivate the old principle's effects
	if oldState ~= "None" and EffectHandlers["Apply" .. oldState] then
		EffectHandlers["Apply" .. oldState](character, false)
	end

	-- Activate the new principle's effects
	if newState ~= "None" and EffectHandlers["Apply" .. newState] then
		EffectHandlers["Apply" .. newState](character, true)
	end

	character:SetAttribute("PreviousAuraState", newState)
end


-- This function connects the listener to a character
local function setupCharacter(character)
	-- Create a placeholder attribute to track the previous state
	character:SetAttribute("PreviousAuraState", "None") 

	-- Listen for when the main attribute changes
	character:GetAttributeChangedSignal("ActivePrinciple"):Connect(function()
		onAuraStateChanged(character)
	end)
end

-- Connect the logic to all players and their characters
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(setupCharacter)
end)
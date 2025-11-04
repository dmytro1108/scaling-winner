local FoeConfigsFolder = script.Parent.Parent.FoeConfigs

local FoeRegistry = {}

-- PART 1: BLUEPRINT STORAGE (Your existing code)
FoeRegistry.Configs = {} -- Holds blueprints {GoblinConfig, OrcConfig}
FoeRegistry.WeightedList = {} -- Holds spawn data {{Blueprint = GoblinConfig, Weight = 10}, ...}
FoeRegistry.TotalWeight = 0

-- PART 2: ACTIVE AI STORAGE (This is the fix)
-- FIX for GameController:31
-- This table MUST be defined. It will hold all active FoeController instances.
FoeRegistry.ActiveFoes = {}

---------------------------------------------------------------------
-- FUNCTIONS
---------------------------------------------------------------------

function FoeRegistry.Initialize()
	print("FoeRegistry: Loading all enemy blueprints...")

	for _, configModule in ipairs(FoeConfigsFolder:GetChildren()) do
		if configModule:IsA("ModuleScript") then
			local configData = require(configModule)

			-- Store the blueprint
			FoeRegistry.Configs[configData.Name] = configData

			-- If it's spawnable, add it to the weighted list
			if configData.SpawnWeight and configData.SpawnWeight > 0 then
				FoeRegistry.TotalWeight = FoeRegistry.TotalWeight + configData.SpawnWeight
				table.insert(FoeRegistry.WeightedList, {
					Blueprint = configData,
					Min = FoeRegistry.TotalWeight - configData.SpawnWeight + 1,
					Max = FoeRegistry.TotalWeight
				})
				print(string.format(" - Loaded %s (Weight: %d, Range: %d-%d)",
					configData.Name,
					configData.SpawnWeight,
					FoeRegistry.TotalWeight - configData.SpawnWeight + 1,
					FoeRegistry.TotalWeight
					))
			end
		end
	end
	print("FoeRegistry: Total spawn weight calculated:", FoeRegistry.TotalWeight)
end

function FoeRegistry.GetBlueprint(foeName)
	return FoeRegistry.Configs[foeName]
end

-- This is the function your SpawnDirector will use
function FoeRegistry.GetRandomBlueprintByWeight(rng)
	if FoeRegistry.TotalWeight == 0 then return nil end

	-- Pick a random number from 1 to the total weight
	local randomPick = rng:NextInteger(1, FoeRegistry.TotalWeight)

	-- Find which foe that number "landed" on
	for _, entry in ipairs(FoeRegistry.WeightedList) do
		if randomPick >= entry.Min and randomPick <= entry.Max then
			return entry.Blueprint
		end
	end
	return nil
end

---------------------------------------------------------------------
-- FIX: ACTIVE AI TRACKING FUNCTIONS
---------------------------------------------------------------------

-- FIX for SpawnDirector:61
-- This function MUST exist so SpawnDirector can register new AI.
function FoeRegistry.Register(foe)
	if not foe or not foe.Humanoid then
		warn("FoeRegistry: Attempted to register an invalid foe.")
		return
	end

	table.insert(FoeRegistry.ActiveFoes, foe)

	-- Automatically handle cleanup.
	-- When the foe dies, it unregisters itself from the list.
	foe.Humanoid.Died:Connect(function()
		FoeRegistry.Unregister(foe)
	end)
end

-- This function removes the foe from the active list
function FoeRegistry.Unregister(foe)
	-- Iterate backwards to safely remove while looping
	for i = #FoeRegistry.ActiveFoes, 1, -1 do
		if FoeRegistry.ActiveFoes[i] == foe then
			table.remove(FoeRegistry.ActiveFoes, i)
			break
		end
	end
end

return FoeRegistry
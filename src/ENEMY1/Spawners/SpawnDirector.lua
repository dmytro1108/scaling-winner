-- This module's ONLY job is to manage the spawn loop.
-- It holds NO configuration.
-- It does NOT know what a "Goblin" is.

local FoeController = require(script.Parent.Parent.MasterFoe.FoeController)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SpawnDirector = {}

-- Store the services we were given
local Config = nil
local FoeRegistry = nil
local Rng = nil
local Population = 0

-- (You would also pass in FoeFactory and Positioning services here)

function SpawnDirector.Start(_Config, _FoeRegistry, _Rng)
	-- Store the injected services
	Config = _Config
	FoeRegistry = _FoeRegistry
	Rng = _Rng

	print(string.format("SpawnDirector: Starting... (MaxPop: %d, Interval: %ds)",
		Config.MaxPopulation,
		Config.SpawnInterval
		))

	-- Start the spawn loop
	task.spawn(function()
		while true do
			local flags = ReplicatedStorage:FindFirstChild("QuestFlags")
			local halt = flags and flags:FindFirstChild("StopGoblinSpawns")
			local stopSpawns = halt and halt.Value
			if (not stopSpawns) and Population < Config.MaxPopulation then
				SpawnDirector.SpawnFoe()
			end
			task.wait(Config.SpawnInterval)
		end
	end)
end

function SpawnDirector.SpawnFoe()
	-- 1. WHAT to spawn?
	local blueprint = FoeRegistry.GetRandomBlueprintByWeight(Rng)
	if not blueprint then
		warn("SpawnDirector: FoeRegistry returned no blueprint. Is it empty?")
		return
	end

	-- 2. WHERE to spawn?
	local spawnPos = Vector3.new(Rng:NextInteger(-100, 100), 10, Rng:NextInteger(-100, 100))

	-- 3. HOW to spawn?
	local newModel = blueprint.Model:Clone()
	newModel:SetPrimaryPartCFrame(CFrame.new(spawnPos))
	newModel.Parent = workspace.Enemies

	-- 4. Create the Controller ("Puppeteer")
	local newFoe = FoeController.new(blueprint, newModel)

	-- 5. CRITICAL FIX 1: TELL THE GAME THE AI EXISTS
	-- This adds the new AI to the central "ActiveFoes" list
	-- so the heartbeat loop can find it and call its :Update()
	FoeRegistry.Register(newFoe)

	Population = Population + 1

	-- 6. CRITICAL FIX 2: DECREASE POPULATION ON DEATH
	-- This connects to the event in FoeController
	newFoe.Humanoid.Died:Connect(function()
		Population = math.max(0, Population - 1)
		-- The FoeRegistry.Unregister() logic should be handled
		-- inside the FoeRegistry.Register() function itself.
	end)

	print("SpawnDirector: Spawning a " .. newFoe.Name .. ". Population is now " .. Population)
end

return SpawnDirector

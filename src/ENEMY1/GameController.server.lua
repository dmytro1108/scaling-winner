-- This script boots up the services AND runs the main game loop.

local RunService = game:GetService("RunService") -- Get the service that provides the heartbeat

local Services = script.Parent.Services
local Spawners = script.Parent.Spawners

-- 1. Load Services
local Config = require(Services.Config)
local FoeRegistry = require(Services.FoeRegistry)
-- (Add other services here like FoeFactory, PositioningService)

-- 2. Initialize Services
FoeRegistry.Initialize()
local rng = Random.new(Config.WORLD_SEED) -- Create our Random object

-- 3. Get and Start Controllers
local SpawnDirector = require(Spawners.SpawnDirector)
SpawnDirector.Start(Config, FoeRegistry, rng) -- Pass in the services it needs

print("GameController: All systems initialized.")

---------------------------------------------------------------------
-- CRITICAL ADDITION: THE AI HEARTBEAT
---------------------------------------------------------------------
-- This function will run ~60 times per second.
RunService.Heartbeat:Connect(function(dt)
	-- 'dt' is "delta time" - the time since the last frame

	-- Loop through every AI the SpawnDirector has registered...
	for _, foe in ipairs(FoeRegistry.ActiveFoes) do

		-- ...and tell its brain to run one "tick" of logic.
		foe:Update(dt) 

	end
end)

-- This script is no longer "done." It is now an active controller.
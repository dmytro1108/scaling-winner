local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

-- Get a DataStore. Naming it "PlayerData" is safer for future stats.
local playerDataStore = DataStoreService:GetDataStore("PlayerData")

local function onPlayerAdded(player)
	-- 1. Reuse or create leaderstats so we don't conflict with other systems
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	-- 2. Reuse or create the Kills value
	local kills = leaderstats:FindFirstChild("Kills")
	if not kills then
		kills = Instance.new("IntValue")
		kills.Name = "Kills"
		kills.Value = 0 -- Default
		kills.Parent = leaderstats
	end

	-- 3. (NEW) Reuse or create the HasSword flag
	local hasSword = leaderstats:FindFirstChild("HasSword")
	if not hasSword then
		hasSword = Instance.new("BoolValue")
		hasSword.Name = "HasSword"
		hasSword.Value = false
		hasSword.Parent = leaderstats
	end

	-- 4. Load Data
	local playerUserId = "Player_" .. player.UserId
	local success, data = pcall(function()
		return playerDataStore:GetAsync(playerUserId)
	end)

	if success then
		if data then
			if data.Kills then
				kills.Value = data.Kills
			end
			if data.HasSword ~= nil then
				hasSword.Value = data.HasSword
			end
		end
		-- (You would also load other data here, e.g., data.Strength)
	else
		warn("Failed to load data for: " .. player.Name)
	end
end

local function onPlayerRemoving(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local playerUserId = "Player_" .. player.UserId

	-- 1. Prepare data to save
	local killsValue = leaderstats:FindFirstChild("Kills")
	local hasSwordValue = leaderstats:FindFirstChild("HasSword")
	local dataToSave = {
		Kills = killsValue and killsValue.Value or 0
		,
		HasSword = hasSwordValue and hasSwordValue.Value or false
		-- (You would also save other stats here from your StatSystem)
		-- Strength = leaderstats:FindFirstChild("Strength").Value 
	}

	-- 2. Save Data
	local success, err = pcall(function()
		playerDataStore:SetAsync(playerUserId, dataToSave)
	end)

	if not success then
		warn("Failed to save data for: " .. player.Name .. " | Error: " .. err)
	end
end

-- Connect events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

game:BindToClose(function()
	-- Save data for all players if the server shuts down
	if game:GetService("RunService"):IsStudio() then
		return -- Don't save in Studio playtests
	end

	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerRemoving(player)
	end
end)

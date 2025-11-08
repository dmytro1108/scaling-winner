-- CharacterSetup Script (with Debugs)

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local scoreStore = DataStoreService:GetDataStore("PlayerScore_v1")

local function onCharacterAdded(character)
	-- DEBUG: Announce the creation of the state object

	local actionState = Instance.new("StringValue")
	actionState.Name = "ActionState"
	actionState.Value = "Idle"
	actionState.Parent = character
end

local function loadScore(player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local score = Instance.new("IntValue")
    score.Name = "Score"
    score.Value = 0
    score.Parent = leaderstats

    local ok, data = pcall(function()
        return scoreStore:GetAsync("score_" .. player.UserId)
    end)
    if ok and typeof(data) == "number" then
        score.Value = data
    end
end

local function saveScore(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    local score = leaderstats and leaderstats:FindFirstChild("Score")
    local value = score and score.Value or 0
    pcall(function()
        scoreStore:SetAsync("score_" .. player.UserId, value)
    end)
end

Players.PlayerAdded:Connect(function(player)
    -- init attributes used elsewhere
    player:SetAttribute("HasQuestWeapon", player:GetAttribute("HasQuestWeapon") or false)

    loadScore(player)
    player.CharacterAdded:Connect(onCharacterAdded)
end)

Players.PlayerRemoving:Connect(saveScore)

game:BindToClose(function()
    for _, plr in ipairs(Players:GetPlayers()) do
        saveScore(plr)
    end
end)

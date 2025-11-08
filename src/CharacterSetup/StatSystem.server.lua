-- ServerScriptService.CharacterSetup.StatSystem
-- Creates core stat values and handles stat upgrade requests

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Ensure remote exists
local statFolder = ReplicatedStorage:FindFirstChild("PlayerStatRemotes") or Instance.new("Folder")
statFolder.Name = "PlayerStatRemotes"
statFolder.Parent = ReplicatedStorage

local upgradeEvent = statFolder:FindFirstChild("RequestStatUpgrade") or Instance.new("RemoteEvent")
upgradeEvent.Name = "RequestStatUpgrade"
upgradeEvent.Parent = statFolder

local VALID = { Strength = true, Endurance = true, Agility = true }

local function ensureStats(player)
    local leaderstats = player:FindFirstChild("leaderstats") or player:WaitForChild("leaderstats")

    local function getOrCreate(name, default)
        local obj = leaderstats:FindFirstChild(name)
        if not obj then
            obj = Instance.new("IntValue")
            obj.Name = name
            obj.Value = default or 0
            obj.Parent = leaderstats
        end
        return obj
    end

    getOrCreate("Strength", 0)
    getOrCreate("Endurance", 0)
    getOrCreate("Agility", 0)
    getOrCreate("StatPoints", 5)
end

Players.PlayerAdded:Connect(function(player)
    -- wait for leaderstats created in CharacterSetup.server.lua
    player:WaitForChild("leaderstats")
    ensureStats(player)
end)

upgradeEvent.OnServerEvent:Connect(function(player, statName)
    if type(statName) ~= "string" or not VALID[statName] then return end
    local ls = player:FindFirstChild("leaderstats")
    if not ls then return end
    local points = ls:FindFirstChild("StatPoints")
    local stat = ls:FindFirstChild(statName)
    if not (points and stat) then return end
    if points.Value <= 0 then return end
    points.Value -= 1
    stat.Value += 1
end)

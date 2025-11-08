-- Watches player Score and completes the Goblin kill quest at 100 points
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Client notify
local questRemotes = ReplicatedStorage:FindFirstChild("QuestRemotes") or Instance.new("Folder")
questRemotes.Name = "QuestRemotes"
questRemotes.Parent = ReplicatedStorage

local questComplete = questRemotes:FindFirstChild("QuestComplete") or Instance.new("RemoteEvent")
questComplete.Name = "QuestComplete"
questComplete.Parent = questRemotes

-- Global flag to halt spawns (simple implementation)
local flags = ReplicatedStorage:FindFirstChild("QuestFlags") or Instance.new("Folder")
flags.Name = "QuestFlags"
flags.Parent = ReplicatedStorage

local stop = flags:FindFirstChild("StopGoblinSpawns") or Instance.new("BoolValue")
stop.Name = "StopGoblinSpawns"
stop.Value = false
stop.Parent = flags

local TARGET = 100

local function hookPlayer(player)
    local ls = player:WaitForChild("leaderstats")
    local score = ls:WaitForChild("Score")

    local function check()
        if player:GetAttribute("GoblinQuestComplete") then return end
        if score.Value >= TARGET then
            player:SetAttribute("GoblinQuestComplete", true)
            questComplete:FireClient(player, "GoblinSlayer")
            -- Stop spawns globally (simple)
            stop.Value = true
        end
    end

    check()
    score.Changed:Connect(check)
end

Players.PlayerAdded:Connect(function(player)
    hookPlayer(player)
end)


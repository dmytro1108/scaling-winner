-- ServerScriptService.QuestScripts.QuestItemPickup

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local FOREST_NAME = "FORBIDDEN FOREST"
local QUEST_PART_NAME = "QUESTITEM"
local RESPAWN_TIME = 30

local forest = Workspace:FindFirstChild(FOREST_NAME)
if not forest then
    warn("[QuestItemPickup] Could not find '" .. FOREST_NAME .. "' in Workspace.")
    return
end

local questPart = forest:FindFirstChild(QUEST_PART_NAME)
if not questPart or not questPart:IsA("BasePart") then
    warn("[QuestItemPickup] Could not find BasePart '" .. QUEST_PART_NAME .. "' inside '" .. FOREST_NAME .. "'.")
    return
end

questPart.CanTouch = true

local function onTouched(hit)
    local character = hit and hit.Parent
    if not character then
        return
    end

    local player = Players:GetPlayerFromCharacter(character)
    if not player then
        return
    end

    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        return
    end

    local hasSword = leaderstats:FindFirstChild("HasSword")
    if not hasSword then
        return
    end

    if hasSword.Value == false then
        hasSword.Value = true
        print("[QuestItemPickup] SWORD ACQUIRED by", player.Name)

        questPart.Transparency = 1
        questPart.CanTouch = false

        task.delay(RESPAWN_TIME, function()
            questPart.Transparency = 0
            questPart.CanTouch = true
        end)
    end
end

questPart.Touched:Connect(onTouched)

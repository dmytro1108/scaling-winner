-- ServerScriptService.QuestScripts.QuestItemPickup

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FOREST_NAME = "FORBIDDEN FOREST"
local QUEST_PART_NAME = "QUESTITEM"
local WEAPON_NAME = "QuestWeapon"

-- Helper to create the quest weapon Tool
local function createQuestWeapon()
    local tool = Instance.new("Tool")
    tool.Name = WEAPON_NAME
    tool.RequiresHandle = true
    tool.CanBeDropped = false

    -- Simple visible sword handle
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.25, 4, 0.6)
    handle.Material = Enum.Material.Metal
    handle.Color = Color3.fromRGB(200, 200, 200)
    handle.Massless = true
    handle.CanCollide = false
    handle.CanQuery = false
    handle.CanTouch = false
    handle.Parent = tool

    -- Grip to align in the hand
    tool.GripForward = Vector3.new(0, 0, -1)
    tool.GripRight = Vector3.new(1, 0, 0)
    tool.GripUp = Vector3.new(0, 1, 0)
    tool.GripPos = Vector3.new(0, -1.5, 0)

    return tool
end

-- Locate the quest item part in the world
local forest = Workspace:FindFirstChild(FOREST_NAME)
if not forest then
    warn("[QuestItemPickup] Could not find '" .. FOREST_NAME .. "' in Workspace.")
    return
end

local questPart = forest:FindFirstChild(QUEST_PART_NAME)
if not questPart then
    warn("[QuestItemPickup] Could not find '" .. QUEST_PART_NAME .. "' inside '" .. FOREST_NAME .. "'.")
    return
end

-- Ensure a ProximityPrompt exists on the quest part
local prompt = questPart:FindFirstChildOfClass("ProximityPrompt")
if not prompt then
    prompt = Instance.new("ProximityPrompt")
    prompt.Name = "QuestPickupPrompt"
    prompt.ActionText = "Pick Up"
    prompt.ObjectText = "Quest Weapon"
    prompt.KeyboardKeyCode = Enum.KeyCode.G
    prompt.HoldDuration = 0
    prompt.RequiresLineOfSight = false
    prompt.MaxActivationDistance = 12
    prompt.Parent = questPart
end
-- Important: make sure every player can trigger once independently
-- Some engine versions may not have OnePerPlayer, so guard with pcall
pcall(function()
    prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerPlayer
end)

prompt.Triggered:Connect(function(player)
    if not player or not player:IsDescendantOf(Players) then
        return
    end

    -- Prevent duplicate pickups per-player
    if player:GetAttribute("HasQuestWeapon") then
        return
    end

    local backpack = player:FindFirstChildOfClass("Backpack") or player:FindFirstChild("Backpack")
    if not backpack then
        -- Create if not present yet (rare)
        backpack = Instance.new("Backpack")
        backpack.Name = "Backpack"
        backpack.Parent = player
    end

    -- Ensure RemoteEvent exists for combat (created once)
    local combatModules = ReplicatedStorage:FindFirstChild("CombatModules") or Instance.new("Folder")
    combatModules.Name = "CombatModules"
    combatModules.Parent = ReplicatedStorage
    local combatRemotes = combatModules:FindFirstChild("CombatRemotes") or Instance.new("Folder")
    combatRemotes.Name = "CombatRemotes"
    combatRemotes.Parent = combatModules
    if not combatRemotes:FindFirstChild("QuestWeaponAttack") then
        Instance.new("RemoteEvent", combatRemotes).Name = "QuestWeaponAttack"
    end

    local tool = createQuestWeapon()
    -- Inject a LocalScript for client animation + input
    local client = Instance.new("LocalScript")
    client.Name = "ClientAttack"
    client.Source = [[
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local tool = script.Parent
        local remotes = ReplicatedStorage:WaitForChild("CombatModules"):WaitForChild("CombatRemotes")
        local evt = remotes:WaitForChild("QuestWeaponAttack")

        local ATTACK_ANIM_ID = "rbxassetid://0" -- replace with your exported anim id

        local function playAnimation()
            local char = tool.Parent
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
            local anim = Instance.new("Animation")
            anim.AnimationId = ATTACK_ANIM_ID
            anim.Priority = Enum.AnimationPriority.Action
            local track = animator:LoadAnimation(anim)
            track:Play(0.05)
            track:AdjustSpeed(1)
        end

        tool.Activated:Connect(function()
            playAnimation()
            evt:FireServer()
        end)
    ]]
    client.Parent = tool
    tool.Parent = backpack

    player:SetAttribute("HasQuestWeapon", true)

    -- Force equip as soon as Tool is in Backpack
    task.defer(function()
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")
        if humanoid and tool.Parent == backpack then
            humanoid:EquipTool(tool)
        end
    end)
end)

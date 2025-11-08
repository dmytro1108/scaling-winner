-- ServerScriptService.CombatScripts.QuestWeaponCombat
-- Handles attack requests for the QuestWeapon and also listens to Tool.Activated as a fallback.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")

local WEAPON_NAME = "QuestWeapon"

-- Create/find RemoteEvent for client attack requests
local combatModules = ReplicatedStorage:FindFirstChild("CombatModules") or Instance.new("Folder")
combatModules.Name = "CombatModules"
combatModules.Parent = ReplicatedStorage

local combatRemotes = combatModules:FindFirstChild("CombatRemotes") or Instance.new("Folder")
combatRemotes.Name = "CombatRemotes"
combatRemotes.Parent = combatModules

local attackEvent = combatRemotes:FindFirstChild("QuestWeaponAttack") or Instance.new("RemoteEvent")
attackEvent.Name = "QuestWeaponAttack"
attackEvent.Parent = combatRemotes

-- Tuning
local COOLDOWN = 0.6
local BASE_DAMAGE = 10
local RANGE, WIDTH, HEIGHT = 6, 4, 4

local lastAttack = {}
local diedConnected = setmetatable({}, { __mode = "k" })

local function isEnemyModel(model)
    return CollectionService:HasTag(model, "Enemy") or model.Name == "Goblin"
end

local function awardOnDeathOnce(enemyHum)
    if diedConnected[enemyHum] then return end
    diedConnected[enemyHum] = true
    enemyHum.Died:Connect(function()
        local tag = enemyHum:FindFirstChild("creator")
        local killer = tag and tag.Value
        if killer and killer.Parent == Players then
            local ls = killer:FindFirstChild("leaderstats")
            local score = ls and ls:FindFirstChild("Score")
            if score then
                score.Value += 1
            end
        end
    end)
end

local function performAttack(player)
    local now = os.clock()
    if (lastAttack[player] or 0) + COOLDOWN > now then return end
    lastAttack[player] = now

    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not (hrp and hum and hum.Health > 0) then return end

    -- Ensure the player is holding the right tool if one is equipped
    local equippedTool = char:FindFirstChildOfClass("Tool")
    if not (equippedTool and equippedTool.Name == WEAPON_NAME) then return end

    -- Hitbox box in front of the player
    local cf = hrp.CFrame * CFrame.new(0, 0, -(RANGE * 0.5))
    local size = Vector3.new(WIDTH, HEIGHT, RANGE)

    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { char }

    local parts = workspace:GetPartBoundsInBox(cf, size, params)
    if #parts == 0 then return end

    local mult = tonumber(char:GetAttribute("DamageMultiplier")) or 1
    local damage = BASE_DAMAGE * mult

    local hitHumanoids = {}
    for _, part in ipairs(parts) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and model ~= char then
            local enemyHum = model:FindFirstChildOfClass("Humanoid")
            if enemyHum and enemyHum.Health > 0 and isEnemyModel(model) then
                hitHumanoids[enemyHum] = model
            end
        end
    end

    for enemyHum, _ in pairs(hitHumanoids) do
        local tag = Instance.new("ObjectValue")
        tag.Name = "creator"
        tag.Value = player
        tag.Parent = enemyHum
        Debris:AddItem(tag, 2)

        enemyHum:TakeDamage(damage)
        awardOnDeathOnce(enemyHum)
    end
end

-- Remote-based attack (preferred when a client LocalScript exists)
attackEvent.OnServerEvent:Connect(function(player)
    performAttack(player)
end)

-- Fallback: if the tool is activated and we don't have a client LocalScript
local function connectTool(tool, player)
    if tool.Name ~= WEAPON_NAME then return end
    tool.Activated:Connect(function()
        performAttack(player)
    end)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        -- Hook any tools in character
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Tool") then
                connectTool(child, player)
            end
        end
        character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                connectTool(child, player)
            end
        end)
    end)

    local backpack = player:WaitForChild("Backpack")
    backpack.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            connectTool(child, player)
        end
    end)
end)


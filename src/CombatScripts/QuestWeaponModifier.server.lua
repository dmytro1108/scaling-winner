-- ServerScriptService.CombatScripts.QuestWeaponModifier

local Players = game:GetService("Players")

local WEAPON_NAME = "QuestWeapon"
local EQUIPPED_MULTIPLIER = 2

local function hookTool(tool, player)
    if not tool or not tool:IsA("Tool") or tool.Name ~= WEAPON_NAME then
        return
    end

    tool.Equipped:Connect(function()
        local character = player.Character
        if character then
            character:SetAttribute("DamageMultiplier", EQUIPPED_MULTIPLIER)
        end
    end)

    tool.Unequipped:Connect(function()
        local character = player.Character
        if character and character:GetAttribute("DamageMultiplier") == EQUIPPED_MULTIPLIER then
            character:SetAttribute("DamageMultiplier", nil)
        end
    end)
end

Players.PlayerAdded:Connect(function(player)
    -- Hook tools added to Backpack
    local backpack = player:WaitForChild("Backpack")
    backpack.ChildAdded:Connect(function(child)
        hookTool(child, player)
    end)

    -- Also watch tools that land directly in the character
    player.CharacterAdded:Connect(function(character)
        character.ChildAdded:Connect(function(child)
            hookTool(child, player)
        end)
    end)

    -- In case the weapon already exists in the backpack
    for _, child in ipairs(backpack:GetChildren()) do
        hookTool(child, player)
    end
end)


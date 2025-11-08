-- Hooks PlayerMenuGui buttons to request stat upgrades and reflects changes
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local function waitForMenu()
    local menu = gui:FindFirstChild("PlayerMenuGui")
    if menu then return menu end
    repeat
        menu = gui:FindFirstChild("PlayerMenuGui")
        task.wait(0.5)
    until menu
    return menu
end

local function connectButtons(root)
    local remotes = ReplicatedStorage:WaitForChild("PlayerStatRemotes")
    local request = remotes:WaitForChild("RequestStatUpgrade")

    -- Strategy: Any TextButton that has a StringValue child named StatName will trigger an upgrade
    for _, btn in ipairs(root:GetDescendants()) do
        if btn:IsA("TextButton") then
            local statNameValue = btn:FindFirstChild("StatName")
            local statName
            if statNameValue and statNameValue:IsA("StringValue") then
                statName = statNameValue.Value
            else
                -- Fallback: Infer from button name
                if btn.Name:lower():find("strength") then statName = "Strength" end
                if btn.Name:lower():find("endurance") then statName = "Endurance" end
                if btn.Name:lower():find("agility") then statName = "Agility" end
            end
            if statName then
                btn.MouseButton1Click:Connect(function()
                    request:FireServer(statName)
                end)
            end
        end
    end
end

local function reflectStats(root)
    local ls = player:WaitForChild("leaderstats")
    local function attach(name)
        local stat = ls:WaitForChild(name)
        local label
        -- Find a TextLabel whose name contains the stat
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("TextLabel") and d.Name:lower():find(name:lower()) then
                label = d; break
            end
        end
        if label then
            local function update()
                label.Text = name .. ": " .. tostring(stat.Value)
            end
            update()
            stat.Changed:Connect(update)
        end
    end

    attach("Strength"); attach("Endurance"); attach("Agility"); attach("StatPoints")
end

local menu = waitForMenu()
connectButtons(menu)
reflectStats(menu)


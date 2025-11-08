-- Updates the PP.Frame TextLabel with the persistent Score value
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local function getScore()
    local leaderstats = player:FindFirstChild("leaderstats") or player:WaitForChild("leaderstats")
    return leaderstats:WaitForChild("Score")
end

local function getScoreLabel()
    local gui = player:WaitForChild("PlayerGui")
    local pp = gui:FindFirstChild("PP") or gui:WaitForChild("PP")
    local frame = pp:FindFirstChild("Frame") or pp:WaitForChild("Frame")
    -- Try to find a TextLabel anywhere in the frame
    local label = frame:FindFirstChildWhichIsA("TextLabel", true)
    if not label then
        -- Create a label if missing to avoid silent failure
        label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.Parent = frame
    end
    return label
end

local score = getScore()
local label = getScoreLabel()

local function update()
    label.Text = "Score: " .. tostring(score.Value)
end

update()
score.Changed:Connect(update)


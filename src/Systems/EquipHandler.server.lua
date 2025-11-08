local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local equipToggleEvent = ReplicatedStorage:WaitForChild("RequestEquipToggle")
local dropItemEvent = ReplicatedStorage:WaitForChild("RequestDropItem")
local masterSword = ServerStorage:WaitForChild("ClassicSword")

equipToggleEvent.OnServerEvent:Connect(function(player)
    local character = player.Character
    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return
    end

    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        return
    end

    local hasSword = leaderstats:FindFirstChild("HasSword")
    if not hasSword or hasSword.Value == false then
        return
    end

    local currentSword = character:FindFirstChild("ClassicSword")
    if currentSword then
        currentSword:Destroy()
        return
    end

    local newSword = masterSword:Clone()
    newSword.Parent = character
end)

-- Handle the drop request coming from the client
dropItemEvent.OnServerEvent:Connect(function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	local hasSword = leaderstats:FindFirstChild("HasSword")
	if not hasSword or hasSword.Value == false then
		return
	end

	-- Flag that the player no longer owns the sword and clear any equipped instance
	hasSword.Value = false

	local character = player.Character
	if not character then
		return
	end

	local currentSword = character:FindFirstChild("ClassicSword")
	if currentSword then
		currentSword:Destroy()
	end
end)

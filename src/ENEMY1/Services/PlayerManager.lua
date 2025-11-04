-- This script lives in ServerScriptService/Services/PlayerManager
local Players = game:GetService("Players")

-- When a player joins the game...
Players.PlayerAdded:Connect(function(player)
	-- Create a folder named "leaderstats"
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	-- Create the "PP" currency value
	local pp = Instance.new("IntValue")
	pp.Name = "PP"
	pp.Value = 0 -- They start with 0
	pp.Parent = leaderstats
end)
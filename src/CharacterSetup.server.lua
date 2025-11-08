-- CharacterSetup Script (with Debugs)

local Players = game:GetService("Players")

local function onCharacterAdded(character)
	-- DEBUG: Announce the creation of the state object

	local actionState = Instance.new("StringValue")
	actionState.Name = "ActionState"
	actionState.Value = "Idle"
	actionState.Parent = character
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(onCharacterAdded)
end)
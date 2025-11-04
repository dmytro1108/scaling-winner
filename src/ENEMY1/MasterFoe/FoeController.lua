-- FoeController.lua
local PathfindingService = game:GetService("PathfindingService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local FoeController = {}
FoeController.__index = FoeController

-- CONFIGURATION (You should move these to your FoeConfig modules)
local AGGRO_RANGE = 50
local ATTACK_RANGE = 6
local DEAGGRO_RANGE = 100 -- Must be > AGGRO_RANGE
local REGEN_RATE = 5 -- HP per second
local WANDER_RADIUS = 50
local WANDER_COOLDOWN = 7 -- Time between wanders
local ATTACK_COOLDOWN = 2

-- Define states
local STATES = {
	Idle = "Idle",
	Chase = "Chase",
	Attack = "Attack"
}

function FoeController.new(blueprint, model)
	local self = setmetatable({}, FoeController)

	self.Model = model
	self.Humanoid = model:WaitForChild("Humanoid")
	self.RootPart = model:WaitForChild("HumanoidRootPart")
	self.Config = blueprint -- Store the blueprint

	-- 1. Apply Stats from Blueprint
	self.Name = blueprint.Name
	self.Humanoid.MaxHealth = blueprint.Health
	self.Humanoid.Health = blueprint.Health
	self.Humanoid.WalkSpeed = blueprint.WalkSpeed

	-- 2. Store Behaviors from Blueprint
	self.AttackBehavior = blueprint.AttackBehavior
	-- self.MoveBehavior is no longer used; logic is internal

	-- 3. State Machine Properties
	self.IsAlive = true
	self.State = STATES.Idle
	self.Target = nil
	self.HomePosition = self.RootPart.Position

	-- 4. Timers
	self.attackTimer = 0
	self.wanderTimer = math.random(0, WANDER_COOLDOWN) -- Stagger initial wanders

	-- 5. Pathfinding Object
	self.Path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true
	})

	-- Connect to the Humanoid's Died event
	self.Humanoid.Died:Connect(function()
		self:Die()
	end)

	-- print("New FoeController *Agent* created for: " .. self.Name)
	return self
end

---------------------------------------------------------------------
-- THE "BRAIN" - This must be called from a central game loop
---------------------------------------------------------------------

function FoeController:Update(dt)
	if not self.IsAlive then return end

	-- Decrement timers
	self.attackTimer = math.max(0, self.attackTimer - dt)
	self.wanderTimer = math.max(0, self.wanderTimer - dt)

	-- Run state logic
	if self.State == STATES.Idle then
		self:UpdateIdle(dt)
	elseif self.State == STATES.Chase then
		self:UpdateChase(dt)
	elseif self.State == STATES.Attack then
		self:UpdateAttack(dt)
	end
end

---------------------------------------------------------------------
-- STATE LOGIC
---------------------------------------------------------------------

-- STATE: IDLE
function FoeController:UpdateIdle(dt)
	-- 1. Regenerate Health
	if self.Humanoid.Health < self.Humanoid.MaxHealth then
		self.Humanoid.Health = math.min(self.Humanoid.Health + (REGEN_RATE * dt), self.Humanoid.MaxHealth)
	end

	-- 2. Check for Target
	local target = self:FindTarget(AGGRO_RANGE)
	if target then
		self:SetState(STATES.Chase, target)
		return
	end

	-- 3. Wander Logic
	if self.wanderTimer <= 0 then
		self.wanderTimer = WANDER_COOLDOWN + math.random(-2, 2)
		local randomPos = self.HomePosition + Vector3.new(
			math.random(-WANDER_RADIUS, WANDER_RADIUS),
			0,
			math.random(-WANDER_RADIUS, WANDER_RADIUS)
		)
		self:MoveTo(randomPos)
	end
end

-- STATE: CHASE
function FoeController:UpdateChase(dt)
	-- 1. Validate Target
	if not self:IsValidTarget(self.Target, DEAGGRO_RANGE) then
		self:SetState(STATES.Idle)
		return
	end

	local targetRoot = self.Target.PrimaryPart
	local distance = (self.RootPart.Position - targetRoot.Position).Magnitude

	-- 2. Check if in Attack Range
	if distance <= ATTACK_RANGE then
		self:SetState(STATES.Attack)
		return
	end

	-- 3. Continue moving to target
	-- (Optimize: Only re-compute path every 0.5s, not every frame)
	self:MoveTo(targetRoot.Position)
end

-- STATE: ATTACK
function FoeController:UpdateAttack(dt)
	-- 1. Validate Target
	if not self:IsValidTarget(self.Target, ATTACK_RANGE * 1.5) then -- Use slightly larger range
		self:SetState(STATES.Chase)
		return
	end

	-- 2. Face Target
	self.RootPart.CFrame = CFrame.new(self.RootPart.Position, Vector3.new(
		self.Target.PrimaryPart.Position.x,
		self.RootPart.Position.y,
		self.Target.PrimaryPart.Position.z
		))

	-- 3. Attack (using your modular behavior)
	if self.attackTimer <= 0 and self.AttackBehavior then
		self.attackTimer = ATTACK_COOLDOWN
		self.AttackBehavior.Execute(self.Model, self.Target)
	end
end

---------------------------------------------------------------------
-- HELPER FUNCTIONS (Internal Logic)
---------------------------------------------------------------------

function FoeController:SetState(newState, target)
	if self.State == newState then return end -- No change

	-- print(self.Name .. " switching state to " .. newState)
	self.State = newState
	self.Target = target or nil

	if newState == STATES.Idle then
		self.Humanoid:MoveTo(self.RootPart.Position) -- Stop moving
	end
end

function FoeController:FindTarget(range)
	local closestTarget = nil
	local minDistance = range

	for _, player in pairs(Players:GetPlayers()) do
		local char = player.Character
		local targetRoot = char and char:FindFirstChild("HumanoidRootPart")
		local targetHumanoid = char and char:FindFirstChild("Humanoid")

		if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
			local distance = (self.RootPart.Position - targetRoot.Position).Magnitude
			if distance < minDistance then
				closestTarget = char
				minDistance = distance
			end
		end
	end
	return closestTarget
end

function FoeController:IsValidTarget(target, range)
	if not target or not target.PrimaryPart or not target:FindFirstChild("Humanoid") or target.Humanoid.Health <= 0 then
		return false
	end

	local distance = (self.RootPart.Position - target.PrimaryPart.Position).Magnitude
	return distance <= range
end

function FoeController:MoveTo(destination)
	-- Using simple MoveTo for this implementation.
	-- For more robust pathfinding, compute self.Path
	-- and iterate through waypoints.
	self.Humanoid:MoveTo(destination)
end

---------------------------------------------------------------------
-- EXISTING FUNCTIONS (Unchanged)
---------------------------------------------------------------------

-- This function is still valid for external damage sources (e.g., player attacks)
function FoeController:TakeDamage(amount)
	if not self.IsAlive then return end
	self.Humanoid:TakeDamage(amount)
end

function FoeController:Die()
	if not self.IsAlive then return end -- Prevent multiple calls

	self.IsAlive = false
	self.Target = nil
	self.State = nil -- Stop all logic

	-- print(self.Name .. " has died.")
	-- Add particle effects, drop loot, etc.
	Debris:AddItem(self.Model, 3) -- Clean up body after 3 seconds
end

-- This function is now OBSOLETE and should not be called.
-- The AI decides when to attack via its Update() loop.
function FoeController:Attack(target)
	warn("FoeController:Attack() is obsolete. AI is autonomous.")
	-- if not self.IsAlive or not self.AttackBehavior then return end
	-- self.AttackBehavior.Execute(self.Model, target)
end

return FoeController
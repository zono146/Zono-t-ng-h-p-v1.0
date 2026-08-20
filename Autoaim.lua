local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==============================================================
-- STATE
--==============================================================

local aimEnabled = false
local lockedTarget = nil

--==============================================================
-- CONFIG
--==============================================================

local MAX_TARGET_DISTANCE = math.huge
local CAMERA_HEIGHT = 2.5
local DEFAULT_ZOOM = 10
local MIN_ZOOM = 2

--==============================================================
-- GUI
--==============================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HeartBattlegroundAimGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 100)
mainFrame.Position = UDim2.new(0.05, 0, 0.4, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(255, 50, 50)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Text = "HEART BATTLEGROUND"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 14
titleLabel.Parent = mainFrame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.8, 0, 0.4, 0)
toggleBtn.Position = UDim2.new(0.1, 0, 0.45, 0)
toggleBtn.Text = "AUTO AIM: OFF"
toggleBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 16
toggleBtn.Parent = mainFrame

--==============================================================
-- UTILITY
--==============================================================

local function GetCharacterRoot(character)
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
		or character:FindFirstChild("Head")
end

local function GetHumanoid(character)
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function IsCharacterValid(character)
	if not character then
		return false
	end

	local humanoid = GetHumanoid(character)
	local root = GetCharacterRoot(character)

	return humanoid
		and humanoid.Health > 0
		and root
		and root:IsDescendantOf(workspace)
end

local function IsTargetValid(target)
	if not target then
		return false
	end

	if not target:IsDescendantOf(workspace) then
		return false
	end

	local character = target:FindFirstAncestorOfClass("Model")
	if not character then
		return false
	end

	return IsCharacterValid(character)
end

--==============================================================
-- FIND CLOSEST TARGET
--
-- Unlike the old version, this does NOT choose randomly and
-- does not prioritize angle.
--
-- The nearest valid player is always selected.
--==============================================================

local function GetClosestTarget()
	local myCharacter = LocalPlayer.Character

	if not IsCharacterValid(myCharacter) then
		return nil
	end

	local myRoot = GetCharacterRoot(myCharacter)
	if not myRoot then
		return nil
	end

	local myPosition = myRoot.Position

	local closestTarget = nil
	local closestDistance = MAX_TARGET_DISTANCE

	for _, player in ipairs(Players:GetPlayers()) do

		-- Never target ourselves.
		if player ~= LocalPlayer then

			local character = player.Character

			if IsCharacterValid(character) then

				local targetRoot = GetCharacterRoot(character)

				if targetRoot then
					local distance =
						(targetRoot.Position - myPosition).Magnitude

					if distance < closestDistance then
						closestDistance = distance
						closestTarget = targetRoot
					end
				end
			end
		end
	end

	return closestTarget
end

--==============================================================
-- TARGET VALIDATION / AUTO REACQUIRE
--==============================================================

local function AcquireNewTarget()
	local newTarget = GetClosestTarget()

	lockedTarget = newTarget

	if newTarget then
		toggleBtn.Text = "AUTO AIM: LOCKED"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	else
		toggleBtn.Text = "NO TARGET!"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
	end

	return newTarget
end

local function TargetNeedsReacquire()
	if not IsTargetValid(lockedTarget) then
		return true
	end

	local targetCharacter = lockedTarget:FindFirstAncestorOfClass("Model")
	local targetHumanoid = GetHumanoid(targetCharacter)

	if not targetHumanoid or targetHumanoid.Health <= 0 then
		return true
	end

	return false
end

--==============================================================
-- CAMERA AIM
--==============================================================

local function AimAtTarget(target)
	if not IsTargetValid(target) then
		return false
	end

	local myCharacter = LocalPlayer.Character
	if not IsCharacterValid(myCharacter) then
		return false
	end

	local myRoot = GetCharacterRoot(myCharacter)
	if not myRoot then
		return false
	end

	local targetPosition = target.Position
	local myPosition = myRoot.Position

	local direction = targetPosition - myPosition

	if direction.Magnitude <= 0.001 then
		direction = myRoot.CFrame.LookVector
	else
		direction = direction.Unit
	end

	-- Preserve the current camera distance where possible.
	local currentZoom =
		(Camera.CFrame.Position - myPosition).Magnitude

	if currentZoom < MIN_ZOOM then
		currentZoom = DEFAULT_ZOOM
	end

	-- Keep camera behind the player relative to the target.
	local cameraOffset =
		-direction * currentZoom
		+ Vector3.new(0, CAMERA_HEIGHT, 0)

	local newCameraPosition =
		myPosition + cameraOffset

	Camera.CFrame =
		CFrame.new(
			newCameraPosition,
			targetPosition
		)

	return true
end

--==============================================================
-- MAIN AIM LOOP
--
-- Every frame:
--
-- 1. Make sure aim is enabled.
-- 2. Check whether the current target still exists.
-- 3. If dead / respawned / removed / invalid -> reacquire.
-- 4. Aim at the currently locked target.
--
-- This means a player leaving the server naturally disappears
-- from Players:GetPlayers(), allowing another target to be found.
--==============================================================

RunService.RenderStepped:Connect(function()

	if not aimEnabled then
		return
	end

	-- No current target or target became invalid.
	if TargetNeedsReacquire() then
		AcquireNewTarget()
	end

	-- Aim at the current target.
	if lockedTarget then
		local success = AimAtTarget(lockedTarget)

		-- Something changed between validation and aiming.
		-- Immediately switch to another target.
		if not success then
			AcquireNewTarget()
		end
	end

end)

--==============================================================
-- EXTRA EVENT-BASED REACQUISITION
--
-- These events make target recovery happen immediately instead
-- of waiting for the next character state change to propagate.
--==============================================================

local function WatchPlayer(player)

	-- Player respawns.
	player.CharacterAdded:Connect(function()

		if not aimEnabled then
			return
		end

		-- If this was our old target, replace it.
		if lockedTarget then
			local oldCharacter =
				lockedTarget:FindFirstAncestorOfClass("Model")

			if oldCharacter == player.Character then
				lockedTarget = nil
				AcquireNewTarget()
			end
		end
	end)

	-- Player leaves the server.
	player.AncestryChanged:Connect(function(_, parent)

		if parent == nil and aimEnabled then
			if lockedTarget then
				local character =
					lockedTarget:FindFirstAncestorOfClass("Model")

				if character == player.Character then
					lockedTarget = nil
					AcquireNewTarget()
				end
			end
		end
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	WatchPlayer(player)
end

Players.PlayerAdded:Connect(function(player)
	WatchPlayer(player)

	-- A new player appearing doesn't steal the current lock.
	-- The current target remains locked until invalid.
end)

Players.PlayerRemoving:Connect(function(player)

	if not aimEnabled or not lockedTarget then
		return
	end

	local character =
		lockedTarget:FindFirstAncestorOfClass("Model")

	if character == player.Character then
		lockedTarget = nil
		AcquireNewTarget()
	end
end)

--==============================================================
-- HANDLE LOCAL PLAYER RESPAWN
--==============================================================

LocalPlayer.CharacterAdded:Connect(function()

	-- The local character changing invalidates old positional data.
	lockedTarget = nil

	if aimEnabled then
		task.defer(function()
			AcquireNewTarget()
		end)
	end
end)

--==============================================================
-- TOGGLE
--==============================================================

toggleBtn.MouseButton1Click:Connect(function()

	aimEnabled = not aimEnabled

	if aimEnabled then

		-- Always start by selecting the closest available player.
		AcquireNewTarget()

	else

		lockedTarget = nil

		toggleBtn.Text = "AUTO AIM: OFF"
		toggleBtn.BackgroundColor3 =
			Color3.fromRGB(150, 50, 50)
	end

end)

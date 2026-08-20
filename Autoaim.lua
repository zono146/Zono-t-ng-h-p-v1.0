--[[
==============================================================
 HEART BATTLEGROUND
 Auto Aim + Random TP
==============================================================
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==============================================================
-- STATE
--==============================================================

local aimEnabled = false
local lockedTarget = nil

local randomTPEnabled = false
local originalCFrame = nil
local randomTPAccumulator = 0
local randomTPDelay = 0.45
local lastRandomTarget = nil

--==============================================================
-- GUI
--==============================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HeartBattlegroundAimGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 230, 0, 155)
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

--==============================================================
-- AIM BUTTON
--==============================================================

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.82, 0, 0, 42)
toggleBtn.Position = UDim2.new(0.09, 0, 0, 38)
toggleBtn.Text = "AUTO AIM: OFF"
toggleBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 16
toggleBtn.Parent = mainFrame

--==============================================================
-- RANDOM TP BUTTON
--==============================================================

local randomTPBtn = Instance.new("TextButton")
randomTPBtn.Size = UDim2.new(0.82, 0, 0, 42)
randomTPBtn.Position = UDim2.new(0.09, 0, 0, 91)
randomTPBtn.Text = "RANDOM TP: OFF"
randomTPBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
randomTPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
randomTPBtn.Font = Enum.Font.SourceSansBold
randomTPBtn.TextSize = 16
randomTPBtn.Parent = mainFrame

--==============================================================
-- CHARACTER HELPERS
--==============================================================

local function GetCharacter(player)
	return player and player.Character
end

local function GetHumanoid(character)
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function GetRoot(character)
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

--==============================================================
-- AIM TARGET FINDER
--==============================================================

local function GetBestTarget()
	local myChar = LocalPlayer.Character

	if not myChar then
		return nil
	end

	local myRoot = GetRoot(myChar)

	if not myRoot then
		return nil
	end

	local myPos = myRoot.Position

	local closestAngleTarget = nil
	local smallestAngle = 45

	local closestDistanceTarget = nil
	local smallestDistance = math.huge

	for _, obj in ipairs(workspace:GetDescendants()) do

		if obj:IsA("Model") and obj ~= myChar then

			local hum =
				obj:FindFirstChildOfClass("Humanoid")

			local hrp =
				obj:FindFirstChild("HumanoidRootPart")
				or obj:FindFirstChild("Head")

			if hum and hrp and hum.Health > 0 then

				local targetPos = hrp.Position
				local dist =
					(targetPos - myPos).Magnitude

				local offset =
					targetPos - Camera.CFrame.Position

				if offset.Magnitude > 0 then

					local camDirection =
						Camera.CFrame.LookVector

					local dirToTarget =
						offset.Unit

					local dot =
						math.clamp(
							camDirection:Dot(dirToTarget),
							-1,
							1
						)

					local angle =
						math.deg(
							math.acos(dot)
						)

					if angle < smallestAngle then

						smallestAngle = angle
						closestAngleTarget = hrp

					end
				end

				if dist < smallestDistance then

					smallestDistance = dist
					closestDistanceTarget = hrp

				end
			end
		end
	end

	return closestAngleTarget
		or closestDistanceTarget
end

--==============================================================
-- RANDOM PLAYER FINDER
--==============================================================

local function GetRandomPlayer()

	local candidates = {}

	local myCharacter =
		LocalPlayer.Character

	for _, player in ipairs(Players:GetPlayers()) do

		if player ~= LocalPlayer then

			local character =
				GetCharacter(player)

			local humanoid =
				GetHumanoid(character)

			local root =
				GetRoot(character)

			if
				character
				and humanoid
				and root
				and humanoid.Health > 0
			then

				-- Avoid selecting the exact same player twice
				-- whenever another valid player exists.
				if player ~= lastRandomTarget then
					table.insert(
						candidates,
						player
					)
				end

			end
		end
	end

	-- If only one valid player exists, allow them again.
	if #candidates == 0 then

		for _, player in ipairs(Players:GetPlayers()) do

			if player ~= LocalPlayer then

				local character =
					GetCharacter(player)

				local humanoid =
					GetHumanoid(character)

				local root =
					GetRoot(character)

				if
					character
					and humanoid
					and root
					and humanoid.Health > 0
				then

					table.insert(
						candidates,
						player
					)

				end
			end
		end
	end

	if #candidates == 0 then
		return nil
	end

	return candidates[
		math.random(
			1,
			#candidates
		)
	]
end

--==============================================================
-- RANDOM TELEPORT
--==============================================================

local function RandomTeleport()

	if not randomTPEnabled then
		return
	end

	local myCharacter =
		LocalPlayer.Character

	if not myCharacter then
		return
	end

	local myRoot =
		GetRoot(myCharacter)

	if not myRoot then
		return
	end

	local humanoid =
		GetHumanoid(myCharacter)

	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local target =
		GetRandomPlayer()

	if not target then
		return
	end

	local targetCharacter =
		target.Character

	local targetRoot =
		GetRoot(targetCharacter)

	if not targetRoot then
		return
	end

	-- Remember which player was selected.
	lastRandomTarget = target

	-- Actual character relocation.
	--
	-- PivotTo changes the character's world transform.
	-- The small vertical offset prevents the character from
	-- being placed directly inside the target's root.
	local destination =
		targetRoot.CFrame
		* CFrame.new(
			math.random(-4, 4),
			2,
			math.random(-4, 4)
		)

	myCharacter:PivotTo(destination)

	-- Stop leftover velocity from making the character
	-- immediately drift away after teleporting.
	local newRoot =
		GetRoot(myCharacter)

	if newRoot then

		newRoot.AssemblyLinearVelocity =
			Vector3.zero

		newRoot.AssemblyAngularVelocity =
			Vector3.zero

	end

	-- Randomize the next jump slightly.
	randomTPDelay =
		math.random(30, 70) / 100

end

--==============================================================
-- AIM LOOP
--==============================================================

RunService.RenderStepped:Connect(function()

	if not aimEnabled or not lockedTarget then
		return
	end

	local myChar =
		LocalPlayer.Character

	local myHRP =
		myChar and
		myChar:FindFirstChild(
			"HumanoidRootPart"
		)

	local parentModel =
		lockedTarget.Parent

	local hum =
		parentModel
		and parentModel:FindFirstChildOfClass(
			"Humanoid"
		)

	if
		parentModel
		and hum
		and hum.Health > 0
		and myHRP
	then

		local targetPos =
			lockedTarget.Position

		local myPos =
			myHRP.Position

		local currentZoom =
			(
				Camera.CFrame.Position
				- myPos
			).Magnitude

		if currentZoom < 2 then
			currentZoom = 10
		end

		local offset =
			targetPos - myPos

		if offset.Magnitude <= 0 then
			return
		end

		local dirToTarget =
			offset.Unit

		local camOffset =
			-dirToTarget * currentZoom
			+ Vector3.new(
				0,
				2.5,
				0
			)

		local newCamPos =
			myPos + camOffset

		Camera.CFrame =
			CFrame.new(
				newCamPos,
				targetPos
			)

	else

		lockedTarget = nil

	end

end)

--==============================================================
-- RANDOM TP LOOP
--==============================================================

RunService.Heartbeat:Connect(function(deltaTime)

	if not randomTPEnabled then
		return
	end

	randomTPAccumulator += deltaTime

	if randomTPAccumulator >= randomTPDelay then

		randomTPAccumulator = 0

		RandomTeleport()

	end

end)

--==============================================================
-- AIM TOGGLE
--==============================================================

toggleBtn.MouseButton1Click:Connect(function()

	aimEnabled =
		not aimEnabled

	if aimEnabled then

		lockedTarget =
			GetBestTarget()

		if lockedTarget then

			toggleBtn.Text =
				"AUTO AIM: LOCKED"

			toggleBtn.BackgroundColor3 =
				Color3.fromRGB(
					50,
					150,
					50
				)

		else

			aimEnabled = false

			toggleBtn.Text =
				"AUTO AIM: NO TARGET"

			toggleBtn.BackgroundColor3 =
				Color3.fromRGB(
					200,
					100,
					0
				)

		end

	else

		lockedTarget = nil

		toggleBtn.Text =
			"AUTO AIM: OFF"

		toggleBtn.BackgroundColor3 =
			Color3.fromRGB(
				150,
				50,
				50
			)

	end

end)

--==============================================================
-- RANDOM TP TOGGLE
--==============================================================

randomTPBtn.MouseButton1Click:Connect(function()

	randomTPEnabled =
		not randomTPEnabled

	if randomTPEnabled then

		local character =
			LocalPlayer.Character

		local root =
			GetRoot(character)

		if not root then

			randomTPEnabled = false

			randomTPBtn.Text =
				"RANDOM TP: NO CHARACTER"

			randomTPBtn.BackgroundColor3 =
				Color3.fromRGB(
					200,
					100,
					0
				)

			return
		end

		-- Save the exact location before any teleport occurs.
		originalCFrame =
			character:GetPivot()

		lastRandomTarget = nil
		randomTPAccumulator = 0

		randomTPBtn.Text =
			"RANDOM TP: ACTIVE"

		randomTPBtn.BackgroundColor3 =
			Color3.fromRGB(
				50,
				150,
				50
			)

		-- Perform the first jump immediately.
		RandomTeleport()

	else

		randomTPBtn.Text =
			"RANDOM TP: OFF"

		randomTPBtn.BackgroundColor3 =
			Color3.fromRGB(
				150,
				50,
				50
			)

		-- Return to the exact transform saved when the
		-- feature was enabled.
		if originalCFrame then

			local character =
				LocalPlayer.Character

			if character then

				character:PivotTo(
					originalCFrame
				)

				local root =
					GetRoot(character)

				if root then

					root.AssemblyLinearVelocity =
						Vector3.zero

					root.AssemblyAngularVelocity =
						Vector3.zero

				end

			end

		end

		originalCFrame = nil
		lastRandomTarget = nil
		randomTPAccumulator = 0

	end

end)

--==============================================================
-- RESPAWN HANDLING
--==============================================================

LocalPlayer.CharacterAdded:Connect(function(character)

	-- A respawn creates a completely new character, so the old
	-- transform is no longer valid.

	if randomTPEnabled then

		task.wait(0.2)

		originalCFrame =
			character:GetPivot()

		randomTPAccumulator = 0

	end

end)

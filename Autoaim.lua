local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- =========================================================
-- LOCK TEST SYSTEM
-- =========================================================
local lockEnabled = false
local lockedTarget = nil

-- =========================================================
-- THEME
-- =========================================================
local THEME = {
	Background = Color3.fromRGB(15, 17, 24),
	Panel = Color3.fromRGB(21, 24, 33),
	PanelLight = Color3.fromRGB(28, 32, 43),
	Stroke = Color3.fromRGB(54, 60, 78),
	Text = Color3.fromRGB(245, 247, 255),
	Muted = Color3.fromRGB(145, 151, 170),
	Accent = Color3.fromRGB(132, 88, 255),
	AccentDark = Color3.fromRGB(91, 56, 196),
	Success = Color3.fromRGB(65, 210, 135),
	Danger = Color3.fromRGB(235, 82, 104),
	Warning = Color3.fromRGB(242, 171, 72),
}

local function tween(object, properties, duration)
	local info = TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	TweenService:Create(object, info, properties):Play()
end

local function addCorner(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = object
	return corner
end

local function addStroke(object, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or THEME.Stroke
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = object
	return stroke
end

-- =========================================================
-- GUI: WINDOW / TAG STYLE
-- =========================================================
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("HeartBattlegroundAdminGui")
if oldGui then
	oldGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HeartBattlegroundAdminGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local WINDOW_W, WINDOW_H = 360, 258
local MINI_H = 56
local minimized = false
local closed = false

-- ---------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------
local function makeButton(parent, name, text, size, position)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = THEME.PanelLight
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = THEME.Muted
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.AutoButtonColor = false
	button.Parent = parent
	addCorner(button, 9)
	addStroke(button, THEME.Stroke, 1, 0.2)
	return button
end

-- ---------------------------------------------------------
-- Window shadow + body
-- ---------------------------------------------------------
local shadow = Instance.new("Frame")
shadow.Name = "Shadow"
shadow.Size = UDim2.new(0, WINDOW_W + 8, 0, WINDOW_H + 8)
shadow.Position = UDim2.new(0.05, 4, 0.34, 6)
shadow.BackgroundColor3 = Color3.new(0, 0, 0)
shadow.BackgroundTransparency = 0.52
shadow.BorderSizePixel = 0
shadow.ZIndex = 0
shadow.Parent = screenGui
addCorner(shadow, 16)

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Window"
mainFrame.Size = UDim2.new(0, WINDOW_W, 0, WINDOW_H)
mainFrame.Position = UDim2.new(0.05, 0, 0.34, 0)
mainFrame.BackgroundColor3 = THEME.Background
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.ZIndex = 1
mainFrame.Parent = screenGui
addCorner(mainFrame, 16)
addStroke(mainFrame, THEME.Stroke, 1, 0.12)

-- ---------------------------------------------------------
-- Title bar
-- ---------------------------------------------------------
local header = Instance.new("Frame")
header.Name = "TitleBar"
header.Size = UDim2.new(1, 0, 0, MINI_H)
header.BackgroundColor3 = THEME.Panel
header.BorderSizePixel = 0
header.Parent = mainFrame
addCorner(header, 16)

local headerFill = Instance.new("Frame")
headerFill.Size = UDim2.new(1, 0, 0, 15)
headerFill.Position = UDim2.new(0, 0, 1, -15)
headerFill.BackgroundColor3 = THEME.Panel
headerFill.BorderSizePixel = 0
headerFill.Parent = header

local accentBar = Instance.new("Frame")
accentBar.Size = UDim2.new(0, 4, 0, 28)
accentBar.Position = UDim2.new(0, 10, 0, 14)
accentBar.BackgroundColor3 = THEME.Accent
accentBar.BorderSizePixel = 0
accentBar.Parent = header
addCorner(accentBar, 4)

local icon = Instance.new("TextLabel")
icon.Size = UDim2.new(0, 30, 0, 30)
icon.Position = UDim2.new(0, 20, 0, 13)
icon.BackgroundTransparency = 1
icon.Text = "⚡"
icon.TextColor3 = THEME.Text
icon.Font = Enum.Font.GothamBold
icon.TextSize = 17
icon.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -145, 0, 20)
titleLabel.Position = UDim2.new(0, 52, 0, 8)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "ADMIN TEST"
titleLabel.TextColor3 = THEME.Text
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -145, 0, 16)
subtitle.Position = UDim2.new(0, 52, 0, 28)
subtitle.BackgroundTransparency = 1
subtitle.Text = "TESTING WINDOW  •  v1"
subtitle.TextColor3 = THEME.Muted
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextSize = 9
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = header

local minimizeButton = makeButton(header, "Minimize", "—", UDim2.new(0, 30, 0, 30), UDim2.new(1, -78, 0, 13))
local closeButton = makeButton(header, "Close", "×", UDim2.new(0, 30, 0, 30), UDim2.new(1, -42, 0, 13))
closeButton.BackgroundColor3 = Color3.fromRGB(56, 31, 39)
closeButton.TextColor3 = THEME.Danger

local divider = Instance.new("Frame")
divider.Name = "Divider"
divider.Size = UDim2.new(1, -28, 0, 1)
divider.Position = UDim2.new(0, 14, 0, MINI_H)
divider.BackgroundColor3 = THEME.Stroke
divider.BackgroundTransparency = 0.25
divider.BorderSizePixel = 0
divider.Parent = mainFrame

-- ---------------------------------------------------------
-- Status card
-- ---------------------------------------------------------
local statusCard = Instance.new("Frame")
statusCard.Name = "StatusCard"
statusCard.Size = UDim2.new(1, -28, 0, 72)
statusCard.Position = UDim2.new(0, 14, 0, 70)
statusCard.BackgroundColor3 = THEME.Panel
statusCard.BorderSizePixel = 0
statusCard.Parent = mainFrame
addCorner(statusCard, 12)
addStroke(statusCard, THEME.Stroke, 1, 0.25)

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 10, 0, 10)
statusDot.Position = UDim2.new(0, 14, 0, 17)
statusDot.BackgroundColor3 = THEME.Danger
statusDot.BorderSizePixel = 0
statusDot.Parent = statusCard
addCorner(statusDot, 50)

local statusTitle = Instance.new("TextLabel")
statusTitle.Size = UDim2.new(0.48, 0, 0, 20)
statusTitle.Position = UDim2.new(0, 34, 0, 8)
statusTitle.BackgroundTransparency = 1
statusTitle.Text = "LOCK STATUS"
statusTitle.TextColor3 = THEME.Text
statusTitle.Font = Enum.Font.GothamBold
statusTitle.TextSize = 12
statusTitle.TextXAlignment = Enum.TextXAlignment.Left
statusTitle.Parent = statusCard

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0.62, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 34, 0, 31)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "INACTIVE • No target"
statusLabel.TextColor3 = THEME.Muted
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextSize = 10
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = statusCard

local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(0.33, 0, 0, 20)
targetLabel.Position = UDim2.new(0.63, 0, 0, 28)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "TARGET: —"
targetLabel.TextColor3 = THEME.Muted
targetLabel.Font = Enum.Font.GothamBold
targetLabel.TextSize = 9
targetLabel.TextXAlignment = Enum.TextXAlignment.Right
targetLabel.TextTruncate = Enum.TextTruncate.AtEnd
targetLabel.Parent = statusCard

-- ---------------------------------------------------------
-- Main lock control
-- ---------------------------------------------------------
local lockButton = Instance.new("TextButton")
lockButton.Name = "LockButton"
lockButton.Size = UDim2.new(1, -28, 0, 50)
lockButton.Position = UDim2.new(0, 14, 0, 153)
lockButton.BackgroundColor3 = THEME.PanelLight
lockButton.BorderSizePixel = 0
lockButton.Text = "LOCK  •  OFF"
lockButton.TextColor3 = THEME.Text
lockButton.Font = Enum.Font.GothamBold
lockButton.TextSize = 13
lockButton.AutoButtonColor = false
lockButton.Parent = mainFrame
addCorner(lockButton, 12)
local lockStroke = addStroke(lockButton, THEME.Stroke, 1, 0.2)

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -28, 0, 22)
hint.Position = UDim2.new(0, 14, 0, 214)
hint.BackgroundTransparency = 1
hint.Text = "Acquire target  •  Toggle Lock"
hint.TextColor3 = THEME.Muted
hint.Font = Enum.Font.GothamMedium
hint.TextSize = 9
hint.TextXAlignment = Enum.TextXAlignment.Center
hint.Parent = mainFrame

-- ---------------------------------------------------------
-- Re-open button shown after closing
-- ---------------------------------------------------------
local reopenButton = Instance.new("TextButton")
reopenButton.Name = "Reopen"
reopenButton.Size = UDim2.new(0, 52, 0, 52)
reopenButton.Position = UDim2.new(0, 20, 0.84, 0)
reopenButton.BackgroundColor3 = THEME.Panel
reopenButton.BorderSizePixel = 0
reopenButton.Text = "⚡"
reopenButton.TextColor3 = THEME.Text
reopenButton.Font = Enum.Font.GothamBold
reopenButton.TextSize = 20
reopenButton.AutoButtonColor = false
reopenButton.Visible = false
reopenButton.Parent = screenGui
addCorner(reopenButton, 14)
addStroke(reopenButton, THEME.Accent, 1, 0.05)

-- ---------------------------------------------------------
-- Window dragging (title bar only)
-- ---------------------------------------------------------
local dragging = false
local dragStart
local startPosition

local function syncShadow()
	shadow.Position = UDim2.new(
		mainFrame.Position.X.Scale,
		mainFrame.Position.X.Offset + 5,
		mainFrame.Position.Y.Scale,
		mainFrame.Position.Y.Offset + 7
	)
end

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPosition = mainFrame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		local newPos = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
		mainFrame.Position = newPos
		syncShadow()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

-- ---------------------------------------------------------
-- Button animation helper
-- ---------------------------------------------------------
local function setupHover(button, normalColor, hoverColor, pressedColor)
	button.MouseEnter:Connect(function()
		tween(button, {BackgroundColor3 = hoverColor, TextColor3 = THEME.Text}, 0.12)
	end)
	button.MouseLeave:Connect(function()
		tween(button, {BackgroundColor3 = normalColor}, 0.12)
	end)
	button.MouseButton1Down:Connect(function()
		tween(button, {BackgroundColor3 = pressedColor or hoverColor}, 0.07)
	end)
	button.MouseButton1Up:Connect(function()
		tween(button, {BackgroundColor3 = hoverColor}, 0.07)
	end)
end

setupHover(minimizeButton, THEME.PanelLight, Color3.fromRGB(41, 45, 59), Color3.fromRGB(50, 54, 70))
setupHover(closeButton, Color3.fromRGB(56, 31, 39), Color3.fromRGB(77, 37, 48), Color3.fromRGB(92, 43, 57))
setupHover(lockButton, THEME.PanelLight, Color3.fromRGB(38, 42, 56), Color3.fromRGB(48, 52, 68))
setupHover(reopenButton, THEME.Panel, Color3.fromRGB(36, 40, 54), Color3.fromRGB(43, 47, 62))

-- =========================================================
-- TARGET SEARCH
-- =========================================================
local function GetBestTarget()
	local myChar = LocalPlayer.Character
	local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myHRP then
		return nil
	end

	local myPos = myHRP.Position
	local closestAngleTarget = nil
	local smallestAngle = 45
	local closestDistanceTarget = nil
	local smallestDistance = math.huge

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and obj ~= myChar then
			local hum = obj:FindFirstChildOfClass("Humanoid")
			local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")

			if hum and hrp and hum.Health > 0 then
				local offset = hrp.Position - Camera.CFrame.Position
				local distanceFromMe = (hrp.Position - myPos).Magnitude

				if offset.Magnitude > 0 then
					local direction = offset.Unit
					local dot = math.clamp(Camera.CFrame.LookVector:Dot(direction), -1, 1)
					local angle = math.deg(math.acos(dot))

					if angle < smallestAngle then
						smallestAngle = angle
						closestAngleTarget = hrp
					end
				end

				if distanceFromMe < smallestDistance then
					smallestDistance = distanceFromMe
					closestDistanceTarget = hrp
				end
			end
		end
	end

	return closestAngleTarget or closestDistanceTarget
end

local function getTargetName(target)
	if not target then
		return "—"
	end

	local model = target:FindFirstAncestorOfClass("Model")
	if not model then
		return target.Name
	end

	local player = Players:GetPlayerFromCharacter(model)
	return player and player.DisplayName or model.Name
end

local function setLockVisual(mode, message)
	if mode == "ON" then
		statusDot.BackgroundColor3 = THEME.Success
		statusTitle.Text = "Lock status"
		statusLabel.Text = message or "ACTIVE • Target acquired"
		statusLabel.TextColor3 = THEME.Success
		lockButton.Text = "LOCK  •  ON"
		lockButton.BackgroundColor3 = THEME.AccentDark
		lockStroke.Color = THEME.Accent
		targetLabel.Text = "TARGET: " .. getTargetName(lockedTarget)
	elseif mode == "WARNING" then
		statusDot.BackgroundColor3 = THEME.Warning
		statusLabel.Text = message or "ACTIVE • No target"
		statusLabel.TextColor3 = THEME.Warning
		lockButton.Text = "LOCK  •  NO TARGET"
		lockButton.BackgroundColor3 = Color3.fromRGB(91, 67, 34)
		lockStroke.Color = THEME.Warning
		targetLabel.Text = "TARGET: —"
	else
		statusDot.BackgroundColor3 = THEME.Danger
		statusLabel.Text = message or "INACTIVE • No target"
		statusLabel.TextColor3 = THEME.Muted
		lockButton.Text = "LOCK  •  OFF"
		lockButton.BackgroundColor3 = THEME.PanelLight
		lockStroke.Color = THEME.Stroke
		targetLabel.Text = "TARGET: —"
	end
end

-- =========================================================
-- CAMERA LOCK LOOP
-- =========================================================
RunService.RenderStepped:Connect(function()
	if not lockEnabled or not lockedTarget then
		return
	end

	local myChar = LocalPlayer.Character
	local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local parentModel = lockedTarget.Parent
	local hum = parentModel and parentModel:FindFirstChildOfClass("Humanoid")

	if not parentModel or not hum or hum.Health <= 0 or not myHRP or not lockedTarget:IsDescendantOf(workspace) then
		lockedTarget = nil
		lockEnabled = false
		setLockVisual("OFF", "INACTIVE • Target lost")
		return
	end

	local targetPos = lockedTarget.Position
	local myPos = myHRP.Position
	local between = targetPos - myPos

	if between.Magnitude <= 0.01 then
		return
	end

	local currentZoom = (Camera.CFrame.Position - myPos).Magnitude
	if currentZoom < 2 then
		currentZoom = 10
	end

	local dirToTarget = between.Unit
	local camOffset = -dirToTarget * currentZoom + Vector3.new(0, 2.5, 0)
	local newCamPos = myPos + camOffset

	Camera.CFrame = CFrame.new(newCamPos, targetPos)
end)

-- =========================================================
-- BUTTON INTERACTION
-- =========================================================
lockButton.MouseEnter:Connect(function()
	if not lockEnabled then
		tween(lockButton, {BackgroundColor3 = Color3.fromRGB(36, 40, 53)})
	else
		tween(lockButton, {BackgroundColor3 = THEME.Accent})
	end
end)

lockButton.MouseLeave:Connect(function()
	if not lockEnabled then
		tween(lockButton, {BackgroundColor3 = THEME.PanelLight})
	else
		tween(lockButton, {BackgroundColor3 = THEME.AccentDark})
	end
end)

lockButton.MouseButton1Down:Connect(function()
	tween(lockButton, {Size = UDim2.new(1, -31, 0, 46)})
end)

lockButton.MouseButton1Up:Connect(function()
	tween(lockButton, {Size = UDim2.new(1, -28, 0, 48)})
end)

lockButton.MouseButton1Click:Connect(function()
	lockEnabled = not lockEnabled

	if lockEnabled then
		lockedTarget = GetBestTarget()

		if lockedTarget then
			setLockVisual("ON")
		else
			setLockVisual("WARNING", "ACTIVE • No valid target")
		end
	else
		lockedTarget = nil
		setLockVisual("OFF")
	end
end)

-- =========================================================
-- WINDOW CONTROLS: MINIMIZE / CLOSE / REOPEN
-- =========================================================
local fullSize = UDim2.new(0, WINDOW_W, 0, WINDOW_H)
local miniSize = UDim2.new(0, WINDOW_W, 0, MINI_H)

local function showWindow()
	closed = false
	reopenButton.Visible = false
	mainFrame.Visible = true
	shadow.Visible = true
end

local function closeWindow()
	closed = true
	mainFrame.Visible = false
	shadow.Visible = false
	reopenButton.Visible = true

	-- Closing the window does NOT disable Lock; it only hides the UI.
	-- Lock can therefore keep running as a background test feature.
end

minimizeButton.MouseButton1Click:Connect(function()
	if closed then
		return
	end

	minimized = not minimized

	if minimized then
		minimizeButton.Text = "+"
		statusCard.Visible = false
		lockButton.Visible = false
		hint.Visible = false
		divider.Visible = false
		tween(mainFrame, {Size = miniSize})
		tween(shadow, {Size = UDim2.new(0, WINDOW_W + 8, 0, MINI_H + 8)})
	else
		minimizeButton.Text = "—"
		tween(mainFrame, {Size = fullSize})
		tween(shadow, {Size = UDim2.new(0, WINDOW_W + 8, 0, WINDOW_H + 8)})
		task.delay(0.10, function()
			if not minimized and not closed then
				statusCard.Visible = true
				lockButton.Visible = true
				hint.Visible = true
				divider.Visible = true
			end
		end)
	end
end)

closeButton.MouseButton1Click:Connect(function()
	-- Collapse state is reset so the next open starts as a normal window.
	minimized = false
	minimizeButton.Text = "—"
	statusCard.Visible = true
	lockButton.Visible = true
	hint.Visible = true
	divider.Visible = true
	mainFrame.Size = fullSize
	shadow.Size = UDim2.new(0, WINDOW_W + 8, 0, WINDOW_H + 8)
	closeWindow()
end)

reopenButton.MouseButton1Click:Connect(function()
	showWindow()
end)

-- Initial state
setLockVisual("OFF")
syncShadow()

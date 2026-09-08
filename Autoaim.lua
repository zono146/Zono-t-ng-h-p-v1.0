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
	PanelLight = Color3.fromRGB(29, 33, 44),
	PanelHover = Color3.fromRGB(39, 43, 57),
	Stroke = Color3.fromRGB(58, 64, 82),
	Text = Color3.fromRGB(245, 247, 255),
	Muted = Color3.fromRGB(145, 151, 170),
	Accent = Color3.fromRGB(132, 88, 255),
	AccentDark = Color3.fromRGB(91, 56, 196),
	Success = Color3.fromRGB(65, 210, 135),
	Danger = Color3.fromRGB(235, 82, 104),
	Warning = Color3.fromRGB(242, 171, 72),
}

local function tween(object, properties, duration, style, direction)
	local info = TweenInfo.new(
		duration or 0.2,
		style or Enum.EasingStyle.Quint,
		direction or Enum.EasingDirection.Out
	)
	local t = TweenService:Create(object, info, properties)
	t:Play()
	return t
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
	button.TextSize = 15
	button.AutoButtonColor = false
	button.Parent = parent
	addCorner(button, 8)
	addStroke(button, THEME.Stroke, 1, 0.2)
	return button
end

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

-- =========================================================
-- WINDOW STATE
-- =========================================================
local WINDOW_W, WINDOW_H = 440, 300
local MIN_W, MIN_H = 330, 230
local TITLE_H = 54
local SIDEBAR_W = 88
local minimized = false
local closed = false
local currentTab = "Status"
local savedSize = Vector2.new(WINDOW_W, WINDOW_H)
local resizing = false
local resizeMode = nil
local resizeStart = nil
local resizeStartSize = nil
local resizeStartPos = nil
local dragging = false
local dragStart = nil
local dragStartPos = nil

-- =========================================================
-- WINDOW + SHADOW
-- =========================================================
local shadow = Instance.new("Frame")
shadow.Name = "Shadow"
shadow.Size = UDim2.new(0, WINDOW_W + 10, 0, WINDOW_H + 10)
shadow.Position = UDim2.new(0.05, 5, 0.34, 8)
shadow.BackgroundColor3 = Color3.new(0, 0, 0)
shadow.BackgroundTransparency = 0.52
shadow.BorderSizePixel = 0
shadow.ZIndex = 0
shadow.Parent = screenGui
addCorner(shadow, 18)

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Window"
mainFrame.Size = UDim2.new(0, WINDOW_W, 0, WINDOW_H)
mainFrame.Position = UDim2.new(0.05, 0, 0.34, 0)
mainFrame.BackgroundColor3 = THEME.Background
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.ClipsDescendants = true
mainFrame.ZIndex = 1
mainFrame.Parent = screenGui
addCorner(mainFrame, 16)
addStroke(mainFrame, THEME.Stroke, 1, 0.08)

local uiScale = Instance.new("UIScale")
uiScale.Scale = 1
uiScale.Parent = mainFrame

-- =========================================================
-- TITLE BAR
-- =========================================================
local header = Instance.new("Frame")
header.Name = "TitleBar"
header.Size = UDim2.new(1, 0, 0, TITLE_H)
header.BackgroundColor3 = THEME.Panel
header.BorderSizePixel = 0
header.ZIndex = 2
header.Parent = mainFrame
addCorner(header, 16)

local headerFill = Instance.new("Frame")
headerFill.Size = UDim2.new(1, 0, 0, 15)
headerFill.Position = UDim2.new(0, 0, 1, -15)
headerFill.BackgroundColor3 = THEME.Panel
headerFill.BorderSizePixel = 0
headerFill.ZIndex = 2
headerFill.Parent = header

local accentBar = Instance.new("Frame")
accentBar.Size = UDim2.new(0, 4, 0, 28)
accentBar.Position = UDim2.new(0, 11, 0, 13)
accentBar.BackgroundColor3 = THEME.Accent
accentBar.BorderSizePixel = 0
accentBar.ZIndex = 3
accentBar.Parent = header
addCorner(accentBar, 4)

local icon = Instance.new("TextLabel")
icon.Size = UDim2.new(0, 28, 0, 28)
icon.Position = UDim2.new(0, 20, 0, 13)
icon.BackgroundTransparency = 1
icon.Text = "⚡"
icon.TextColor3 = THEME.Text
icon.Font = Enum.Font.GothamBold
icon.TextSize = 17
icon.ZIndex = 3
icon.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -175, 0, 18)
titleLabel.Position = UDim2.new(0, 51, 0, 7)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "ADMIN TEST"
titleLabel.TextColor3 = THEME.Text
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 3
titleLabel.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -175, 0, 15)
subtitle.Position = UDim2.new(0, 51, 0, 27)
subtitle.BackgroundTransparency = 1
subtitle.Text = "TESTING WINDOW  •  v2"
subtitle.TextColor3 = THEME.Muted
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextSize = 9
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 3
subtitle.Parent = header

local minimizeButton = makeButton(header, "Minimize", "—", UDim2.new(0, 29, 0, 29), UDim2.new(1, -109, 0, 12))
local maximizeButton = makeButton(header, "Maximize", "□", UDim2.new(0, 29, 0, 29), UDim2.new(1, -75, 0, 12))
local closeButton = makeButton(header, "Close", "×", UDim2.new(0, 29, 0, 29), UDim2.new(1, -41, 0, 12))
closeButton.BackgroundColor3 = Color3.fromRGB(56, 31, 39)
closeButton.TextColor3 = THEME.Danger

for _, button in ipairs({minimizeButton, maximizeButton, closeButton}) do
	button.ZIndex = 4
end

local divider = Instance.new("Frame")
divider.Name = "Divider"
divider.Size = UDim2.new(1, 0, 0, 1)
divider.Position = UDim2.new(0, 0, 0, TITLE_H)
divider.BackgroundColor3 = THEME.Stroke
divider.BackgroundTransparency = 0.3
divider.BorderSizePixel = 0
divider.ZIndex = 2
divider.Parent = mainFrame

-- =========================================================
-- SIDEBAR / TABS
-- =========================================================
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -TITLE_H)
sidebar.Position = UDim2.new(0, 0, 0, TITLE_H)
sidebar.BackgroundColor3 = THEME.Panel
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 2
sidebar.Parent = mainFrame

local sideTitle = Instance.new("TextLabel")
sideTitle.Size = UDim2.new(1, -16, 0, 20)
sideTitle.Position = UDim2.new(0, 8, 0, 15)
sideTitle.BackgroundTransparency = 1
sideTitle.Text = "MENU"
sideTitle.TextColor3 = THEME.Muted
sideTitle.Font = Enum.Font.GothamBold
sideTitle.TextSize = 9
sideTitle.TextXAlignment = Enum.TextXAlignment.Center
sideTitle.Parent = sidebar

local statusTab = makeButton(sidebar, "StatusTab", "◉\nSTATUS", UDim2.new(1, -14, 0, 52), UDim2.new(0, 7, 0, 42))
local testTab = makeButton(sidebar, "TestTab", "◆\nTEST", UDim2.new(1, -14, 0, 52), UDim2.new(0, 7, 0, 100))
statusTab.TextSize = 10
testTab.TextSize = 10

local sideFooter = Instance.new("TextLabel")
sideFooter.Size = UDim2.new(1, -12, 0, 30)
sideFooter.Position = UDim2.new(0, 6, 1, -42)
sideFooter.BackgroundTransparency = 1
sideFooter.Text = "TEST\nBUILD"
sideFooter.TextColor3 = THEME.Muted
sideFooter.Font = Enum.Font.GothamMedium
sideFooter.TextSize = 7
sideFooter.TextXAlignment = Enum.TextXAlignment.Center
sideFooter.Parent = sidebar

-- =========================================================
-- CONTENT AREA
-- =========================================================
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -SIDEBAR_W, 1, -TITLE_H)
content.Position = UDim2.new(0, SIDEBAR_W, 0, TITLE_H)
content.BackgroundColor3 = THEME.Background
content.BorderSizePixel = 0
content.ClipsDescendants = true
content.ZIndex = 2
content.Parent = mainFrame

local contentTitle = Instance.new("TextLabel")
contentTitle.Size = UDim2.new(1, -28, 0, 24)
contentTitle.Position = UDim2.new(0, 14, 0, 12)
contentTitle.BackgroundTransparency = 1
contentTitle.Text = "STATUS"
contentTitle.TextColor3 = THEME.Text
contentTitle.Font = Enum.Font.GothamBold
contentTitle.TextSize = 16
contentTitle.TextXAlignment = Enum.TextXAlignment.Left
contentTitle.Parent = content

local contentSubtitle = Instance.new("TextLabel")
contentSubtitle.Size = UDim2.new(1, -28, 0, 18)
contentSubtitle.Position = UDim2.new(0, 14, 0, 35)
contentSubtitle.BackgroundTransparency = 1
contentSubtitle.Text = "Player and test information"
contentSubtitle.TextColor3 = THEME.Muted
contentSubtitle.Font = Enum.Font.GothamMedium
contentSubtitle.TextSize = 9
contentSubtitle.TextXAlignment = Enum.TextXAlignment.Left
contentSubtitle.Parent = content

local statusPage = Instance.new("Frame")
statusPage.Name = "StatusPage"
statusPage.Size = UDim2.new(1, -28, 1, -73)
statusPage.Position = UDim2.new(0, 14, 0, 67)
statusPage.BackgroundTransparency = 1
statusPage.Parent = content

local testPage = Instance.new("Frame")
testPage.Name = "TestPage"
testPage.Size = statusPage.Size
testPage.Position = statusPage.Position
testPage.BackgroundTransparency = 1
testPage.Visible = false
testPage.Parent = content

-- Status cards
local function createInfoCard(parent, y, title, value, accent)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 54)
	card.Position = UDim2.new(0, 0, 0, y)
	card.BackgroundColor3 = THEME.Panel
	card.BorderSizePixel = 0
	card.Parent = parent
	addCorner(card, 10)
	addStroke(card, THEME.Stroke, 1, 0.24)

	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 7, 0, 7)
	dot.Position = UDim2.new(0, 13, 0, 14)
	dot.BackgroundColor3 = accent
	dot.BorderSizePixel = 0
	dot.Parent = card
	addCorner(dot, 50)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.42, 0, 0, 16)
	label.Position = UDim2.new(0, 28, 0, 7)
	label.BackgroundTransparency = 1
	label.Text = title
	label.TextColor3 = THEME.Muted
	label.Font = Enum.Font.GothamBold
	label.TextSize = 8
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = card

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0.9, 0, 0, 18)
	valueLabel.Position = UDim2.new(0, 28, 0, 24)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = value
	valueLabel.TextColor3 = THEME.Text
	valueLabel.Font = Enum.Font.GothamMedium
	valueLabel.TextSize = 10
	valueLabel.TextXAlignment = Enum.TextXAlignment.Left
	valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
	valueLabel.Parent = card

	return valueLabel
end

local playerValue = createInfoCard(statusPage, 0, "PLAYER", LocalPlayer.DisplayName, THEME.Accent)
local healthValue = createInfoCard(statusPage, 62, "HEALTH", "—", THEME.Success)
local targetStatusValue = createInfoCard(statusPage, 124, "LOCK", "OFF • No target", THEME.Danger)
local positionValue = createInfoCard(statusPage, 186, "POSITION", "—", THEME.Warning)

local statusHint = Instance.new("TextLabel")
statusHint.Size = UDim2.new(1, 0, 0, 18)
statusHint.Position = UDim2.new(0, 0, 1, -20)
statusHint.BackgroundTransparency = 1
statusHint.Text = "Status updates live while the panel is open."
statusHint.TextColor3 = THEME.Muted
statusHint.Font = Enum.Font.GothamMedium
statusHint.TextSize = 8
statusHint.TextXAlignment = Enum.TextXAlignment.Left
statusHint.Parent = statusPage

-- Test page: ONLY Lock
local lockTitle = Instance.new("TextLabel")
lockTitle.Size = UDim2.new(1, 0, 0, 22)
lockTitle.Position = UDim2.new(0, 0, 0, 0)
lockTitle.BackgroundTransparency = 1
lockTitle.Text = "LOCK"
lockTitle.TextColor3 = THEME.Text
lockTitle.Font = Enum.Font.GothamBold
lockTitle.TextSize = 12
lockTitle.TextXAlignment = Enum.TextXAlignment.Left
lockTitle.Parent = testPage

local lockDescription = Instance.new("TextLabel")
lockDescription.Size = UDim2.new(1, 0, 0, 30)
lockDescription.Position = UDim2.new(0, 0, 0, 22)
lockDescription.BackgroundTransparency = 1
lockDescription.Text = "Acquire the best visible target and lock the test camera onto it."
lockDescription.TextColor3 = THEME.Muted
lockDescription.Font = Enum.Font.GothamMedium
lockDescription.TextSize = 9
lockDescription.TextWrapped = true
lockDescription.TextXAlignment = Enum.TextXAlignment.Left
lockDescription.Parent = testPage

local statusCard = Instance.new("Frame")
statusCard.Name = "LockStatusCard"
statusCard.Size = UDim2.new(1, 0, 0, 62)
statusCard.Position = UDim2.new(0, 0, 0, 58)
statusCard.BackgroundColor3 = THEME.Panel
statusCard.BorderSizePixel = 0
statusCard.Parent = testPage
addCorner(statusCard, 11)
addStroke(statusCard, THEME.Stroke, 1, 0.24)

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 9, 0, 9)
statusDot.Position = UDim2.new(0, 13, 0, 15)
statusDot.BackgroundColor3 = THEME.Danger
statusDot.BorderSizePixel = 0
statusDot.Parent = statusCard
addCorner(statusDot, 50)

local statusTitle = Instance.new("TextLabel")
statusTitle.Size = UDim2.new(0.38, 0, 0, 17)
statusTitle.Position = UDim2.new(0, 31, 0, 7)
statusTitle.BackgroundTransparency = 1
statusTitle.Text = "LOCK STATUS"
statusTitle.TextColor3 = THEME.Text
statusTitle.Font = Enum.Font.GothamBold
statusTitle.TextSize = 9
statusTitle.TextXAlignment = Enum.TextXAlignment.Left
statusTitle.Parent = statusCard

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0.58, 0, 0, 18)
statusLabel.Position = UDim2.new(0, 31, 0, 27)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "INACTIVE • No target"
statusLabel.TextColor3 = THEME.Muted
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextSize = 9
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = statusCard

local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(0.32, 0, 0, 18)
targetLabel.Position = UDim2.new(0.65, 0, 0, 23)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "—"
targetLabel.TextColor3 = THEME.Muted
targetLabel.Font = Enum.Font.GothamBold
targetLabel.TextSize = 9
targetLabel.TextXAlignment = Enum.TextXAlignment.Right
targetLabel.TextTruncate = Enum.TextTruncate.AtEnd
targetLabel.Parent = statusCard

local lockButton = Instance.new("TextButton")
lockButton.Name = "LockButton"
lockButton.Size = UDim2.new(1, 0, 0, 44)
lockButton.Position = UDim2.new(0, 0, 0, 128)
lockButton.BackgroundColor3 = THEME.PanelLight
lockButton.BorderSizePixel = 0
lockButton.Text = "LOCK  •  OFF"
lockButton.TextColor3 = THEME.Text
lockButton.Font = Enum.Font.GothamBold
lockButton.TextSize = 11
lockButton.AutoButtonColor = false
lockButton.Parent = testPage
addCorner(lockButton, 10)
local lockStroke = addStroke(lockButton, THEME.Stroke, 1, 0.18)

local testHint = Instance.new("TextLabel")
testHint.Size = UDim2.new(1, 0, 0, 24)
testHint.Position = UDim2.new(0, 0, 0, 181)
testHint.BackgroundTransparency = 1
testHint.Text = "Test tab intentionally contains only Lock."
testHint.TextColor3 = THEME.Muted
testHint.Font = Enum.Font.GothamMedium
testHint.TextSize = 8
testHint.TextXAlignment = Enum.TextXAlignment.Left
testHint.Parent = testPage

-- =========================================================
-- REOPEN BUTTON
-- =========================================================
local reopenButton = Instance.new("TextButton")
reopenButton.Name = "Reopen"
reopenButton.Size = UDim2.new(0, 48, 0, 48)
reopenButton.Position = UDim2.new(0, 20, 0.84, 0)
reopenButton.BackgroundColor3 = THEME.Panel
reopenButton.BorderSizePixel = 0
reopenButton.Text = "⚡"
reopenButton.TextColor3 = THEME.Text
reopenButton.Font = Enum.Font.GothamBold
reopenButton.TextSize = 18
reopenButton.AutoButtonColor = false
reopenButton.Visible = false
reopenButton.Parent = screenGui
reopenButton.ZIndex = 10
addCorner(reopenButton, 13)
addStroke(reopenButton, THEME.Accent, 1, 0.05)

local reopenScale = Instance.new("UIScale")
reopenScale.Scale = 0.7
reopenScale.Parent = reopenButton

-- =========================================================
-- TAB HELPERS
-- =========================================================
local function setTabVisual(button, active)
	if active then
		button.BackgroundColor3 = THEME.AccentDark
		button.TextColor3 = THEME.Text
	else
		button.BackgroundColor3 = THEME.PanelLight
		button.TextColor3 = THEME.Muted
	end
end

local function switchTab(tabName)
	currentTab = tabName
	local isStatus = tabName == "Status"
	statusPage.Visible = isStatus
	testPage.Visible = not isStatus
	contentTitle.Text = isStatus and "STATUS" or "TEST"
	contentSubtitle.Text = isStatus and "Player and test information" or "Experimental features"
	setTabVisual(statusTab, isStatus)
	setTabVisual(testTab, not isStatus)
end

setTabVisual(statusTab, true)
setTabVisual(testTab, false)

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
		statusLabel.Text = message or "ACTIVE • Target acquired"
		statusLabel.TextColor3 = THEME.Success
		lockButton.Text = "LOCK  •  ON"
		lockButton.BackgroundColor3 = THEME.AccentDark
		lockStroke.Color = THEME.Accent
		targetLabel.Text = getTargetName(lockedTarget)
	elseif mode == "WARNING" then
		statusDot.BackgroundColor3 = THEME.Warning
		statusLabel.Text = message or "ACTIVE • No target"
		statusLabel.TextColor3 = THEME.Warning
		lockButton.Text = "LOCK  •  NO TARGET"
		lockButton.BackgroundColor3 = Color3.fromRGB(91, 67, 34)
		lockStroke.Color = THEME.Warning
		targetLabel.Text = "—"
	else
		statusDot.BackgroundColor3 = THEME.Danger
		statusLabel.Text = message or "INACTIVE • No target"
		statusLabel.TextColor3 = THEME.Muted
		lockButton.Text = "LOCK  •  OFF"
		lockButton.BackgroundColor3 = THEME.PanelLight
		lockStroke.Color = THEME.Stroke
		targetLabel.Text = "—"
	end
end

-- =========================================================
-- STATUS UPDATE
-- =========================================================
local function updateStatusPage()
	playerValue.Text = LocalPlayer.DisplayName .. "  (" .. LocalPlayer.Name .. ")"

	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	if hum then
		healthValue.Text = string.format("%d / %d", math.floor(hum.Health), math.floor(hum.MaxHealth))
	else
		healthValue.Text = "—"
	end

	if lockEnabled then
		if lockedTarget then
			targetStatusValue.Text = "ON • " .. getTargetName(lockedTarget)
		else
			targetStatusValue.Text = "ON • No target"
		end
	else
		targetStatusValue.Text = "OFF • No target"
	end

	if hrp then
		local p = hrp.Position
		positionValue.Text = string.format("X %.0f   Y %.0f   Z %.0f", p.X, p.Y, p.Z)
	else
		positionValue.Text = "—"
	end
end

-- =========================================================
-- CAMERA LOCK LOOP
-- =========================================================
RunService.RenderStepped:Connect(function()
	updateStatusPage()

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
-- BUTTON FEEDBACK
-- =========================================================
local function setupHover(button, normalColor, hoverColor, pressedColor)
	button.MouseEnter:Connect(function()
		tween(button, {BackgroundColor3 = hoverColor, TextColor3 = THEME.Text}, 0.1)
	end)
	button.MouseLeave:Connect(function()
		if button == closeButton then
			tween(button, {BackgroundColor3 = Color3.fromRGB(56, 31, 39)}, 0.1)
		elseif button == minimizeButton or button == maximizeButton then
			tween(button, {BackgroundColor3 = THEME.PanelLight}, 0.1)
		end
	end)
	button.MouseButton1Down:Connect(function()
		tween(button, {BackgroundColor3 = pressedColor or hoverColor}, 0.06)
	end)
	button.MouseButton1Up:Connect(function()
		tween(button, {BackgroundColor3 = hoverColor}, 0.06)
	end)
end

setupHover(minimizeButton, THEME.PanelLight, THEME.PanelHover, Color3.fromRGB(50, 54, 70))
setupHover(maximizeButton, THEME.PanelLight, THEME.PanelHover, Color3.fromRGB(50, 54, 70))
setupHover(closeButton, Color3.fromRGB(56, 31, 39), Color3.fromRGB(77, 37, 48), Color3.fromRGB(92, 43, 57))
setupHover(reopenButton, THEME.Panel, THEME.PanelHover, Color3.fromRGB(43, 47, 62))

statusTab.MouseEnter:Connect(function()
	if currentTab ~= "Status" then tween(statusTab, {BackgroundColor3 = THEME.PanelHover}, 0.1) end
end)
statusTab.MouseLeave:Connect(function()
	setTabVisual(statusTab, currentTab == "Status")
end)
testTab.MouseEnter:Connect(function()
	if currentTab ~= "Test" then tween(testTab, {BackgroundColor3 = THEME.PanelHover}, 0.1) end
end)
testTab.MouseLeave:Connect(function()
	setTabVisual(testTab, currentTab == "Test")
end)

statusTab.MouseButton1Click:Connect(function() switchTab("Status") end)
testTab.MouseButton1Click:Connect(function() switchTab("Test") end)

-- =========================================================
-- LOCK BUTTON
-- =========================================================
lockButton.MouseEnter:Connect(function()
	if lockEnabled then
		tween(lockButton, {BackgroundColor3 = THEME.Accent}, 0.1)
	else
		tween(lockButton, {BackgroundColor3 = THEME.PanelHover}, 0.1)
	end
end)
lockButton.MouseLeave:Connect(function()
	if lockEnabled then
		tween(lockButton, {BackgroundColor3 = THEME.AccentDark}, 0.1)
	else
		tween(lockButton, {BackgroundColor3 = THEME.PanelLight}, 0.1)
	end
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
-- DRAGGING: TITLE BAR ONLY
-- =========================================================
local function inputIsPrimary(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

header.InputBegan:Connect(function(input)
	if not inputIsPrimary(input) then
		return
	end

	local pos = input.Position
	local x = pos.X
	local headerAbsolute = header.AbsolutePosition
	local headerSize = header.AbsoluteSize

	-- Do not begin dragging when touching/clicking the top-right controls.
	if x >= headerAbsolute.X + headerSize.X - 120 then
		return
	end

	dragging = true
	dragStart = input.Position
	dragStartPos = mainFrame.Position
end)

-- =========================================================
-- RESIZE HANDLES
-- Edges resize one axis; corner resizes both axes.
-- =========================================================
local resizeThickness = 7
local resizeHandles = {}

local function createResizeHandle(name, position, size, mode, cursor)
	local handle = Instance.new("Frame")
	handle.Name = name
	handle.Position = position
	handle.Size = size
	handle.BackgroundTransparency = 1
	handle.BorderSizePixel = 0
	handle.Active = true
	handle.ZIndex = 8
	handle.Parent = mainFrame

	local function beginResize(input)
		if not inputIsPrimary(input) or minimized or closed then
			return
		end
		resizing = true
		resizeMode = mode
		resizeStart = input.Position
		resizeStartSize = Vector2.new(mainFrame.AbsoluteSize.X, mainFrame.AbsoluteSize.Y)
		resizeStartPos = mainFrame.Position
	end

	handle.InputBegan:Connect(beginResize)
	table.insert(resizeHandles, {frame = handle, mode = mode, cursor = cursor})
	return handle
end

createResizeHandle("ResizeTop", UDim2.new(0, 8, 0, 0), UDim2.new(1, -16, 0, resizeThickness), "Top")
createResizeHandle("ResizeBottom", UDim2.new(0, 8, 1, -resizeThickness), UDim2.new(1, -16, 0, resizeThickness), "Bottom")
createResizeHandle("ResizeLeft", UDim2.new(0, 0, 0, 8), UDim2.new(0, resizeThickness, 1, -16), "Left")
createResizeHandle("ResizeRight", UDim2.new(1, -resizeThickness, 0, 8), UDim2.new(0, resizeThickness, 1, -16), "Right")
createResizeHandle("ResizeTopLeft", UDim2.new(0, 0, 0, 0), UDim2.new(0, resizeThickness + 2, 0, resizeThickness + 2), "TopLeft")
createResizeHandle("ResizeTopRight", UDim2.new(1, -resizeThickness - 2, 0, 0), UDim2.new(0, resizeThickness + 2, 0, resizeThickness + 2), "TopRight")
createResizeHandle("ResizeBottomLeft", UDim2.new(0, 0, 1, -resizeThickness - 2), UDim2.new(0, resizeThickness + 2, 0, resizeThickness + 2), "BottomLeft")
createResizeHandle("ResizeBottomRight", UDim2.new(1, -resizeThickness - 2, 1, -resizeThickness - 2), UDim2.new(0, resizeThickness + 2, 0, resizeThickness + 2), "BottomRight")

local function setWindowSize(width, height, xOffset, yOffset)
	width = math.max(MIN_W, math.floor(width))
	height = math.max(minimized and TITLE_H or MIN_H, math.floor(height))

	mainFrame.Size = UDim2.new(0, width, 0, height)
	shadow.Size = UDim2.new(0, width + 10, 0, height + 10)

	if xOffset then
		mainFrame.Position = UDim2.new(
			dragStartPos.X.Scale,
			xOffset,
			dragStartPos.Y.Scale,
			yOffset
		)
	end
end

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(
			dragStartPos.X.Scale,
			dragStartPos.X.Offset + delta.X,
			dragStartPos.Y.Scale,
			dragStartPos.Y.Offset + delta.Y
		)
		shadow.Position = UDim2.new(
			mainFrame.Position.X.Scale,
			mainFrame.Position.X.Offset + 5,
			mainFrame.Position.Y.Scale,
			mainFrame.Position.Y.Offset + 7
		)
	elseif resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - resizeStart
		local newW = resizeStartSize.X
		local newH = resizeStartSize.Y
		local posX = resizeStartPos.X.Offset
		local posY = resizeStartPos.Y.Offset

		if string.find(resizeMode, "Right") or resizeMode == "Right" or resizeMode == "TopRight" or resizeMode == "BottomRight" then
			newW = resizeStartSize.X + delta.X
		elseif string.find(resizeMode, "Left") then
			newW = resizeStartSize.X - delta.X
			if newW < MIN_W then
				delta = Vector2.new(resizeStartSize.X - MIN_W, delta.Y)
				newW = MIN_W
			end
			posX = resizeStartPos.X.Offset + delta.X
		end

		if string.find(resizeMode, "Bottom") or resizeMode == "Bottom" or resizeMode == "BottomLeft" or resizeMode == "BottomRight" then
			newH = resizeStartSize.Y + delta.Y
		elseif string.find(resizeMode, "Top") then
			newH = resizeStartSize.Y - delta.Y
			if newH < (minimized and TITLE_H or MIN_H) then
				delta = Vector2.new(delta.X, resizeStartSize.Y - (minimized and TITLE_H or MIN_H))
				newH = minimized and TITLE_H or MIN_H
			end
			posY = resizeStartPos.Y.Offset + delta.Y
		end

		if resizeMode == "TopLeft" or resizeMode == "TopRight" then
			-- handled by Top and corresponding X side above
		end

		newW = math.max(MIN_W, newW)
		newH = math.max(minimized and TITLE_H or MIN_H, newH)
		mainFrame.Size = UDim2.new(0, math.floor(newW), 0, math.floor(newH))
		mainFrame.Position = UDim2.new(resizeStartPos.X.Scale, math.floor(posX), resizeStartPos.Y.Scale, math.floor(posY))
		shadow.Size = UDim2.new(0, math.floor(newW) + 10, 0, math.floor(newH) + 10)
		shadow.Position = UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset + 5, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset + 7)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if inputIsPrimary(input) then
		dragging = false
		if resizing then
			resizing = false
			resizeMode = nil
			savedSize = Vector2.new(mainFrame.AbsoluteSize.X, mainFrame.AbsoluteSize.Y)
		end
	end
end)

-- =========================================================
-- MINIMIZE / MAXIMIZE / CLOSE ANIMATIONS
-- =========================================================
local fullSize = UDim2.new(0, WINDOW_W, 0, WINDOW_H)
local miniSize = UDim2.new(0, WINDOW_W, 0, TITLE_H)

local function syncShadow()
	shadow.Position = UDim2.new(
		mainFrame.Position.X.Scale,
		mainFrame.Position.X.Offset + 5,
		mainFrame.Position.Y.Scale,
		mainFrame.Position.Y.Offset + 7
	)
end

local function setBodyVisible(visible)
	sidebar.Visible = visible
	content.Visible = visible
	divider.Visible = visible
end

minimizeButton.MouseButton1Click:Connect(function()
	if closed then return end

	minimized = not minimized
	if minimized then
		savedSize = Vector2.new(mainFrame.AbsoluteSize.X, mainFrame.AbsoluteSize.Y)
		minimizeButton.Text = "+"
		setBodyVisible(false)
		tween(mainFrame, {Size = UDim2.new(0, savedSize.X, 0, TITLE_H)}, 0.24)
		tween(shadow, {Size = UDim2.new(0, savedSize.X + 10, 0, TITLE_H + 10)}, 0.24)
	else
		minimizeButton.Text = "—"
		setBodyVisible(true)
		tween(mainFrame, {Size = UDim2.new(0, savedSize.X, 0, savedSize.Y)}, 0.28)
		tween(shadow, {Size = UDim2.new(0, savedSize.X + 10, 0, savedSize.Y + 10)}, 0.28)
	end
end)

maximizeButton.MouseButton1Click:Connect(function()
	if closed then return end
	if minimized then
		minimized = false
		minimizeButton.Text = "—"
		setBodyVisible(true)
	end

	local cameraSize = Camera.ViewportSize
	local targetW = math.floor(math.clamp(cameraSize.X * 0.65, MIN_W, 620))
	local targetH = math.floor(math.clamp(cameraSize.Y * 0.65, MIN_H, 460))

	if math.abs(mainFrame.AbsoluteSize.X - targetW) < 15 and math.abs(mainFrame.AbsoluteSize.Y - targetH) < 15 then
		targetW = savedSize.X
		targetH = savedSize.Y
	else
		savedSize = Vector2.new(mainFrame.AbsoluteSize.X, mainFrame.AbsoluteSize.Y)
	end

	tween(mainFrame, {Size = UDim2.new(0, targetW, 0, targetH)}, 0.3)
	tween(shadow, {Size = UDim2.new(0, targetW + 10, 0, targetH + 10)}, 0.3)
end)

local function openWindowAnimated()
	closed = false
	mainFrame.Visible = true
	shadow.Visible = true
	reopenButton.Visible = false
	uiScale.Scale = 0.82
	shadow.BackgroundTransparency = 0.78
	tween(uiScale, {Scale = 1}, 0.28, Enum.EasingStyle.Back)
	tween(shadow, {BackgroundTransparency = 0.52}, 0.28)
end

local function closeWindowAnimated()
	closed = true
	tween(uiScale, {Scale = 0.82}, 0.2)
	tween(shadow, {BackgroundTransparency = 1}, 0.18)
	task.delay(0.19, function()
		if closed then
			mainFrame.Visible = false
			shadow.Visible = false
			reopenButton.Visible = true
			reopenScale.Scale = 0.65
			tween(reopenScale, {Scale = 1}, 0.24, Enum.EasingStyle.Back)
		end
	end)
end

closeButton.MouseButton1Click:Connect(function()
	minimized = false
	minimizeButton.Text = "—"
	setBodyVisible(true)
	mainFrame.Size = UDim2.new(0, savedSize.X, 0, savedSize.Y)
	shadow.Size = UDim2.new(0, savedSize.X + 10, 0, savedSize.Y + 10)
	closeWindowAnimated()
end)

reopenButton.MouseButton1Click:Connect(function()
	openWindowAnimated()
end)

-- =========================================================
-- INITIAL STATE
-- =========================================================
setLockVisual("OFF")
syncShadow()
savedSize = Vector2.new(WINDOW_W, WINDOW_H)
switchTab("Status")

-- =========================================================
-- OPTIONAL HINT: reset stored size if viewport changes heavily
-- =========================================================
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	if mainFrame.Visible and not closed then
		local view = Camera.ViewportSize
		if mainFrame.AbsolutePosition.X + mainFrame.AbsoluteSize.X > view.X + 40 then
			mainFrame.Position = UDim2.new(0, math.max(10, view.X - mainFrame.AbsoluteSize.X - 10), mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset)
		end
		if mainFrame.AbsolutePosition.Y + mainFrame.AbsoluteSize.Y > view.Y + 40 then
			mainFrame.Position = UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, 0, math.max(10, view.Y - mainFrame.AbsoluteSize.Y - 10))
		end
		syncShadow()
	end
end)

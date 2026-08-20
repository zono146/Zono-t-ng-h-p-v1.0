--[[
==============================================================
 HEART BATTLEGROUND
 Windows-Style UI + Auto Aim
==============================================================
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==============================================================
-- STATE
--==============================================================

local aimEnabled = false
local lockedTarget = nil

local windowMinimized = false
local windowMaximized = false

local normalSize = UDim2.fromOffset(520, 350)
local normalPosition = UDim2.new(0.5, -260, 0.5, -175)

local maximizedSize = UDim2.new(0.9, 0, 0.85, 0)
local maximizedPosition = UDim2.new(0.05, 0, 0.075, 0)

--==============================================================
-- CLEAN UP OLD GUI
--==============================================================

local oldGui =
	LocalPlayer:WaitForChild("PlayerGui")
		:FindFirstChild("HeartBattlegroundAimGui")

if oldGui then
	oldGui:Destroy()
end

--==============================================================
-- GUI ROOT
--==============================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HeartBattlegroundAimGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent =
	LocalPlayer:WaitForChild("PlayerGui")

--==============================================================
-- WINDOW SHADOW
--==============================================================

local shadow = Instance.new("Frame")
shadow.Name = "WindowShadow"
shadow.Size = normalSize
shadow.Position = UDim2.new(
	0.5, -254,
	0.5, -169
)
shadow.BackgroundColor3 =
	Color3.fromRGB(0, 0, 0)
shadow.BackgroundTransparency = 0.55
shadow.BorderSizePixel = 0
shadow.ZIndex = 1
shadow.Parent = screenGui

local shadowCorner = Instance.new("UICorner")
shadowCorner.CornerRadius =
	UDim.new(0, 12)
shadowCorner.Parent = shadow

--==============================================================
-- MAIN WINDOW
--==============================================================

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainWindow"
mainFrame.Size = normalSize
mainFrame.Position = normalPosition
mainFrame.BackgroundColor3 =
	Color3.fromRGB(28, 29, 34)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.ZIndex = 2
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius =
	UDim.new(0, 12)
mainCorner.Parent = mainFrame

local windowStroke = Instance.new("UIStroke")
windowStroke.Color =
	Color3.fromRGB(70, 72, 82)
windowStroke.Thickness = 1
windowStroke.Transparency = 0.25
windowStroke.Parent = mainFrame

--==============================================================
-- TITLE BAR
--==============================================================

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size =
	UDim2.new(1, 0, 0, 46)
titleBar.BackgroundColor3 =
	Color3.fromRGB(36, 38, 45)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 3
titleBar.Parent = mainFrame

local titleText = Instance.new("TextLabel")
titleText.Name = "Title"
titleText.Size =
	UDim2.new(1, -180, 1, 0)
titleText.Position =
	UDim2.fromOffset(18, 0)
titleText.BackgroundTransparency = 1
titleText.Text =
	"♥  HEART BATTLEGROUND"
titleText.TextColor3 =
	Color3.fromRGB(240, 240, 245)
titleText.Font =
	Enum.Font.GothamBold
titleText.TextSize = 14
titleText.TextXAlignment =
	Enum.TextXAlignment.Left
titleText.ZIndex = 4
titleText.Parent = titleBar

local subtitle = Instance.new("TextLabel")
subtitle.Size =
	UDim2.new(1, -180, 0, 14)
subtitle.Position =
	UDim2.fromOffset(40, 27)
subtitle.BackgroundTransparency = 1
subtitle.Text =
	"Combat Control Panel"
subtitle.TextColor3 =
	Color3.fromRGB(135, 138, 150)
subtitle.Font =
	Enum.Font.Gotham
subtitle.TextSize = 9
subtitle.TextXAlignment =
	Enum.TextXAlignment.Left
subtitle.ZIndex = 4
subtitle.Parent = titleBar

--==============================================================
-- WINDOW CONTROL BUTTON FACTORY
--==============================================================

local function CreateWindowButton(
	text,
	xOffset,
	hoverColor
)

	local button = Instance.new("TextButton")

	button.Size =
		UDim2.fromOffset(42, 46)

	button.Position =
		UDim2.new(
			1,
			xOffset,
			0,
			0
		)

	button.BackgroundTransparency = 1

	button.Text = text

	button.TextColor3 =
		Color3.fromRGB(
			220,
			220,
			225
		)

	button.Font =
		Enum.Font.Gotham

	button.TextSize = 15

	button.AutoButtonColor = false

	button.ZIndex = 5

	button.Parent = titleBar

	button.MouseEnter:Connect(
		function()

			TweenService:Create(
				button,
				TweenInfo.new(
					0.12,
					Enum.EasingStyle.Quad
				),
				{
					BackgroundColor3 =
						hoverColor,
					BackgroundTransparency = 0
				}
			):Play()

		end
	)

	button.MouseLeave:Connect(
		function()

			TweenService:Create(
				button,
				TweenInfo.new(
					0.12,
					Enum.EasingStyle.Quad
				),
				{
					BackgroundTransparency = 1
				}
			):Play()

		end
	)

	return button
end

local closeButton =
	CreateWindowButton(
		"×",
		UDim2.new(0, -42, 0, 0),
		Color3.fromRGB(190, 55, 55)
	)

local maximizeButton =
	CreateWindowButton(
		"□",
		UDim2.new(0, -84, 0, 0),
		Color3.fromRGB(70, 72, 82)
	)

local minimizeButton =
	CreateWindowButton(
		"—",
		UDim2.new(0, -126, 0, 0),
		Color3.fromRGB(70, 72, 82)
	)

--==============================================================
-- SIDEBAR
--==============================================================

local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size =
	UDim2.new(0, 150, 1, -46)
sidebar.Position =
	UDim2.fromOffset(0, 46)
sidebar.BackgroundColor3 =
	Color3.fromRGB(24, 25, 30)
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 3
sidebar.Parent = mainFrame

local sidebarTitle = Instance.new("TextLabel")
sidebarTitle.Size =
	UDim2.new(1, -24, 0, 30)
sidebarTitle.Position =
	UDim2.fromOffset(12, 15)
sidebarTitle.BackgroundTransparency = 1
sidebarTitle.Text =
	"FEATURES"
sidebarTitle.TextColor3 =
	Color3.fromRGB(115, 118, 130)
sidebarTitle.Font =
	Enum.Font.GothamBold
sidebarTitle.TextSize = 10
sidebarTitle.TextXAlignment =
	Enum.TextXAlignment.Left
sidebarTitle.ZIndex = 4
sidebarTitle.Parent = sidebar

--==============================================================
-- SIDEBAR BUTTON
--==============================================================

local commonButton = Instance.new("TextButton")
commonButton.Size =
	UDim2.new(1, -20, 0, 42)
commonButton.Position =
	UDim2.fromOffset(10, 52)
commonButton.BackgroundColor3 =
	Color3.fromRGB(48, 50, 60)
commonButton.BorderSizePixel = 0
commonButton.Text =
	"   ◈   Common Features"
commonButton.TextColor3 =
	Color3.fromRGB(240, 240, 245)
commonButton.Font =
	Enum.Font.GothamMedium
commonButton.TextSize = 11
commonButton.TextXAlignment =
	Enum.TextXAlignment.Left
commonButton.ZIndex = 4
commonButton.Parent = sidebar

local commonCorner = Instance.new("UICorner")
commonCorner.CornerRadius =
	UDim.new(0, 7)
commonCorner.Parent = commonButton

--==============================================================
-- STATUS AREA
--==============================================================

local statusLabel = Instance.new("TextLabel")
statusLabel.Size =
	UDim2.new(1, -20, 0, 40)
statusLabel.Position =
	UDim2.new(0, 10, 1, -55)
statusLabel.BackgroundTransparency = 1
statusLabel.Text =
	"●  READY"
statusLabel.TextColor3 =
	Color3.fromRGB(85, 200, 120)
statusLabel.Font =
	Enum.Font.GothamMedium
statusLabel.TextSize = 10
statusLabel.TextXAlignment =
	Enum.TextXAlignment.Left
statusLabel.ZIndex = 4
statusLabel.Parent = sidebar

--==============================================================
-- CONTENT AREA
--==============================================================

local content = Instance.new("Frame")
content.Name = "Content"
content.Size =
	UDim2.new(1, -150, 1, -46)
content.Position =
	UDim2.fromOffset(150, 46)
content.BackgroundColor3 =
	Color3.fromRGB(30, 31, 37)
content.BorderSizePixel = 0
content.ZIndex = 3
content.Parent = mainFrame

local contentTitle = Instance.new("TextLabel")
contentTitle.Size =
	UDim2.new(1, -40, 0, 36)
contentTitle.Position =
	UDim2.fromOffset(20, 18)
contentTitle.BackgroundTransparency = 1
contentTitle.Text =
	"Common Features"
contentTitle.TextColor3 =
	Color3.fromRGB(245, 245, 250)
contentTitle.Font =
	Enum.Font.GothamBold
contentTitle.TextSize = 19
contentTitle.TextXAlignment =
	Enum.TextXAlignment.Left
contentTitle.ZIndex = 4
contentTitle.Parent = content

local contentDescription = Instance.new("TextLabel")
contentDescription.Size =
	UDim2.new(1, -40, 0, 30)
contentDescription.Position =
	UDim2.fromOffset(20, 51)
contentDescription.BackgroundTransparency = 1
contentDescription.Text =
	"Configure your available combat features."
contentDescription.TextColor3 =
	Color3.fromRGB(135, 138, 150)
contentDescription.Font =
	Enum.Font.Gotham
contentDescription.TextSize = 10
contentDescription.TextXAlignment =
	Enum.TextXAlignment.Left
contentDescription.ZIndex = 4
contentDescription.Parent = content

--==============================================================
-- FEATURE CARD
--==============================================================

local aimCard = Instance.new("Frame")
aimCard.Size =
	UDim2.new(1, -40, 0, 105)
aimCard.Position =
	UDim2.fromOffset(20, 95)
aimCard.BackgroundColor3 =
	Color3.fromRGB(39, 41, 49)
aimCard.BorderSizePixel = 0
aimCard.ZIndex = 4
aimCard.Parent = content

local aimCardCorner = Instance.new("UICorner")
aimCardCorner.CornerRadius =
	UDim.new(0, 9)
aimCardCorner.Parent = aimCard

local aimCardStroke = Instance.new("UIStroke")
aimCardStroke.Color =
	Color3.fromRGB(62, 64, 74)
aimCardStroke.Thickness = 1
aimCardStroke.Transparency = 0.3
aimCardStroke.Parent = aimCard

local aimIcon = Instance.new("TextLabel")
aimIcon.Size =
	UDim2.fromOffset(42, 42)
aimIcon.Position =
	UDim2.fromOffset(15, 17)
aimIcon.BackgroundColor3 =
	Color3.fromRGB(55, 57, 68)
aimIcon.Text =
	"◎"
aimIcon.TextColor3 =
	Color3.fromRGB(255, 90, 90)
aimIcon.Font =
	Enum.Font.GothamBold
aimIcon.TextSize = 22
aimIcon.ZIndex = 5
aimIcon.Parent = aimCard

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius =
	UDim.new(0, 8)
iconCorner.Parent = aimIcon

local aimTitle = Instance.new("TextLabel")
aimTitle.Size =
	UDim2.new(1, -170, 0, 25)
aimTitle.Position =
	UDim2.fromOffset(70, 15)
aimTitle.BackgroundTransparency = 1
aimTitle.Text =
	"Auto Aim"
aimTitle.TextColor3 =
	Color3.fromRGB(240, 240, 245)
aimTitle.Font =
	Enum.Font.GothamBold
aimTitle.TextSize = 13
aimTitle.TextXAlignment =
	Enum.TextXAlignment.Left
aimTitle.ZIndex = 5
aimTitle.Parent = aimCard

local aimDescription = Instance.new("TextLabel")
aimDescription.Size =
	UDim2.new(1, -170, 0, 35)
aimDescription.Position =
	UDim2.fromOffset(70, 39)
aimDescription.BackgroundTransparency = 1
aimDescription.Text =
	"Lock the camera onto the nearest valid target."
aimDescription.TextColor3 =
	Color3.fromRGB(140, 143, 154)
aimDescription.Font =
	Enum.Font.Gotham
aimDescription.TextSize = 9
aimDescription.TextWrapped = true
aimDescription.TextXAlignment =
	Enum.TextXAlignment.Left
aimDescription.ZIndex = 5
aimDescription.Parent = aimCard

--==============================================================
-- AIM TOGGLE
--==============================================================

local aimButton = Instance.new("TextButton")
aimButton.Size =
	UDim2.fromOffset(105, 38)
aimButton.Position =
	UDim2.new(1, -120, 0.5, -19)
aimButton.BackgroundColor3 =
	Color3.fromRGB(150, 50, 50)
aimButton.BorderSizePixel = 0
aimButton.Text =
	"OFF"
aimButton.TextColor3 =
	Color3.fromRGB(255, 255, 255)
aimButton.Font =
	Enum.Font.GothamBold
aimButton.TextSize = 11
aimButton.AutoButtonColor = false
aimButton.ZIndex = 6
aimButton.Parent = aimCard

local aimButtonCorner = Instance.new("UICorner")
aimButtonCorner.CornerRadius =
	UDim.new(0, 7)
aimButtonCorner.Parent = aimButton

--==============================================================
-- FOOTER
--==============================================================

local footer = Instance.new("TextLabel")
footer.Size =
	UDim2.new(1, -40, 0, 22)
footer.Position =
	UDim2.new(0, 20, 1, -32)
footer.BackgroundTransparency = 1
footer.Text =
	"HEART BATTLEGROUND  •  CONTROL PANEL"
footer.TextColor3 =
	Color3.fromRGB(90, 93, 104)
footer.Font =
	Enum.Font.Gotham
footer.TextSize = 8
footer.TextXAlignment =
	Enum.TextXAlignment.Left
footer.ZIndex = 4
footer.Parent = content

--==============================================================
-- WINDOW DRAGGING
--==============================================================

local dragging = false
local dragStart = nil
local startPosition = nil

titleBar.InputBegan:Connect(
	function(input)

		if
			input.UserInputType
			== Enum.UserInputType.MouseButton1
		then

			dragging = true
			dragStart = input.Position
			startPosition = mainFrame.Position

		end

	end
)

titleBar.InputEnded:Connect(
	function(input)

		if
			input.UserInputType
			== Enum.UserInputType.MouseButton1
		then

			dragging = false

		end

	end
)

UserInputService.InputChanged:Connect(
	function(input)

		if
			dragging
			and input.UserInputType
				== Enum.UserInputType.MouseMovement
		then

			local delta =
				input.Position - dragStart

			mainFrame.Position =
				UDim2.new(
					startPosition.X.Scale,
					startPosition.X.Offset + delta.X,
					startPosition.Y.Scale,
					startPosition.Y.Offset + delta.Y
				)

			shadow.Position =
				UDim2.new(
					mainFrame.Position.X.Scale,
					mainFrame.Position.X.Offset + 6,
					mainFrame.Position.Y.Scale,
					mainFrame.Position.Y.Offset + 6
				)

		end

	end
)

--==============================================================
-- WINDOW ANIMATION
--==============================================================

local function TweenWindow(
	size,
	position
)

	TweenService:Create(
		mainFrame,
		TweenInfo.new(
			0.25,
			Enum.EasingStyle.Quart,
			Enum.EasingDirection.Out
		),
		{
			Size = size,
			Position = position
		}
	):Play()

	TweenService:Create(
		shadow,
		TweenInfo.new(
			0.25,
			Enum.EasingStyle.Quart,
			Enum.EasingDirection.Out
		),
		{
			Size = size,
			Position = UDim2.new(
				position.X.Scale,
				position.X.Offset + 6,
				position.Y.Scale,
				position.Y.Offset + 6
			)
		}
	):Play()

end

--==============================================================
-- MINIMIZE
--==============================================================

minimizeButton.MouseButton1Click:Connect(
	function()

		if windowMaximized then
			return
		end

		windowMinimized =
			not windowMinimized

		if windowMinimized then

			TweenWindow(
				UDim2.new(
					normalSize.X.Scale,
					normalSize.X.Offset,
					0,
					46
				),
				mainFrame.Position
			)

		else

			TweenWindow(
				normalSize,
				mainFrame.Position
			)

		end

	end
)

--==============================================================
-- MAXIMIZE / RESTORE
--==============================================================

maximizeButton.MouseButton1Click:Connect(
	function()

		windowMinimized = false

		windowMaximized =
			not windowMaximized

		if windowMaximized then

			maximizeButton.Text =
				"❐"

			TweenWindow(
				maximizedSize,
				maximizedPosition
			)

		else

			maximizeButton.Text =
				"□"

			TweenWindow(
				normalSize,
				normalPosition
			)

		end

	end
)

--==============================================================
-- CLOSE
--==============================================================

closeButton.MouseButton1Click:Connect(
	function()

		aimEnabled = false
		lockedTarget = nil

		TweenService:Create(
			mainFrame,
			TweenInfo.new(
				0.2,
				Enum.EasingStyle.Back,
				Enum.EasingDirection.In
			),
			{
				Size = UDim2.fromOffset(
					0,
					0
				)
			}
		):Play()

		TweenService:Create(
			shadow,
			TweenInfo.new(
				0.2,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.In
			),
			{
				Size = UDim2.fromOffset(
					0,
					0
				)
			}
		):Play()

		task.delay(
			0.22,
			function()
				screenGui:Destroy()
			end
		)

	end
)

--==============================================================
-- AIM TARGET FINDER
--==============================================================

local function GetBestTarget()

	local myChar =
		LocalPlayer.Character

	if
		not myChar
		or not myChar:FindFirstChild(
			"HumanoidRootPart"
		)
	then
		return nil
	end

	local myPos =
		myChar.HumanoidRootPart.Position

	local closestAngleTarget = nil
	local smallestAngle = 45

	local closestDistanceTarget = nil
	local smallestDistance = math.huge

	for _, obj in ipairs(
		workspace:GetDescendants()
	) do

		if
			obj:IsA("Model")
			and obj ~= myChar
		then

			local hum =
				obj:FindFirstChildOfClass(
					"Humanoid"
				)

			local hrp =
				obj:FindFirstChild(
					"HumanoidRootPart"
				)
				or obj:FindFirstChild("Head")

			if
				hum
				and hrp
				and hum.Health > 0
			then

				local targetPos =
					hrp.Position

				local dist =
					(targetPos - myPos).Magnitude

				local offset =
					targetPos
					- Camera.CFrame.Position

				if offset.Magnitude > 0 then

					local camDirection =
						Camera.CFrame.LookVector

					local dirToTarget =
						offset.Unit

					local dot =
						math.clamp(
							camDirection:Dot(
								dirToTarget
							),
							-1,
							1
						)

					local angle =
						math.deg(
							math.acos(dot)
						)

					if angle < smallestAngle then

						smallestAngle =
							angle

						closestAngleTarget =
							hrp

					end

				end

				if
					dist < smallestDistance
				then

					smallestDistance =
						dist

					closestDistanceTarget =
						hrp

				end

			end

		end

	end

	return closestAngleTarget
		or closestDistanceTarget

end

--==============================================================
-- AIM CAMERA LOOP
--==============================================================

RunService.RenderStepped:Connect(
	function()

		if
			not aimEnabled
			or not lockedTarget
		then
			return
		end

		local myChar =
			LocalPlayer.Character

		local myHRP =
			myChar
			and myChar:FindFirstChild(
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

	end
)

--==============================================================
-- AIM BUTTON
--==============================================================

aimButton.MouseButton1Click:Connect(
	function()

		aimEnabled =
			not aimEnabled

		if aimEnabled then

			lockedTarget =
				GetBestTarget()

			if lockedTarget then

				aimButton.Text =
					"●  ACTIVE"

				aimButton.BackgroundColor3 =
					Color3.fromRGB(
						45,
						165,
						95
					)

				statusLabel.Text =
					"●  AUTO AIM ACTIVE"

				statusLabel.TextColor3 =
					Color3.fromRGB(
						85,
						200,
						120
					)

			else

				aimEnabled = false

				aimButton.Text =
					"NO TARGET"

				aimButton.BackgroundColor3 =
					Color3.fromRGB(
						200,
						100,
						45
					)

				statusLabel.Text =
					"●  NO TARGET"

				statusLabel.TextColor3 =
					Color3.fromRGB(
						230,
						170,
						80
					)

			end

		else

			lockedTarget = nil

			aimButton.Text =
				"OFF"

			aimButton.BackgroundColor3 =
				Color3.fromRGB(
					150,
					50,
					50
				)

			statusLabel.Text =
				"●  READY"

			statusLabel.TextColor3 =
				Color3.fromRGB(
					85,
					200,
					120
				)

		end

	end
)

--==============================================================
-- HOVER EFFECT
--==============================================================

aimButton.MouseEnter:Connect(
	function()

		TweenService:Create(
			aimButton,
			TweenInfo.new(0.12),
			{
				Size =
					UDim2.fromOffset(
						110,
						40
					)
			}
		):Play()

	end
)

aimButton.MouseLeave:Connect(
	function()

		TweenService:Create(
			aimButton,
			TweenInfo.new(0.12),
			{
				Size =
					UDim2.fromOffset(
						105,
						38
					)
			}
		):Play()

	end
)

--==============================================================
-- INITIAL WINDOW ANIMATION
--==============================================================

mainFrame.Size =
	UDim2.fromOffset(
		480,
		0
	)

mainFrame.Position =
	UDim2.new(
		0.5,
		-240,
		0.5,
		-175
	)

shadow.Size =
	UDim2.fromOffset(
		480,
		0
	)

shadow.Position =
	UDim2.new(
		0.5,
		-234,
		0.5,
		-169
	)

TweenService:Create(
	mainFrame,
	TweenInfo.new(
		0.4,
		Enum.EasingStyle.Quart,
		Enum.EasingDirection.Out
	),
	{
		Size = normalSize
	}
):Play()

TweenService:Create(
	shadow,
	TweenInfo.new(
		0.4,
		Enum.EasingStyle.Quart,
		Enum.EasingDirection.Out
	),
	{
		Size = normalSize
	}
):Play()

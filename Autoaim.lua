local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Trạng thái Aim & Biến Lưu Mục Tiêu Khóa
local aimEnabled = false
local lockedTarget = nil

--------------------------------------------------------------------------------
-- 1. TẠO GIAO DIỆN MENU BẬT / TẮT (GUI)
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- 2. HÀM QUÉT DÒ TÌM MỤC TIÊU BAN ĐẦU
--------------------------------------------------------------------------------
local function GetBestTarget()
	local myChar = LocalPlayer.Character
	if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
	local myPos = myChar.HumanoidRootPart.Position

	local closestAngleTarget = nil
	local smallestAngle = 45

	local closestDistanceTarget = nil
	local smallestDistance = math.huge

	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and obj ~= myChar then
			local hum = obj:FindFirstChildOfClass("Humanoid")
			local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")

			if hum and hrp and hum.Health > 0 then
				local targetPos = hrp.Position
				local dist = (targetPos - myPos).Magnitude

				local camDirection = Camera.CFrame.LookVector
				local dirToTarget = (targetPos - Camera.CFrame.Position).Unit
				local angle = math.deg(math.acos(camDirection:Dot(dirToTarget)))

				if angle < smallestAngle then
					smallestAngle = angle
					closestAngleTarget = hrp
				end

				if dist < smallestDistance then
					smallestDistance = dist
					closestDistanceTarget = hrp
				end
			end
		end
	end

	return closestAngleTarget or closestDistanceTarget
end

--------------------------------------------------------------------------------
-- 3. VÒNG LẶP AIM (CHỈ BẢO TRÌ VÀ KHÓA CAMERA VÀO MỤC TIÊU)
--------------------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	if aimEnabled and lockedTarget then
		local myChar = LocalPlayer.Character
		local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
		
		local parentModel = lockedTarget.Parent
		local hum = parentModel and parentModel:FindFirstChildOfClass("Humanoid")

		if parentModel and hum and hum.Health > 0 and myHRP then
			local targetPos = lockedTarget.Position
			local camPos = Camera.CFrame.Position

			-- Đặt lại góc nhìn của Camera hướng về phía mục tiêu, giữ nguyên vị trí hiện tại của Camera
			Camera.CFrame = CFrame.new(camPos, targetPos)
		else
			-- Mục tiêu chết hoặc hủy
			lockedTarget = nil
		end
	end
end)

--------------------------------------------------------------------------------
-- 4. BẬT / TẮT
--------------------------------------------------------------------------------
toggleBtn.MouseButton1Click:Connect(function()
	aimEnabled = not aimEnabled
	if aimEnabled then
		lockedTarget = GetBestTarget()

		if lockedTarget then
			toggleBtn.Text = "AUTO AIM: LOCKED"
			toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		else
			toggleBtn.Text = "NO TARGET!"
			toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
		end
	else
		lockedTarget = nil
		toggleBtn.Text = "AUTO AIM: OFF"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	end
end)

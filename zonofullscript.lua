local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Trạng thái Aim
local aimEnabled = false

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
-- 2. HÀM QUÉT MỤC TIÊU (PLAYERS + NPCS)
--------------------------------------------------------------------------------
local function GetBestTarget()
	local myChar = LocalPlayer.Character
	if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
	local myPos = myChar.HumanoidRootPart.Position

	local closestAngleTarget = nil
	local smallestAngle = 35 -- Góc nhìn (độ)

	local closestDistanceTarget = nil
	local smallestDistance = math.huge

	-- Lấy tất cả các Model trong Workspace (Bao gồm cả Player lẫn NPC)
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and obj ~= myChar then
			local hum = obj:FindFirstChildOfClass("Humanoid")
			local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")

			-- Kiểm tra xem đây có phải nhân vật/NPC còn sống không
			if hum and hrp and hum.Health > 0 then
				local targetPos = hrp.Position
				local dist = (targetPos - myPos).Magnitude

				-- 1. Tính góc nhìn từ Camera đến mục tiêu
				local camDirection = Camera.CFrame.LookVector
				local dirToTarget = (targetPos - Camera.CFrame.Position).Unit
				local angle = math.deg(math.acos(camDirection:Dot(dirToTarget)))

				-- Lựa chọn ưu tiên góc nhìn
				if angle < smallestAngle then
					smallestAngle = angle
					closestAngleTarget = hrp
				end

				-- Lựa chọn ưu tiên khoảng cách (xung quanh 360 độ)
				if dist < smallestDistance then
					smallestDistance = dist
					closestDistanceTarget = hrp
				end
			end
		end
	end

	-- Ưu tiên 1: Nhắm vào NPC/Player đang nhìn
	if closestAngleTarget then
		return closestAngleTarget
	end

	-- Ưu tiên 2: Nhắm vào NPC/Player gần nhất xung quanh
	return closestDistanceTarget
end

--------------------------------------------------------------------------------
-- 3. VÒNG LẶP AIM
--------------------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	if aimEnabled then
		local targetPart = GetBestTarget()
		if targetPart then
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
		end
	end
end)

--------------------------------------------------------------------------------
-- 4. BẬT / TẮT
--------------------------------------------------------------------------------
toggleBtn.MouseButton1Click:Connect(function()
	aimEnabled = not aimEnabled
	if aimEnabled then
		toggleBtn.Text = "AUTO AIM: ON"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	else
		toggleBtn.Text = "AUTO AIM: OFF"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	end
end)

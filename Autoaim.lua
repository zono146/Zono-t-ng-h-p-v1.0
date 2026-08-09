local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Trạng thái Aim & Biến Lưu Mục Tiêu Khóa
local aimEnabled = false
local lockedTarget = nil

--------------------------------------------------------------------------------
-- 1. TẠO KHUNG MAIN GUI MỚI (RỘNG RÃI & MỞ RỘNG)
--------------------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HeartBattlegroundTestBench"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Bảng Main mới rộng 220px, cao 240px (tha hồ chứa tính năng)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 240)
mainFrame.Position = UDim2.new(0.05, 0, 0.35, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(255, 60, 60)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Tiêu đề Bảng
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 32)
titleLabel.Text = "⚡ HEART BATTLEGROUND ⚡"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 14
titleLabel.Parent = mainFrame

--------------------------------------------------------------------------------
-- GIAO DIỆN CÁC NÚT BẤM (UI BUTTONS)
--------------------------------------------------------------------------------

-- Nút 1: AUTO AIM (Ổn định)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.88, 0, 0, 35)
toggleBtn.Position = UDim2.new(0.06, 0, 0.18, 0)
toggleBtn.Text = "AUTO AIM: OFF"
toggleBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 14
toggleBtn.Parent = mainFrame

-- Nút 2: TÍNH NĂNG THỬ NGHIỆM MỚI 1 (Slot 1)
local expBtn1 = Instance.new("TextButton")
expBtn1.Size = UDim2.new(0.88, 0, 0, 35)
expBtn1.Position = UDim2.new(0.06, 0, 0.36, 0)
expBtn1.Text = "[THỬ NGHIỆM 1] CHỜ YÊU CẦU..."
expBtn1.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
expBtn1.TextColor3 = Color3.fromRGB(200, 200, 200)
expBtn1.Font = Enum.Font.SourceSansBold
expBtn1.TextSize = 12
expBtn1.Parent = mainFrame

-- Nút 3: TÍNH NĂNG THỬ NGHIỆM MỚI 2 (Slot 2)
local expBtn2 = Instance.new("TextButton")
expBtn2.Size = UDim2.new(0.88, 0, 0, 35)
expBtn2.Position = UDim2.new(0.06, 0, 0.54, 0)
expBtn2.Text = "[THỬ NGHIỆM 2] CHỜ YÊU CẦU..."
expBtn2.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
expBtn2.TextColor3 = Color3.fromRGB(200, 200, 200)
expBtn2.Font = Enum.Font.SourceSansBold
expBtn2.TextSize = 12
expBtn2.Parent = mainFrame

-- Ghi chú nhỏ phía dưới
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0, 30)
infoLabel.Position = UDim2.new(0, 0, 0.82, 0)
infoLabel.Text = "Dev Test Bench v2.0"
infoLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
infoLabel.BackgroundTransparency = 1
infoLabel.Font = Enum.Font.SourceSansItalic
infoLabel.TextSize = 12
infoLabel.Parent = mainFrame

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
-- 3. VÒNG LẶP AIM (CAMERA GÓC NHÌN THỨ 3 ỔN ĐỊNH)
--------------------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	if aimEnabled and lockedTarget then
		local myChar = LocalPlayer.Character
		local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
		
		local parentModel = lockedTarget.Parent
		local hum = parentModel and parentModel:FindFirstChildOfClass("Humanoid")

		if parentModel and hum and hum.Health > 0 and myHRP then
			local targetPos = lockedTarget.Position
			local myPos = myHRP.Position
			
			-- 1. Xoay nhân vật hướng mặt về phía đối thủ
			local lookAtPos = Vector3.new(targetPos.X, myPos.Y, targetPos.Z)
			myHRP.CFrame = CFrame.new(myPos, lookAtPos)

			-- 2. Lấy khoảng cách Zoom hiện tại
			local currentZoom = (Camera.CFrame.Position - myPos).Magnitude
			if currentZoom < 2 then currentZoom = 10 end

			-- 3. Tính toán hướng từ Nhân vật -> Đến Đối thủ
			local dirToTarget = (targetPos - myPos).Unit
			if dirToTarget.Magnitude == 0 then dirToTarget = myHRP.CFrame.LookVector end

			-- 4. Đặt Camera ở PHÍA SAU LƯNG nhân vật
			local camOffset = -dirToTarget * currentZoom + Vector3.new(0, 2.5, 0)
			local newCamPos = myPos + camOffset

			-- 5. Cập nhật Camera nhìn về phía đối thủ
			Camera.CFrame = CFrame.new(newCamPos, targetPos)
		else
			-- Mục tiêu chết hoặc hủy
			lockedTarget = nil
		end
	end
end)

--------------------------------------------------------------------------------
-- 4. SỰ KIỆN NÚT AUTO AIM
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

--------------------------------------------------------------------------------
-- 5. SỰ KIỆN CÁC NÚT THỬ NGHIỆM MỚI (CHỜ LẬP TRÌNH)
--------------------------------------------------------------------------------
expBtn1.MouseButton1Click:Connect(function()
	print("Đã bấm Ô Thử Nghiệm 1 - Chưa gán tính năng!")
end)

expBtn2.MouseButton1Click:Connect(function()
	print("Đã bấm Ô Thử Nghiệm 2 - Chưa gán tính năng!")
end)

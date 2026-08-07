local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Trạng thái Aim & Biến Lưu Mục Tiêu Khóa
local aimEnabled = false
local lockedTarget = nil -- Dùng để "khóa cứng" 1 mục tiêu duy nhất

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
	local smallestAngle = 45 -- Mở rộng góc nhìn lên 45 độ để dễ nhận diện mục tiêu trước mặt hơn

	local closestDistanceTarget = nil
	local smallestDistance = math.huge

	-- Quét tất cả Model trong Workspace (Player + NPC)
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and obj ~= myChar then
			local hum = obj:FindFirstChildOfClass("Humanoid")
			local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")

			if hum and hrp and hum.Health > 0 then
				local targetPos = hrp.Position
				local dist = (targetPos - myPos).Magnitude

				-- Tính góc nhìn từ Camera đến mục tiêu
				local camDirection = Camera.CFrame.LookVector
				local dirToTarget = (targetPos - Camera.CFrame.Position).Unit
				local angle = math.deg(math.acos(camDirection:Dot(dirToTarget)))

				-- Ưu tiên 1: Mục tiêu nằm trước mặt (trong góc nhìn)
				if angle < smallestAngle then
					smallestAngle = angle
					closestAngleTarget = hrp
				end

				-- Ưu tiên 2: Mục tiêu gần nhất xung quanh
				if dist < smallestDistance then
					smallestDistance = dist
					closestDistanceTarget = hrp
				end
			end
		end
	end

	if closestAngleTarget then
		return closestAngleTarget
	end

	return closestDistanceTarget
end

--------------------------------------------------------------------------------
-- 3. VÒNG LẶP AIM (KHÓA MỤC TIÊU CỐ ĐỊNH)
--------------------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	if aimEnabled and lockedTarget then
		-- Kiểm tra xem mục tiêu được khóa còn tồn tại và còn sống hay không
		local parentModel = lockedTarget.Parent
		local hum = parentModel and parentModel:FindFirstChildOfClass("Humanoid")

		if parentModel and hum and hum.Health > 0 then
			-- Khóa cứng Camera vào đúng mục tiêu đã chọn
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, lockedTarget.Position)
		else
			-- Nếu mục tiêu chết hoặc biến mất, tự động nhả khóa
			lockedTarget = nil
		end
	end
end)

--------------------------------------------------------------------------------
-- 4. BẬT / TẮT (KÍCH HOẠT LỌC MỤC TIÊU)
--------------------------------------------------------------------------------
toggleBtn.MouseButton1Click:Connect(function()
	aimEnabled = not aimEnabled
	if aimEnabled then
		-- Khi BẬT: Tìm và KHÓA duy nhất 1 mục tiêu tại thời điểm đó
		lockedTarget = GetBestTarget()

		if lockedTarget then
			toggleBtn.Text = "AUTO AIM: LOCKED"
			toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		else
			-- Nếu xung quanh không có ai
			toggleBtn.Text = "NO TARGET!"
			toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
		end
	else
		-- Khi TẮT: Giải phóng mục tiêu đã khóa
		lockedTarget = nil
		toggleBtn.Text = "AUTO AIM: OFF"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	end
end)

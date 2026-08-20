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
-- HELPER: LẤY CHARACTER GỐC CỦA OBJECT
--==============================================================

local function GetCharacterFromTarget(target)
	if not target then
		return nil
	end

	local model = target:FindFirstAncestorOfClass("Model")

	if not model then
		return nil
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return nil
	end

	return model, humanoid
end

--==============================================================
-- HELPER: KIỂM TRA TARGET CÓ CÒN HỢP LỆ
--==============================================================

local function IsTargetValid(target)
	if not target or not target.Parent then
		return false
	end

	local model, humanoid = GetCharacterFromTarget(target)

	if not model or not humanoid then
		return false
	end

	if humanoid.Health <= 0 then
		return false
	end

	local myChar = LocalPlayer.Character

	if model == myChar then
		return false
	end

	return true
end

--==============================================================
-- HELPER: KIỂM TRA CÓ NHÌN THẤY TARGET KHÔNG
--==============================================================

local function IsTargetVisible(target)
	if not IsTargetValid(target) then
		return false
	end

	local myChar = LocalPlayer.Character

	if not myChar then
		return false
	end

	local origin = Camera.CFrame.Position
	local direction = target.Position - origin

	if direction.Magnitude <= 0 then
		return true
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {
		myChar
	}

	local result = workspace:Raycast(
		origin,
		direction,
		raycastParams
	)

	-- Không có vật chắn
	if not result then
		return true
	end

	-- Nếu ray chạm chính target hoặc model của target
	local targetModel = target:FindFirstAncestorOfClass("Model")

	if targetModel and result.Instance:IsDescendantOf(targetModel) then
		return true
	end

	return false
end

--==============================================================
-- TÌM MỤC TIÊU GẦN NHẤT
--==============================================================

local function GetBestTarget()
	local myChar = LocalPlayer.Character

	if not myChar then
		return nil
	end

	local myHRP = myChar:FindFirstChild("HumanoidRootPart")

	if not myHRP then
		return nil
	end

	local myPos = myHRP.Position

	local closestTarget = nil
	local closestDistance = math.huge

	for _, obj in ipairs(workspace:GetDescendants()) do

		if obj:IsA("Model") and obj ~= myChar then

			local humanoid = obj:FindFirstChildOfClass("Humanoid")

			local targetPart =
				obj:FindFirstChild("HumanoidRootPart")
				or obj:FindFirstChild("Head")

			if humanoid
				and targetPart
				and humanoid.Health > 0 then

				local distance =
					(targetPart.Position - myPos).Magnitude

				-- Ưu tiên khoảng cách gần nhất
				if distance < closestDistance then

					-- Chỉ chọn mục tiêu đang nhìn thấy được
					if IsTargetVisible(targetPart) then
						closestDistance = distance
						closestTarget = targetPart
					end

				end
			end
		end
	end

	return closestTarget
end

--==============================================================
-- LOCK TARGET
--==============================================================

local function AcquireNewTarget()
	if not aimEnabled then
		lockedTarget = nil
		return
	end

	lockedTarget = GetBestTarget()

	if lockedTarget then
		toggleBtn.Text = "AUTO AIM: LOCKED"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	else
		toggleBtn.Text = "NO TARGET!"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
	end
end

--==============================================================
-- CAMERA AIM LOOP
--==============================================================

RunService.RenderStepped:Connect(function()

	if not aimEnabled then
		return
	end

	local myChar = LocalPlayer.Character
	local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

	-- Nếu character của mình chưa tồn tại
	if not myHRP then
		lockedTarget = nil
		return
	end

	--==========================================================
	-- KIỂM TRA TARGET HIỆN TẠI
	--==========================================================

	if not IsTargetValid(lockedTarget)
		or not IsTargetVisible(lockedTarget) then

		AcquireNewTarget()
	end

	--==========================================================
	-- NẾU VẪN KHÔNG CÓ TARGET THÌ DỪNG
	--==========================================================

	if not lockedTarget then
		return
	end

	--==========================================================
	-- LẤY THÔNG TIN TARGET
	--==========================================================

	local parentModel, humanoid =
		GetCharacterFromTarget(lockedTarget)

	if not parentModel or not humanoid then
		AcquireNewTarget()
		return
	end

	if humanoid.Health <= 0 then
		AcquireNewTarget()
		return
	end

	local targetPos = lockedTarget.Position
	local myPos = myHRP.Position

	--==========================================================
	-- GIỮ ZOOM HIỆN TẠI
	--==========================================================

	local currentZoom =
		(Camera.CFrame.Position - myPos).Magnitude

	if currentZoom < 2 then
		currentZoom = 10
	end

	--==========================================================
	-- HƯỚNG TỪ PLAYER TỚI TARGET
	--==========================================================

	local direction = targetPos - myPos

	if direction.Magnitude <= 0.001 then
		direction = myHRP.CFrame.LookVector
	else
		direction = direction.Unit
	end

	--==========================================================
	-- CAMERA Ở SAU PLAYER
	--==========================================================

	local camOffset =
		-direction * currentZoom
		+ Vector3.new(0, 2.5, 0)

	local newCamPos =
		myPos + camOffset

	--==========================================================
	-- XOAY CAMERA VỀ TARGET
	--==========================================================

	Camera.CFrame =
		CFrame.new(newCamPos, targetPos)
end)

--==============================================================
-- TOGGLE
--==============================================================

toggleBtn.MouseButton1Click:Connect(function()

	aimEnabled = not aimEnabled

	if aimEnabled then

		AcquireNewTarget()

	else

		lockedTarget = nil

		toggleBtn.Text = "AUTO AIM: OFF"
		toggleBtn.BackgroundColor3 =
			Color3.fromRGB(150, 50, 50)
	end
end)

--==============================================================
-- KHI CHARACTER CỦA PLAYER RESPAWN
--==============================================================

LocalPlayer.CharacterAdded:Connect(function()
	if aimEnabled then

		lockedTarget = nil

		task.wait(0.2)

		AcquireNewTarget()
	end
end)

--==============================================================
-- TỰ KIỂM TRA KHI PLAYER KHÁC RỜI GAME
--==============================================================

Players.PlayerRemoving:Connect(function(player)
	if not aimEnabled or not lockedTarget then
		return
	end

	local targetModel = lockedTarget:FindFirstAncestorOfClass("Model")

	if targetModel and Players:GetPlayerFromCharacter(targetModel) == player then
		lockedTarget = nil
		AcquireNewTarget()
	end
end)

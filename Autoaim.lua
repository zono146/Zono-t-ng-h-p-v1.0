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
-- TARGET VALIDATION
--==============================================================

local function IsTargetValid(target)
	if not target then
		return false
	end

	if not target.Parent then
		return false
	end

	local model = target.Parent

	if not model:IsA("Model") then
		return false
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return false
	end

	if humanoid.Health <= 0 then
		return false
	end

	-- Target part still has to exist in the workspace
	if not target:IsDescendantOf(workspace) then
		return false
	end

	return true
end

--==============================================================
-- FIND NEW TARGET
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

	local closestAngleTarget = nil
	local smallestAngle = 45

	local closestDistanceTarget = nil
	local smallestDistance = math.huge

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and obj ~= myChar then

			local hum = obj:FindFirstChildOfClass("Humanoid")
			local hrp = obj:FindFirstChild("HumanoidRootPart")
				or obj:FindFirstChild("Head")

			if hum and hrp and hum.Health > 0 then

				local targetPos = hrp.Position
				local dist = (targetPos - myPos).Magnitude

				-- Distance target
				if dist < smallestDistance then
					smallestDistance = dist
					closestDistanceTarget = hrp
				end

				-- Angle target
				local cameraPosition = Camera.CFrame.Position
				local cameraDirection = Camera.CFrame.LookVector

				local direction = targetPos - cameraPosition

				if direction.Magnitude > 0 then
					local dirToTarget = direction.Unit

					local dot = math.clamp(
						cameraDirection:Dot(dirToTarget),
						-1,
						1
					)

					local angle = math.deg(math.acos(dot))

					if angle < smallestAngle then
						smallestAngle = angle
						closestAngleTarget = hrp
					end
				end
			end
		end
	end

	return closestAngleTarget or closestDistanceTarget
end

--==============================================================
-- ACQUIRE / REACQUIRE TARGET
--==============================================================

local function AcquireTarget()
	if not aimEnabled then
		lockedTarget = nil
		return
	end

	local newTarget = GetBestTarget()

	if newTarget then
		lockedTarget = newTarget

		toggleBtn.Text = "AUTO AIM: LOCKED"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	else
		lockedTarget = nil

		toggleBtn.Text = "NO TARGET!"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
	end
end

--==============================================================
-- AIM LOOP
--==============================================================

RunService.RenderStepped:Connect(function()

	if not aimEnabled then
		return
	end

	--==========================================================
	-- CURRENT TARGET INVALID -> FIND ANOTHER
	--==========================================================

	if not IsTargetValid(lockedTarget) then
		lockedTarget = nil
		AcquireTarget()
	end

	--==========================================================
	-- NO TARGET AVAILABLE
	--==========================================================

	if not lockedTarget then
		return
	end

	local myChar = LocalPlayer.Character
	local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

	if not myHRP then
		return
	end

	--==========================================================
	-- AIM AT TARGET
	--==========================================================

	local targetPos = lockedTarget.Position
	local myPos = myHRP.Position

	local currentZoom =
		(Camera.CFrame.Position - myPos).Magnitude

	if currentZoom < 2 then
		currentZoom = 10
	end

	local direction = targetPos - myPos

	if direction.Magnitude <= 0 then
		direction = myHRP.CFrame.LookVector
	end

	local dirToTarget = direction.Unit

	local camOffset =
		-dirToTarget * currentZoom
		+ Vector3.new(0, 2.5, 0)

	local newCamPos =
		myPos + camOffset

	Camera.CFrame =
		CFrame.new(newCamPos, targetPos)
end)

--==============================================================
-- TOGGLE
--==============================================================

toggleBtn.MouseButton1Click:Connect(function()

	aimEnabled = not aimEnabled

	if aimEnabled then

		toggleBtn.Text = "SEARCHING..."
		toggleBtn.BackgroundColor3 =
			Color3.fromRGB(200, 150, 0)

		AcquireTarget()

	else

		lockedTarget = nil

		toggleBtn.Text = "AUTO AIM: OFF"
		toggleBtn.BackgroundColor3 =
			Color3.fromRGB(150, 50, 50)
	end
end)

--==============================================================
-- PLAYER RESPAWN / CHARACTER CHANGES
--==============================================================

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		if aimEnabled then
			task.wait(0.15)

			-- Recheck because a new character may have appeared
			if not IsTargetValid(lockedTarget) then
				AcquireTarget()
			end
		end
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	if player ~= LocalPlayer then
		player.CharacterAdded:Connect(function()
			if aimEnabled then
				task.wait(0.15)

				if not IsTargetValid(lockedTarget) then
					AcquireTarget()
				end
			end
		end)
	end
end

--==============================================================
-- ALSO HANDLE PLAYERS LEAVING
--==============================================================

Players.PlayerRemoving:Connect(function(player)

	if not lockedTarget then
		return
	end

	local targetModel = lockedTarget.Parent
	local targetPlayer = Players:GetPlayerFromCharacter(targetModel)

	if targetPlayer == player then
		lockedTarget = nil

		if aimEnabled then
			AcquireTarget()
		end
	end
end)titleLabel.TextSize = 14
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


---

-- 2. HÀM QUÉT DÒ TÌM MỤC TIÊU BAN ĐẦU

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


---

-- 3. VÒNG LẶP AIM (CAMERA ĐI THEO NHÂN VẬT & XOAY VỀ MỤC TIÊU)

RunService.RenderStepped:Connect(function()
if aimEnabled and lockedTarget then
local myChar = LocalPlayer.Character
local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

local parentModel = lockedTarget.Parent
local hum = parentModel and parentModel:FindFirstChildOfClass("Humanoid")

if parentModel and hum and hum.Health > 0 and myHRP then    
	local targetPos = lockedTarget.Position    
	local myPos = myHRP.Position    
	    
	-- 1. Lấy khoảng cách Zoom hiện tại giữa Camera và Nhân vật    
	local currentZoom = (Camera.CFrame.Position - myPos).Magnitude    
	if currentZoom < 2 then currentZoom = 10 end -- Độ xa mặc định nếu zoom quá gần    

	-- 2. Tính hướng từ Nhân vật đến Đối thủ    
	local dirToTarget = (targetPos - myPos).Unit    
	if dirToTarget.Magnitude == 0 then dirToTarget = myHRP.CFrame.LookVector end    

	-- 3. Đặt vị trí Camera LÙI VỀ SAU LƯNG nhân vật (dựa trên hướng nhìn sang đối thủ)    
	-- Giúp nhân vật LUÔN NẰM TRONG KHUNG HÌNH kể cả khi di chuyển sang trái/phải    
	local camOffset = -dirToTarget * currentZoom + Vector3.new(0, 2.5, 0)    
	local newCamPos = myPos + camOffset    

	-- 4. Cập nhật Camera nhìn về phía đối thủ mà KHÔNG xoay nhân vật    
	Camera.CFrame = CFrame.new(newCamPos, targetPos)    
else    
	-- Mục tiêu chết hoặc mất dấu    
	lockedTarget = nil    
end

end

end)


---

-- 4. BẬT / TẮT

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

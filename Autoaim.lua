-- LocalScript / Command Bar Test trong Roblox Studio
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Trạng thái Aim & Biến Lưu Mục Tiêu Khóa
local aimEnabled = false
local lockedTarget = nil

--------------------------------------------------------------------------------
-- 1. HÀM QUÉT DÒ TÌM MỤC TIÊU BAN ĐẦU
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
-- 2. VÒNG LẶP AIM (RENDERSTEPPED)
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
			
			-- Xoay nhân vật hướng mặt về phía đối thủ
			local lookAtPos = Vector3.new(targetPos.X, myPos.Y, targetPos.Z)
			myHRP.CFrame = CFrame.new(myPos, lookAtPos)

			-- Lấy khoảng cách Zoom hiện tại
			local currentZoom = (Camera.CFrame.Position - myPos).Magnitude
			if currentZoom < 2 then currentZoom = 10 end

			-- Tính hướng từ Nhân vật -> Đối thủ
			local dirToTarget = (targetPos - myPos).Unit
			if dirToTarget.Magnitude == 0 then dirToTarget = myHRP.CFrame.LookVector end

			-- Đặt Camera phía sau lưng
			local camOffset = -dirToTarget * currentZoom + Vector3.new(0, 2.5, 0)
			local newCamPos = myPos + camOffset

			-- Cập nhật CFrame Camera
			Camera.CFrame = CFrame.new(newCamPos, targetPos)
		else
			-- Tự tìm lại mục tiêu nếu mục tiêu cũ chết hoặc mất
			lockedTarget = GetBestTarget()
		end
	end
end)

--------------------------------------------------------------------------------
-- 3. KHỞI TẠO MENU REDZ V2
--------------------------------------------------------------------------------
local redzlib = loadstring(game:HttpGet("https://raw.githubusercontent.com/daucobonhi/Ui-Redz-V2/refs/heads/main/UiREDzV2.lua"))()

local Window = MakeWindow({
  Hub = {
    Title = "HEART BATTLEGROUND",
    Animation = "Dev Testing Menu"
  },
  Key = {
    KeySystem = false
  }
})

MinimizeButton({
  Image = "http://www.roblox.com/asset/?id=93280542413490",
  Size = {25, 25},
  Color = Color3.fromRGB(10, 10, 10),
  Corner = true,
  Stroke = false,
  StrokeColor = Color3.fromRGB(255, 0, 0)
})

-- Tạo Tab
local Tab1 = MakeTab({Name = "Thử nghiệm"})

-- Hàm bổ trợ giúp hiển thị đúng UI cho Redz V2 trong Studio
local function SafeAddToggle(tabObj, config)
    if typeof(AddToggle) == "function" then
        return AddToggle(tabObj, config)
    elseif tabObj and typeof(tabObj.AddToggle) == "function" then
        return tabObj:AddToggle(config)
    end
end

local function SafeAddButton(tabObj, config)
    if typeof(AddButton) == "function" then
        return AddButton(tabObj, config)
    elseif tabObj and typeof(tabObj.AddButton) == "function" then
        return tabObj:AddButton(config)
    end
end

--------------------------------------------------------------------------------
-- 4. TẠO CÁC NÚT ĐIỀU KHIỂN AIM
--------------------------------------------------------------------------------

-- Toggle Auto Aim
SafeAddToggle(Tab1, {
  Name = "Auto Aim (Khóa Mục Tiêu)",
  Description = "Tự động khóa Camera & xoay hướng mặt vào đối thủ",
  Default = false,
  Callback = function(Value)
    aimEnabled = Value
    if aimEnabled then
      lockedTarget = GetBestTarget()
    else
      lockedTarget = nil
    end
  end
})

-- Nút quét lại mục tiêu
SafeAddButton(Tab1, {
  Name = "Đổi Mục Tiêu (Re-target)",
  Description = "Quét tìm đối thủ/Dummy khác gần nhất",
  Callback = function()
    if aimEnabled then
      lockedTarget = GetBestTarget()
    end
  end
})

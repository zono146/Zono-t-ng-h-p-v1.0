-- Services & Variables
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
			
			-- 1. Xoay nhân vật hướng mặt về phía đối thủ
			local lookAtPos = Vector3.new(targetPos.X, myPos.Y, targetPos.Z)
			myHRP.CFrame = CFrame.new(myPos, lookAtPos)

			-- 2. Lấy khoảng cách Zoom hiện tại của người chơi
			local currentZoom = (Camera.CFrame.Position - myPos).Magnitude
			if currentZoom < 2 then currentZoom = 10 end

			-- 3. Tính toán hướng từ Nhân vật -> Đến Đối thủ
			local dirToTarget = (targetPos - myPos).Unit
			if dirToTarget.Magnitude == 0 then dirToTarget = myHRP.CFrame.LookVector end

			-- 4. Đặt Camera ở PHÍA SAU LƯNG nhân vật
			local camOffset = -dirToTarget * currentZoom + Vector3.new(0, 2.5, 0)
			local newCamPos = myPos + camOffset

			-- 5. Cập nhật Camera luôn nhìn về phía đối thủ
			Camera.CFrame = CFrame.new(newCamPos, targetPos)
		else
			-- Mục tiêu chết/mất -> Tự động tìm lại mục tiêu mới nếu vẫn bật Aim
			lockedTarget = GetBestTarget()
		end
	end
end)

--------------------------------------------------------------------------------
-- 3. TẠO MENU REDZ V2 & KẾT NỐI TÍNH NĂNG AIM
--------------------------------------------------------------------------------
loadstring(game:HttpGet(("https://raw.githubusercontent.com/daucobonhi/Ui-Redz-V2/refs/heads/main/UiREDzV2.lua")))()

local Window = MakeWindow({
  Hub = {
    Title = "Zonoreal Hub",
    Animation = "Zonoreal Hub"
  },
  Key = {
    KeySystem = false,
    Title = "",
    Description = "",
    KeyLink = "",
    Keys = {""},
    Notifi = {
      Notifications = true,
      CorrectKey = "Running",
      Incorrectkey = "incorrect",
      CopyKeyLink = "Copied"
    }
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

------ Tab Thử Nghiệm
local Tab1 = MakeTab({Name = "AIMBOT"})

------ Các Chức Năng
Tab1:AddToggle({
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

Tab1:AddButton({
  Name = "Đổi Mục Tiêu (Re-target)",
  Description = "Quét lại mục tiêu mới gần nhất",
  Callback = function()
    if aimEnabled then
      lockedTarget = GetBestTarget()
    end
  end
})

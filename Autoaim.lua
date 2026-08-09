-- LocalScript đặt trong StarterPlayerScripts
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local aimEnabled = false
local lockedTarget = nil

-- 1. HÀM QUÉT DÒ TÌM MỤC TIÊU
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

-- 2. VÒNG LẶP AIM (RENDERSTEPPED)
RunService.RenderStepped:Connect(function()
	if aimEnabled and lockedTarget then
		local myChar = LocalPlayer.Character
		local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
		
		local parentModel = lockedTarget.Parent
		local hum = parentModel and parentModel:FindFirstChildOfClass("Humanoid")

		if parentModel and hum and hum.Health > 0 and myHRP then
			local targetPos = lockedTarget.Position
			local myPos = myHRP.Position
			
			local lookAtPos = Vector3.new(targetPos.X, myPos.Y, targetPos.Z)
			myHRP.CFrame = CFrame.new(myPos, lookAtPos)

			local currentZoom = (Camera.CFrame.Position - myPos).Magnitude
			if currentZoom < 2 then currentZoom = 10 end

			local dirToTarget = (targetPos - myPos).Unit
			if dirToTarget.Magnitude == 0 then dirToTarget = myHRP.CFrame.LookVector end

			local camOffset = -dirToTarget * currentZoom + Vector3.new(0, 2.5, 0)
			local newCamPos = myPos + camOffset

			Camera.CFrame = CFrame.new(newCamPos, targetPos)
		else
			lockedTarget = GetBestTarget()
		end
	end
end)

-- 3. BẮT SỰ KIỆN BẤM PHÍM ĐỂ TEST IN-GAME
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	-- Bấm phím 'E' để Bật / Tắt Aim
	if input.KeyCode == Enum.KeyCode.E then
		aimEnabled = not aimEnabled
		if aimEnabled then
			lockedTarget = GetBestTarget()
			print("[TEST STUDIO] Auto Aim: ON | Target:", lockedTarget and lockedTarget.Parent.Name or "None")
		else
			lockedTarget = nil
			print("[TEST STUDIO] Auto Aim: OFF")
		end
	end
	
	-- Bấm phím 'R' để Đổi mục tiêu khác
	if input.KeyCode == Enum.KeyCode.R and aimEnabled then
		lockedTarget = GetBestTarget()
		print("[TEST STUDIO] Re-targeted to:", lockedTarget and lockedTarget.Parent.Name or "None")
	end
end)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local GojoService = ReplicatedStorage:WaitForChild("Knit"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("GojoService")


local Config = {
    TELEPORT_DELAY = 0,
    DASH_SPEED = 0.65,
    TIME_PER_TARGET = 0.1,
    DISTANCE_FROM_TARGET = 2,
    HEIGHT_OFFSET = 0,
    VOID_DELAY = 16,
    AUTO_VOID = false,
    TP_COUNT_MIN = 2,
    TP_COUNT_MAX = 5
}

local tpEnabled = false
local canTeleport = false
local isRunning = true
local spectatingPlayer = nil

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SimpleGojoUI"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 560, 0, 320)
Main.Position = UDim2.new(0.5, -280, 0.5, -160)
Main.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 6)

-- Topbar
local Topbar = Instance.new("Frame")
Topbar.Size = UDim2.new(1, 0, 0, 30)
Topbar.BackgroundColor3 = Color3.fromRGB(36, 36, 40)
Topbar.BorderSizePixel = 0
Topbar.Parent = Main
local TBCorner = Instance.new("UICorner", Topbar)
TBCorner.CornerRadius = UDim.new(0, 6)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 200, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.Text = "GOJO KILL ALL HUB <font color='#888888'>v3.0</font>"
Title.RichText = true
Title.TextColor3 = Color3.fromRGB(224, 224, 224)
Title.TextSize = 12
Title.Font = Enum.Font.GothamMedium
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Parent = Topbar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -28, 0, 3)
CloseBtn.Text = "×"
CloseBtn.TextSize = 20
CloseBtn.TextColor3 = Color3.fromRGB(170, 170, 170)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Parent = Topbar
CloseBtn.MouseButton1Click:Connect(function() isRunning = false ScreenGui:Destroy() end)

-- Chia cột
local Left = Instance.new("Frame")
Left.Size = UDim2.new(0, 140, 1, -55)
Left.Position = UDim2.new(0, 0, 0, 30)
Left.BackgroundColor3 = Color3.fromRGB(32, 32, 36)
Left.BorderSizePixel = 0
Left.Parent = Main

local LeftHeader = Instance.new("TextLabel")
LeftHeader.Size = UDim2.new(1, 0, 0, 25)
LeftHeader.Text = "REMOTES / PLAYERS"
LeftHeader.TextSize = 9
LeftHeader.TextColor3 = Color3.fromRGB(100, 100, 100)
LeftHeader.BackgroundTransparency = 1
LeftHeader.Parent = Left

local LogList = Instance.new("ScrollingFrame")
LogList.Size = UDim2.new(1, -10, 1, -30)
LogList.Position = UDim2.new(0, 5, 0, 25)
LogList.BackgroundTransparency = 1
LogList.ScrollBarThickness = 2
LogList.Parent = Left
Instance.new("UIListLayout", LogList).Padding = UDim.new(0, 2)

local Right = Instance.new("Frame")
Right.Size = UDim2.new(1, -140, 1, -55)
Right.Position = UDim2.new(0, 140, 0, 30)
Right.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
Right.BorderSizePixel = 0
Right.Parent = Main

local ControlArea = Instance.new("ScrollingFrame")
ControlArea.Size = UDim2.new(1, 0, 1, -45)
ControlArea.BackgroundTransparency = 1
ControlArea.ScrollBarThickness = 2
ControlArea.Parent = Right
local ControlLayout = Instance.new("UIListLayout", ControlArea)
ControlLayout.Padding = UDim.new(0, 5)
Instance.new("UIPadding", ControlArea).PaddingLeft = UDim.new(0, 15)

-- HÀM TẠO SLIDER (Để chỉnh thông số trực tiếp)
local function CreateSlider(name, min, max, default, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0.9, 0, 0, 35)
    Frame.BackgroundTransparency = 1
    Frame.Parent = ControlArea
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 15)
    Label.Text = name .. ": " .. default
    Label.TextColor3 = Color3.fromRGB(160, 160, 180)
    Label.TextSize = 10
    Label.Font = Enum.Font.Code
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.BackgroundTransparency = 1
    Label.Parent = Frame
    
    local SliderBar = Instance.new("Frame")
    SliderBar.Size = UDim2.new(1, 0, 0, 4)
    SliderBar.Position = UDim2.new(0, 0, 0, 20)
    SliderBar.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    SliderBar.BorderSizePixel = 0
    SliderBar.Parent = Frame
    
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(99, 85, 214)
    Fill.BorderSizePixel = 0
    Fill.Parent = SliderBar
    
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 1, 0)
    Button.BackgroundTransparency = 1
    Button.Text = ""
    Button.Parent = SliderBar
    
    local function Update(input)
        local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
        Fill.Size = UDim2.new(pos, 0, 1, 0)
        local val = math.floor(min + (max - min) * pos)
        if max <= 10 then -- Cho các giá trị lẻ như Dash Speed
            val = math.round((min + (max - min) * pos) * 10) / 10
        end
        Label.Text = name .. ": " .. val
        callback(val)
    end
    
    Button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local move = game:GetService("UserInputService").InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then Update(input) end
            end)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then move:Disconnect() end
            end)
        end
    end)
end

-- TẠO CÁC SLIDER VÀO BÊN PHẢI (Không còn bị trống)
CreateSlider("Dash Speed", 0.1, 1, Config.DASH_SPEED, function(v) Config.DASH_SPEED = v end)
CreateSlider("Teleport Delay", 0, 10, Config.TELEPORT_DELAY, function(v) Config.TELEPORT_DELAY = v end)
CreateSlider("Distance", 1, 10, Config.DISTANCE_FROM_TARGET, function(v) Config.DISTANCE_FROM_TARGET = v end)
CreateSlider("Void Delay (s)", 5, 30, Config.VOID_DELAY, function(v) Config.VOID_DELAY = v end)

-- Nút bấm dưới cùng
local BtnRow = Instance.new("Frame")
BtnRow.Size = UDim2.new(1, 0, 0, 45)
BtnRow.Position = UDim2.new(0, 0, 1, -45)
BtnRow.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
BtnRow.BorderSizePixel = 0
BtnRow.Parent = Right
local RowLayout = Instance.new("UIListLayout", BtnRow)
RowLayout.FillDirection = Enum.FillDirection.Horizontal
RowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
RowLayout.Padding = UDim.new(0, 10)
Instance.new("UIPadding", BtnRow).PaddingLeft = UDim.new(0, 15)

local function CreateBtn(text, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 100, 0, 26)
    b.BackgroundColor3 = Color3.fromRGB(40, 40, 46)
    b.TextColor3 = color
    b.Text = text
    b.Font = Enum.Font.Code
    b.TextSize = 10
    b.Parent = BtnRow
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    return b
end

local DashToggle = CreateBtn("○ DASH: OFF", Color3.fromRGB(240, 128, 128))
local VoidToggle = CreateBtn("○ VOID: OFF", Color3.fromRGB(170, 170, 184))

-- Status Bar
local Statusbar = Instance.new("Frame")
Statusbar.Size = UDim2.new(1, 0, 0, 25)
Statusbar.Position = UDim2.new(0, 0, 1, -25)
Statusbar.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
Statusbar.BorderSizePixel = 0
Statusbar.Parent = Main
local SCorner = Instance.new("UICorner", Statusbar)
SCorner.CornerRadius = UDim.new(0, 6)

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 6, 0, 6)
StatusDot.Position = UDim2.new(0, 12, 0.5, -3)
StatusDot.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
StatusDot.BorderSizePixel = 0
StatusDot.Parent = Statusbar
Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -40, 1, 0)
StatusText.Position = UDim2.new(0, 25, 0, 0)
StatusText.Text = "hooked — knit.GojoService + lerp.dash"
StatusText.TextColor3 = Color3.fromRGB(85, 85, 85)
StatusText.TextSize = 9
StatusText.Font = Enum.Font.Code
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.BackgroundTransparency = 1
StatusText.Parent = Statusbar

-- ==========================================
-- LOGIC CHIẾN ĐẤU (GIỮ NGUYÊN)
-- ==========================================
DashToggle.MouseButton1Click:Connect(function()
    tpEnabled = not tpEnabled
    if tpEnabled then
        DashToggle.Text = "● DASH: ON"
        DashToggle.TextColor3 = Color3.fromRGB(125, 207, 128)
        GojoService.RE.Ultimate:FireServer()
        
        task.spawn(function()
            while tpEnabled and isRunning do
                GojoService.RE.RightActivated:FireServer()
                task.wait(0.01)
            end
        end)

        task.spawn(function()
            canTeleport = false
            task.wait(Config.TELEPORT_DELAY)
            if tpEnabled then canTeleport = true end
        end)

        task.spawn(function()
            if Config.AUTO_VOID then
                task.wait(Config.VOID_DELAY)
                if tpEnabled and isRunning then
                    local char = LocalPlayer.Character
                    local hum = char and char:FindFirstChild("Humanoid")
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if hum and root then
                        canTeleport = false
                        for i = 1, math.random(Config.TP_COUNT_MIN, Config.TP_COUNT_MAX) do
                            root.CFrame = CFrame.new(700, -100, 700)

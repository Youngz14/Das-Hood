	-- 🧩 Tải thư viện Linoria
	local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
	local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"))()
	local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua"))()

	-- 📦 Dịch vụ
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UIS = game:GetService("UserInputService")
	local localPlayer = Players.LocalPlayer
	local camera = workspace.CurrentCamera

	-- ⚙️ Biến chính
	local lockedTarget = nil
	local aimlockEnabled = false
	local fovRadius = 200
	local maxDistance = 200
	local smoothness = 0.1
	local showFOV = false
	local aimPart = "HumanoidRootPart" -- mặc định

	-- ⚡ Biến lưu aura
	local auraModel = nil
	local auraId = 101440596358217 -- ⚠️ thay bằng Asset ID của Aura bạn đã upload

	local fakePosEnabled = false
	local fakePosRadius = 200 -- bán kính chạy vòng quanh map
	local fakePosSpeed = 1 -- tốc độ xoay vòng
	local fakeMode = "Circle"
	local fakeAngle = 0

-- 📱 Mobile Auto-Lock
local mobileAutoLock = false
local lastAutoScan = 0
local autoScanInterval = 0.15 -- giãn cách scan
local mobileLockButtonEnabled = false
local mobileLockBtn

local function getClosestInFOV()
    local cam = camera
    local center = cam.ViewportSize / 2
    local bestPlr, bestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and hrp then
                local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                local dist3d = (hrp.Position - cam.CFrame.Position).Magnitude
                if onScreen and dist3d <= maxDistance then
                    local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if d <= fovRadius and d < bestDist then
                        bestDist, bestPlr = d, p
                    end
                end
            end
        end
    end
    return bestPlr
end

	-- 🌐 Fake Lag
	local fakeLagEnabled = false
	local fakeLagDelay = 0.3
	local fakeLagTimer = 0

	-- ⚡ Biến WalkSpeed
	local walkEnabled = false
	local walkValue = 16 -- mặc định Da Hood = 16
	-- Hàm cập nhật WalkSpeed
local function updateWalk()
    local char = localPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if walkEnabled then
        hum.WalkSpeed = walkValue
    else
        hum.WalkSpeed = 16 -- mặc định
    end
end

-- Theo dõi khi respawn
localPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    updateWalk()
    updateJump()
end)
	-- 🟢 Biến JumpPower
 	local jumpEnabled = false
 	local jumpValue = 50 -- mặc định
	 -- Hàm cập nhật Jump
local function updateJump()
    local char = localPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    -- Bypass anti JumpPower
    hum.UseJumpPower = false
    if jumpEnabled then
        hum.JumpHeight = jumpValue
    else
        hum.JumpHeight = 7.2 -- mặc định của Da Hood
    end
end

-- Gọi khi respawn
localPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    updateJump()
end)
	local orbitEnabled = false
	local orbitSpeed = 10
	local orbitRadius = 10
	local orbitTarget = nil
	local orbitAngle = 0

	local ghostEnabled = false
	local fakeClone = nil
	-- ESP Variables
	local espEnabled = false
	local espDistance = 1000
	local espTargetName = "All"
	local boxEnabled = false
	local highlightEnabled = false
	local tracerEnabled = false
	local skeletonEnabled = false

	local skeletonEnabled = false
	local infoEnabled = false

	-- ⚙️ Biến hitbox
	local hitboxEnabled = false
	local hitboxTransparency = 0.5
	local hitboxSize = 2 -- scale HRP (2 = gấp đôi)

	-- 🛠️ Update hitbox cho nhân vật
	local function updateHitboxForChar(char)
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			if hitboxEnabled then
				hrp.Size = Vector3.new(2, 2, 1) * hitboxSize
				hrp.Transparency = hitboxTransparency
				hrp.Material = Enum.Material.Neon
				hrp.Color = Color3.fromRGB(255, 0, 0)
				hrp.CanCollide = false
			else
				-- reset lại như mặc định
				hrp.Size = Vector3.new(2, 2, 1)
				hrp.Transparency = 0
				hrp.Material = Enum.Material.Plastic
			end
		end
	end

	-- 📱 Button mở menu cho Mobile
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "YoungzMobileMenu"
	ScreenGui.Parent = game:GetService("CoreGui")

	local MenuButton = Instance.new("ImageButton")
	MenuButton.Name = "MenuButton"
	MenuButton.Parent = ScreenGui
	MenuButton.Size = UDim2.new(0, 60, 0, 60) -- nút 60x60
	MenuButton.Position = UDim2.new(0.05, 0, 0.4, 0) -- mặc định ở bên trái
	MenuButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	MenuButton.ImageTransparency = 0.2
	MenuButton.BackgroundTransparency = 0.2
	MenuButton.Image = "rbxassetid://76302086268396" -- icon (bạn có thể đổi ID)

	-- UICorner bo tròn
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = MenuButton

	-- Kéo được
	local dragging = false
	local dragInput, dragStart, startPos

	MenuButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = MenuButton.Position
		end
	end)

	MenuButton.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement 
		or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	game:GetService("UserInputService").InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			MenuButton.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)

	game:GetService("UserInputService").InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	-- Khi bấm thì mở menu
	MenuButton.MouseButton1Click:Connect(function()
		Library:Toggle()
	end)
-- 📱 Hàm tạo nút Lock/Unlock duy nhất (kéo được + trang trí đẹp)
local function createMobileLockBtn()
    if not UIS.TouchEnabled then return end -- chỉ mobile
    if mobileLockBtn then return end

    mobileLockBtn = Instance.new("ImageButton")
    mobileLockBtn.Name = "MobileLockBtn"
    mobileLockBtn.Parent = ScreenGui
    mobileLockBtn.Size = UDim2.new(0, 70, 0, 70) -- to hơn chút
    mobileLockBtn.Position = UDim2.new(0.05, 0, 0.75, 0)
    mobileLockBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    mobileLockBtn.BackgroundTransparency = 0.2
    mobileLockBtn.ImageTransparency = 1

    -- Bo tròn
    local corner = Instance.new("UICorner", mobileLockBtn)
    corner.CornerRadius = UDim.new(0.5, 0)

    -- Viền
    local stroke = Instance.new("UIStroke", mobileLockBtn)
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(0, 170, 255)
    stroke.Transparency = 0.2

    -- Nền mờ
    local blurFrame = Instance.new("Frame", mobileLockBtn)
    blurFrame.Size = UDim2.new(1, 0, 1, 0)
    blurFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    blurFrame.BackgroundTransparency = 0.4
    blurFrame.BorderSizePixel = 0
    local blurCorner = Instance.new("UICorner", blurFrame)
    blurCorner.CornerRadius = UDim.new(0.5, 0)

    -- Text
    local text = Instance.new("TextLabel", mobileLockBtn)
    text.Name = "Label"
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = "LOCK"
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.TextColor3 = Color3.new(1, 1, 1)
    text.TextStrokeTransparency = 0.3

    -- Dragging logic
    local dragging, dragInput, dragStart, startPos
    mobileLockBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mobileLockBtn.Position
        end
    end)

    mobileLockBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mobileLockBtn.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Click event
    mobileLockBtn.MouseButton1Click:Connect(function()
        if not aimlockEnabled then
            Library:Notify("Aimlock chưa bật!")
            return
        end
        if lockedTarget then
            lockedTarget = nil
            text.Text = "LOCK"
            Library:Notify("Đã hủy khóa")
        else
            local t = getClosestInFOV()
            if t then
                lockedTarget = t
                text.Text = "UNLOCK"
                Library:Notify("Khóa: " .. t.Name)
            else
                Library:Notify("Không có mục tiêu trong FOV")
            end
        end
    end)
end

-- 📱 Hàm xóa nút
local function removeMobileLockBtn()
    if mobileLockBtn then
        mobileLockBtn:Destroy()
        mobileLockBtn = nil
    end
end

	local tracers = {}
	local boxes = {}

	local function createBox()
		local box = Drawing.new("Square")
		box.Thickness = 1 -- viền dày hơn 1.5
		box.Filled = false
		box.Color = Color3.fromRGB(255, 255, 255) -- màu trắng
		box.Transparency = 0.9 -- hơi trong suốt
		box.Visible = false
		box.ZIndex = 2 -- đảm bảo box nổi lên trên
		return box
	end


	-- Hàm tạo tracer
	local function createTracer()
		local line = Drawing.new("Line")
		line.Thickness = 1.5
		line.Transparency = 1
		line.Color = Color3.fromRGB(255, 255, 255)
		line.Visible = false
		return line
	end

	-- 🟢 Vẽ FOV Circle
	local circle = Drawing.new("Circle")
	circle.Color = Color3.new(1, 1, 1)
	circle.Thickness = 1.5
	circle.Transparency = 0.4
	circle.Filled = false
	circle.Radius = fovRadius
	circle.Visible = true

	-- 🧩 Hit Log Config
	local HitLogConfig = {
		Enabled = true,
		HitWindow = 0.75,
		PlayHitSound = true,
		HitSoundId = "rbxassetid://287062939",
		SoundCooldown = 0.08,
		SelfOnly = true,
		UseMouseRaycast = true,
		MouseRayDistance = 1000,
		CrosshairLockOnly = true,
		ScreenLockRadius = 60,
		CandidateTTL = 1.0,
		HoldRefreshRate = 0.10,
	}
--== State
local lastActionTick, lastActionSource, lastActionInfo = 0, "Unknown", ""
local lastCandidate = { plr = nil, t = 0 }
local lastSoundTick = 0
local lastHealth = {}
local m1Down, holdConn, lastHoldRefresh = false, nil, 0
local currentToolName = "LMB"

--== Sound
local function playHitSound()
    if not HitLogConfig.PlayHitSound then return end
    local now = tick()
    if now - lastSoundTick < HitLogConfig.SoundCooldown then return end
    lastSoundTick = now
    local s = Instance.new("Sound")
    s.SoundId = HitLogConfig.HitSoundId
    s.Volume = 0.7
    s.PlayOnRemove = true
    s.Parent = workspace
    s:Destroy()
end

--== Mark hành động
local function markAction(label, source)
    lastActionTick = tick()
    lastActionInfo = label or ""
    lastActionSource = source or "Unknown"
end

--== Helper: tên tool đang cầm (fallback LMB)
local function getActiveToolName()
    local char = localPlayer.Character
    if not char then return "LMB" end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        return "Tool:" .. tool.Name
    end
    return "LMB"
end

--== Candidate chọn khi bắn
local function getMouseRaycastCandidate()
    if not HitLogConfig.UseMouseRaycast then return nil end
    local cam = workspace.CurrentCamera
    local mouse = localPlayer:GetMouse()
    local origin = cam.CFrame.Position
    local dir = (mouse.Hit.Position - origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { localPlayer.Character }
    local result = workspace:Raycast(origin, dir.Unit * HitLogConfig.MouseRayDistance, params)
    if result and result.Instance then
        local model = result.Instance:FindFirstAncestorOfClass("Model")
        local hum = model and model:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            return Players:GetPlayerFromCharacter(model)
        end
    end
    return nil
end

local function getScreenCenterCandidate()
    local cam = workspace.CurrentCamera
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    local best, bestDist = nil, math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local pos, onScreen = cam:WorldToViewportPoint(p.Character.Head.Position)
                if onScreen then
                    local d = (Vector2.new(pos.X,pos.Y) - center).Magnitude
                    if d < bestDist then bestDist, best = d, p end
                end
            end
        end
    end
    if best and bestDist <= HitLogConfig.ScreenLockRadius then return best end
    return nil
end

local function snapshotCandidate()
    local plr = getMouseRaycastCandidate() or getScreenCenterCandidate()
    lastCandidate.plr, lastCandidate.t = plr, tick()
end

--== Health tracking
local function bindHumanoid(plr, hum)
    lastHealth[plr] = hum.Health
    hum.HealthChanged:Connect(function(new)
        if not HitLogConfig.Enabled then return end
        local prev = lastHealth[plr] or new
        lastHealth[plr] = new
        local now = tick()
        if new < prev and (now - lastActionTick) <= HitLogConfig.HitWindow then
            if HitLogConfig.SelfOnly and lastActionSource ~= "Self" then return end
            if HitLogConfig.CrosshairLockOnly then
                if lastCandidate.plr ~= plr then return end
                if now - (lastCandidate.t or 0) > HitLogConfig.CandidateTTL then return end
            end
            local dmg = math.floor(prev - new + 0.5)
            Library:Notify(("Hit %s  -%d HP [%s]"):format(plr.Name, dmg, lastActionInfo))
            playHitSound()
        end
    end)
end

-- Khi bắt đầu theo dõi / respawn:
local function hookChar(plr,char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        bindHumanoid(plr, hum)
    end
    char.ChildAdded:Connect(function(c)
        if c:IsA("Humanoid") then
            bindHumanoid(plr,c)
        end
    end)
end

-- Khi player rời game, dọn bảng:
Players.PlayerRemoving:Connect(function(p)
    lastHealth[p] = nil
    lastHitBySelf[p] = nil
end)

local function startTrack(plr)
    if plr == localPlayer then return end
    hookChar(plr, plr.Character)
    plr.CharacterAdded:Connect(function(char)
        hookChar(plr, char)
    end)
end

for _,p in ipairs(Players:GetPlayers()) do startTrack(p) end
Players.PlayerAdded:Connect(startTrack)

--== Đánh dấu self attack
local function markSelfAttack(label,resnap)
    -- ƯU TIÊN tên tool đang cầm tại thời điểm click
    local nameToUse = label or getActiveToolName()
    -- Nếu label là "LMB" nhưng đang cầm tool thì thay bằng tool
    if nameToUse == "LMB" then
        local active = getActiveToolName()
        if active ~= "LMB" then nameToUse = active end
    end
    -- Cập nhật currentToolName để đảm bảo log sau đó thống nhất
    currentToolName = nameToUse
    markAction(nameToUse, "Self")
    if resnap ~= false then snapshotCandidate() end
end

--== Tool tagging (ổn định qua Backpack/Character)
local function tagOneTool(t)
    if not t:IsA("Tool") or t:GetAttribute("Hit_Tagged") then return end
    t:SetAttribute("Hit_Tagged", true)

    -- Đồng bộ tên khi Equip/Unequip
    t.Equipped:Connect(function()
        currentToolName = "Tool:" .. t.Name
    end)
    t.Unequipped:Connect(function()
        currentToolName = "LMB"
    end)

    -- Khi tool thực sự Activated → chắc chắn gán Self attack với đúng tên tool
    t.Activated:Connect(function()
        if HitLogConfig.Enabled then
            markSelfAttack("Tool:" .. t.Name, true)
        end
    end)

    -- Phòng trường hợp Equip mà sự kiện kích hoạt chậm: theo dõi Parent để cập nhật nhanh
    t:GetPropertyChangedSignal("Parent"):Connect(function()
        local parent = t.Parent
        if parent and parent:IsDescendantOf(localPlayer.Character) then
            currentToolName = "Tool:" .. t.Name
        end
    end)
end

local function tagAllToolsOnContainer(container)
    if not container then return end
    for _,child in ipairs(container:GetChildren()) do
        if child:IsA("Tool") then
            tagOneTool(child)
        end
    end
    container.ChildAdded:Connect(function(c)
        if c:IsA("Tool") then
            tagOneTool(c)
        end
    end)
end

-- Gắn tag cho Tool của localPlayer cả ở Character và Backpack
local function wireLocalToolTracking(char)
    local backpack = localPlayer:FindFirstChildOfClass("Backpack") or localPlayer:WaitForChild("Backpack", 5)
    tagAllToolsOnContainer(char)
    tagAllToolsOnContainer(backpack)
end

if localPlayer.Character then wireLocalToolTracking(localPlayer.Character) end
localPlayer.CharacterAdded:Connect(function(c)
    wireLocalToolTracking(c)
end)

--== M1 hold refresh
UIS.InputBegan:Connect(function(inp,gp)
    if gp then return end
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        m1Down = true
        if HitLogConfig.Enabled then
            -- DÙNG tên tool đang cầm ngay tại thời điểm click (fix “chỉ hiện LMB”)
            markSelfAttack(getActiveToolName(), true)
            holdConn = RunService.RenderStepped:Connect(function()
                if not m1Down then return end
                local now = tick()
                if now - lastHoldRefresh >= HitLogConfig.HoldRefreshRate then
                    markAction(getActiveToolName(), "Self")
                    snapshotCandidate()
                    lastHoldRefresh = now
                end
            end)
        end
    end
end)

UIS.InputEnded:Connect(function(inp,gp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        m1Down = false
        if holdConn then holdConn:Disconnect() holdConn = nil end
    end
end)

	-- 🪟 Giao diện chính
	local Window = Library:CreateWindow({
		Title = "Youngz Project | Mystic ✨",
		Center = true,
		AutoShow = true,
		TabPadding = 8,
		MenuFadeTime = 0.2
	})

	-- 📁 Tabs
	local Tabs = {
		Main = Window:AddTab("Main"),
		Players = Window:AddTab("Players"),
		ESP = Window:AddTab("Visual"),
		Graphic = Window:AddTab("Graphics"),
		Config = Window:AddTab("Config")
	}

	-- 📦 Groupbox
	local MainBox = Tabs.Main:AddLeftGroupbox("Cài đặt Aimlock")
	local PlayerBox = Tabs.Players:AddLeftGroupbox("Chức năng người chơi")
	local ESPBox = Tabs.ESP:AddLeftGroupbox("Cài đặt ESP")
	local HitboxBox = Tabs.Main:AddRightGroupbox("Hitbox")
	local WalkJump = Tabs.Players:AddRightGroupbox("Tốc Độ Chạy & Nhảy Cao")
	local OrbitBox = Tabs.Main:AddRightGroupbox("Orbit")
	local GraphicBox = Tabs.Graphic:AddLeftGroupbox("Cài đặt Đồ Họa")
	-- ✅ Aimlock Toggle
	MainBox:AddToggle("AimlockToggle", {
		Text = "Bật Aimlock",
		Default = false,
		Callback = function(val)
			aimlockEnabled = val
			if not val then lockedTarget = nil end
		end
	})

	-- 👁️ Hiện FOV
	MainBox:AddToggle("ShowFOVToggle", {
		Text = "Hiện vòng FOV",
		Default = false,
		Callback = function(val)
			showFOV = val
			circle.Visible = val
		end
	})

	-- 🌀 Smoothness
	MainBox:AddSlider("SmoothnessSlider", {
		Text = "Smoothness",
		Min = 0.01,
		Max = 1,
		Default = 0.1,
		Rounding = 2,
		Callback = function(val)
			smoothness = val
		end
	})

	-- 📏 Max distance
	MainBox:AddSlider("DistanceSlider", {
		Text = "Max Distance",
		Min = 10,
		Max = 500,
		Default = 200,
		Rounding = 0,
		Callback = function(val)
			maxDistance = val
		end
	})

	-- 🎯 FOV Radius
	MainBox:AddSlider("FOVSlider", {
		Text = "FOV Radius",
		Min = 50,
		Max = 1000,
		Default = 200,
		Rounding = 0,
		Callback = function(val)
			fovRadius = val
			circle.Radius = val
		end
	})
	-- 🎯 Dropdown chọn Aim Part
	MainBox:AddDropdown("AimPartDropdown", {
		Values = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart", "LeftArm", "RightArm", "LeftLeg", "RightLeg"},
		Default = "HumanoidRootPart",
		Multi = false,
		Text = "Chọn phần cơ thể để Aim",
		Callback = function(val)
			aimPart = val
			Library:Notify("Aim vào: " .. val)
		end
	})

	-- ESP Settings
	ESPBox:AddToggle("ESPEnabled", {Text = "Bật ESP", Default = false, Callback = function(v) espEnabled = v end})
	ESPBox:AddToggle("InfoToggle", {Text = "Hiển thị tên và máu", Default = false, Callback = function(v) infoEnabled = v end})
	ESPBox:AddToggle("HighlightToggle", {Text = "Highlight viền trắng", Default = false, Callback = function(v) highlightEnabled = v end})
	ESPBox:AddToggle("TracerToggle", {Text = "ESP Tracer", Default = false, Callback = function(v) tracerEnabled = v end})
	ESPBox:AddToggle("BoxToggle", {
		Text = "ESP Box",
		Default = false,
		Callback = function(v)
			boxEnabled = v
		end
	})

	ESPBox:AddSlider("ESPDistance", {
		Text = "Khoảng cách ESP",
		Min = 100,
		Max = 5000,
		Default = 1000,
		Rounding = 0,
		Callback = function(val) espDistance = val end
	})

	ESPBox:AddDropdown("PlayerDropdown", {
		Values = {"All"},
		Default = "All",
		Multi = false,
		Text = "Chọn người ESP",
		Callback = function(val) espTargetName = val end
	})

	-- 🔤 Nhập tên mục tiêu
	MainBox:AddInput("TargetName", {
		Default = "",
		Text = "Tên mục tiêu",
		Placeholder = "Nhập chính xác tên",
		Callback = function(name)
			local target = Players:FindFirstChild(name)
			if target and target.Character then
				lockedTarget = target
				aimlockEnabled = true
				Library:Notify("Đã khóa: " .. target.Name)
			else
				Library:Notify("Không tìm thấy người chơi!")
			end
		end
	})

	-- 🕹️ Toggle Fly & TPWalk
	PlayerBox:AddToggle("FlyToggle", {
		Text = "Bật Fly",
		Default = false,
		Callback = function(v)
			flyEnabled = v
			if v then tpwalkEnabled = false end
		end
	})

	PlayerBox:AddSlider("FlySpeedSlider", {
		Text = "Fly Speed",
		Min = 10,
		Max = 3000,
		Default = 50,
		Rounding = 0,
		Callback = function(v) flySpeed = v end
	})

	PlayerBox:AddToggle("TPWalkToggle", {
		Text = "Bật TPWalk",
		Default = false,
		Callback = function(v)
			tpwalkEnabled = v
			if v then flyEnabled = false end
		end
	})

	PlayerBox:AddSlider("TPWalkSpeedSlider", {
		Text = "TPWalk Speed",
		Min = 10,
		Max = 300,
		Default = 50,
		Rounding = 0,
		Callback = function(v) tpwalkSpeed = v end
	})

	HitboxBox:AddToggle("HitboxToggle", {
		Text = "Bật Hitbox",
		Default = false,
		Callback = function(v)
			hitboxEnabled = v
			updateHitbox()
		end
	})

	HitboxBox:AddSlider("HitboxTransparency", {
		Text = "Độ mờ Hitbox",
		Min = 0,
		Max = 1,
		Default = 0.5,
		Rounding = 2,
		Callback = function(v)
			hitboxTransparency = v
			updateHitbox()
		end
	})

	HitboxBox:AddSlider("HitboxSize", {
		Text = "Kích thước Hitbox",
		Min = 1,
		Max = 100,
		Default = 1.5,
		Rounding = 1,
		Callback = function(v)
			hitboxSize = v
			updateHitbox()
		end
	})

	-- 👁️ ESP Text Info
	local function createBillboard(name)
		local bb = Instance.new("BillboardGui")
		bb.Name = "ESP_Info"
		bb.Size = UDim2.new(0, 200, 0, 50)
		bb.StudsOffset = Vector3.new(0, 6, 0)
		bb.AlwaysOnTop = true
		bb.Adornee = name
		bb.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

		local textLabel = Instance.new("TextLabel", bb)
		textLabel.Name = "Text"
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.TextColor3 = Color3.new(1, 1, 1)
		textLabel.TextStrokeTransparency = 0
		textLabel.TextScaled = true
		textLabel.Font = Enum.Font.SourceSansBold

		return bb
	end

	PlayerBox:AddToggle("FakePosToggle", {
		Text = "Bật FakePos",
		Default = false,
		Callback = function(v)
			fakePosEnabled = v
			if not v then
				-- Reset lại vị trí khi tắt
				local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					hrp.CFrame = CFrame.new(camera.CFrame.Position)
				end
			end
		end
	})

	PlayerBox:AddDropdown("FakeMode", {
		Values = {"Circle", "Hidden"},
		Default = "Circle",
		Multi = false,
		Text = "Chế độ Fake",
		Callback = function(v)
			fakeMode = v
		end
	})

	PlayerBox:AddSlider("FakeRadius", {
		Text = "Bán kính vòng",
		Min = 50,
		Max = 1000,
		Default = 200,
		Rounding = 0,
		Callback = function(v)
			fakePosRadius = v
		end
	})

	PlayerBox:AddSlider("FakeSpeed", {
		Text = "Tốc độ xoay",
		Min = 0.1,
		Max = 10,
		Default = 1,
		Rounding = 1,
		Callback = function(v)
			fakePosSpeed = v
		end
	})
	PlayerBox:AddToggle("GhostToggle", {
		Text = "Bật Ghost Mode (Xác giả)",
		Default = false,
		Callback = function(v)
			ghostEnabled = v
			local char = localPlayer.Character
			if not char then return end

			if v then
				-- Tạo xác giả
				fakeClone = char:Clone()
				fakeClone.Parent = workspace
				for _, part in ipairs(fakeClone:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Anchored = true -- đứng yên
						part.CanCollide = false
					elseif part:IsA("Humanoid") then
						part.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
					end
				end

				-- Đưa nhân vật thật xuống dưới map
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp then
					hrp.CFrame = hrp.CFrame + Vector3.new(0, -10000, 0)
				end

				Library:Notify("Ghost Mode: ON (xác giả tạo thành công)")

			else
				-- Xóa xác giả
				if fakeClone then
					fakeClone:Destroy()
					fakeClone = nil
				end

				-- Đưa nhân vật thật trở lại map
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp then
					hrp.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position + Vector3.new(0,5,0))
				end

				Library:Notify("Ghost Mode: OFF")
			end
		end
	})
	OrbitBox:AddToggle("OrbitToggle", {
		Text = "Bật Orbit quanh người chơi",
		Default = false,
		Callback = function(v)
			orbitEnabled = v
			if not v then
				orbitTarget = nil
			end
		end
	})

	OrbitBox:AddSlider("OrbitSpeed", {
		Text = "Tốc độ Orbit",
		Min = 1,
		Max = 100,
		Default = 10,
		Rounding = 0,
		Callback = function(v) orbitSpeed = v end
	})

	OrbitBox:AddSlider("OrbitRadius", {
		Text = "Bán kính Orbit",
		Min = 5,
		Max = 100,
		Default = 10,
		Rounding = 0,
		Callback = function(v) orbitRadius = v end
	})

	-- 🔤 Nhập tên người để Orbit
	OrbitBox:AddInput("OrbitTargetName", {
		Default = "",
		Text = "Tên player để Orbit",
		Placeholder = "Nhập chính xác tên",
		Callback = function(name)
			local target = Players:FindFirstChild(name)
			if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
				orbitTarget = target
				Library:Notify("Đã chọn Orbit: " .. target.Name)
			else
				Library:Notify("Không tìm thấy player này!")
			end
		end
	})
	PlayerBox:AddToggle("AuraToggle", {
		Text = "Bật Aura",
		Default = false,
		Callback = function(v)
			local char = localPlayer.Character
			if not char then return end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hrp then return end

			if v then
				if not auraModel then
					local ok, aura = pcall(function()
						return game:GetObjects("rbxassetid://" .. auraId)[1]
					end)

					if ok and aura then
						auraModel = aura

						-- 👇 Lấy Part chính của aura (nếu model thì lấy BasePart đầu tiên)
						local auraPart = auraModel:IsA("BasePart") and auraModel or auraModel:FindFirstChildWhichIsA("BasePart", true)
						if not auraPart then
							Library:Notify("⚠️ Aura không có BasePart!")
							return
						end

						-- Đặt Parent thẳng vào HRP
						auraPart.Parent = hrp
						auraPart.CFrame = hrp.CFrame

						-- 🔗 Weld vào HRP
						local weld = Instance.new("WeldConstraint")
						weld.Part0 = hrp
						weld.Part1 = auraPart
						weld.Parent = hrp

						auraPart.Anchored = false
						auraPart.CanCollide = false

						Library:Notify("Aura: ON")
					else
						Library:Notify("⚠️ Không load được Aura ID")
					end
				end
			else
				-- Xoá Aura
				if auraModel then
					auraModel:Destroy()
					auraModel = nil
					Library:Notify("Aura: OFF")
				end
			end
		end
	})
	-- 🛠️ Fix Lag Toggle
	GraphicBox:AddToggle("NoShadows", {
		Text = "Tắt Shadow",
		Default = false,
		Callback = function(v)
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
			game.Lighting.GlobalShadows = not v
		end
	})

	GraphicBox:AddToggle("NoDecals", {
		Text = "Xóa Decal/Texture",
		Default = false,
		Callback = function(v)
			if v then
				for _, obj in ipairs(workspace:GetDescendants()) do
					if obj:IsA("Decal") or obj:IsA("Texture") then
						obj.Transparency = 1
					end
				end
			else
				for _, obj in ipairs(workspace:GetDescendants()) do
					if obj:IsA("Decal") or obj:IsA("Texture") then
						obj.Transparency = 0
					end
				end
			end
		end
	})

	GraphicBox:AddToggle("NoEffects", {
		Text = "Tắt Post Effects (Bloom, SunRays, DOF)",
		Default = false,
		Callback = function(v)
			for _, eff in ipairs(game.Lighting:GetChildren()) do
				if eff:IsA("BloomEffect") or eff:IsA("DepthOfFieldEffect") or eff:IsA("SunRaysEffect") then
					eff.Enabled = not v
				end
			end
		end
	})
	GraphicBox:AddToggle("NoFog", {
		Text = "Xóa Sương Mù (Fog)",
		Default = false,
		Callback = function(v)
			if v then
				game.Lighting.FogEnd = 1e9
				game.Lighting.FogStart = 1e9
			else
				game.Lighting.FogEnd = 1000
				game.Lighting.FogStart = 0
			end
		end
	})
	-- ⚡ FPS Unlock
	GraphicBox:AddDropdown("FPSUnlock", {
		Values = {"60", "144", "240", "Unlimited"},
		Default = "60",
		Multi = false,
		Text = "Unlock FPS",
		Callback = function(v)
			if setfpscap then
				if v == "Unlimited" then
					setfpscap(10000)
					Library:Notify("FPS cap: Unlimited")
				else
					setfpscap(tonumber(v))
					Library:Notify("FPS cap: " .. v)
				end
			else
				Library:Notify("⚠️ Executor không hỗ trợ setfpscap!")
			end
		end
	})

	-- 🚀 FPS Booster (tối ưu mạnh)
	GraphicBox:AddToggle("FPSBoost", {
		Text = "Boost FPS (200+)",
		Default = false,
		Callback = function(v)
			if v then
				for _, obj in ipairs(workspace:GetDescendants()) do
					if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
						obj.Enabled = false
					elseif obj:IsA("MeshPart") then
						obj.TextureID = ""
					elseif obj:IsA("SpecialMesh") then
						obj.TextureId = ""
						obj.MeshId = ""
					elseif obj:IsA("Decal") or obj:IsA("Texture") then
						obj.Transparency = 1
					elseif obj:IsA("Sound") then
						obj.Playing = false
					end
				end
				game.Lighting.GlobalShadows = false
				game.Lighting.FogEnd = 1e9
				settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
				Library:Notify("🚀 FPS Boost: ON")
			else
				Library:Notify("🚀 FPS Boost: OFF (reload game để reset)")
			end
		end
	})
	PlayerBox:AddToggle("FakeLagToggle", {
		Text = "Fake Lag",
		Default = false,
		Callback = function(v)
			fakeLagEnabled = v
		end
	})

	PlayerBox:AddSlider("FakeLagDelay", {
		Text = "Độ trễ FakeLag",
		Min = 0.1,
		Max = 2,
		Default = 0.3,
		Rounding = 1,
		Callback = function(v) fakeLagDelay = v end
	})
	--== Toggle trong Linoria
	MainBox:AddToggle("HitLogToggle",{
		Text="Bật Hit Log",
		Default=true,
		Callback=function(v) HitLogConfig.Enabled=v end
	})
	-- 📌 Thêm vào Tab Players
WalkJump:AddToggle("JumpToggle", {
    Text = "Custom JumpPower",
    Default = false,
    Callback = function(v)
        jumpEnabled = v
        updateJump()
    end
})

WalkJump:AddSlider("JumpSlider", {
    Text = "JumpPower",
    Min = 10,
    Max = 1000,
    Default = 50,
    Rounding = 0,
    Callback = function(v)
        jumpValue = v
        if jumpEnabled then updateJump() end
    end
})
-- Thêm vào Tab Players
WalkJump:AddToggle("WalkToggle", {
    Text = "Custom WalkSpeed",
    Default = false,
    Callback = function(v)
        walkEnabled = v
        updateWalk()
    end
})

WalkJump:AddSlider("WalkSlider", {
    Text = "WalkSpeed",
    Min = 16,
    Max = 1000,
    Default = 50,
    Rounding = 0,
    Callback = function(v)
        walkValue = v
        if walkEnabled then updateWalk() end
    end
})

MainBox:AddToggle("MobileAutoLock", {
    Text = "Mobile Auto-Lock (Trong FOV)",
    Default = false,
    Callback = function(v)
        mobileAutoLock = v
        if v then aimlockEnabled = true end
    end
})

MainBox:AddToggle("MobileLockBtnToggle", {
    Text = "Hiện Mobile Lock Button",
    Default = false,
    Callback = function(v)
        mobileLockButtonEnabled = v
        if v then
            createMobileLockBtn()
        else
            removeMobileLockBtn()
        end
    end
})
RunService.Heartbeat:Connect(function(dt)
    if not aimlockEnabled or not mobileAutoLock then return end
    local now = tick()
    if now - lastAutoScan >= autoScanInterval then
        lastAutoScan = now

        -- Nếu đang khóa nhưng target chết/ra ngoài FOV → relock
        local needRelock = true
        if lockedTarget and lockedTarget.Character then
            local hum = lockedTarget.Character:FindFirstChildOfClass("Humanoid")
            local hrp = lockedTarget.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and hrp then
                local pos, on = camera:WorldToViewportPoint(hrp.Position)
                local d = (Vector2.new(pos.X, pos.Y) - camera.ViewportSize/2).Magnitude
                local dist3d = (hrp.Position - camera.CFrame.Position).Magnitude
                if on and d <= fovRadius and dist3d <= maxDistance then
                    needRelock = false
                end
            end
        end

        if needRelock then
            local t = getClosestInFOV()
            if t then
                lockedTarget = t
                -- Không spam notify cho đỡ rối
            end
        end
    end
end)

-- Bypass anti (update liên tục)
RunService.RenderStepped:Connect(function()
    if walkEnabled and localPlayer.Character then
        local hum = localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed ~= walkValue then
            hum.WalkSpeed = walkValue
        end
    end
    if jumpEnabled and localPlayer.Character then
        local hum = localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.UseJumpPower == true then
            hum.UseJumpPower = false
            hum.JumpHeight = jumpValue
        end
    end
end)

	RunService.Heartbeat:Connect(function(dt)
		if fakeLagEnabled and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
			fakeLagTimer = fakeLagTimer + dt
			if fakeLagTimer >= fakeLagDelay then
				fakeLagTimer = 0
				-- tạm "teleport" HRP để tạo hiệu ứng giật
				local hrp = localPlayer.Character.HumanoidRootPart
				hrp.CFrame = hrp.CFrame * CFrame.new(math.random(-2,2), 0, math.random(-2,2))
			end
		end
	end)
	-- 🔍 Aimlock Gần Nhất
	local function getClosestPlayer()
		local closest, shortest = nil, fovRadius
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local pos, onScreen = camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
				if onScreen then
					local dist = (Vector2.new(pos.X, pos.Y) - camera.ViewportSize / 2).Magnitude
					if dist < shortest then
						closest, shortest = player, dist
					end
				end
			end
		end
		return closest
	end

	-- Phím E chọn mục tiêu gần
	UIS.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.E and aimlockEnabled then
			if lockedTarget then
				lockedTarget = nil
				Library:Notify("Đã hủy khóa")
			else
				local t = getClosestPlayer()
				if t then
					lockedTarget = t
					Library:Notify("Khóa: " .. t.Name)
				else
					Library:Notify("Không tìm thấy mục tiêu!")
				end
			end
		end
	end)

	-- Phím K mở menu
	UIS.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.K then
			Library:Toggle()
		end
	end)
	-- Orbit chạy riêng
	RunService.RenderStepped:Connect(function(dt)
		if orbitEnabled and orbitTarget and orbitTarget.Character then
			local hrp = orbitTarget.Character:FindFirstChild("HumanoidRootPart")
			local myChar = localPlayer.Character
			if hrp and myChar and myChar:FindFirstChild("HumanoidRootPart") then
				local myRoot = myChar.HumanoidRootPart

				-- Góc tăng nhanh theo tốc độ orbit
				orbitAngle = orbitAngle + orbitSpeed * dt

				-- Tính toán vị trí quanh player
				local offset = Vector3.new(
					math.cos(orbitAngle) * orbitRadius,
					0,
					math.sin(orbitAngle) * orbitRadius
				)

				-- Đặt nhân vật bay quanh target
				myRoot.CFrame = CFrame.new(hrp.Position + offset, hrp.Position + Vector3.new(0, 2, 0))

				-- 📷 Cho camera theo dõi chính mình
				camera.CameraSubject = myRoot
				camera.CFrame = CFrame.new(camera.CFrame.Position, hrp.Position)
			end
		else
			-- ✅ Khi orbit tắt -> trả camera về mặc định
			if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
				camera.CameraSubject = localPlayer.Character.Humanoid
				camera.CameraType = Enum.CameraType.Custom
			end
		end
	end)

	-- 🛠️ Keybind bật/tắt Fly
	UIS.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.F then
			flyEnabled = not flyEnabled
			Library:Notify("Fly: " .. (flyEnabled and "ON" or "OFF"))
			if flyEnabled then tpwalkEnabled = false end
		end
	end)
-- 🎮 Chạy hiệu ứng
RunService.RenderStepped:Connect(function(dt)
	local char = localPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- Aimlock
	if aimlockEnabled and lockedTarget and lockedTarget.Character then
		local targetPart = lockedTarget.Character:FindFirstChild(aimPart)
		if targetPart then
			local dir = (targetPart.Position - camera.CFrame.Position).Unit
			local goal = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + dir)
			camera.CFrame = camera.CFrame:Lerp(goal, smoothness)
		end
	end

	-- ESP + Box + Tracer
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= localPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local hrp = plr.Character.HumanoidRootPart
			local head = plr.Character:FindFirstChild("Head")
			local hum = plr.Character:FindFirstChildOfClass("Humanoid")
			if not hrp or not head or not hum then continue end

			local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
			local dist = (hrp.Position - camera.CFrame.Position).Magnitude

			if espEnabled and onScreen and hum.Health > 0 and dist <= espDistance then
				-- Box
				if boxEnabled then
					if not boxes[plr] then
						boxes[plr] = createBox()
					end
					local box = boxes[plr]
					local headPos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
					local rootPos = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2.5, 0))
					local boxHeight = math.abs(headPos.Y - rootPos.Y)
					local boxWidth = boxHeight / 2
					box.Size = Vector2.new(boxWidth, boxHeight)
					box.Position = Vector2.new(headPos.X - boxWidth / 2, headPos.Y)
					box.Visible = true
				end

				-- Highlight
				if highlightEnabled then
					if not plr.Character:FindFirstChild("ESP_Highlight") then
						local hl = Instance.new("Highlight")
						hl.Name = "ESP_Highlight"
						hl.FillTransparency = 1
						hl.OutlineTransparency = 0
						hl.OutlineColor = Color3.fromRGB(255,255,255)
						hl.Adornee = plr.Character
						hl.Parent = plr.Character
					end
				elseif plr.Character:FindFirstChild("ESP_Highlight") then
					plr.Character.ESP_Highlight:Destroy()
				end

				-- Tracer
				if tracerEnabled then
					if not tracers[plr] then tracers[plr] = createTracer() end
					local line = tracers[plr]
					line.From = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y)
					line.To = Vector2.new(pos.X, pos.Y)
					line.Visible = true
				elseif tracers[plr] then
					tracers[plr].Visible = false
				end

				-- Info
				if infoEnabled then
					local gui = head:FindFirstChild("ESP_Info")
					if not gui then
						gui = createBillboard(head)
						gui.Parent = head
					end
					gui.Text.Text = string.format("HP: %d\n%s (%s)\nDist: %.1f",
						hum.Health, plr.DisplayName, plr.Name, dist)
				elseif head:FindFirstChild("ESP_Info") then
					head.ESP_Info:Destroy()
				end
			else
				-- Cleanup nếu ngoài tầm
				if boxes[plr] then boxes[plr].Visible = false end
				if tracers[plr] then tracers[plr].Visible = false end
			end
		end
	end

	-- FOV Circle
	circle.Visible = showFOV
	circle.Position = camera.ViewportSize/2

	-- Fly
	if flyEnabled then
		local move = Vector3.zero
		if UIS:IsKeyDown(Enum.KeyCode.W) then move += camera.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then move -= camera.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then move -= camera.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then move += camera.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then move += camera.CFrame.UpVector end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move -= camera.CFrame.UpVector end
		root.Velocity = move.Magnitude > 0 and move.Unit * flySpeed or Vector3.zero
	end

	-- TP Walk
	if tpwalkEnabled and UIS:IsKeyDown(Enum.KeyCode.W) then
		root.CFrame += camera.CFrame.LookVector * (tpwalkSpeed * dt)
	end
end)

-- Cleanup khi player thoát
local function clearESP(plr)
	if tracers[plr] then tracers[plr]:Remove(); tracers[plr] = nil end
	if boxes[plr] then boxes[plr]:Remove(); boxes[plr] = nil end
	if plr.Character then
		if plr.Character:FindFirstChild("ESP_Highlight") then
			plr.Character.ESP_Highlight:Destroy()
		end
		local head = plr.Character:FindFirstChild("Head")
		if head and head:FindFirstChild("ESP_Info") then
			head.ESP_Info:Destroy()
		end
	end
end

-- Gắn event 1 lần duy nhất
Players.PlayerAdded:Connect(function(plr)
	plr.CharacterRemoving:Connect(function() clearESP(plr) end)
end)
Players.PlayerRemoving:Connect(clearESP)
-- 🎮 RenderStepped cập nhật liên tục
RunService.RenderStepped:Connect(function()
    if hitboxEnabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= localPlayer and plr.Character then
                updateHitboxForChar(plr.Character)
            end
        end
    end
end)
	-- 🎨 Theme + Config
	ThemeManager:SetLibrary(Library)
	SaveManager:SetLibrary(Library)
	SaveManager:IgnoreThemeSettings()
	SaveManager:SetFolder("YoungzProject")
	SaveManager:BuildConfigSection(Tabs.Config)
	ThemeManager:ApplyToTab(Tabs.Config)
	Library:OnLoad()

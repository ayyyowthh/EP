--[[ 
   SCRIPT 4: CLIENT VISUALS (VIRAL EDITION)
   PDR 3: Premium HUD
   PDR 6: Confessional Camera
   PDR 7: Dynamic Camera
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local remotes = ReplicatedStorage:WaitForChild("ChooseADoorOrDie"):WaitForChild("Remotes")
local sounds = ReplicatedStorage:WaitForChild("ChooseADoorOrDie"):WaitForChild("Sounds")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- // HUD SETUP //
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "GameHUD"
gui.ResetOnSpawn = false 

-- Top Info
local topFrame = Instance.new("Frame", gui)
topFrame.Size = UDim2.new(0.4, 0, 0.1, 0)
topFrame.Position = UDim2.new(0.3, 0, 0, 0)
topFrame.BackgroundTransparency = 1

local stageTxt = Instance.new("TextLabel", topFrame)
stageTxt.Size = UDim2.new(1,0,0.6,0)
stageTxt.BackgroundTransparency = 1
stageTxt.Text = "WAITING..."
stageTxt.TextColor3 = Color3.new(1,1,1)
stageTxt.Font = Enum.Font.Bangers
stageTxt.TextScaled = true
stageTxt.TextStrokeTransparency = 0.5

local subTxt = Instance.new("TextLabel", topFrame)
subTxt.Size = UDim2.new(1,0,0.4,0)
subTxt.Position = UDim2.new(0,0,0.6,0)
subTxt.BackgroundTransparency = 1
subTxt.Text = ""
subTxt.TextColor3 = Color3.fromRGB(200,200,200)
subTxt.Font = Enum.Font.FredokaOne
subTxt.TextScaled = true
subTxt.TextStrokeTransparency = 0.5

-- Bottom Stats
local streakTxt = Instance.new("TextLabel", gui)
streakTxt.Size = UDim2.new(0.15,0,0.05,0)
streakTxt.Position = UDim2.new(0.02,0,0.92,0)
streakTxt.BackgroundTransparency = 1
streakTxt.Text = "STREAK: 0"
streakTxt.TextColor3 = Color3.fromRGB(85,255,127)
streakTxt.Font = Enum.Font.FredokaOne
streakTxt.TextScaled = true
streakTxt.TextStrokeTransparency = 0

-- Center Intro
local introFrame = Instance.new("Frame", gui)
introFrame.Size = UDim2.new(1,0,1,0)
introFrame.BackgroundTransparency = 1
introFrame.Visible = false
local introMain = Instance.new("TextLabel", introFrame)
introMain.Size = UDim2.new(1,0,0.2,0)
introMain.Position = UDim2.new(0,0,0.4,0)
introMain.BackgroundTransparency = 1
introMain.Text = "STAGE 1"
introMain.TextColor3 = Color3.fromRGB(255, 215, 0)
introMain.Font = Enum.Font.Bangers
introMain.TextScaled = true

-- Camera Overlay (For Death)
local overlay = Instance.new("Frame", gui)
overlay.Size = UDim2.new(1,0,1,0)
overlay.BackgroundColor3 = Color3.new(0,0,0)
overlay.BackgroundTransparency = 1
overlay.Visible = false
local deathWords = Instance.new("TextLabel", overlay)
deathWords.Size = UDim2.new(1,0,0.2,0)
deathWords.Position = UDim2.new(0,0,0.7,0)
deathWords.BackgroundTransparency = 1
deathWords.Text = "UNLUCKY."
deathWords.TextColor3 = Color3.new(1,0,0)
deathWords.Font = Enum.Font.IndieFlower
deathWords.TextScaled = true

-- STATE
local ClientState = {
	Mode = "Normal", -- Normal, Locked, DeathConfession, Intro
	Target = nil,
	Shake = 0,
	ArmingGui = nil
}

-- FUNCTIONS
local function PlaySnd(name)
	local s = sounds:FindFirstChild(name)
	if s then s:Clone().Parent = gui; s:Play() end
end

local function ForceReset()
	ClientState.Mode = "Normal"
	ClientState.Target = nil
	ClientState.Shake = 0
	camera.CameraType = Enum.CameraType.Custom
	overlay.Visible = false
	overlay.BackgroundTransparency = 1
	if ClientState.ArmingGui then ClientState.ArmingGui:Destroy() end
end

player.CharacterAdded:Connect(function(c)
	ForceReset()
	c:WaitForChild("Humanoid").Died:Connect(ForceReset)
	streakTxt.Text = "STREAK: " .. (player:GetAttribute("Streak") or 0)
end)

-- RENDER LOOP
RunService.RenderStepped:Connect(function(dt)
	local char = player.Character
	if not char or not char:FindFirstChild("Head") then return end
	local root = char.HumanoidRootPart
	local head = char.Head

	-- Shake Decay
	local shake = CFrame.new()
	if ClientState.Shake > 0 then
		shake = CFrame.new(math.random()-.5, math.random()-.5, 0) * ClientState.Shake
		ClientState.Shake = math.max(0, ClientState.Shake - dt)
	end

	-- CAMERA MODES
	if ClientState.Mode == "DeathConfession" then
		camera.CameraType = Enum.CameraType.Scriptable
		-- Confessional Shot: In front of face, looking at face
		local camPos = head.Position + (head.CFrame.LookVector * 5) + Vector3.new(0, 0.5, 0)
		camera.CFrame = CFrame.new(camPos, head.Position) * shake

	elseif ClientState.Mode == "Locked" and ClientState.Target then
		camera.CameraType = Enum.CameraType.Scriptable
		local doorPos = ClientState.Target.PrimaryPart.Position
		local camPos = root.Position + Vector3.new(0, 5, 12)
		camera.CFrame = camera.CFrame:Lerp(CFrame.new(camPos, doorPos), dt*5) * shake

	elseif ClientState.Mode == "Intro" then
		camera.CameraType = Enum.CameraType.Scriptable
		-- Sweep logic handled by tween or simple pan
		camera.CFrame = camera.CFrame * CFrame.new(dt*2, 0, 0)

	else
		camera.CameraType = Enum.CameraType.Custom
		if ClientState.Shake > 0 then camera.CFrame = camera.CFrame * shake end
	end
end)

-- // EVENT HANDLERS //

remotes.CameraEvent.OnClientEvent:Connect(function(action, data)
	if action == "Sweep" then
		-- Simple intro sweep
		ClientState.Mode = "Intro"
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.new(0, 20, 60, 0,0,0) -- Center view

	elseif action == "Focus" then
		-- Nudge camera to reveal door
		if ClientState.Mode == "Normal" and data and data.PrimaryPart then
			local tw = TweenService:Create(camera, TweenInfo.new(0.3), {CFrame = CFrame.new(camera.CFrame.Position, data.PrimaryPart.Position)})
			tw:Play()
		end
	end
end)

remotes.DeathEvent.OnClientEvent:Connect(function(style, door, isConfessional)
	if isConfessional then
		ClientState.Mode = "DeathConfession"
		ClientState.Shake = 0.2
		overlay.Visible = true

		-- Random Death Text
		local lines = {"UNLUCKY", "WHY??", "I KNEW IT", "GOODBYE", "RIP STREAK"}
		deathWords.Text = lines[math.random(1, #lines)]

		TweenService:Create(overlay, TweenInfo.new(0.5), {BackgroundTransparency = 0.2}):Play()
		wait(1.5)
		if style == "Blast" then ClientState.Shake = 2.0; PlaySnd("Shatter")
		elseif style == "Trapdoor" then ClientState.Shake = 0.5; PlaySnd("RevealBad") end
	end
end)

remotes.ArmingEvent.OnClientEvent:Connect(function(action, door, duration)
	if action == "Start" then
		PlaySnd("Tick")
		if ClientState.ArmingGui then ClientState.ArmingGui:Destroy() end

		local bg = Instance.new("BillboardGui")
		bg.Size = UDim2.new(0,200,0,40)
		bg.StudsOffset = Vector3.new(0,9,0)
		bg.AlwaysOnTop = true
		local fill = Instance.new("Frame", bg)
		fill.Size = UDim2.new(0,0,1,0)
		fill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)

		bg.Parent = door.PrimaryPart
		ClientState.ArmingGui = bg

		TweenService:Create(fill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(1,0,1,0)}):Play()

	elseif action == "Cancel" then
		if ClientState.ArmingGui then ClientState.ArmingGui:Destroy(); ClientState.ArmingGui = nil end
	end
end)

remotes.StageIntroEvent.OnClientEvent:Connect(function(stage, doors, safe, twist)
	stageTxt.Text = "STAGE " .. stage
	subTxt.Text = "TWIST: " .. twist

	introFrame.Visible = true
	introMain.Text = "STAGE " .. stage .. "\n" .. twist
	introMain.TextTransparency = 1
	TweenService:Create(introMain, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
	wait(2.5)
	TweenService:Create(introMain, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
	wait(0.5)
	introFrame.Visible = false
	ClientState.Mode = "Normal"
end)

remotes.RevealEvent.OnClientEvent:Connect(function(door, type)
	if not door or not door.PrimaryPart then return end
	local color = Color3.new(1,1,1)
	local txt = ""

	if type == "Safe" then 
		color = Color3.fromRGB(85,255,127); txt = "✔ SAFE"; PlaySnd("RevealSafe")
	else 
		color = Color3.fromRGB(255,85,85); txt = "☠️ WRONG"; PlaySnd("RevealBad")
	end

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0,200,0,100)
	bb.StudsOffset = Vector3.new(0,6,0)
	bb.AlwaysOnTop = true
	local t = Instance.new("TextLabel", bb)
	t.Size = UDim2.new(1,0,1,0)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.Bangers
	t.Text = txt
	t.TextColor3 = color
	t.TextScaled = true
	t.TextStrokeTransparency = 0

	bb.Parent = door.PrimaryPart
	TweenService:Create(bb, TweenInfo.new(0.5, Enum.EasingStyle.Back), {StudsOffset = Vector3.new(0,10,0)}):Play()
	Debris:AddItem(bb, 3)
end)

remotes.CrowdEvent.OnClientEvent:Connect(function(door, active)
	if active and door then
		local hl = door:FindFirstChild("BaitGlow") or Instance.new("Highlight")
		hl.Name = "BaitGlow"
		hl.FillColor = Color3.fromRGB(150, 0, 255)
		hl.Parent = door
	elseif door and door:FindFirstChild("BaitGlow") then
		door.BaitGlow:Destroy()
	end
end)

remotes.LockInEvent.OnClientEvent:Connect(function(door)
	if ClientState.ArmingGui then ClientState.ArmingGui:Destroy() end
	ClientState.Mode = "Locked"
	ClientState.Target = door
	PlaySnd("Lock")
end)

remotes.WinnerEvent.OnClientEvent:Connect(function(winner)
	stageTxt.Text = "WINNER!"
	subTxt.Text = winner.Name
	PlaySnd("WinCheer")
end)

remotes.TimerEvent.OnClientEvent:Connect(function(t)
	if t <= 3 and t > 0 then 
		stageTxt.TextColor3 = Color3.new(1,0,0)
		ClientState.Shake = 0.3
	else 
		stageTxt.TextColor3 = Color3.new(1,1,1)
	end
end)

--[[ 
   SCRIPT 1: BOOTSTRAP / ENVIRONMENT
   EDITION: Viral Game Show
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local function createFolder(name, parent)
	if not parent:FindFirstChild(name) then
		local f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
		return f
	end
	return parent[name]
end

local function createPart(name, parent, size, pos, color, anchor, mat)
	local p = parent:FindFirstChild(name) or Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.BrickColor = BrickColor.new(color)
	p.Anchored = anchor
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

-- 1. FOLDER STRUCTURE
local rsFolder = createFolder("ChooseADoorOrDie", ReplicatedStorage)
local remotes = createFolder("Remotes", rsFolder)
local ssFolder = createFolder("ChooseADoorOrDie", ServerStorage)

-- NEW REMOTES
local remoteNames = {
	"StatusEvent", "TimerEvent", "RevealEvent", 
	"DeathEvent", "LockInEvent", "StageIntroEvent",
	"SocialEvent", "ArmingEvent", "CrowdEvent", 
	"WinnerEvent", "CameraEvent" -- New Camera Control
}

for _, n in pairs(remoteNames) do
	if not remotes:FindFirstChild(n) then
		local r = Instance.new("RemoteEvent")
		r.Name = n
		r.Parent = remotes
	end
end

-- 2. SOUND LIBRARY (Created on Server, played on Client/Server)
local soundFolder = createFolder("Sounds", rsFolder)
local sounds = {
	{Name = "Tick", Id = "rbxassetid://461227511", Vol = 0.5},
	{Name = "Lock", Id = "rbxassetid://2865228021", Vol = 1.5}, -- Heavy Clunk
	{Name = "RevealSafe", Id = "rbxassetid://1096630750", Vol = 1},
	{Name = "RevealBad", Id = "rbxassetid://4590662766", Vol = 1},
	{Name = "Shatter", Id = "rbxassetid://4909776948", Vol = 1},
	{Name = "WinCheer", Id = "rbxassetid://4829676997", Vol = 0.8}
}

for _, s in pairs(sounds) do
	if not soundFolder:FindFirstChild(s.Name) then
		local snd = Instance.new("Sound")
		snd.Name = s.Name
		snd.SoundId = s.Id
		snd.Volume = s.Vol
		snd.Parent = soundFolder
	end
end

-- 3. WORLD BUILDER
local world = createFolder("CADOD_World", Workspace)

-- Lobby
local lobby = createFolder("Lobby", world)
createPart("LobbyPlatform", lobby, Vector3.new(100, 2, 100), Vector3.new(0, 500, 0), "Bright blue", true)

-- Arena
local arena = createFolder("Arena", world)
createPart("ArenaFloor", arena, Vector3.new(160, 4, 100), Vector3.new(0, 0, 0), "Dark stone grey", true, Enum.Material.Concrete)
createFolder("Doors", arena) 

-- Spectator
local spec = createPart("SpectatorPlatform", arena, Vector3.new(160, 1, 40), Vector3.new(0, 30, -70), "Glass", true, Enum.Material.Glass)
spec.Transparency = 0.5

-- The Void
local void = createPart("TheVoid", arena, Vector3.new(800, 1, 800), Vector3.new(0, -200, 0), "Really black", true, Enum.Material.Neon)
void.Transparency = 1
void.CanCollide = false
local light = Instance.new("PointLight", void)
light.Range = 300
light.Color = Color3.fromRGB(150, 0, 0)
light.Brightness = 4

-- 4. TEMPLATE DOOR (With Twist/Crowd FX Parts)
if not rsFolder:FindFirstChild("TemplateDoor") then
	local doorModel = Instance.new("Model")
	doorModel.Name = "TemplateDoor"

	-- Frame
	local frame = Instance.new("Part")
	frame.Name = "Frame"
	frame.Size = Vector3.new(10, 16, 1)
	frame.Position = Vector3.new(0, 8, 0)
	frame.Color = Color3.fromRGB(20, 20, 20)
	frame.Anchored = true
	frame.Parent = doorModel

	-- Door Visual
	local d = Instance.new("Part")
	d.Name = "DoorPart"
	d.Size = Vector3.new(8, 14, 1)
	d.Position = Vector3.new(0, 7, 0)
	d.Color = Color3.fromRGB(120, 120, 120)
	d.Anchored = true
	d.CanCollide = false 
	d.Parent = doorModel

	-- Fake Sparkles (For Mindgames)
	local particle = Instance.new("ParticleEmitter")
	particle.Name = "Sparkles"
	particle.Texture = "rbxassetid://243098098" 
	particle.Color = ColorSequence.new(Color3.fromRGB(255, 255, 100))
	particle.Enabled = false 
	particle.Parent = d

	-- Trigger Zone
	local trig = Instance.new("Part")
	trig.Name = "Trigger"
	trig.Size = Vector3.new(10, 3, 10) 
	trig.Position = Vector3.new(0, 1.5, 6) 
	trig.Transparency = 1
	trig.CanCollide = false
	trig.Anchored = true
	trig.Parent = doorModel

	-- Sign
	local sg = Instance.new("SurfaceGui", frame)
	sg.Face = Enum.NormalId.Front
	local txt = Instance.new("TextLabel", sg)
	txt.Size = UDim2.new(1,0,0.15,0)
	txt.Text = "?"
	txt.TextScaled = true
	txt.BackgroundTransparency = 1

	doorModel.PrimaryPart = frame
	doorModel.Parent = rsFolder
end

print("✅ Game Show Environment Ready.")

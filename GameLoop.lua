--[[ 
   SCRIPT 3: SERVER DIRECTOR (VIRAL EDITION)
   PDR 1: Phase System
   PDR 6: Confessional Death Cam
   PDR 5: Functional Twists
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local DoorGen = require(game.ServerScriptService.DoorGenerator)
local remotes = ReplicatedStorage.ChooseADoorOrDie.Remotes

local world = Workspace.CADOD_World
local lobbySpawn = world.Lobby.LobbyPlatform.Position + Vector3.new(0, 5, 0)
local arenaSpawn = world.Arena.ArenaFloor.Position + Vector3.new(0, 5, 40)
local spectatorSpawn = world.Arena.SpectatorPlatform.Position + Vector3.new(0, 5, 0)

-- GAME STATE
local Phase = "LOBBY" -- LOBBY, INTRO, PICK, LOCK, SILENCE, REVEAL, RESET
local gameState = {
	Stage = 1, 
	Survivors = {}, 
	Mode = "Classic", 
	Twist = "None",
	PlayerChoices = {}, 
	ArmingStatus = {} 
}

-- CONFIG
local ARM_TIME = 1.2
local TRIGGER_DIST = 8
local TWISTS = {"LAST SECOND SHUFFLE", "GHOST HINTS", "DOUBLE SAFE", "SPEED RUN", "NONE"}

-- // HELPER: CONFESSIONAL DEATH //
local function ExecuteConfessionalDeath(victim, style, door)
	if not victim.Character then return end

	-- 1. Freeze
	local hum = victim.Character:FindFirstChild("Humanoid")
	local root = victim.Character:FindFirstChild("HumanoidRootPart")
	if hum then hum.WalkSpeed = 0 end
	if root then root.Anchored = true end

	-- 2. Trigger Client Cam
	remotes.DeathEvent:FireClient(victim, style, door, true) -- true = isConfessional

	-- 3. Pause for Drama
	wait(1.5)

	-- 4. Physics Execution
	if root then root.Anchored = false end

	if style == "Trapdoor" then
		local trap = door:FindFirstChild("TrapdoorPart")
		if trap then trap.CanCollide = false; trap.Transparency = 1 end
	elseif style == "Blast" then
		if root then
			local bp = Instance.new("BodyVelocity", root)
			bp.Velocity = Vector3.new(math.random(-20,20), 80, 100)
			bp.MaxForce = Vector3.new(1e5, 1e5, 1e5)
			game.Debris:AddItem(bp, 0.5)
		end
	end

	wait(2.0) -- Fall time

	-- 5. Kill & Spectate
	if victim.Character then 
		victim.Character:BreakJoints()
		wait(0.1)
		victim:LoadCharacter()
		delay(0.2, function()
			if victim.Character then victim.Character:PivotTo(CFrame.new(spectatorSpawn)) end
		end)
	end
end

-- // HEARTBEAT: ARMING & CROWD (Throttled) //
local lastCrowdUpdate = 0
RunService.Heartbeat:Connect(function()
	if Phase ~= "PICK" then return end -- GATED

	local now = os.clock()
	local doors = world.Arena.Doors:GetChildren()
	local doorCounts = {} 

	-- Arming Logic
	for _, p in pairs(gameState.Survivors) do
		if gameState.PlayerChoices[p] or not p.Character then continue end

		local root = p.Character:FindFirstChild("HumanoidRootPart")
		if not root then continue end

		local foundDoor = nil
		for _, door in pairs(doors) do
			local trig = door:FindFirstChild("Trigger")
			if trig and (root.Position - trig.Position).Magnitude < TRIGGER_DIST then
				foundDoor = door
				doorCounts[door] = (doorCounts[door] or 0) + 1
				break
			end
		end

		local currentArm = gameState.ArmingStatus[p]
		if foundDoor then
			if not currentArm or currentArm.Door ~= foundDoor then
				gameState.ArmingStatus[p] = {Door = foundDoor, StartTime = now}
				remotes.ArmingEvent:FireClient(p, "Start", foundDoor, ARM_TIME)
			else
				if now - currentArm.StartTime >= ARM_TIME then
					gameState.PlayerChoices[p] = foundDoor
					gameState.ArmingStatus[p] = nil 
					root.Anchored = true
					root.CFrame = CFrame.new(foundDoor.TrapdoorPart.Position + Vector3.new(0,3,0), foundDoor.PrimaryPart.Position)
					remotes.LockInEvent:FireClient(p, foundDoor)
				end
			end
		else
			if currentArm then
				gameState.ArmingStatus[p] = nil
				remotes.ArmingEvent:FireClient(p, "Cancel")
			end
		end
	end

	-- Crowd Update (Throttled to 4Hz)
	if now - lastCrowdUpdate > 0.25 then
		lastCrowdUpdate = now
		local total = #gameState.Survivors
		if total >= 3 then
			for door, count in pairs(doorCounts) do
				remotes.CrowdEvent:FireAllClients(door, count >= (total * 0.5))
			end
		end
	end
end)

-- // MAIN GAME LOOP //
while true do
	Phase = "LOBBY"
	gameState.Stage = 1
	gameState.Survivors = {}
	gameState.PlayerChoices = {}

	local r = math.random()
	if r < 0.5 then gameState.Mode = "Classic" else gameState.Mode = "Chaos" end
	gameState.Twist = TWISTS[math.random(1, #TWISTS)]

	DoorGen.ClearDoors()

	repeat 
		remotes.StatusEvent:FireAllClients("Waiting for players...")
		wait(1) 
	until #Players:GetPlayers() >= 1

	-- START GAME
	for _, p in pairs(Players:GetPlayers()) do
		table.insert(gameState.Survivors, p)
		p:SetAttribute("Status", "Alive")
		if p.Character then p.Character:PivotTo(CFrame.new(arenaSpawn)) end
	end

	local gameRunning = true
	while gameRunning do
		if #gameState.Survivors == 0 then break end
		if #gameState.Survivors == 1 and gameState.Stage > 3 then
			Phase = "WINNER"
			remotes.WinnerEvent:FireAllClients(gameState.Survivors[1])
			wait(8)
			break
		end

		Phase = "INTRO"
		local doors, safeCount = DoorGen.SpawnDoors(gameState.Stage, gameState.Mode, gameState.Twist)
		remotes.StageIntroEvent:FireAllClients(gameState.Stage, #doors, safeCount, gameState.Twist)
		-- Camera Sweep
		remotes.CameraEvent:FireAllClients("Sweep", world.Arena.Doors)
		wait(3.5) 

		Phase = "PICK"
		gameState.PlayerChoices = {}
		gameState.ArmingStatus = {}

		-- Unfreeze
		for _, p in pairs(gameState.Survivors) do
			if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				p.Character.HumanoidRootPart.Anchored = false
			end
		end

		-- TIMER
		local timeLimit = (gameState.Twist == "SPEED RUN") and 8 or 12
		for i = timeLimit, 0, -1 do
			remotes.TimerEvent:FireAllClients(i)

			-- Twist: Shuffle
			if i == 2 and gameState.Twist == "LAST SECOND SHUFFLE" then
				remotes.StatusEvent:FireAllClients("SHUFFLE!")
				DoorGen.ShufflePositions()
				wait(0.5)
			end

			local locked = 0
			for _, _ in pairs(gameState.PlayerChoices) do locked = locked + 1 end
			remotes.SocialEvent:FireAllClients(#gameState.Survivors - locked)
			wait(1)
		end

		Phase = "LOCK"
		-- Auto Assign
		local doorList = world.Arena.Doors:GetChildren()
		for _, p in pairs(gameState.Survivors) do
			if not gameState.PlayerChoices[p] then
				local rnd = doorList[math.random(1, #doorList)]
				gameState.PlayerChoices[p] = rnd
				if p.Character then
					p.Character:PivotTo(CFrame.new(rnd.TrapdoorPart.Position + Vector3.new(0,3,0)))
					p.Character.HumanoidRootPart.Anchored = true
				end
				remotes.LockInEvent:FireClient(p, rnd)
			end
		end

		remotes.SocialEvent:FireAllClients(0)
		remotes.CrowdEvent:FireAllClients(nil, false)

		Phase = "SILENCE"
		remotes.StatusEvent:FireAllClients("...")
		wait(1.2) 

		Phase = "REVEAL"
		-- Sort by crowd size
		table.sort(doorList, function(a, b)
			local cA, cB = 0, 0
			for _, ch in pairs(gameState.PlayerChoices) do
				if ch == a then cA = cA + 1 end
				if ch == b then cB = cB + 1 end
			end
			return cA < cB -- Smallest first
		end)

		local nextSurvivors = {}
		for _, door in pairs(doorList) do
			local type = door:GetAttribute("Type")
			remotes.RevealEvent:FireAllClients(door, type) 

			-- Focus Camera
			remotes.CameraEvent:FireAllClients("Focus", door)
			wait(0.7) 

			local victims = {}
			for p, choice in pairs(gameState.PlayerChoices) do
				if choice == door and table.find(gameState.Survivors, p) then
					if type == "Safe" then
						table.insert(nextSurvivors, p)
						p:SetAttribute("Streak", (p:GetAttribute("Streak") or 0) + 1)
					else
						table.insert(victims, p)
					end
				end
			end

			if #victims > 0 then
				-- Execute Confessional Death
				local style = (type == "Blast") and "Blast" or (type == "Freeze" and "Freeze" or "Trapdoor")
				for _, v in pairs(victims) do
					spawn(function() ExecuteConfessionalDeath(v, style, door) end)
				end
				wait(2.5) -- Wait for death animation
				remotes.StatusEvent:FireAllClients(tostring(#victims) .. " DIED")
			end
			wait(0.3)
		end

		gameState.Survivors = nextSurvivors
		gameState.Stage = gameState.Stage + 1
		wait(2)
	end

	Phase = "RESET"
	remotes.StatusEvent:FireAllClients("ROUND OVER")
	wait(3)
	DoorGen.ClearDoors()
	for _, p in pairs(Players:GetPlayers()) do
		if p.Character then 
			p.Character.HumanoidRootPart.Anchored = false
			p.Character:PivotTo(CFrame.new(lobbySpawn + Vector3.new(0,5,0))) 
		end
	end
	wait(2)
end

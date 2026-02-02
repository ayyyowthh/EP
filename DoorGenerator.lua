--[[ 
   SCRIPT 2: DOOR GENERATOR
   EDITION: Shuffle Ready
]]

local DoorGenerator = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local rsFolder = ReplicatedStorage:WaitForChild("ChooseADoorOrDie")
local template = rsFolder:WaitForChild("TemplateDoor")
local arenaDoors = Workspace.CADOD_World.Arena.Doors

local DOOR_SPACING = 18

function DoorGenerator.ClearDoors()
	arenaDoors:ClearAllChildren()
end

function DoorGenerator.ShufflePositions()
	-- Twist: Physically swap door positions
	local doors = arenaDoors:GetChildren()
	local positions = {}

	for _, d in pairs(doors) do
		if d.PrimaryPart then table.insert(positions, d.PrimaryPart.CFrame) end
	end

	-- Scramble positions list
	for i = #positions, 2, -1 do
		local j = math.random(i)
		positions[i], positions[j] = positions[j], positions[i]
	end

	-- Apply new positions
	for i, d in pairs(doors) do
		if d.PrimaryPart and positions[i] then
			d:PivotTo(positions[i])
		end
	end
end

function DoorGenerator.SpawnDoors(stage, gameMode, twist)
	DoorGenerator.ClearDoors()

	local doorCount = math.clamp(stage + 2, 3, 6)
	local outcomes = {}

	-- Safe Count Logic
	local safeCount = 1
	if gameMode == "Mercy" or twist == "DOUBLE SAFE" then safeCount = 2 end

	for i = 1, safeCount do table.insert(outcomes, "Safe") end

	while #outcomes < doorCount do
		if gameMode == "Chaos" then
			table.insert(outcomes, math.random() > 0.5 and "Blast" or "Trapdoor")
		elseif stage >= 5 then
			table.insert(outcomes, math.random() > 0.8 and "Freeze" or "Trapdoor")
		else
			table.insert(outcomes, "Trapdoor")
		end
	end

	-- Shuffle Outcomes
	for i = #outcomes, 2, -1 do
		local j = math.random(i)
		outcomes[i], outcomes[j] = outcomes[j], outcomes[i]
	end

	local startX = -(( (doorCount - 1) * DOOR_SPACING ) / 2)
	local generated = {}

	for i = 1, doorCount do
		local newDoor = template:Clone()
		newDoor.Name = "Door_" .. i
		local xPos = startX + ((i-1) * DOOR_SPACING)
		newDoor:PivotTo(CFrame.new(xPos, 8, -25)) 

		-- Trapdoor Floor
		local trap = Instance.new("Part")
		trap.Name = "TrapdoorPart"
		trap.Size = Vector3.new(10, 1, 10)
		trap.Position = Vector3.new(xPos, 2.5, -25 + 6) 
		trap.Anchored = true
		trap.Color = Color3.fromRGB(50, 50, 50)
		trap.Material = Enum.Material.DiamondPlate
		trap.Parent = newDoor

		newDoor:SetAttribute("Type", outcomes[i])
		newDoor:SetAttribute("Index", i)

		-- Fake Hints (Ghost Twist)
		if twist == "GHOST HINTS" or math.random() > 0.7 then
			if newDoor.DoorPart:FindFirstChild("Sparkles") then
				newDoor.DoorPart.Sparkles.Enabled = true
			end
		end

		local label = newDoor:FindFirstChildWhichIsA("TextLabel", true)
		if label then label.Text = tostring(i) end

		newDoor.Parent = arenaDoors
		table.insert(generated, newDoor)
	end

	return generated, safeCount 
end

return DoorGenerator

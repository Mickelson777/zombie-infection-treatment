local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local zombieAgent = ReplicatedStorage:WaitForChild("ZombieAgent")

local human = script.Parent

local AI = require(ServerStorage.HumanAI).new(human)
local DestroyService = require(ServerStorage.DestroyService)

local function clearParts(parent)
	for _, part in pairs(parent:GetChildren()) do
		clearParts(part)
	end
	
	local delay
	if parent:IsA("Part") then
		delay = math.random(3, 7)
	else
		delay = 8
	end
	
	DestroyService:AddItem(parent, delay)
end

local function infectHumanZombie(human)
	if human:GetAttribute("Zombified") then return end
	human:SetAttribute("Zombified", true)
	
	local zombie = zombieAgent:Clone()
	
	zombie:PivotTo(human:GetPivot())
	zombie.Parent = workspace.Zombies
end

human.Humanoid.Died:Once(function()
	AI.Stop()
	
	math.randomseed(tick())
	
	infectHumanZombie(human)
	clearParts(human)
	
	script.Disabled = true
end)


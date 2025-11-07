local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local humanAgent = ReplicatedStorage:WaitForChild("HumanAgent")

local zombie = script.Parent

local AI = require(ServerStorage.ZombieAI).new(zombie)
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

local function curedToHuman(zombie)
	if zombie:GetAttribute("Humanified") then return end
	zombie:SetAttribute("Humanified", true)

	local human = humanAgent:Clone()

	human:PivotTo(zombie:GetPivot())
	human.Parent = workspace.Humans
end

zombie.Humanoid.Died:Once(function()
	AI.Stop()
	
	math.randomseed(tick())
	
	curedToHuman(zombie)
	clearParts(zombie)
	
	script.Disabled = true
end)

local lastMoan = os.time()
math.randomseed(os.time())

while true do
	local animationTrack = zombie.Humanoid:LoadAnimation(zombie.Animations.Arms)
	animationTrack:Play()

	local now = os.time()
	if now - lastMoan > 5 then	
		if math.random() > 0.3 then
			zombie.Moan:Play()
			lastMoan = now
		end
	end
	
	task.wait(2)
end
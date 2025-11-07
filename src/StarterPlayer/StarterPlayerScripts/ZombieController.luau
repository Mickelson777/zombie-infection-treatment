local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local zombieAttackEvent = ReplicatedStorage:WaitForChild("ZombieAttack")

-- Left Mouse and VR Button Attack 
UserInputService.InputBegan:Connect(function(input, gameProcessed) 
	if gameProcessed then return end 
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then 
		zombieAttackEvent:FireServer()
	end 
end)

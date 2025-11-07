local ZombieFeature = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local zombieAttackEvent = ReplicatedStorage:WaitForChild("ZombieAttack")

local playerConnections = {}

function ZombieFeature.Initialize(player)
	playerConnections[player] = {}

	player.Character:SetAttribute("Name", "Zombie")

	local character = player.Character
	local humanoid = character:WaitForChild("Humanoid")
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	-- R15 arm parts
	local leftLowerArm = character:WaitForChild("LeftLowerArm")
	local leftUpperArm = character:WaitForChild("LeftUpperArm")
	local leftHand = character:WaitForChild("LeftHand")
	local rightLowerArm = character:WaitForChild("RightLowerArm")
	local rightUpperArm = character:WaitForChild("RightUpperArm")
	local rightHand = character:WaitForChild("RightHand")

	local ATTACK_RANGE = 3
	local DAMAGE = 10
	local DAMAGE_COOLDOWN = 1

	local canAttack = true
	local lastAttack = os.time()

	local zombieAnimations = ReplicatedStorage:WaitForChild("Animations")
	local attackTrack = humanoid:LoadAnimation(zombieAnimations.Attack)

	local function findNearbyHumans()
		local nearbyHumans = {}

		for _, otherPlayer in pairs(Players:GetPlayers()) do
			if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
				local otherCharacter = otherPlayer.Character
				local distance = (humanoidRootPart.Position - otherCharacter.HumanoidRootPart.Position).Magnitude

				if otherCharacter:GetAttribute("Name") == "Human" and distance <= ATTACK_RANGE then
					table.insert(nearbyHumans, otherCharacter)
				end
			end
		end

		for _, model in pairs(workspace:GetChildren()) do
			if model:IsA("Model") and model:GetAttribute("Name") == "Human" and model:FindFirstChild("HumanoidRootPart") and model:FindFirstChild("Humanoid") then
				local distance = (humanoidRootPart.Position - model.HumanoidRootPart.Position).Magnitude
				if distance <= ATTACK_RANGE and model.Humanoid.Health > 0 then
					table.insert(nearbyHumans, model)
				end
			end
		end

		return nearbyHumans
	end

	local function damageHuman(targetHuman)
		local targetHumanoid = targetHuman:FindFirstChild("Humanoid")
		if targetHumanoid and targetHumanoid.Health > 0 then
			targetHumanoid.Health = targetHumanoid.Health - DAMAGE

			if targetHuman:FindFirstChild("HumanoidRootPart") then
				local damageGui = Instance.new("BillboardGui")
				damageGui.Size = UDim2.new(0, 200, 0, 50)
				damageGui.StudsOffset = Vector3.new(0, 3, 0)
				damageGui.Parent = targetHuman.HumanoidRootPart

				local damageLabel = Instance.new("TextLabel")
				damageLabel.Size = UDim2.new(1, 0, 1, 0)
				damageLabel.BackgroundTransparency = 1
				damageLabel.Text = "-" .. DAMAGE
				damageLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
				damageLabel.TextStrokeTransparency = 0
				damageLabel.TextScaled = true
				damageLabel.Font = Enum.Font.FredokaOne
				damageLabel.Parent = damageGui

				damageLabel:TweenPosition(UDim2.new(0, 0, -1, 0), "Out", "Quad", 1, true)
				TweenService:Create(damageLabel, TweenInfo.new(1), {TextTransparency = 1}):Play()

				Debris:AddItem(damageGui, 1)
			end

			print(player.Name .. " damaged " .. (targetHuman.Name or "AI Human") .. " for " .. DAMAGE .. " damage!")
		end
	end

	local function performAttack(playerRequesting)
		if not playerRequesting or playerRequesting ~= player then return end
		if not canAttack then return end

		local nearbyHumans = findNearbyHumans()

		if #nearbyHumans > 0 then
			canAttack = false
			lastAttack = os.time()

			attackTrack:Play()

			for _, human in pairs(nearbyHumans) do
				damageHuman(human)
			end

			task.wait(DAMAGE_COOLDOWN)
			canAttack = true
		else
			attackTrack:Play()
		end
	end

	playerConnections[player].zombieAttackConnection = zombieAttackEvent.OnServerEvent:Connect(performAttack)

	local function handleArmTouch(hit, armName)
		if not canAttack then return end

		local hitModel = hit.Parent
		if hitModel and hitModel:GetAttribute("Name") == "Human" and hitModel:FindFirstChild("Humanoid") then
			if hitModel:FindFirstChild("HumanoidRootPart") then
				local distance = (humanoidRootPart.Position - hitModel.HumanoidRootPart.Position).Magnitude
				if distance <= ATTACK_RANGE and hitModel.Humanoid.Health > 0 then
					canAttack = false
					lastAttack = os.time()

					damageHuman(hitModel)

					task.wait(DAMAGE_COOLDOWN)
					canAttack = true
				end
			end
		end
	end

	playerConnections[player].leftLowerArmConnection = leftLowerArm.Touched:Connect(function(hit)
		handleArmTouch(hit, "LeftLowerArm")
	end)

	playerConnections[player].leftUpperArmConnection = leftUpperArm.Touched:Connect(function(hit)
		handleArmTouch(hit, "LeftUpperArm")
	end)

	playerConnections[player].leftHandConnection = leftHand.Touched:Connect(function(hit)
		handleArmTouch(hit, "LeftHand")
	end)

	playerConnections[player].rightLowerArmConnection = rightLowerArm.Touched:Connect(function(hit)
		handleArmTouch(hit, "RightLowerArm")
	end)

	playerConnections[player].rightUpperArmConnection = rightUpperArm.Touched:Connect(function(hit)
		handleArmTouch(hit, "RightUpperArm")
	end)

	playerConnections[player].rightHandConnection = rightHand.Touched:Connect(function(hit)
		handleArmTouch(hit, "RightHand")
	end)
end

function ZombieFeature.Cancel(player)
	if not playerConnections[player] then
		return
	end

	local connections = playerConnections[player]

	if connections.zombieAttackConnection then
		connections.zombieAttackConnection:Disconnect()
	end

	if connections.leftLowerArmConnection then
		connections.leftLowerArmConnection:Disconnect()
	end

	if connections.leftUpperArmConnection then
		connections.leftUpperArmConnection:Disconnect()
	end

	if connections.leftHandConnection then
		connections.leftHandConnection:Disconnect()
	end

	if connections.rightLowerArmConnection then
		connections.rightLowerArmConnection:Disconnect()
	end

	if connections.rightUpperArmConnection then
		connections.rightUpperArmConnection:Disconnect()
	end

	if connections.rightHandConnection then
		connections.rightHandConnection:Disconnect()
	end

	if connections.characterCleanupConnection then
		connections.characterCleanupConnection:Disconnect()
	end

	if connections.playerRemovingConnection then
		connections.playerRemovingConnection:Disconnect()
	end

	playerConnections[player] = nil

	if player.Character then
		player.Character:SetAttribute("Name", nil)
	end

	print(player.Name .. " zombie connections cancelled!")
end

return ZombieFeature
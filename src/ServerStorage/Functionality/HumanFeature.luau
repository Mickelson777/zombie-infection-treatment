local HumanFeature = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local cureClaimedBindableEvent = ReplicatedStorage:WaitForChild("CureClaimedEvent")

local playerConnections = {}

local function setupZombieConversion(character, player, cureUsesRemaining)
	if cureUsesRemaining <= 0 then return end

	local debounce = false
	local debounceTime = 1

	local connection
	connection = character.HumanoidRootPart.Touched:Connect(function(hit)
		if debounce then return end
		debounce = true

		local hitModel = hit.Parent
		if hitModel and hitModel:GetAttribute("Name") == "Zombie" and hitModel:FindFirstChild("Humanoid") and cureUsesRemaining > 0 then
			cureUsesRemaining -= 1
			character:SetAttribute("CureUsesRemaining", cureUsesRemaining)

			hitModel.Humanoid.Health = 0

			print(player.Name .. " cured a zombie! Uses remaining: " .. cureUsesRemaining)

			if cureUsesRemaining <= 0 then
				character:SetAttribute("ObtainedCure", false)

				local highlight = character:FindFirstChildOfClass("Highlight")
				if highlight then highlight:Destroy() end

				for _, particleEmitter in pairs(character:GetDescendants()) do
					if particleEmitter:IsA("ParticleEmitter") and particleEmitter.Name == "CureAura" then
						particleEmitter:Destroy()
					end
				end

				connection:Disconnect()
				if playerConnections[player] then
					playerConnections[player].zombieConversionConnection = nil
				end

				print(player.Name .. " has used all cure charges!")
			end
		end

		task.delay(debounceTime, function()
			debounce = false
		end)
	end)

	if playerConnections[player] then
		playerConnections[player].zombieConversionConnection = connection
	end
end

function HumanFeature.Initialize(player)
	playerConnections[player] = {}

	player.Character:SetAttribute("Name", "Human")

	local character = player.Character
	local humanoid = character:WaitForChild("Humanoid")
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	if not character:GetAttribute("ObtainedCure") then
		character:SetAttribute("ObtainedCure", false)
	end

	if not character:GetAttribute("CureUsesRemaining") then
		character:SetAttribute("CureUsesRemaining", 0)
	end

	local CURE_CLAIM_DISTANCE = 10

	local cureUsesRemaining = 0

	local function claimCure(cure)
		cure:SetAttribute("Claimed", true)

		character:SetAttribute("ObtainedCure", true)
		cureUsesRemaining = 3
		character:SetAttribute("CureUsesRemaining", 3)

		local highlight = Instance.new("Highlight")
		highlight.FillTransparency = 0.7
		highlight.FillColor = Color3.fromRGB(255, 170, 255)
		highlight.OutlineColor = Color3.fromRGB(255, 100, 130)
		highlight.Parent = character

		for _, part in pairs(character:GetChildren()) do
			if part:IsA("BasePart") then
				local cureAura = ReplicatedStorage.CureAura:Clone()
				cureAura.Parent = part
				cureAura.Enabled = true
			end
		end

		cureClaimedBindableEvent:Fire(cure, character)

		setupZombieConversion(character, player, cureUsesRemaining)

		print(player.Name .. " claimed a cure! Uses remaining: " .. cureUsesRemaining)
	end

	local cures = {}

	for _, cure in ipairs(workspace.City:WaitForChild("Cures"):GetChildren()) do
		table.insert(cures, cure)
	end

	for _, cure in ipairs(workspace.Farm:WaitForChild("Cures"):GetChildren()) do
		table.insert(cures, cure)
	end

	playerConnections[player].cureCheckConnection = RunService.Heartbeat:Connect(function()
		if not character.Parent then
			HumanFeature.Cancel(player)
			return
		end

		if not character:GetAttribute("ObtainedCure") then
			for _, cure in pairs(cures) do
				if cure:GetAttribute("Enabled") == true and cure:GetAttribute("Claimed") ~= true then
					local distance = (humanoidRootPart.Position - cure:GetPivot().Position).Magnitude
					if distance <= CURE_CLAIM_DISTANCE then
						claimCure(cure)
						break
					end
				end
			end
		end
	end)
end

function HumanFeature.Cancel(player)
	if not playerConnections[player] then
		return
	end

	local connections = playerConnections[player]

	if connections.cureCheckConnection then
		connections.cureCheckConnection:Disconnect()
	end

	if connections.zombieConversionConnection then
		connections.zombieConversionConnection:Disconnect()
	end

	if connections.characterCleanupConnection then
		connections.characterCleanupConnection:Disconnect()
	end

	if connections.playerRemovingConnection then
		connections.playerRemovingConnection:Disconnect()
	end

	if player.Character then
		local highlight = player.Character:FindFirstChildOfClass("Highlight")
		if highlight then highlight:Destroy() end

		for _, particleEmitter in pairs(player.Character:GetDescendants()) do
			if particleEmitter:IsA("ParticleEmitter") and particleEmitter.Name == "CureAura" then
				particleEmitter:Destroy()
			end
		end

		player.Character:SetAttribute("Name", nil)
		player.Character:SetAttribute("ObtainedCure", false)
		player.Character:SetAttribute("CureUsesRemaining", 0)
	end

	playerConnections[player] = nil

	print(player.Name .. " human connections cancelled!")
end

return HumanFeature
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local spectateFunction = ReplicatedStorage:WaitForChild("Spectate") :: RemoteFunction
local humanFunction = ReplicatedStorage:WaitForChild("Human") :: RemoteFunction
local zombieFunction = ReplicatedStorage:WaitForChild("Zombie") :: RemoteFunction
local resetFunction = ReplicatedStorage:WaitForChild("Reset") :: RemoteFunction
local parameterChangeEvent = ReplicatedStorage:WaitForChild("ParameterChange") :: RemoteEvent

local interfaceGui = workspace.SafeBox:WaitForChild("Interface"):WaitForChild("SurfaceGui")
local mapSelected = nil
local spawnPart = nil

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Map Selection
interfaceGui.CityMap.Activated:Connect(function()
	mapSelected = "City"
	spawnPart = workspace.City:FindFirstChild("SpawnPart")
	
	interfaceGui.CityMap.UIStroke.Color = Color3.fromRGB(255, 255, 255)
	interfaceGui.FarmMap.UIStroke.Color = Color3.fromRGB(0, 0, 0)
end)

interfaceGui.FarmMap.Activated:Connect(function()
	mapSelected = "Farm"
	spawnPart = workspace.Farm:FindFirstChild("SpawnPart")
	
	interfaceGui.FarmMap.UIStroke.Color = Color3.fromRGB(255, 255, 255)
	interfaceGui.CityMap.UIStroke.Color = Color3.fromRGB(0, 0, 0)
end)

-- Spectate
interfaceGui.Spectate.Activated:Connect(function()
	if not mapSelected or not spawnPart then return end 
	
	local success = spectateFunction:InvokeServer(mapSelected)
	if success then
		player.Character:PivotTo(spawnPart.CFrame)
	end
end)

-- Play as Human
interfaceGui.Human.Activated:Connect(function()
	if not mapSelected or not spawnPart then return end 
	
	local success = humanFunction:InvokeServer(mapSelected)
	if success then
		player.Character:PivotTo(spawnPart.CFrame)
	end
end)

-- Play as Zombie
interfaceGui.Zombie.Activated:Connect(function()
	if not mapSelected or not spawnPart then return end 
	
	local success = zombieFunction:InvokeServer(mapSelected)
	if success then
		player.Character:PivotTo(spawnPart.CFrame)
	end
end)

-- Reset (VR + Keyboard & Mouse)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.X or input.KeyCode == Enum.KeyCode.ButtonX then 
		local success = resetFunction:InvokeServer()
		if success then
			player.Character:PivotTo(CFrame.new(workspace.SafeBox.SpawnLocation.Position + Vector3.new(0, 2, 0)))
		end
	end 
end)

--------------------------------------------------------------------------------------------------
-- Sliders
local parameterEditorGui = workspace.SafeBox:WaitForChild("ParameterEditor")
local Mouse = player:GetMouse()
local activeSlider = nil

local function CalculateScalePosition(Part, Axis)
	local Mouse3DPosition = Mouse.Hit.Position
	local StartAxis = Part.Position[Axis] - (Part.Size[Axis] / 2)
	local EndAxis = Part.Position[Axis] + (Part.Size[Axis] / 2)
	local Range = EndAxis - StartAxis
	local Distance = Mouse3DPosition[Axis] - StartAxis
	local Percentage = math.clamp(Distance / Range, 0, 1)

	if Axis == "X" then
		Percentage = 1 - Percentage
	end

	return Percentage
end

local function setupSlider(InputSliderGui, InputMaxVal, InputMinVal)
	local Slider = InputSliderGui
	local Fill = Slider.Fill
	local Trigger = Slider.Trigger
	local OutputLabel = Slider.Label
	local Output = Slider.Output

	local MaxValue = InputMaxVal
	local MinValue = InputMinVal
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad)

	-- Init fill size
	Fill.Size = UDim2.fromScale((Output.Value - MinValue) / (MaxValue - MinValue), 1)
	OutputLabel.Text = tostring(math.round(Output.Value))

	local function updateSlider()
		local normalized = CalculateScalePosition(parameterEditorGui, "X")
		local clampedValue = MinValue + normalized * (MaxValue - MinValue)

		TweenService:Create(Fill, tweenInfo, {
			Size = UDim2.fromScale(normalized, 1)
		}):Play()

		Output.Value = clampedValue
		OutputLabel.Text = tostring(math.round(clampedValue))
	end

	local function ActivateSlider()
		while activeSlider == Slider do
			updateSlider()
			RunService.RenderStepped:Wait()
		end
	end

	Trigger.MouseButton1Down:Connect(function()
		activeSlider = Slider
		ActivateSlider()
	end)
end

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if activeSlider then
			local Output = activeSlider:FindFirstChild("Output")

			if Output and Output:IsA("NumberValue") then
				local rounded = math.round(Output.Value)
				parameterChangeEvent:FireServer(activeSlider.Name, rounded)
			end
			activeSlider = nil
		end
	end
end)

setupSlider(parameterEditorGui.SurfaceGui.agentsPerPoint, 20, 5)
setupSlider(parameterEditorGui.SurfaceGui.humanPick, 8, 0)
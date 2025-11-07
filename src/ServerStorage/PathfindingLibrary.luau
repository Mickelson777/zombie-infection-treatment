local PathfindingService = game:GetService("PathfindingService")

local PathfindingLibrary = {}

local TargetOffsetMax = 10
local JumpThreshold = 1.5
local NextPointThreshold = 4
local StuckThreshold = 2
local StuckDistanceThreshold = 1
local ForceJumpCooldown = 0.75
local PathRecomputeTime = 3

function PathfindingLibrary.new()
	local this = {}

	local currentTargetPos = nil	
	local lastTargetPos = Vector3.new(math.huge, math.huge, math.huge)	
	local path = nil
	local currentPointIndex = 1	

	local lastPosition = nil
	local stuckTimer = 0
	local lastJumpTime = 0
	local lastUpdateTime = tick()
	local lastPathComputeTime = 0
	local pathFailureCount = 0

	function this:MoveToTarget(character, target)
		local currentTime = tick()
		local deltaTime = currentTime - lastUpdateTime
		lastUpdateTime = currentTime

		local targetOffset = (lastTargetPos - target).Magnitude
		local currentPosition = character.HumanoidRootPart.Position

		-- Check if mob is stuck
		local isStuck = false
		if lastPosition then
			local distanceMoved = (currentPosition - lastPosition).Magnitude
			
			if distanceMoved < StuckDistanceThreshold then
				stuckTimer = stuckTimer + deltaTime
				if stuckTimer > StuckThreshold then
					isStuck = true
				end
			else
				stuckTimer = 0 -- Reset stuck timer if moving
				pathFailureCount = math.max(0, pathFailureCount - 1) -- Reduce failure count when moving
			end
		end
		
		lastPosition = currentPosition

		--[[ Conditions to recompute path:
			1. Target moved significantly
			2. Character is stuck
			3. Path is old (hasn't been recomputed in a while)
			4. No path exists ]]
		
		local shouldRecomputePath = false

		if targetOffset > TargetOffsetMax then
			shouldRecomputePath = true
		elseif isStuck then
			shouldRecomputePath = true
			stuckTimer = 0
		elseif (currentTime - lastPathComputeTime) > PathRecomputeTime then
			shouldRecomputePath = true
		elseif not path then
			shouldRecomputePath = true
		end

		if shouldRecomputePath then
			-- Compute starting point (accounting for jumping / falling)
			local startPoint = character.HumanoidRootPart.Position
			local humanoidState = character.Humanoid:GetState()
			if humanoidState == Enum.HumanoidStateType.Jumping or humanoidState == Enum.HumanoidStateType.Freefall then
				local ray = workspace:Raycast(character.HumanoidRootPart.Position, Vector3.new(0, -100, 0), RaycastParams.new())
				if ray then
					startPoint = ray.Position
				end
			end

			-- Adjust target to ensure it's on ground
			local newTarget = target
			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = {character}
			rayParams.FilterType = Enum.RaycastFilterType.Exclude

			local ray = workspace:Raycast(target + Vector3.new(0, 5, 0), Vector3.new(0, -100, 0), rayParams)
			if ray then
				newTarget = ray.Position + Vector3.new(0, 2, 0) -- Slightly above ground
			end

			-- Compute path
			local success, newPath = pcall(function()
				return PathfindingService:CreatePath({
					AgentRadius = 2,
					AgentHeight = 5,
					AgentCanJump = true,
					AgentJumpHeight = 7.5,
					AgentMaxSlope = 45,
					WaypointSpacing = 4,
					Costs = {
						Water = 20,
						DangerZone = math.huge
					}
				}):ComputeAsync(startPoint, newTarget)
			end)

			if success and newPath and newPath.Status == Enum.PathStatus.Success then
				path = newPath
				currentPointIndex = 1
				lastTargetPos = target
				lastPathComputeTime = currentTime
				pathFailureCount = 0
			else
				-- Path computation failed
				pathFailureCount = pathFailureCount + 1
				lastPathComputeTime = currentTime

				-- If pathfinding repeatedly fails, use direct movement as fallback
				if pathFailureCount > 2 then
					path = nil -- Clear path to use direct movement
				end
			end
		end

		-- Movement logic
		if path then
			-- Use pathfinding waypoints
			local waypoints = path:GetWaypoints()

			if currentPointIndex <= #waypoints then
				local currentWaypoint = waypoints[currentPointIndex]
				local distance = (character.HumanoidRootPart.Position * Vector3.new(1, 0, 1) - currentWaypoint.Position * Vector3.new(1, 0, 1)).Magnitude

				-- Check if we should move to next waypoint
				if distance < NextPointThreshold then
					currentPointIndex = currentPointIndex + 1
					if currentPointIndex > #waypoints then
						currentPointIndex = #waypoints
					end
				end

				-- Move to current waypoint
				local targetPoint = waypoints[math.min(currentPointIndex, #waypoints)].Position
				character.Humanoid:MoveTo(targetPoint)

				-- Handle jumping
				local shouldJump = false

				-- Check if waypoint requires jump
				if currentWaypoint.Action == Enum.PathWaypointAction.Jump then
					shouldJump = true
				end

				-- Jump if target is higher
				if targetPoint.Y - character.HumanoidRootPart.Position.Y > JumpThreshold then
					shouldJump = true
				end

				-- Jump if there's an obstacle ahead
				local forwardDirection = (targetPoint - currentPosition).Unit
				local rayParams = RaycastParams.new()
				rayParams.FilterDescendantsInstances = {character}
				rayParams.FilterType = Enum.RaycastFilterType.Exclude

				local ray = workspace:Raycast(currentPosition + Vector3.new(0, 1, 0), forwardDirection * 3, rayParams)
				if ray and ray.Instance and ray.Instance.Parent:GetAttribute("Name") ~= "Human" and ray.Instance.Parent:GetAttribute("Name") ~= "Zombie" and (currentTime - lastJumpTime) > ForceJumpCooldown then
					shouldJump = true
				end

				if shouldJump then
					character.Humanoid.Jump = true
					lastJumpTime = currentTime
					stuckTimer = 0
				end
			else
				-- Reached end of path, move directly to final target
				character.Humanoid:MoveTo(target)
			end

			return true
		else
			-- Fallback: Direct movement when pathfinding fails
			-- Ensures the character keeps trying to move even without a valid path

			local direction = (target - currentPosition).Unit
			local distance = (target - currentPosition).Magnitude

			-- Move in steps to avoid getting stuck
			local stepDistance = math.min(distance, 10)
			local moveTarget = currentPosition + direction * stepDistance

			character.Humanoid:MoveTo(moveTarget)

			-- Simple obstacle detection for jumping
			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = {character}
			rayParams.FilterType = Enum.RaycastFilterType.Exclude

			local ray = workspace:Raycast(currentPosition + Vector3.new(0, 1, 0), direction * 3, rayParams)
			if ray and ray.Instance and (currentTime - lastJumpTime) > ForceJumpCooldown then
				character.Humanoid.Jump = true
				lastJumpTime = currentTime
			end

			return true
		end
	end

	-- Reset function to clear path data
	function this:Reset()
		path = nil
		currentPointIndex = 1
		lastTargetPos = Vector3.new(math.huge, math.huge, math.huge)
		stuckTimer = 0
		pathFailureCount = 0
		lastPosition = nil
	end

	return this
end

return PathfindingLibrary
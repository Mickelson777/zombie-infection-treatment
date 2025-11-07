local Machine = {}

Machine.new = function()
	local StateMachine = {}	
	
	StateMachine.WaitTime = 0.2
	StateMachine.CurrentState = nil
	
	StateMachine.SwitchState = function(newState)
		if StateMachine.CurrentState then
			StateMachine.CurrentState.Stop()
		end
		
		StateMachine.CurrentState = newState
		
		if newState then
			newState.Start()
		end
	end
	
	StateMachine.NewState = function()
		local State = {}
		State.Name = ""
		State.Conditions = {}
		State.isRunning = false
		State.Action = function() end
		
		State.Run = function()
			State.isRunning = true
			while State.isRunning do
				-- Checking conditions
				for _, condition in pairs(State.Conditions) do
					if condition.Evaluate() then
						-- print(condition.Name .. " is true. Switching states!")
						StateMachine.SwitchState(condition.TransitionState)
						return
					end
				end
				
				-- If no conditions satisfied, perform action
				State.Action()
				task.wait(StateMachine.WaitTime)
			end
		end
		State.Init = function()
			
		end
		State.Start = function()
			State.Init()
			local thread = coroutine.create(State.Run)
			coroutine.resume(thread)
		end
		State.Stop = function()
			State.isRunning = false
		end
		
		return State
	end
	
	StateMachine.NewCondition = function()
		local condition = {}
		condition.Name = ""
		condition.Evaluate = function() return false end
		condition.TransitionState = {}
		
		return condition
	end	
	
	return StateMachine
end

return Machine
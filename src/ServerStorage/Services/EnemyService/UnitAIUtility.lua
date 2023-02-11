local Debris = game:GetService('Debris')
local RunService = game:GetService('RunService')
local PathfindingService = game:GetService('PathfindingService')

local baseVisualPart = Instance.new('Part')
baseVisualPart.Transparency = 0.5
baseVisualPart.Color = Color3.new(0.9, 0, 0)
baseVisualPart.Anchored = true
baseVisualPart.CanCollide = false
baseVisualPart.CanQuery = false
baseVisualPart.CanTouch = false
baseVisualPart.Size = Vector3.new(1, 1, 1)
baseVisualPart.CastShadow = false

local MoveToWaitGlobalCache = {}
local DEFAULT_MOVE_TO_WAIT_TIMEOUT_DURATION = 4

-- // Module // --
local Module = {}

function Module:MoveToWait( AIClass, Position )
	local bindable = Instance.new("BindableEvent")
	local data = {AIClass, Position, bindable, time(), nil}
	table.insert(MoveToWaitGlobalCache, data)
	AIClass:MoveTo( Position )
	if data[6] == nil then
		bindable.Event:Wait()
	end
	bindable:Destroy()
	return data[6]
end

function Module:VisualizePathWaypoints( pathWaypoints )
	local Points = {}
	for _, waypointNode in ipairs( pathWaypoints ) do
		local clonePart = baseVisualPart:Clone()
		clonePart.Position = waypointNode.Position
		clonePart.Parent = workspace
		table.insert(Points, clonePart)
	end
	return Points
end

function Module:PathfindTo( AIClass, TargetPosition, AgentParams )
	local PathObject = PathfindingService:CreatePath( AgentParams )
	PathObject:ComputeAsync( AIClass.Position, TargetPosition )

	local Waypoints = PathObject:GetWaypoints()
	local VisualWaypoints = Module:VisualizePathWaypoints( Waypoints )
	for _, basePart in ipairs( VisualWaypoints ) do
		Debris:AddItem(basePart, 4)
	end

	for _, waypoint in ipairs( Waypoints ) do
		if not Module:MoveToWait( AIClass, waypoint.Position ) then
			return false
		end
	end
	return true
end

RunService.Heartbeat:Connect(function()
	local index = 1
	while index <= #MoveToWaitGlobalCache do
		local data = MoveToWaitGlobalCache[index]
		local AIClass, Position, bindable, startTime, _ = unpack(data)
		if (time() - startTime > DEFAULT_MOVE_TO_WAIT_TIMEOUT_DURATION) or (AIClass.Health <= 0) then
			-- timeout or if the humanoid died
			table.remove(MoveToWaitGlobalCache, index)
			data[6] = false
			bindable:Fire()
		elseif (AIClass.Position - Position).Magnitude < 4 then
			-- if they have reached the point
			table.remove(MoveToWaitGlobalCache, index)
			data[6] = true
			bindable:Fire()
		else
			AIClass:MoveTo( Position )
			index += 1
		end
	end
end)

return Module

--[[local CollectionService = game:GetService('CollectionService')

local RunService = game:GetService("RunService")

local Terrain = workspace.Terrain
local RedFolder = workspace:WaitForChild('Red')
local BlueFolder = workspace:WaitForChild('Blue')

local DEFAULT_MOVE_TO_WAIT_TIMEOUT_DURATION = 5
local SubjectBasedRaycastParams = RaycastParams.new()
SubjectBasedRaycastParams.FilterType = Enum.RaycastFilterType.Whitelist
SubjectBasedRaycastParams.IgnoreWater = true
SubjectBasedRaycastParams.FilterDescendantsInstances = { BlueFolder, RedFolder, Terrain }

local MoveToWaitGlobalCache = {}]]

-- // Module // --
local Module = {}

--[[function Module:FindNearestCharacterWithFilters( Position, MaxRange, teamInstance, filterFunction )
	local EnemyModel, EnemyHumanoid, EnemyDistance = nil, nil, -1

	for _, Model in ipairs( CollectionService:GetTagged('GameCharacters') ) do
		local Humanoid = Model:FindFirstChildWhichIsA('Humanoid')
		if (not Humanoid) or (Humanoid.Health <= 0) then
			continue
		end

		if teamInstance then
			local ValidTeamCharacters = CollectionService:GetTagged(teamInstance.Name..'Characters')
			if not table.find(ValidTeamCharacters, Model) then
				continue
			end
		end

		if filterFunction and (not filterFunction(Model, Humanoid, EnemyDistance)) then
			continue
		end

		local Distance = (Model:GetPivot().Position - Position).Magnitude
		if EnemyModel then
			if Distance < EnemyDistance then
				EnemyModel = Model
				EnemyHumanoid = Humanoid
				EnemyDistance = Distance
			end
		elseif Distance < MaxRange then
			EnemyModel = Model
			EnemyHumanoid = Humanoid
			EnemyDistance = Distance
		end
	end

	return EnemyModel, EnemyHumanoid, EnemyDistance
end

function Module:GetSubjectFieldOfViewAngle( PerspectiveCFrame, SubjectCFrame )
	return (PerspectiveCFrame.Position - SubjectCFrame.Position):Dot(SubjectCFrame.LookVector)
end

function Module:IsSubjectWithinRaycastLineOfSight( OriginPosition, Subject )
	local SubjectPosition = Subject:GetPivot().Position
	local RayDir = CFrame.lookAt(OriginPosition, SubjectPosition).LookVector
	local Dist = (SubjectPosition - OriginPosition).Magnitude

	local RayResult = workspace:Raycast(OriginPosition, RayDir * Dist, SubjectBasedRaycastParams)
	return RayResult and RayResult.Instance:IsDescendantOf(Subject)
end

function Module:IsPositionWithinRaycastLineOfSight(OriginPosition, TargetPosition)
	local RayDir = CFrame.lookAt(OriginPosition, TargetPosition).LookVector
	local Dist = (TargetPosition - OriginPosition).Magnitude
	return workspace:Raycast(OriginPosition, RayDir * Dist, SubjectBasedRaycastParams) == nil
end
]]

return Module
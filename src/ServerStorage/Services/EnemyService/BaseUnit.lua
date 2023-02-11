local HttpService = game:GetService('HttpService')
local CollectionService = game:GetService('CollectionService')

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedModules = require(ReplicatedStorage:WaitForChild('Modules'))

local EventClass = ReplicatedModules.Classes.Event

local DEFAULT_AGENT_PARAMETERS = {AgentCanJump = false, AgentCanClimb = false}
local CHARACTER_ROTATION_SPEED = 2

local DefaultRayParams = RaycastParams.new()
DefaultRayParams.FilterType = Enum.RaycastFilterType.Blacklist
DefaultRayParams.IgnoreWater = true
DefaultRayParams.FilterDescendantsInstances = CollectionService:GetTagged('PlayerCharacters')

local function V3ToV2XZ( vec3 )
	return Vector2.new( vec3.X, vec3.Z )
end

-- // Class // --
local Class = {}
Class.__index = Class

function Class.New( Position, Rotation, OffsetFromGround, OutfitReference )
	local self = setmetatable({
		UUID = HttpService:GenerateGUID(false),
		OutfitReference = OutfitReference,

		Health = 100,
		WalkSpeed = 16,
		Position = Position,
		Rotation = Rotation,
		YOffset = OffsetFromGround,

		AIConfig = false, -- animations, walkspeed, etc

		--[[States = {
			IsWalking = false,
			IsIdle = true,
		},]]

		LastMoveToPosition = false,
		MoveToPosition = false,

		_IsUpdating = false,
		_Destroyed = false,

		_RaycastParams = DefaultRayParams,
		_PropertyChanged = EventClass.New(),
	}, Class)

	return self
end

function Class:_StopMovementOperations()
	if self.MoveToPosition then
		self.MoveToPosition = false
		self._PropertyChanged:Fire('MoveToPosition', false)
	end
end

function Class:MoveTo( TargetPosition )
	self:_StopMovementOperations()
	if self.MoveToPosition ~= TargetPosition then
		self.MoveToPosition = TargetPosition
		self._PropertyChanged:Fire('MoveToPosition', TargetPosition)
	end
end

function Class:GetPropertyChangedSignal(propertyName, callback)
	return self._PropertyChanged:Connect(function(name, ...)
		if name == propertyName then
			callback(...)
		end
	end)
end

--[[function Class:SetState(stateName, stateEnabled)
	stateEnabled = stateEnabled and true or false -- lock to boolean
	if self.States[stateName] ~= stateEnabled then
		self.States[stateName] = stateEnabled
		self._PropertyChanged:Fire(stateName, stateEnabled)
	end
end]]

-- update MoveToPosition and walking/idle states
function Class:UpdateAI(_)
	DefaultRayParams.FilterDescendantsInstances = CollectionService:GetTagged('PlayerCharacters')

	if self.LastMoveToPosition ~= self.MoveToPosition then
		self.LastMoveToPosition = self.MoveToPosition
		self._PropertyChanged:Fire('LastMoveToPosition', self.LastMoveToPosition)
	end

	--[[local isWalking = false
	if self.MoveToPosition then
		isWalking = (V3ToV2XZ(self.Position) - V3ToV2XZ(self.MoveToPosition)).Magnitude > 1
	end

	if isWalking then
		if not self.States.IsWalking then
			self:SetState('IsWalking', true)
		end
		if self.States.IsIdle then
			self:SetState('IsIdle', false)
		end
	else
		if self.States.IsWalking then
			self:SetState('IsWalking', false)
		end
		if not self.States.IsIdle then
			self:SetState('IsIdle', true)
		end
	end]]
end

function Class:UpdateMovement(movementDeltaTime)
	if self.MoveToPosition then
		local DirectionToTarget = (self.MoveToPosition - self.Position)
		local OffsetXZ = Vector3.new( DirectionToTarget.Unit.X, 0, DirectionToTarget.Unit.Z) * movementDeltaTime * self.WalkSpeed
		-- print(OffsetXZ)
		self.Position += OffsetXZ
		-- self._PropertyChanged:Fire('Position', self.Position)

		-- find the delta rotation
		local _, finalRotation, _ = CFrame.lookAt(self.Position, self.MoveToPosition):ToOrientation()

		-- apply the delta rotation
		self.Rotation += (math.deg(finalRotation) - self.Rotation) * movementDeltaTime * CHARACTER_ROTATION_SPEED
		self._PropertyChanged:Fire('Rotation', self.Rotation)
	end

	local yPositionValue = self.Position.Y
	local raycastResult = workspace:Raycast( self.Position, Vector3.new(0, -self.YOffset, 0), self._RaycastParams )
	if raycastResult then
		yPositionValue = raycastResult.Position.Y + self.YOffset
	--else
		--yPositionValue -= (self.YOffset * movementDeltaTime) -- TODO: change to gravity
	end

	self.Position = Vector3.new( self.Position.X, yPositionValue, self.Position.Z )
	self._PropertyChanged:Fire('Position', self.Position)
end

return Class

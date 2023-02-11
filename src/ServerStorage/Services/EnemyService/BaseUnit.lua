local HttpService = game:GetService('HttpService')
local CollectionService = game:GetService('CollectionService')

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedModules = require(ReplicatedStorage:WaitForChild('Modules'))

local EventClass = ReplicatedModules.Classes.Event

local CHARACTER_ROTATION_SPEED = 6

local DefaultRayParams = RaycastParams.new()
DefaultRayParams.FilterType = Enum.RaycastFilterType.Blacklist
DefaultRayParams.IgnoreWater = true
DefaultRayParams.FilterDescendantsInstances = CollectionService:GetTagged('PlayerCharacters')

local EnemyService =  false

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

		LastMoveToPosition = false,
		MoveToPosition = false,

		_IsUpdating = false,
		_Destroyed = false,

		_RaycastParams = DefaultRayParams,
		_PropertyChanged = EventClass.New(),
	}, Class)

	return self
end

function Class:MoveTo( TargetPosition )
	if self.MoveToPosition ~= TargetPosition then
		self.MoveToPosition = TargetPosition
		self._PropertyChanged:Fire('MoveToPosition', TargetPosition)
	end
end

function Class:Destroy()
	self._Destroyed = true
	EnemyService.OnNPCRemoved:FireAllClients(self.UUID)
end

function Class:GetPropertyChangedSignal(propertyName, callback)
	return self._PropertyChanged:Connect(function(name, ...)
		if name == propertyName then
			callback(...)
		end
	end)
end

-- update MoveToPosition and walking/idle states
function Class:UpdateAI(_)
	DefaultRayParams.FilterDescendantsInstances = CollectionService:GetTagged('PlayerCharacters')

	if self.LastMoveToPosition ~= self.MoveToPosition then
		self.LastMoveToPosition = self.MoveToPosition
		self._PropertyChanged:Fire('LastMoveToPosition', self.LastMoveToPosition)
	end
end

function Class:UpdateMovement(movementDeltaTime)
	if self.MoveToPosition then
		local DirectionToTarget = (self.MoveToPosition - self.Position)
		local OffsetXZ = Vector3.new( DirectionToTarget.Unit.X, 0, DirectionToTarget.Unit.Z) * movementDeltaTime * self.WalkSpeed * 0.5
		-- print(OffsetXZ)
		self.Position += OffsetXZ
		-- self._PropertyChanged:Fire('Position', self.Position)

		-- find the delta rotation
		local _, finalRotation, _ = CFrame.lookAt(self.Position, self.MoveToPosition):ToOrientation()

		-- apply the delta rotation
		self.Rotation += (math.deg(finalRotation) - self.Rotation) * movementDeltaTime * CHARACTER_ROTATION_SPEED
		self._PropertyChanged:Fire('Rotation', self.Rotation)
	end

	--[[local yPositionValue = self.Position.Y
	local raycastResult = workspace:Raycast( self.Position, Vector3.new(0, -self.YOffset, 0), self._RaycastParams )
	if raycastResult then
		yPositionValue = raycastResult.Position.Y + self.YOffset
	end

	self.Position = Vector3.new( self.Position.X, yPositionValue, self.Position.Z )]]
	self._PropertyChanged:Fire('Position', self.Position)
end

function Class:SetEnemyService(newService)
	EnemyService = newService
end

return Class

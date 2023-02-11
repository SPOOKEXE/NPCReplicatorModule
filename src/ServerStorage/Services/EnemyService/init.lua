local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Knit = require(ReplicatedStorage:WaitForChild("Knit"))

local EnemyService = Knit.CreateService { Name = "EnemyService", Client = {},}
local DataReplicateService = false

local UnitModelCacheFolder = Instance.new('Folder')
UnitModelCacheFolder.Name = 'UnitModelCache'
UnitModelCacheFolder.Parent = ReplicatedStorage

local BaseUnitClassModule = require(script.BaseUnit)
local UnitAIUtility = require(script.UnitAIUtility)

local MOVEMENT_STEPS = 2

local ActiveNPCClasses = {}
local EnemyOutfitCache = {}

function EnemyService:RegisterModel( EnemyModel : Model )
	local Humanoid = EnemyModel:FindFirstChildWhichIsA('Humanoid')
	if not Humanoid then
		warn('EnemyService:RegisterModel - Model does not have a Humanoid - ' .. EnemyModel:GetFullName())
		return
	end

	local EnemyModelName = EnemyModel.Name
	if not EnemyOutfitCache[ EnemyModelName ] then
		local ClonedModel = EnemyModel:Clone()
		ClonedModel.Parent = UnitModelCacheFolder
		EnemyOutfitCache[ EnemyModelName ] = ClonedModel
	end

	local EnemyPivot = EnemyModel:GetPivot()
	local _, yAngle, _ = EnemyPivot:ToOrientation()
	yAngle = math.deg(yAngle)

	local BaseEnemyClass = BaseUnitClassModule.New(
		EnemyPivot.Position,
		yAngle,
		Humanoid.HipHeight,
		EnemyModelName
	)

	ActiveNPCClasses[BaseEnemyClass.UUID] = BaseEnemyClass

	return BaseEnemyClass
end

function EnemyService:KnitStart()
	DataReplicateService:SetData('NPCReplicator', ActiveNPCClasses, nil)

	task.defer(function()
		local DummyModel = workspace.Dummy

		local BlankRootPart = Instance.new('Part')
		BlankRootPart.Name = 'FakeRootPart'
		BlankRootPart.Transparency = 0.5
		BlankRootPart.Anchored = true
		BlankRootPart.Size = Vector3.new(2, 2, 1)
		BlankRootPart.CanCollide = false
		BlankRootPart.CanQuery = false
		BlankRootPart.CanTouch = false
		BlankRootPart.Parent = workspace

		local TestVirtualNPC = EnemyService:RegisterModel(DummyModel)
		TestVirtualNPC:GetPropertyChangedSignal('Position', function(newValue)
			local Direction = (newValue - BlankRootPart.Position).Unit
			if tostring(Direction.Magnitude) == 'nan' or Direction.Magnitude == 0 then
				return
			end
			local newCFrame = CFrame.lookAt(newValue, newValue + Vector3.new(Direction.X, 0, Direction.Z))
			BlankRootPart:PivotTo( newCFrame )
		end)

		DummyModel:Destroy()

		while true do
			task.wait(1)
			print( UnitAIUtility:PathfindTo( TestVirtualNPC, workspace.Part1.Position ) )
			task.wait(1)
			print( UnitAIUtility:PathfindTo( TestVirtualNPC, workspace.Part2.Position ) )
		end
	end)

end

function EnemyService:UpdateDelta(deltaTime)

	-- for each active ai class
	for UUID, AI in pairs( ActiveNPCClasses ) do
		-- if the NPC is destroyed,
		-- remove it from the active classes
		if AI._Destroyed then
			ActiveNPCClasses[UUID] = nil
			continue
		end

		-- if this npc is updating, skip it
		if AI._IsUpdating then
			continue
		end
		-- now it is updating
		AI._IsUpdating = true
		-- thread for update
		task.spawn(function()
			-- single step to update AI
			AI:UpdateAI(deltaTime)
			-- several small steps to update movement
			local movementDeltaTime = deltaTime / MOVEMENT_STEPS
			for _ = 1, MOVEMENT_STEPS do
				AI:UpdateMovement(movementDeltaTime)
			end
			-- no longer updating
			AI._IsUpdating = false
		end)
	end

end

function EnemyService:KnitInit()
	DataReplicateService = Knit.GetService('DataReplicateService')

	-- default core update loop
	RunService.Heartbeat:Connect(function(deltaTime)
		EnemyService:UpdateDelta(deltaTime)
	end)
end

return EnemyService

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService('PhysicsService')

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Knit"))

local EnemyService = Knit.CreateService { Name = "EnemyService", Client = {},}

local ReplicatedModules = require(ReplicatedStorage:WaitForChild('Modules'))
local RemoteService = ReplicatedModules.Services.RemoteService
EnemyService.OnNPCCreated = RemoteService:GetRemote('OnNPCCreated', 'RemoteEvent', false)
EnemyService.OnNPCUpdated = RemoteService:GetRemote('OnNPCUpdated', 'RemoteEvent', false)
EnemyService.OnNPCRemoved = RemoteService:GetRemote('OnNPCRemoved', 'RemoteEvent', false)
EnemyService.GetData = RemoteService:GetRemote('GetData', 'RemoteEvent', false)

local UnitModelCacheFolder = Instance.new('Folder')
UnitModelCacheFolder.Name = 'UnitModelCache'
UnitModelCacheFolder.Parent = ReplicatedStorage

local BaseUnitClassModule = require(script.BaseUnit)
local UnitAIUtility = require(script.UnitAIUtility)

local ActiveNPCClasses = {}
local EnemyOutfitCache = {}

function EnemyService:SetCollisionGroup(Model, Group)
	for _, basePart in ipairs( Model:GetDescendants() ) do
		if basePart:IsA('BasePart') then
			basePart.CollisionGroup = Group
		end
	end
end

function EnemyService:RegisterModel( EnemyModel : Model )
	local Humanoid = EnemyModel:FindFirstChildWhichIsA('Humanoid')
	if not Humanoid then
		warn('EnemyService:RegisterModel - Model does not have a Humanoid - ' .. EnemyModel:GetFullName())
		return
	end

	local EnemyModelName = EnemyModel.Name
	if not EnemyOutfitCache[ EnemyModelName ] then
		local ClonedModel = EnemyModel:Clone()
		EnemyService:SetCollisionGroup(ClonedModel, 'FakeNPC')
		ClonedModel.Parent = UnitModelCacheFolder
		EnemyOutfitCache[ EnemyModelName ] = ClonedModel
	end

	local EnemyPivot = EnemyModel:GetPivot()
	local _, yAngle, _ = EnemyPivot:ToOrientation()
	yAngle = math.deg(yAngle)

	local BaseEnemyClass = BaseUnitClassModule.New(EnemyPivot.Position, yAngle, Humanoid.HipHeight,	EnemyModelName)

	EnemyService.OnNPCCreated:FireAllClients({
		UUID = BaseEnemyClass.UUID,
		OutfitReference = BaseEnemyClass.OutfitReference,
		Health = BaseEnemyClass.Health,
		MoveToPosition = BaseEnemyClass.MoveToPosition,
		WalkSpeed = BaseEnemyClass.WalkSpeed,
	})

	BaseEnemyClass:GetPropertyChangedSignal('WalkSpeed', function(newValue)
		EnemyService.OnNPCUpdated:FireAllClients(BaseEnemyClass.UUID, 1, newValue)
	end)

	BaseEnemyClass:GetPropertyChangedSignal('MoveToPosition', function(newValue)
		EnemyService.OnNPCUpdated:FireAllClients(BaseEnemyClass.UUID, 2, Vector2int16.new( math.round(newValue.X), math.round(newValue.Z)))
	end)

	ActiveNPCClasses[BaseEnemyClass.UUID] = BaseEnemyClass

	return BaseEnemyClass
end

function EnemyService:KnitStart()
	EnemyService.GetData.OnServerEvent:Connect(function(LocalPlayer)
		EnemyService.GetData:FireClient(LocalPlayer, ActiveNPCClasses)
	end)

	-- default core update loop
	RunService.Heartbeat:Connect(function(deltaTime)
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
				AI:UpdateMovement(deltaTime)
				-- no longer updating
				AI._IsUpdating = false
			end)
		end

	end)

	local ActiveNPCs = {}

	local DummyModel = workspace.DummyR6
	for _ = 1, 400 do
		--[[local BlankRootPart = Instance.new('Part')
		BlankRootPart.Name = 'FakeRootPart'
		BlankRootPart.Transparency = 0
		BlankRootPart.TopSurface = Enum.SurfaceType.SmoothNoOutlines
		BlankRootPart.BottomSurface = Enum.SurfaceType.SmoothNoOutlines
		BlankRootPart.Anchored = true
		BlankRootPart.Size = Vector3.new(1, 1, 1)
		BlankRootPart.CanCollide = false
		BlankRootPart.CanQuery = false
		BlankRootPart.CanTouch = false
		BlankRootPart.CastShadow = false
		BlankRootPart.Parent = workspace]]
		local TestVirtualNPC = EnemyService:RegisterModel(DummyModel)
		--[[TestVirtualNPC:GetPropertyChangedSignal('Position', function(newValue)
			local newCFrame = CFrame.new(newValue)
			BlankRootPart:PivotTo( newCFrame )
		end)]]
		table.insert(ActiveNPCClasses, TestVirtualNPC)
		table.insert(ActiveNPCs, TestVirtualNPC)
	end
	DummyModel:Destroy()

	local Counter = 0
	local Total = #ActiveNPCs

	local Parts = {workspace.Part1.Position, workspace.Part2.Position, workspace.Part3.Position}
	local PartIndex = 1

	workspace.Gravity = 784.8

	task.spawn(function()
		while true do
			task.wait(1)
			PartIndex += 1
			if PartIndex > #Parts then
				PartIndex = 1
			end
			Counter = 0
			for _, TestVirtualNPC in ipairs( ActiveNPCs ) do
				task.defer(function()
					UnitAIUtility:MoveToWait( TestVirtualNPC, Parts[PartIndex] + Vector3.new( math.random(-50, 50), 0, math.random(-50, 50) ) )
					Counter += 1
				end)
			end
			repeat task.wait(0.2)
			until Counter >= Total
		end
	end)

end

function EnemyService:KnitInit()
	BaseUnitClassModule:SetEnemyService(EnemyService)
	PhysicsService:RegisterCollisionGroup('FakeNPC')
	PhysicsService:CollisionGroupSetCollidable('FakeNPC', 'FakeNPC', false)

	EnemyService:SetCollisionGroup(workspace.DummyR15, 'FakeNPC')
	EnemyService:SetCollisionGroup(workspace.DummyR6, 'FakeNPC')

	workspace.ChildAdded:Connect(function(Character)
		if Players:FindFirstChild(Character.Name) then
			CollectionService:AddTag(Character, 'PlayerCharacters')
			EnemyService:SetCollisionGroup(Character, 'FakeNPC')
		end
	end)
end

return EnemyService

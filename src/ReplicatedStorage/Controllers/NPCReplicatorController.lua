local TweenService = game:GetService('TweenService')

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Knit"))

local UnitModelCacheFolder = ReplicatedStorage:WaitForChild('UnitModelCache')

local NPCReplicatorController = Knit.CreateController { Name = "NPCReplicatorController" }
local DataReplicateController = false

local ReplicatedNPCData = {}
local RunningNPCsCache = {}

function NPCReplicatorController:UpdateNPCPositions()
	for UUID, Data in pairs( RunningNPCsCache ) do
		local NPC_Data = ReplicatedNPCData[UUID]
		if not NPC_Data then
			warn('Could not find active NPC data with UUID; ', UUID)
			continue
		end

		local Model, Vector3Value = unpack(Data)
		Model.Humanoid.WalkSpeed = NPC_Data.WalkSpeed
	end
end

function NPCReplicatorController:OnNPCDataUpdated( NewReplicantData )
	if not NewReplicantData then
		return
	end
	ReplicatedNPCData = NewReplicantData

	local ActiveNPCUUIDs = {}

	-- load any un-loaded npcs into the system
	for NPC_UUID, NPC_Class in pairs( ReplicatedNPCData ) do
		local NPC_Data = RunningNPCsCache[NPC_UUID]
		if not NPC_Data then
			print('New NPC : ', NPC_UUID)

			-- find the npc reference model
			local StoredNPCReference = UnitModelCacheFolder:FindFirstChild(NPC_Class.OutfitReference)
			if not StoredNPCReference then
				warn('Could not find Stored NPC Reference - ' .. tostring(NPC_Class.OutfitReference))
				continue
			end

			-- create the fake npc model
			local Model = StoredNPCReference:Clone()
			Model.Name = NPC_UUID
			Model.PrimaryPart.Anchored = false

			-- for moving the npc
			local blankVector3Value = Instance.new('Vector3Value')
			blankVector3Value.Changed:Connect(function()
				Model.Humanoid:MoveTo( blankVector3Value.Value, workspace.Terrain )
			end)
			blankVector3Value.Parent = Model

			-- parent the npc
			Model.Parent = workspace

			-- add to cache
			RunningNPCsCache[NPC_UUID] = {Model, blankVector3Value}
			NPC_Data = RunningNPCsCache[NPC_UUID]
		end

		if NPC_Data then
			print(NPC_Class.Position)
			NPC_Data[1].Humanoid.WalkSpeed = NPC_Data.WalkSpeed
			NPC_Data[2].Value = NPC_Class.Position

			table.insert(ActiveNPCUUIDs, NPC_UUID)
		end
	end

	-- remove any un-loaded npcs
	for UUID, NPC_Data in pairs( RunningNPCsCache ) do
		if not table.find(ActiveNPCUUIDs, UUID) then
			local Model, CFrameValue = unpack(NPC_Data)
			Model:Destroy() -- npc model
			CFrameValue:Destroy() -- cframevalue
			RunningNPCsCache[UUID] = nil -- remove from cache
		end
	end

	NPCReplicatorController:UpdateNPCPositions()
end

function NPCReplicatorController:KnitStart()
	NPCReplicatorController:OnNPCDataUpdated(
		DataReplicateController:GetData( 'NPCReplicator', false )
	)

	DataReplicateController.OnUpdate:Connect(function(Category, Data)
		if Category == 'NPCReplicator' then
			print('update')
			NPCReplicatorController:OnNPCDataUpdated(Data)
		end
	end)
end

function NPCReplicatorController:KnitInit()
	DataReplicateController = Knit.GetController('DataReplicateController')
end

return NPCReplicatorController


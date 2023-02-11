local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Knit = require(ReplicatedStorage:WaitForChild("Knit"))

local EnemyReplicatorController = Knit.CreateController { Name = "EnemyReplicatorController" }

local ReplicatedModules = require(ReplicatedStorage:WaitForChild('Modules'))
local AnimationService = ReplicatedModules.Services.AnimationService

local RemoteService = ReplicatedModules.Services.RemoteService
local OnNPCCreated = RemoteService:GetRemote('OnNPCCreated', 'RemoteEvent', false)
local OnNPCUpdated = RemoteService:GetRemote('OnNPCUpdated', 'RemoteEvent', false)
local OnNPCRemoved = RemoteService:GetRemote('OnNPCRemoved', 'RemoteEvent', false)
local GetData = RemoteService:GetRemote('GetData', 'RemoteEvent', false)

local UnitModelCacheFolder = ReplicatedStorage:WaitForChild('UnitModelCache')

local AnimObjR15 = Instance.new('Animation')
AnimObjR15.AnimationId = 'rbxassetid://12453438064'
local AnimObjR6 = Instance.new('Animation')
AnimObjR6.AnimationId = 'rbxassetid://12453567049'

local NPCDataCache = {}
local NPCModelCache = {}

function EnemyReplicatorController:UpdateNPCProperty( UUID, Property, Value, ... )
	local Active_Data = NPCDataCache[UUID]
	if not Active_Data then
		return
	end

	Active_Data[Property] = Value

	local ModelData = NPCModelCache[UUID]
	if not ModelData then
		return
	end

	local Model, CFrameValue = unpack(ModelData)
	if Property == 1 then
		Model.Humanoid.WalkSpeed = Value
	elseif Property == 2 then
		CFrameValue.Value = CFrame.new( Value.X, 0, Value.Y )
	end
end

function EnemyReplicatorController:CreateNPC( NPC_Data )
	local NPC_UUID = NPC_Data.UUID
	if NPCDataCache[NPC_UUID] then
		return
	end
	NPCDataCache[NPC_UUID] = NPC_Data

	-- print('New NPC : ', NPC_UUID)
	-- find the npc reference model
	local StoredNPCReference = UnitModelCacheFolder:FindFirstChild(NPC_Data.OutfitReference)
	if not StoredNPCReference then
		warn('Could not find Stored NPC Reference - ' .. tostring(NPC_Data.OutfitReference))
		return
	end

	-- create the fake npc model
	local Model = StoredNPCReference:Clone()
	Model.Name = NPC_UUID
	Model.PrimaryPart.Anchored = false
	if NPC_Data.MoveToPosition then
		Model:PivotTo( CFrame.new( NPC_Data.MoveToPosition ) )
	end

	-- for moving the npc
	local blankCFrameValue = Instance.new('CFrameValue')
	blankCFrameValue.Changed:Connect(function()
		--Model:PivotTo( blankCFrameValue.Value )
		Model.Humanoid:MoveTo( blankCFrameValue.Value.Position, workspace.Terrain )
	end)

	if NPC_Data.MoveToPosition then
		blankCFrameValue.Value = CFrame.new( NPC_Data.MoveToPosition )
	end
	blankCFrameValue.Parent = Model

	-- parent the npc
	Model.Parent = workspace

	-- run animation
	Instance.new('Animator').Parent = Model.Humanoid
	--local LoadedAnim = Model.Humanoid.Animator:LoadAnimation(AnimObjR15)
	local LoadedAnim = Model.Humanoid.Animator:LoadAnimation(AnimObjR6)
	LoadedAnim.Looped = true
	Model.Humanoid.Running:Connect(function(speed)
		if speed == 0 then
			if LoadedAnim.IsPlaying then
				LoadedAnim:Stop()
			end
		else
			LoadedAnim:AdjustSpeed(speed/16)
			if not LoadedAnim.IsPlaying then
				LoadedAnim:Play()
			end
		end
	end)

	-- add to cache
	NPCModelCache[NPC_UUID] = {Model, blankCFrameValue}
end

function EnemyReplicatorController:RemoveNPC( NPC_UUID )
	-- clear class data
	NPCDataCache[NPC_UUID] = nil

	-- remove model data
	local Model_Data = NPCModelCache[NPC_UUID]
	if Model_Data then
		local Model, CFrameValue = unpack(Model_Data)
		Model:Destroy() -- npc model
		CFrameValue:Destroy() -- cframevalue
		NPCModelCache[NPC_UUID] = nil
	end
end

function EnemyReplicatorController:KnitStart()
	GetData.OnClientEvent:Connect(function(Data)
		for _, NPC_DATA in pairs(Data) do
			EnemyReplicatorController:CreateNPC(NPC_DATA)
		end
	end)
	GetData:FireServer()

	OnNPCCreated.OnClientEvent:Connect(function(NPC_Class)
		EnemyReplicatorController:CreateNPC(NPC_Class)
	end)

	OnNPCUpdated.OnClientEvent:Connect(function(UUID, Property, Value)
		EnemyReplicatorController:UpdateNPCProperty(UUID, Property, Value)
	end)

	OnNPCRemoved.OnClientEvent:Connect(function(UUID)
		EnemyReplicatorController:RemoveNPC(UUID)
	end)

	task.defer(function()
		local avtable = table.create(4, 50)
		while true do
			task.wait(0.1)

			local loudness = workspace.Chaos.PlaybackLoudness
			while #avtable > 4 do
				table.remove(avtable, #avtable)
			end
			table.insert(avtable, 1, loudness)

			local average = 0
			for _, v in ipairs( avtable ) do
				average += v
			end
			if #avtable > 0 then
				average /= #avtable
			end

			TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.075), {
				FieldOfView = math.clamp(70 + 30 * (loudness / 700), 70, 150)
			}):Play()

			if loudness < average-40 then
				continue
			end

			for _, Data in pairs( NPCModelCache ) do
				local Model, _ = unpack(Data)
				if math.random(1, 3) == 3 then
					Model.Humanoid.JumpHeight = 25 * (loudness / 250)
					Model.Humanoid.UseJumpPower = false
					Model.Humanoid.Jump = true
				end
			end

			local Col = game.Lighting.OutdoorAmbient
			local Vec = Vector3.new(Col.R + math.random(0, 1), Col.G + math.random(0, 1), Col.B + math.random(0, 1)).Unit * 255
			game.Lighting.OutdoorAmbient = Color3.fromRGB(Vec.X, Vec.Y, Vec.Z)
		end
	end)
end

function EnemyReplicatorController:KnitInit()

end

return EnemyReplicatorController



local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Knit"))

local DataReplicateController = Knit.CreateController { Name = "DataReplicateController" }
local DataService = false

local ActiveDataCache = { }

function DataReplicateController:GetData( Category, Yield )
	if ActiveDataCache[Category] then
		return ActiveDataCache[Category]
	end
	if Yield then
		local yieldStart = time()
		repeat task.wait(0.1)
		until ActiveDataCache[Category] or (time() - yieldStart) > 5
	end
	return ActiveDataCache[Category]
end

function DataReplicateController:KnitStart()
	DataService.DataUpdateSignal:Connect(function(Category, Data)
		-- print(Category, Data)
		ActiveDataCache[ Category ] = Data
		DataReplicateController.UpdateBindable:Fire( Category, Data )
	end)

	task.defer(function()
		DataService.DataUpdateSignal:Fire()
	end)
end

function DataReplicateController:KnitInit()
	DataService = Knit.GetService('DataReplicateService')

	DataReplicateController.UpdateBindable = Instance.new('BindableEvent')
	DataReplicateController.OnUpdate = DataReplicateController.UpdateBindable.Event
end

return DataReplicateController

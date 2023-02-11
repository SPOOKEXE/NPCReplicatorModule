local HttpService = game:GetService('HttpService')

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Knit"))

local DataReplicateService = Knit.CreateService { Name = "DataReplicateService", Client = {}, }
DataReplicateService.Client.DataUpdateSignal = Knit.CreateSignal()

local ActiveReplicationCache = { Public = {}, Private = {}, }
local comparisonCache = { } -- [category] = cache_string

function DataReplicateService:CheckCachedDataForUpdate()
	-- public data, replicates to all
	for publicCategory, publicData in pairs( ActiveReplicationCache.Public ) do
		local newEncodedString = HttpService:JSONEncode( publicData )
		if ( not comparisonCache[publicCategory] ) or comparisonCache[publicCategory] ~= newEncodedString then 
			-- update the data
			comparisonCache[publicCategory] = newEncodedString
			DataReplicateService:UpdateData( publicCategory, publicData, nil )
		end
	end

	-- private data, replicates to specific
	for _, replicationInfo in ipairs( ActiveReplicationCache.Private ) do
		local Category, Data, PlayerTable = unpack( replicationInfo )
		local newEncodedString = HttpService:JSONEncode( Data )
		local idIndex = Category..tostring(typeof(PlayerTable) == 'table' and DataReplicateService:TableToString(PlayerTable) or PlayerTable)
		if ( not comparisonCache[idIndex] ) or comparisonCache[idIndex] ~= newEncodedString then
			comparisonCache[idIndex] = newEncodedString
			DataReplicateService:UpdateData( Category, Data, PlayerTable )
		end
	end
end

function DataReplicateService:SetData(Category, Data, PlayerTable)
	if PlayerTable then
		-- private data for a select group of players
		table.insert(ActiveReplicationCache.Private, { Category, Data, PlayerTable })
	else
		-- public data
		ActiveReplicationCache.Public [ Category ] = Data
	end
end

function DataReplicateService:RemoveData( Category, ForThesePlayers )
	if ActiveReplicationCache.Public [ Category ] then
		ActiveReplicationCache.Public [ Category ] = nil
		DataReplicateService.Client.DataUpdateSignal:FireAll(Category, nil)
	end
	for index, replicationInfo in ipairs( ActiveReplicationCache.Private ) do
		if replicationInfo[1] == Category then
			if typeof(ForThesePlayers) == 'table' then
				-- TODO: check implementation
				for _, player in ipairs( ForThesePlayers ) do
					local plrindex = table.find(replicationInfo[3], player)
					if plrindex then
						table.remove(replicationInfo[3], plrindex)
					end
					DataReplicateService.Client.DataUpdateSignal:Fire(player, replicationInfo[1], nil)
				end
				if #replicationInfo[3] == 0 then
					table.remove(ActiveReplicationCache.Private, index)
				end
			else
				table.remove(ActiveReplicationCache.Private, index)
				for _, player in ipairs( replicationInfo[3] ) do
					DataReplicateService.Client.DataUpdateSignal:Fire(player, replicationInfo[1], nil)
				end
			end
		end
	end
end

function DataReplicateService:ClearData()
	-- clear public data
	for Category, _ in pairs( ActiveReplicationCache.Public ) do
		DataReplicateService.Client.DataUpdateSignal:FireAll(Category, nil)
	end
	ActiveReplicationCache.Public = {}
	-- clear private data
	for _, replicationInfo in pairs( ActiveReplicationCache.Private ) do
		for _, player in ipairs( replicationInfo[3] ) do
			DataReplicateService.Client.DataUpdateSignal:Fire(player, replicationInfo[1], nil)
		end
	end
	ActiveReplicationCache.Private = {}
	-- update data
	DataReplicateService:CheckCachedDataForUpdate()
end

function DataReplicateService:UpdateData( category, data, playerTable )
	if playerTable then
		for _, LocalPlayer in ipairs( playerTable ) do
			DataReplicateService.Client.DataUpdateSignal:Fire(LocalPlayer, category, data)
		end
	else
		DataReplicateService.Client.DataUpdateSignal:FireAll(category, data)
	end
end

function DataReplicateService:TableToString(Tbl)
	local Str = ""
	for i, v in pairs(Tbl) do
		Str = Str..tostring(i)..tostring(v)
	end
	return Str
end

function DataReplicateService:KnitStart()
	DataReplicateService.Client.DataUpdateSignal:Connect(function( LocalPlayer )
		for publicCategory, publicData in pairs( ActiveReplicationCache.Public ) do
			DataReplicateService.Client.DataUpdateSignal:Fire( LocalPlayer, publicCategory, publicData )
		end
		for _, replicationInfo in ipairs( ActiveReplicationCache.Private ) do
			local Category, Data, PlayerTable = unpack( replicationInfo )
			if table.find( PlayerTable, LocalPlayer ) then
				DataReplicateService.Client.DataUpdateSignal:Fire( LocalPlayer, Category, Data )
			end
		end
	end)

	task.defer(function()
		while true do
			task.wait(0.2)
			DataReplicateService:CheckCachedDataForUpdate()
		end
	end)
end

function DataReplicateService:KnitInit()

end

return DataReplicateService


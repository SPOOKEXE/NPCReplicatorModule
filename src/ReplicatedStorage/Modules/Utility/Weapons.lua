local CollectionService = game:GetService('CollectionService')

local Module = {}

-- Find the closest enemy model to a position (that is alive, also optionally given a custom max range)
function Module:GetClosestEnemyModel( Position, MaxRange )
	MaxRange = MaxRange or 9

	local ClosestModel, ClosestHumanoid, ClosestDistance = nil, nil, nil

	-- for each enemy model in the collection tag
	for _, Model in ipairs( CollectionService:GetTagged('EnemyModel') ) do
		local Humanoid = Model:FindFirstChildWhichIsA('Humanoid')

		-- if dead, skip it
		if (not Humanoid) or Humanoid.Health == 0 then
			continue
		end

		-- if further than max range, skip it
		local Distance = (Model:GetPivot().Position - Position).Magnitude
		if Distance > MaxRange then
			continue
		end

		-- if it is closer than the current closest then set it as the closest
		if ClosestModel then
			if Distance < ClosestDistance then
				ClosestModel = Model
				ClosestHumanoid = Humanoid
				ClosestDistance = Distance
			end
		else -- if no closest was set, this is the new closest
			ClosestModel = Model
			ClosestHumanoid = Humanoid
			ClosestDistance = Distance
		end
	end

	return ClosestModel, ClosestHumanoid, ClosestDistance
end

return Module

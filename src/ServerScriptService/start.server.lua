
local ReplicatedStorage = game:GetService('ReplicatedStorage')
require(ReplicatedStorage:WaitForChild('Modules'))

local ServerStorage = game:GetService('ServerStorage')
require(ServerStorage:WaitForChild('Modules'))
require(ServerStorage:WaitForChild('Services'))

local Knit = require(ReplicatedStorage.Knit)
Knit.Start():andThen(function()
	print("Knit Started")
end):catch(warn)

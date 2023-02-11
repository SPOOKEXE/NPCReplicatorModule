local LocalPlayer = game:GetService('Players').LocalPlayer
local ReplicatedStorage = game:GetService('ReplicatedStorage')
require(ReplicatedStorage:WaitForChild('Modules'))
require(LocalPlayer:WaitForChild('PlayerScripts'):WaitForChild('Modules'))
require(ReplicatedStorage:WaitForChild('Controllers'))

local Knit = require(ReplicatedStorage.Knit)
Knit.Start():andThen(function()
	print("Knit Started")
end):catch(warn)

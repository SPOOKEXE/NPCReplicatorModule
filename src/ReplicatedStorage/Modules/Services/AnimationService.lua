
local RunService = game:GetService('RunService')

local AnimationCache = {}

-- // Module // --
local Module = {}

function Module:GetAnimatorFromInstance(Parent)
	if Parent:IsA('Animator') then
		return Parent
	end
	local AnimatorInstance = Parent:FindFirstChildWhichIsA('Animator')
	if AnimatorInstance then
		return AnimatorInstance
	end
	local HumanoidOrController = Parent:FindFirstChildWhichIsA('Humanoid') or Parent:FindFirstChildWhichIsA('AnimationController')
	return HumanoidOrController and HumanoidOrController:FindFirstChildWhichIsA('Animator')
end

function Module:ConvertToAnimationObject(Value)
	if typeof(Value) == 'number' then
		Value = 'rbxassetid://'..Value
	end
	if typeof(Value) == 'string' then
		local animInstance = script:FindFirstChild( Value )
		if not animInstance then
			animInstance = Instance.new('Animation')
			animInstance.Name = Value
			animInstance.AnimationId = Value
			animInstance.Parent = script
		end
		Value = animInstance
	end
	if typeof(Value) == 'Instance' and Value:IsA('Animation') then
		return Value
	end
	return false
end

function Module:LoadAnimationToAnimator(Animator, AnimTrack, doNotLoadIfNull)
	if not Animator:GetAttribute('OnDestroyAnimClear') then
		Animator:SetAttribute('OnDestroyAnimClear', true)
		Animator.Destroying:Connect(function()
			AnimationCache[Animator] = nil
		end)
	end
	if not AnimationCache[Animator] then
		AnimationCache[Animator] = {}
	end
	local activeTrack = AnimationCache[Animator][AnimTrack]
	if (not activeTrack) and (not doNotLoadIfNull) then
		activeTrack = Animator:LoadAnimation(AnimTrack)
		AnimationCache[Animator][AnimTrack] = activeTrack
	end
	return activeTrack
end

function Module:LoadAnimationToCharacter(Character, Animation, doNotLoadIfNull)
	local Animator = Character and Module:GetAnimatorFromInstance(Character)
	local AnimationObject = Animation and Module:ConvertToAnimationObject(Animation)
	if Animator and AnimationObject then
		return Module:LoadAnimationToAnimator(Animator, AnimationObject, doNotLoadIfNull)
	end
	return false
end

if not RunService:IsServer() then

	local LocalPlayer = game:GetService('Players').LocalPlayer

	function Module:LoadAnimationToLocal(Animation, doNotLoadIfNull)
		return Module:LoadAnimationToCharacter(LocalPlayer.Character, Animation, doNotLoadIfNull)
	end

	function Module:PlayAnimationTrackWithPropertieS(AnimTrack, Properties)
		Properties = Properties or {}
		if Properties.Speed then
			AnimTrack:AdjustSpeed(Properties.Speed)
		else
			AnimTrack:AdjustSpeed(1)
		end
		if Properties.Weight then
			AnimTrack:AdjustWeight(Properties.Weight)
		else
			AnimTrack:AdjustWeight(1)
		end
		AnimTrack:Play(Properties.FadeInTime)
	end

	function Module:PlayLocalAnimation(Animation, Properties)
		local AnimTrack = Module:LoadAnimationToLocal(Animation, false)
		if AnimTrack then
			Module:PlayAnimationTrackWithPropertieS(AnimTrack, Properties)
		end
		return AnimTrack
	end

	function Module:StopLocalAnimation(Animation, FadeOutTime)
		local AnimTrack = Module:LoadAnimationToLocal(Animation, true)
		if AnimTrack then
			AnimTrack:Stop(FadeOutTime)
		end
		return AnimTrack
	end

end

return Module

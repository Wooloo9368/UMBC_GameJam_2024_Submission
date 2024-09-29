local tool = script.Parent
local invEvent = game.ReplicatedStorage.InventoryEvent
tool.Handle:WaitForChild("TouchInterest"):Destroy()

tool.ClickDetector.MouseClick:Connect(function(plr)
	tool.ClickDetector:Destroy()

	invEvent:FireClient(plr, tool.Name)
	
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://73227894342457"

	local animationTrack = plr.Character:FindFirstChild("Humanoid"):LoadAnimation(animation)
	
	animationTrack:GetMarkerReachedSignal("pulled"):Connect(function(paramString)
		tool.Handle.Anchored = false
		tool.Parent = plr.Character
	end)
	animationTrack:GetMarkerReachedSignal("pocketed"):Connect(function(paramString)
		tool:Destroy()
	end)
	
	animationTrack:Play()
end)
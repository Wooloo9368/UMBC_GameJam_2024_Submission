wait(1)
local plr = game.Players.LocalPlayer
local pStatsModule = require(game.ReplicatedStorage.playerStats)
local pStats = pStatsModule[plr]
local invEvent = game.ReplicatedStorage.InventoryEvent

local size = 0
local gui = script.Parent

local opened = false

local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local numberValue = Instance.new("NumberValue", game.Workspace)

local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local goal = { Value = 250 }

local tween = TweenService:Create(numberValue, tweenInfo, goal)

local function tweenNumber()
	tween:Cancel()
	numberValue.Value = 0
	tween:Play()
	numberValue.Changed:Connect(function(property)
		size = numberValue.Value
	end)
end

local function openInv(open)
	local count = #pStats.Inventory
	if not count then
		return
	end
	for i,v in gui.Background:GetChildren() do
		if v.Name == "Clone" then
			v:Destroy()
		end
	end
	if open then
		for i=0, count-1 do
			local clone = gui.Background.ViewportFrame:Clone()
			clone.Name = "Clone"
			clone.Parent = gui.Background
			clone.AnchorPoint = Vector2.new(.5,0,.5,0)
		end
		tweenNumber()
		opened = true
		for i, v in gui.Background:GetChildren() do
			if v.Name == "Clone" then
				coroutine.resume(coroutine.create(function()
					while opened do
						v.Position = UDim2.new(.5, (math.sin(math.rad((360/count)*i)))*size, .3, (math.cos(math.rad((360/count)*i)))*size)
						task.wait()
					end
				end))
				v.Visible = true
			end
		end
	else
		size = 0
		opened = false
		for i, v in gui.Background:GetChildren() do
			if v.Name == "Clone" then
				v.Visible = false
			end
		end
	end
end

UIS.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.E then
		openInv(true)
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.E then
		openInv(false)
	end
end)

invEvent.OnClientEvent:Connect(function(name)
	table.insert(pStats.Inventory, name)
end)
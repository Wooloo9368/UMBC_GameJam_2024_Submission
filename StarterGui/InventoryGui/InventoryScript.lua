wait(1)
local plr = game.Players.LocalPlayer
local mouse = plr:GetMouse()
local pStatsModule = require(game.ReplicatedStorage.playerStats)
local pStats = pStatsModule[plr]
local invEvent = game.ReplicatedStorage.InventoryEvent

local size = 0
local selected = nil
local gui = script.Parent
local tooltip = gui.Tooltip
tooltip.Visible = false
gui.Background.ViewportFrame.Visible = false

local co = nil

local canOpen = true

local opened = false

local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local numberValue = Instance.new("NumberValue", game.Workspace)

local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local goal = { Value = 150 }

local tween = TweenService:Create(numberValue, tweenInfo, goal)

local function tweenNumber()
	tween:Cancel()
	numberValue.Value = 0
	tween:Play()
	numberValue.Changed:Connect(function(property)
		size = numberValue.Value
	end)
end

local function setStats(flowerName)
	gui.Equip:Play()
	if flowerName == "Sunflower" then
		pStats.Jumps = 1
	end
	if flowerName == "LilyOfTheValley" then
		pStats.CanGrapple = true
	end
	if flowerName == "Dandelion" then
		pStats.Gravity = 100
	end
end

local function remStats(flowerName)
	if flowerName == "Sunflower" then
		pStats.Jumps = 0
	end
	if flowerName == "LilyOfTheValley" then
		pStats.CanGrapple = false
	end
	if flowerName == "Dandelion" then
		pStats.Gravity = 196
	end
end

local function openInv(open)
	local inv = pStats.Inventory
	local count = #inv
	if not count then
		return
	end
	for i,v in gui.Background:GetChildren() do
		if v.Name ~= "ViewportFrame" then
			v:Destroy()
		end
	end
	if open then
		selected = nil
		for i,v in inv do
			local clone = gui.Background.ViewportFrame:Clone()
			clone.Name = v
			clone.Parent = gui.Background
			clone.AnchorPoint = Vector2.new(.5,0,.5,0)
			
			local displayClone = game.ReplicatedStorage.Flowers[v]:Clone()
			displayClone.Parent = clone
		end
		tweenNumber()
		opened = true
		for i, v in gui.Background:GetChildren() do
			if v.Name ~= "ViewportFrame" then
				coroutine.resume(coroutine.create(function()
					while opened do
						if selected == v.Name then
							v.BackgroundColor3 = Color3.new(1, 1, 1)
						else
							v.BackgroundColor3 = Color3.new(0, 0, 0)
						end
						v.Position = UDim2.new(.5, (math.sin(math.rad((360/count)*i)))*size, .3, (math.cos(math.rad((360/count)*i)))*size)
						task.wait()
					end
				end))
				v.MouseEnter:Connect(function()
					gui.Click:Play()
					selected = v.Name
					v.MouseMoved:Connect(function()
						tooltip.Text = v.Name.." : "..v[v.Name].TT.Value
						tooltip.Visible = true
						v.MouseLeave:Connect(function()
							tooltip.Text = ""
							tooltip.Visible = false
						end)
					end)
				end)
				v.Visible = true
			end
		end
		co = game:GetService("RunService").Stepped:Connect(function()
			tooltip.Position = UDim2.new(0, mouse.X, 0, mouse.Y)
		end)
	else
		tooltip.Visible = false
		if co then
			co:Disconnect()
		end
		size = 0
		opened = false
		if selected then
			if pStats.EquippedItem ~= nil then
				local eqItem = plr.Character[pStats.EquippedItem]
				if eqItem then
					eqItem:Destroy()
				end
				remStats(pStats.EquippedItem)
			end
			
			pStats.EquippedItem = selected
			setStats(pStats.EquippedItem)
			local headClone = game.ReplicatedStorage.Flowers[selected]:Clone()
			headClone.Parent = plr.Character
			headClone:ScaleTo(0.8)
			
			local weld = Instance.new("Weld")
			weld.Part0 = plr.Character.Head
			weld.Part1 = headClone.Handle
			weld.C0 = CFrame.new(0,1.5,0) * CFrame.Angles(0,math.rad(-90),0)
			weld.Parent = headClone
			
			plr.Character.Head.HatChangePoint.SmokePuff:Emit(math.random(20,30))
		end
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

plr.Character:FindFirstChild("Humanoid").Died:Connect(function()
	if pStats.EquippedItem ~= nil then
		remStats(pStats.EquippedItem)
		print("removed")
		print(pStats.EduippedItem)
		pStats.EquippedItem = nil
	end
end)

local planted = false


game.Workspace.SoilPlant.ClickDetector.MouseClick:Connect(function(splr)
	if splr == plr and planted == false then
		planted = true
		plr.Character.Humanoid.AutoRotate = false
		plr.Character.HumanoidRootPart.Anchored = true
		plr.Character:SetPrimaryPartCFrame(workspace.charpos.CFrame)
		local animation = plr.Character.Humanoid:LoadAnimation(script.Plant)
		animation:Play()
		
		local model = game.ReplicatedStorage.Flowers.Sunflower:Clone()
		
		local weld = Instance.new("Weld")
		weld.Part0 = plr.Character["Right Arm"]
		weld.Part1 = model.Handle
		weld.C0 = CFrame.new(0,-1,0) * CFrame.Angles(0,math.rad(-90),math.rad(90))
		weld.Parent = model
		
		animation:GetMarkerReachedSignal("takeout"):Once(function()
			model.Parent = plr.Character
			
			local sfx = game.ReplicatedStorage.WallrunDetachsfx:Clone()
			sfx.Parent = plr.Character.HumanoidRootPart
			sfx:Play()
			game.Debris:AddItem(sfx,.5)
		end)
		
		animation:GetMarkerReachedSignal("place"):Once(function()
			model.Handle.Anchored = true
			weld:Destroy()
			model.PrimaryPart = model.Handle
			model:SetPrimaryPartCFrame(game.Workspace.FlowerPos.CFrame)
			
			local sfx = game.ReplicatedStorage.plant:Clone()
			sfx.Parent = game.Workspace.FlowerPos
			sfx:Play()
			game.Debris:AddItem(sfx,.5)
			
			game.Workspace.FlowerPos.PlantParticle:Emit(math.random(25))
			
			plr.Character.Humanoid.AutoRotate = true
			plr.Character.HumanoidRootPart.Anchored = false
			
			plr.PlayerGui["End Screen"].Enabled = true
			wait(5)
			plr.PlayerGui["End Screen"].Enabled = false
		end)
	end
end)
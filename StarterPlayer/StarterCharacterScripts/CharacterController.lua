wait(1)
local plr = game.Players.LocalPlayer
plr:SetAttribute("CameraTilt",0)
local char = plr.Character
local hrp = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")

local camera = game.Workspace.CurrentCamera

local mouse = plr:GetMouse()

local playerDataContainer = require(game.ReplicatedStorage.playerStats)
local playerdata = playerDataContainer[plr]
print(playerdata)

local RunTrack = hum:LoadAnimation(script.RunAnimation)

local activeInputs = {}

local currentAction = "None"

local uis = game:GetService("UserInputService")

local bv = Instance.new("BodyVelocity")
bv.MaxForce = Vector3.new(1,1,1) * 25000
bv.P = 25000
bv.Velocity = Vector3.new(0,0,0)

local bg = Instance.new("BodyGyro")
bg.MaxTorque = Vector3.new(0,25000,0)
bg.P = 25000
bg.D = 25

local wallCheckParams = RaycastParams.new()
wallCheckParams.FilterType = Enum.RaycastFilterType.Exclude
wallCheckParams.IgnoreWater = true
wallCheckParams.RespectCanCollide = true
wallCheckParams.FilterDescendantsInstances = {char}

function rotateVectorAround( v, amount, axis )
	return CFrame.fromAxisAngle(axis, amount):VectorToWorldSpace(v)
end

function CalculateInitalWallRunDirection(Direction,WallNormal)
	local ForceCrossVector = WallNormal:Cross(Direction)
	ForceCrossVector = -(WallNormal:Cross(ForceCrossVector))
	return ForceCrossVector
end

local DoubleJumpData = {
	["Jumps"] = 0;
}

local WallRunData = {
	["Exclude"] = {
		
	};
	["CurrentWall"] = nil;
	["CurrentDirection"] = nil;
	["Speed"] = nil
}

local GrappleData = {
	["Activated"] = false;
	["HighlightedPoint"] = nil;
	["StartxRad"] = 0;
	["StartyRad"] = 0;
	["StartzRad"] = 0;
}

local GrappleHighlight = game.ReplicatedStorage.GrappleHighlight

local wallRunCheck = function()
	if char.Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
		local referenceVector = hrp.CFrame.LookVector
		local leftVector = rotateVectorAround(referenceVector,math.rad(90),Vector3.new(0,1,0))
		local rightVector = rotateVectorAround(referenceVector,math.rad(-90),Vector3.new(0,1,0))

		local leftCast = workspace:Raycast(hrp.Position,leftVector * 3,wallCheckParams)
		local rightCast = workspace:Raycast(hrp.Position,rightVector * 3,wallCheckParams)
		
		if leftCast and WallRunData["Exclude"][leftCast.Instance] and tick() - WallRunData["Exclude"][leftCast.Instance] < .5 then
			leftCast = nil
		end
		if rightCast and WallRunData["Exclude"][rightCast.Instance] and tick() - WallRunData["Exclude"][rightCast.Instance] < .5 then
			rightCast = nil
		end
		
		local result = leftCast or rightCast

		if result then
			local dominateCast = nil
			local Direction = nil
			
			if leftCast == nil then
				dominateCast = rightCast
				Direction = "right"
			elseif rightCast == nil then
				dominateCast = leftCast
				Direction = "left"
			else
				local rdist = (hrp.Position - rightCast.Position).Magnitude 
				local ldist = (hrp.Position - rightCast.Position).Magnitude
				
				if rdist < ldist then
					dominateCast = rightCast
					Direction = "right"
				else
					dominateCast = leftCast
					Direction = "left"
				end
			end
			return true, {["cast"] = dominateCast,["direction"] = Direction}
		end
	end
	return false
end

function CalculateGrappleForceVector(GrappleVector,MovementVector)
	local ForceCrossVector = GrappleVector:Cross(MovementVector)
	return ForceCrossVector
	
end

local part = Instance.new("Part")
part.Material = Enum.Material.Neon
part.Anchored = true
part.CanCollide = false
part.Parent = workspace
part.Size = Vector3.new(.1,.1,5)

local ActionFunctions = {
	["WallRun"] = {
		["Data"] = WallRunData;
		["Start"] = function(data)
			
			local ForceCrossVector = CalculateInitalWallRunDirection(hrp.CFrame.LookVector,data.cast.Normal)
			
			bv.Velocity = ForceCrossVector * hum.WalkSpeed
			bv.Parent = hrp
			
			bg.CFrame = CFrame.new(Vector3.new(),ForceCrossVector)
			bg.Parent = hrp
			
			hum.AutoRotate = false
			
			WallRunData.CurrentCast = data.cast
			WallRunData.CurrentWall = data.cast.Instance
			WallRunData.CurrentDirection = data.direction
			WallRunData.Speed = hum.WalkSpeed
		end,
		["Stop"] = function()
			WallRunData.Exclude[WallRunData.CurrentWall] = tick()
			
			bv.Parent = nil
			bg.Parent = nil
			
			hum.AutoRotate = true
			
			plr:SetAttribute("CameraTilt",0)
			
			local bv = Instance.new("BodyVelocity")
			bv.Velocity = (WallRunData.CurrentCast.Normal + hrp.CFrame.LookVector).Unit * 40
			bv.Parent = hrp
			bv.MaxForce = Vector3.new(25000,25000,25000)
			bv.P = 25000
			game.Debris:AddItem(bv,.1)
		end,
		["OnStep"] = function()
			
			local result, data = wallRunCheck()
			
			if data and data.cast.Instance ~= WallRunData.CurrentWall then
				WallRunData.Exclude[WallRunData.CurrentWall] = tick()
				WallRunData.CurrentWall = data.cast.Instance
				
				local ForceCrossVector = CalculateInitalWallRunDirection(hrp.CFrame.LookVector,data.cast.Normal)
				bv.Velocity = bv.Velocity.Magnitude * ForceCrossVector
				bg.CFrame = CFrame.new(Vector3.new(),ForceCrossVector)
			end
			
			if data and data.direction == "left" then
				plr:SetAttribute("CameraTilt",-15)
			elseif data then
				plr:SetAttribute("CameraTilt",15)
			end
			
			bv.Velocity = bv.Velocity.Magnitude * (bv.Velocity.Unit + Vector3.new(0,-.01,0)).Unit
			
			WallRunData.Speed = bv.Velocity.Magnitude
			
			if result == false or bv.Velocity.Unit.Y < -.65 or hum:GetState() == Enum.HumanoidStateType.Running then
				WallRunData.Exclude[WallRunData.CurrentWall] = tick()
				
				bv.Parent = nil
				bg.Parent = nil

				hum.AutoRotate = true
				
				plr:SetAttribute("CameraTilt",0)
			end
		end,
		["Check"] = wallRunCheck
	};
	["DoubleJump"] = {
		["Data"] = DoubleJumpData;
		["Landed"] = function()
			DoubleJumpData.Jumps = 0
		end;
		["Start"] = function(data)
			DoubleJumpData.Jumps += 1
			local nbv = Instance.new("BodyVelocity")
			nbv.Parent = hrp
			nbv.MaxForce = Vector3.new(0,25000,0)
			nbv.P = 25000
			nbv.Velocity = Vector3.new(0,hum.JumpPower,0) -- Modifiy to characters Jump Power
			game.Debris:AddItem(nbv,.05)
			
		end,
		["Check"] = function()
			if char.Humanoid:GetState() == Enum.HumanoidStateType.Freefall and DoubleJumpData.Jumps < playerdata.Jumps then
				return true
			end
			return false
		end
	};
	["Run"] = {
		["Start"] = function()
			print(playerdata)
			RunTrack:Play()
			hum.WalkSpeed = playerdata.Runspeed
			workspace.Gravity = playerdata.Gravity
		end,
		["RunStop"] = function()
			RunTrack:Stop()
			hum.WalkSpeed = playerdata.Walkspeed
		end,
		["Check"] = function(str)
			if str and hum:GetState() == Enum.HumanoidStateType.Running then
				return true
			end
			return false
		end
	};
	["Grapple"] = {
		["Data"] = GrappleData;
		["Check"] = function()
			
		end,
		["OnStepRegardless"] = function()
			if GrappleData.Activated == false and playerdata.CanGrapple == true then
				
				local LowestDistance = 60
				local GrapplePoint = nil
				
				for i , v in pairs(game.Workspace.GrapplePoints:GetChildren()) do
					local position , onscreen = camera:WorldToScreenPoint(v.Position)
					local cast = workspace:Raycast(hrp.Position,(v.Position - hrp.Position).Unit * (v.Position - hrp.Position).Magnitude,wallCheckParams)
					if onscreen and cast == nil then
						local mousePosition = Vector2.new(mouse.X,mouse.Y)
						local screenPosition = Vector2.new(position.X,position.Y)
						
						local distance = (screenPosition - mousePosition).Magnitude
						if distance < LowestDistance then
							GrapplePoint = v
							LowestDistance = distance
						end
					end
				end
				
				if GrapplePoint then
					GrappleData.HighlightedPoint = GrapplePoint
					GrappleHighlight.Parent = GrapplePoint
				else
					GrappleData.HighlightedPoint = nil
					GrappleHighlight.Parent = game.ReplicatedStorage
				end
			else
				
			end
		end,
		["MouseClick"] = function()
			if GrappleData.HighlightedPoint and playerdata.CanGrapple == true then
				
				
				
				local GrapplePosition = GrappleData.HighlightedPoint.Position
				
				local GrappleDirection = (GrapplePosition - hrp.Position).Unit
				local GrappleDistance = (GrapplePosition - hrp.Position).Magnitude
				
				local cast = workspace:Raycast(hrp.Position,GrappleDirection * GrappleDistance,wallCheckParams)
				
				if cast ~= nil then
					if cast.Instance ~= GrappleData.HighlightedPoint then
						return
					end
				end
				
				bv.Velocity = GrappleDirection * 2 * GrappleDistance
				bv.MaxForce = Vector3.new(25000,25000,25000)
				bv.P = 25000
				bv.Parent = char.HumanoidRootPart
				
				
				
				GrappleData.Activated = true 
				
				GrappleData.HighlightedPoint = nil
				GrappleHighlight.Parent = game.ReplicatedStorage
				
				wait(.5)
				
				bv.Parent = nil
				
				local bv = Instance.new("BodyVelocity")
				bv.Velocity = Vector3.new(0,50,0)
				bv.MaxForce = Vector3.new(0,25000,0)
				bv.P = 25000
				bv.Parent = char.HumanoidRootPart
				
				game.Debris:AddItem(bv,.1)
				
				GrappleData.Activated = false 
			end
		end,
	}
}

function GetAction()
	for Action , tab in pairs(ActionFunctions) do
		local result , extraData = tab.Check()
		if result == true then
			return Action , extraData
		end
	end
end

uis.InputBegan:Connect(function(input,gpe)
	if gpe then return end
	
	local keyString = uis:GetStringForKeyCode(input.KeyCode)
	
	if input.KeyCode == Enum.KeyCode.Space and currentAction == "None" then
		
		local Action, extra = GetAction()
		
		currentAction = Action
		
		if ActionFunctions[Action] then
			if ActionFunctions[Action].Start then
				ActionFunctions[Action].Start(extra)
			end
		end
	elseif input.KeyCode == Enum.KeyCode.LeftShift then
		if ActionFunctions.Run.Check("") then
			ActionFunctions.Run.Start()
		end
	elseif input.KeyCode == Enum.KeyCode.E then
		uis.MouseBehavior = Enum.MouseBehavior.Default
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		for action , tab in pairs(ActionFunctions) do
			if tab.MouseClick then
				tab.MouseClick()
			end
		end
	end
	
	activeInputs[keyString] = tick()
end)

uis.InputEnded:Connect(function(input,gpe)
	if gpe then return end
	
	if input.KeyCode == Enum.KeyCode.Space then
		
		if ActionFunctions[currentAction] then
			if ActionFunctions[currentAction].Stop then
				ActionFunctions[currentAction].Stop()
			end
		end
		
		bv.Parent = nil
		currentAction = "None"
	elseif input.KeyCode == Enum.KeyCode.LeftShift then
		ActionFunctions.Run.RunStop()
	elseif input.KeyCode == Enum.KeyCode.E then
		uis.MouseBehavior = Enum.MouseBehavior.LockCenter
	end
end)

game["Run Service"].RenderStepped:Connect(function()
	if ActionFunctions[currentAction] then
		if ActionFunctions[currentAction].OnStep then
			ActionFunctions[currentAction].OnStep()
		end
	end
	for action , tab in pairs(ActionFunctions) do
		if tab.OnStepRegardless then
			tab.OnStepRegardless()
		end
	end
end)

char.Humanoid.StateChanged:Connect(function(oldState,newState)
	if newState == Enum.HumanoidStateType.Landed then
		for Action, dict in pairs(ActionFunctions) do
			if dict.Landed then
				dict.Landed()
			end
		end
	end
end)
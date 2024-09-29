local camera = game.Workspace.CurrentCamera
local plr = game.Players.LocalPlayer
local char = plr.Character
local hrp = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")

local mouse = plr:GetMouse()

camera.CameraType = Enum.CameraType.Scriptable
camera.CameraSubject = hum
camera.CFrame += hrp.Position + Vector3.new(0,15,0)

local uis = game:GetService('UserInputService')
uis.MouseBehavior = Enum.MouseBehavior.LockCenter

local orientationx = 0
local orientationy = 0

local distance = 10
local maxdistance = 15
local mindistance = 5

local castParams = RaycastParams.new()
castParams.FilterType = Enum.RaycastFilterType.Exclude
castParams.RespectCanCollide = true
castParams.FilterDescendantsInstances = {char}

local GhettoTweenData = {
	["Startp"] = 0;
	["Endp"] = 0;
	["Duration"] = .5;
	["StartTick"] = 0;
}

local function GhettoTween()
	local startp = GhettoTweenData.Startp
	local endp = GhettoTweenData.Endp
	local duration = GhettoTweenData.Duration
	local startTick = GhettoTweenData.StartTick
	
	local difference = endp-startp
	local x = (tick() - startTick)/duration
	return startp + (math.min(math.pow(x,2),1) * difference)
end

game["Run Service"].RenderStepped:Connect(function()
	
	--local EndPosition = hrp.Position + Vector3.new(0,3,0)
	
	local CameraCenteredPosition = (hrp.Position + Vector3.new(0,3,0))
	
	local xpos = math.cos(math.rad(orientationx))
	local zpos = math.sin(math.rad(orientationx))
	
	local ypos = math.rad(orientationy)   --math.clamp(math.cos(math.rad(orientationy) % (2 * math.pi)),-1,1)
	
	local RealCFrame = CFrame.new(hrp.Position + Vector3.new(xpos * distance * math.cos(ypos) ,3 + ypos * distance,zpos * distance * math.cos(ypos)),hrp.Position + Vector3.new(0,3,0))
	
	local castDirection = (RealCFrame.Position - CameraCenteredPosition).Unit
	
	local cast = workspace:Raycast(hrp.Position + Vector3.new(0,3,0), castDirection * distance,castParams)
	
	if cast then
		
		local distanceBetweenPoints = (cast.Position - CameraCenteredPosition).Magnitude
		local direction = (CameraCenteredPosition - cast.Position).Unit
		
		RealCFrame = CFrame.new((hrp.Position + Vector3.new(0,3,0)) + (-direction * (distanceBetweenPoints - .2)),hrp.Position + Vector3.new(0,3,0)) * CFrame.Angles(0,0,math.rad(GhettoTween()))
	end
	
	camera.CFrame = RealCFrame * CFrame.Angles(0,0,math.rad(GhettoTween()))
	
	local speed = hrp.Velocity.Magnitude
	local fov = math.clamp(70 + ((speed - 16) / 10),70,120)
	
	camera.FieldOfView = fov
end)

uis.InputChanged:Connect(function(input,gpe)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		orientationx += input.Delta.X * uis.MouseDeltaSensitivity
		orientationy = math.clamp(orientationy + input.Delta.Y * uis.MouseDeltaSensitivity,-70,70)
	end
end)

mouse.WheelForward:Connect(function()
	distance = math.max(mindistance , distance - 2)
end)

mouse.WheelBackward:Connect(function()
	distance = math.min(maxdistance , distance + 2)
end)

plr:SetAttribute("CameraTilt",0)

plr:GetAttributeChangedSignal("CameraTilt"):Connect(function()
	GhettoTweenData = {
		["Startp"] = GhettoTween();
		["Endp"] = plr:GetAttribute('CameraTilt');
		["Duration"] = .5;
		["StartTick"] = tick();
	}
	print(GhettoTweenData)
end)
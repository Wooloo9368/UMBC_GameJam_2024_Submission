local notifEvent = game.ReplicatedStorage.NotificationEvent
local gui = script.Parent
gui.Frame.Box.Visible = false

notifEvent.OnClientEvent:Connect(function(title, body, _color)
	local clone = gui.Frame.Box:Clone()
	clone.Visible = true
	clone.Parent = gui.Frame
	
	clone.Title.Text = title
	clone.Body.Text = body
	
	if _color then	
		clone.Title.BackgroundColor3 = _color
		clone.Body.BackgroundColor3 = _color
	end
	
	gui.NotificationSound:Play()
	
	game.Debris:AddItem(clone, 8)
end)
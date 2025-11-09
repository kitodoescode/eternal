-- custom version of ui lib
local ui = loadstring(game:HttpGet("https://raw.githubusercontent.com/kitodoescode/Bracket/main/BracketV34.lua"))()

-- game objects/services
local players = game:GetService("Players")
local runservice = game:GetService("RunService")
local camera = workspace.CurrentCamera

-- our globals vars
_G.esp_enabled = true

-- our local vars
local esp_objects = {}
local date = os.date("%d-%m-%y")
local last

local window = ui:Window({Name="eternal | @kitodoescode"}) do
	local watermark = window:Watermark({
		Title="eternal | @kitodoescode | " .. date,
		Enabled=true,
		Fixed=true, -- custom
	})

	last = tick()
	runservice.Heartbeat:Connect(function() -- update date ( checking every one second )
    	local curr = tick()
    	if curr - last >= 1 then
    	    date = os.date("%d-%m-%y")
    	    watermark.Title = "eternal | @kitodoescode | " .. date
    	end
	end)

    
end

-- helper for drawing objects
local function draw(type, options)
    local obj = Drawing.new(type)
    for n, v in pairs(options) do
        obj[n] = v
    end
    return obj
end

-- helper for w2s obv
local function world_to_screen(world) 
	return camera:WorldToViewportPoint(world)
end

-- function to add esp objects and connections on a player
local function add_player_esp(player)
    if esp_objects[player] then return end

    local box = draw("Square", 
	    {
			Visible = false,
			Color = Color3.new(1, 1, 1),
			Size = Vector2.new(0, 0),
			Thickness = 1,
			ZIndex = 2,
		}
	)

	local box_outline = draw("Square", 
	    {
			Visible = false,
			Color = Color3.new(0, 0, 0),
			Size = Vector2.new(0, 0),
			Thickness = 3,
		}
	)

	local name = draw("Text",
		{
			Visible = false,
			Color = Color3.new(1, 1, 1),
			Text = player.Name,
			Center = true,
			Outline = true,
			OutlineColor = Color3.new(0, 0, 0),
		}
	)

	local distance = draw("Text",
		{
			Visible = false,
			Color = Color3.new(1, 1, 1),
			Text = "[ 0.0m ]",
			Center = true,
			Outline = true,
			OutlineColor = Color3.new(0, 0, 0),
		}
	)

	local objects = { box = box, box_outline = box_outline, name = name, distance = distance }

	local connection = runservice.RenderStepped:Connect(function()
	    local char = player.Character
		if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Head") then
			objects.box.Visible = false
			objects.box_outline.Visible = false
			objects.name.Visible = false
			objects.distance.Visible = false
			return
		end

		local hrp = char:FindFirstChild("HumanoidRootPart")
		local head = char:FindFirstChild("Head")

		local _, visible = world_to_screen(hrp.Position)
		if not visible then
			objects.box.Visible = false
			objects.box_outline.Visible = false
			objects.name.Visible = false
			objects.distance.Visible = false
			return
		end

		local head_pos, _ = world_to_screen(head.Position + Vector3.new(0, 0.5, 0))
		local hrp_pos, _ = world_to_screen(hrp.Position - Vector3.new(0, 3, 0))

		local w = math.abs(head_pos.y - hrp_pos.y) * 1.05
		local h = math.abs(head_pos.y - hrp_pos.y) * 1.25

        local top_left = Vector2.new(head_pos.x - (w / 2), hrp_pos.y - (h * 0.925))
        
		objects.box.Size = Vector2.new(w, h)
        objects.box.Position = top_left
        objects.box.Visible = true

		objects.box_outline.Size = Vector2.new(w, h)
        objects.box_outline.Position = top_left
        objects.box_outline.Visible = true

		local top_center = Vector2.new(head_pos.x, top_left.y - 20)
		objects.name.Position = top_center
		objects.name.Visible = true

		local bottom_center = Vector2.new(head_pos.x, top_left.y + h + 10)
		local our_pos
		if not players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
			our_pos = workspace.CurrentCamera.CFrame.Position
		else
			our_pos = players.LocalPlayer.Character.HumanoidRootPart.Position
		end
		objects.distance.Text = string.format("[ %.1fm ]", (our_pos - hrp.Position).Magnitude)
		objects.distance.Position = bottom_center
		objects.distance.Visible = true
	end)

	local connections = { connection }

	esp_objects[player] = { objects = objects, connections = connections }
end

-- function to remove esp objects and connections from player
local function remove_player_esp(player)
    local idk = esp_objects[player]
	if not idk then return end

    for _, con in pairs(idk.connections) do
		if con.Connected then
			con:Disconnect()
		end
	end

    for _, obj in pairs(idk.objects) do
		obj:Destroy()
	end

	idk = nil
end

-- adding esp objects and connections on all current player
for _, p in pairs(players:GetPlayers()) do
    add_player_esp(p)
end

-- add esp objects and connections on any new player that joined
players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Wait()
    add_player_esp(player)
end)

-- remove esp objects and connections from any new player that left
players.PlayerRemoving:Connect(function(player) 
   remove_player_esp(player)
end)

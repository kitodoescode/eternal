-- stop if already running, prevents lag ofc.
if _G.eternal_esp_loaded then
        print("eternal is already open!")
    return
end
_G.eternal_esp_loaded = true

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

local lp = players.LocalPlayer
local lp_char = lp.Character

local bone_connections_r6 = {
    {"Head", "Torso"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Leg"},
    {"Torso", "Left Leg"}
}

local bone_connections_r15 = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LowerTorso", "RightUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
    {"UpperTorso", "LeftUpperArm"},
    {"UpperTorso", "RightUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"}
}

local all_bones_r6 = {
    "Head",
    "Torso",
    "Right Arm",
    "Left Arm",
    "Right Leg",
    "Left Leg"
}

local all_bones_r15 = {
    "Head",
    "UpperTorso",
    "LowerTorso",
    "RightUpperLeg",
    "LeftUpperLeg",
    "RightLowerLeg",
    "LeftLowerLeg",
    "RightFoot",
    "LeftFoot",
    "RightUpperArm",
    "LeftUpperArm",
    "RightLowerArm",
    "LeftLowerArm",
    "RightHand",
    "LeftHand"
}

-- check if window already exists
if not _G.eternal_window then
    _G.eternal_window = ui:Window({Name = "eternal | @kitodoescode"})
end
local window = _G.eternal_window
do
    local watermark =
        window:Watermark(
        {
            Title = "eternal | @kitodoescode | " .. date,
            Enabled = true,
            Fixed = true -- custom
        }
    )

    last = tick()
    runservice.Heartbeat:Connect(
        function()
            -- update date ( checking every one second )
            local curr = tick()
            if curr - last >= 1 then
                date = os.date("%d-%m-%y")
                watermark.Title = "eternal | @kitodoescode | " .. date
            end
        end
    )
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
    if esp_objects[player] then
        return
    end

    local box =
        draw(
        "Square",
        {
            Visible = false,
            Color = Color3.new(1, 1, 1),
            Size = Vector2.new(0, 0),
            Thickness = 1,
            ZIndex = 20
        }
    )

    local box_outline =
        draw(
        "Square",
        {
            Visible = false,
            Color = Color3.new(0, 0, 0),
            Size = Vector2.new(0, 0),
            Thickness = 3
        }
    )

    local name =
        draw(
        "Text",
        {
            Visible = false,
            Color = Color3.new(1, 1, 1),
            Text = player.Name,
            Center = true,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0)
        }
    )

    local distance =
        draw(
        "Text",
        {
            Visible = false,
            Color = Color3.new(1, 1, 1),
            Text = "[ 0.0m ]",
            Center = true,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0)
        }
    )

    local skeleton = {lines = {}, joints = {}, bone_connections = nil, bone_set = nil, rig_detected = false}

    local objects = {box = box, box_outline = box_outline, name = name, distance = distance, skeleton = skeleton}

    local function hide_esp_objects()
        objects.box.Visible = false
        objects.box_outline.Visible = false
        objects.name.Visible = false
        objects.distance.Visible = false
        for _, bone_table in ipairs(objects.skeleton.lines) do
            bone_table.joint.Visible = false
            bone_table.joint_outline.Visible = false
        end
        for _, joint_table in ipairs(objects.skeleton.joints) do
            joint_table.dot.Visible = false
            joint_table.outline.Visible = false
        end
    end

    local connection =
        runservice.RenderStepped:Connect(
        function()
            local char = player.Character
            if not char then
                hide_esp_objects()
                return
            end

            local hrp = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")

            if not hrp or not head then
                hide_esp_objects()
                return
            end

            if not objects.skeleton.rig_detected then
                local humanoid = char:FindFirstChild("Humanoid")
                if humanoid.RigType == Enum.HumanoidRigType.R6 then
                    objects.skeleton.bone_connections = bone_connections_r6
                    objects.skeleton.bone_set = all_bones_r6
                else
                    objects.skeleton.bone_connections = bone_connections_r15
                    objects.skeleton.bone_set = all_bones_r15
                end

                objects.skeleton.rig_detected = true

                for idx, bone_joint in pairs(objects.skeleton.bone_connections) do
                    local from_bone, to_bone = bone_joint[1], bone_joint[2]

                    local joint =
                        draw(
                        "Line",
                        {
                            Visible = false,
                            Color = Color3.new(1, 1, 1),
                            Thickness = 1,
                            ZIndex = 2
                        }
                    )

                    local joint_outline =
                        draw(
                        "Line",
                        {
                            Visible = false,
                            Color = Color3.new(0, 0, 0),
                            Thickness = 3
                        }
                    )

                    objects.skeleton.lines[idx] = {
                        joint = joint,
                        joint_outline = joint_outline,
                        from_bone = from_bone,
                        to_bone = to_bone
                    }
                end

                for _, bone_name in pairs(objects.skeleton.bone_set) do
                    local dot =
                        draw(
                        "Circle",
                        {
                            Visible = false,
                            Color = Color3.new(1, 1, 1),
                            Thickness = 1,
                            Radius = 2,
                            Filled = true,
                            ZIndex = 4
                        }
                    )

                    local outline =
                        draw(
                        "Circle",
                        {
                            Visible = false,
                            Color = Color3.new(0, 0, 0),
                            Radius = 3,
                            Filled = true,
                            ZIndex = 3
                        }
                    )

                    table.insert(objects.skeleton.joints, {dot = dot, outline = outline, bone = bone_name})
                end
            end

            local _, visible = world_to_screen(hrp.Position)
            if not visible then
                hide_esp_objects()
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
            if not lp_char:FindFirstChild("HumanoidRootPart") then
                our_pos = workspace.CurrentCamera.CFrame.Position
            else
                our_pos = lp_char.HumanoidRootPart.Position
            end
            objects.distance.Text = string.format("[ %.1fm ]", (our_pos - hrp.Position).Magnitude)
            objects.distance.Position = bottom_center
            objects.distance.Visible = true

            if objects.skeleton.rig_detected then
                for _, bone_table in ipairs(objects.skeleton.lines) do
                    local from_bone, to_bone =
                        char:FindFirstChild(bone_table.from_bone),
                        char:FindFirstChild(bone_table.to_bone)
                    if not from_bone or not to_bone then
                        bone_table.joint.Visible = false
                        bone_table.joint_outline.Visible = false
                        return
                    end

                    local from_pos, from_visibility = world_to_screen(from_bone.Position)
                    local to_pos, to_visibility = world_to_screen(to_bone.Position)

                    if not from_visibility or not to_visibility then
                        bone_table.joint.Visible = false
                        bone_table.joint_outline.Visible = false
                        return
                    end

                    bone_table.joint.From = Vector2.new(from_pos.x, from_pos.y)
                    bone_table.joint.To = Vector2.new(to_pos.x, to_pos.y)
                    bone_table.joint.Visible = true

                    bone_table.joint_outline.From = Vector2.new(from_pos.x, from_pos.y)
                    bone_table.joint_outline.To = Vector2.new(to_pos.x, to_pos.y)
                    bone_table.joint_outline.Visible = true
                end

                for _, joint_table in ipairs(objects.skeleton.joints) do
                    local bone = char:FindFirstChild(joint_table.bone)
                    if not bone then
                        joint_table.dot.Visible = false
                        joint_table.outline.Visiblie = false
                    end

                    local bone_pos, bone_visibility = world_to_screen(bone.Position)
                    if not bone_visibility then
                        joint_table.dot.Visible = false
                        joint_table.outline.Visible = false
                    end

                    joint_table.dot.Position = Vector2.new(bone_pos.x, bone_pos.y)
                    joint_table.dot.Visible = true

                    joint_table.outline.Position = Vector2.new(bone_pos.x, bone_pos.y)
                    joint_table.outline.Visible = true
                end
            end
        end
    )

    local connections = {connection}

    esp_objects[player] = {objects = objects, connections = connections}
end

-- function to remove esp objects and connections from player
local function remove_player_esp(player)
    local player_table = esp_objects[player]
    if not player_table then
        return
    end

    for _, connection in pairs(player_table.connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end

    for name, draw_object in pairs(player_table.objects) do
        if name == "skeleton" then
            for _, b in ipairs(player_table.objects.skeleton.lines) do
                b.joint:Destroy()
                b.joint_outline:Destroy()
            end

            for _, b in ipairs(player_table.objects.skeleton.joints) do
                b.dot:Destroy()
                b.outline:Destroy()
            end
        else
            draw_object:Destroy()
        end
    end

    player_table = nil
end

-- adding esp objects and connections on all current player
for _, p in pairs(players:GetPlayers()) do
    add_player_esp(p)
end

-- add esp objects and connections on any new player that joined
players.PlayerAdded:Connect(
    function(player)
        player.CharacterAdded:Connect(
            function()
                add_player_esp(player)
            end
        )
    end
)

-- remove esp objects and connections from any new player that left
players.PlayerRemoving:Connect(
    function(player)
        remove_player_esp(player)
    end
)

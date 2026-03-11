-- ════════════════════════════════════════════════════════════
-- SENTENCE Hub  —  Murder Mystery 2  v1.1
-- Author: DareQPlaysRBX
-- ════════════════════════════════════════════════════════════

local Lib    = _G.Lib    or error("[ SENTENCE ] Lib not found in _G")
local Window = _G.Window or error("[ SENTENCE ] Window not found in _G")

-- ════════════════════════════════════════════════════════════
-- SERVICES
-- ════════════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TextChatService  = game:GetService("TextChatService")

local LP        = Players.LocalPlayer
local Camera    = workspace.CurrentCamera

-- ════════════════════════════════════════════════════════════
-- NOTIFICATIONS
-- ════════════════════════════════════════════════════════════
local function Notify(title, content, ntype, duration)
    Lib:Notify({
        Title    = title or "MM2",
        Content  = content or "",
        Type     = ntype or "Info",
        Duration = duration or 3,
    })
end

-- ════════════════════════════════════════════════════════════
-- INTERNAL STATE
-- ════════════════════════════════════════════════════════════
local State = {
    shootOffset      = 2.8,
    offsetToPingMult = 1.0,
    killAuraRadius   = 7,
    playerData       = {},
}

local Connections = {}

-- ════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════
local function getChar()
    local c = LP.Character
    if not c then return nil, nil, nil end
    return c, c:FindFirstChildOfClass("Humanoid"), c:FindFirstChild("HumanoidRootPart")
end

local function getMap()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:FindFirstChild("CoinContainer") and obj:FindFirstChild("Spawns") then
            return obj
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- ROLE DETECTION
-- ════════════════════════════════════════════════════════════
local function FindMurderer()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Backpack:FindFirstChild("Knife") then return p end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("Knife") then return p end
    end
    for name, data in pairs(State.playerData) do
        if data.Role == "Murderer" then
            return Players:FindFirstChild(name)
        end
    end
end

local function FindSheriff()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Backpack:FindFirstChild("Gun") then return p end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("Gun") then return p end
    end
    for name, data in pairs(State.playerData) do
        if data.Role == "Sheriff" then
            return Players:FindFirstChild(name)
        end
    end
end

local function FindSheriffNotMe()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            if p.Backpack:FindFirstChild("Gun") then return p end
            if p.Character and p.Character:FindFirstChild("Gun") then return p end
        end
    end
end

local function FindNearest()
    local char, _, root = getChar()
    if not root then return end
    local best, minD = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - root.Position).Magnitude
                if d < minD then minD = d; best = p end
            end
        end
    end
    return best
end

-- ════════════════════════════════════════════════════════════
-- PREDICTION
-- ════════════════════════════════════════════════════════════
local function GetPredicted(target, offset)
    offset = offset or State.shootOffset
    local c = target.Character
    if not c then return Vector3.zero end
    local torso = c:FindFirstChild("UpperTorso") or c:FindFirstChild("HumanoidRootPart")
    local hum   = c:FindFirstChildOfClass("Humanoid")
    if not torso or not hum then return Vector3.zero end
    local pingM = ((LP:GetNetworkPing() * 1000) * ((State.offsetToPingMult - 1) * 0.01)) + 1
    return (torso.Position
        + (torso.AssemblyLinearVelocity * Vector3.new(0.75, 0.5, 0.75)) * (offset / 15)
        + hum.MoveDirection * offset) * pingM
end

-- ════════════════════════════════════════════════════════════
-- EQUIP HELPER
-- ════════════════════════════════════════════════════════════
local function equipTool(name)
    local char, hum = getChar()
    if not char then return false end
    if char:FindFirstChild(name) then return true end
    local tool = LP.Backpack:FindFirstChild(name)
    if hum and tool then
        hum:EquipTool(tool)
        task.wait(0.1)
        return true
    end
    return false
end

-- ════════════════════════════════════════════════════════════
-- SHOOT
-- ════════════════════════════════════════════════════════════
local function ShootAt(target, instant)
    if FindSheriff() ~= LP then Notify("MM2", "You are not the sheriff!", "Warning") return end
    if not target then Notify("MM2", "No target found.", "Warning") return end
    if not equipTool("Gun") then Notify("MM2", "You don't have a gun!", "Error") return end
    local char = LP.Character
    local tHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end
    local origin = CFrame.new(char.RightHand.Position)
    local aimPos = instant and CFrame.new(tHRP.Position) or CFrame.new(GetPredicted(target))
    char:WaitForChild("Gun"):WaitForChild("Shoot"):FireServer(origin, aimPos)
end

-- ════════════════════════════════════════════════════════════
-- KNIFE THROW
-- ════════════════════════════════════════════════════════════
local function KnifeThrow(silent)
    if FindMurderer() ~= LP then
        if not silent then Notify("MM2", "You are not the murderer!", "Warning") end
        return
    end
    if not equipTool("Knife") then
        if not silent then Notify("MM2", "You don't have a knife!", "Error") end
        return
    end
    local nearest = FindNearest()
    if not nearest or not nearest.Character then
        if not silent then Notify("MM2", "No players nearby.", "Warning") end
        return
    end
    local tHRP = nearest.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end
    local char = LP.Character
    local knife = char:WaitForChild("Knife")
    knife:WaitForChild("Events"):WaitForChild("KnifeThrown"):FireServer(
        CFrame.new(char.RightHand.Position),
        CFrame.new(GetPredicted(nearest, State.shootOffset + 1))
    )
end

-- ════════════════════════════════════════════════════════════
-- KILL NEAREST
-- ════════════════════════════════════════════════════════════
local function KillNearest()
    if FindMurderer() ~= LP then Notify("MM2", "You are not the murderer!", "Warning") return end
    if not equipTool("Knife") then Notify("MM2", "You don't have a knife!", "Error") return end
    local nearest = FindNearest()
    if not nearest or not nearest.Character then Notify("MM2", "No players nearby.", "Warning") return end
    local char, _, root = getChar()
    local tHRP = nearest.Character:FindFirstChild("HumanoidRootPart")
    if not root or not tHRP then return end
    tHRP.Anchored = true
    tHRP.CFrame = root.CFrame + root.CFrame.LookVector * 2
    task.wait(0.05)
    char.Knife.Stab:FireServer("Slash")
    task.delay(0.3, function() pcall(function() tHRP.Anchored = false end) end)
end

-- ════════════════════════════════════════════════════════════
-- KILL ALL
-- ════════════════════════════════════════════════════════════
local function KillAll()
    if FindMurderer() ~= LP then Notify("MM2", "You are not the murderer!", "Warning") return end
    if not equipTool("Knife") then Notify("MM2", "You don't have a knife!", "Error") return end
    local char, _, root = getChar()
    if not root then return end
    local anchored = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Anchored = true
                hrp.CFrame   = root.CFrame + root.CFrame.LookVector * 1.5
                table.insert(anchored, hrp)
            end
        end
    end
    task.wait(0.05)
    char.Knife.Stab:FireServer("Slash")
    task.delay(0.5, function()
        for _, hrp in ipairs(anchored) do pcall(function() hrp.Anchored = false end) end
    end)
    Notify("MM2", "Attacked all players.", "Success")
end

-- ════════════════════════════════════════════════════════════
-- FLING
-- ════════════════════════════════════════════════════════════
local function Fling(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then
        Notify("MM2", "Invalid target.", "Warning") return
    end
    local lChar, lHum, lHRP = getChar()
    if not lChar then return end
    local tChar = targetPlayer.Character
    local tHum  = tChar:FindFirstChildOfClass("Humanoid")
    local tHRP  = tHum and tHum.RootPart
    local tHead = tChar:FindFirstChild("Head")
    local oldCF = lHRP.CFrame
    Camera.CameraSubject = tHead or tHum
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(9e8, 9e8, 9e8)
    bv.MaxForce = Vector3.new(1/0, 1/0, 1/0)
    bv.Parent   = lHRP
    lHum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    workspace.FallenPartsDestroyHeight = 0/0
    local deadline = tick() + 2
    local basePart = tHRP or tHead
    if not basePart then bv:Destroy() return end
    local angle = 0
    repeat
        angle = angle + 100
        for _, off in ipairs({
            CFrame.new(0,1.5,0), CFrame.new(0,-1.5,0),
            CFrame.new(2.25,1.5,-2.25), CFrame.new(-2.25,-1.5,2.25),
        }) do
            lHRP.CFrame = CFrame.new(basePart.Position) * off * CFrame.Angles(math.rad(angle),0,0)
            lChar:SetPrimaryPartCFrame(lHRP.CFrame)
            lHRP.Velocity    = Vector3.new(9e7, 9e7*10, 9e7)
            lHRP.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
            task.wait()
        end
    until (basePart.Velocity.Magnitude > 500)
       or (basePart.Parent ~= tChar)
       or (targetPlayer.Parent ~= Players)
       or (lHum.Health <= 0)
       or (tick() > deadline)
    bv:Destroy()
    lHum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    Camera.CameraSubject = lHum
    workspace.FallenPartsDestroyHeight = -500
    local t0 = tick()
    repeat
        lHRP.CFrame = oldCF * CFrame.new(0,0.5,0)
        lChar:SetPrimaryPartCFrame(lHRP.CFrame)
        lHum:ChangeState(Enum.HumanoidStateType.GettingUp)
        for _, part in ipairs(lChar:GetChildren()) do
            if part:IsA("BasePart") then
                part.Velocity = Vector3.zero
                part.RotVelocity = Vector3.zero
            end
        end
        task.wait()
    until (lHRP.Position - oldCF.p).Magnitude < 25 or tick() - t0 > 3
    Notify("MM2", "Fling complete.", "Success")
end

-- ════════════════════════════════════════════════════════════
-- LOOPS / TOGGLES
-- ════════════════════════════════════════════════════════════
local Loops = {}

-- NoClip
local function startNoClip()
    if Loops.noClip then return end
    Loops.noClip = RunService.Stepped:Connect(function()
        local c = LP.Character
        if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                p.CanCollide = false
            end
        end
    end)
end
local function stopNoClip()
    if Loops.noClip then Loops.noClip:Disconnect() Loops.noClip = nil end
end

-- Auto Shoot
local function startAutoShoot()
    if Loops.autoShoot then return end
    Loops.autoShoot = RunService.Heartbeat:Connect(function()
        if FindSheriff() ~= LP then return end
        local target = FindMurderer() or FindSheriffNotMe()
        if not target or not target.Character then return end
        local _, _, root = getChar()
        local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
        if not root or not tHRP then return end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {LP.Character}
        local hit = workspace:Raycast(root.Position, (tHRP.Position - root.Position).Unit * 60, params)
        if hit and hit.Instance.Parent ~= target.Character then return end
        ShootAt(target)
    end)
end
local function stopAutoShoot()
    if Loops.autoShoot then Loops.autoShoot:Disconnect() Loops.autoShoot = nil end
end

-- Auto Knife Throw
local function startAutoKnife(interval)
    if Loops.autoKnife then return end
    Loops.autoKnife = true
    task.spawn(function()
        while Loops.autoKnife do
            KnifeThrow(true)
            task.wait(interval or 1.5)
        end
    end)
end
local function stopAutoKnife()
    Loops.autoKnife = false
end

-- Kill Aura
local function startKillAura()
    if Loops.killAura then return end
    Loops.killAura = RunService.Heartbeat:Connect(function()
        if FindMurderer() ~= LP then return end
        local char, _, root = getChar()
        if not root then return end
        if not equipTool("Knife") then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
                if tHRP and (tHRP.Position - root.Position).Magnitude < State.killAuraRadius then
                    tHRP.Anchored = true
                    tHRP.CFrame   = root.CFrame + root.CFrame.LookVector * 2
                    task.wait(0.05)
                    pcall(function() char.Knife.Stab:FireServer("Slash") end)
                    task.delay(0.2, function() pcall(function() tHRP.Anchored = false end) end)
                    return
                end
            end
        end
    end)
end
local function stopKillAura()
    if Loops.killAura then Loops.killAura:Disconnect() Loops.killAura = nil end
end

-- Anti-Fling
local antiFlingLastPos = Vector3.zero
local function startAntiFling()
    if Loops.antiFling then return end
    Loops.antiFling = RunService.Heartbeat:Connect(function()
        local _, _, root = getChar()
        if not root then return end
        if root.AssemblyLinearVelocity.Magnitude > 250
        or root.AssemblyAngularVelocity.Magnitude > 250 then
            root.AssemblyLinearVelocity  = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            if antiFlingLastPos ~= Vector3.zero then
                root.CFrame = CFrame.new(antiFlingLastPos)
            end
        else
            antiFlingLastPos = root.Position
        end
    end)
end
local function stopAntiFling()
    if Loops.antiFling then Loops.antiFling:Disconnect() Loops.antiFling = nil end
end

-- ════════════════════════════════════════════════════════════
-- ROUND TIMER
-- ════════════════════════════════════════════════════════════
local timerLabel = nil
local timerTask  = nil

local function showTimer()
    if timerLabel then return end
    timerLabel = Instance.new("TextLabel")
    timerLabel.BackgroundTransparency = 0.45
    timerLabel.BackgroundColor3  = Color3.fromRGB(15,15,15)
    timerLabel.TextColor3        = Color3.fromRGB(255,255,255)
    timerLabel.Font              = Enum.Font.GothamBold
    timerLabel.TextScaled        = true
    timerLabel.AnchorPoint       = Vector2.new(0.5, 0)
    timerLabel.Position          = UDim2.fromScale(0.5, 0.04)
    timerLabel.Size              = UDim2.fromOffset(130, 40)
    timerLabel.Text              = "⏱ --:--"
    timerLabel.ZIndex            = 10
    Instance.new("UICorner", timerLabel).CornerRadius = UDim.new(0,8)
    timerLabel.Parent = game:GetService("CoreGui")
    timerTask = task.spawn(function()
        while timerLabel and timerLabel.Parent do
            local ok, t = pcall(function()
                return game.ReplicatedStorage
                    :WaitForChild("Remotes",2)
                    :WaitForChild("Extras",2)
                    :WaitForChild("GetTimer",2)
                    :InvokeServer()
            end)
            local s = ok and (t or 0) or 0
            timerLabel.Text = ok and string.format("⏱ %d:%02d", math.floor(s/60), s%60) or "⏱ --:--"
            task.wait(0.5)
        end
    end)
end
local function hideTimer()
    if timerLabel then timerLabel:Destroy() timerLabel = nil end
    if timerTask  then task.cancel(timerTask) timerTask = nil end
end

-- ════════════════════════════════════════════════════════════
-- TELEPORTS
-- ════════════════════════════════════════════════════════════
local function TeleportToMap()
    local map = getMap()
    if not map then Notify("MM2", "No map found.", "Warning") return end
    local spawns = map:FindFirstChild("Spawns")
    if not spawns then return end
    local list = spawns:GetChildren()
    local char = LP.Character
    if char and #list > 0 then
        char:MoveTo(list[math.random(#list)].Position)
        Notify("MM2", "Teleported to a spawnpoint.", "Success")
    end
end

local function TeleportToGun()
    local map = getMap()
    if not map then Notify("MM2", "No map found.", "Warning") return end
    local gun = map:FindFirstChild("GunDrop")
    if not gun then Notify("MM2", "No dropped gun found.", "Warning") return end
    local char = LP.Character
    if not char then return end
    local prevCF = char:GetPivot()
    char:PivotTo(gun:GetPivot())
    LP.Backpack.ChildAdded:Wait()
    task.wait(0.1)
    char:PivotTo(prevCF)
    Notify("MM2", "Picked up gun and returned.", "Success")
end

local function TeleportToPlayer(target)
    if not target or not target.Character then Notify("MM2", "Player unavailable.", "Warning") return end
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end
    local char = LP.Character
    if char then
        char:PivotTo(tHRP.CFrame + tHRP.CFrame.LookVector * 3)
        Notify("MM2", "Teleported to " .. target.Name, "Success")
    end
end

-- ════════════════════════════════════════════════════════════
-- SEND ROLES
-- ════════════════════════════════════════════════════════════
local function SendRoles()
    local m = FindMurderer()
    local s = FindSheriff()
    local msg = string.format("🔪 Murderer: %s | 🔫 Sheriff: %s",
        m and m.Name or "?", s and s.Name or "?")
    local channels = TextChatService:WaitForChild("TextChannels"):GetChildren()
    for _, ch in ipairs(channels) do
        if ch.Name ~= "RBXSystem" then pcall(function() ch:SendAsync(msg) end) end
    end
    Notify("MM2", "Roles sent to chat.", "Success")
end

-- ════════════════════════════════════════════════════════════
-- GAME EVENTS
-- ════════════════════════════════════════════════════════════
local remotes = game.ReplicatedStorage:FindFirstChild("Remotes")
if remotes then
    local pdc = remotes:FindFirstChild("Gameplay")
                and remotes.Gameplay:FindFirstChild("PlayerDataChanged")
    if pdc then
        local c = pdc.OnClientEvent:Connect(function(data)
            State.playerData = data
        end)
        table.insert(Connections, c)
    end
end

-- ════════════════════════════════════════════════════════════
-- HELPER — player list for dropdowns
-- ════════════════════════════════════════════════════════════
local function getPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(names, p.Name) end
    end
    return names
end

-- ════════════════════════════════════════════════════════════
-- ████████ UI — TABS ████████
-- ════════════════════════════════════════════════════════════

-- ─── TAB: COMBAT ────────────────────────────────────────────
local TabCombat = Window:CreateTab({ Name = "Combat", Icon = "rbxassetid://17714855134" })

-- MURDERER
local S_Murd = TabCombat:CreateSection("🔪 Murderer")

S_Murd:CreateButton({
    Name     = "Knife Throw (nearest)",
    Callback = function() KnifeThrow(false) end,
})

S_Murd:CreateButton({
    Name     = "Kill Nearest",
    Callback = KillNearest,
})

S_Murd:CreateButton({
    Name     = "Kill ALL",
    Callback = KillAll,
})

S_Murd:CreateToggle({
    Name         = "Auto Knife Throw",
    CurrentValue = false,
    Flag         = "MM2_AutoKnife",
    Callback     = function(v)
        if v then startAutoKnife(1.5) else stopAutoKnife() end
    end,
})

S_Murd:CreateToggle({
    Name         = "Kill Aura",
    CurrentValue = false,
    Flag         = "MM2_KillAura",
    Callback     = function(v)
        if v then startKillAura() else stopKillAura() end
    end,
})

S_Murd:CreateSlider({
    Name         = "Kill Aura Radius",
    Range        = {3, 20},
    Increment    = 0.5,
    CurrentValue = 7,
    Suffix       = " st",
    Flag         = "MM2_KillAuraRadius",
    Callback     = function(v) State.killAuraRadius = v end,
})

-- SHERIFF
local S_Sher = TabCombat:CreateSection("🔫 Sheriff")

S_Sher:CreateButton({
    Name     = "Shoot Murderer",
    Callback = function() ShootAt(FindMurderer()) end,
})

S_Sher:CreateButton({
    Name     = "Shoot Murderer (instant kill)",
    Callback = function() ShootAt(FindMurderer(), true) end,
})

S_Sher:CreateToggle({
    Name         = "Auto-Shoot (Murderer)",
    CurrentValue = false,
    Flag         = "MM2_AutoShoot",
    Callback     = function(v)
        if v then startAutoShoot() else stopAutoShoot() end
    end,
})

S_Sher:CreateSlider({
    Name         = "Shoot Offset (prediction)",
    Range        = {0, 8},
    Increment    = 0.1,
    CurrentValue = 2.8,
    Flag         = "MM2_ShootOffset",
    Callback     = function(v) State.shootOffset = v end,
})

S_Sher:CreateSlider({
    Name         = "Ping Multiplier",
    Range        = {0.5, 3.0},
    Increment    = 0.05,
    CurrentValue = 1.0,
    Flag         = "MM2_PingMult",
    Callback     = function(v) State.offsetToPingMult = v end,
})

-- ─── TAB: PLAYERS ───────────────────────────────────────────
local TabPlayers = Window:CreateTab({ Name = "Players", Icon = "rbxassetid://17714848175" })

local S_Roles = TabPlayers:CreateSection("🎭 Roles")

S_Roles:CreateButton({
    Name     = "Announce Roles in Chat",
    Callback = SendRoles,
})

S_Roles:CreateButton({
    Name     = "Show Roles (notify)",
    Callback = function()
        local m = FindMurderer()
        local s = FindSheriff()
        Notify("Roles",
            string.format("🔪 %s  |  🔫 %s",
                m and m.Name or "?",
                s and s.Name or "?"
            ), "Info", 5)
    end,
})

local S_TP = TabPlayers:CreateSection("⚡ Teleport")

local tpTargetName = nil

S_TP:CreateDropdown({
    Name           = "Select Player",
    Options        = getPlayerNames(),
    CurrentOption  = nil,
    Flag           = "MM2_TPTarget",
    Callback       = function(v) tpTargetName = v end,
})

S_TP:CreateButton({
    Name     = "Teleport to Selected",
    Callback = function()
        if not tpTargetName then Notify("MM2", "Select a player from the list.", "Warning") return end
        TeleportToPlayer(Players:FindFirstChild(tpTargetName))
    end,
})

S_TP:CreateButton({
    Name     = "Teleport to Spawnpoint",
    Callback = TeleportToMap,
})

S_TP:CreateButton({
    Name     = "Teleport to Gun (pickup)",
    Callback = TeleportToGun,
})

local S_Fling = TabPlayers:CreateSection("💥 Fling")

local flingTargetName = nil

S_Fling:CreateDropdown({
    Name          = "Select Fling Target",
    Options       = getPlayerNames(),
    CurrentOption = nil,
    Flag          = "MM2_FlingTarget",
    Callback      = function(v) flingTargetName = v end,
})

S_Fling:CreateButton({
    Name     = "Fling Selected",
    Callback = function()
        if not flingTargetName then Notify("MM2", "Select a target.", "Warning") return end
        Fling(Players:FindFirstChild(flingTargetName))
    end,
})

S_Fling:CreateButton({
    Name     = "Fling Nearest",
    Callback = function() Fling(FindNearest()) end,
})

-- ─── TAB: MISC ──────────────────────────────────────────────
local TabMisc = Window:CreateTab({ Name = "Misc", Icon = "rbxassetid://17714831196" })

local S_Move = TabMisc:CreateSection("🏃 Movement")

S_Move:CreateToggle({
    Name         = "NoClip",
    CurrentValue = false,
    Flag         = "MM2_NoClip",
    Callback     = function(v)
        if v then startNoClip() else stopNoClip() end
    end,
})

S_Move:CreateToggle({
    Name         = "Anti-Fling",
    CurrentValue = false,
    Flag         = "MM2_AntiFling",
    Callback     = function(v)
        if v then startAntiFling() else stopAntiFling() end
    end,
})

local S_Round = TabMisc:CreateSection("⏱ Round")

S_Round:CreateToggle({
    Name         = "Show Round Timer",
    CurrentValue = false,
    Flag         = "MM2_Timer",
    Callback     = function(v)
        if v then showTimer() else hideTimer() end
    end,
})

S_Round:CreateButton({
    Name     = "Refresh Player List (dropdowns)",
    Callback = function()
        Notify("MM2", "Re-open the dropdown — the list is dynamic.", "Info")
    end,
})

-- ════════════════════════════════════════════════════════════
-- READY
-- ════════════════════════════════════════════════════════════
Notify("Murder Mystery 2", "Script loaded! 🔪", "Success", 4)

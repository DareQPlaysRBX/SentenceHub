local Lib    = _G.Lib    or error("[ SENTENCE ] Lib not found in _G")
local Window = _G.Window or error("[ SENTENCE ] Window not found in _G")

-- ════════════════════════════════════════════════════════════
-- SERVICES
-- ════════════════════════════════════════════════════════════
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local UIS             = game:GetService("UserInputService")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Icons = loadstring(game:HttpGet('https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua'))()

-- ════════════════════════════════════════════════════════════
-- NOTIFY HELPER
-- ════════════════════════════════════════════════════════════
local function Notify(title, content, ntype, duration)
    Lib:Notify({
        Title    = title    or "SentenceHub: MM2",
        Content  = content  or "",
        Type     = ntype    or "Info",
        Duration = duration or 3,
    })
end

-- ════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════
local State = {
    shootOffset      = 2.8,
    offsetToPingMult = 1.0,
    killAuraRadius   = 7,
    knifeInterval    = 1.5,
    flySpeed         = 60,
    walkSpeed        = 16,
    jumpPower        = 50,
    playerData       = {},
}

local Conn  = {}
local Loops = {}

-- ════════════════════════════════════════════════════════════
-- CORE HELPERS
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

local function stopLoop(key)
    local v = Loops[key]
    if not v then return end
    if typeof(v) == "RBXScriptConnection" then v:Disconnect() end
    Loops[key] = nil
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
        if data.Role == "Murderer" then return Players:FindFirstChild(name) end
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
        if data.Role == "Sheriff" then return Players:FindFirstChild(name) end
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
    local _, _, root = getChar()
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
-- EQUIP TOOL
-- ════════════════════════════════════════════════════════════
local function equipTool(name)
    local char, hum = getChar()
    if not char then return false end
    if char:FindFirstChild(name) then return true end
    local tool = LP.Backpack:FindFirstChild(name)
    if hum and tool then hum:EquipTool(tool); task.wait(0.1); return true end
    return false
end

-- ════════════════════════════════════════════════════════════
-- COMBAT FUNCTIONS
-- ════════════════════════════════════════════════════════════

local function ShootAt(target, instant)
    if FindSheriff() ~= LP then Notify("MM2", "You are not the Sheriff.", "Warning") return end
    if not target then Notify("MM2", "No target detected.", "Warning") return end
    if not equipTool("Gun") then Notify("MM2", "Gun not found in backpack.", "Error") return end
    local char = LP.Character
    local tHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end
    local origin = CFrame.new(char.RightHand.Position)
    local aimPos = instant and CFrame.new(tHRP.Position) or CFrame.new(GetPredicted(target))
    char:WaitForChild("Gun"):WaitForChild("Shoot"):FireServer(origin, aimPos)
end

local function KnifeThrow(silent)
    if FindMurderer() ~= LP then
        if not silent then Notify("MM2", "You are not the Murderer.", "Warning") end
        return
    end
    if not equipTool("Knife") then
        if not silent then Notify("MM2", "Knife not found in backpack.", "Error") end
        return
    end
    local nearest = FindNearest()
    if not nearest or not nearest.Character then
        if not silent then Notify("MM2", "No players in range.", "Warning") end
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

local function KillNearest()
    if FindMurderer() ~= LP then Notify("MM2", "You are not the Murderer.", "Warning") return end
    if not equipTool("Knife") then Notify("MM2", "Knife not found.", "Error") return end
    local nearest = FindNearest()
    if not nearest or not nearest.Character then Notify("MM2", "No players nearby.", "Warning") return end
    local char, _, root = getChar()
    local tHRP = nearest.Character:FindFirstChild("HumanoidRootPart")
    if not root or not tHRP then return end
    tHRP.Anchored = true
    tHRP.CFrame   = root.CFrame + root.CFrame.LookVector * 2
    task.wait(0.05)
    char.Knife.Stab:FireServer("Slash")
    task.delay(0.3, function() pcall(function() tHRP.Anchored = false end) end)
end

local function KillAll()
    if FindMurderer() ~= LP then Notify("MM2", "You are not the Murderer.", "Warning") return end
    if not equipTool("Knife") then Notify("MM2", "Knife not found.", "Error") return end
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
    Notify("MM2", "All players attacked.", "Success")
end

local function Fling(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then
        Notify("MM2", "Invalid target.", "Warning") return
    end

    local lChar, lHum, lHRP = getChar()
    if not lChar or not lHum or not lHRP then return end

    local tChar = targetPlayer.Character
    local tHRP  = tChar:FindFirstChild("HumanoidRootPart")
    if not tHRP then Notify("MM2", "Target has no HumanoidRootPart.", "Error") return end

    local savedCF = lHRP.CFrame
    local oldFPDH = workspace.FallenPartsDestroyHeight
    workspace.FallenPartsDestroyHeight = -1e9

    for _, state in ipairs({
        Enum.HumanoidStateType.Seated,
        Enum.HumanoidStateType.FallingDown,
        Enum.HumanoidStateType.Ragdoll,
    }) do
        pcall(function() lHum:SetStateEnabled(state, false) end)
    end

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1/0, 1/0, 1/0)
    bv.Velocity = Vector3.zero
    bv.Parent   = lHRP

    local deadline = tick() + 2.5
    local frame    = 0

    repeat
        frame += 1
        if not tHRP.Parent or targetPlayer.Parent ~= Players then break end

        -- alternate slight Y offset so overlap isn't perfectly static
        local yOff = (frame % 2 == 0) and 0.3 or -0.3
        lHRP.CFrame = tHRP.CFrame * CFrame.new(0, yOff, 0)

        -- massive upward + outward velocity on us (transfers to target)
        local dir = (frame % 3 == 0)
            and Vector3.new( 9e5,  9e6 * 3,  9e5)
            or  Vector3.new(-9e5,  9e6 * 3, -9e5)

        lHRP.Velocity      = dir
        lHRP.RotVelocity   = Vector3.new(9e6, 9e6, 9e6)
        bv.Velocity        = dir

        -- also stamp velocity directly onto target each frame
        tHRP.AssemblyLinearVelocity  = dir * 1.5
        tHRP.AssemblyAngularVelocity = Vector3.new(9e6, 9e6, 9e6)

        task.wait()
    until tHRP.AssemblyLinearVelocity.Magnitude > 8e4
       or tick() > deadline
       or targetPlayer.Parent ~= Players

    -- final slam burst
    pcall(function()
        tHRP.AssemblyLinearVelocity  = Vector3.new(9e8, 9e8 * 20, 9e8)
        tHRP.AssemblyAngularVelocity = Vector3.new(9e8, 9e8,      9e8)
    end)
    task.wait(0.05)

    -- cleanup
    bv:Destroy()
    for _, state in ipairs({
        Enum.HumanoidStateType.Seated,
        Enum.HumanoidStateType.FallingDown,
        Enum.HumanoidStateType.Ragdoll,
    }) do
        pcall(function() lHum:SetStateEnabled(state, true) end)
    end
    workspace.FallenPartsDestroyHeight = oldFPDH

    -- snap back
    lHRP.CFrame      = savedCF
    lHRP.Velocity    = Vector3.zero
    lHRP.RotVelocity = Vector3.zero
    lHum:ChangeState(Enum.HumanoidStateType.GettingUp)

    Notify("MM2", targetPlayer.Name .. " launched.", "Success")
end

-- ════════════════════════════════════════════════════════════
-- TOGGLEABLE LOOPS
-- ════════════════════════════════════════════════════════════

-- NoClip
local function startNoClip()
    if Loops.noClip then return end
    Loops.noClip = RunService.Stepped:Connect(function()
        local c = LP.Character
        if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end
local function stopNoClip() stopLoop("noClip") end

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
local function stopAutoShoot() stopLoop("autoShoot") end

-- Auto Knife
local function startAutoKnife()
    if Loops.autoKnife then return end
    Loops.autoKnife = true
    task.spawn(function()
        while Loops.autoKnife do
            KnifeThrow(true)
            task.wait(State.knifeInterval)
        end
    end)
end
local function stopAutoKnife() Loops.autoKnife = false end

-- Kill Aura — hits ALL players in radius per frame
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
                if tHRP and (tHRP.Position - root.Position).Magnitude <= State.killAuraRadius then
                    tHRP.Anchored = true
                    tHRP.CFrame   = root.CFrame + root.CFrame.LookVector * 2
                    task.wait(0.03)
                    pcall(function() char.Knife.Stab:FireServer("Slash") end)
                    task.delay(0.15, function() pcall(function() tHRP.Anchored = false end) end)
                end
            end
        end
    end)
end
local function stopKillAura() stopLoop("killAura") end

-- Anti-Fling — zeroes velocity and snaps back to last safe position
local antiFlingLastPos = nil
local function startAntiFling()
    if Loops.antiFling then return end
    Loops.antiFling = RunService.Heartbeat:Connect(function()
        local _, _, root = getChar()
        if not root then return end
        local linMag = root.AssemblyLinearVelocity.Magnitude
        local angMag = root.AssemblyAngularVelocity.Magnitude
        if linMag > 200 or angMag > 200 then
            root.AssemblyLinearVelocity  = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            if antiFlingLastPos then
                root.CFrame = CFrame.new(antiFlingLastPos)
            end
            Notify("Anti-Fling", "Fling blocked — position restored.", "Warning", 2)
        elseif linMag < 50 then
            antiFlingLastPos = root.Position
        end
    end)
end
local function stopAntiFling() stopLoop("antiFling") end

-- Follow Player
local function startFollowPlayer(target)
    stopLoop("follow")
    if not target then return end
    Loops.follow = RunService.Heartbeat:Connect(function()
        if not target.Character then return end
        local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
        if not tHRP then return end
        local char = LP.Character
        if char then char:PivotTo(tHRP.CFrame * CFrame.new(0, 0, 3.5)) end
    end)
    Notify("MM2", "Following " .. target.Name .. ".", "Info", 2)
end
local function stopFollowPlayer()
    stopLoop("follow")
    Notify("MM2", "Follow stopped.", "Info", 2)
end

-- God Mode
local function startGodMode()
    if Loops.godMode then return end
    Loops.godMode = RunService.Heartbeat:Connect(function()
        local _, hum = getChar()
        if hum then hum.Health = hum.MaxHealth end
    end)
    Notify("MM2", "God Mode active.", "Success")
end
local function stopGodMode()
    stopLoop("godMode")
    Notify("MM2", "God Mode disabled.", "Info")
end

-- ════════════════════════════════════════════════════════════
-- ESP — Highlight-based, no external module
-- ════════════════════════════════════════════════════════════
local espHighlights = {}

local function removeAllESP()
    for _, h in pairs(espHighlights) do pcall(function() h:Destroy() end) end
    espHighlights = {}
end

local function applyESP(player)
    if not player.Character then return end
    if espHighlights[player.Name] then
        espHighlights[player.Name]:Destroy()
        espHighlights[player.Name] = nil
    end
    local h = Instance.new("Highlight")
    h.Adornee          = player.Character
    h.DepthMode        = Enum.HighlightDepthMode.AlwaysOnTop
    h.FillTransparency = 0.55
    if FindMurderer() == player then
        h.FillColor    = Color3.fromRGB(220, 40,  40)
        h.OutlineColor = Color3.fromRGB(255, 80,  80)
    elseif FindSheriff() == player then
        h.FillColor    = Color3.fromRGB(40,  120, 255)
        h.OutlineColor = Color3.fromRGB(80,  160, 255)
    else
        h.FillColor    = Color3.fromRGB(40,  200, 80)
        h.OutlineColor = Color3.fromRGB(80,  255, 120)
    end
    h.Parent = game:GetService("CoreGui")
    espHighlights[player.Name] = h
end

local function reloadESP()
    removeAllESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then applyESP(p) end
    end
end

local function startESP()
    if Loops.esp then return end
    reloadESP()
    Loops.espCharConns = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local c = p.CharacterAdded:Connect(function()
                task.wait(0.15)
                if Loops.esp then applyESP(p) end
            end)
            table.insert(Loops.espCharConns, c)
        end
    end
    Loops.esp = RunService.Heartbeat:Connect(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and not espHighlights[p.Name] then
                applyESP(p)
            end
        end
    end)
end

local function stopESP()
    stopLoop("esp")
    if Loops.espCharConns then
        for _, c in ipairs(Loops.espCharConns) do c:Disconnect() end
        Loops.espCharConns = nil
    end
    removeAllESP()
end

-- ════════════════════════════════════════════════════════════
-- ROUND TIMER (premium label with pulse at <30s)
-- ════════════════════════════════════════════════════════════
local timerLabel, timerTask = nil, nil

local function showTimer()
    if timerLabel then return end
    timerLabel = Instance.new("TextLabel")
    timerLabel.BackgroundColor3       = Color3.fromRGB(10, 10, 16)
    timerLabel.BackgroundTransparency = 0.30
    timerLabel.TextColor3             = Color3.fromRGB(200, 220, 255)
    timerLabel.Font                   = Enum.Font.GothamBold
    timerLabel.TextScaled             = true
    timerLabel.AnchorPoint            = Vector2.new(0.5, 0)
    timerLabel.Position               = UDim2.fromScale(0.5, 0.03)
    timerLabel.Size                   = UDim2.fromOffset(144, 38)
    timerLabel.Text                   = "⏱  --:--"
    timerLabel.ZIndex                 = 10
    Instance.new("UICorner",  timerLabel).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", timerLabel)
    stroke.Color = Color3.fromRGB(80, 120, 255); stroke.Thickness = 1.2; stroke.Transparency = 0.35
    timerLabel.Parent = game:GetService("CoreGui")

    timerTask = task.spawn(function()
        while timerLabel and timerLabel.Parent do
            local ok, t = pcall(function()
                return game.ReplicatedStorage
                    :WaitForChild("Remotes",  2)
                    :WaitForChild("Extras",   2)
                    :WaitForChild("GetTimer", 2)
                    :InvokeServer()
            end)
            if timerLabel then
                local s = ok and (t or 0) or 0
                timerLabel.Text      = ok and string.format("⏱  %d:%02d", math.floor(s/60), s%60) or "⏱  --:--"
                timerLabel.TextColor3 = (ok and s < 30)
                    and Color3.fromRGB(255, 80, 80)
                    or  Color3.fromRGB(200, 220, 255)
                if stroke then
                    stroke.Color = (ok and s < 30)
                        and Color3.fromRGB(255, 60, 60)
                        or  Color3.fromRGB(80, 120, 255)
                end
            end
            task.wait(0.5)
        end
    end)
end

local function hideTimer()
    if timerLabel then timerLabel:Destroy(); timerLabel = nil end
    if timerTask  then task.cancel(timerTask); timerTask = nil end
end

-- ════════════════════════════════════════════════════════════
-- TELEPORTS
-- ════════════════════════════════════════════════════════════
local function TeleportToMap()
    local map = getMap()
    if not map then Notify("MM2", "No active map found.", "Warning") return end
    local spawns = map:FindFirstChild("Spawns")
    if not spawns then return end
    local list = spawns:GetChildren()
    local char = LP.Character
    if char and #list > 0 then
        char:MoveTo(list[math.random(#list)].Position)
        Notify("MM2", "Teleported to spawn.", "Success")
    end
end

local function TeleportToGun()
    local map = getMap()
    if not map then Notify("MM2", "No active map found.", "Warning") return end
    local gun = map:FindFirstChild("GunDrop")
    if not gun then Notify("MM2", "No dropped gun on the map.", "Warning") return end
    local char = LP.Character
    if not char then return end
    local prevCF = char:GetPivot()
    char:PivotTo(gun:GetPivot())
    LP.Backpack.ChildAdded:Wait()
    task.wait(0.1)
    char:PivotTo(prevCF)
    Notify("MM2", "Gun picked up — returned.", "Success")
end

local function TeleportToPlayer(target)
    if not target or not target.Character then Notify("MM2", "Player unavailable.", "Warning") return end
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end
    local char = LP.Character
    if char then
        char:PivotTo(tHRP.CFrame + tHRP.CFrame.LookVector * 3)
        Notify("MM2", "Teleported to " .. target.Name .. ".", "Success")
    end
end

-- ════════════════════════════════════════════════════════════
-- BROADCAST ROLES
-- ════════════════════════════════════════════════════════════
local function SendRoles()
    local m = FindMurderer()
    local s = FindSheriff()
    local msg = string.format("🔪 Murderer: %s  |  🔫 Sheriff: %s",
        m and m.Name or "unknown", s and s.Name or "unknown")
    for _, ch in ipairs(TextChatService:WaitForChild("TextChannels"):GetChildren()) do
        if ch.Name ~= "RBXSystem" then pcall(function() ch:SendAsync(msg) end) end
    end
    Notify("MM2", "Roles broadcast to chat.", "Success")
end

-- ════════════════════════════════════════════════════════════
-- COIN FARM (requires firetouchinterest executor API)
-- ════════════════════════════════════════════════════════════
local function startCoinFarm()
    if Loops.coinFarm then return end
    Loops.coinFarm = true
    task.spawn(function()
        while Loops.coinFarm do
            local map = getMap()
            if map then
                local cc = map:FindFirstChild("CoinContainer")
                if cc then
                    for _, coin in ipairs(cc:GetDescendants()) do
                        if coin:IsA("BasePart") and Loops.coinFarm then
                            local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                            if root then
                                pcall(function()
                                    firetouchinterest(root, coin, 0)
                                    task.wait(0.02)
                                    firetouchinterest(root, coin, 1)
                                end)
                            end
                        end
                    end
                end
            end
            task.wait(3)
        end
    end)
    Notify("MM2", "Coin Farm started.", "Success")
end
local function stopCoinFarm()
    Loops.coinFarm = false
    Notify("MM2", "Coin Farm stopped.", "Info")
end

-- ════════════════════════════════════════════════════════════
-- UNIVERSAL — FLY
-- ════════════════════════════════════════════════════════════
local flyBV, flyBG = nil, nil

local function startFly()
    if Loops.fly then return end
    local char, hum, root = getChar()
    if not root then return end

    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent   = root

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    flyBG.P         = 1e4
    flyBG.CFrame    = root.CFrame
    flyBG.Parent    = root

    if hum then hum.PlatformStand = true end

    Loops.fly = RunService.Heartbeat:Connect(function()
        local _, _, r = getChar()
        if not r or not flyBV or not flyBG then return end
        local speed = State.flySpeed
        local dir   = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W)          then dir = dir + Camera.CFrame.LookVector  end
        if UIS:IsKeyDown(Enum.KeyCode.S)          then dir = dir - Camera.CFrame.LookVector  end
        if UIS:IsKeyDown(Enum.KeyCode.A)          then dir = dir - Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D)          then dir = dir + Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space)      then dir = dir + Vector3.yAxis              end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift)  then dir = dir - Vector3.yAxis              end
        flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * speed or Vector3.zero
        flyBG.CFrame   = Camera.CFrame
    end)

    Notify("MM2", "Fly on — WASD · Space/Shift.", "Success")
end

local function stopFly()
    stopLoop("fly")
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    local _, hum = getChar()
    if hum then hum.PlatformStand = false end
    Notify("MM2", "Fly disabled.", "Info")
end

-- ════════════════════════════════════════════════════════════
-- UNIVERSAL — SPEED / JUMP / INF JUMP
-- ════════════════════════════════════════════════════════════
local function applySpeed(v)
    State.walkSpeed = v
    local _, hum = getChar()
    if hum then hum.WalkSpeed = v end
end

local function applyJump(v)
    State.jumpPower = v
    local _, hum = getChar()
    if hum then hum.JumpPower = v; hum.UseJumpPower = true end
end

local function startInfiniteJump()
    if Loops.infJump then return end
    Loops.infJump = UIS.JumpRequest:Connect(function()
        local _, hum = getChar()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end
local function stopInfiniteJump() stopLoop("infJump") end

-- Re-apply movement stats on respawn
LP.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    task.wait(0.5)
    hum.WalkSpeed    = State.walkSpeed
    hum.JumpPower    = State.jumpPower
    hum.UseJumpPower = true
    if Loops.noClip    then stopNoClip();    task.wait(0.1); startNoClip()    end
    if Loops.antiFling then stopAntiFling(); task.wait(0.1); startAntiFling() end
    if Loops.fly       then stopFly();       task.wait(0.3); startFly()       end
end)

-- ════════════════════════════════════════════════════════════
-- GAME EVENTS
-- ════════════════════════════════════════════════════════════
local remotes = game.ReplicatedStorage:FindFirstChild("Remotes")
if remotes then
    local gameplay = remotes:FindFirstChild("Gameplay")
    if gameplay then
        local pdc = gameplay:FindFirstChild("PlayerDataChanged")
        if pdc then
            local c = pdc.OnClientEvent:Connect(function(data)
                State.playerData = data
                if Loops.esp then reloadESP() end
            end)
            table.insert(Conn, c)
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- DROPDOWN AUTO-REFRESH
-- ════════════════════════════════════════════════════════════
local playerDropdowns = {}

local function getPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(names, p.Name) end
    end
    return names
end

local function refreshDropdowns()
    local names = getPlayerNames()
    for _, dd in ipairs(playerDropdowns) do
        pcall(function() dd:Refresh(names) end)
    end
end

Players.PlayerAdded:Connect(function()   task.wait(0.5); refreshDropdowns() end)
Players.PlayerRemoving:Connect(function() task.wait(0.2); refreshDropdowns() end)

-- ─────────────────────────────────────────────────────────────
--  TAB  ·  COMBAT
-- ─────────────────────────────────────────────────────────────
local TabCombat = Window:CreateTab({ Name = "Combat", Icon = Icons['swords'] })

local sMurd = TabCombat:CreateSection("Murderer")

sMurd:CreateButton({ Name = "Knife Throw",  Callback = function() KnifeThrow(false) end })
sMurd:CreateButton({ Name = "Kill Nearest Player", Callback = KillNearest })
sMurd:CreateButton({ Name = "Kill All Players",     Callback = KillAll     })

sMurd:CreateToggle({
    Name = "Auto Knife Throw", CurrentValue = false, Flag = "MM2_AutoKnife",
    Callback = function(v) if v then startAutoKnife() else stopAutoKnife() end end,
})
sMurd:CreateSlider({
    Name = "Knife Interval", Range = {0.3, 5.0}, Increment = 0.1,
    CurrentValue = 1.5, Suffix = "s", Flag = "MM2_KnifeInterval",
    Callback = function(v) State.knifeInterval = v end,
})
sMurd:CreateToggle({
    Name = "Kill Aura", CurrentValue = false, Flag = "MM2_KillAura",
    Callback = function(v) if v then startKillAura() else stopKillAura() end end,
})
sMurd:CreateSlider({
    Name = "Aura Radius", Range = {3, 25}, Increment = 0.5,
    CurrentValue = 7, Suffix = " st", Flag = "MM2_KillAuraRadius",
    Callback = function(v) State.killAuraRadius = v end,
})

local sSher = TabCombat:CreateSection("Sheriff")

sSher:CreateButton({ Name = "Shoot Murderer",          Callback = function() ShootAt(FindMurderer())       end })
sSher:CreateButton({ Name = "Shoot Murderer  [Instant]", Callback = function() ShootAt(FindMurderer(), true) end })

sSher:CreateToggle({
    Name = "Auto-Shoot", CurrentValue = false, Flag = "MM2_AutoShoot",
    Callback = function(v) if v then startAutoShoot() else stopAutoShoot() end end,
})
sSher:CreateSlider({
    Name = "Aim Prediction", Range = {0, 8}, Increment = 0.1,
    CurrentValue = 2.8, Flag = "MM2_ShootOffset",
    Callback = function(v) State.shootOffset = v end,
})
sSher:CreateSlider({
    Name = "Ping Compensation", Range = {0.5, 3.0}, Increment = 0.05,
    CurrentValue = 1.0, Flag = "MM2_PingMult",
    Callback = function(v) State.offsetToPingMult = v end,
})

-- ─────────────────────────────────────────────────────────────
--  TAB  ·  PLAYERS
-- ─────────────────────────────────────────────────────────────
local TabPlayers = Window:CreateTab({ Name = "Players", Icon = Icons['circle-user-round'] })

local sInfo = TabPlayers:CreateSection("Intelligence")

sInfo:CreateButton({ Name = "Broadcast Roles", Callback = SendRoles })
sInfo:CreateButton({
    Name = "Display Roles",
    Callback = function()
        local m, s = FindMurderer(), FindSheriff()
        Notify("Roles", string.format("Murderer: %s\nSheriff: %s",
            m and m.Name or "unknown", s and s.Name or "unknown"), "Info", 6)
    end,
})
sInfo:CreateToggle({
    Name = "Player ESP", CurrentValue = false, Flag = "MM2_ESP",
    Callback = function(v) if v then startESP() else stopESP() end end,
})

-- ── Teleport ─────────────────────────────────────────────────
local sTP      = TabPlayers:CreateSection("Teleport")
local tpTarget = nil

local tpDrop = sTP:CreateDropdown({
    Name = "Target Player", Options = getPlayerNames(),
    CurrentOption = nil, Flag = "MM2_TPTarget",
    Callback = function(v) tpTarget = v end,
})
table.insert(playerDropdowns, tpDrop)

sTP:CreateButton({ Name = "→ Murderer", Callback = function() TeleportToPlayer(FindMurderer()) end })
sTP:CreateButton({ Name = "→ Sheriff",  Callback = function() TeleportToPlayer(FindSheriff())  end })
sTP:CreateButton({
    Name = "→ Selected Player",
    Callback = function()
        if not tpTarget then Notify("MM2", "Select a player first.", "Warning") return end
        TeleportToPlayer(Players:FindFirstChild(tpTarget))
    end,
})
sTP:CreateButton({ Name = "→ Random Spawn",  Callback = TeleportToMap })
sTP:CreateButton({ Name = "Pickup Dropped Gun", Callback = TeleportToGun })

-- ── Follow ───────────────────────────────────────────────────
local sFollow      = TabPlayers:CreateSection("Follow")
local followTarget = nil

local followDrop = sFollow:CreateDropdown({
    Name = "Follow Target", Options = getPlayerNames(),
    CurrentOption = nil, Flag = "MM2_FollowTarget",
    Callback = function(v) followTarget = v end,
})
table.insert(playerDropdowns, followDrop)

sFollow:CreateToggle({
    Name = "Follow Player", CurrentValue = false, Flag = "MM2_Follow",
    Callback = function(v)
        if v then
            local p = followTarget and Players:FindFirstChild(followTarget)
            if not p then Notify("MM2", "Select a follow target first.", "Warning") return end
            startFollowPlayer(p)
        else
            stopFollowPlayer()
        end
    end,
})

-- ── Fling ─────────────────────────────────────────────────────
local sFling      = TabPlayers:CreateSection("Fling")
local flingTarget = nil

local flingDrop = sFling:CreateDropdown({
    Name = "Fling Target", Options = getPlayerNames(),
    CurrentOption = nil, Flag = "MM2_FlingTarget",
    Callback = function(v) flingTarget = v end,
})
table.insert(playerDropdowns, flingDrop)

sFling:CreateButton({ Name = "Fling Murderer", Callback = function()
    local m = FindMurderer()
    if not m then Notify("MM2", "Murderer not found.", "Warning") return end
    Fling(m)
end })
sFling:CreateButton({ Name = "Fling Sheriff", Callback = function()
    local s = FindSheriff()
    if not s then Notify("MM2", "Sheriff not found.", "Warning") return end
    Fling(s)
end })

sFling:CreateButton({
    Name = "Fling Selected",
    Callback = function()
        if not flingTarget then Notify("MM2", "Select a target first.", "Warning") return end
        Fling(Players:FindFirstChild(flingTarget))
    end,
})
sFling:CreateButton({ Name = "Fling Nearest", Callback = function() Fling(FindNearest()) end })

-- ─────────────────────────────────────────────────────────────
--  TAB  ·  UNIVERSAL
-- ─────────────────────────────────────────────────────────────
local TabUniversal = Window:CreateTab({ Name = "Universal", Icons['globe'] })

local sMove = TabUniversal:CreateSection("Movement")

sMove:CreateToggle({
    Name = "Fly", CurrentValue = false, Flag = "UNI_Fly",
    Callback = function(v) if v then startFly() else stopFly() end end,
})
sMove:CreateSlider({
    Name = "Fly Speed", Range = {10, 250}, Increment = 5,
    CurrentValue = 60, Suffix = " st/s", Flag = "UNI_FlySpeed",
    Callback = function(v) State.flySpeed = v end,
})
sMove:CreateToggle({
    Name = "NoClip", CurrentValue = false, Flag = "UNI_NoClip",
    Callback = function(v) if v then startNoClip() else stopNoClip() end end,
})
sMove:CreateToggle({
    Name = "Infinite Jump", CurrentValue = false, Flag = "UNI_InfJump",
    Callback = function(v) if v then startInfiniteJump() else stopInfiniteJump() end end,
})
sMove:CreateSlider({
    Name = "Walk Speed", Range = {4, 200}, Increment = 2,
    CurrentValue = 16, Suffix = " st/s", Flag = "UNI_WalkSpeed",
    Callback = function(v) applySpeed(v) end,
})
sMove:CreateSlider({
    Name = "Jump Power", Range = {10, 300}, Increment = 5,
    CurrentValue = 50, Suffix = " pw", Flag = "UNI_JumpPower",
    Callback = function(v) applyJump(v) end,
})

local sPlayer = TabUniversal:CreateSection("Player")

sPlayer:CreateToggle({
    Name = "God Mode", CurrentValue = false, Flag = "UNI_GodMode",
    Callback = function(v) if v then startGodMode() else stopGodMode() end end,
})
sPlayer:CreateToggle({
    Name = "Anti-Fling", CurrentValue = false, Flag = "UNI_AntiFling",
    Callback = function(v) if v then startAntiFling() else stopAntiFling() end end,
})

-- ════════════════════════════════════════════════════════════
-- READY
-- ════════════════════════════════════════════════════════════
Notify("Murder Mystery 2", "v2.0 — ready.", "Success", 4)

local Lib    = _G.Lib    or error("[ SENTENCE ] Lib not found in _G")
local Window = _G.Window or error("[ SENTENCE ] Window not found in _G")

-- ════════════════════════════════════════════════════════════
-- SERVICES
-- ════════════════════════════════════════════════════════════
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local UGS              = game:GetService("UserInputService")
local LP               = Players.LocalPlayer
local Workspace        = game:GetService("Workspace")

local _GUI_PARENT = (typeof(gethui) == "function" and gethui())
    or game:GetService("CoreGui")

-- ════════════════════════════════════════════════════════════
-- SHARED STATE  (wszystko domyślnie wyłączone)
-- ════════════════════════════════════════════════════════════
local UNI = {
    FlyEnabled       = false,
    NoclipEnabled    = false,
    AntiFlingEnabled = false,
    InfiniteJump     = false,
    SpeedEnabled     = false,
    WalkSpeed        = 16,
    JumpPower        = 50,
    FlySpeed         = 60,
}

-- ════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════
local function getChar()
    local char = LP.Character
    if not char then return nil, nil, nil end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    return char, hum, root
end

-- ════════════════════════════════════════════════════════════
-- FLY
-- ════════════════════════════════════════════════════════════
local FlyConn, FlyBodyVel, FlyBodyGyro

local function stopFly()
    if FlyConn     then FlyConn:Disconnect();    FlyConn     = nil end
    if FlyBodyVel  then FlyBodyVel:Destroy();    FlyBodyVel  = nil end
    if FlyBodyGyro then FlyBodyGyro:Destroy();   FlyBodyGyro = nil end
    local _, hum = getChar()
    if hum then pcall(function() hum.PlatformStand = false end) end
end

local function startFly()
    stopFly()
    local char, hum, root = getChar()
    if not (char and hum and root) then return end

    hum.PlatformStand = true

    FlyBodyVel = Instance.new("BodyVelocity")
    FlyBodyVel.Velocity  = Vector3.zero
    FlyBodyVel.MaxForce  = Vector3.new(1e5, 1e5, 1e5)
    FlyBodyVel.Parent    = root

    FlyBodyGyro = Instance.new("BodyGyro")
    FlyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    FlyBodyGyro.P         = 1e4
    FlyBodyGyro.CFrame    = root.CFrame
    FlyBodyGyro.Parent    = root

    local cam = Workspace.CurrentCamera
    FlyConn = RunService.RenderStepped:Connect(function()
        if not UNI.FlyEnabled then stopFly(); return end
        local _, hum2, root2 = getChar()
        if not (hum2 and root2) then stopFly(); return end

        local dir = Vector3.zero
        if UGS:IsKeyDown(Enum.KeyCode.W)           then dir = dir + cam.CFrame.LookVector  end
        if UGS:IsKeyDown(Enum.KeyCode.S)           then dir = dir - cam.CFrame.LookVector  end
        if UGS:IsKeyDown(Enum.KeyCode.A)           then dir = dir - cam.CFrame.RightVector end
        if UGS:IsKeyDown(Enum.KeyCode.D)           then dir = dir + cam.CFrame.RightVector end
        if UGS:IsKeyDown(Enum.KeyCode.Space)       then dir = dir + Vector3.new(0, 1, 0)   end
        if UGS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0)   end

        if dir.Magnitude > 0 then dir = dir.Unit end
        FlyBodyVel.Velocity = dir * UNI.FlySpeed
        if dir.Magnitude > 0 then
            FlyBodyGyro.CFrame = CFrame.new(Vector3.zero, dir)
        end
    end)
end

-- ════════════════════════════════════════════════════════════
-- NOCLIP
-- ════════════════════════════════════════════════════════════
local NoclipConn

local function stopNoclip()
    if NoclipConn then NoclipConn:Disconnect(); NoclipConn = nil end
    local char = LP.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide = true end) end
        end
    end
end

local function startNoclip()
    stopNoclip()
    NoclipConn = RunService.Stepped:Connect(function()
        if not UNI.NoclipEnabled then stopNoclip(); return end
        local char = LP.Character
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end
        end
    end)
end

-- ════════════════════════════════════════════════════════════
-- ANTI-FLING
-- ════════════════════════════════════════════════════════════
local ANTI_FLING_THRESHOLD = 350
local AntiFlingConn
local _lastSafePos = nil
local _lastSafeCF  = nil

local function stopAntiFling()
    if AntiFlingConn then AntiFlingConn:Disconnect(); AntiFlingConn = nil end
end

local function startAntiFling()
    stopAntiFling()
    AntiFlingConn = RunService.Heartbeat:Connect(function()
        if not UNI.AntiFlingEnabled then return end
        local _, _, root = getChar()
        if not root then _lastSafePos = nil; return end

        local vel = root.AssemblyLinearVelocity
        if vel.Magnitude > ANTI_FLING_THRESHOLD then
            if _lastSafeCF then
                root.CFrame                  = _lastSafeCF
                root.AssemblyLinearVelocity  = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                local bv = Instance.new("BodyVelocity")
                bv.Velocity = Vector3.zero
                bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
                bv.Parent   = root
                task.delay(0.1, function() pcall(function() bv:Destroy() end) end)
            end
        else
            _lastSafePos = root.Position
            _lastSafeCF  = root.CFrame
        end
    end)
end

-- ════════════════════════════════════════════════════════════
-- INFINITE JUMP
-- ════════════════════════════════════════════════════════════
local InfJumpConn

local function stopInfiniteJump()
    if InfJumpConn then InfJumpConn:Disconnect(); InfJumpConn = nil end
end

local function startInfiniteJump()
    stopInfiniteJump()
    InfJumpConn = UGS.JumpRequest:Connect(function()
        if not UNI.InfiniteJump then return end
        local _, hum = getChar()
        if hum and hum:GetState() ~= Enum.HumanoidStateType.Dead then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

startInfiniteJump()

-- ════════════════════════════════════════════════════════════
-- WALKSPEED / JUMP POWER
-- ════════════════════════════════════════════════════════════
local StatConn

local function startStatLoop()
    if StatConn then StatConn:Disconnect() end
    StatConn = RunService.Heartbeat:Connect(function()
        local _, hum = getChar()
        if not hum then return end
        if UNI.SpeedEnabled then
            pcall(function() hum.WalkSpeed = UNI.WalkSpeed end)
        end
        pcall(function() hum.JumpPower = UNI.JumpPower end)
    end)
end

startStatLoop()

-- ════════════════════════════════════════════════════════════
-- CHARACTER RESPAWN HOOK
-- ════════════════════════════════════════════════════════════
LP.CharacterAdded:Connect(function()
    task.wait(0.3)
    if UNI.FlyEnabled       then startFly()       end
    if UNI.NoclipEnabled    then startNoclip()    end
    if UNI.AntiFlingEnabled then startAntiFling() end
    startInfiniteJump()
    startStatLoop()
end)

-- ════════════════════════════════════════════════════════════
-- MAIN TAB  UI
-- ════════════════════════════════════════════════════════════
local TabMain = Window:CreateTab({
    Name      = "Main",
    Icon      = "rbxassetid://6031280882",
    ShowTitle = true,
})

-- ── Movement ───────────────────────────────────────────────
local M1 = TabMain:CreateSection("Movement")

M1:CreateToggle({
    Name     = "Fly",
    Default  = false,
    Callback = function(v)
        UNI.FlyEnabled = v
        if v then startFly() else stopFly() end
    end,
})
M1:CreateToggle({
    Name     = "Noclip",
    Default  = false,
    Callback = function(v)
        UNI.NoclipEnabled = v
        if v then startNoclip() else stopNoclip() end
    end,
})
M1:CreateToggle({
    Name     = "Infinite Jump",
    Default  = false,
    Callback = function(v) UNI.InfiniteJump = v end,
})
M1:CreateToggle({
    Name     = "Speed Hack",
    Default  = false,
    Callback = function(v)
        UNI.SpeedEnabled = v
        if not v then
            local _, hum = getChar()
            if hum then pcall(function() hum.WalkSpeed = 16 end) end
        end
    end,
})
M1:CreateSlider({
    Name      = "Walk Speed",
    Range     = { 4, 500 },
    Default   = 16,
    Increment = 1,
    Callback  = function(v) UNI.WalkSpeed = v end,
})
M1:CreateSlider({
    Name      = "Jump Power",
    Range     = { 1, 500 },
    Default   = 50,
    Increment = 1,
    Callback  = function(v) UNI.JumpPower = v end,
})
M1:CreateSlider({
    Name      = "Fly Speed",
    Range     = { 10, 500 },
    Default   = 60,
    Increment = 5,
    Callback  = function(v) UNI.FlySpeed = v end,
})

-- ── Protection ─────────────────────────────────────────────
local M2 = TabMain:CreateSection("Protection")

M2:CreateToggle({
    Name     = "Anti-Fling",
    Default  = false,
    Callback = function(v)
        UNI.AntiFlingEnabled = v
        if v then startAntiFling() else stopAntiFling() end
    end,
})
M2:CreateSlider({
    Name      = "Anti-Fling Threshold",
    Range     = { 50, 2000 },
    Default   = 350,
    Increment = 25,
    Callback  = function(v) ANTI_FLING_THRESHOLD = v end,
})

-- ── Utility ────────────────────────────────────────────────
local M3 = TabMain:CreateSection("Utility")

M3:CreateButton({
    Name     = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
    end,
})
M3:CreateButton({
    Name     = "Respawn Character",
    Callback = function() LP:LoadCharacter() end,
})
M3:CreateButton({
    Name     = "Copy Place ID",
    Callback = function()
        if setclipboard then
            setclipboard(tostring(game.PlaceId))
            Lib:Notify({ Title = "SENTENCE Hub", Content = "Place ID copied to clipboard.", Type = "Info", Duration = 3 })
        end
    end,
})
M3:CreateButton({
    Name     = "Copy Job ID",
    Callback = function()
        if setclipboard then
            setclipboard(game.JobId)
            Lib:Notify({ Title = "SENTENCE Hub", Content = "Job ID copied to clipboard.", Type = "Info", Duration = 3 })
        end
    end,
})

-- ════════════════════════════════════════════════════════════
-- ████████████████  ESP  SYSTEM  ████████████████████████████
-- ════════════════════════════════════════════════════════════

local DARK_BG     = Color3.fromRGB(18,  18,  18)
local BORDER_DARK = Color3.fromRGB(37,  37,  37)
local V2          = Vector2.new

-- ── Config ─────────────────────────────────────────────────
local CFG = {
    Enabled           = false,
    ShowNames         = false,
    ShowDistance      = false,
    ShowHealth        = false,
    ShowBoxes         = false,
    ShowTracers       = false,
    ShowHeadDot       = false,
    ShowHealthBar     = false,
    ShowChams         = false,
    TeamCheck         = false,  -- gdy true: ukrywa ESP dla graczy z tej samej drużyny
    RainbowMode       = false,

    MaxDistance       = 250,
    TextSize          = 10,
    TextScaleRef      = 100,
    BoxThickness      = 1,
    TracerThickness   = 1,
    HeadDotSize       = 5,
    HealthBarWidth    = 3,
    ChamsFillTrans    = 0.55,
    ChamsOutlineTrans = 0.0,

    TracerOrigin = "Bottom",
    BoxStyle     = "Corner",
    TextOutline  = true,

    EnemyColor = Color3.fromRGB(90, 159, 232),
    TeamColor  = Color3.fromRGB(90, 159, 232),
}

-- ── Camera / utils ─────────────────────────────────────────
local Camera = Workspace.CurrentCamera

local function W2S(pos)
    local s, vis = Camera:WorldToViewportPoint(pos)
    return V2(s.X, s.Y), s.Z > 0 and vis, s.Z
end

local function isTeammate(p)
    if LP.Neutral and p.Neutral then return true end
    return p.TeamColor == LP.TeamColor
end

local function playerColor(p)
    return isTeammate(p) and CFG.TeamColor or CFG.EnemyColor
end

local rainbowHue = 0
local function getColor(p)
    if CFG.RainbowMode then return Color3.fromHSV(rainbowHue, 1, 1) end
    return playerColor(p)
end

local function tracerOrigin()
    local vp = Camera.ViewportSize
    if CFG.TracerOrigin == "Center" then return V2(vp.X/2, vp.Y/2) end
    if CFG.TracerOrigin == "Mouse"  then local m = LP:GetMouse(); return V2(m.X, m.Y) end
    return V2(vp.X/2, vp.Y)
end

local function scaledTextSize(basePx, dist)
    local scaled = math.floor(basePx * (CFG.TextScaleRef / math.max(dist, 30)))
    return math.clamp(scaled, 9, basePx * 3)
end

-- ── Drawing helpers ────────────────────────────────────────
local AllDrawings = {}

local function newDraw(dtype, props)
    local ok, obj = pcall(Drawing.new, dtype)
    if not ok or not obj then return nil end
    obj.Visible = false
    for k, v in pairs(props or {}) do pcall(function() obj[k] = v end) end
    AllDrawings[obj] = true
    return obj
end

local function set(obj, props)
    if not obj then return end
    for k, v in pairs(props) do pcall(function() obj[k] = v end) end
end

-- ── Full box ───────────────────────────────────────────────
local function makeFullBox()
    return {
        bg  = newDraw("Square", { Filled=true }),
        t   = newDraw("Line",   {}),
        b   = newDraw("Line",   {}),
        l   = newDraw("Line",   {}),
        r   = newDraw("Line",   {}),
        ot  = newDraw("Line",   { Color=BORDER_DARK }),
        ob  = newDraw("Line",   { Color=BORDER_DARK }),
        ol  = newDraw("Line",   { Color=BORDER_DARK }),
        or_ = newDraw("Line",   { Color=BORDER_DARK }),
    }
end

local function drawFullBox(bx, tl, tr, bl, br, col, thick)
    local oth = thick + 2
    set(bx.bg, { Visible=true, Position=tl, Size=br-tl, Color=DARK_BG, Transparency=0.82, Filled=true })
    local segs = {
        {bx.t, bx.ot, tl, tr}, {bx.b, bx.ob, bl, br},
        {bx.l, bx.ol, tl, bl}, {bx.r, bx.or_,tr, br},
    }
    for _, s in ipairs(segs) do
        set(s[1], { Visible=true, From=s[3], To=s[4], Color=col,         Thickness=thick, Transparency=1   })
        set(s[2], { Visible=true, From=s[3], To=s[4], Color=BORDER_DARK, Thickness=oth,   Transparency=0.5 })
    end
end

local function hideFullBox(bx)
    for _, obj in pairs(bx) do
        if obj then pcall(function() obj.Visible = false end) end
    end
end

local function removeFullBox(bx)
    for _, obj in pairs(bx) do
        pcall(function() obj:Remove(); AllDrawings[obj] = nil end)
    end
end

-- ── Corner box ─────────────────────────────────────────────
local CRATIO = 0.28

local function makeCornerBox()
    local s = {}
    for i = 1, 16 do s[i] = newDraw("Line", {}) end
    return s
end

local function drawCornerBox(segs, tl, tr, bl, br, col, thick)
    local w   = tr - tl
    local h   = bl - tl
    local cw  = w * CRATIO
    local ch  = h * CRATIO
    local oth = thick + 2
    local corners = {
        {tl, tl+cw, tl+ch}, {tr, tr-cw, tr+ch},
        {bl, bl+cw, bl-ch}, {br, br-cw, br-ch},
    }
    for ci, c in ipairs(corners) do
        local i1 = (ci-1)*2+1
        local i2 = i1+1
        set(segs[i1],     { Visible=true, From=c[1], To=c[2], Color=col,         Thickness=thick, Transparency=1   })
        set(segs[i2],     { Visible=true, From=c[1], To=c[3], Color=col,         Thickness=thick, Transparency=1   })
        set(segs[i1 + 8], { Visible=true, From=c[1], To=c[2], Color=BORDER_DARK, Thickness=oth,   Transparency=0.5 })
        set(segs[i2 + 8], { Visible=true, From=c[1], To=c[3], Color=BORDER_DARK, Thickness=oth,   Transparency=0.5 })
    end
end

local function hideCornerBox(segs)
    for _, s in ipairs(segs) do pcall(function() s.Visible = false end) end
end

local function removeCornerBox(segs)
    for _, s in ipairs(segs) do
        pcall(function() s:Remove(); AllDrawings[s] = nil end)
    end
end

-- ── Chams ──────────────────────────────────────────────────
local AllHighlights = {}

local function destroyHighlight(player)
    local h = AllHighlights[player]
    if h then pcall(function() h:Destroy() end) end
    AllHighlights[player] = nil
end

local function applyHighlight(player, char, col)
    if not CFG.ShowChams or not CFG.Enabled then
        destroyHighlight(player); return
    end
    local h = AllHighlights[player]
    if not h or not h.Parent or h.Adornee ~= char then
        destroyHighlight(player)
        local ok
        ok, h = pcall(function()
            local hl = Instance.new("Highlight")
            hl.FillTransparency    = CFG.ChamsFillTrans
            hl.OutlineTransparency = CFG.ChamsOutlineTrans
            hl.Adornee             = char
            hl.Parent              = LP.PlayerGui
            return hl
        end)
        if not ok then return end
        AllHighlights[player] = h
    end
    pcall(function()
        h.FillColor           = col
        h.OutlineColor        = col
        h.FillTransparency    = CFG.ChamsFillTrans
        h.OutlineTransparency = CFG.ChamsOutlineTrans
        h.Enabled             = true
    end)
end

-- ── Per-player objects ─────────────────────────────────────
local ESPObjects = {}

local function makePlayerESP(player)
    if ESPObjects[player] then return end
    ESPObjects[player] = {
        fullBox   = makeFullBox(),
        cornerBox = makeCornerBox(),
        tracer    = newDraw("Line",   { Thickness=1, Transparency=1 }),
        tracerOL  = newDraw("Line",   { Color=BORDER_DARK, Thickness=3, Transparency=0.4 }),
        nameTag   = newDraw("Text",   { Center=true, Outline=true }),
        distTag   = newDraw("Text",   { Center=true, Outline=true }),
        hpBarBg   = newDraw("Square", { Filled=true, Color=DARK_BG }),
        hpBar     = newDraw("Square", { Filled=true }),
        headDot   = newDraw("Circle", { Filled=true,  NumSides=30 }),
        headDotOL = newDraw("Circle", { Filled=false, NumSides=30, Color=BORDER_DARK }),
    }
end

local function removePlayerESP(player)
    local d = ESPObjects[player]
    if d then
        removeFullBox(d.fullBox)
        removeCornerBox(d.cornerBox)
        for k, obj in pairs(d) do
            if k ~= "fullBox" and k ~= "cornerBox" then
                pcall(function() obj:Remove(); AllDrawings[obj] = nil end)
            end
        end
        ESPObjects[player] = nil
    end
    destroyHighlight(player)
end

local function hidePlayerAll(d, player)
    hideFullBox(d.fullBox)
    hideCornerBox(d.cornerBox)
    d.tracer.Visible    = false
    d.tracerOL.Visible  = false
    d.nameTag.Visible   = false
    d.distTag.Visible   = false
    d.hpBar.Visible     = false
    d.hpBarBg.Visible   = false
    d.headDot.Visible   = false
    d.headDotOL.Visible = false
    destroyHighlight(player)
end

-- ── Cleanup ────────────────────────────────────────────────
local ESP_BIND        = "SentenceHub_ESP_v23"
local CharConnections = {}

local function teardownCharacterConnections(player)
    local conns = CharConnections[player]
    if conns then
        for _, conn in ipairs(conns) do pcall(function() conn:Disconnect() end) end
        CharConnections[player] = nil
    end
end

local function ESPCleanup()
    pcall(function() RunService:UnbindFromRenderStep(ESP_BIND) end)
    for player in pairs(CharConnections) do teardownCharacterConnections(player) end
    for player in pairs(ESPObjects)      do removePlayerESP(player)              end
    for obj    in pairs(AllDrawings)     do pcall(function() obj:Remove() end)   end
    table.clear(AllDrawings)
    for player in pairs(AllHighlights)   do destroyHighlight(player)             end
end

_GUI_PARENT.ChildRemoved:Connect(function(child)
    if child:IsA("ScreenGui") then task.delay(0.05, ESPCleanup) end
end)

-- ── Render loop ────────────────────────────────────────────
RunService:UnbindFromRenderStep(ESP_BIND)
RunService:BindToRenderStep(ESP_BIND, Enum.RenderPriority.Camera.Value + 1, function()
    rainbowHue = (tick() * 0.4) % 1

    local camPos = Camera.CFrame.Position
    local vp     = Camera.ViewportSize
    local tOrig  = tracerOrigin()

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LP then continue end

        local d = ESPObjects[player]
        if not d then continue end

        local char = player.Character
        if not char then hidePlayerAll(d, player); continue end

        local hum  = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")

        if not (hum and root and head)                                    then hidePlayerAll(d, player); continue end
        if hum:GetState() == Enum.HumanoidStateType.Dead or hum.Health<=0 then hidePlayerAll(d, player); continue end
        if not CFG.Enabled                                                 then hidePlayerAll(d, player); continue end

        -- TeamCheck: gdy włączony, ukryj ESP dla graczy z tej samej drużyny
        if CFG.TeamCheck and isTeammate(player) then hidePlayerAll(d, player); continue end

        local dist = (camPos - head.Position).Magnitude
        if dist > CFG.MaxDistance then hidePlayerAll(d, player); continue end

        local col      = getColor(player)
        local nameSize = scaledTextSize(CFG.TextSize, dist)
        local infoSize = scaledTextSize(math.floor(CFG.TextSize * 0.8), dist)

        local headSP, _, headZ = W2S(head.Position)
        local topSP,  _, topZ  = W2S((root.CFrame * CFrame.new(0,  root.Size.Y*0.55 + head.Size.Y*0.55, 0)).p)
        local botSP,  _, botZ  = W2S((root.CFrame * CFrame.new(0, -root.Size.Y*1.25, 0)).p)

        if CFG.ShowTracers and headZ ~= 0 then
            local tDest = headSP
            if headZ < 0 then
                tDest = V2(math.clamp(vp.X-headSP.X, 0, vp.X), math.clamp(vp.Y-headSP.Y, 0, vp.Y))
            end
            local alpha = math.clamp(1 - dist/(CFG.MaxDistance*0.85), 0.2, 0.9)
            set(d.tracer,   { Visible=true, From=tOrig, To=tDest, Color=col,         Thickness=CFG.TracerThickness,     Transparency=alpha     })
            set(d.tracerOL, { Visible=true, From=tOrig, To=tDest, Color=BORDER_DARK, Thickness=CFG.TracerThickness + 2, Transparency=alpha*0.4 })
        else
            d.tracer.Visible   = false
            d.tracerOL.Visible = false
        end

        if headZ<=0 or topZ<=0 or botZ<=0 then
            hideFullBox(d.fullBox); hideCornerBox(d.cornerBox)
            d.nameTag.Visible=false; d.distTag.Visible=false
            d.hpBar.Visible=false;   d.hpBarBg.Visible=false
            d.headDot.Visible=false; d.headDotOL.Visible=false
            continue
        end

        local boxH  = math.abs(botSP.Y - topSP.Y)
        local halfW = math.max(boxH * 0.3, 14)
        local tl    = V2(headSP.X - halfW, topSP.Y)
        local tr    = V2(headSP.X + halfW, topSP.Y)
        local bl    = V2(headSP.X - halfW, botSP.Y)
        local br    = V2(headSP.X + halfW, botSP.Y)

        if CFG.ShowBoxes then
            if CFG.BoxStyle == "Full" then
                drawFullBox(d.fullBox, tl, tr, bl, br, col, CFG.BoxThickness)
                hideCornerBox(d.cornerBox)
            else
                hideFullBox(d.fullBox)
                drawCornerBox(d.cornerBox, tl, tr, bl, br, col, CFG.BoxThickness)
            end
        else
            hideFullBox(d.fullBox); hideCornerBox(d.cornerBox)
        end

        applyHighlight(player, char, col)

        if CFG.ShowHealthBar then
            local hp    = math.clamp(hum.Health, 0, hum.MaxHealth)
            local pct   = hum.MaxHealth > 0 and (hp / hum.MaxHealth) or 0
            local bw    = CFG.HealthBarWidth
            local bx    = tl.X - bw - 3
            local hpCol = Color3.fromRGB(
                math.floor(255*(1-pct)), math.floor(200*pct+55), 50
            )
            set(d.hpBarBg, { Visible=true, Filled=true, Position=V2(bx-1,topSP.Y-1), Size=V2(bw+2,boxH+2), Color=DARK_BG, Transparency=0.5 })
            set(d.hpBar,   { Visible=true, Filled=true, Position=V2(bx,topSP.Y+boxH*(1-pct)), Size=V2(bw,math.max(boxH*pct,1)), Color=hpCol, Transparency=1 })
        else
            d.hpBar.Visible=false; d.hpBarBg.Visible=false
        end

        if CFG.ShowHeadDot then
            local r = math.clamp(CFG.HeadDotSize*(120/math.max(dist,1)), 2, 14)
            set(d.headDot,  { Visible=true, Position=headSP, Radius=r,   Color=col,         Filled=true,  Thickness=0, NumSides=30 })
            set(d.headDotOL,{ Visible=true, Position=headSP, Radius=r+1, Color=BORDER_DARK, Filled=false, Thickness=2, NumSides=30 })
        else
            d.headDot.Visible=false; d.headDotOL.Visible=false
        end

        local tagY = topSP.Y - 6
        if CFG.ShowNames then
            set(d.nameTag, {
                Visible=true, Text=player.Name, Size=nameSize,
                Color=Color3.fromRGB(255, 255, 255),
                Position=V2(headSP.X, tagY-nameSize),
                Outline=true, OutlineColor=Color3.fromRGB(0,0,0),
                Transparency=1, Center=true,
            })
            tagY = tagY - nameSize - 4
        else
            d.nameTag.Visible = false
        end

        local info = ""
        if CFG.ShowDistance then info = string.format("%.0fm", dist) end
        if CFG.ShowHealth and hum.MaxHealth > 0 then
            local pct = math.floor(hum.Health / hum.MaxHealth * 100)
            info = info .. (info ~= "" and "  |  " or "") .. string.format("HP %d%%", pct)
        end

        if info ~= "" then
            set(d.distTag, {
                Visible=true, Text=info, Size=infoSize, Color=col,
                Position=V2(headSP.X, tagY-infoSize),
                Outline=true, OutlineColor=Color3.fromRGB(0,0,0),
                Transparency=1, Center=true,
            })
        else
            d.distTag.Visible = false
        end
    end
end)

-- ── Player management ──────────────────────────────────────
local function onCharacterRemoving(player)
    destroyHighlight(player)
    local d = ESPObjects[player]
    if d then hidePlayerAll(d, player) end
end

local function onCharacterAdded(player, char)
    destroyHighlight(player)
    char:WaitForChild("HumanoidRootPart", 5)
    char:WaitForChild("Head",             5)
    char:WaitForChild("Humanoid",         5)
    makePlayerESP(player)
end

local function setupCharacterConnections(player)
    local old = CharConnections[player]
    if old then
        for _, conn in ipairs(old) do pcall(function() conn:Disconnect() end) end
    end
    CharConnections[player] = {
        player.CharacterRemoving:Connect(function()    onCharacterRemoving(player)    end),
        player.CharacterAdded:Connect(function(char)   onCharacterAdded(player, char) end),
    }
    if player.Character then makePlayerESP(player) end
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then makePlayerESP(p); setupCharacterConnections(p) end
end

Players.PlayerAdded:Connect(function(p)
    task.wait(0.1)
    makePlayerESP(p)
    setupCharacterConnections(p)
end)

Players.PlayerRemoving:Connect(function(p)
    teardownCharacterConnections(p)
    removePlayerESP(p)
end)

-- ════════════════════════════════════════════════════════════
-- VISUALS TAB
-- ════════════════════════════════════════════════════════════
local TabVis = Window:CreateTab({
    Name      = "Visuals",
    Icon      = "rbxassetid://6031280882",
    ShowTitle = true,
})

local S1 = TabVis:CreateSection("ESP")

S1:CreateToggle({ Name="Enabled",           Default=false, Callback=function(v) CFG.Enabled      = v end })
S1:CreateToggle({ Name="Names",             Default=false, Callback=function(v) CFG.ShowNames     = v end })
S1:CreateToggle({ Name="Distance & Health", Default=false, Callback=function(v) CFG.ShowDistance  = v; CFG.ShowHealth = v end })
S1:CreateToggle({ Name="Health Bar",        Default=false, Callback=function(v) CFG.ShowHealthBar = v end })
S1:CreateToggle({ Name="Bounding Box",      Default=false, Callback=function(v) CFG.ShowBoxes     = v end })
S1:CreateToggle({ Name="Tracers",           Default=false, Callback=function(v) CFG.ShowTracers   = v end })
S1:CreateToggle({ Name="Head Dot",          Default=false, Callback=function(v) CFG.ShowHeadDot   = v end })
S1:CreateToggle({
    Name     = "Chams",
    Default  = false,
    Callback = function(v)
        CFG.ShowChams = v
        if not v then for p in pairs(AllHighlights) do destroyHighlight(p) end end
    end,
})
S1:CreateToggle({ Name="Team Check", Default=false, Callback=function(v) CFG.ShowTeam = v end })

local S2 = TabVis:CreateSection("Appearance")

S2:CreateDropdown({ Name="Box Style",     Options={"Corner","Full"},          Default="Corner", Callback=function(v) CFG.BoxStyle     = v end })
S2:CreateDropdown({ Name="Tracer Origin", Options={"Bottom","Center","Mouse"},Default="Bottom", Callback=function(v) CFG.TracerOrigin = v end })
S2:CreateSlider({ Name="Render Distance",    Range={50,10000}, Default=250, Increment=50, Callback=function(v) CFG.MaxDistance      = v end })
S2:CreateSlider({ Name="Box Thickness",      Range={1,5},      Default=1,   Increment=1,  Callback=function(v) CFG.BoxThickness     = v end })
S2:CreateSlider({ Name="Tracer Thickness",   Range={1,5},      Default=1,   Increment=1,  Callback=function(v) CFG.TracerThickness  = v end })
S2:CreateSlider({
    Name="Chams Fill Opacity", Range={0,100}, Default=55, Increment=5,
    Callback=function(v)
        CFG.ChamsFillTrans = v / 100
        for _, h in pairs(AllHighlights) do pcall(function() h.FillTransparency = CFG.ChamsFillTrans end) end
    end,
})
S2:CreateSlider({
    Name="Chams Outline Opacity", Range={0,100}, Default=0, Increment=5,
    Callback=function(v)
        CFG.ChamsOutlineTrans = v / 100
        for _, h in pairs(AllHighlights) do pcall(function() h.OutlineTransparency = CFG.ChamsOutlineTrans end) end
    end,
})

local S3 = TabVis:CreateSection("Colors")

S3:CreateToggle({ Name="Rainbow Mode", Default=false, Callback=function(v) CFG.RainbowMode = v end })
S3:CreateColorPicker({ Name="Enemy Color", Default=CFG.EnemyColor, Callback=function(v) CFG.EnemyColor = v end })
S3:CreateColorPicker({ Name="Team Color",  Default=CFG.TeamColor,  Callback=function(v) CFG.TeamColor  = v end })

-- ════════════════════════════════════════════════════════════
-- DONE
-- ════════════════════════════════════════════════════════════
print("[ SENTENCE ] Universal script loaded.")

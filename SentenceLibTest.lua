--[[
╔══════════════════════════════════════════════════════════════╗
║  SENTENCE GUI  ·  OG Sentence Edition  ·  v2.2              ║
╚══════════════════════════════════════════════════════════════╝
--]]

local Sentence = {
    Version = "2.2",
    Flags   = {},
    Options = {},
    _conns  = {},
}

-- ── Serwisy ───────────────────────────────────────────────────
local TS   = game:GetService("TweenService")
local UIS  = game:GetService("UserInputService")
local RS   = game:GetService("RunService")
local Plrs = game:GetService("Players")
local CG   = game:GetService("CoreGui")
local LP   = Plrs.LocalPlayer
local Cam  = workspace.CurrentCamera
local IsStudio = RS:IsStudio()

-- ── Skala 110% ────────────────────────────────────────────────
local SCALE = 1.10

-- ── Hex → Color3 ─────────────────────────────────────────────
local function HC(hex)
    hex = hex:gsub("#","")
    return Color3.fromRGB(
        tonumber("0x"..hex:sub(1,2)),
        tonumber("0x"..hex:sub(3,4)),
        tonumber("0x"..hex:sub(5,6))
    )
end

-- ══════════════════════════════════════════════════════════════
-- MOTYW
-- ══════════════════════════════════════════════════════════════
local Theme = {
    PrimaryBackground   = HC("#0e0e0e"),
    SecondaryBackground = HC("#141414"),
    TertiaryBackground  = HC("#1c1c1c"),
    SurfaceBackground   = HC("#181818"),
    ElevatedSurface     = HC("#202020"),

    BorderColor         = HC("#2a2a2a"),
    BorderSubtle        = HC("#1e1e1e"),
    BorderAccent        = HC("#3a5a8a"),

    AccentColor         = HC("#4d9de0"),
    AccentDim           = HC("#2a5a8a"),
    AccentGlow          = HC("#3a7abf"),

    TextPrimary         = HC("#e6e6e6"),
    TextSecondary       = HC("#787878"),
    TextMuted           = HC("#505050"),
    TextAccent          = HC("#4d9de0"),

    ButtonNormal        = HC("#1a1a1a"),
    ButtonHover         = HC("#222222"),
    ButtonActive        = HC("#161616"),

    ScrollBar           = HC("#2a2a2a"),
    
    -- Splash Screen
    SplashBackground    = HC("#080808"),
    SplashAccent        = HC("#4d9de0"),
    SplashGlow          = HC("#2a5a8a"),
    SplashText          = HC("#e6e6e6"),
    SplashSubtext       = HC("#505050"),
}

local NotifColors = {
    Info    = Theme.AccentColor,
    Success = HC("#00c97a"),
    Warning = HC("#f0a500"),
    Error   = HC("#e03c3c"),
}

-- ── Tween helpers ─────────────────────────────────────────────
local function TI(t, s, d)
    return TweenInfo.new(t or .18, s or Enum.EasingStyle.Exponential, d or Enum.EasingDirection.Out)
end
local TI_FAST   = TI(.14)
local TI_MED    = TI(.24)
local TI_SLOW   = TI(.48)
local TI_SPRING = TweenInfo.new(.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function tw(o, p, info, cb)
    local t = TS:Create(o, info or TI_MED, p)
    if cb then t.Completed:Once(cb) end
    t:Play(); return t
end

-- ── Utilities ─────────────────────────────────────────────────
local function merge(d, t)
    t = t or {}
    for k, v in pairs(d) do if t[k] == nil then t[k] = v end end
    return t
end
local function track(c)  table.insert(Sentence._conns, c); return c end
local function safe(cb, ...) local ok, e = pcall(cb, ...); if not ok then warn("SENTENCE: "..tostring(e)) end end

-- Skalowanie wartości pikseli
local function S(v) return math.floor(v * SCALE + 0.5) end

local ICONS = {
    close  = "rbxassetid://6031094678",
    min    = "rbxassetid://6031094687",
    hide   = "rbxassetid://6031075929",
    home   = "rbxassetid://6026568195",
    info   = "rbxassetid://6026568227",
    warn   = "rbxassetid://6031071053",
    ok     = "rbxassetid://6031094667",
    chev_d = "rbxassetid://6031094687",
    arr    = "rbxassetid://6031090995",
    notif  = "rbxassetid://6034308946",
    unk    = "rbxassetid://6031079152",
}
local function ico(n)
    if not n or n=="" then return "" end
    if n:find("rbxassetid") then return n end
    if tonumber(n) then return "rbxassetid://"..n end
    return ICONS[n] or ICONS.unk
end

-- ══════════════════════════════════════════════════════════════
-- KOMPONENTY UI
-- ══════════════════════════════════════════════════════════════
local function Box(p)
    p = p or {}
    local f = Instance.new("Frame")
    f.Name                   = p.Name or "Box"
    f.Size                   = p.Sz   or UDim2.new(1,0,0, S(36))
    f.Position               = p.Pos  or UDim2.new()
    f.AnchorPoint            = p.AP   or Vector2.zero
    f.BackgroundColor3       = p.Bg   or Theme.SecondaryBackground
    f.BackgroundTransparency = p.BgA  or 0
    f.BorderSizePixel        = 0
    f.ZIndex                 = p.Z    or 1
    f.LayoutOrder            = p.Ord  or 0
    f.Visible                = p.Vis ~= false
    if p.Clip  then f.ClipsDescendants = true end
    if p.AutoY then f.AutomaticSize = Enum.AutomaticSize.Y end
    if p.AutoX then f.AutomaticSize = Enum.AutomaticSize.X end
    if p.R ~= nil then
        local uc = Instance.new("UICorner")
        uc.CornerRadius = type(p.R)=="number" and UDim.new(0,p.R) or (p.R or UDim.new(0, S(5)))
        uc.Parent = f
    end
    if p.Border then
        local s = Instance.new("UIStroke")
        s.Color           = p.BorderCol or Theme.BorderColor
        s.Transparency    = p.BorderA   or 0
        s.Thickness       = p.BorderThk or 1
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent = f
    end
    if p.Par then f.Parent = p.Par end
    return f
end

local function Txt(p)
    p = p or {}
    local l = Instance.new("TextLabel")
    l.Name                   = p.Name  or "Txt"
    l.Text                   = p.T     or ""
    l.Size                   = p.Sz    or UDim2.new(1,0,0, S(14))
    l.Position               = p.Pos   or UDim2.new()
    l.AnchorPoint            = p.AP    or Vector2.zero
    l.Font                   = p.Font  or Enum.Font.GothamSemibold
    l.TextSize               = p.TS    or S(13)
    l.TextColor3             = p.Col   or Theme.TextPrimary
    l.TextTransparency       = p.Alpha or 0
    l.TextXAlignment         = p.AX    or Enum.TextXAlignment.Left
    l.TextYAlignment         = p.AY    or Enum.TextYAlignment.Center
    l.TextWrapped            = p.Wrap  or false
    l.RichText               = false
    l.BackgroundTransparency = 1
    l.BorderSizePixel        = 0
    l.ZIndex                 = p.Z     or 2
    l.LayoutOrder            = p.Ord   or 0
    if p.AutoY then l.AutomaticSize = Enum.AutomaticSize.Y end
    if p.AutoX then l.AutomaticSize = Enum.AutomaticSize.X end
    if p.Par   then l.Parent = p.Par end
    return l
end

local function Img(p)
    p = p or {}
    local i = Instance.new("ImageLabel")
    i.Name                   = p.Name or "Img"
    i.Image                  = ico(p.Ico or "")
    i.Size                   = p.Sz   or UDim2.new(0, S(18), 0, S(18))
    i.Position               = p.Pos  or UDim2.new(0.5,0,0.5,0)
    i.AnchorPoint            = p.AP   or Vector2.new(0.5,0.5)
    i.ImageColor3            = p.Col  or Theme.TextPrimary
    i.ImageTransparency      = p.IA   or 0
    i.BackgroundTransparency = 1
    i.BorderSizePixel        = 0
    i.ZIndex                 = p.Z    or 3
    i.ScaleType              = Enum.ScaleType.Fit
    if p.Par then i.Parent = p.Par end
    return i
end

local function Btn(par, z)
    local b = Instance.new("TextButton")
    b.Name                   = "Btn"
    b.Size                   = UDim2.new(1,0,1,0)
    b.BackgroundTransparency = 1
    b.Text                   = ""
    b.ZIndex                 = z or 8
    b.Parent                 = par
    return b
end

local function List(par, gap, dir, ha, va)
    local l = Instance.new("UIListLayout")
    l.SortOrder     = Enum.SortOrder.LayoutOrder
    l.Padding       = UDim.new(0, gap or S(4))
    l.FillDirection = dir or Enum.FillDirection.Vertical
    if ha then l.HorizontalAlignment = ha end
    if va then l.VerticalAlignment   = va end
    l.Parent = par; return l
end

local function Pad(par, top, bot, lft, rgt)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top or 0)
    p.PaddingBottom = UDim.new(0, bot or 0)
    p.PaddingLeft   = UDim.new(0, lft or 0)
    p.PaddingRight  = UDim.new(0, rgt or 0)
    p.Parent = par; return p
end

local function Wire(par, vertical, color)
    local f = Instance.new("Frame")
    f.BackgroundColor3       = color or Theme.BorderColor
    f.BackgroundTransparency = 0
    f.BorderSizePixel        = 0
    f.ZIndex                 = 2
    f.Size = vertical and UDim2.new(0,1,1,0) or UDim2.new(1,0,0,1)
    f.Parent = par; return f
end

local function applyGradient(frame, c0, c1, rot)
    local g = Instance.new("UIGradient")
    g.Color    = ColorSequence.new(c0, c1)
    g.Rotation = rot or 90
    g.Parent   = frame
    return g
end

-- ── Draggable ─────────────────────────────────────────────────
local function Draggable(handle, win)
    local dragging, dragStart, startPos = false
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = inp.Position
            startPos  = win.Position
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if (inp.UserInputType == Enum.UserInputType.MouseMovement
        or  inp.UserInputType == Enum.UserInputType.Touch) and dragging then
            local d = inp.Position - dragStart
            TS:Create(win, TweenInfo.new(0.07, Enum.EasingStyle.Sine), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                     startPos.Y.Scale, startPos.Y.Offset + d.Y),
            }):Play()
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
-- NOTYFIKACJE
-- ══════════════════════════════════════════════════════════════
function Sentence:Notify(data)
    task.spawn(function()
        data = merge({ Title="Notice", Content="", Icon="info", Type="Info", Duration=4 }, data)
        local ac = NotifColors[data.Type] or Theme.AccentColor

        local card = Box({
            Name      = "NCard",
            Sz        = UDim2.new(0, S(300), 0, 0),
            Pos       = UDim2.new(0, 0, 1, 0),
            AP        = Vector2.new(0, 1),
            Bg        = HC("#181818"),
            BgA       = 1,
            Clip      = true,
            R         = S(6),
            Border    = true,
            BorderCol = Theme.BorderColor,
            BorderA   = 1,
            Par       = self._notifHolder,
        })

        local strip = Box({ Sz=UDim2.new(0,3,1,0), Pos=UDim2.new(0,0,0,0), Bg=ac, R=0, Z=5, Par=card })
        local glow = Box({ Sz=UDim2.new(1,0,1,0), Bg=ac, BgA=0.88, R=0, Z=1, Par=card })
        applyGradient(glow, ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
                             ColorSequenceKeypoint.new(1, Color3.new(1,1,1)), 90)
        local gg = Instance.new("UIGradient")
        gg.Color    = ColorSequence.new{
            ColorSequenceKeypoint.new(0, ac),
            ColorSequenceKeypoint.new(1, Theme.PrimaryBackground),
        }
        gg.Rotation = 0
        gg.Parent   = glow

        local content = Box({ Name="Content", Sz=UDim2.new(1,0,0,0), Bg=HC("#181818"), BgA=0, AutoY=true, Z=3, Par=card })
        Pad(content, S(12), S(12), S(38), S(14))
        List(content, S(4))

        local iconBox = Box({ Sz=UDim2.new(0, S(22), 0, S(22)), Pos=UDim2.new(0, S(10), 0, S(10)), Bg=Theme.TertiaryBackground, R=S(4), Z=5, Par=card })
        Img({ Ico=data.Icon, Sz=UDim2.new(0, S(13), 0, S(13)), Col=ac, IA=1, Z=6, Par=iconBox })

        local ttl = Txt({ T=data.Title, Sz=UDim2.new(1,0,0, S(16)), Font=Enum.Font.GothamBold, TS=S(13), Col=Theme.TextPrimary, Alpha=1, Z=5, Par=content })
        local msg = Txt({ T=data.Content, Sz=UDim2.new(1,0,0,0), Font=Enum.Font.Gotham, TS=S(12), Col=Theme.TextSecondary, Alpha=1, Wrap=true, AutoY=true, Z=5, Par=content })

        task.wait()
        local targetH = content.AbsoluteSize.Y
        tw(card,          { Size=UDim2.new(0, S(300), 0, targetH) },  TI_MED)
        tw(card,          { BackgroundTransparency=0 },          TI_FAST)
        if card:FindFirstChildOfClass("UIStroke") then
            tw(card:FindFirstChildOfClass("UIStroke"), { Transparency=0 }, TI_FAST)
        end
        tw(strip,         { BackgroundTransparency=0 },          TI_FAST)
        tw(iconBox,       { BackgroundTransparency=0 },          TI_FAST)
        tw(iconBox:FindFirstChildOfClass("ImageLabel"), { ImageTransparency=0 }, TI_FAST)
        tw(ttl,           { TextTransparency=0 },                TI_FAST)
        tw(msg,           { TextTransparency=0 },                TI_FAST)

        task.wait(data.Duration)

        tw(ttl,   { TextTransparency=1 },        TI_FAST)
        tw(msg,   { TextTransparency=1 },        TI_FAST)
        tw(strip, { BackgroundTransparency=1 },  TI_FAST)
        tw(card,  { BackgroundTransparency=1 },  TI_FAST)
        if card:FindFirstChildOfClass("UIStroke") then
            tw(card:FindFirstChildOfClass("UIStroke"), { Transparency=1 }, TI_FAST)
        end
        task.wait(0.14)
        tw(card, { Size=UDim2.new(0, S(300), 0, 0) }, TI_MED, function() card:Destroy() end)
    end)
end

-- ══════════════════════════════════════════════════════════════
-- SPLASH SCREEN - SENTENCE HUB
-- ══════════════════════════════════════════════════════════════
local function CreateSplashScreen(gui, cfg, onComplete)
    -- ── Splash overlay ────────────────────────────────────────
    local splash = Instance.new("Frame")
    splash.Name                   = "SplashScreen"
    splash.Size                   = UDim2.new(1, 0, 1, 0)
    splash.Position               = UDim2.new(0, 0, 0, 0)
    splash.BackgroundColor3       = Theme.SplashBackground
    splash.BackgroundTransparency = 0
    splash.BorderSizePixel        = 0
    splash.ZIndex                 = 500
    splash.Parent                 = gui

    -- ── Cząsteczki / pulsujące kółka tła ──────────────────────
    local particles = {}
    for i = 1, 8 do
        local p = Instance.new("Frame")
        p.Name                   = "Particle"..i
        p.Size                   = UDim2.new(0, math.random(80, 200), 0, math.random(80, 200))
        p.Position               = UDim2.new(math.random(10, 90)/100, 0, math.random(10, 90)/100, 0)
        p.AnchorPoint            = Vector2.new(0.5, 0.5)
        p.BackgroundColor3       = Theme.SplashAccent
        p.BackgroundTransparency = 0.92
        p.BorderSizePixel        = 0
        p.ZIndex                 = 501
        p.Parent                 = splash
        local uc = Instance.new("UICorner")
        uc.CornerRadius = UDim.new(1, 0)
        uc.Parent = p
        table.insert(particles, p)
    end

    -- Animuj cząsteczki
    for _, p in ipairs(particles) do
        task.spawn(function()
            while p and p.Parent do
                local targetPos = UDim2.new(
                    math.random(5, 95)/100, 0,
                    math.random(5, 95)/100, 0
                )
                local t = TS:Create(p, TweenInfo.new(
                    math.random(30, 60)/10,
                    Enum.EasingStyle.Sine,
                    Enum.EasingDirection.InOut
                ), { Position = targetPos, BackgroundTransparency = math.random(88, 96)/100 })
                t:Play()
                t.Completed:Wait()
            end
        end)
    end

    -- ── Centralna zawartość ───────────────────────────────────
    local centerFrame = Instance.new("Frame")
    centerFrame.Name                   = "Center"
    centerFrame.Size                   = UDim2.new(0, S(400), 0, S(280))
    centerFrame.Position               = UDim2.new(0.5, 0, 0.5, 0)
    centerFrame.AnchorPoint            = Vector2.new(0.5, 0.5)
    centerFrame.BackgroundTransparency = 1
    centerFrame.BorderSizePixel        = 0
    centerFrame.ZIndex                 = 510
    centerFrame.Parent                 = splash

    -- ── Logo ring (animowany pierścień) ───────────────────────
    local ringOuter = Instance.new("Frame")
    ringOuter.Name                   = "RingOuter"
    ringOuter.Size                   = UDim2.new(0, S(80), 0, S(80))
    ringOuter.Position               = UDim2.new(0.5, 0, 0, S(20))
    ringOuter.AnchorPoint            = Vector2.new(0.5, 0)
    ringOuter.BackgroundColor3       = Theme.SplashAccent
    ringOuter.BackgroundTransparency = 1
    ringOuter.BorderSizePixel        = 0
    ringOuter.ZIndex                 = 511
    ringOuter.Parent                 = centerFrame
    Instance.new("UICorner", ringOuter).CornerRadius = UDim.new(1, 0)
    local ringStroke = Instance.new("UIStroke")
    ringStroke.Color       = Theme.SplashAccent
    ringStroke.Thickness   = 2
    ringStroke.Transparency = 1
    ringStroke.Parent      = ringOuter

    -- ── Logo ikona (24x24 wewnątrz pierścienia) ───────────────
    local logoIcon
    if cfg.Icon and cfg.Icon ~= "" then
        logoIcon = Instance.new("ImageLabel")
        logoIcon.Name                   = "LogoIcon"
        logoIcon.Image                  = ico(cfg.Icon)
        logoIcon.Size                   = UDim2.new(0, 24, 0, 24)
        logoIcon.Position               = UDim2.new(0.5, 0, 0.5, 0)
        logoIcon.AnchorPoint            = Vector2.new(0.5, 0.5)
        logoIcon.ImageColor3            = Theme.SplashText
        logoIcon.ImageTransparency      = 1
        logoIcon.BackgroundTransparency = 1
        logoIcon.BorderSizePixel        = 0
        logoIcon.ZIndex                 = 512
        logoIcon.ScaleType              = Enum.ScaleType.Fit
        logoIcon.Parent                 = ringOuter
    end

    -- ── Pulsujący glow za pierścieniem ────────────────────────
    local glowCircle = Instance.new("Frame")
    glowCircle.Name                   = "Glow"
    glowCircle.Size                   = UDim2.new(0, S(80), 0, S(80))
    glowCircle.Position               = UDim2.new(0.5, 0, 0, S(20))
    glowCircle.AnchorPoint            = Vector2.new(0.5, 0)
    glowCircle.BackgroundColor3       = Theme.SplashAccent
    glowCircle.BackgroundTransparency = 1
    glowCircle.BorderSizePixel        = 0
    glowCircle.ZIndex                 = 510
    glowCircle.Parent                 = centerFrame
    Instance.new("UICorner", glowCircle).CornerRadius = UDim.new(1, 0)

    -- ── Tytuł "SENTENCE" ─────────────────────────────────────
    local titleSplash = Instance.new("TextLabel")
    titleSplash.Name                   = "SplashTitle"
    titleSplash.Text                   = "SENTENCE"
    titleSplash.Size                   = UDim2.new(1, 0, 0, S(36))
    titleSplash.Position               = UDim2.new(0.5, 0, 0, S(115))
    titleSplash.AnchorPoint            = Vector2.new(0.5, 0)
    titleSplash.Font                   = Enum.Font.GothamBold
    titleSplash.TextSize               = S(28)
    titleSplash.TextColor3             = Theme.SplashText
    titleSplash.TextTransparency       = 1
    titleSplash.TextXAlignment         = Enum.TextXAlignment.Center
    titleSplash.BackgroundTransparency = 1
    titleSplash.BorderSizePixel        = 0
    titleSplash.ZIndex                 = 511
    titleSplash.Parent                 = centerFrame

    -- ── Podtytuł "HUB" ───────────────────────────────────────
    local subtitleSplash = Instance.new("TextLabel")
    subtitleSplash.Name                   = "SplashSub"
    subtitleSplash.Text                   = "HUB"
    subtitleSplash.Size                   = UDim2.new(1, 0, 0, S(22))
    subtitleSplash.Position               = UDim2.new(0.5, 0, 0, S(150))
    subtitleSplash.AnchorPoint            = Vector2.new(0.5, 0)
    subtitleSplash.Font                   = Enum.Font.Code
    subtitleSplash.TextSize               = S(14)
    subtitleSplash.TextColor3             = Theme.SplashAccent
    subtitleSplash.TextTransparency       = 1
    subtitleSplash.TextXAlignment         = Enum.TextXAlignment.Center
    subtitleSplash.BackgroundTransparency = 1
    subtitleSplash.BorderSizePixel        = 0
    subtitleSplash.ZIndex                 = 511
    subtitleSplash.Parent                 = centerFrame

    -- ── Separator linia ──────────────────────────────────────
    local sepLine = Instance.new("Frame")
    sepLine.Name                   = "SepLine"
    sepLine.Size                   = UDim2.new(0, 0, 0, 1)
    sepLine.Position               = UDim2.new(0.5, 0, 0, S(182))
    sepLine.AnchorPoint            = Vector2.new(0.5, 0)
    sepLine.BackgroundColor3       = Theme.SplashAccent
    sepLine.BackgroundTransparency = 0.5
    sepLine.BorderSizePixel        = 0
    sepLine.ZIndex                 = 511
    sepLine.Parent                 = centerFrame

    -- ── Status text ──────────────────────────────────────────
    local statusText = Instance.new("TextLabel")
    statusText.Name                   = "Status"
    statusText.Text                   = "INITIALIZING"
    statusText.Size                   = UDim2.new(1, 0, 0, S(16))
    statusText.Position               = UDim2.new(0.5, 0, 0, S(195))
    statusText.AnchorPoint            = Vector2.new(0.5, 0)
    statusText.Font                   = Enum.Font.Code
    statusText.TextSize               = S(10)
    statusText.TextColor3             = Theme.SplashSubtext
    statusText.TextTransparency       = 1
    statusText.TextXAlignment         = Enum.TextXAlignment.Center
    statusText.BackgroundTransparency = 1
    statusText.BorderSizePixel        = 0
    statusText.ZIndex                 = 511
    statusText.Parent                 = centerFrame

    -- ── Progress bar ─────────────────────────────────────────
    local progressTrack = Instance.new("Frame")
    progressTrack.Name                   = "ProgressTrack"
    progressTrack.Size                   = UDim2.new(0, S(220), 0, S(3))
    progressTrack.Position               = UDim2.new(0.5, 0, 0, S(220))
    progressTrack.AnchorPoint            = Vector2.new(0.5, 0)
    progressTrack.BackgroundColor3       = HC("#1a1a1a")
    progressTrack.BackgroundTransparency = 1
    progressTrack.BorderSizePixel        = 0
    progressTrack.ZIndex                 = 511
    progressTrack.Parent                 = centerFrame
    Instance.new("UICorner", progressTrack).CornerRadius = UDim.new(0, S(2))

    local progressFill = Instance.new("Frame")
    progressFill.Name                   = "ProgressFill"
    progressFill.Size                   = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3       = Theme.SplashAccent
    progressFill.BackgroundTransparency = 0
    progressFill.BorderSizePixel        = 0
    progressFill.ZIndex                 = 512
    progressFill.Parent                 = progressTrack
    Instance.new("UICorner", progressFill).CornerRadius = UDim.new(0, S(2))
    local fillGrad = Instance.new("UIGradient")
    fillGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Theme.SplashAccent),
        ColorSequenceKeypoint.new(1, HC("#7dc8ff")),
    }
    fillGrad.Parent = progressFill

    -- ── Procent ──────────────────────────────────────────────
    local pctText = Instance.new("TextLabel")
    pctText.Name                   = "Pct"
    pctText.Text                   = "0%"
    pctText.Size                   = UDim2.new(1, 0, 0, S(14))
    pctText.Position               = UDim2.new(0.5, 0, 0, S(230))
    pctText.AnchorPoint            = Vector2.new(0.5, 0)
    pctText.Font                   = Enum.Font.Code
    pctText.TextSize               = S(9)
    pctText.TextColor3             = Theme.SplashAccent
    pctText.TextTransparency       = 1
    pctText.TextXAlignment         = Enum.TextXAlignment.Center
    pctText.BackgroundTransparency = 1
    pctText.BorderSizePixel        = 0
    pctText.ZIndex                 = 511
    pctText.Parent                 = centerFrame

    -- ── Wersja na dole ───────────────────────────────────────
    local verText = Instance.new("TextLabel")
    verText.Name                   = "Ver"
    verText.Text                   = "v"..Sentence.Version
    verText.Size                   = UDim2.new(1, 0, 0, S(14))
    verText.Position               = UDim2.new(0.5, 0, 1, -S(20))
    verText.AnchorPoint            = Vector2.new(0.5, 1)
    verText.Font                   = Enum.Font.Code
    verText.TextSize               = S(9)
    verText.TextColor3             = Theme.SplashSubtext
    verText.TextTransparency       = 1
    verText.TextXAlignment         = Enum.TextXAlignment.Center
    verText.BackgroundTransparency = 1
    verText.BorderSizePixel        = 0
    verText.ZIndex                 = 511
    verText.Parent                 = splash

    -- ══════════════════════════════════════════════════════════
    -- ANIMACJA SPLASH SCREEN
    -- ══════════════════════════════════════════════════════════

    -- Faza 1: Pojawianie się elementów (0 → 0.8s)
    task.wait(0.1)

    -- Ring glow pulse
    tw(glowCircle, { BackgroundTransparency = 0.85 }, TI(.6, Enum.EasingStyle.Sine))
    task.spawn(function()
        while glowCircle and glowCircle.Parent do
            tw(glowCircle, { Size = UDim2.new(0, S(100), 0, S(100)), BackgroundTransparency = 0.92 },
                TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            task.wait(1.2)
            tw(glowCircle, { Size = UDim2.new(0, S(80), 0, S(80)), BackgroundTransparency = 0.85 },
                TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            task.wait(1.2)
        end
    end)

    -- Ring pojawienie
    tw(ringStroke, { Transparency = 0 }, TI(.5, Enum.EasingStyle.Quad))
    tw(ringOuter, { BackgroundTransparency = 0.9 }, TI(.5, Enum.EasingStyle.Quad))
    task.wait(0.15)

    -- Logo ikona
    if logoIcon then
        tw(logoIcon, { ImageTransparency = 0 }, TI(.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
    end
    task.wait(0.15)

    -- Tytuł - litery po kolei (symulacja przez fade-in z przesunięciem)
    tw(titleSplash, { TextTransparency = 0, Position = UDim2.new(0.5, 0, 0, S(115)) },
        TI(.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
    titleSplash.Position = UDim2.new(0.5, 0, 0, S(125))
    tw(titleSplash, { Position = UDim2.new(0.5, 0, 0, S(115)), TextTransparency = 0 },
        TI(.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
    task.wait(0.2)

    -- Podtytuł
    subtitleSplash.Position = UDim2.new(0.5, 0, 0, S(158))
    tw(subtitleSplash, { TextTransparency = 0, Position = UDim2.new(0.5, 0, 0, S(150)) },
        TI(.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
    task.wait(0.15)

    -- Separator linia rozszerzająca się
    tw(sepLine, { Size = UDim2.new(0, S(180), 0, 1) }, TI(.5, Enum.EasingStyle.Quad))
    task.wait(0.1)

    -- Status, progress, pct, version
    tw(statusText, { TextTransparency = 0 }, TI(.3, Enum.EasingStyle.Quad))
    tw(progressTrack, { BackgroundTransparency = 0 }, TI(.3, Enum.EasingStyle.Quad))
    tw(pctText, { TextTransparency = 0 }, TI(.3, Enum.EasingStyle.Quad))
    tw(verText, { TextTransparency = 0.4 }, TI(.3, Enum.EasingStyle.Quad))

    -- Faza 2: Progress loading (0.8s → 2.2s)
    local statuses = {
        { pct = 0.12, text = "LOADING MODULES" },
        { pct = 0.25, text = "LOADING MODULES" },
        { pct = 0.38, text = "CONNECTING" },
        { pct = 0.52, text = "BUILDING INTERFACE" },
        { pct = 0.65, text = "BUILDING INTERFACE" },
        { pct = 0.78, text = "APPLYING THEME" },
        { pct = 0.88, text = "FINALIZING" },
        { pct = 0.95, text = "FINALIZING" },
        { pct = 1.00, text = "READY" },
    }

    for _, step in ipairs(statuses) do
        tw(progressFill, { Size = UDim2.new(step.pct, 0, 1, 0) }, TI(.18, Enum.EasingStyle.Quad))
        pctText.Text = math.floor(step.pct * 100).."%"
        statusText.Text = step.text
        
        -- Animuj ring na każdym kroku
        if step.pct < 1 then
            tw(ringStroke, { Color = Theme.SplashAccent:Lerp(HC("#7dc8ff"), step.pct) }, TI_FAST)
        end
        
        task.wait(0.13 + math.random() * 0.08)
    end

    -- Faza 3: Gotowe - krótki flash
    task.wait(0.15)
    statusText.Text = "READY"
    tw(ringOuter, { BackgroundTransparency = 0.7 }, TI(.2, Enum.EasingStyle.Quad))
    tw(ringStroke, { Color = HC("#7dc8ff") }, TI(.2, Enum.EasingStyle.Quad))
    task.wait(0.3)

    -- Faza 4: Zanikanie (2.5s → 3s)
    -- Fade out wszystkich elementów
    tw(pctText, { TextTransparency = 1 }, TI(.2))
    tw(statusText, { TextTransparency = 1 }, TI(.2))
    tw(progressTrack, { BackgroundTransparency = 1 }, TI(.2))
    tw(progressFill, { BackgroundTransparency = 1 }, TI(.2))
    task.wait(0.1)

    tw(sepLine, { BackgroundTransparency = 1, Size = UDim2.new(0, S(300), 0, 1) }, TI(.3, Enum.EasingStyle.Quad))
    tw(subtitleSplash, { TextTransparency = 1, Position = UDim2.new(0.5, 0, 0, S(145)) }, TI(.25))
    task.wait(0.05)
    tw(titleSplash, { TextTransparency = 1, Position = UDim2.new(0.5, 0, 0, S(110)) }, TI(.25))
    task.wait(0.05)

    if logoIcon then
        tw(logoIcon, { ImageTransparency = 1 }, TI(.2))
    end
    tw(ringStroke, { Transparency = 1 }, TI(.2))
    tw(ringOuter, { BackgroundTransparency = 1 }, TI(.2))
    tw(glowCircle, { BackgroundTransparency = 1 }, TI(.2))
    tw(verText, { TextTransparency = 1 }, TI(.2))

    -- Cząsteczki fade out
    for _, p in ipairs(particles) do
        tw(p, { BackgroundTransparency = 1 }, TI(.3))
    end

    task.wait(0.2)

    -- Całe tło splash zanika
    tw(splash, { BackgroundTransparency = 1 }, TI(.4, Enum.EasingStyle.Quad), function()
        splash:Destroy()
    end)

    task.wait(0.3)

    -- Callback: ładuj główne GUI
    if onComplete then
        onComplete()
    end
end

-- ══════════════════════════════════════════════════════════════
-- CREATE WINDOW
-- ══════════════════════════════════════════════════════════════
function Sentence:CreateWindow(cfg)
    cfg = merge({
        Name            = "SENTENCE",
        Subtitle        = "",
        Icon            = "",
        ToggleBind      = Enum.KeyCode.RightControl,
        LoadingEnabled  = true,
        LoadingTitle    = "SENTENCE",
        LoadingSubtitle = "INITIALISING",
        SplashScreen    = true,
        ConfigurationSaving = { Enabled=false, FolderName="Sentence", FileName="config" },
    }, cfg)

    -- ── Rozmiar okna (POWIĘKSZONY o 10%) ──────────────────────
    local vp   = Cam.ViewportSize
    local WW   = math.clamp(math.floor((vp.X - 80) * SCALE),  S(650), S(900))
    local WH   = math.clamp(math.floor((vp.Y - 60) * SCALE),  S(480), S(600))
    local FULL = UDim2.fromOffset(WW, WH)
    local TB_H = S(44)
    local MINI = UDim2.fromOffset(WW, TB_H)

    -- ── ScreenGui ─────────────────────────────────────────────
    local gui = Instance.new("ScreenGui")
    gui.Name           = "OGSentenceUI"
    gui.DisplayOrder   = 999999999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.ResetOnSpawn   = false
    gui.IgnoreGuiInset = true

    if gethui then
        gui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(gui); gui.Parent = CG
    elseif not IsStudio then
        gui.Parent = CG
    else
        gui.Parent = LP:WaitForChild("PlayerGui")
    end

    -- ── Notif holder ──────────────────────────────────────────
    local notifHolder = Instance.new("Frame")
    notifHolder.Name                   = "Notifs"
    notifHolder.Size                   = UDim2.new(0, S(304), 1, -S(16))
    notifHolder.Position               = UDim2.new(0, S(8), 0, S(8))
    notifHolder.BackgroundTransparency = 1
    notifHolder.ZIndex                 = 200
    notifHolder.Parent                 = gui
    local nList = List(notifHolder, S(8))
    nList.VerticalAlignment = Enum.VerticalAlignment.Bottom
    self._notifHolder = notifHolder

    -- ══════════════════════════════════════════════════════════
    -- SPLASH SCREEN
    -- ══════════════════════════════════════════════════════════
    local splashDone = false
    local mainGuiReady = Instance.new("BindableEvent")

    if cfg.SplashScreen then
        CreateSplashScreen(gui, cfg, function()
            splashDone = true
            mainGuiReady:Fire()
        end)
    else
        splashDone = true
    end

    -- Czekaj na splash jeśli włączony
    if cfg.SplashScreen and not splashDone then
        mainGuiReady.Event:Wait()
    end
    mainGuiReady:Destroy()

    -- ══════════════════════════════════════════════════════════
    -- GŁÓWNE OKNO (ładowane progresywnie po splashu)
    -- ══════════════════════════════════════════════════════════
    local win = Box({
        Name      = "Win",
        Sz        = UDim2.fromOffset(0, 0),
        Pos       = UDim2.new(0.5, 0, 0.5, 0),
        AP        = Vector2.new(0.5, 0.5),
        Bg        = Theme.PrimaryBackground,
        BgA       = 0,
        Clip      = true,
        R         = S(6),
        Border    = true,
        BorderCol = Theme.BorderColor,
        BorderA   = 0,
        Z         = 1,
        Par       = gui,
    })

    -- ── Tło okna: subtelny gradient ───────────────────────────
    local topLine = Box({
        Name = "TopLine",
        Sz   = UDim2.new(1, 0, 0, 2),
        Pos  = UDim2.new(0, 0, 0, 0),
        Bg   = Theme.AccentColor,
        BgA  = 0,
        Z    = 6,
        Par  = win,
    })
    local bgGrad = Box({
        Name = "BgGrad",
        Sz   = UDim2.new(1, 0, 1, 0),
        Bg   = HC("#141414"),
        BgA  = 0,
        Z    = 0,
        Par  = win,
    })
    local bgGradGrad = Instance.new("UIGradient")
    bgGradGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0,    HC("#1a1a1a")),
        ColorSequenceKeypoint.new(0.35, HC("#141414")),
        ColorSequenceKeypoint.new(1,    HC("#0e0e0e")),
    }
    bgGradGrad.Rotation = 110
    bgGradGrad.Parent   = bgGrad

    -- ── Title Bar ─────────────────────────────────────────────
    local titleBar = Box({
        Name = "TitleBar",
        Sz   = UDim2.new(1, 0, 0, TB_H),
        Pos  = UDim2.new(0, 0, 0, 2),
        Bg   = Theme.PrimaryBackground,
        BgA  = 1,
        Z    = 4,
        Par  = win,
    })
    local tbLine = Box({ Sz=UDim2.new(1,0,0,1), Pos=UDim2.new(0,0,1,-1), Bg=Theme.BorderColor, BgA=0, Z=5, Par=titleBar })

    Draggable(titleBar, win)

    -- ── Przyciski sterowania (lewy bok) ───────────────────────
    local CTRL = {
        { key="X", ico="close", hov=HC("#e03c3c") },
        { key="−", ico="min",   hov=Theme.TextSecondary },
        { key="·", ico="hide",  hov=Theme.TextSecondary },
    }
    local ctrlBtns = {}
    for idx, cd in ipairs(CTRL) do
        local xPos = S(10) + (idx-1) * S(30)
        local cb = Box({
            Name=cd.key, Sz=UDim2.new(0, S(24), 0, S(24)),
            Pos=UDim2.new(0,xPos,0.5,0), AP=Vector2.new(0,0.5),
            Bg=Theme.TertiaryBackground, BgA=0.5,
            R=S(5), Border=true, BorderCol=Theme.BorderColor, BorderA=0,
            Z=5, Par=titleBar,
        })
        local cIco = Img({ Ico=cd.ico, Sz=UDim2.new(0, S(12), 0, S(12)), Col=Theme.TextMuted, Z=6, Par=cb })
        local cCL  = Btn(cb, 7)
        cb.MouseEnter:Connect(function()
            tw(cb,   { BackgroundColor3=cd.hov, BackgroundTransparency=0 }, TI_FAST)
            tw(cIco, { ImageColor3=Color3.new(1,1,1) },                     TI_FAST)
        end)
        cb.MouseLeave:Connect(function()
            tw(cb,   { BackgroundColor3=Theme.TertiaryBackground, BackgroundTransparency=0.5 }, TI_FAST)
            tw(cIco, { ImageColor3=Theme.TextMuted },                                           TI_FAST)
        end)
        ctrlBtns[cd.key] = { frame=cb, click=cCL }
    end

    -- ── Logo / Ikona (24x24) ──────────────────────────────────
    local ICON_SIZE = 24
    local ICON_X    = S(108)
    local logoImg = Img({
        Ico=cfg.Icon, Sz=UDim2.new(0, ICON_SIZE, 0, ICON_SIZE),
        Pos=UDim2.new(0, ICON_X, 0.5, 0), AP=Vector2.new(0,0.5),
        Col=Theme.TextPrimary, Z=5, Par=titleBar,
    })
    local nameOffX = cfg.Icon ~= "" and (ICON_X + ICON_SIZE + S(8)) or ICON_X

    local nameLabel = Txt({
        T=cfg.Name, Sz=UDim2.new(0, S(240), 0, S(18)),
        Pos=UDim2.new(0, nameOffX, 0, S(7)),
        Font=Enum.Font.GothamBold, TS=S(16),
        Col=Theme.TextPrimary, Alpha=1, Z=5, Par=titleBar,
    })
    local subLabel = Txt({
        T=cfg.Subtitle ~= "" and ("/ "..cfg.Subtitle) or ("/ v"..Sentence.Version),
        Sz=UDim2.new(0, S(200), 0, S(13)), Pos=UDim2.new(0, nameOffX, 0, S(27)),
        Font=Enum.Font.Gotham, TS=S(12),
        Col=Theme.TextSecondary, Alpha=1, Z=5, Par=titleBar,
    })

    -- ── Status Bar (prawa strona paska tytułu) ────────────────
    local statWrap = Box({
        Sz=UDim2.new(0, S(150), 0, S(28)), Pos=UDim2.new(1, -S(12), 0.5, 0), AP=Vector2.new(1,0.5),
        Bg=Theme.SurfaceBackground, BgA=0, R=S(5),
        Border=true, BorderCol=Theme.BorderSubtle, BorderA=0,
        Z=5, Par=titleBar,
    })
    Pad(statWrap, 0, 0, S(10), S(10))
    List(statWrap, 0, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)

    local pingDot = Box({ Sz=UDim2.new(0, S(6), 0, S(6)), Bg=NotifColors.Success, R=S(3), Z=6, Par=statWrap })
    local pingL   = Txt({
        T="— ms", Sz=UDim2.new(0, S(55), 1, 0),
        Font=Enum.Font.Code, TS=S(11), Col=Theme.TextSecondary, Z=6,
        AX=Enum.TextXAlignment.Left, Par=statWrap,
    })
    local sep2 = Box({ Sz=UDim2.new(0, 1, 0.5, 0), Bg=Theme.BorderColor, BgA=0, Z=6, Par=statWrap })
    local plrsL = Txt({
        T="—/—", Sz=UDim2.new(0, S(55), 1, 0),
        Font=Enum.Font.Code, TS=S(11), Col=Theme.TextSecondary, Z=6,
        AX=Enum.TextXAlignment.Right, Par=statWrap,
    })

    task.spawn(function()
        while task.wait(1.5) do
            if not win or not win.Parent then break end
            pcall(function()
                local ping = math.floor(LP:GetNetworkPing() * 1000)
                pingL.Text  = ping.."ms"
                plrsL.Text  = #Plrs:GetPlayers().."/"..Plrs.MaxPlayers
                pingDot.BackgroundColor3 =
                    ping < 80  and NotifColors.Success or
                    ping < 180 and NotifColors.Warning or
                    NotifColors.Error
            end)
        end
    end)

    -- ══════════════════════════════════════════════════════════
    -- SIDEBAR (POWIĘKSZONY)
    -- ══════════════════════════════════════════════════════════
    local SIDE_W = S(54)
    local sidebar = Box({
        Name="Sidebar",
        Sz=UDim2.new(0, SIDE_W, 1, -TB_H-2),
        Pos=UDim2.new(0, 0, 0, TB_H+2),
        Bg=Theme.SurfaceBackground,
        BgA=0, Z=3, Par=win,
    })

    local sideWire = Box({
        Sz=UDim2.new(0, 1, 1, 0), Pos=UDim2.new(1, -1, 0, 0),
        Bg=Theme.BorderColor, BgA=0,
        Z=4, Par=sidebar,
    })
    local sideGrad = Box({ Sz=UDim2.new(1,0,1,0), Bg=Theme.SurfaceBackground, BgA=0, Z=0, Par=sidebar })
    local sgg = Instance.new("UIGradient")
    sgg.Color    = ColorSequence.new{ ColorSequenceKeypoint.new(0, HC("#1e1e1e")), ColorSequenceKeypoint.new(1, HC("#141414")) }
    sgg.Rotation = 90
    sgg.Parent   = sideGrad

    local tabIconsList = Instance.new("ScrollingFrame")
    tabIconsList.Name                   = "TabIcons"
    tabIconsList.Size                   = UDim2.new(1, 0, 1, -S(60))
    tabIconsList.Position               = UDim2.new(0, 0, 0, S(12))
    tabIconsList.BackgroundTransparency = 1
    tabIconsList.BorderSizePixel        = 0
    tabIconsList.ScrollBarThickness     = 0
    tabIconsList.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    tabIconsList.ZIndex                 = 4
    tabIconsList.Parent                 = sidebar
    List(tabIconsList, S(5), Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center)
    Pad(tabIconsList, S(4), S(4), 0, 0)

    -- Avatar na dole sidebaru
    local avBox = Box({
        Sz=UDim2.new(0, S(36), 0, S(36)), Pos=UDim2.new(0.5, 0, 1, -S(12)), AP=Vector2.new(0.5,1),
        Bg=Theme.TertiaryBackground, R=S(5), Z=4, Par=sidebar,
    })
    local avImg = Instance.new("ImageLabel")
    avImg.Size=UDim2.new(1,0,1,0); avImg.BackgroundTransparency=1; avImg.ZIndex=5
    Instance.new("UICorner",avImg).CornerRadius=UDim.new(0, S(5))
    local avStroke = Instance.new("UIStroke")
    avStroke.Color=Theme.AccentColor; avStroke.Thickness=1.5; avStroke.Transparency=0.5
    avStroke.Parent=avImg; avImg.Parent=avBox
    pcall(function() avImg.Image=Plrs:GetUserThumbnailAsync(LP.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size48x48) end)

    -- Tooltip
    local tooltip = Box({
        Name="Tooltip", Sz=UDim2.new(0,0,0, S(26)),
        Pos=UDim2.new(0, SIDE_W+S(5), 0, 0),
        Bg=Theme.ElevatedSurface, R=S(5),
        Border=true, BorderCol=Theme.BorderColor, BorderA=0,
        Z=20, Vis=false, Par=win,
    })
    tooltip.AutomaticSize = Enum.AutomaticSize.X
    Pad(tooltip, 0, 0, S(10), S(10))
    local tooltipL = Txt({ T="", Sz=UDim2.new(0,0,1,0), Font=Enum.Font.GothamSemibold, TS=S(12), Col=Theme.TextPrimary, Z=21, Par=tooltip })
    tooltipL.AutomaticSize = Enum.AutomaticSize.X

    -- Content area
    local contentArea = Box({
        Name="Content",
        Sz=UDim2.new(1, -SIDE_W-1, 1, -TB_H-2),
        Pos=UDim2.new(0, SIDE_W+1, 0, TB_H+2),
        Bg=Theme.PrimaryBackground,
        BgA=1, Clip=true, Z=2, Par=win,
    })

    -- ── State okna ────────────────────────────────────────────
    local W = {
        _gui       = gui,
        _win       = win,
        _content   = contentArea,
        _tabs      = {},
        _activeTab = nil,
        _visible   = true,
        _minimized = false,
        _cfg       = cfg,
    }

    local function SwitchTab(tabId)
        for _, tab in ipairs(W._tabs) do
            if tab.id == tabId then
                tab.page.Visible = true
                tw(tab.activeLine, { BackgroundTransparency=0 },          TI_FAST)
                tw(tab.iconImg,    { ImageColor3=Theme.AccentColor },      TI_FAST)
                tw(tab.bgBox,      { BackgroundColor3=Theme.AccentDim, BackgroundTransparency=0.6 }, TI_FAST)
                W._activeTab = tabId
            else
                tab.page.Visible = false
                tw(tab.activeLine, { BackgroundTransparency=1 },           TI_FAST)
                tw(tab.iconImg,    { ImageColor3=Theme.TextMuted },        TI_FAST)
                tw(tab.bgBox,      { BackgroundColor3=Theme.TertiaryBackground, BackgroundTransparency=1 }, TI_FAST)
            end
        end
    end

    -- ══════════════════════════════════════════════════════════
    -- PROGRESYWNE ŁADOWANIE GŁÓWNEGO GUI
    -- ══════════════════════════════════════════════════════════
    if cfg.LoadingEnabled then
        local lf = Box({ Name="Loading", Sz=UDim2.new(1,0,1,0), Bg=Theme.PrimaryBackground, BgA=0, Z=50, Par=win })
        Instance.new("UICorner",lf).CornerRadius = UDim.new(0, S(6))

        local lBgGrad = Box({ Sz=UDim2.new(1,0,1,0), Bg=HC("#1a1a1a"), BgA=0, Z=50, Par=lf })
        local lgg = Instance.new("UIGradient")
        lgg.Color    = ColorSequence.new{ ColorSequenceKeypoint.new(0,HC("#1c1c1c")), ColorSequenceKeypoint.new(1,HC("#0e0e0e")) }
        lgg.Rotation = 120
        lgg.Parent   = lBgGrad

        local lLogo  = Img({ Ico=cfg.Icon, Sz=UDim2.new(0, S(36), 0, S(36)), Pos=UDim2.new(0.5, 0, 0.5, -S(58)), AP=Vector2.new(0.5,0.5), Col=Theme.TextPrimary, IA=1, Z=51, Par=lf })
        local lTitle = Txt({ T=cfg.LoadingTitle,    Sz=UDim2.new(1,0,0, S(28)), Pos=UDim2.new(0.5,0,0.5,-S(16)), AP=Vector2.new(0.5,0.5), Font=Enum.Font.GothamBold, TS=S(22), Col=Theme.TextPrimary, AX=Enum.TextXAlignment.Center, Alpha=1, Z=51, Par=lf })
        local lSub   = Txt({ T=cfg.LoadingSubtitle, Sz=UDim2.new(1,0,0, S(14)), Pos=UDim2.new(0.5,0,0.5, S(18)), AP=Vector2.new(0.5,0.5), Font=Enum.Font.Code, TS=S(11), Col=Theme.TextSecondary, AX=Enum.TextXAlignment.Center, Alpha=1, Z=51, Par=lf })

        local pTrack = Box({ Sz=UDim2.new(0.42,0,0, S(4)), Pos=UDim2.new(0.5,0,0.5, S(48)), AP=Vector2.new(0.5,0.5), Bg=Theme.TertiaryBackground, R=S(2), Z=51, Par=lf })
        local pFill  = Box({ Sz=UDim2.new(0,0,1,0), Bg=Theme.AccentColor, R=S(2), Z=52, Par=pTrack })
        local pfGrad = Instance.new("UIGradient")
        pfGrad.Color  = ColorSequence.new{ ColorSequenceKeypoint.new(0,Theme.AccentColor), ColorSequenceKeypoint.new(1,HC("#7dc8ff")) }
        pfGrad.Parent = pFill
        local pctL   = Txt({ T="0%", Sz=UDim2.new(1,0,0, S(14)), Pos=UDim2.new(0.5,0,0.5, S(62)), AP=Vector2.new(0.5,0.5), Font=Enum.Font.Code, TS=S(10), Col=Theme.AccentColor, AX=Enum.TextXAlignment.Center, Z=51, Par=lf })

        tw(win, { Size=FULL }, TI_SLOW)
        task.wait(0.28)
        tw(lBgGrad, { BackgroundTransparency=0 }, TI_MED)
        tw(lTitle, { TextTransparency=0 }, TI_MED)
        task.wait(0.1)
        tw(lSub, { TextTransparency=0.25 }, TI_MED)
        if cfg.Icon ~= "" then tw(lLogo, { ImageTransparency=0 }, TI_MED) end

        local pct = 0
        for _, step in ipairs({ 0.1, 0.08, 0.14, 0.12, 0.16, 0.1, 0.14, 0.16 }) do
            pct = math.min(pct + step, 1)
            tw(pFill, { Size=UDim2.new(pct,0,1,0) }, TI(.22, Enum.EasingStyle.Quad))
            pctL.Text = math.floor(pct*100).."%"
            task.wait(0.12 + math.random()*0.1)
        end
        pctL.Text="100%"
        tw(pFill, { Size=UDim2.new(1,0,1,0) }, TI_FAST)
        task.wait(0.28)
        tw(pfGrad, { Offset=Vector2.new(1,0) }, TI(.4, Enum.EasingStyle.Sine))
        task.wait(0.1)

        tw(lTitle,  { TextTransparency=1 }, TI_FAST)
        tw(lSub,    { TextTransparency=1 }, TI_FAST)
        tw(pctL,    { TextTransparency=1 }, TI_FAST)
        tw(pTrack,  { BackgroundTransparency=1 }, TI_FAST)
        tw(pFill,   { BackgroundTransparency=1 }, TI_FAST)
        if cfg.Icon ~= "" then tw(lLogo, { ImageTransparency=1 }, TI_FAST) end
        task.wait(0.18)
        tw(lf, { BackgroundTransparency=1 }, TI_MED, function() lf:Destroy() end)
        task.wait(0.28)
    else
        tw(win, { Size=FULL }, TI_SLOW)
        task.wait(0.35)
    end

    -- Progresywne pojawianie elementów tytułu
    tw(topLine,   { BackgroundTransparency=0 }, TI_MED)
    task.wait(0.05)
    tw(tbLine,    { BackgroundTransparency=0 }, TI_MED)
    task.wait(0.05)
    tw(bgGrad,    { BackgroundTransparency=0 }, TI_MED)
    task.wait(0.05)
    tw(sideWire,  { BackgroundTransparency=0 }, TI_MED)
    task.wait(0.05)
    tw(nameLabel, { TextTransparency=0 },       TI_MED)
    task.wait(0.03)
    tw(subLabel,  { TextTransparency=0 },       TI_MED)
    task.wait(0.05)
    tw(statWrap,  { BackgroundTransparency=0 }, TI_MED)
    if statWrap:FindFirstChildOfClass("UIStroke") then
        tw(statWrap:FindFirstChildOfClass("UIStroke"), { Transparency=0 }, TI_MED)
    end
    tw(sep2, { BackgroundTransparency=0 }, TI_MED)

    -- ── Przyciski sterowania ──────────────────────────────────
    local function HideW()
        W._visible = false
        tw(win, { Size=UDim2.fromOffset(0,0) }, TI_SLOW, function() win.Visible=false end)
    end
    local function ShowW()
        win.Visible=true; W._visible=true
        tw(win, { Size = W._minimized and MINI or FULL }, TI_SLOW)
    end

    ctrlBtns["X"].click.MouseButton1Click:Connect(function() Sentence:Destroy() end)
    ctrlBtns["·"].click.MouseButton1Click:Connect(function()
        Sentence:Notify({ Title="Hidden", Content="Press "..cfg.ToggleBind.Name.." to restore.", Type="Info" })
        HideW()
    end)
    ctrlBtns["−"].click.MouseButton1Click:Connect(function()
        W._minimized = not W._minimized
        if W._minimized then
            sidebar.Visible=false; contentArea.Visible=false
            tw(win, { Size=MINI }, TI_MED)
        else
            tw(win, { Size=FULL }, TI_MED, function()
                sidebar.Visible=true; contentArea.Visible=true
            end)
        end
    end)

    track(UIS.InputBegan:Connect(function(inp, proc)
        if proc then return end
        if inp.KeyCode == cfg.ToggleBind then
            if W._visible then HideW() else ShowW() end
        end
    end))

    -- ══════════════════════════════════════════════════════════
    -- HOME TAB
    -- ══════════════════════════════════════════════════════════
    function W:CreateHomeTab(hCfg)
        hCfg = merge({ Icon="home" }, hCfg or {})
        local tabId = "Home"

        local hBox = Box({
            Name="HomeTabBtn", Sz=UDim2.new(0, S(42), 0, S(42)),
            Bg=Theme.AccentDim, BgA=1, R=S(6), Z=5, Par=tabIconsList,
        })
        local hLine = Box({ Sz=UDim2.new(0, 3, 0.55, 0), Pos=UDim2.new(0, 0, 0.225, 0), Bg=Theme.AccentColor, BgA=0, R=0, Z=6, Par=hBox })
        local hIco  = Img({ Ico=hCfg.Icon, Sz=UDim2.new(0, S(20), 0, S(20)), Col=Theme.TextMuted, Z=6, Par=hBox })
        local hCL   = Btn(hBox, 7)

        local hPage = Instance.new("ScrollingFrame")
        hPage.Name="HomePage"; hPage.Size=UDim2.new(1,0,1,0)
        hPage.BackgroundTransparency=1; hPage.BorderSizePixel=0
        hPage.ScrollBarThickness=2; hPage.ScrollBarImageColor3=Theme.ScrollBar
        hPage.CanvasSize=UDim2.new(0,0,0,0); hPage.AutomaticCanvasSize=Enum.AutomaticSize.Y
        hPage.ZIndex=3; hPage.Visible=false; hPage.Parent=contentArea
        List(hPage, S(12)); Pad(hPage, S(18), S(18), S(20), S(20))

        -- ── Karta profilu ─────────────────────────────────────
        local pCard = Box({
            Sz=UDim2.new(1,0,0, S(80)), Bg=Theme.SurfaceBackground, BgA=0,
            R=S(6), Border=true, BorderCol=Theme.BorderColor, Z=3, Par=hPage,
        })
        Box({ Sz=UDim2.new(0, 3, 1, 0), Bg=Theme.AccentColor, R=0, Z=4, Par=pCard })

        local pAv = Instance.new("ImageLabel")
        pAv.Size=UDim2.new(0, S(52), 0, S(52)); pAv.Position=UDim2.new(0, S(18), 0.5, 0)
        pAv.AnchorPoint=Vector2.new(0,0.5); pAv.BackgroundTransparency=1; pAv.ZIndex=4
        pAv.Parent=pCard
        Instance.new("UICorner",pAv).CornerRadius=UDim.new(0, S(5))
        local pAS=Instance.new("UIStroke"); pAS.Color=Theme.AccentColor; pAS.Thickness=1.5; pAS.Transparency=0.45; pAS.Parent=pAv
        pcall(function() pAv.Image=Plrs:GetUserThumbnailAsync(LP.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size150x150) end)

        Txt({ T=LP.DisplayName, Sz=UDim2.new(1, -S(96), 0, S(20)), Pos=UDim2.new(0, S(84), 0, S(17)), Font=Enum.Font.GothamBold, TS=S(17), Col=Theme.TextPrimary, Z=4, Par=pCard })
        Txt({ T="@"..LP.Name,  Sz=UDim2.new(1, -S(96), 0, S(14)), Pos=UDim2.new(0, S(84), 0, S(40)), Font=Enum.Font.Code,       TS=S(12), Col=Theme.TextSecondary, Z=4, Par=pCard })

        -- ── Karta statystyk serwera ───────────────────────────
        local sCard = Box({
            Sz=UDim2.new(1,0,0, S(104)), Bg=Theme.SurfaceBackground, BgA=0,
            R=S(6), Border=true, BorderCol=Theme.BorderColor, Z=3, Par=hPage,
        })
        Txt({ T="#", Sz=UDim2.new(0, S(12), 0, S(13)), Pos=UDim2.new(0, S(14), 0, S(9)), Font=Enum.Font.GothamBold, TS=S(9), Col=Theme.AccentColor, Z=4, Par=sCard })
        Txt({ T="SRV STATISTICS", Sz=UDim2.new(1, -S(40), 0, S(13)), Pos=UDim2.new(0, S(28), 0, S(9)), Font=Enum.Font.GothamBold, TS=S(9), Col=Theme.TextSecondary, Z=4, Par=sCard })
        Wire(sCard, false).Position = UDim2.new(0, 0, 0, S(26))

        local statVals = {}
        local sData    = { {"PLAYERS",""}, {"PING",""}, {"UPTIME",""}, {"REGION",""} }
        local cW2      = (WW - SIDE_W - S(56)) / 2
        for i, sd in ipairs(sData) do
            local col = (i-1) % 2
            local row = math.floor((i-1) / 2)
            local x   = S(16) + col * cW2
            local y   = S(34) + row * S(34)
            Txt({ T=sd[1], Sz=UDim2.new(0, S(160), 0, S(11)), Pos=UDim2.new(0,x,0,y), Font=Enum.Font.GothamBold, TS=S(9), Col=Theme.TextMuted, Z=4, Par=sCard })
            statVals[sd[1]] = Txt({ T="—", Sz=UDim2.new(0, S(200), 0, S(16)), Pos=UDim2.new(0,x,0,y+S(12)), Font=Enum.Font.Code, TS=S(14), Col=Theme.TextPrimary, Z=4, Par=sCard })
        end

        task.spawn(function()
            while task.wait(1) do
                if not win or not win.Parent then break end
                pcall(function()
                    statVals["PLAYERS"].Text = #Plrs:GetPlayers().."/"..Plrs.MaxPlayers
                    statVals["PING"].Text    = math.floor(LP:GetNetworkPing()*1000).."ms"
                    local t = math.floor(time())
                    statVals["UPTIME"].Text  = string.format("%02d:%02d:%02d", math.floor(t/3600), math.floor(t%3600/60), t%60)
                    pcall(function() statVals["REGION"].Text = game:GetService("LocalizationService"):GetCountryRegionForPlayerAsync(LP) end)
                end)
            end
        end)

        table.insert(W._tabs, { id=tabId, btn=hBox, page=hPage, activeLine=hLine, iconImg=hIco, bgBox=hBox })
        hCL.MouseButton1Click:Connect(function() SwitchTab(tabId) end)

        hBox.MouseEnter:Connect(function()
            if W._activeTab ~= tabId then tw(hBox, { BackgroundTransparency=0.88 }, TI_FAST) end
            tooltipL.Text=tabId; tooltip.Visible=true
            tw(tooltip, { Position=UDim2.new(0, SIDE_W+S(5), 0, hBox.AbsolutePosition.Y-win.AbsolutePosition.Y+S(9)) }, TI_FAST)
        end)
        hBox.MouseLeave:Connect(function()
            if W._activeTab ~= tabId then tw(hBox, { BackgroundTransparency=1 }, TI_FAST) end
            tooltip.Visible=false
        end)

        SwitchTab(tabId)
        return { Activate=function() SwitchTab(tabId) end }
    end

    -- ══════════════════════════════════════════════════════════
    -- CREATE TAB
    -- ══════════════════════════════════════════════════════════
    function W:CreateTab(tCfg)
        tCfg = merge({ Name="Tab", Icon="unk", ShowTitle=true }, tCfg or {})
        local Tab   = {}
        local tabId = tCfg.Name

        local tBox = Box({
            Name=tCfg.Name.."Btn", Sz=UDim2.new(0, S(42), 0, S(42)),
            Bg=Theme.TertiaryBackground, BgA=1, R=S(6), Z=5,
            Ord=#W._tabs+1, Par=tabIconsList,
        })
        local tLine = Box({ Sz=UDim2.new(0, 3, 0.55, 0), Pos=UDim2.new(0, 0, 0.225, 0), Bg=Theme.AccentColor, BgA=1, R=0, Z=6, Par=tBox })
        local tIco  = Img({ Ico=tCfg.Icon, Sz=UDim2.new(0, S(20), 0, S(20)), Col=Theme.TextMuted, Z=6, Par=tBox })
        local tCL   = Btn(tBox, 7)

        local tPage = Instance.new("ScrollingFrame")
        tPage.Name=tCfg.Name; tPage.Size=UDim2.new(1,0,1,0)
        tPage.BackgroundTransparency=1; tPage.BorderSizePixel=0
        tPage.ScrollBarThickness=2; tPage.ScrollBarImageColor3=Theme.ScrollBar
        tPage.CanvasSize=UDim2.new(0,0,0,0); tPage.AutomaticCanvasSize=Enum.AutomaticSize.Y
        tPage.ZIndex=3; tPage.Visible=false; tPage.Parent=contentArea
        List(tPage, S(8)); Pad(tPage, S(18), S(18), S(20), S(20))

        if tCfg.ShowTitle then
            local titleRow = Box({ Sz=UDim2.new(1,0,0, S(28)), BgA=1, Z=3, Par=tPage })
            Box({ Sz=UDim2.new(0, 3, 0.7, 0), Pos=UDim2.new(0, 0, 0.15, 0), Bg=Theme.AccentColor, R=0, Z=4, Par=titleRow })
            Img({ Ico=tCfg.Icon, Sz=UDim2.new(0, S(15), 0, S(15)), Pos=UDim2.new(0, S(12), 0.5, 0), AP=Vector2.new(0,0.5), Col=Theme.AccentColor, Z=4, Par=titleRow })
            Txt({ T=tCfg.Name:upper(), Sz=UDim2.new(1, -S(40), 0, S(18)), Pos=UDim2.new(0, S(34), 0.5, 0), AP=Vector2.new(0,0.5), Font=Enum.Font.GothamBold, TS=S(16), Col=Theme.TextPrimary, Z=4, Par=titleRow })
        end

        table.insert(W._tabs, { id=tabId, btn=tBox, page=tPage, activeLine=tLine, iconImg=tIco, bgBox=tBox })
        function Tab:Activate() SwitchTab(tabId) end

        tCL.MouseButton1Click:Connect(function() Tab:Activate() end)
        tBox.MouseEnter:Connect(function()
            if W._activeTab ~= tabId then tw(tBox, { BackgroundTransparency=0.88 }, TI_FAST) end
            tooltipL.Text=tCfg.Name; tooltip.Visible=true
            tw(tooltip, { Position=UDim2.new(0, SIDE_W+S(5), 0, tBox.AbsolutePosition.Y-win.AbsolutePosition.Y+S(9)) }, TI_FAST)
        end)
        tBox.MouseLeave:Connect(function()
            if W._activeTab ~= tabId then tw(tBox, { BackgroundTransparency=1 }, TI_FAST) end
            tooltip.Visible=false
        end)

        -- ── CreateSection ──────────────────────────────────────
        local _secN = 0
        function Tab:CreateSection(sName)
            sName = sName or ""
            _secN = _secN + 1
            local Sec = {}

            local shRow = Box({
                Name="SH", Sz=UDim2.new(1,0,0,sName~="" and S(22) or S(6)),
                BgA=1, Z=3, Par=tPage, Ord=#tPage:GetChildren(),
            })

            if sName ~= "" then
                local secLine = Box({ Sz=UDim2.new(1,0,0,1), Pos=UDim2.new(0,0,0.5,0), Bg=Theme.BorderColor, BgA=0, Z=3, Par=shRow })
                local slGrad = Instance.new("UIGradient")
                slGrad.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Theme.AccentColor),
                    ColorSequenceKeypoint.new(0.3, Theme.BorderColor),
                    ColorSequenceKeypoint.new(1, Theme.BorderColor),
                }
                slGrad.Parent = secLine
                tw(secLine, { BackgroundTransparency=0 }, TI_MED)

                local badge = Box({
                    Sz=UDim2.new(0,0,0, S(18)), Pos=UDim2.new(0,0,0.5,0), AP=Vector2.new(0,0.5),
                    Bg=Theme.PrimaryBackground, R=0, Z=4, Par=shRow,
                })
                badge.AutomaticSize = Enum.AutomaticSize.X
                Pad(badge, 0, 0, 0, S(8))

                local badgeRow = Instance.new("Frame")
                badgeRow.Size=UDim2.new(0,0,1,0); badgeRow.AutomaticSize=Enum.AutomaticSize.X
                badgeRow.BackgroundTransparency=1; badgeRow.ZIndex=5; badgeRow.Parent=badge
                List(badgeRow, 0, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)

                local numL = Instance.new("TextLabel")
                numL.Text="#"..string.format("%02d",_secN).." "; numL.Size=UDim2.new(0,0,1,0)
                numL.AutomaticSize=Enum.AutomaticSize.X; numL.Font=Enum.Font.GothamBold; numL.TextSize=S(9)
                numL.TextColor3=Theme.AccentColor; numL.BackgroundTransparency=1; numL.BorderSizePixel=0
                numL.ZIndex=5; numL.RichText=false; numL.Parent=badgeRow

                local nameL = Instance.new("TextLabel")
                nameL.Text=sName:upper(); nameL.Size=UDim2.new(0,0,1,0)
                nameL.AutomaticSize=Enum.AutomaticSize.X; nameL.Font=Enum.Font.GothamBold; nameL.TextSize=S(9)
                nameL.TextColor3=Theme.TextSecondary; nameL.BackgroundTransparency=1; nameL.BorderSizePixel=0
                nameL.ZIndex=5; nameL.RichText=false; nameL.Parent=badgeRow
            end

            local secCon = Box({ Name="SC", Sz=UDim2.new(1,0,0,0), BgA=1, Z=3, AutoY=true, Ord=shRow.LayoutOrder+1, Par=tPage })
            List(secCon, S(5))

            local function Elem(h, autoY)
                local f = Box({
                    Sz=UDim2.new(1,0,0,h or S(40)),
                    Bg=Theme.SurfaceBackground, BgA=0,
                    R=S(6), Border=true, BorderCol=Theme.BorderColor,
                    Z=3, Par=secCon,
                })
                if autoY then f.AutomaticSize = Enum.AutomaticSize.Y end
                return f
            end

            local function HoverEffect(f)
                f.MouseEnter:Connect(function()
                    if f:FindFirstChildOfClass("UIStroke") then
                        tw(f:FindFirstChildOfClass("UIStroke"), { Color=Theme.AccentDim }, TI_FAST)
                    end
                end)
                f.MouseLeave:Connect(function()
                    if f:FindFirstChildOfClass("UIStroke") then
                        tw(f:FindFirstChildOfClass("UIStroke"), { Color=Theme.BorderColor }, TI_FAST)
                    end
                end)
            end

            -- ── Divider ───────────────────────────────────────
            function Sec:CreateDivider()
                local d = Box({ Sz=UDim2.new(1,0,0,1), Bg=Theme.BorderColor, BgA=0, Z=3, Par=secCon })
                local dg = Instance.new("UIGradient")
                dg.Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(0.5, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, Color3.new(0,0,0)) }
                dg.Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(0.1,0), NumberSequenceKeypoint.new(0.9,0), NumberSequenceKeypoint.new(1,1) }
                dg.Parent = d
                tw(d, { BackgroundTransparency=0 }, TI_MED)
                return { Destroy=function() d:Destroy() end }
            end

            -- ── Label ─────────────────────────────────────────
            function Sec:CreateLabel(lc)
                lc = merge({ Text="", Name="", Style=1 }, lc or {})
                local text = lc.Text ~= "" and lc.Text or (lc.Name or "")
                local cMap = { [1]=Theme.TextSecondary, [2]=NotifColors.Info, [3]=NotifColors.Warning }
                local f  = Elem(S(30))
                local xo = lc.Style > 1 and S(16) or S(12)
                if lc.Style > 1 then
                    Box({ Sz=UDim2.new(0, 3, 0.65, 0), Pos=UDim2.new(0, 0, 0.175, 0), Bg=cMap[lc.Style], R=0, Z=4, Par=f })
                end
                local lb = Txt({ T=text, Sz=UDim2.new(1, -xo-S(8), 0, S(14)), Pos=UDim2.new(0, xo, 0.5, 0), AP=Vector2.new(0,0.5), Font=Enum.Font.GothamSemibold, TS=S(12), Col=cMap[lc.Style], Z=4, Par=f })
                return {
                    Set     = function(self, t) lb.Text = t end,
                    Destroy = function() f:Destroy() end,
                }
            end

            -- ── Paragraph ─────────────────────────────────────
            function Sec:CreateParagraph(pc)
                pc = merge({ Title="Title", Content="" }, pc or {})
                local f = Elem(0, true)
                Pad(f, S(12), S(12), S(14), S(14)); List(f, S(5))
                local pt    = Txt({ T=pc.Title,   Sz=UDim2.new(1,0,0, S(16)), Font=Enum.Font.GothamBold, TS=S(14), Col=Theme.TextPrimary,   Z=4, Par=f })
                local pcont = Txt({ T=pc.Content, Sz=UDim2.new(1,0,0,0),  Font=Enum.Font.Gotham,     TS=S(12), Col=Theme.TextSecondary, Z=4, Wrap=true, AutoY=true, Par=f })
                return {
                    Set = function(self, s)
                        if s.Title   then pt.Text    = s.Title   end
                        if s.Content then pcont.Text = s.Content end
                    end,
                    Destroy = function() f:Destroy() end,
                }
            end

            -- ── Button ────────────────────────────────────────
            function Sec:CreateButton(bc)
                bc = merge({ Name="Button", Description=nil, Callback=function() end }, bc or {})
                local h = bc.Description and S(58) or S(40)
                local f = Elem(h)
                f.ClipsDescendants = true

                local chargeFill = Box({ Sz=UDim2.new(0,0,1,0), Bg=Theme.ButtonHover, BgA=0, R=0, Z=3, Par=f })
                local pip        = Box({ Sz=UDim2.new(0, 3, 1, 0), Bg=Theme.AccentColor, BgA=1, R=0, Z=4, Par=f })
                Txt({ T=bc.Name, Sz=UDim2.new(1, -S(48), 0, S(16)), Pos=UDim2.new(0, S(16), 0, bc.Description and S(11) or S(12)), Font=Enum.Font.GothamSemibold, TS=S(13), Col=Theme.TextPrimary, Z=4, Par=f })
                if bc.Description then
                    Txt({ T=bc.Description, Sz=UDim2.new(1, -S(48), 0, S(13)), Pos=UDim2.new(0, S(16), 0, S(30)), Font=Enum.Font.Gotham, TS=S(11), Col=Theme.TextSecondary, Z=4, Par=f })
                end
                Img({ Ico="arr", Sz=UDim2.new(0, S(12), 0, S(12)), Pos=UDim2.new(1, -S(18), 0.5, 0), AP=Vector2.new(0,0.5), Col=Theme.AccentColor, IA=0.5, Z=5, Par=f })

                local cl = Btn(f, 6)
                f.MouseEnter:Connect(function()
                    tw(chargeFill, { Size=UDim2.new(1,0,1,0), BackgroundTransparency=0 }, TI(.28, Enum.EasingStyle.Quad))
                    if f:FindFirstChildOfClass("UIStroke") then tw(f:FindFirstChildOfClass("UIStroke"), { Color=Theme.AccentDim }, TI_FAST) end
                end)
                f.MouseLeave:Connect(function()
                    tw(chargeFill, { Size=UDim2.new(0,0,1,0), BackgroundTransparency=1 }, TI_MED)
                    if f:FindFirstChildOfClass("UIStroke") then tw(f:FindFirstChildOfClass("UIStroke"), { Color=Theme.BorderColor }, TI_FAST) end
                end)
                cl.MouseButton1Click:Connect(function()
                    tw(chargeFill, { BackgroundColor3=Theme.AccentDim }, TI_FAST)
                    task.wait(0.1)
                    tw(chargeFill, { BackgroundColor3=Theme.ButtonHover, Size=UDim2.new(0,0,1,0), BackgroundTransparency=1 }, TI_MED)
                    safe(bc.Callback)
                end)
                return { Destroy=function() f:Destroy() end }
            end

            -- ── Toggle ────────────────────────────────────────
            function Sec:CreateToggle(tc)
                tc = merge({ Name="Toggle", Description=nil, CurrentValue=false, Flag=nil, Callback=function() end }, tc or {})
                local h = tc.Description and S(58) or S(40)
                local f = Elem(h)

                Txt({ T=tc.Name, Sz=UDim2.new(1, -S(72), 0, S(16)), Pos=UDim2.new(0, S(16), 0, tc.Description and S(11) or S(12)), Font=Enum.Font.GothamSemibold, TS=S(13), Col=Theme.TextPrimary, Z=4, Par=f })
                if tc.Description then
                    Txt({ T=tc.Description, Sz=UDim2.new(1, -S(72), 0, S(13)), Pos=UDim2.new(0, S(16), 0, S(30)), Font=Enum.Font.Gotham, TS=S(11), Col=Theme.TextSecondary, Z=4, Par=f })
                end

                local trk  = Box({ Sz=UDim2.new(0, S(44), 0, S(22)), Pos=UDim2.new(1, -S(56), 0.5, 0), AP=Vector2.new(0,0.5), Bg=Theme.TertiaryBackground, R=S(4), Border=true, BorderCol=Theme.BorderColor, Z=4, Par=f })
                local knob = Box({ Sz=UDim2.new(0, S(16), 0, S(16)), Pos=UDim2.new(0, S(3), 0.5, 0), AP=Vector2.new(0,0.5), Bg=Theme.TextSecondary, R=S(3), Z=5, Par=trk })

                local TV = { CurrentValue=tc.CurrentValue, Type="Toggle", Settings=tc }

                local function upd()
                    if TV.CurrentValue then
                        tw(trk,  { BackgroundColor3=Theme.AccentDim }, TI_MED)
                        if trk:FindFirstChildOfClass("UIStroke") then tw(trk:FindFirstChildOfClass("UIStroke"), { Color=Theme.AccentColor }, TI_MED) end
                        tw(knob, { Position=UDim2.new(0, S(25), 0.5, 0), BackgroundColor3=Theme.AccentColor }, TI_SPRING)
                    else
                        tw(trk,  { BackgroundColor3=Theme.TertiaryBackground }, TI_MED)
                        if trk:FindFirstChildOfClass("UIStroke") then tw(trk:FindFirstChildOfClass("UIStroke"), { Color=Theme.BorderColor }, TI_MED) end
                        tw(knob, { Position=UDim2.new(0, S(3), 0.5, 0), BackgroundColor3=Theme.TextSecondary }, TI_SPRING)
                    end
                end

                upd()
                HoverEffect(f)
                Btn(f, 5).MouseButton1Click:Connect(function()
                    TV.CurrentValue = not TV.CurrentValue
                    upd()
                    safe(tc.Callback, TV.CurrentValue)
                end)
                function TV:Set(v) TV.CurrentValue=v; upd(); safe(tc.Callback, v) end
                if tc.Flag then Sentence.Flags[tc.Flag]=TV; Sentence.Options[tc.Flag]=TV end
                return TV
            end

            -- ── Slider ────────────────────────────────────────
            function Sec:CreateSlider(sc)
                sc = merge({ Name="Slider", Range={0,100}, Increment=1, CurrentValue=50, Suffix="", Flag=nil, Callback=function() end }, sc or {})
                local f = Elem(S(58))

                Txt({ T=sc.Name, Sz=UDim2.new(1, -S(110), 0, S(16)), Pos=UDim2.new(0, S(16), 0, S(10)), Font=Enum.Font.GothamSemibold, TS=S(13), Col=Theme.TextPrimary, Z=4, Par=f })

                local valChip = Box({ Sz=UDim2.new(0,0,0, S(20)), Pos=UDim2.new(1, -S(14), 0, S(8)), AP=Vector2.new(1,0), Bg=Theme.ElevatedSurface, R=S(5), Z=4, Par=f })
                valChip.AutomaticSize = Enum.AutomaticSize.X
                Pad(valChip, 0, 0, S(8), S(8))
                local valL = Txt({ T=tostring(sc.CurrentValue)..sc.Suffix, Sz=UDim2.new(0,0,1,0), Font=Enum.Font.Code, TS=S(12), Col=Theme.TextAccent, AX=Enum.TextXAlignment.Center, Z=5, Par=valChip })
                valL.AutomaticSize = Enum.AutomaticSize.X

                local trackBg = Box({ Sz=UDim2.new(1, -S(30), 0, S(4)), Pos=UDim2.new(0, S(16), 0, S(40)), Bg=Theme.TertiaryBackground, R=S(2), Z=4, Par=f })
                local fillF   = Box({ Sz=UDim2.new(0,0,1,0), Bg=Theme.AccentColor, R=S(2), Z=5, Par=trackBg })
                local fillGrad = Instance.new("UIGradient")
                fillGrad.Color = ColorSequence.new{ ColorSequenceKeypoint.new(0,Theme.AccentColor), ColorSequenceKeypoint.new(1,HC("#7dc8ff")) }
                fillGrad.Parent = fillF
                local thumb   = Box({ Sz=UDim2.new(0, S(12), 0, S(12)), Pos=UDim2.new(0,0,0.5,0), AP=Vector2.new(0.5,0.5), Bg=Theme.TextPrimary, R=S(3), Z=6, Par=trackBg })

                local SV = { CurrentValue=sc.CurrentValue, Type="Slider", Settings=sc }
                local mn, mx, inc = sc.Range[1], sc.Range[2], sc.Increment

                local function setV(v)
                    v = math.clamp(v, mn, mx)
                    v = math.floor(v/inc+0.5)*inc
                    v = tonumber(string.format("%.10g", v))
                    SV.CurrentValue = v
                    valL.Text = tostring(v)..sc.Suffix
                    local pct = (v-mn)/(mx-mn)
                    tw(fillF,  { Size=UDim2.new(pct,0,1,0) },       TI_FAST)
                    tw(thumb,  { Position=UDim2.new(pct,0,0.5,0) }, TI_FAST)
                end
                setV(sc.CurrentValue)

                local drag = false
                local bCL  = Btn(trackBg, 8)
                local function fromInp(i)
                    local rel = math.clamp((i.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1)
                    setV(mn + (mx-mn)*rel)
                    safe(sc.Callback, SV.CurrentValue)
                end
                bCL.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1
                    or i.UserInputType==Enum.UserInputType.Touch then
                        drag=true; fromInp(i)
                    end
                end)
                UIS.InputEnded:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1
                    or i.UserInputType==Enum.UserInputType.Touch then
                        drag=false
                    end
                end)
                track(UIS.InputChanged:Connect(function(i)
                    if drag and (i.UserInputType==Enum.UserInputType.MouseMovement
                    or i.UserInputType==Enum.UserInputType.Touch) then
                        fromInp(i)
                    end
                end))

                HoverEffect(f)
                function SV:Set(v) setV(v); safe(sc.Callback, SV.CurrentValue) end
                if sc.Flag then Sentence.Flags[sc.Flag]=SV; Sentence.Options[sc.Flag]=SV end
                return SV
            end

            return Sec
        end

        -- Skróty bezpośrednio na Tab
        local _ds
        local function gds()
            if not _ds then _ds = Tab:CreateSection("") end
            return _ds
        end
        for _, m in ipairs({"CreateButton","CreateLabel","CreateParagraph","CreateToggle","CreateSlider","CreateDivider"}) do
            Tab[m] = function(self, ...) return gds()[m](gds(), ...) end
        end

        return Tab
    end

    -- ── Zapis / Wczyt ─────────────────────────────────────────
    function W:SaveConfiguration()  end
    function W:LoadConfiguration()  end

    return W
end

-- ── Destroy ───────────────────────────────────────────────────
function Sentence:Destroy()
    for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
    self._conns={}
    if self._notifHolder and self._notifHolder.Parent then
        self._notifHolder.Parent:Destroy()
    end
    self.Flags={}; self.Options={}
end

return Sentence

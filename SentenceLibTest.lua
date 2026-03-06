--[[
╔═══════════════════════════════════════════════════════════╗
║  SENTENCE GUI · OG Sentence Edition                       ║
║  Wersja: 2.1                                              ║
╚═══════════════════════════════════════════════════════════╝
--]]

local Sentence = {
    Version = "2.1",
    Flags   = {},
    Options = {},
    _conns  = {},
}

-- ── Serwisy ──────────────────────────────────────────────────────────────────
local TS    = game:GetService("TweenService")
local UIS   = game:GetService("UserInputService")
local RS    = game:GetService("RunService")
local HS    = game:GetService("HttpService")
local Plrs  = game:GetService("Players")
local CG    = game:GetService("CoreGui")
local LP    = Plrs.LocalPlayer
local Cam   = workspace.CurrentCamera
local IsStudio = RS:IsStudio()

-- ── Motyw "OG Sentence" ───────────────────────────────────────────────────────
local function HexToColor3(hex)
    hex = hex:gsub("#", "")
    return Color3.fromRGB(
        tonumber("0x"..hex:sub(1,2)),
        tonumber("0x"..hex:sub(3,4)),
        tonumber("0x"..hex:sub(5,6))
    )
end

local Theme = {
    PrimaryBackground               = HexToColor3("#121212"),
    SecondaryBackground             = HexToColor3("#161616"),
    TertiaryBackground              = HexToColor3("#1a1a1a"),
    BorderColor                     = HexToColor3("#252525"),
    AccentColor                     = HexToColor3("#5A9FE8"),
    TextPrimary                     = HexToColor3("#E8E8E8"),
    TextSecondary                   = HexToColor3("#909090"),
    ConsoleBackground               = HexToColor3("#181818"),
    ConsoleBorder                   = HexToColor3("#252525"),
    ConsoleHeader                   = HexToColor3("#181818"),
    ConsoleHeaderBorder             = HexToColor3("#2d2d2d"),
    ConsoleContent                  = HexToColor3("#151515"),
    MenuBackground                  = HexToColor3("#181818"),
    MenuBorder                      = HexToColor3("#2d2d2d"),
    EditorBackground                = HexToColor3("#111111"),
    EditorForeground                = HexToColor3("#d4d4d4"),
    EditorLineHighlight             = HexToColor3("#1e1e1e"),
    EditorSelection                 = HexToColor3("#2d5a8a"),
    EditorCursor                    = HexToColor3("#5A9FE8"),
    EditorLineNumber                = HexToColor3("#757575"),
    EditorActiveLineNumber          = HexToColor3("#c6c6c6"),
    EditorPanelBackground           = HexToColor3("#121212"),
    EditorPanelBorder               = HexToColor3("#252525"),
    EditorStatusBar                 = HexToColor3("#161616"),
    EditorNavbar                    = HexToColor3("#121212"),
    WindowShadowColor               = HexToColor3("#e3e4e6"),
    ButtonNormalBackground          = HexToColor3("#1f1f1f"),
    ButtonNormalForeground          = HexToColor3("#C8C8C8"),
    ButtonNormalBorder              = HexToColor3("#2d2d2d"),
    ButtonHoverBackground           = HexToColor3("#252525"),
    ButtonPressedBackground         = HexToColor3("#161616"),
    ButtonPressedForeground         = HexToColor3("#5A9FE8"),
    ButtonDisabledBackground        = HexToColor3("#141414"),
    ButtonDisabledForeground        = HexToColor3("#505050"),
    ScriptsPanelBackground          = HexToColor3("#121212"),
    ScriptsPanelBorder              = HexToColor3("#252525"),
    ScriptsPanelHeader              = HexToColor3("#181818"),
    ScriptsPanelHeaderBorder        = HexToColor3("#2d2d2d"),
    ScriptsPanelHeaderText          = HexToColor3("#A8A8A8"),
    AutoExecPanelBackground         = HexToColor3("#121212"),
    AutoExecPanelBorder             = HexToColor3("#252525"),
    AutoExecPanelHeader             = HexToColor3("#181818"),
    AutoExecPanelHeaderBorder       = HexToColor3("#2d2d2d"),
    AutoExecPanelHeaderText         = HexToColor3("#A8A8A8"),
    AutoExecPlaceholderText         = HexToColor3("#B0B0B0"),
    GridSplitterColor               = HexToColor3("#252525"),
    NotificationPanelBackground     = HexToColor3("#202020"),
    NotificationPanelBorder         = HexToColor3("#252525"),
    NotificationPanelAccent         = HexToColor3("#5A9FE8"),
    NotificationPanelAccentGradientStart = HexToColor3("#5A9FE8"),
    NotificationPanelAccentGradientEnd   = HexToColor3("#4580C9"),
    NotificationPanelIconBackground = HexToColor3("#161616"),
    NotificationPanelIconBorder     = HexToColor3("#2d2d2d"),
    NotificationPanelText           = HexToColor3("#E8E8E8"),
}

local NotifColors = {
    Info    = Theme.AccentColor,
    Success = HexToColor3("#00D68F"),
    Warning = HexToColor3("#FFB800"),
    Error   = HexToColor3("#FF3C3C"),
}

local function TI(t, s, d)
    return TweenInfo.new(t or .2, s or Enum.EasingStyle.Exponential, d or Enum.EasingDirection.Out)
end
local TI_FAST   = TI(.16)
local TI_MED    = TI(.26)
local TI_SLOW   = TI(.52)
local TI_SPRING = TweenInfo.new(.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function tw(o, p, info, cb)
    local t = TS:Create(o, info or TI_MED, p)
    if cb then t.Completed:Once(cb) end
    t:Play(); return t
end

local function merge(d, t)
    t = t or {}
    for k, v in pairs(d) do if t[k] == nil then t[k] = v end end
    return t
end
local function track(c) table.insert(Sentence._conns, c); return c end
local function safe(cb, ...) local ok, e = pcall(cb, ...); if not ok then warn("SENTENCE: "..tostring(e)) end end

-- ── Asset loga ────────────────────────────────────────────────────────────────
local LOGO_ASSET = "rbxassetid://117810891565979"

-- ── Ikony ─────────────────────────────────────────────────────────────────────
local ICONS = {
    close  = "rbxassetid://6031094678",
    min    = "rbxassetid://6031094687",
    hide   = "rbxassetid://6031075929",
    home   = "rbxassetid://6031079158",   -- zmieniona ikona Home
    info   = "rbxassetid://6026568227",
    warn   = "rbxassetid://6031071053",
    ok     = "rbxassetid://6031094667",
    chev_d = "rbxassetid://6031094687",
    chev_u = "rbxassetid://6031094679",
    arr    = "rbxassetid://6031090995",
    search = "rbxassetid://6031154871",
    notif  = "rbxassetid://6034308946",
    unk    = "rbxassetid://6031079152",
}

local function ico(n)
    if not n or n == "" then return "" end
    if n:find("rbxassetid") then return n end
    if tonumber(n) then return "rbxassetid://"..n end
    return ICONS[n] or ICONS.unk
end

-- ── Komponenty UI ─────────────────────────────────────────────────────────────
local function Box(p)
    p = p or {}
    local f = Instance.new("Frame")
    f.Name                   = p.Name or "Box"
    f.Size                   = p.Sz   or UDim2.new(1,0,0,36)
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
        uc.CornerRadius = type(p.R)=="number" and UDim.new(0,p.R) or (p.R or UDim.new(0,4))
        uc.Parent = f
    end
    if p.Border then
        local s = Instance.new("UIStroke")
        s.Color           = p.BorderCol or Theme.BorderColor
        s.Transparency    = p.BorderA   or 0
        s.Thickness       = 1
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
    l.Size                   = p.Sz    or UDim2.new(1,0,0,16)
    l.Position               = p.Pos   or UDim2.new()
    l.AnchorPoint            = p.AP    or Vector2.zero
    l.Font                   = p.Font  or Enum.Font.GothamSemibold
    l.TextSize               = p.TS    or 15
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
    i.Size                   = p.Sz   or UDim2.new(0,18,0,18)
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
    l.Padding       = UDim.new(0, gap or 4)
    l.FillDirection = dir or Enum.FillDirection.Vertical
    if ha then l.HorizontalAlignment = ha end
    if va then l.VerticalAlignment   = va end
    l.Parent = par
    return l
end

local function Pad(par, top, bot, lft, rgt)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top or 0)
    p.PaddingBottom = UDim.new(0, bot or 0)
    p.PaddingLeft   = UDim.new(0, lft or 0)
    p.PaddingRight  = UDim.new(0, rgt or 0)
    p.Parent = par
    return p
end

local function Wire(par, vertical)
    local f = Instance.new("Frame")
    f.BackgroundColor3       = Theme.BorderColor
    f.BackgroundTransparency = 0
    f.BorderSizePixel        = 0
    f.ZIndex                 = 2
    f.Size = vertical and UDim2.new(0,1,1,0) or UDim2.new(1,0,0,1)
    f.Parent = par
    return f
end

local function Draggable(handle, win)
    local dragging = false
    local dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = win.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement
        or  input.UserInputType == Enum.UserInputType.Touch) and dragging then
            local d = input.Position - dragStart
            TS:Create(win, TweenInfo.new(0.08,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{
                Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
            }):Play()
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- NOTYFIKACJE
-- ══════════════════════════════════════════════════════════════════════════════
function Sentence:Notify(data)
    task.spawn(function()
        data = merge({Title="Notice",Content="",Icon="info",Type="Info",Duration=4}, data)
        local ac = NotifColors[data.Type] or Theme.AccentColor
        local card = Box({
            Name="NCard", Sz=UDim2.new(0,290,0,0), Pos=UDim2.new(0,0,1,0),
            AP=Vector2.new(0,1), Bg=Theme.NotificationPanelBackground, BgA=1,
            Clip=true, R=4, Border=true, BorderCol=Theme.NotificationPanelBorder,
            BorderA=1, Par=self._notifHolder,
        })
        local cc = Box({Name="Content",Sz=UDim2.new(1,0,0,0),BgA=1,AutoY=true,Par=card})
        Pad(cc, 12, 12, 34, 12)
        local strip   = Box({Sz=UDim2.new(0,3,1,0),Pos=UDim2.new(0,0,0,0),Bg=ac,BgA=1,R=0,Z=4,Par=card})
        local iconImg = Img({Ico=data.Icon,Sz=UDim2.new(0,14,0,14),Pos=UDim2.new(0,12,0,12),AP=Vector2.zero,Col=ac,IA=1,Z=4,Par=card})
        local ttl = Txt({T=data.Title,   Sz=UDim2.new(1,0,0,18),Font=Enum.Font.GothamBold,TS=15,Col=Theme.NotificationPanelText,Alpha=1,Z=4,Par=cc})
        local msg = Txt({T=data.Content, Sz=UDim2.new(1,0,0,0), Pos=UDim2.new(0,0,0,22),Font=Enum.Font.Gotham,TS=14,Col=Theme.TextSecondary,Alpha=1,Wrap=true,Z=4,AutoY=true,Par=cc})
        task.wait()
        local h = cc.AbsoluteSize.Y
        tw(card,{Size=UDim2.new(0,290,0,h)},TI_MED)
        tw(card,{BackgroundTransparency=0},TI_FAST)
        tw(card.UIStroke,{Transparency=0},TI_FAST)
        tw(strip,{BackgroundTransparency=0},TI_FAST)
        tw(iconImg,{ImageTransparency=0},TI_FAST)
        tw(ttl,{TextTransparency=0},TI_FAST)
        tw(msg,{TextTransparency=0},TI_FAST)
        task.wait(data.Duration)
        tw(msg,{TextTransparency=1},TI_FAST)
        tw(ttl,{TextTransparency=1},TI_FAST)
        tw(iconImg,{ImageTransparency=1},TI_FAST)
        tw(strip,{BackgroundTransparency=1},TI_FAST)
        tw(card,{BackgroundTransparency=1},TI_FAST)
        tw(card.UIStroke,{Transparency=1},TI_FAST)
        task.wait(0.15)
        tw(card,{Size=UDim2.new(0,290,0,0)},TI_MED,function() card:Destroy() end)
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- CREATE WINDOW
-- ══════════════════════════════════════════════════════════════════════════════
function Sentence:CreateWindow(cfg)
    cfg = merge({
        Name="SENTENCE", Subtitle="", Icon="",
        ToggleBind=Enum.KeyCode.RightControl,
        LoadingEnabled=true, LoadingTitle="SENTENCE", LoadingSubtitle="INITIALISING",
        ConfigurationSaving={Enabled=false,FolderName="Sentence",FileName="config"},
    }, cfg)

    local vp = Cam.ViewportSize
    local WW = math.clamp(vp.X-100, 616, 825)
    local WH = math.clamp(vp.Y-80,  440, 550)
    local FULL = UDim2.fromOffset(WW, WH)
    local MINI = UDim2.fromOffset(WW, 40)

    local gui = Instance.new("ScreenGui")
    gui.Name="OGSentenceUI"; gui.DisplayOrder=999999999
    gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true

    if gethui then gui.Parent=gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(gui); gui.Parent=CG
    elseif not IsStudio then gui.Parent=CG
    else gui.Parent=LP:WaitForChild("PlayerGui") end

    -- ══════════════════════════════════════════════════════════════════════════
    -- SPLASH SCREEN · SENTENCE HUB — interaktywny
    -- ══════════════════════════════════════════════════════════════════════════
    task.spawn(function()
        local splashConns = {}
        local splashAlive = true

        -- Tło
        local splash = Instance.new("Frame")
        splash.Name="SplashScreen"; splash.Size=UDim2.new(1,0,1,0)
        splash.BackgroundColor3=HexToColor3("#080c10")
        splash.BackgroundTransparency=1; splash.BorderSizePixel=0
        splash.ZIndex=1000; splash.ClipsDescendants=true
        splash.Parent=gui

        -- ── Narożniki dekoracyjne ─────────────────────────────────────────────
        local allCornerLines = {}
        local function MakeCorner(ax, ay, rx, ry)
            local root = Instance.new("Frame")
            root.Size=UDim2.new(0,36,0,36)
            root.Position=UDim2.new(ax,rx,ay,ry)
            root.AnchorPoint=Vector2.new(ax,ay)
            root.BackgroundTransparency=1; root.ZIndex=1002; root.Parent=splash
            local h = Instance.new("Frame")
            h.Size=UDim2.new(1,0,0,1)
            h.Position = ay==0 and UDim2.new(0,0,0,0) or UDim2.new(0,0,1,-1)
            h.BackgroundColor3=Theme.AccentColor; h.BackgroundTransparency=1
            h.BorderSizePixel=0; h.ZIndex=1003; h.Parent=root
            local v = Instance.new("Frame")
            v.Size=UDim2.new(0,1,1,0)
            v.Position = ax==0 and UDim2.new(0,0,0,0) or UDim2.new(1,-1,0,0)
            v.BackgroundColor3=Theme.AccentColor; v.BackgroundTransparency=1
            v.BorderSizePixel=0; v.ZIndex=1003; v.Parent=root
            table.insert(allCornerLines, h)
            table.insert(allCornerLines, v)
        end
        MakeCorner(0,0, 24, 24); MakeCorner(1,0,-24, 24)
        MakeCorner(0,1, 24,-24); MakeCorner(1,1,-24,-24)

        -- ── Główna poświata (parallax) ────────────────────────────────────────
        local glow = Instance.new("Frame")
        glow.Name="Glow"; glow.Size=UDim2.new(0,540,0,270)
        glow.Position=UDim2.new(0.5,0,0.5,0); glow.AnchorPoint=Vector2.new(0.5,0.5)
        glow.BackgroundColor3=Theme.AccentColor; glow.BackgroundTransparency=1
        glow.BorderSizePixel=0; glow.ZIndex=1001; glow.Parent=splash
        Instance.new("UICorner",glow).CornerRadius=UDim.new(1,0)
        local gg=Instance.new("UIGradient")
        gg.Transparency=NumberSequence.new{
            NumberSequenceKeypoint.new(0,0.74), NumberSequenceKeypoint.new(1,1)}
        gg.Parent=glow

        -- ── Linia skanowania ─────────────────────────────────────────────────
        local scanLine = Instance.new("Frame")
        scanLine.Size=UDim2.new(0,2,1,0); scanLine.Position=UDim2.new(-0.02,0,0,0)
        scanLine.BackgroundColor3=Theme.AccentColor; scanLine.BackgroundTransparency=0.5
        scanLine.BorderSizePixel=0; scanLine.ZIndex=1020; scanLine.Parent=splash
        local sg=Instance.new("UIGradient")
        sg.Transparency=NumberSequence.new{
            NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.38,0.35),
            NumberSequenceKeypoint.new(0.62,0.35),NumberSequenceKeypoint.new(1,1)}
        sg.Rotation=90; sg.Parent=scanLine

        -- ── Wrapper loga ─────────────────────────────────────────────────────
        local logoWrap = Instance.new("Frame")
        logoWrap.Name="LogoWrap"; logoWrap.Size=UDim2.new(0,48,0,48)
        logoWrap.Position=UDim2.new(0.5,0,0.44,0); logoWrap.AnchorPoint=Vector2.new(0.5,0.5)
        logoWrap.BackgroundTransparency=1; logoWrap.ZIndex=1004; logoWrap.Parent=splash

        -- Poświata loga
        local logoGlow = Instance.new("Frame")
        logoGlow.Size=UDim2.new(2.0,0,2.0,0)
        logoGlow.Position=UDim2.new(0.5,0,0.5,0); logoGlow.AnchorPoint=Vector2.new(0.5,0.5)
        logoGlow.BackgroundColor3=Theme.AccentColor; logoGlow.BackgroundTransparency=1
        logoGlow.BorderSizePixel=0; logoGlow.ZIndex=1003; logoGlow.Parent=logoWrap
        Instance.new("UICorner",logoGlow).CornerRadius=UDim.new(1,0)
        local lgg=Instance.new("UIGradient")
        lgg.Transparency=NumberSequence.new{
            NumberSequenceKeypoint.new(0,0.78),NumberSequenceKeypoint.new(1,1)}
        lgg.Parent=logoGlow

        -- Zewnętrzny pierścień (obraca się w prawo)
        local ringOuter = Instance.new("Frame")
        ringOuter.Size=UDim2.new(1,28,1,28)
        ringOuter.Position=UDim2.new(0.5,0,0.5,0); ringOuter.AnchorPoint=Vector2.new(0.5,0.5)
        ringOuter.BackgroundTransparency=1; ringOuter.BorderSizePixel=0
        ringOuter.ZIndex=1005; ringOuter.Parent=logoWrap
        Instance.new("UICorner",ringOuter).CornerRadius=UDim.new(1,0)
        local souter=Instance.new("UIStroke")
        souter.Color=Theme.AccentColor; souter.Thickness=1.5; souter.Transparency=0.15
        souter.Parent=ringOuter
        local gouter=Instance.new("UIGradient")
        gouter.Transparency=NumberSequence.new{
            NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.3,0),
            NumberSequenceKeypoint.new(0.65,0.88),NumberSequenceKeypoint.new(1,0)}
        gouter.Parent=souter

        -- Wewnętrzny pierścień (obraca się w lewo)
        local ringInner = Instance.new("Frame")
        ringInner.Size=UDim2.new(1,-16,1,-16)
        ringInner.Position=UDim2.new(0.5,0,0.5,0); ringInner.AnchorPoint=Vector2.new(0.5,0.5)
        ringInner.BackgroundTransparency=1; ringInner.BorderSizePixel=0
        ringInner.ZIndex=1005; ringInner.Parent=logoWrap
        Instance.new("UICorner",ringInner).CornerRadius=UDim.new(1,0)
        local sinner=Instance.new("UIStroke")
        sinner.Color=HexToColor3("#4580C9"); sinner.Thickness=1; sinner.Transparency=0.45
        sinner.Parent=ringInner
        local ginner=Instance.new("UIGradient")
        ginner.Transparency=NumberSequence.new{
            NumberSequenceKeypoint.new(0,0.85),NumberSequenceKeypoint.new(0.28,0),
            NumberSequenceKeypoint.new(0.72,0),NumberSequenceKeypoint.new(1,0.85)}
        ginner.Parent=sinner

        -- Obrazek loga (zeskalowany 160×160)
        local logoImg = Instance.new("ImageLabel")
        logoImg.Name="Logo"; logoImg.Size=UDim2.new(1,0,1,0)
        logoImg.BackgroundTransparency=1; logoImg.Image=LOGO_ASSET
        logoImg.ImageTransparency=1; logoImg.ScaleType=Enum.ScaleType.Fit
        logoImg.ZIndex=1006; logoImg.Parent=logoWrap
        Instance.new("UICorner",logoImg).CornerRadius=UDim.new(0,10)

        -- ── Napisy ───────────────────────────────────────────────────────────
        local textWrap = Instance.new("Frame")
        textWrap.Name="TextWrap"; textWrap.Size=UDim2.new(0,420,0,0)
        textWrap.Position=UDim2.new(0.5,0,0.44,110); textWrap.AnchorPoint=Vector2.new(0.5,0)
        textWrap.BackgroundTransparency=1; textWrap.AutomaticSize=Enum.AutomaticSize.Y
        textWrap.ZIndex=1004; textWrap.Parent=splash

        -- Rząd z literami SENTENCE + HUB
        local titleRow = Instance.new("Frame")
        titleRow.Size=UDim2.new(1,0,0,0); titleRow.BackgroundTransparency=1
        titleRow.AutomaticSize=Enum.AutomaticSize.XY; titleRow.ZIndex=1005; titleRow.Parent=textWrap
        local trl=Instance.new("UIListLayout")
        trl.FillDirection=Enum.FillDirection.Horizontal
        trl.HorizontalAlignment=Enum.HorizontalAlignment.Center
        trl.VerticalAlignment=Enum.VerticalAlignment.Center
        trl.Padding=UDim.new(0,0); trl.SortOrder=Enum.SortOrder.LayoutOrder; trl.Parent=titleRow

        -- Litery "SENTENCE" — staggered appear
        local CHARS = {"S","E","N","T","E","N","C","E"}
        local charLabels = {}
        for i, ch in ipairs(CHARS) do
            local lbl = Instance.new("TextLabel")
            lbl.Text=ch; lbl.Size=UDim2.new(0,0,0,0); lbl.AutomaticSize=Enum.AutomaticSize.XY
            lbl.Font=Enum.Font.GothamBold; lbl.TextSize=48
            lbl.TextColor3=Theme.TextPrimary; lbl.TextTransparency=1
            lbl.BackgroundTransparency=1; lbl.BorderSizePixel=0
            lbl.ZIndex=1006; lbl.LayoutOrder=i; lbl.RichText=false; lbl.Parent=titleRow
            charLabels[i]=lbl
        end

        local spacerMid = Instance.new("Frame")
        spacerMid.Size=UDim2.new(0,14,0,1); spacerMid.BackgroundTransparency=1
        spacerMid.BorderSizePixel=0; spacerMid.LayoutOrder=9; spacerMid.Parent=titleRow

        local lblHub = Instance.new("TextLabel")
        lblHub.Text="HUB"; lblHub.Size=UDim2.new(0,0,0,0); lblHub.AutomaticSize=Enum.AutomaticSize.XY
        lblHub.Font=Enum.Font.GothamBold; lblHub.TextSize=48
        lblHub.TextColor3=Theme.AccentColor; lblHub.TextTransparency=1
        lblHub.BackgroundTransparency=1; lblHub.BorderSizePixel=0
        lblHub.ZIndex=1006; lblHub.LayoutOrder=10; lblHub.RichText=false; lblHub.Parent=titleRow

        -- Linia akcentu pod tekstem
        local accentLine = Instance.new("Frame")
        accentLine.Size=UDim2.new(0,0,0,2); accentLine.Position=UDim2.new(0.5,0,0,56)
        accentLine.AnchorPoint=Vector2.new(0.5,0); accentLine.BackgroundColor3=Theme.AccentColor
        accentLine.BackgroundTransparency=1; accentLine.BorderSizePixel=0
        accentLine.ZIndex=1005; accentLine.Parent=textWrap
        Instance.new("UICorner",accentLine).CornerRadius=UDim.new(1,0)
        local alg=Instance.new("UIGradient")
        alg.Color=ColorSequence.new{
            ColorSequenceKeypoint.new(0,HexToColor3("#4580C9")),
            ColorSequenceKeypoint.new(0.5,HexToColor3("#5A9FE8")),
            ColorSequenceKeypoint.new(1,HexToColor3("#4580C9"))}
        alg.Parent=accentLine

        -- Status
        local lblStatus = Instance.new("TextLabel")
        lblStatus.Text="INITIALISING CORE"; lblStatus.Size=UDim2.new(1,0,0,22)
        lblStatus.Position=UDim2.new(0,0,0,64); lblStatus.Font=Enum.Font.Code; lblStatus.TextSize=12
        lblStatus.TextColor3=Theme.TextSecondary; lblStatus.TextTransparency=1
        lblStatus.BackgroundTransparency=1; lblStatus.BorderSizePixel=0
        lblStatus.ZIndex=1005; lblStatus.TextXAlignment=Enum.TextXAlignment.Center
        lblStatus.RichText=false; lblStatus.Parent=textWrap

        -- Progress bar
        local prgWrap = Instance.new("Frame")
        prgWrap.Size=UDim2.new(0,260,0,3); prgWrap.Position=UDim2.new(0.5,0,0,90)
        prgWrap.AnchorPoint=Vector2.new(0.5,0); prgWrap.BackgroundColor3=HexToColor3("#1a1f28")
        prgWrap.BackgroundTransparency=1; prgWrap.BorderSizePixel=0
        prgWrap.ZIndex=1005; prgWrap.Parent=textWrap
        Instance.new("UICorner",prgWrap).CornerRadius=UDim.new(1,0)

        local prgFill = Instance.new("Frame")
        prgFill.Size=UDim2.new(0,0,1,0); prgFill.BackgroundColor3=Theme.AccentColor
        prgFill.BackgroundTransparency=1; prgFill.BorderSizePixel=0
        prgFill.ZIndex=1006; prgFill.Parent=prgWrap
        Instance.new("UICorner",prgFill).CornerRadius=UDim.new(1,0)
        local pfg=Instance.new("UIGradient")
        pfg.Color=ColorSequence.new{
            ColorSequenceKeypoint.new(0,HexToColor3("#4580C9")),
            ColorSequenceKeypoint.new(0.6,HexToColor3("#5A9FE8")),
            ColorSequenceKeypoint.new(1,HexToColor3("#8BC4FF"))}
        pfg.Parent=prgFill

        -- ── Cząsteczki driftujące ─────────────────────────────────────────────
        local particles = {}
        for pi=1,7 do
            local px=Instance.new("Frame")
            px.Size=UDim2.new(0,math.random(2,4),0,math.random(2,4))
            px.Position=UDim2.new(math.random(15,85)/100,0,math.random(15,85)/100,0)
            px.AnchorPoint=Vector2.new(0.5,0.5)
            px.BackgroundColor3=Theme.AccentColor
            px.BackgroundTransparency=0.55+math.random()*0.35
            px.BorderSizePixel=0; px.ZIndex=1002; px.Parent=splash
            Instance.new("UICorner",px).CornerRadius=UDim.new(1,0)
            particles[pi]={
                frame=px, baseX=math.random(15,85)/100, baseY=math.random(15,85)/100,
                phase=math.random()*math.pi*2, speed=0.28+math.random()*0.38,
                range=0.011+math.random()*0.017,
            }
        end

        -- ════════════════════════════════════════════════════════════════════════
        -- ANIMACJA WEJŚCIA
        -- ════════════════════════════════════════════════════════════════════════

        tw(splash,{BackgroundTransparency=0},TI(.38,Enum.EasingStyle.Quad))
        task.wait(0.14)

        -- Narożniki
        for _,ln in ipairs(allCornerLines) do
            tw(ln,{BackgroundTransparency=0},TI(.48,Enum.EasingStyle.Exponential))
        end
        task.wait(0.16)

        -- Linia skanowania
        tw(scanLine,{Position=UDim2.new(1.02,0,0,0)},TI(.85,Enum.EasingStyle.Quad))
        task.wait(0.08)

        -- Poświata tła
        tw(glow,{BackgroundTransparency=0.76},TI(.6,Enum.EasingStyle.Quad))
        task.wait(0.06)

        -- Pierścienie
        tw(souter,{Transparency=0},TI(.38,Enum.EasingStyle.Quad))
        tw(sinner,{Transparency=0},TI(.38,Enum.EasingStyle.Quad))

        -- Logo wskakuje (spring scale 48→160)
        tw(logoWrap,{Size=UDim2.new(0,160,0,160)},TI_SPRING)
        tw(logoGlow,{BackgroundTransparency=0.82},TI(.5,Enum.EasingStyle.Quad))
        tw(logoImg, {ImageTransparency=0},        TI(.5,Enum.EasingStyle.Exponential))
        task.wait(0.24)

        -- Litery SENTENCE — stagger po 55ms
        for i,lbl in ipairs(charLabels) do
            task.spawn(function()
                task.wait((i-1)*0.055)
                tw(lbl,{TextTransparency=0},TI(.28,Enum.EasingStyle.Back))
            end)
        end
        task.wait(0.38)

        -- HUB z efektem Back
        tw(lblHub,{TextTransparency=0},TI(.32,Enum.EasingStyle.Back))
        task.wait(0.14)

        -- Linia akcentu rozszerza się
        tw(accentLine,{Size=UDim2.new(0,280,0,2),BackgroundTransparency=0},TI(.45,Enum.EasingStyle.Exponential))
        task.wait(0.1)

        -- Status + pasek
        tw(lblStatus,{TextTransparency=0.3},TI(.28,Enum.EasingStyle.Quad))
        tw(prgWrap,{BackgroundTransparency=0},TI_FAST)
        tw(prgFill,{BackgroundTransparency=0},TI_FAST)

        -- ── RenderStepped: obroty, parallax, pulsowanie ───────────────────────
        local rsConn = RS.RenderStepped:Connect(function(dt)
            if not splashAlive then return end
            ringOuter.Rotation = ringOuter.Rotation + 88 * dt
            ringInner.Rotation = ringInner.Rotation - 52 * dt
            -- Pulsowanie blasku
            local p = 0.82 + math.sin(tick()*2.2)*0.07
            logoGlow.BackgroundTransparency = 1-(1-0.82)*p
            -- Parallax myszy
            local mp = UIS:GetMouseLocation()
            local vs = Cam.ViewportSize
            local ox = (mp.X/vs.X-0.5)*38
            local oy = (mp.Y/vs.Y-0.5)*18
            glow.Position = UDim2.new(0.5,ox,0.5,oy)
            -- Cząsteczki
            for _,p2 in ipairs(particles) do
                local t2 = tick()*p2.speed+p2.phase
                p2.frame.Position = UDim2.new(
                    p2.baseX+math.sin(t2)*p2.range, 0,
                    p2.baseY+math.cos(t2*1.4)*p2.range, 0)
            end
        end)
        table.insert(splashConns, rsConn)

        -- ── Etapy ładowania ───────────────────────────────────────────────────
        local steps = {
            {label="VERIFYING MODULES",  pct=0.20},
            {label="INJECTING SCRIPTS",  pct=0.42},
            {label="LOADING ASSETS",     pct=0.64},
            {label="BUILDING INTERFACE", pct=0.86},
            {label="COMPLETE",           pct=1.00},
        }
        for _, step in ipairs(steps) do
            tw(lblStatus,{TextTransparency=1},TI(.07,Enum.EasingStyle.Quad))
            task.wait(0.08)
            lblStatus.Text = step.label
            tw(lblStatus,{TextTransparency=0.3},TI(.1,Enum.EasingStyle.Quad))
            tw(prgFill,{Size=UDim2.new(step.pct,0,1,0)},TI(.36,Enum.EasingStyle.Quad))
            -- Logo mini-flash przy każdym kroku
            tw(logoImg,{ImageTransparency=0.22},TI(.06,Enum.EasingStyle.Quad))
            task.wait(0.07)
            tw(logoImg,{ImageTransparency=0},TI(.1,Enum.EasingStyle.Quad))
            task.wait(step.pct==1 and 0.30 or 0.28)
        end

        task.wait(0.38)

        -- ── FADE OUT ─────────────────────────────────────────────────────────
        splashAlive = false
        for _,c in ipairs(splashConns) do pcall(function() c:Disconnect() end) end

        -- Litery wychodzą w odwrotnej kolejności
        for i=#charLabels,1,-1 do
            task.spawn(function()
                task.wait((#charLabels-i)*0.038)
                tw(charLabels[i],{TextTransparency=1},TI(.18,Enum.EasingStyle.Quad))
            end)
        end
        tw(lblHub,{TextTransparency=1},     TI(.18,Enum.EasingStyle.Quad))
        tw(accentLine,{BackgroundTransparency=1,Size=UDim2.new(0,0,0,2)},TI(.3,Enum.EasingStyle.Exponential))
        task.wait(0.14)

        tw(lblStatus,{TextTransparency=1},  TI(.16,Enum.EasingStyle.Quad))
        tw(prgFill,{BackgroundTransparency=1},TI(.16,Enum.EasingStyle.Quad))
        tw(prgWrap, {BackgroundTransparency=1},TI(.16,Enum.EasingStyle.Quad))
        tw(logoImg, {ImageTransparency=1},  TI(.26,Enum.EasingStyle.Quad))
        tw(souter,  {Transparency=1},       TI(.22,Enum.EasingStyle.Quad))
        tw(sinner,  {Transparency=1},       TI(.22,Enum.EasingStyle.Quad))
        tw(logoGlow,{BackgroundTransparency=1},TI(.28,Enum.EasingStyle.Quad))
        for _,ln in ipairs(allCornerLines) do
            tw(ln,{BackgroundTransparency=1},TI(.20,Enum.EasingStyle.Quad))
        end
        for _,p2 in ipairs(particles) do
            tw(p2.frame,{BackgroundTransparency=1},TI(.18,Enum.EasingStyle.Quad))
        end
        task.wait(0.16)
        tw(glow,  {BackgroundTransparency=1},TI(.32,Enum.EasingStyle.Quad))
        tw(splash,{BackgroundTransparency=1},TI(.42,Enum.EasingStyle.Quad),function()
            splash:Destroy()
        end)
    end) -- end splash task.spawn

    -- ── Notif Holder ─────────────────────────────────────────────────────────
    local notifHolder = Instance.new("Frame")
    notifHolder.Name="Notifs"; notifHolder.Size=UDim2.new(0,294,1,-16)
    notifHolder.Position=UDim2.new(0,8,0,8); notifHolder.BackgroundTransparency=1
    notifHolder.ZIndex=200; notifHolder.Parent=gui
    local nList=List(notifHolder,8)
    nList.VerticalAlignment=Enum.VerticalAlignment.Bottom
    self._notifHolder=notifHolder

    -- ── Główne okno ───────────────────────────────────────────────────────────
    local win = Box({
        Name="OGSentenceWin",Sz=UDim2.fromOffset(0,0),
        Pos=UDim2.new(0.5,0,0.5,0),AP=Vector2.new(0.5,0.5),
        Bg=Theme.PrimaryBackground,BgA=0,Clip=true,R=4,
        Border=true,BorderCol=Theme.BorderColor,BorderA=0,Z=1,Par=gui,
    })

    local topLine = Box({Name="TopLine",Sz=UDim2.new(1,0,0,2),Pos=UDim2.new(0,0,0,0),Bg=Theme.AccentColor,BgA=0,Z=6,Par=win})

    local glowTL = Box({Name="Glow",Sz=UDim2.new(0,200,0,120),Pos=UDim2.new(0,0,0,0),Bg=Theme.AccentColor,BgA=0.8,R=0,Z=0,Par=win})
    local g2=Instance.new("UIGradient")
    g2.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.6),NumberSequenceKeypoint.new(1,1)}
    g2.Rotation=135; g2.Parent=glowTL

    -- ── Title Bar ─────────────────────────────────────────────────────────────
    local TB_H = 40
    local titleBar = Box({Name="TitleBar",Sz=UDim2.new(1,0,0,TB_H),Pos=UDim2.new(0,0,0,2),Bg=Theme.PrimaryBackground,BgA=1,Z=4,Par=win})
    Draggable(titleBar, win)

    local CTRL_ICONS = {
        {"X","close",HexToColor3("#FF3C3C")},
        {"−","min",  Theme.TextSecondary},
        {"·","hide", Theme.TextSecondary},
    }
    local ctrlBtns = {}
    for idx,cd in ipairs(CTRL_ICONS) do
        local xPos=10+(idx-1)*30
        local cb  =Box({Name=cd[1],Sz=UDim2.new(0,22,0,22),Pos=UDim2.new(0,xPos,0.5,0),AP=Vector2.new(0,0.5),Bg=Theme.TertiaryBackground,BgA=0.6,R=4,Border=true,BorderCol=Theme.BorderColor,BorderA=0,Z=5,Par=titleBar})
        local cIco=Img({Ico=cd[2],Sz=UDim2.new(0,12,0,12),Pos=UDim2.new(0.5,0,0.5,0),AP=Vector2.new(0.5,0.5),Col=Theme.TextSecondary,Z=6,Par=cb})
        local cCL =Btn(cb,7)
        cb.MouseEnter:Connect(function() tw(cb,{BackgroundColor3=cd[3],BackgroundTransparency=0},TI_FAST); tw(cIco,{ImageColor3=Color3.new(1,1,1)},TI_FAST) end)
        cb.MouseLeave:Connect(function() tw(cb,{BackgroundColor3=Theme.TertiaryBackground,BackgroundTransparency=0.6},TI_FAST); tw(cIco,{ImageColor3=Theme.TextSecondary},TI_FAST) end)
        ctrlBtns[cd[1]]={frame=cb,click=cCL}
    end

    -- Ikona 24x24
    local ICON_SIZE=24; local ICON_X_POS=108
    Img({Ico=cfg.Icon,Sz=UDim2.new(0,ICON_SIZE,0,ICON_SIZE),Pos=UDim2.new(0,ICON_X_POS,0.5,0),AP=Vector2.new(0,0.5),Col=Theme.TextPrimary,Z=5,Par=titleBar})
    local nameOffX = cfg.Icon~="" and (ICON_X_POS+ICON_SIZE+6) or ICON_X_POS

    -- Tytuł 15→17, sub 11→13
    local nameLabel=Txt({T=cfg.Name,Sz=UDim2.new(0,220,0,20),Pos=UDim2.new(0,nameOffX,0,5),Font=Enum.Font.GothamBold,TS=17,Col=Theme.TextPrimary,Alpha=1,Z=5,Par=titleBar})
    local subLabel =Txt({T=cfg.Subtitle~="" and ("/ "..cfg.Subtitle) or ("/ v"..Sentence.Version),Sz=UDim2.new(0,200,0,13),Pos=UDim2.new(0,nameOffX,0,26),Font=Enum.Font.Gotham,TS=13,Col=Theme.TextSecondary,Alpha=1,Z=5,Par=titleBar})

    local statBar=Box({Name="StatBar",Sz=UDim2.new(0,140,0,24),Pos=UDim2.new(1,-8,0.5,0),AP=Vector2.new(1,0.5),Bg=Theme.SecondaryBackground,BgA=0,R=4,Z=5,Par=titleBar})
    -- Stat bar 11→13
    local pingL=Txt({T="— ms",Sz=UDim2.new(0,65,1,0),Pos=UDim2.new(0,0,0,0),Font=Enum.Font.Code,TS=13,Col=Theme.TextSecondary,AX=Enum.TextXAlignment.Right,Z=6,Par=statBar})
    local plrsL=Txt({T="—/—", Sz=UDim2.new(0,60,1,0),Pos=UDim2.new(0,70,0,0),Font=Enum.Font.Code,TS=13,Col=Theme.TextSecondary,Z=6,Par=statBar})

    task.spawn(function()
        while task.wait(1.5) do
            if not win or not win.Parent then break end
            pcall(function()
                pingL.Text = math.floor(LP:GetNetworkPing()*1000).."ms"
                plrsL.Text = #Plrs:GetPlayers().."/"..Plrs.MaxPlayers
            end)
        end
    end)

    Wire(titleBar, false).Position=UDim2.new(0,0,1,-1)

    -- ── Sidebar ───────────────────────────────────────────────────────────────
    local SIDE_W=48
    local sidebar=Box({Name="Sidebar",Sz=UDim2.new(0,SIDE_W,1,-TB_H-2),Pos=UDim2.new(0,0,0,TB_H+2),Bg=Theme.SecondaryBackground,BgA=0,Z=3,Par=win})
    Wire(sidebar,true).Position=UDim2.new(1,-1,0,0)

    local tabIconsList=Instance.new("ScrollingFrame")
    tabIconsList.Name="TabIcons"; tabIconsList.Size=UDim2.new(1,0,1,-56)
    tabIconsList.Position=UDim2.new(0,0,0,12); tabIconsList.BackgroundTransparency=1
    tabIconsList.BorderSizePixel=0; tabIconsList.ScrollBarThickness=0
    tabIconsList.AutomaticCanvasSize=Enum.AutomaticSize.Y; tabIconsList.ZIndex=4; tabIconsList.Parent=sidebar
    List(tabIconsList,4,Enum.FillDirection.Vertical,Enum.HorizontalAlignment.Center)
    Pad(tabIconsList,4,4,0,0)

    local avBox=Box({Sz=UDim2.new(0,32,0,32),Pos=UDim2.new(0.5,0,1,-10),AP=Vector2.new(0.5,1),Bg=Theme.SecondaryBackground,R=4,Z=4,Par=sidebar})
    local avImg=Instance.new("ImageLabel")
    avImg.Size=UDim2.new(1,0,1,0); avImg.BackgroundTransparency=1; avImg.ZIndex=5; avImg.Parent=avBox
    Instance.new("UICorner",avImg).CornerRadius=UDim.new(0,4)
    local avStroke=Instance.new("UIStroke"); avStroke.Color=Theme.AccentColor; avStroke.Thickness=1.5; avStroke.Transparency=0.55; avStroke.Parent=avImg
    pcall(function() avImg.Image=Plrs:GetUserThumbnailAsync(LP.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size48x48) end)

    -- Tooltip (12→14)
    local tooltip=Box({Name="Tooltip",Sz=UDim2.new(0,0,0,26),Pos=UDim2.new(0,SIDE_W+4,0,0),Bg=Theme.TertiaryBackground,R=4,Border=true,BorderCol=Theme.BorderColor,BorderA=0,Z=20,Vis=false,Par=win})
    tooltip.AutomaticSize=Enum.AutomaticSize.X; Pad(tooltip,0,0,9,9)
    local tooltipL=Txt({T="",Sz=UDim2.new(0,0,1,0),Font=Enum.Font.GothamSemibold,TS=14,Col=Theme.TextPrimary,Z=21,Par=tooltip})
    tooltipL.AutomaticSize=Enum.AutomaticSize.X

    local contentArea=Box({Name="Content",Sz=UDim2.new(1,-SIDE_W-1,1,-TB_H-2),Pos=UDim2.new(0,SIDE_W+1,0,TB_H+2),Bg=Theme.PrimaryBackground,BgA=1,Clip=true,Z=2,Par=win})

    local W = {
        _gui=gui,_win=win,_content=contentArea,
        _tabs={},_activeTab=nil,_visible=true,_minimized=false,_cfg=cfg,
    }

    local function SwitchTab(tabId)
        for _,tab in ipairs(W._tabs) do
            if tab.id==tabId then
                tab.page.Visible=true
                tw(tab.activeBar,{BackgroundTransparency=0},TI_FAST)
                tw(tab.iconImg,{ImageColor3=Theme.AccentColor},TI_FAST)
                tw(tab.bgBox,{BackgroundTransparency=0.88},TI_FAST)
                W._activeTab=tabId
            else
                tab.page.Visible=false
                tw(tab.activeBar,{BackgroundTransparency=1},TI_FAST)
                tw(tab.iconImg,{ImageColor3=Theme.TextSecondary},TI_FAST)
                tw(tab.bgBox,{BackgroundTransparency=1},TI_FAST)
            end
        end
    end

    -- ── Ekran ładowania ───────────────────────────────────────────────────────
    if cfg.LoadingEnabled then
        local lf=Box({Name="Loading",Sz=UDim2.new(1,0,1,0),Bg=Theme.PrimaryBackground,BgA=0,Z=50,Par=win})
        Instance.new("UICorner",lf).CornerRadius=UDim.new(0,4)
        local lLogo =Img({Ico=cfg.Icon,Sz=UDim2.new(0,32,0,32),Pos=UDim2.new(0.5,0,0.5,-52),AP=Vector2.new(0.5,0.5),Col=Theme.TextPrimary,Z=51,Par=lf})
        -- Loading title 22→24, sub 12→14, pct 11→13
        local lTitle=Txt({T=cfg.LoadingTitle,    Sz=UDim2.new(1,0,0,26),Pos=UDim2.new(0.5,0,0.5,-14),AP=Vector2.new(0.5,0.5),Font=Enum.Font.GothamBold,TS=24,Col=Theme.TextPrimary,  AX=Enum.TextXAlignment.Center,Alpha=1,Z=51,Par=lf})
        local lSub  =Txt({T=cfg.LoadingSubtitle, Sz=UDim2.new(1,0,0,16),Pos=UDim2.new(0.5,0,0.5, 16),AP=Vector2.new(0.5,0.5),Font=Enum.Font.Code,      TS=14,Col=Theme.TextSecondary,AX=Enum.TextXAlignment.Center,Alpha=1,Z=51,Par=lf})
        local pTrack=Box({Sz=UDim2.new(0.45,0,0,3),Pos=UDim2.new(0.5,0,0.5,44),AP=Vector2.new(0.5,0.5),Bg=Theme.TertiaryBackground,R=2,Z=51,Par=lf})
        local pFill =Box({Sz=UDim2.new(0,0,1,0),Bg=Theme.AccentColor,R=2,Z=52,Par=pTrack})
        local pctL  =Txt({T="0%",Sz=UDim2.new(1,0,0,16),Pos=UDim2.new(0.5,0,0.5,54),AP=Vector2.new(0.5,0.5),Font=Enum.Font.Code,TS=13,Col=Theme.AccentColor,AX=Enum.TextXAlignment.Center,Z=51,Par=lf})

        tw(win,{Size=FULL},TI_SLOW); task.wait(0.3)
        tw(lTitle,{TextTransparency=0},TI_MED); task.wait(0.1)
        tw(lSub,{TextTransparency=0.3},TI_MED)
        if cfg.Icon~="" then tw(lLogo,{ImageTransparency=0},TI_MED) end
        local pct=0
        for _,step in ipairs({0.12,0.08,0.15,0.1,0.18,0.12,0.1,0.15}) do
            pct=math.min(pct+step,1)
            tw(pFill,{Size=UDim2.new(pct,0,1,0)},TI(.25,Enum.EasingStyle.Quad))
            pctL.Text=math.floor(pct*100).."%"
            task.wait(0.13+math.random()*0.1)
        end
        pctL.Text="100%"
        tw(pFill,{Size=UDim2.new(1,0,1,0)},TI_FAST); task.wait(0.3)
        tw(pFill,{BackgroundColor3=Theme.TextPrimary},TI_FAST); task.wait(0.08)
        tw(lTitle,{TextTransparency=1},TI_FAST); tw(lSub,{TextTransparency=1},TI_FAST)
        tw(pctL,{TextTransparency=1},TI_FAST); tw(pTrack,{BackgroundTransparency=1},TI_FAST)
        tw(pFill,{BackgroundTransparency=1},TI_FAST)
        if cfg.Icon~="" then tw(lLogo,{ImageTransparency=1},TI_FAST) end
        task.wait(0.2)
        tw(lf,{BackgroundTransparency=1},TI_MED,function() lf:Destroy() end); task.wait(0.3)
    else
        tw(win,{Size=FULL},TI_SLOW); task.wait(0.35)
    end

    tw(topLine,  {BackgroundTransparency=0},TI_MED)
    tw(nameLabel,{TextTransparency=0},      TI_MED)
    tw(subLabel, {TextTransparency=0},      TI_MED)

    local function HideW()
        W._visible=false
        tw(win,{Size=UDim2.fromOffset(0,0)},TI_SLOW,function() win.Visible=false end)
    end
    local function ShowW()
        win.Visible=true; W._visible=true
        tw(win,{Size=W._minimized and MINI or FULL},TI_SLOW)
    end

    -- ── Zamknięcie X → wyładuj opcje + zniszcz ───────────────────────────────
    ctrlBtns["X"].click.MouseButton1Click:Connect(function()
        Sentence:Destroy()
    end)
    ctrlBtns["·"].click.MouseButton1Click:Connect(function()
        Sentence:Notify({Title="Hidden",Content="Press "..cfg.ToggleBind.Name.." to restore.",Type="Info"})
        HideW()
    end)
    ctrlBtns["−"].click.MouseButton1Click:Connect(function()
        W._minimized = not W._minimized
        if W._minimized then
            sidebar.Visible=false; contentArea.Visible=false
            tw(win,{Size=MINI},TI_MED)
        else
            tw(win,{Size=FULL},TI_MED,function() sidebar.Visible=true; contentArea.Visible=true end)
        end
    end)

    track(UIS.InputBegan:Connect(function(inp,proc)
        if proc then return end
        if inp.KeyCode==cfg.ToggleBind then
            if W._visible then HideW() else ShowW() end
        end
    end))

    -- ══════════════════════════════════════════════════════════════════════════
    -- HOME TAB
    -- ══════════════════════════════════════════════════════════════════════════
    function W:CreateHomeTab(hCfg)
        hCfg = merge({Icon="home"}, hCfg or {})
        local tabId="Home"
        local hBox=Box({Name="HomeTabBtn",Sz=UDim2.new(0,40,0,40),Bg=Theme.AccentColor,BgA=1,R=4,Z=5,Par=tabIconsList})
        local hBar=Box({Sz=UDim2.new(0,3,0.6,0),Pos=UDim2.new(0,0,0.2,0),Bg=Theme.AccentColor,BgA=1,R=0,Z=6,Par=hBox})
        local hIco=Img({Ico=hCfg.Icon,Sz=UDim2.new(0,18,0,18),Col=Theme.TextSecondary,Z=6,Par=hBox})
        local hCL =Btn(hBox,7)

        local hPage=Instance.new("ScrollingFrame")
        hPage.Name="HomePage"; hPage.Size=UDim2.new(1,0,1,0)
        hPage.BackgroundTransparency=1; hPage.BorderSizePixel=0
        hPage.ScrollBarThickness=2; hPage.ScrollBarImageColor3=Theme.BorderColor
        hPage.CanvasSize=UDim2.new(0,0,0,0); hPage.AutomaticCanvasSize=Enum.AutomaticSize.Y
        hPage.ZIndex=3; hPage.Visible=false; hPage.Parent=contentArea
        List(hPage,10); Pad(hPage,16,16,18,18)

        -- Karta profilu
        local pCard=Box({Name="PCard",Sz=UDim2.new(1,0,0,82),Bg=Theme.SecondaryBackground,BgA=0,R=4,Border=true,BorderCol=Theme.BorderColor,Z=3,Par=hPage})
        Box({Sz=UDim2.new(0,3,1,0),Bg=Theme.AccentColor,R=0,Z=4,Par=pCard})
        local pAv=Instance.new("ImageLabel")
        pAv.Size=UDim2.new(0,50,0,50); pAv.Position=UDim2.new(0,16,0.5,0); pAv.AnchorPoint=Vector2.new(0,0.5)
        pAv.BackgroundTransparency=1; pAv.ZIndex=4; pAv.Parent=pCard
        Instance.new("UICorner",pAv).CornerRadius=UDim.new(0,4)
        local pAS=Instance.new("UIStroke"); pAS.Color=Theme.AccentColor; pAS.Thickness=1.5; pAS.Transparency=0.5; pAS.Parent=pAv
        pcall(function() pAv.Image=Plrs:GetUserThumbnailAsync(LP.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size150x150) end)
        -- DisplayName 17→19, @name 12→14
        Txt({T=LP.DisplayName,Sz=UDim2.new(1,-90,0,22),Pos=UDim2.new(0,80,0,14),Font=Enum.Font.GothamBold,TS=19,Col=Theme.TextPrimary,  Z=4,Par=pCard})
        Txt({T="@"..LP.Name,  Sz=UDim2.new(1,-90,0,16),Pos=UDim2.new(0,80,0,38),Font=Enum.Font.Code,      TS=14,Col=Theme.TextSecondary,Z=4,Par=pCard})

        -- Karta statystyk
        local sCard=Box({Name="SCard",Sz=UDim2.new(1,0,0,106),Bg=Theme.SecondaryBackground,BgA=0,R=4,Border=true,BorderCol=Theme.BorderColor,Z=3,Par=hPage})
        -- Header 10→12
        Txt({T="SRV",       Sz=UDim2.new(0,32,0,14),Pos=UDim2.new(0,14,0,8),Font=Enum.Font.GothamBold,TS=12,Col=Theme.AccentColor,  Z=4,Par=sCard})
        Txt({T="STATISTICS",Sz=UDim2.new(1,-50,0,14),Pos=UDim2.new(0,48,0,8),Font=Enum.Font.GothamBold,TS=12,Col=Theme.TextSecondary,Z=4,Par=sCard})
        local statVals={}
        for i,sd in ipairs({{"PLAYERS",""},{"PING",""},{"UPTIME",""},{"REGION",""}}) do
            local col=(i-1)%2; local row=math.floor((i-1)/2)
            local cW=(WW-SIDE_W-50)/2
            local x=14+col*cW; local y=26+row*36
            -- labels 10→12, values 15→17
            Txt({T=sd[1],Sz=UDim2.new(0,130,0,13),Pos=UDim2.new(0,x,0,y),Font=Enum.Font.GothamBold,TS=12,Col=Theme.TextSecondary,Z=4,Par=sCard})
            statVals[sd[1]]=Txt({T="—",Sz=UDim2.new(0,170,0,19),Pos=UDim2.new(0,x,0,y+14),Font=Enum.Font.Code,TS=17,Col=Theme.TextPrimary,Z=4,Par=sCard})
        end
        task.spawn(function()
            while task.wait(1) do
                if not win or not win.Parent then break end
                pcall(function()
                    statVals["PLAYERS"].Text=#Plrs:GetPlayers().."/"..Plrs.MaxPlayers
                    statVals["PING"].Text=math.floor(LP:GetNetworkPing()*1000).."ms"
                    local t=math.floor(time())
                    statVals["UPTIME"].Text=string.format("%02d:%02d:%02d",math.floor(t/3600),math.floor(t%3600/60),t%60)
                    pcall(function() statVals["REGION"].Text=game:GetService("LocalizationService"):GetCountryRegionForPlayerAsync(LP) end)
                end)
            end
        end)

        table.insert(W._tabs,{id=tabId,btn=hBox,page=hPage,activeBar=hBar,iconImg=hIco,bgBox=hBox})
        hCL.MouseButton1Click:Connect(function() SwitchTab(tabId) end)
        hBox.MouseEnter:Connect(function()
            if W._activeTab~=tabId then tw(hBox,{BackgroundTransparency=0.92},TI_FAST) end
            tooltipL.Text="Home"; tooltip.Visible=true
            tw(tooltip,{Position=UDim2.new(0,SIDE_W+4,0,hBox.AbsolutePosition.Y-win.AbsolutePosition.Y+8)},TI_FAST)
        end)
        hBox.MouseLeave:Connect(function()
            if W._activeTab~=tabId then tw(hBox,{BackgroundTransparency=1},TI_FAST) end
            tooltip.Visible=false
        end)
        SwitchTab(tabId)
        return {Activate=function() SwitchTab(tabId) end}
    end

    -- ══════════════════════════════════════════════════════════════════════════
    -- CREATE TAB
    -- ══════════════════════════════════════════════════════════════════════════
    function W:CreateTab(tCfg)
        tCfg=merge({Name="Tab",Icon="unk",ShowTitle=true},tCfg or {})
        local Tab={}; local tabId=tCfg.Name

        local tBox=Box({Name=tCfg.Name.."Btn",Sz=UDim2.new(0,40,0,40),Bg=Theme.AccentColor,BgA=1,R=4,Z=5,Ord=#W._tabs+1,Par=tabIconsList})
        local tBar=Box({Sz=UDim2.new(0,3,0.6,0),Pos=UDim2.new(0,0,0.2,0),Bg=Theme.AccentColor,BgA=1,R=0,Z=6,Par=tBox})
        local tIco=Img({Ico=tCfg.Icon,Sz=UDim2.new(0,18,0,18),Col=Theme.TextSecondary,Z=6,Par=tBox})
        local tCL =Btn(tBox,7)

        local tPage=Instance.new("ScrollingFrame")
        tPage.Name=tCfg.Name; tPage.Size=UDim2.new(1,0,1,0)
        tPage.BackgroundTransparency=1; tPage.BorderSizePixel=0
        tPage.ScrollBarThickness=2; tPage.ScrollBarImageColor3=Theme.BorderColor
        tPage.CanvasSize=UDim2.new(0,0,0,0); tPage.AutomaticCanvasSize=Enum.AutomaticSize.Y
        tPage.ZIndex=3; tPage.Visible=false; tPage.Parent=contentArea
        List(tPage,8); Pad(tPage,16,16,18,18)

        if tCfg.ShowTitle then
            -- Tab title row 16→18
            local tRow=Box({Sz=UDim2.new(1,0,0,30),BgA=1,Z=3,Par=tPage})
            Img({Ico=tCfg.Icon,Sz=UDim2.new(0,16,0,16),Pos=UDim2.new(0,0,0.5,0),AP=Vector2.new(0,0.5),Col=Theme.AccentColor,Z=4,Par=tRow})
            Txt({T=tCfg.Name:upper(),Sz=UDim2.new(1,-24,0,18),Pos=UDim2.new(0,24,0.5,0),AP=Vector2.new(0,0.5),Font=Enum.Font.GothamBold,TS=18,Col=Theme.TextPrimary,Z=4,Par=tRow})
        end

        table.insert(W._tabs,{id=tabId,btn=tBox,page=tPage,activeBar=tBar,iconImg=tIco,bgBox=tBox})
        function Tab:Activate() SwitchTab(tabId) end
        tCL.MouseButton1Click:Connect(function() Tab:Activate() end)
        tBox.MouseEnter:Connect(function()
            if W._activeTab~=tabId then tw(tBox,{BackgroundTransparency=0.92},TI_FAST) end
            tooltipL.Text=tCfg.Name; tooltip.Visible=true
            tw(tooltip,{Position=UDim2.new(0,SIDE_W+4,0,tBox.AbsolutePosition.Y-win.AbsolutePosition.Y+8)},TI_FAST)
        end)
        tBox.MouseLeave:Connect(function()
            if W._activeTab~=tabId then tw(tBox,{BackgroundTransparency=1},TI_FAST) end
            tooltip.Visible=false
        end)

        -- ── CreateSection ─────────────────────────────────────────────────────
        local _secN=0
        function Tab:CreateSection(sName)
            sName=sName or ""; _secN=_secN+1
            local Sec={}
            local shRow=Box({Name="SH",Sz=UDim2.new(1,0,0,sName~="" and 22 or 6),BgA=1,Z=3,Par=tPage,Ord=#tPage:GetChildren()})

            if sName~="" then
                Wire(shRow,false).Size=UDim2.new(1,0,0,1)
                Wire(shRow,false).Position=UDim2.new(0,0,1,-1)
                local badge=Box({Sz=UDim2.new(0,0,0,18),Pos=UDim2.new(0,0,0.5,0),AP=Vector2.new(0,0.5),Bg=Theme.PrimaryBackground,R=0,Z=4,Par=shRow})
                badge.AutomaticSize=Enum.AutomaticSize.X; Pad(badge,0,0,0,6)
                local bRow=Instance.new("Frame"); bRow.Size=UDim2.new(0,0,1,0)
                bRow.AutomaticSize=Enum.AutomaticSize.X; bRow.BackgroundTransparency=1
                bRow.ZIndex=5; bRow.Parent=badge
                List(bRow,0,Enum.FillDirection.Horizontal,nil,Enum.VerticalAlignment.Center)
                -- Badge font 9→12
                local numL=Instance.new("TextLabel"); numL.Text="#"..string.format("%02d",_secN).." "
                numL.Size=UDim2.new(0,0,1,0); numL.AutomaticSize=Enum.AutomaticSize.X
                numL.Font=Enum.Font.GothamBold; numL.TextSize=12; numL.TextColor3=Theme.AccentColor
                numL.BackgroundTransparency=1; numL.BorderSizePixel=0; numL.ZIndex=5; numL.RichText=false; numL.Parent=bRow
                local namL=Instance.new("TextLabel"); namL.Text=sName:upper()
                namL.Size=UDim2.new(0,0,1,0); namL.AutomaticSize=Enum.AutomaticSize.X
                namL.Font=Enum.Font.GothamBold; namL.TextSize=12; namL.TextColor3=Theme.TextSecondary
                namL.BackgroundTransparency=1; namL.BorderSizePixel=0; namL.ZIndex=5; namL.RichText=false; namL.Parent=bRow
            end

            local secCon=Box({Name="SC",Sz=UDim2.new(1,0,0,0),BgA=1,Z=3,AutoY=true,Ord=shRow.LayoutOrder+1,Par=tPage})
            List(secCon,4)

            -- Elem height: standardowy 40, z description 58
            local function Elem(h,autoY)
                local f=Box({Sz=UDim2.new(1,0,0,h or 40),Bg=Theme.SecondaryBackground,BgA=0,R=4,Border=true,BorderCol=Theme.BorderColor,Z=3,Par=secCon})
                if autoY then f.AutomaticSize=Enum.AutomaticSize.Y end
                return f
            end
            local function HoverEffect(f)
                f.MouseEnter:Connect(function() tw(f.UIStroke,{Color=Theme.ButtonHoverBackground},TI_FAST) end)
                f.MouseLeave:Connect(function() tw(f.UIStroke,{Color=Theme.BorderColor},TI_FAST) end)
            end

            function Sec:CreateDivider()
                local d=Wire(secCon,false); d.Size=UDim2.new(1,0,0,1)
                return {Destroy=function() d:Destroy() end}
            end

            -- Label (13→15)
            function Sec:CreateLabel(lc)
                lc=merge({Text="Label",Style=1},lc or {})
                local cMap={[1]=Theme.TextSecondary,[2]=NotifColors.Info,[3]=NotifColors.Warning}
                local f=Elem(32); local xo=lc.Style>1 and 14 or 10
                if lc.Style>1 then Box({Sz=UDim2.new(0,3,0.7,0),Pos=UDim2.new(0,0,0.15,0),Bg=cMap[lc.Style],R=0,Z=4,Par=f}) end
                local lb=Txt({T=lc.Text,Sz=UDim2.new(1,-xo-6,0,15),Pos=UDim2.new(0,xo,0.5,0),AP=Vector2.new(0,0.5),Font=Enum.Font.GothamSemibold,TS=15,Col=cMap[lc.Style],Z=4,Par=f})
                return {Set=function(self,t) lb.Text=t end, Destroy=function() f:Destroy() end}
            end

            -- Paragraph (title 14→16, content 13→15)
            function Sec:CreateParagraph(pc)
                pc=merge({Title="Title",Content=""},pc or {})
                local f=Elem(0,true); Pad(f,12,12,14,14); List(f,4)
                local pt   =Txt({T=pc.Title,  Sz=UDim2.new(1,0,0,18),Font=Enum.Font.GothamBold,TS=16,Col=Theme.TextPrimary,  Z=4,Par=f})
                local pcont=Txt({T=pc.Content,Sz=UDim2.new(1,0,0,0), Font=Enum.Font.Gotham,    TS=15,Col=Theme.TextSecondary,Z=4,Wrap=true,AutoY=true,Par=f})
                return {
                    Set=function(self,s) if s.Title then pt.Text=s.Title end; if s.Content then pcont.Text=s.Content end end,
                    Destroy=function() f:Destroy() end,
                }
            end

            -- Button (name 14→16, desc 12→14)
            function Sec:CreateButton(bc)
                bc=merge({Name="Button",Description=nil,Callback=function()end},bc or {})
                local f=Elem(bc.Description and 58 or 40); f.ClipsDescendants=true
                local chargeFill=Box({Sz=UDim2.new(0,0,1,0),Bg=Theme.ButtonHoverBackground,BgA=0,R=0,Z=3,Par=f})
                local pip=Box({Sz=UDim2.new(0,3,1,0),Pos=UDim2.new(0,0,0,0),Bg=Theme.AccentColor,BgA=1,R=0,Z=4,Par=f})
                Txt({T=bc.Name,Sz=UDim2.new(1,-48,0,17),Pos=UDim2.new(0,14,0,bc.Description and 10 or 12),Font=Enum.Font.GothamSemibold,TS=16,Col=Theme.TextPrimary,Z=4,Par=f})
                if bc.Description then
                    Txt({T=bc.Description,Sz=UDim2.new(1,-48,0,15),Pos=UDim2.new(0,14,0,30),Font=Enum.Font.Gotham,TS=14,Col=Theme.TextSecondary,Z=4,Par=f})
                end
                Img({Ico="arr",Sz=UDim2.new(0,13,0,13),Pos=UDim2.new(1,-20,0.5,0),AP=Vector2.new(0,0.5),Col=Theme.AccentColor,IA=0.6,Z=5,Par=f})
                local cl=Btn(f,6)
                f.MouseEnter:Connect(function()
                    tw(chargeFill,{Size=UDim2.new(1,0,1,0),BackgroundTransparency=0},TI(.3,Enum.EasingStyle.Quad))
                    tw(pip,{BackgroundTransparency=0},TI_FAST); tw(f.UIStroke,{Color=Theme.AccentColor},TI_FAST)
                end)
                f.MouseLeave:Connect(function()
                    tw(chargeFill,{Size=UDim2.new(0,0,1,0),BackgroundTransparency=1},TI_MED)
                    tw(pip,{BackgroundTransparency=1},TI_FAST); tw(f.UIStroke,{Color=Theme.BorderColor},TI_FAST)
                end)
                cl.MouseButton1Click:Connect(function()
                    tw(chargeFill,{BackgroundColor3=Theme.AccentColor},TI_FAST); task.wait(0.12)
                    tw(chargeFill,{BackgroundColor3=Theme.ButtonHoverBackground,Size=UDim2.new(0,0,1,0),BackgroundTransparency=1},TI_MED)
                    safe(bc.Callback)
                end)
                return {Destroy=function() f:Destroy() end}
            end

            -- Toggle (name 14→16, desc 12→14)
            function Sec:CreateToggle(tc)
                tc=merge({Name="Toggle",Description=nil,CurrentValue=false,Flag=nil,Callback=function()end},tc or {})
                local f=Elem(tc.Description and 58 or 40)
                Txt({T=tc.Name,Sz=UDim2.new(1,-70,0,17),Pos=UDim2.new(0,14,0,tc.Description and 10 or 12),Font=Enum.Font.GothamSemibold,TS=16,Col=Theme.TextPrimary,Z=4,Par=f})
                if tc.Description then
                    Txt({T=tc.Description,Sz=UDim2.new(1,-70,0,15),Pos=UDim2.new(0,14,0,30),Font=Enum.Font.Gotham,TS=14,Col=Theme.TextSecondary,Z=4,Par=f})
                end
                local trk =Box({Sz=UDim2.new(0,44,0,22),Pos=UDim2.new(1,-56,0.5,0),AP=Vector2.new(0,0.5),Bg=Theme.TertiaryBackground,R=3,Border=true,BorderCol=Theme.BorderColor,Z=4,Par=f})
                local knob=Box({Sz=UDim2.new(0,16,0,16),Pos=UDim2.new(0,3,0.5,0),AP=Vector2.new(0,0.5),Bg=Theme.TextSecondary,R=2,Z=5,Par=trk})
                local TV={CurrentValue=tc.CurrentValue,Type="Toggle",Settings=tc}
                local function upd()
                    if TV.CurrentValue then
                        tw(trk,{BackgroundColor3=Theme.ButtonHoverBackground},TI_MED)
                        tw(trk.UIStroke,{Color=Theme.AccentColor},TI_MED)
                        tw(knob,{Position=UDim2.new(0,25,0.5,0),BackgroundColor3=Theme.AccentColor},TI_SPRING)
                    else
                        tw(trk,{BackgroundColor3=Theme.TertiaryBackground},TI_MED)
                        tw(trk.UIStroke,{Color=Theme.BorderColor},TI_MED)
                        tw(knob,{Position=UDim2.new(0,3,0.5,0),BackgroundColor3=Theme.TextSecondary},TI_SPRING)
                    end
                end
                upd(); HoverEffect(f)
                Btn(f,5).MouseButton1Click:Connect(function()
                    TV.CurrentValue=not TV.CurrentValue; upd(); safe(tc.Callback,TV.CurrentValue)
                end)
                function TV:Set(v) TV.CurrentValue=v; upd(); safe(tc.Callback,v) end
                if tc.Flag then Sentence.Flags[tc.Flag]=TV; Sentence.Options[tc.Flag]=TV end
                return TV
            end

            -- Slider (name 14→16, value 12→14)
            function Sec:CreateSlider(sc)
                sc=merge({Name="Slider",Range={0,100},Increment=1,CurrentValue=50,Suffix="",Flag=nil,Callback=function()end},sc or {})
                local f=Elem(58)
                Txt({T=sc.Name,Sz=UDim2.new(1,-110,0,17),Pos=UDim2.new(0,14,0,9),Font=Enum.Font.GothamSemibold,TS=16,Col=Theme.TextPrimary,Z=4,Par=f})
                local valChip=Box({Sz=UDim2.new(0,0,0,20),Pos=UDim2.new(1,-13,0,7),AP=Vector2.new(1,0),Bg=Theme.TertiaryBackground,R=4,Z=4,Par=f})
                valChip.AutomaticSize=Enum.AutomaticSize.X; Pad(valChip,0,0,7,7)
                local valL=Txt({T=tostring(sc.CurrentValue)..sc.Suffix,Sz=UDim2.new(0,0,1,0),Font=Enum.Font.Code,TS=14,Col=Theme.AccentColor,AX=Enum.TextXAlignment.Center,Z=5,Par=valChip})
                valL.AutomaticSize=Enum.AutomaticSize.X
                local trackBg=Box({Sz=UDim2.new(1,-28,0,5),Pos=UDim2.new(0,14,0,38),Bg=Theme.TertiaryBackground,R=2,Z=4,Par=f})
                local fillF  =Box({Sz=UDim2.new(0,0,1,0),Bg=Theme.AccentColor,R=2,Z=5,Par=trackBg})
                local thumb  =Box({Sz=UDim2.new(0,11,0,11),Pos=UDim2.new(0,0,0.5,0),AP=Vector2.new(0.5,0.5),Bg=Theme.TextPrimary,R=2,Z=6,Par=trackBg})
                local SV={CurrentValue=sc.CurrentValue,Type="Slider",Settings=sc}
                local mn,mx,inc=sc.Range[1],sc.Range[2],sc.Increment
                local function setV(v)
                    v=math.clamp(v,mn,mx); v=math.floor(v/inc+0.5)*inc
                    v=tonumber(string.format("%.10g",v)); SV.CurrentValue=v
                    valL.Text=tostring(v)..sc.Suffix
                    local pct=(v-mn)/(mx-mn)
                    tw(fillF,{Size=UDim2.new(pct,0,1,0)},TI_FAST)
                    tw(thumb,{Position=UDim2.new(pct,0,0.5,0)},TI_FAST)
                end
                setV(sc.CurrentValue)
                local drag=false; local bCL=Btn(trackBg,8)
                local function fromInp(i)
                    local rel=math.clamp((i.Position.X-trackBg.AbsolutePosition.X)/trackBg.AbsoluteSize.X,0,1)
                    setV(mn+(mx-mn)*rel); safe(sc.Callback,SV.CurrentValue)
                end
                bCL.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                        drag=true; fromInp(i)
                    end
                end)
                UIS.InputEnded:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                        drag=false
                    end
                end)
                track(UIS.InputChanged:Connect(function(i)
                    if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
                        fromInp(i)
                    end
                end))
                HoverEffect(f)
                function SV:Set(v) setV(v); safe(sc.Callback,SV.CurrentValue) end
                if sc.Flag then Sentence.Flags[sc.Flag]=SV; Sentence.Options[sc.Flag]=SV end
                return SV
            end

            return Sec
        end

        local _ds
        local function gds() if not _ds then _ds=Tab:CreateSection("") end; return _ds end
        for _,m in ipairs({"CreateButton","CreateLabel","CreateParagraph","CreateToggle","CreateSlider","CreateDivider"}) do
            Tab[m]=function(self,...) return gds()[m](gds(),...) end
        end
        return Tab
    end

    function W:SaveConfiguration() end
    function W:LoadConfiguration() end
    return W
end

-- ══════════════════════════════════════════════════════════════════════════════
-- DESTROY — wyładuj opcje, rozłącz, zniszcz
-- ══════════════════════════════════════════════════════════════════════════════
function Sentence:Destroy()
    -- 1. Wyładuj wszystkie zarejestrowane opcje
    for _, option in pairs(self.Flags) do
        pcall(function()
            if option.Type == "Toggle" then
                -- Wywołaj callback z false jeśli był aktywny
                if option.CurrentValue then
                    option.CurrentValue = false
                    if option.Settings and type(option.Settings.Callback) == "function" then
                        option.Settings.Callback(false)
                    end
                end
            elseif option.Type == "Slider" then
                -- Przywróć do wartości minimalnej (Range[1])
                local minVal = (option.Settings and option.Settings.Range and option.Settings.Range[1]) or 0
                if option.CurrentValue ~= minVal then
                    option.CurrentValue = minVal
                    if option.Settings and type(option.Settings.Callback) == "function" then
                        option.Settings.Callback(minVal)
                    end
                end
            end
        end)
    end

    -- 2. Rozłącz wszystkie połączenia
    for _, c in ipairs(self._conns) do
        pcall(function() c:Disconnect() end)
    end
    self._conns = {}

    -- 3. Zniszcz ScreenGui
    if self._notifHolder and self._notifHolder.Parent then
        self._notifHolder.Parent:Destroy()
    end

    -- 4. Wyczyść tablice
    self.Flags   = {}
    self.Options = {}
end

return Sentence

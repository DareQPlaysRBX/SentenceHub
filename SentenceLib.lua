--[[
╔═══════════════════════════════════════════════════════════╗
║  SENTENCE GUI · OG Sentence Edition                           ║
║  Wersja: 2.0 (Przepisana)                                 ║
╚═══════════════════════════════════════════════════════════╝
--]]

local Sentence = {
    Version = "2.0",
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

-- ── Kolory Notyfikacji ────────────────────────────────────────────────────────
local NotifColors = {
    Info    = Theme.AccentColor,
    Success = HexToColor3("#00D68F"),
    Warning = HexToColor3("#FFB800"),
    Error   = HexToColor3("#FF3C3C"),
}

-- ── Tween Presets ─────────────────────────────────────────────────────────────
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

-- ── Funkcje Pomocnicze ────────────────────────────────────────────────────────
local function merge(d, t)
    t = t or {}
    for k, v in pairs(d) do if t[k] == nil then t[k] = v end end
    return t
end
local function track(c) table.insert(Sentence._conns, c); return c end
local function safe(cb, ...) local ok, e = pcall(cb, ...); if not ok then warn("SENTENCE: "..tostring(e)) end end

local ICONS = {
    close  = "rbxassetid://6031094678",
    min    = "rbxassetid://6031094687",
    hide   = "rbxassetid://6031075929",
    home   = "rbxassetid://6026568195",
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
    f.Size                   = p.Sz   or UDim2.new(1, 0, 0, 36)
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
        uc.CornerRadius = type(p.R) == "number" and UDim.new(0, p.R) or (p.R or UDim.new(0, 4))
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
    l.Size                   = p.Sz    or UDim2.new(1, 0, 0, 14)
    l.Position               = p.Pos   or UDim2.new()
    l.AnchorPoint            = p.AP    or Vector2.zero
    l.Font                   = p.Font  or Enum.Font.GothamSemibold
    l.TextSize               = p.TS    or 13
    l.TextColor3             = p.Col   or Theme.TextPrimary
    l.TextTransparency       = p.Alpha or 0
    l.TextXAlignment         = p.AX    or Enum.TextXAlignment.Left
    l.TextYAlignment         = p.AY    or Enum.TextYAlignment.Center
    l.TextWrapped            = p.Wrap  or false
    l.RichText               = false   -- wyłączone globalnie
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
    i.Size                   = p.Sz   or UDim2.new(0, 18, 0, 18)
    i.Position               = p.Pos  or UDim2.new(0.5, 0, 0.5, 0)
    i.AnchorPoint            = p.AP   or Vector2.new(0.5, 0.5)
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
    b.Size                   = UDim2.new(1, 0, 1, 0)
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
    f.Size = vertical and UDim2.new(0, 1, 1, 0) or UDim2.new(1, 0, 0, 1)
    f.Parent = par
    return f
end

-- ── System Przeciągania ───────────────────────────────────────────────────────
local function Draggable(handle, win)
    local dragging  = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = win.Position
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement
        or  input.UserInputType == Enum.UserInputType.Touch) and dragging then
            local delta = input.Position - dragStart
            TS:Create(win, TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                ),
            }):Play()
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- SYSTEM NOTYFIKACJI
-- ══════════════════════════════════════════════════════════════════════════════
function Sentence:Notify(data)
    task.spawn(function()
        data = merge({ Title="Notice", Content="", Icon="info", Type="Info", Duration=4 }, data)
        local ac = NotifColors[data.Type] or Theme.AccentColor

        local card = Box({
            Name      = "NCard",
            Sz        = UDim2.new(0, 290, 0, 0),
            Pos       = UDim2.new(0, 0, 1, 0),
            AP        = Vector2.new(0, 1),
            Bg        = Theme.NotificationPanelBackground,
            BgA       = 1,
            Clip      = true,
            R         = 4,
            Border    = true,
            BorderCol = Theme.NotificationPanelBorder,
            BorderA   = 1,
            Par       = self._notifHolder,
        })

        local contentContainer = Box({ Name="Content", Sz=UDim2.new(1,0,0,0), BgA=1, AutoY=true, Par=card })
        Pad(contentContainer, 12, 12, 34, 12)

        local strip = Box({ Sz=UDim2.new(0,3,1,0), Pos=UDim2.new(0,0,0,0), Bg=ac, BgA=1, R=0, Z=4, Par=card })

        local iconImg = Img({ Ico=data.Icon, Sz=UDim2.new(0,14,0,14), Pos=UDim2.new(0,12,0,12), AP=Vector2.zero, Col=ac, IA=1, Z=4, Par=card })

        local ttl = Txt({ T=data.Title,   Sz=UDim2.new(1,0,0,16), Font=Enum.Font.GothamBold, TS=13, Col=Theme.NotificationPanelText, Alpha=1, Z=4, Par=contentContainer })
        local msg = Txt({ T=data.Content, Sz=UDim2.new(1,0,0,0),  Pos=UDim2.new(0,0,0,20),  Font=Enum.Font.Gotham, TS=12, Col=Theme.TextSecondary, Alpha=1, Wrap=true, Z=4, AutoY=true, Par=contentContainer })

        task.wait()
        local targetHeight = contentContainer.AbsoluteSize.Y

        tw(card,          { Size=UDim2.new(0,290,0,targetHeight) }, TI_MED)
        tw(card,          { BackgroundTransparency=0 },  TI_FAST)
        tw(card.UIStroke, { Transparency=0 },            TI_FAST)
        tw(strip,         { BackgroundTransparency=0 },  TI_FAST)
        tw(iconImg,       { ImageTransparency=0 },       TI_FAST)
        tw(ttl,           { TextTransparency=0 },        TI_FAST)
        tw(msg,           { TextTransparency=0 },        TI_FAST)

        task.wait(data.Duration)

        tw(msg,           { TextTransparency=1 },        TI_FAST)
        tw(ttl,           { TextTransparency=1 },        TI_FAST)
        tw(iconImg,       { ImageTransparency=1 },       TI_FAST)
        tw(strip,         { BackgroundTransparency=1 },  TI_FAST)
        tw(card,          { BackgroundTransparency=1 },  TI_FAST)
        tw(card.UIStroke, { Transparency=1 },            TI_FAST)

        task.wait(0.15)
        tw(card, { Size=UDim2.new(0,290,0,0) }, TI_MED, function() card:Destroy() end)
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- CREATE WINDOW
-- ══════════════════════════════════════════════════════════════════════════════
function Sentence:CreateWindow(cfg)
    cfg = merge({
        Name            = "SENTENCE",
        Subtitle        = "",
        Icon            = "",
        ToggleBind      = Enum.KeyCode.RightControl,
        LoadingEnabled  = true,
        LoadingTitle    = "SENTENCE",
        LoadingSubtitle = "INITIALISING",
        ConfigurationSaving = { Enabled=false, FolderName="Sentence", FileName="config" },
    }, cfg)

    local vp   = Cam.ViewportSize
    local WW   = math.clamp(vp.X - 100, 560, 750)
    local WH   = math.clamp(vp.Y - 80,  400, 500)
    local FULL = UDim2.fromOffset(WW, WH)
    local MINI = UDim2.fromOffset(WW, 40)

    -- ── ScreenGui ────────────────────────────────────────────────────────────
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

    -- ── Notif Holder ─────────────────────────────────────────────────────────
    local notifHolder = Instance.new("Frame")
    notifHolder.Name                   = "Notifs"
    notifHolder.Size                   = UDim2.new(0, 294, 1, -16)
    notifHolder.Position               = UDim2.new(0, 8, 0, 8)
    notifHolder.BackgroundTransparency = 1
    notifHolder.ZIndex                 = 200
    notifHolder.Parent                 = gui
    local nList = List(notifHolder, 8)
    nList.VerticalAlignment = Enum.VerticalAlignment.Bottom
    self._notifHolder = notifHolder

    -- ── Główne Okno ──────────────────────────────────────────────────────────
    local win = Box({
        Name      = "OGSentenceWin",
        Sz        = UDim2.fromOffset(0, 0),
        Pos       = UDim2.new(0.5, 0, 0.5, 0),
        AP        = Vector2.new(0.5, 0.5),
        Bg        = Theme.PrimaryBackground,
        BgA       = 0,
        Clip      = true,
        R         = 4,
        Border    = true,
        BorderCol = Theme.BorderColor,
        BorderA   = 0,
        Z         = 1,
        Par       = gui,
    })

    local topLine = Box({ Name="TopLine", Sz=UDim2.new(1,0,0,2), Pos=UDim2.new(0,0,0,0), Bg=Theme.AccentColor, BgA=0, Z=6, Par=win })

    local glowTL = Box({ Name="Glow", Sz=UDim2.new(0,200,0,120), Pos=UDim2.new(0,0,0,0), Bg=Theme.AccentColor, BgA=0.8, R=0, Z=0, Par=win })
    local glowGrad = Instance.new("UIGradient")
    glowGrad.Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0,0.6), NumberSequenceKeypoint.new(1,1) }
    glowGrad.Rotation = 135
    glowGrad.Parent   = glowTL

    -- ── Title Bar ────────────────────────────────────────────────────────────
    local TB_H    = 40
    local titleBar = Box({ Name="TitleBar", Sz=UDim2.new(1,0,0,TB_H), Pos=UDim2.new(0,0,0,2), Bg=Theme.PrimaryBackground, BgA=1, Z=4, Par=win })
    Draggable(titleBar, win)

    -- Przyciski sterowania
    local CTRL_ICONS = {
        { "X", "close", HexToColor3("#FF3C3C") },
        { "−", "min",   Theme.TextSecondary },
        { "·", "hide",  Theme.TextSecondary },
    }
    local ctrlBtns = {}
    for idx, cd in ipairs(CTRL_ICONS) do
        local xPos = 10 + (idx - 1) * 30
        local cb = Box({ Name=cd[1], Sz=UDim2.new(0,22,0,22), Pos=UDim2.new(0,xPos,0.5,0), AP=Vector2.new(0,0.5), Bg=Theme.TertiaryBackground, BgA=0.6, R=4, Border=true, BorderCol=Theme.BorderColor, BorderA=0, Z=5, Par=titleBar })
        local cIco = Img({ Ico=cd[2], Sz=UDim2.new(0,12,0,12), Pos=UDim2.new(0.5,0,0.5,0), AP=Vector2.new(0.5,0.5), Col=Theme.TextSecondary, Z=6, Par=cb })
        local cCL = Btn(cb, 7)
        cb.MouseEnter:Connect(function()
            tw(cb,   { BackgroundColor3=cd[3], BackgroundTransparency=0 }, TI_FAST)
            tw(cIco, { ImageColor3=Color3.new(1,1,1) },                    TI_FAST)
        end)
        cb.MouseLeave:Connect(function()
            tw(cb,   { BackgroundColor3=Theme.TertiaryBackground, BackgroundTransparency=0.6 }, TI_FAST)
            tw(cIco, { ImageColor3=Theme.TextSecondary },                                       TI_FAST)
        end)
        ctrlBtns[cd[1]] = { frame=cb, click=cCL }
    end

    -- ── Ikona 32×32 ──────────────────────────────────────────────────────────
    local ICON_SIZE  = 32
    local ICON_X_POS = 108
    local logoImg = Img({
        Ico = cfg.Icon,
        Sz  = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE),
        Pos = UDim2.new(0, ICON_X_POS, 0.5, 0),
        AP  = Vector2.new(0, 0.5),
        Col = Theme.TextPrimary,
        Z   = 5, Par=titleBar,
    })

    -- Pozycja tekstu uwzględnia szerokość ikony + 6px margines
    local nameOffX = cfg.Icon ~= "" and (ICON_X_POS + ICON_SIZE + 6) or ICON_X_POS

    local nameLabel = Txt({ T=cfg.Name, Sz=UDim2.new(0,220,0,16), Pos=UDim2.new(0,nameOffX,0,7),  Font=Enum.Font.GothamBold, TS=13, Col=Theme.TextPrimary,   Alpha=1, Z=5, Par=titleBar })
    local subLabel  = Txt({ T=cfg.Subtitle~="" and ("/ "..cfg.Subtitle) or ("/ v"..Sentence.Version), Sz=UDim2.new(0,200,0,12), Pos=UDim2.new(0,nameOffX,0,24), Font=Enum.Font.Gotham, TS=10, Col=Theme.TextSecondary, Alpha=1, Z=5, Par=titleBar })

    local statBar = Box({ Name="StatBar", Sz=UDim2.new(0,130,0,24), Pos=UDim2.new(1,-8,0.5,0), AP=Vector2.new(1,0.5), Bg=Theme.SecondaryBackground, BgA=0, R=4, Z=5, Par=titleBar })
    local pingL   = Txt({ T="— ms", Sz=UDim2.new(0,60,1,0), Pos=UDim2.new(0,0,0,0),  Font=Enum.Font.Code, TS=10, Col=Theme.TextSecondary, AX=Enum.TextXAlignment.Right, Z=6, Par=statBar })
    local plrsL   = Txt({ T="—/—",  Sz=UDim2.new(0,55,1,0), Pos=UDim2.new(0,66,0,0), Font=Enum.Font.Code, TS=10, Col=Theme.TextSecondary, Z=6, Par=statBar })

    task.spawn(function()
        while task.wait(1.5) do
            if not win or not win.Parent then break end
            pcall(function()
                pingL.Text = math.floor(LP:GetNetworkPing() * 1000).."ms"
                plrsL.Text = #Plrs:GetPlayers().."/"..Plrs.MaxPlayers
            end)
        end
    end)

    Wire(titleBar, false).Position = UDim2.new(0, 0, 1, -1)

    -- ── Sidebar ──────────────────────────────────────────────────────────────
    local SIDE_W = 48
    local sidebar = Box({ Name="Sidebar", Sz=UDim2.new(0,SIDE_W,1,-TB_H-2), Pos=UDim2.new(0,0,0,TB_H+2), Bg=Theme.SecondaryBackground, BgA=0, Z=3, Par=win })
    Wire(sidebar, true).Position = UDim2.new(1, -1, 0, 0)

    local tabIconsList = Instance.new("ScrollingFrame")
    tabIconsList.Name                   = "TabIcons"
    tabIconsList.Size                   = UDim2.new(1, 0, 1, -56)
    tabIconsList.Position               = UDim2.new(0, 0, 0, 12)
    tabIconsList.BackgroundTransparency = 1
    tabIconsList.BorderSizePixel        = 0
    tabIconsList.ScrollBarThickness     = 0
    tabIconsList.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    tabIconsList.ZIndex                 = 4
    tabIconsList.Parent                 = sidebar
    List(tabIconsList, 4, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center)
    Pad(tabIconsList, 4, 4, 0, 0)

    local avBox = Box({ Sz=UDim2.new(0,32,0,32), Pos=UDim2.new(0.5,0,1,-10), AP=Vector2.new(0.5,1), Bg=Theme.SecondaryBackground, R=4, Z=4, Par=sidebar })
    local avImg = Instance.new("ImageLabel")
    avImg.Size                   = UDim2.new(1, 0, 1, 0)
    avImg.BackgroundTransparency = 1
    avImg.ZIndex                 = 5
    avImg.Parent                 = avBox
    Instance.new("UICorner", avImg).CornerRadius = UDim.new(0, 4)
    local avStroke = Instance.new("UIStroke")
    avStroke.Color        = Theme.AccentColor
    avStroke.Thickness    = 1.5
    avStroke.Transparency = 0.55
    avStroke.Parent       = avImg
    pcall(function() avImg.Image = Plrs:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end)

    local tooltip = Box({ Name="Tooltip", Sz=UDim2.new(0,0,0,24), Pos=UDim2.new(0,SIDE_W+4,0,0), Bg=Theme.TertiaryBackground, R=4, Border=true, BorderCol=Theme.BorderColor, BorderA=0, Z=20, Vis=false, Par=win })
    tooltip.AutomaticSize = Enum.AutomaticSize.X
    Pad(tooltip, 0, 0, 8, 8)
    local tooltipL = Txt({ T="", Sz=UDim2.new(0,0,1,0), Font=Enum.Font.GothamSemibold, TS=11, Col=Theme.TextPrimary, Z=21, Par=tooltip })
    tooltipL.AutomaticSize = Enum.AutomaticSize.X

    local contentArea = Box({ Name="Content", Sz=UDim2.new(1,-SIDE_W-1,1,-TB_H-2), Pos=UDim2.new(0,SIDE_W+1,0,TB_H+2), Bg=Theme.PrimaryBackground, BgA=1, Clip=true, Z=2, Par=win })

    -- ── State okna ───────────────────────────────────────────────────────────
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
                tw(tab.activeBar, { BackgroundTransparency=0 },        TI_FAST)
                tw(tab.iconImg,   { ImageColor3=Theme.AccentColor },   TI_FAST)
                tw(tab.bgBox,     { BackgroundTransparency=0.88 },     TI_FAST)
                W._activeTab = tabId
            else
                tab.page.Visible = false
                tw(tab.activeBar, { BackgroundTransparency=1 },        TI_FAST)
                tw(tab.iconImg,   { ImageColor3=Theme.TextSecondary }, TI_FAST)
                tw(tab.bgBox,     { BackgroundTransparency=1 },        TI_FAST)
            end
        end
    end

    -- ── Ekran Ładowania ───────────────────────────────────────────────────────
    if cfg.LoadingEnabled then
        local lf = Box({ Name="Loading", Sz=UDim2.new(1,0,1,0), Bg=Theme.PrimaryBackground, BgA=0, Z=50, Par=win })
        Instance.new("UICorner", lf).CornerRadius = UDim.new(0, 4)

        local lLogo  = Img({ Ico=cfg.Icon, Sz=UDim2.new(0,32,0,32), Pos=UDim2.new(0.5,0,0.5,-50), AP=Vector2.new(0.5,0.5), Col=Theme.TextPrimary, Z=51, Par=lf })
        local lTitle = Txt({ T=cfg.LoadingTitle,    Sz=UDim2.new(1,0,0,24), Pos=UDim2.new(0.5,0,0.5,-14), AP=Vector2.new(0.5,0.5), Font=Enum.Font.GothamBold, TS=20, Col=Theme.TextPrimary,   AX=Enum.TextXAlignment.Center, Alpha=1, Z=51, Par=lf })
        local lSub   = Txt({ T=cfg.LoadingSubtitle, Sz=UDim2.new(1,0,0,14), Pos=UDim2.new(0.5,0,0.5, 14), AP=Vector2.new(0.5,0.5), Font=Enum.Font.Code,       TS=11, Col=Theme.TextSecondary, AX=Enum.TextXAlignment.Center, Alpha=1, Z=51, Par=lf })
        local pTrack = Box({ Sz=UDim2.new(0.45,0,0,3), Pos=UDim2.new(0.5,0,0.5,42), AP=Vector2.new(0.5,0.5), Bg=Theme.TertiaryBackground, R=2, Z=51, Par=lf })
        local pFill  = Box({ Sz=UDim2.new(0,0,1,0), Bg=Theme.AccentColor, R=2, Z=52, Par=pTrack })
        local pctL   = Txt({ T="0%", Sz=UDim2.new(1,0,0,14), Pos=UDim2.new(0.5,0,0.5,52), AP=Vector2.new(0.5,0.5), Font=Enum.Font.Code, TS=10, Col=Theme.AccentColor, AX=Enum.TextXAlignment.Center, Z=51, Par=lf })

        tw(win, { Size=FULL }, TI_SLOW)
        task.wait(0.3)
        tw(lTitle, { TextTransparency=0 }, TI_MED)
        task.wait(0.1)
        tw(lSub, { TextTransparency=0.3 }, TI_MED)
        if cfg.Icon ~= "" then tw(lLogo, { ImageTransparency=0 }, TI_MED) end

        local pct = 0
        for _, step in ipairs({ 0.12, 0.08, 0.15, 0.1, 0.18, 0.12, 0.1, 0.15 }) do
            pct = math.min(pct + step, 1)
            tw(pFill, { Size=UDim2.new(pct,0,1,0) }, TI(.25, Enum.EasingStyle.Quad))
            pctL.Text = math.floor(pct * 100).."%"
            task.wait(0.13 + math.random() * 0.1)
        end
        pctL.Text = "100%"
        tw(pFill, { Size=UDim2.new(1,0,1,0) }, TI_FAST)
        task.wait(0.3)
        tw(pFill, { BackgroundColor3=Theme.TextPrimary }, TI_FAST)
        task.wait(0.08)

        tw(lTitle,  { TextTransparency=1 }, TI_FAST)
        tw(lSub,    { TextTransparency=1 }, TI_FAST)
        tw(pctL,    { TextTransparency=1 }, TI_FAST)
        tw(pTrack,  { BackgroundTransparency=1 }, TI_FAST)
        tw(pFill,   { BackgroundTransparency=1 }, TI_FAST)
        if cfg.Icon ~= "" then tw(lLogo, { ImageTransparency=1 }, TI_FAST) end
        task.wait(0.2)
        tw(lf, { BackgroundTransparency=1 }, TI_MED, function() lf:Destroy() end)
        task.wait(0.3)
    else
        tw(win, { Size=FULL }, TI_SLOW)
        task.wait(0.35)
    end

    tw(topLine,   { BackgroundTransparency=0 }, TI_MED)
    tw(nameLabel, { TextTransparency=0 },       TI_MED)
    tw(subLabel,  { TextTransparency=0 },       TI_MED)

    -- ── Logika przycisków sterowania ─────────────────────────────────────────
    local function HideW()
        W._visible = false
        tw(win, { Size=UDim2.fromOffset(0,0) }, TI_SLOW, function() win.Visible = false end)
    end
    local function ShowW()
        win.Visible = true
        W._visible  = true
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
            sidebar.Visible     = false
            contentArea.Visible = false
            tw(win, { Size=MINI }, TI_MED)
        else
            tw(win, { Size=FULL }, TI_MED, function()
                sidebar.Visible     = true
                contentArea.Visible = true
            end)
        end
    end)

    track(UIS.InputBegan:Connect(function(inp, proc)
        if proc then return end
        if inp.KeyCode == cfg.ToggleBind then
            if W._visible then HideW() else ShowW() end
        end
    end))

    -- ══════════════════════════════════════════════════════════════════════════
    -- HOME TAB
    -- ══════════════════════════════════════════════════════════════════════════
    function W:CreateHomeTab(hCfg)
        hCfg = merge({ Icon="home" }, hCfg or {})
        local tabId = "Home"

        local hBox = Box({ Name="HomeTabBtn", Sz=UDim2.new(0,40,0,40), Bg=Theme.AccentColor, BgA=1, R=4, Z=5, Par=tabIconsList })
        local hBar = Box({ Sz=UDim2.new(0,3,0.6,0), Pos=UDim2.new(0,0,0.2,0), Bg=Theme.AccentColor, BgA=1, R=0, Z=6, Par=hBox })
        local hIco = Img({ Ico=hCfg.Icon, Sz=UDim2.new(0,18,0,18), Col=Theme.TextSecondary, Z=6, Par=hBox })
        local hCL  = Btn(hBox, 7)

        local hPage = Instance.new("ScrollingFrame")
        hPage.Name                   = "HomePage"
        hPage.Size                   = UDim2.new(1, 0, 1, 0)
        hPage.BackgroundTransparency = 1
        hPage.BorderSizePixel        = 0
        hPage.ScrollBarThickness     = 2
        hPage.ScrollBarImageColor3   = Theme.BorderColor
        hPage.CanvasSize             = UDim2.new(0, 0, 0, 0)
        hPage.AutomaticCanvasSize    = Enum.AutomaticSize.Y
        hPage.ZIndex                 = 3
        hPage.Visible                = false
        hPage.Parent                 = contentArea
        List(hPage, 10)
        Pad(hPage, 16, 16, 18, 18)

        -- Karta profilu
        local pCard = Box({ Name="PCard", Sz=UDim2.new(1,0,0,76), Bg=Theme.SecondaryBackground, BgA=0, R=4, Border=true, BorderCol=Theme.BorderColor, Z=3, Par=hPage })
        Box({ Sz=UDim2.new(0,3,1,0), Bg=Theme.AccentColor, R=0, Z=4, Par=pCard })

        local pAv = Instance.new("ImageLabel")
        pAv.Size                   = UDim2.new(0, 48, 0, 48)
        pAv.Position               = UDim2.new(0, 16, 0.5, 0)
        pAv.AnchorPoint            = Vector2.new(0, 0.5)
        pAv.BackgroundTransparency = 1
        pAv.ZIndex                 = 4
        pAv.Parent                 = pCard
        Instance.new("UICorner", pAv).CornerRadius = UDim.new(0, 4)
        local pAS = Instance.new("UIStroke")
        pAS.Color        = Theme.AccentColor
        pAS.Thickness    = 1.5
        pAS.Transparency = 0.5
        pAS.Parent       = pAv
        pcall(function() pAv.Image = Plrs:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end)

        Txt({ T=LP.DisplayName, Sz=UDim2.new(1,-90,0,18), Pos=UDim2.new(0,76,0,16), Font=Enum.Font.GothamBold, TS=16, Col=Theme.TextPrimary,   Z=4, Par=pCard })
        Txt({ T="@"..LP.Name,  Sz=UDim2.new(1,-90,0,13), Pos=UDim2.new(0,76,0,36), Font=Enum.Font.Code,       TS=11, Col=Theme.TextSecondary, Z=4, Par=pCard })

        -- Karta statystyk serwera
        local sCard = Box({ Name="SCard", Sz=UDim2.new(1,0,0,98), Bg=Theme.SecondaryBackground, BgA=0, R=4, Border=true, BorderCol=Theme.BorderColor, Z=3, Par=hPage })

        -- Nagłówek podzielony na dwa TextLabel zamiast font-color tagów
        Txt({ T="SRV",        Sz=UDim2.new(0,28,0,12),  Pos=UDim2.new(0,14,0,8), Font=Enum.Font.GothamBold, TS=9, Col=Theme.AccentColor,    Z=4, Par=sCard })
        Txt({ T="STATISTICS", Sz=UDim2.new(1,-50,0,12), Pos=UDim2.new(0,44,0,8), Font=Enum.Font.GothamBold, TS=9, Col=Theme.TextSecondary,  Z=4, Par=sCard })

        local statVals = {}
        local sData = { {"PLAYERS",""}, {"PING",""}, {"UPTIME",""}, {"REGION",""} }
        for i, sd in ipairs(sData) do
            local col = (i - 1) % 2
            local row = math.floor((i - 1) / 2)
            local cW  = (WW - SIDE_W - 50) / 2
            local x   = 14 + col * cW
            local y   = 24 + row * 32
            Txt({ T=sd[1], Sz=UDim2.new(0,120,0,11), Pos=UDim2.new(0,x,0,y),    Font=Enum.Font.GothamBold, TS=9,  Col=Theme.TextSecondary, Z=4, Par=sCard })
            statVals[sd[1]] = Txt({ T="—", Sz=UDim2.new(0,160,0,15), Pos=UDim2.new(0,x,0,y+12), Font=Enum.Font.Code, TS=14, Col=Theme.TextPrimary, Z=4, Par=sCard })
        end

        task.spawn(function()
            while task.wait(1) do
                if not win or not win.Parent then break end
                pcall(function()
                    statVals["PLAYERS"].Text = #Plrs:GetPlayers().."/"..Plrs.MaxPlayers
                    statVals["PING"].Text    = math.floor(LP:GetNetworkPing() * 1000).."ms"
                    local t = math.floor(time())
                    statVals["UPTIME"].Text  = string.format("%02d:%02d:%02d", math.floor(t/3600), math.floor(t%3600/60), t%60)
                    pcall(function() statVals["REGION"].Text = game:GetService("LocalizationService"):GetCountryRegionForPlayerAsync(LP) end)
                end)
            end
        end)

        table.insert(W._tabs, { id=tabId, btn=hBox, page=hPage, activeBar=hBar, iconImg=hIco, bgBox=hBox })
        hCL.MouseButton1Click:Connect(function() SwitchTab(tabId) end)

        hBox.MouseEnter:Connect(function()
            if W._activeTab ~= tabId then tw(hBox, { BackgroundTransparency=0.92 }, TI_FAST) end
            tooltipL.Text   = "Home"
            tooltip.Visible = true
            tw(tooltip, { Position=UDim2.new(0,SIDE_W+4,0,hBox.AbsolutePosition.Y-win.AbsolutePosition.Y+8) }, TI_FAST)
        end)
        hBox.MouseLeave:Connect(function()
            if W._activeTab ~= tabId then tw(hBox, { BackgroundTransparency=1 }, TI_FAST) end
            tooltip.Visible = false
        end)

        SwitchTab(tabId)
        return { Activate=function() SwitchTab(tabId) end }
    end

    -- ══════════════════════════════════════════════════════════════════════════
    -- CREATE TAB
    -- ══════════════════════════════════════════════════════════════════════════
    function W:CreateTab(tCfg)
        tCfg = merge({ Name="Tab", Icon="unk", ShowTitle=true }, tCfg or {})
        local Tab   = {}
        local tabId = tCfg.Name

        local tBox = Box({ Name=tCfg.Name.."Btn", Sz=UDim2.new(0,40,0,40), Bg=Theme.AccentColor, BgA=1, R=4, Z=5, Ord=#W._tabs+1, Par=tabIconsList })
        local tBar = Box({ Sz=UDim2.new(0,3,0.6,0), Pos=UDim2.new(0,0,0.2,0), Bg=Theme.AccentColor, BgA=1, R=0, Z=6, Par=tBox })
        local tIco = Img({ Ico=tCfg.Icon, Sz=UDim2.new(0,18,0,18), Col=Theme.TextSecondary, Z=6, Par=tBox })
        local tCL  = Btn(tBox, 7)

        local tPage = Instance.new("ScrollingFrame")
        tPage.Name                   = tCfg.Name
        tPage.Size                   = UDim2.new(1, 0, 1, 0)
        tPage.BackgroundTransparency = 1
        tPage.BorderSizePixel        = 0
        tPage.ScrollBarThickness     = 2
        tPage.ScrollBarImageColor3   = Theme.BorderColor
        tPage.CanvasSize             = UDim2.new(0, 0, 0, 0)
        tPage.AutomaticCanvasSize    = Enum.AutomaticSize.Y
        tPage.ZIndex                 = 3
        tPage.Visible                = false
        tPage.Parent                 = contentArea
        List(tPage, 8)
        Pad(tPage, 16, 16, 18, 18)

        if tCfg.ShowTitle then
            local titleRow = Box({ Sz=UDim2.new(1,0,0,26), BgA=1, Z=3, Par=tPage })
            Img({ Ico=tCfg.Icon, Sz=UDim2.new(0,14,0,14), Pos=UDim2.new(0,0,0.5,0), AP=Vector2.new(0,0.5), Col=Theme.AccentColor, Z=4, Par=titleRow })
            Txt({ T=tCfg.Name:upper(), Sz=UDim2.new(1,-22,0,16), Pos=UDim2.new(0,22,0.5,0), AP=Vector2.new(0,0.5), Font=Enum.Font.GothamBold, TS=15, Col=Theme.TextPrimary, Z=4, Par=titleRow })
        end

        table.insert(W._tabs, { id=tabId, btn=tBox, page=tPage, activeBar=tBar, iconImg=tIco, bgBox=tBox })
        function Tab:Activate() SwitchTab(tabId) end

        tCL.MouseButton1Click:Connect(function() Tab:Activate() end)
        tBox.MouseEnter:Connect(function()
            if W._activeTab ~= tabId then tw(tBox, { BackgroundTransparency=0.92 }, TI_FAST) end
            tooltipL.Text   = tCfg.Name
            tooltip.Visible = true
            tw(tooltip, { Position=UDim2.new(0,SIDE_W+4,0,tBox.AbsolutePosition.Y-win.AbsolutePosition.Y+8) }, TI_FAST)
        end)
        tBox.MouseLeave:Connect(function()
            if W._activeTab ~= tabId then tw(tBox, { BackgroundTransparency=1 }, TI_FAST) end
            tooltip.Visible = false
        end)

        -- ── CreateSection ─────────────────────────────────────────────────────
        local _secN = 0
        function Tab:CreateSection(sName)
            sName = sName or ""
            _secN = _secN + 1
            local Sec = {}

            local shRow = Box({ Name="SH", Sz=UDim2.new(1,0,0,sName~="" and 20 or 6), BgA=1, Z=3, Par=tPage, Ord=#tPage:GetChildren() })

            if sName ~= "" then
                Wire(shRow, false).Size     = UDim2.new(1, 0, 0, 1)
                Wire(shRow, false).Position = UDim2.new(0, 0, 1, -1)

                local badge = Box({ Sz=UDim2.new(0,0,0,16), Pos=UDim2.new(0,0,0.5,0), AP=Vector2.new(0,0.5), Bg=Theme.PrimaryBackground, R=0, Z=4, Par=shRow })
                badge.AutomaticSize = Enum.AutomaticSize.X
                Pad(badge, 0, 0, 0, 6)

                -- Row contenera dla dwóch osobnych TextLabel zamiast font-color tagów
                local badgeRow = Instance.new("Frame")
                badgeRow.Size                   = UDim2.new(0, 0, 1, 0)
                badgeRow.AutomaticSize          = Enum.AutomaticSize.X
                badgeRow.BackgroundTransparency = 1
                badgeRow.ZIndex                 = 5
                badgeRow.Parent                 = badge
                List(badgeRow, 0, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)

                -- Numer sekcji w kolorze akcentu
                local numL = Instance.new("TextLabel")
                numL.Text                   = "#"..string.format("%02d", _secN).." "
                numL.Size                   = UDim2.new(0, 0, 1, 0)
                numL.AutomaticSize          = Enum.AutomaticSize.X
                numL.Font                   = Enum.Font.GothamBold
                numL.TextSize               = 9
                numL.TextColor3             = Theme.AccentColor
                numL.BackgroundTransparency = 1
                numL.BorderSizePixel        = 0
                numL.ZIndex                 = 5
                numL.RichText               = false
                numL.Parent                 = badgeRow

                -- Nazwa sekcji w kolorze TextSecondary
                local nameL = Instance.new("TextLabel")
                nameL.Text                   = sName:upper()
                nameL.Size                   = UDim2.new(0, 0, 1, 0)
                nameL.AutomaticSize          = Enum.AutomaticSize.X
                nameL.Font                   = Enum.Font.GothamBold
                nameL.TextSize               = 9
                nameL.TextColor3             = Theme.TextSecondary
                nameL.BackgroundTransparency = 1
                nameL.BorderSizePixel        = 0
                nameL.ZIndex                 = 5
                nameL.RichText               = false
                nameL.Parent                 = badgeRow
            end

            local secCon = Box({ Name="SC", Sz=UDim2.new(1,0,0,0), BgA=1, Z=3, AutoY=true, Ord=shRow.LayoutOrder+1, Par=tPage })
            List(secCon, 4)

            local function Elem(h, autoY)
                local f = Box({ Sz=UDim2.new(1,0,0,h or 36), Bg=Theme.SecondaryBackground, BgA=0, R=4, Border=true, BorderCol=Theme.BorderColor, Z=3, Par=secCon })
                if autoY then f.AutomaticSize = Enum.AutomaticSize.Y end
                return f
            end

            local function HoverEffect(f)
                f.MouseEnter:Connect(function() tw(f.UIStroke, { Color=Theme.ButtonHoverBackground }, TI_FAST) end)
                f.MouseLeave:Connect(function() tw(f.UIStroke, { Color=Theme.BorderColor },          TI_FAST) end)
            end

            -- ── Divider ──────────────────────────────────────────────────────
            function Sec:CreateDivider()
                local d = Wire(secCon, false)
                d.Size = UDim2.new(1, 0, 0, 1)
                return { Destroy=function() d:Destroy() end }
            end

            -- ── Label ────────────────────────────────────────────────────────
            function Sec:CreateLabel(lc)
                lc = merge({ Text="Label", Style=1 }, lc or {})
                local cMap = { [1]=Theme.TextSecondary, [2]=NotifColors.Info, [3]=NotifColors.Warning }
                local f  = Elem(28)
                local xo = lc.Style > 1 and 14 or 10
                if lc.Style > 1 then
                    Box({ Sz=UDim2.new(0,3,0.7,0), Pos=UDim2.new(0,0,0.15,0), Bg=cMap[lc.Style], R=0, Z=4, Par=f })
                end
                local lb = Txt({ T=lc.Text, Sz=UDim2.new(1,-xo-6,0,13), Pos=UDim2.new(0,xo,0.5,0), AP=Vector2.new(0,0.5), Font=Enum.Font.GothamSemibold, TS=12, Col=cMap[lc.Style], Z=4, Par=f })
                return {
                    Set     = function(self, t) lb.Text = t end,
                    Destroy = function() f:Destroy() end,
                }
            end

            -- ── Paragraph ────────────────────────────────────────────────────
            function Sec:CreateParagraph(pc)
                pc = merge({ Title="Title", Content="" }, pc or {})
                local f = Elem(0, true)
                Pad(f, 10, 10, 12, 12)
                List(f, 4)
                local pt    = Txt({ T=pc.Title,   Sz=UDim2.new(1,0,0,15), Font=Enum.Font.GothamBold, TS=13, Col=Theme.TextPrimary,   Z=4, Par=f })
                local pcont = Txt({ T=pc.Content, Sz=UDim2.new(1,0,0,0),  Font=Enum.Font.Gotham,     TS=12, Col=Theme.TextSecondary, Z=4, Wrap=true, AutoY=true, Par=f })
                return {
                    Set = function(self, s)
                        if s.Title   then pt.Text    = s.Title   end
                        if s.Content then pcont.Text = s.Content end
                    end,
                    Destroy = function() f:Destroy() end,
                }
            end

            -- ── Button ───────────────────────────────────────────────────────
            function Sec:CreateButton(bc)
                bc = merge({ Name="Button", Description=nil, Callback=function() end }, bc or {})
                local f = Elem(bc.Description and 52 or 36)
                f.ClipsDescendants = true

                local chargeFill = Box({ Sz=UDim2.new(0,0,1,0), Bg=Theme.ButtonHoverBackground, BgA=0, R=0, Z=3, Par=f })
                local pip        = Box({ Sz=UDim2.new(0,3,1,0), Pos=UDim2.new(0,0,0,0), Bg=Theme.AccentColor, BgA=1, R=0, Z=4, Par=f })

                Txt({ T=bc.Name, Sz=UDim2.new(1,-44,0,15), Pos=UDim2.new(0,14,0,bc.Description and 9 or 11), Font=Enum.Font.GothamSemibold, TS=13, Col=Theme.TextPrimary, Z=4, Par=f })
                if bc.Description then
                    Txt({ T=bc.Description, Sz=UDim2.new(1,-44,0,13), Pos=UDim2.new(0,14,0,28), Font=Enum.Font.Gotham, TS=11, Col=Theme.TextSecondary, Z=4, Par=f })
                end
                Img({ Ico="arr", Sz=UDim2.new(0,12,0,12), Pos=UDim2.new(1,-20,0.5,0), AP=Vector2.new(0,0.5), Col=Theme.AccentColor, IA=0.6, Z=5, Par=f })

                local cl = Btn(f, 6)
                f.MouseEnter:Connect(function()
                    tw(chargeFill, { Size=UDim2.new(1,0,1,0), BackgroundTransparency=0 }, TI(.3, Enum.EasingStyle.Quad))
                    tw(pip,        { BackgroundTransparency=0 },                           TI_FAST)
                    tw(f.UIStroke, { Color=Theme.AccentColor },                            TI_FAST)
                end)
                f.MouseLeave:Connect(function()
                    tw(chargeFill, { Size=UDim2.new(0,0,1,0), BackgroundTransparency=1 }, TI_MED)
                    tw(pip,        { BackgroundTransparency=1 },                           TI_FAST)
                    tw(f.UIStroke, { Color=Theme.BorderColor },                            TI_FAST)
                end)
                cl.MouseButton1Click:Connect(function()
                    tw(chargeFill, { BackgroundColor3=Theme.AccentColor }, TI_FAST)
                    task.wait(0.12)
                    tw(chargeFill, { BackgroundColor3=Theme.ButtonHoverBackground, Size=UDim2.new(0,0,1,0), BackgroundTransparency=1 }, TI_MED)
                    safe(bc.Callback)
                end)
                return { Destroy=function() f:Destroy() end }
            end

            -- ── Toggle ───────────────────────────────────────────────────────
            function Sec:CreateToggle(tc)
                tc = merge({ Name="Toggle", Description=nil, CurrentValue=false, Flag=nil, Callback=function() end }, tc or {})
                local f = Elem(tc.Description and 52 or 36)

                Txt({ T=tc.Name, Sz=UDim2.new(1,-66,0,15), Pos=UDim2.new(0,14,0,tc.Description and 9 or 11), Font=Enum.Font.GothamSemibold, TS=13, Col=Theme.TextPrimary, Z=4, Par=f })
                if tc.Description then
                    Txt({ T=tc.Description, Sz=UDim2.new(1,-66,0,13), Pos=UDim2.new(0,14,0,28), Font=Enum.Font.Gotham, TS=11, Col=Theme.TextSecondary, Z=4, Par=f })
                end

                local trk  = Box({ Sz=UDim2.new(0,40,0,20), Pos=UDim2.new(1,-52,0.5,0), AP=Vector2.new(0,0.5), Bg=Theme.TertiaryBackground, R=3, Border=true, BorderCol=Theme.BorderColor, Z=4, Par=f })
                local knob = Box({ Sz=UDim2.new(0,14,0,14), Pos=UDim2.new(0,3,0.5,0), AP=Vector2.new(0,0.5), Bg=Theme.TextSecondary, R=2, Z=5, Par=trk })

                local TV = { CurrentValue=tc.CurrentValue, Type="Toggle", Settings=tc }

                local function upd()
                    if TV.CurrentValue then
                        tw(trk,  { BackgroundColor3=Theme.ButtonHoverBackground }, TI_MED)
                        tw(trk.UIStroke, { Color=Theme.AccentColor },              TI_MED)
                        tw(knob, { Position=UDim2.new(0,23,0.5,0), BackgroundColor3=Theme.AccentColor }, TI_SPRING)
                    else
                        tw(trk,  { BackgroundColor3=Theme.TertiaryBackground }, TI_MED)
                        tw(trk.UIStroke, { Color=Theme.BorderColor },           TI_MED)
                        tw(knob, { Position=UDim2.new(0,3,0.5,0), BackgroundColor3=Theme.TextSecondary }, TI_SPRING)
                    end
                end

                upd()
                HoverEffect(f)
                Btn(f, 5).MouseButton1Click:Connect(function()
                    TV.CurrentValue = not TV.CurrentValue
                    upd()
                    safe(tc.Callback, TV.CurrentValue)
                end)
                function TV:Set(v) TV.CurrentValue = v; upd(); safe(tc.Callback, v) end
                if tc.Flag then Sentence.Flags[tc.Flag] = TV; Sentence.Options[tc.Flag] = TV end
                return TV
            end

            -- ── Slider ───────────────────────────────────────────────────────
            function Sec:CreateSlider(sc)
                sc = merge({ Name="Slider", Range={0,100}, Increment=1, CurrentValue=50, Suffix="", Flag=nil, Callback=function() end }, sc or {})
                local f = Elem(52)

                Txt({ T=sc.Name, Sz=UDim2.new(1,-100,0,15), Pos=UDim2.new(0,14,0,8), Font=Enum.Font.GothamSemibold, TS=13, Col=Theme.TextPrimary, Z=4, Par=f })

                local valChip = Box({ Sz=UDim2.new(0,0,0,18), Pos=UDim2.new(1,-12,0,6), AP=Vector2.new(1,0), Bg=Theme.TertiaryBackground, R=4, Z=4, Par=f })
                valChip.AutomaticSize = Enum.AutomaticSize.X
                Pad(valChip, 0, 0, 6, 6)
                local valL = Txt({ T=tostring(sc.CurrentValue)..sc.Suffix, Sz=UDim2.new(0,0,1,0), Font=Enum.Font.Code, TS=11, Col=Theme.AccentColor, AX=Enum.TextXAlignment.Center, Z=5, Par=valChip })
                valL.AutomaticSize = Enum.AutomaticSize.X

                local trackBg = Box({ Sz=UDim2.new(1,-28,0,4), Pos=UDim2.new(0,14,0,34), Bg=Theme.TertiaryBackground, R=2, Z=4, Par=f })
                local fillF   = Box({ Sz=UDim2.new(0,0,1,0), Bg=Theme.AccentColor, R=2, Z=5, Par=trackBg })
                local thumb   = Box({ Sz=UDim2.new(0,10,0,10), Pos=UDim2.new(0,0,0.5,0), AP=Vector2.new(0.5,0.5), Bg=Theme.TextPrimary, R=2, Z=6, Par=trackBg })

                local SV = { CurrentValue=sc.CurrentValue, Type="Slider", Settings=sc }
                local mn, mx, inc = sc.Range[1], sc.Range[2], sc.Increment

                local function setV(v)
                    v = math.clamp(v, mn, mx)
                    v = math.floor(v / inc + 0.5) * inc
                    v = tonumber(string.format("%.10g", v))
                    SV.CurrentValue = v
                    valL.Text       = tostring(v)..sc.Suffix
                    local pct       = (v - mn) / (mx - mn)
                    tw(fillF,  { Size=UDim2.new(pct,0,1,0) },       TI_FAST)
                    tw(thumb,  { Position=UDim2.new(pct,0,0.5,0) }, TI_FAST)
                end
                setV(sc.CurrentValue)

                local drag = false
                local bCL  = Btn(trackBg, 8)

                local function fromInp(i)
                    local rel = math.clamp((i.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1)
                    setV(mn + (mx - mn) * rel)
                    safe(sc.Callback, SV.CurrentValue)
                end

                bCL.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1
                    or i.UserInputType == Enum.UserInputType.Touch then
                        drag = true; fromInp(i)
                    end
                end)
                UIS.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1
                    or i.UserInputType == Enum.UserInputType.Touch then
                        drag = false
                    end
                end)
                track(UIS.InputChanged:Connect(function(i)
                    if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
                    or i.UserInputType == Enum.UserInputType.Touch) then
                        fromInp(i)
                    end
                end))

                HoverEffect(f)
                function SV:Set(v) setV(v); safe(sc.Callback, SV.CurrentValue) end
                if sc.Flag then Sentence.Flags[sc.Flag] = SV; Sentence.Options[sc.Flag] = SV end
                return SV
            end

            return Sec
        end

        -- Skróty bezpośrednio na Tab (bez jawnego CreateSection)
        local _ds
        local function gds()
            if not _ds then _ds = Tab:CreateSection("") end
            return _ds
        end
        for _, m in ipairs({ "CreateButton","CreateLabel","CreateParagraph","CreateToggle","CreateSlider","CreateDivider" }) do
            Tab[m] = function(self, ...) return gds()[m](gds(), ...) end
        end

        return Tab
    end

    -- ── Zapis / Wczytanie konfiguracji ────────────────────────────────────────
    function W:SaveConfiguration()
        -- Implementacja zapisu
    end
    function W:LoadConfiguration()
        -- Implementacja wczytywania
    end

    return W
end

-- ── Destroy ──────────────────────────────────────────────────────────────────
function Sentence:Destroy()
    for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
    self._conns = {}
    if self._notifHolder and self._notifHolder.Parent then
        self._notifHolder.Parent:Destroy()
    end
    self.Flags   = {}
    self.Options = {}
end

return Sentence

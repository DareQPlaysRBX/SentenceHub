--[[
╔══════════════════════════════════════════════════════════════════════╗
║  SENTENCE GUI  ·  v1.0.15                                              ║
║  Glassmorphism Executor Framework                                    ║
║  Professional · Animated · Modular                                  ║
╚══════════════════════════════════════════════════════════════════════╝
--]]

local Sentence = {
    Version = "1.0.15",
    Flags   = {},
    Options = {},
    _conns  = {},
    _notifHolder = nil,
}

-- ── Services ──────────────────────────────────────────────────────────────────
local TS   = game:GetService("TweenService")
local UIS  = game:GetService("UserInputService")
local RS   = game:GetService("RunService")
local Plrs = game:GetService("Players")
local CG   = game:GetService("CoreGui")
local LP   = Plrs.LocalPlayer
local Cam  = workspace.CurrentCamera
local IsStudio = RS:IsStudio()

-- ── Hex Helper ────────────────────────────────────────────────────────────────
local function H(hex)
    hex = hex:gsub("#","")
    return Color3.fromRGB(
        tonumber("0x"..hex:sub(1,2)),
        tonumber("0x"..hex:sub(3,4)),
        tonumber("0x"..hex:sub(5,6))
    )
end

-- ── Color Theme — OG Sentence ─────────────────────────────────────────────────
local T = {
    -- Backgrounds — Midnight Sentence (eye-friendly)
    BG0     = H("#151515"),  -- void
    BG1     = H("#0e0e0e"),  -- PrimaryBackground
    BG2     = H("#151515"),  -- SecondaryBackground
    BG3     = H("#1a1a1a"),  -- TertiaryBackground
    BG4     = H("#151515"),  -- ButtonNormalBackground

    -- Glass surfaces
    Glass   = H("#181818"),  -- glass tint
    GlassHi = H("#262626"),  -- glass hover

    -- Borders
    Border  = H("#2a2a2a"),  -- BorderColor
    BorderHi= H("#323232"),  -- aktywna krawędź
    BorderGl= H("#3a3a3a"),  -- krawędź szkła

    -- Midnight Blue
    Ice     = H("#4AABF5"),  -- główny akcent
    IceDim  = H("#3080D0"),  -- przyciemniony akcent
    IceLo   = H("#081828"),  -- ledwo widoczne tło akcentu
    IceGlow = H("#7DCAFF"),  -- glow / highlight

    -- Secondary
    Violet  = H("#909090"),  -- TextSecondary
    VioletDim=H("#606060"),  -- przyciemniony
    VioletLo= H("#111111"),  -- ciemne tło

    -- Tertiary
    Teal    = H("#C8C8C8"),  -- highlight
    TealDim = H("#A8A8A8"),  -- dim
    TealLo  = H("#111111"),  -- ciemne tło

    -- Status
    Success = H("#4ade80"),  -- zielony
    Warning = H("#fbbf24"),  -- bursztyn
    Error   = H("#f87171"),  -- czerwony

    -- Text
    TextHi  = H("#E8E8E8"),  -- primary
    TextMid = H("#909090"),  -- secondary
    TextLo  = H("#4a4a4a"),  -- disabled
    TextGhost=H("#282828"),  -- ledwo widoczny
}

-- ── Tween Helpers ─────────────────────────────────────────────────────────────
local function TI(t,s,d)
    return TweenInfo.new(t or .18, s or Enum.EasingStyle.Exponential, d or Enum.EasingDirection.Out)
end
local TI_SNAP    = TI(.08)
local TI_FAST    = TI(.14)
local TI_MED     = TI(.24)
local TI_SLOW    = TI(.44)
local TI_SPRING  = TweenInfo.new(.42, Enum.EasingStyle.Back,     Enum.EasingDirection.Out)
local TI_ELASTIC = TweenInfo.new(.52, Enum.EasingStyle.Elastic,  Enum.EasingDirection.Out)
local TI_CIRC    = TweenInfo.new(.28, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)
local TI_QUAD    = TweenInfo.new(.22, Enum.EasingStyle.Quad,     Enum.EasingDirection.Out)

local function tw(obj, props, info, cb)
    local t = TS:Create(obj, info or TI_MED, props)
    if cb then t.Completed:Once(cb) end
    t:Play(); return t
end

-- ── Utility ───────────────────────────────────────────────────────────────────
local function merge(defaults, overrides)
    overrides = overrides or {}
    for k,v in pairs(defaults) do
        if overrides[k] == nil then overrides[k] = v end
    end
    return overrides
end
local function track(c) table.insert(Sentence._conns, c); return c end
local function safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("[SENTENCE] " .. tostring(err)) end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- FONT SIZE CONFIGURATION
-- Zmień tutaj rozmiary czcionek dla całego GUI.
-- ══════════════════════════════════════════════════════════════════════════════
local FS = {
    -- ── Kontrolki (elementy w sekcjach) ───────────────────────────────────────
    ElemName    = 14,  -- nazwa kontrolki (Toggle, Button, Slider…)
    ElemDesc    = 12,  -- opis pod nazwą kontrolki
    ElemValue   = 12,  -- wartość (badge slidera, pole input, dropdown)
    ElemSection = 10,  -- nagłówek sekcji (np. "01 · COMBAT")

    -- ── Title bar (górny pasek okna) ──────────────────────────────────────────
    WinTitle    = 15,  -- główna nazwa okna (np. "SENTENCE")
    WinSubtitle = 13,  -- subtitle pod nazwą (np. "v4.0")

    -- ── Zakładki / sidebar ────────────────────────────────────────────────────
    TabHeader   = 14,  -- nagłówek zakładki (widoczny na stronie)
    Tooltip     = 12,  -- tooltip przy hover na ikonę zakładki

    -- ── Notyfikacje ───────────────────────────────────────────────────────────
    NotifType   = 10,  -- badge typu ("INFO", "SUCCESS"…)
    NotifTitle  = 14,  -- tytuł notyfikacji
    NotifBody   = 12,  -- treść notyfikacji

    -- ── Splash screen ─────────────────────────────────────────────────────────
    SplashTitle  = 38, -- litery tytułu na splash screen
    SplashStatus = 10, -- tekst statusu postępu ("loading modules…")

    -- ── Loading screen ────────────────────────────────────────────────────────
    LoadTitle    = 20, -- tytuł na ekranie ładowania
    LoadSubtitle = 12, -- podtytuł na ekranie ładowania
    LoadPercent  = 11, -- "0%" / "100%"

    -- ── Home tab — karta gracza i statystyki ──────────────────────────────────
    HomePlayerName = 15, -- DisplayName gracza
    HomePlayerUser = 11, -- @username
    HomeStatKey    =  9, -- etykieta statystyki ("PLAYERS", "PING"…)
    HomeStatVal    = 13, -- wartość statystyki
}
-- ══════════════════════════════════════════════════════════════════════════════

-- ── Icon Assets ───────────────────────────────────────────────────────────────
local ICONS = {
    close   = "rbxassetid://6031094678",
    minimize= "rbxassetid://6031094687",
    hide    = "rbxassetid://6031075929",
    home    = "rbxassetid://6031079158",
    info    = "rbxassetid://6026568227",
    warn    = "rbxassetid://6031071053",
    ok      = "rbxassetid://6031094667",
    arrow   = "rbxassetid://6031090995",
    unknown = "rbxassetid://6031079152",
    notif   = "rbxassetid://6034308946",
    chevD   = "rbxassetid://6031094687",
    chevU   = "rbxassetid://6031094679",
    settings= "rbxassetid://6031079152",
    search  = "rbxassetid://6031079152",
    key     = "rbxassetid://6026568227",
}
local LOGO_ID = "rbxassetid://117810891565979"

local function resolveIcon(n)
    if not n or n == "" then return "" end
    if n:find("rbxassetid") then return n end
    if tonumber(n) then return "rbxassetid://"..n end
    return ICONS[n] or ICONS.unknown
end

-- ══════════════════════════════════════════════════════════════════════════════
-- PRIMITIVE CONSTRUCTORS
-- ══════════════════════════════════════════════════════════════════════════════

local function newFrame(p)
    p = p or {}
    local f = Instance.new("Frame")
    f.Name               = p.Name or "Frame"
    f.Size               = p.Size or UDim2.new(1,0,0,32)
    f.Position           = p.Position or UDim2.new()
    f.AnchorPoint        = p.AnchorPoint or Vector2.zero
    f.BackgroundColor3   = p.Color or T.BG2
    f.BackgroundTransparency = p.Alpha ~= nil and p.Alpha or 0
    f.BorderSizePixel    = 0
    f.ZIndex             = p.Z or 1
    f.LayoutOrder        = p.Order or 0
    f.Visible            = p.Visible ~= false
    if p.Clip  then f.ClipsDescendants = true end
    if p.AutoY then f.AutomaticSize = Enum.AutomaticSize.Y end
    if p.AutoX then f.AutomaticSize = Enum.AutomaticSize.X end
    if p.AutoXY then f.AutomaticSize = Enum.AutomaticSize.XY end
    if p.Radius ~= nil then
        local uc = Instance.new("UICorner")
        uc.CornerRadius = type(p.Radius)=="number" and UDim.new(0,p.Radius) or p.Radius
        uc.Parent = f
    end
    if p.Parent then f.Parent = p.Parent end
    return f
end

local function newText(p)
    p = p or {}
    local l = Instance.new("TextLabel")
    l.Name              = p.Name or "Label"
    l.Text              = p.Text or ""
    l.Size              = p.Size or UDim2.new(1,0,0,14)
    l.Position          = p.Position or UDim2.new()
    l.AnchorPoint       = p.AnchorPoint or Vector2.zero
    l.Font              = p.Font or Enum.Font.GothamSemibold
    l.TextSize          = p.TextSize or 13
    l.TextColor3        = p.Color or T.TextHi
    l.TextTransparency  = p.Alpha or 0
    l.TextXAlignment    = p.AlignX or Enum.TextXAlignment.Left
    l.TextYAlignment    = p.AlignY or Enum.TextYAlignment.Center
    l.TextWrapped       = p.Wrap or false
    l.RichText          = false
    l.BackgroundTransparency = 1
    l.BorderSizePixel   = 0
    l.ZIndex            = p.Z or 2
    l.LayoutOrder       = p.Order or 0
    if p.AutoY  then l.AutomaticSize = Enum.AutomaticSize.Y end
    if p.AutoX  then l.AutomaticSize = Enum.AutomaticSize.X end
    if p.AutoXY then l.AutomaticSize = Enum.AutomaticSize.XY end
    if p.Parent then l.Parent = p.Parent end
    return l
end

local function newImage(p)
    p = p or {}
    local i = Instance.new("ImageLabel")
    i.Name              = p.Name or "Image"
    i.Image             = resolveIcon(p.Icon or "")
    i.Size              = p.Size or UDim2.new(0,16,0,16)
    i.Position          = p.Position or UDim2.new(0.5,0,0.5,0)
    i.AnchorPoint       = p.AnchorPoint or Vector2.new(0.5,0.5)
    i.ImageColor3       = p.Color or T.TextHi
    i.ImageTransparency = p.Alpha or 0
    i.BackgroundTransparency = 1
    i.BorderSizePixel   = 0
    i.ZIndex            = p.Z or 3
    i.ScaleType         = Enum.ScaleType.Fit
    if p.Parent then i.Parent = p.Parent end
    return i
end

local function newButton(parent, zindex)
    local b = Instance.new("TextButton")
    b.Name   = "ClickLayer"
    b.Size   = UDim2.new(1,0,1,0)
    b.BackgroundTransparency = 1
    b.Text   = ""
    b.ZIndex = zindex or 9
    b.Parent = parent
    return b
end

local function newLayout(parent, gap, direction, halign, valign)
    local l = Instance.new("UIListLayout")
    l.SortOrder     = Enum.SortOrder.LayoutOrder
    l.Padding       = UDim.new(0, gap or 4)
    l.FillDirection = direction or Enum.FillDirection.Vertical
    if halign then l.HorizontalAlignment = halign end
    if valign then l.VerticalAlignment   = valign end
    l.Parent = parent
    return l
end

local function newPadding(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top    or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft   = UDim.new(0, left   or 0)
    p.PaddingRight  = UDim.new(0, right  or 0)
    p.Parent = parent
    return p
end

local function newStroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color           = color or T.Border
    s.Thickness       = thickness or 1
    s.Transparency    = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function newGradient(parent, colorSeq, transparencySeq, rotation)
    local g = Instance.new("UIGradient")
    if colorSeq then g.Color        = colorSeq end
    if transparencySeq then g.Transparency = transparencySeq end
    g.Rotation = rotation or 0
    g.Parent   = parent
    return g
end

-- ── Glass Card Helper ─────────────────────────────────────────────────────────
-- Creates the layered frosted glass look: base + shimmer overlay + border
local function glassCard(parent, size, pos, anchorPoint, radius, zindex)
    local card = newFrame({
        Size        = size or UDim2.new(1,0,0,36),
        Position    = pos  or UDim2.new(),
        AnchorPoint = anchorPoint or Vector2.zero,
        Color       = T.Glass,
        Alpha       = 0.70,  -- semi-transparent glass
        Radius      = radius or 6,
        Z           = zindex or 2,
        Parent      = parent,
    })

    -- Shimmer layer (top-to-bottom gradient gives "glass" depth feel)
    local shimmer = newFrame({
        Size   = UDim2.new(1,0,1,0),
        Color  = T.TextHi,
        Alpha  = 1,
        Radius = radius or 6,
        Z      = zindex and zindex+1 or 3,
        Parent = card,
    })
    newGradient(shimmer,
        nil,
        NumberSequence.new{
            NumberSequenceKeypoint.new(0,   0.92),
            NumberSequenceKeypoint.new(0.4, 0.96),
            NumberSequenceKeypoint.new(1,   1.00),
        },
        90
    )

    -- Frosted border
    newStroke(card, T.BorderGl, 1, 0.72)

    return card
end

-- ── Draggable ─────────────────────────────────────────────────────────────────
local function makeDraggable(handle, window)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
           inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = inp.Position
            startPos  = window.Position
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and (
            inp.UserInputType == Enum.UserInputType.MouseMovement or
            inp.UserInputType == Enum.UserInputType.Touch) then
            local delta = inp.Position - dragStart
            TS:Create(window, TweenInfo.new(0.05, Enum.EasingStyle.Sine), {
                Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            }):Play()
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
           inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- SECTION / ELEMENT BUILDER
-- Attached to any ScrollingFrame page to produce a full element API.
-- ══════════════════════════════════════════════════════════════════════════════
local function buildSectionAPI(page, accent, secondary)
    accent    = accent    or T.Ice
    secondary = secondary or T.Violet
    local sectionCount = 0
    local API = {}

    -- ── Base element frame ────────────────────────────────────────────────────
    -- Each control lives in a glass card with left accent strip and hover effect
    local function makeElemFrame(container, height, autoY)
        -- Outer glass card
        local card = newFrame({
            Size   = UDim2.new(1,0,0, height or 40),
            Color  = T.Glass,
            Alpha  = 0.68,
            Radius = 6,
            Z      = 3,
            Parent = container,
        })
        if autoY then card.AutomaticSize = Enum.AutomaticSize.Y end

        -- Inner shimmer (glass depth)
        local shimmer = newFrame({
            Size   = UDim2.new(1,0,1,0),
            Color  = T.TextHi,
            Alpha  = 1,
            Radius = 6,
            Z      = 3,
            Parent = card,
        })
        newGradient(shimmer, nil,
            NumberSequence.new{
                NumberSequenceKeypoint.new(0,   0.94),
                NumberSequenceKeypoint.new(0.5, 0.97),
                NumberSequenceKeypoint.new(1,   1.00),
            }, 90)

        -- Left accent strip
        local strip = newFrame({
            Size   = UDim2.new(0,2,0.55,0),
            Position=UDim2.new(0,0,0.225,0),
            Color  = accent,
            Alpha  = 0.55,
            Radius = 1,
            Z      = 5,
            Parent = card,
        })

        -- Glass border
        local stroke = newStroke(card, T.BorderGl, 1, 0.78)

        return card, strip, stroke
    end

    -- ── Hover animation ───────────────────────────────────────────────────────
    local function addHover(card, strip, stroke)
        card.MouseEnter:Connect(function()
            tw(card,   {BackgroundColor3=T.GlassHi, BackgroundTransparency=0.58}, TI_FAST)
            tw(strip,  {BackgroundTransparency=0.15, BackgroundColor3=accent},    TI_FAST)
            tw(stroke, {Transparency=0.48, Color=accent},                         TI_FAST)
        end)
        card.MouseLeave:Connect(function()
            tw(card,   {BackgroundColor3=T.Glass,   BackgroundTransparency=0.68}, TI_FAST)
            tw(strip,  {BackgroundTransparency=0.55, BackgroundColor3=accent},    TI_FAST)
            tw(stroke, {Transparency=0.78, Color=T.BorderGl},                    TI_FAST)
        end)
    end

    -- ── CreateSection ─────────────────────────────────────────────────────────
    function API:CreateSection(name)
        name = name or ""
        sectionCount = sectionCount + 1
        local Sec = {}

        -- Section header
        if name ~= "" then
            local header = newFrame({
                Size   = UDim2.new(1,0,0,20),
                Color  = T.BG0,
                Alpha  = 1,
                Z      = 3,
                Parent = page,
            })

            -- Gradient line behind text
            local line = newFrame({
                Size     = UDim2.new(1,0,0,1),
                Position = UDim2.new(0,0,0.5,0),
                Color    = T.Border,
                Alpha    = 0,
                Z        = 3,
                Parent   = header,
            })
            newGradient(line,
                ColorSequence.new{
                    ColorSequenceKeypoint.new(0,   accent),
                    ColorSequenceKeypoint.new(0.3, secondary),
                    ColorSequenceKeypoint.new(1,   T.Border),
                }, nil, 0)

            -- Section label pill
            local pill = newFrame({
                Size      = UDim2.new(0,0,1,0),
                Position  = UDim2.new(0,0,0,0),
                Color     = T.BG1,
                Alpha     = 0,
                Radius    = 3,
                Z         = 4,
                AutoX     = true,
                Parent    = header,
            })
            newPadding(pill, 0,0,0,8)

            local pillRow = newFrame({
                Size   = UDim2.new(0,0,1,0),
                Color  = T.BG0,
                Alpha  = 1,
                Z      = 5,
                AutoX  = true,
                Parent = pill,
            })
            newLayout(pillRow, 4, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)

            -- Dot accent
            newText({
                Text     = "·",
                Size     = UDim2.new(0,0,1,0),
                Font     = Enum.Font.GothamBold,
                TextSize = FS.ElemSection + 4,
                Color    = accent,
                AutoX    = true,
                Z        = 6,
                Parent   = pillRow,
            })

            newText({
                Text     = " "..name:upper(),
                Size     = UDim2.new(0,0,1,0),
                Font     = Enum.Font.GothamBold,
                TextSize = FS.ElemSection,
                Color    = T.TextMid,
                AutoX    = true,
                Z        = 6,
                Parent   = pillRow,
            })
        end

        -- Element container
        local container = newFrame({
            Size   = UDim2.new(1,0,0,0),
            Color  = T.BG0,
            Alpha  = 1,
            Z      = 3,
            AutoY  = true,
            Parent = page,
        })
        newLayout(container, 4)

        -- ── Divider ───────────────────────────────────────────────────────────
        function Sec:CreateDivider()
            local d = newFrame({
                Size   = UDim2.new(1,0,0,1),
                Color  = T.Border,
                Alpha  = 0,
                Z      = 3,
                Parent = container,
            })
            newGradient(d,
                ColorSequence.new{
                    ColorSequenceKeypoint.new(0,   accent),
                    ColorSequenceKeypoint.new(0.5, secondary),
                    ColorSequenceKeypoint.new(1,   T.BG1),
                })
            return {Destroy=function() d:Destroy() end}
        end

        -- ── Label ─────────────────────────────────────────────────────────────
        function Sec:CreateLabel(cfg)
            cfg = merge({Text="", Style=1}, cfg or {})
            local text = cfg.Text ~= "" and cfg.Text or (cfg.Name or "")
            local colors = {T.TextMid, accent, T.Warning}
            local col = colors[cfg.Style] or T.TextMid

            local card, strip, stroke = makeElemFrame(container, 34)
            if cfg.Style > 1 then
                strip.BackgroundTransparency = 0
                strip.BackgroundColor3       = col
            end
            local lbl = newText({
                Text     = text,
                Size     = UDim2.new(1,-24,0,14),
                Position = UDim2.new(0,14,0.5,0),
                AnchorPoint=Vector2.new(0,0.5),
                Font     = Enum.Font.GothamSemibold,
                TextSize = FS.ElemName,
                Color    = col,
                Z        = 5,
                Parent   = card,
            })
            return {
                Set     = function(_, t) lbl.Text = t end,
                Destroy = function() card:Destroy() end,
            }
        end

        -- ── Paragraph ─────────────────────────────────────────────────────────
        function Sec:CreateParagraph(cfg)
            cfg = merge({Title="", Content=""}, cfg or {})
            local card, strip, stroke = makeElemFrame(container, 0, true)
            newPadding(card, 12,12,14,14)
            newLayout(card, 5)
            strip.BackgroundTransparency = 0

            local title = newText({
                Text     = cfg.Title,
                Size     = UDim2.new(1,0,0,17),
                Font     = Enum.Font.GothamBold,
                TextSize = FS.ElemName,
                Color    = T.TextHi,
                Z        = 5,
                Parent   = card,
            })
            local body = newText({
                Text     = cfg.Content,
                Size     = UDim2.new(1,0,0,0),
                Font     = Enum.Font.Gotham,
                TextSize = FS.ElemDesc,
                Color    = T.TextMid,
                Wrap     = true,
                AutoY    = true,
                Z        = 5,
                Parent   = card,
            })
            return {
                Set     = function(_,s)
                    if s.Title   then title.Text = s.Title   end
                    if s.Content then body.Text  = s.Content end
                end,
                Destroy = function() card:Destroy() end,
            }
        end

        -- ── Button ────────────────────────────────────────────────────────────
        function Sec:CreateButton(cfg)
            cfg = merge({
                Name="Button", Description=nil,
                Callback=function()end
            }, cfg or {})

            local h = cfg.Description and 58 or 40
            local card, strip, stroke = makeElemFrame(container, h)
            card.ClipsDescendants = true

            -- Hover fill sweep (slides in from left on hover)
            local sweep = newFrame({
                Size   = UDim2.new(0,0,1,0),
                Color  = accent,
                Alpha  = 1,
                Radius = 6,
                Z      = 3,
                Parent = card,
            })
            newGradient(sweep, nil,
                NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 0.78),
                    NumberSequenceKeypoint.new(1, 1.00),
                })

            -- Always-visible strip
            strip.BackgroundTransparency = 0

            -- Labels
            newText({
                Text     = cfg.Name,
                Size     = UDim2.new(1,-48,0,15),
                Position = UDim2.new(0,14,0, cfg.Description and 9 or 11),
                Font     = Enum.Font.GothamBold,
                TextSize = FS.ElemName,
                Color    = T.TextHi,
                Z        = 6,
                Parent   = card,
            })
            if cfg.Description then
                newText({
                    Text     = cfg.Description,
                    Size     = UDim2.new(1,-48,0,13),
                    Position = UDim2.new(0,14,0,28),
                    Font     = Enum.Font.Gotham,
                    TextSize = FS.ElemDesc,
                    Color    = T.TextMid,
                    Z        = 6,
                    Parent   = card,
                })
            end

            -- Arrow
            local arrow = newImage({
                Icon     = "arrow",
                Size     = UDim2.new(0,10,0,10),
                Position = UDim2.new(1,-14,0.5,0),
                AnchorPoint=Vector2.new(0,0.5),
                Color    = accent,
                Alpha    = 0.6,
                Z        = 6,
                Parent   = card,
            })

            local cl = newButton(card, 8)

            card.MouseEnter:Connect(function()
                tw(sweep,  {Size=UDim2.new(1,0,1,0)},                          TI(.22, Enum.EasingStyle.Quad))
                tw(strip,  {BackgroundColor3=secondary},                        TI_FAST)
                tw(arrow,  {ImageTransparency=0, ImageColor3=T.TextHi},         TI_FAST)
                tw(stroke, {Transparency=0.28, Color=accent},                   TI_FAST)
            end)
            card.MouseLeave:Connect(function()
                tw(sweep,  {Size=UDim2.new(0,0,1,0)},                          TI_MED)
                tw(strip,  {BackgroundColor3=accent},                           TI_FAST)
                tw(arrow,  {ImageTransparency=0.6, ImageColor3=accent},         TI_FAST)
                tw(stroke, {Transparency=0.78, Color=T.BorderGl},              TI_FAST)
            end)
            cl.MouseButton1Click:Connect(function()
                -- Click ripple flash
                tw(sweep, {BackgroundColor3=T.IceGlow}, TI(.05, Enum.EasingStyle.Quad))
                task.wait(0.07)
                tw(sweep, {BackgroundColor3=accent, Size=UDim2.new(0,0,1,0)}, TI_MED)
                safe(cfg.Callback)
            end)

            return {Destroy=function() card:Destroy() end}
        end

        -- ── Toggle ────────────────────────────────────────────────────────────
        function Sec:CreateToggle(cfg)
            cfg = merge({
                Name="Toggle", Description=nil,
                CurrentValue=false, Flag=nil,
                Callback=function()end
            }, cfg or {})

            local h = cfg.Description and 58 or 40
            local card, strip, stroke = makeElemFrame(container, h)

            newText({
                Text     = cfg.Name,
                Size     = UDim2.new(1,-70,0,15),
                Position = UDim2.new(0,14,0, cfg.Description and 9 or 11),
                Font     = Enum.Font.GothamBold,
                TextSize = FS.ElemName,
                Color    = T.TextHi,
                Z        = 5,
                Parent   = card,
            })
            if cfg.Description then
                newText({
                    Text     = cfg.Description,
                    Size     = UDim2.new(1,-70,0,13),
                    Position = UDim2.new(0,14,0,28),
                    Font     = Enum.Font.Gotham,
                    TextSize = FS.ElemDesc,
                    Color    = T.TextMid,
                    Z        = 5,
                    Parent   = card,
                })
            end

            -- Track pill (glass style)
            local track = newFrame({
                Size     = UDim2.new(0,42,0,22),
                Position = UDim2.new(1,-56,0.5,0),
                AnchorPoint=Vector2.new(0,0.5),
                Color    = T.BG3,
                Alpha    = 0,
                Radius   = 10,
                Z        = 5,
                Parent   = card,
            })
            local trackStroke = newStroke(track, T.Border, 1, 0.4)

            -- Track tint (shows when ON)
            local tint = newFrame({
                Size   = UDim2.new(1,0,1,0),
                Color  = accent,
                Alpha  = 1,
                Radius = 10,
                Z      = 5,
                Parent = track,
            })
            newGradient(tint, nil,
                NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 0.82),
                    NumberSequenceKeypoint.new(1, 1.00),
                })

            -- Knob (glass pill)
            local knob = newFrame({
                Size      = UDim2.new(0,16,0,16),
                Position  = UDim2.new(0,3,0.5,0),
                AnchorPoint=Vector2.new(0,0.5),
                Color     = T.TextMid,
                Alpha     = 0,
                Radius    = 8,
                Z         = 6,
                Parent    = track,
            })
            local knobStroke = newStroke(knob, T.Border, 1, 0.3)

            local TV = {CurrentValue=cfg.CurrentValue, Type="Toggle", Settings=cfg}

            local function refresh(animate)
                animate = animate ~= false  -- domyślnie true, przy init = false
                local ti = animate and TI_MED or TI(.001)
                local tf = animate and TI_FAST or TI(.001)
                local te = animate and TI_ELASTIC or TI(.001)
                if TV.CurrentValue then
                    tw(track,      {BackgroundColor3=T.IceLo,  BackgroundTransparency=0},   ti)
                    tw(trackStroke,{Color=accent, Transparency=0.2},                         ti)
                    tw(tint,       {BackgroundTransparency=0.75},                            ti)
                    tw(knob,       {Position=UDim2.new(1,-19,0.5,0), BackgroundColor3=accent,BackgroundTransparency=0}, te)
                    tw(knobStroke, {Color=accent, Transparency=0.0},                        tf)
                    tw(strip,      {BackgroundColor3=accent, BackgroundTransparency=0},      tf)
                    tw(stroke,     {Transparency=0.35, Color=accent},                       tf)

                    -- Pulse tylko przy kliknięciu, nie przy init
                    if animate then
                        task.spawn(function()
                            tw(knob,{Size=UDim2.new(0,20,0,20)},TI(.12,Enum.EasingStyle.Back))
                            task.wait(0.13)
                            tw(knob,{Size=UDim2.new(0,16,0,16)},TI_FAST)
                        end)
                    end
                else
                    tw(track,      {BackgroundColor3=T.BG3, BackgroundTransparency=0},       ti)
                    tw(trackStroke,{Color=T.Border, Transparency=0.4},                       ti)
                    tw(tint,       {BackgroundTransparency=1},                               ti)
                    tw(knob,       {Position=UDim2.new(0,3,0.5,0), BackgroundColor3=T.TextMid,BackgroundTransparency=0}, te)
                    tw(knobStroke, {Color=T.Border, Transparency=0.3},                      tf)
                    tw(strip,      {BackgroundTransparency=0.55},                           tf)
                    tw(stroke,     {Transparency=0.78, Color=T.BorderGl},                  tf)
                end
            end

            refresh(false)  -- stan początkowy bez animacji
            addHover(card, strip, stroke)
            newButton(card, 7).MouseButton1Click:Connect(function()
                TV.CurrentValue = not TV.CurrentValue
                refresh(true)  -- kliknięcie — z animacją
                safe(cfg.Callback, TV.CurrentValue)
            end)

            function TV:Set(v)
                TV.CurrentValue = v; refresh(true); safe(cfg.Callback, v)
            end
            if cfg.Flag then Sentence.Flags[cfg.Flag]=TV; Sentence.Options[cfg.Flag]=TV end
            return TV
        end

        -- ── Slider ────────────────────────────────────────────────────────────
        function Sec:CreateSlider(cfg)
            cfg = merge({
                Name="Slider", Range={0,100}, Increment=1,
                CurrentValue=50, Suffix="", Flag=nil,
                Callback=function()end
            }, cfg or {})

            local card, strip, stroke = makeElemFrame(container, 56)
            strip.BackgroundTransparency = 0

            newText({
                Text     = cfg.Name,
                Size     = UDim2.new(1,-96,0,15),
                Position = UDim2.new(0,14,0,7),
                Font     = Enum.Font.GothamBold,
                TextSize = FS.ElemName,
                Color    = T.TextHi,
                Z        = 5,
                Parent   = card,
            })

            -- Value badge (frosted pill)
            local badge = newFrame({
                Size      = UDim2.new(0,0,0,17),
                Position  = UDim2.new(1,-12,0,7),
                AnchorPoint=Vector2.new(1,0),
                Color     = T.IceLo,
                Alpha     = 0,
                Radius    = 4,
                Z         = 5,
                AutoX     = true,
                Parent    = card,
            })
            newPadding(badge, 0,0,6,6)
            newStroke(badge, accent, 1, 0.55)
            local valLabel = newText({
                Text     = tostring(cfg.CurrentValue)..cfg.Suffix,
                Size     = UDim2.new(0,0,1,0),
                Font     = Enum.Font.Code,
                TextSize = FS.ElemValue,
                Color    = accent,
                AlignX   = Enum.TextXAlignment.Center,
                AutoX    = true,
                Z        = 6,
                Parent   = badge,
            })

            -- Rail
            local rail = newFrame({
                Size     = UDim2.new(1,-28,0,4),
                Position = UDim2.new(0,14,0,38),
                Color    = T.BG3,
                Alpha    = 0,
                Radius   = 2,
                Z        = 5,
                Parent   = card,
            })
            newStroke(rail, T.Border, 1, 0.55)

            -- Fill (gradient ice→violet)
            local fill = newFrame({
                Size   = UDim2.new(0,0,1,0),
                Color  = accent,
                Alpha  = 0,
                Radius = 2,
                Z      = 6,
                Parent = rail,
            })
            newGradient(fill, ColorSequence.new{
                ColorSequenceKeypoint.new(0,   accent),
                ColorSequenceKeypoint.new(1,   secondary),
            })

            -- Thumb (circle with glow ring)
            local thumb = newFrame({
                Size      = UDim2.new(0,11,0,11),
                Position  = UDim2.new(0,0,0.5,0),
                AnchorPoint=Vector2.new(0.5,0.5),
                Color     = T.TextHi,
                Alpha     = 0,
                Radius    = 6,
                Z         = 7,
                Parent    = rail,
            })
            local thumbGlow = newStroke(thumb, accent, 2, 0.4)

            -- Floating value bubble (appears while dragging)
            local bubble = newFrame({
                Size      = UDim2.new(0,0,0,18),
                Position  = UDim2.new(0,0,-1,0),
                AnchorPoint=Vector2.new(0.5,1),
                Color     = T.BG3,
                Alpha     = 1,
                Radius    = 4,
                Z         = 9,
                AutoX     = true,
                Visible   = false,
                Parent    = rail,
            })
            newPadding(bubble, 0,0,5,5)
            newStroke(bubble, accent, 1, 0.4)
            local bubbleLabel = newText({
                Text     = "",
                Size     = UDim2.new(0,0,1,0),
                Font     = Enum.Font.Code,
                TextSize = FS.ElemValue,
                Color    = T.TextHi,
                AlignX   = Enum.TextXAlignment.Center,
                AutoX    = true,
                Z        = 10,
                Parent   = bubble,
            })

            local SV = {CurrentValue=cfg.CurrentValue, Type="Slider", Settings=cfg}
            local mn, mx, inc = cfg.Range[1], cfg.Range[2], cfg.Increment

            local function setValue(v)
                v = math.clamp(v, mn, mx)
                v = math.floor(v / inc + 0.5) * inc
                v = tonumber(string.format("%.10g", v))
                SV.CurrentValue = v

                local pct = (v - mn) / (mx - mn)
                valLabel.Text   = tostring(v)..cfg.Suffix
                bubbleLabel.Text= tostring(v)..cfg.Suffix

                tw(fill,  {Size=UDim2.new(pct,0,1,0)},       TI_FAST)
                tw(thumb, {Position=UDim2.new(pct,0,0.5,0)}, TI_FAST)
                bubble.Position = UDim2.new(pct,0,-0.8,0)
            end
            setValue(cfg.CurrentValue)

            local dragging = false
            local railBtn  = newButton(rail, 9)

            local function fromInput(inp)
                local rel = math.clamp(
                    (inp.Position.X - rail.AbsolutePosition.X) / rail.AbsoluteSize.X,
                    0, 1
                )
                setValue(mn + (mx - mn) * rel)
                safe(cfg.Callback, SV.CurrentValue)
            end

            railBtn.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or
                   inp.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    fromInput(inp)
                    bubble.Visible = true
                    tw(thumb,     {Size=UDim2.new(0,15,0,15)},              TI_CIRC)
                    tw(thumbGlow, {Color=secondary, Transparency=0.1},      TI_FAST)
                    tw(fill,      {BackgroundColor3=secondary},              TI_FAST)
                end
            end)
            track(UIS.InputChanged:Connect(function(inp)
                if dragging and (
                    inp.UserInputType == Enum.UserInputType.MouseMovement or
                    inp.UserInputType == Enum.UserInputType.Touch) then
                    fromInput(inp)
                end
            end))
            track(UIS.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or
                   inp.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                    bubble.Visible = false
                    tw(thumb,     {Size=UDim2.new(0,11,0,11)},              TI_CIRC)
                    tw(thumbGlow, {Color=accent, Transparency=0.4},         TI_FAST)
                    tw(fill,      {BackgroundColor3=accent},                TI_FAST)
                end
            end))

            addHover(card, strip, stroke)

            function SV:Set(v) setValue(v); safe(cfg.Callback, SV.CurrentValue) end
            if cfg.Flag then Sentence.Flags[cfg.Flag]=SV; Sentence.Options[cfg.Flag]=SV end
            return SV
        end

        -- ── ColorPicker ───────────────────────────────────────────────────────
        function Sec:CreateColorPicker(cfg)
            cfg = merge({
                Name="Color", Color=Color3.new(1,1,1),
                Flag=nil, Callback=function()end
            }, cfg or {})

            local card, strip, stroke = makeElemFrame(container, 34)
            newText({
                Text     = cfg.Name,
                Size     = UDim2.new(1,-56,0,14),
                Position = UDim2.new(0,12,0.5,0),
                AnchorPoint=Vector2.new(0,0.5),
                Font     = Enum.Font.GothamBold,
                TextSize = 13,
                Color    = T.TextHi,
                Z        = 5,
                Parent   = card,
            })

            local swatch = newFrame({
                Size      = UDim2.new(0,22,0,22),
                Position  = UDim2.new(1,-36,0.5,0),
                AnchorPoint=Vector2.new(0,0.5),
                Color     = cfg.Color,
                Alpha     = 0,
                Radius    = 5,
                Z         = 5,
                Parent    = card,
            })
            newStroke(swatch, T.BorderGl, 1, 0.45)

            addHover(card, strip, stroke)
            local CV = {CurrentValue=cfg.Color, Type="ColorPicker", Settings=cfg}
            function CV:Set(c)
                CV.CurrentValue = c
                swatch.BackgroundColor3 = c
                safe(cfg.Callback, c)
            end
            if cfg.Flag then Sentence.Flags[cfg.Flag]=CV; Sentence.Options[cfg.Flag]=CV end
            return CV
        end

        -- ── Keybind ───────────────────────────────────────────────────────────
        function Sec:CreateBind(cfg)
            cfg = merge({
                Name="Keybind", Description=nil,
                CurrentBind="E", HoldToInteract=false,
                Flag=nil,
                Callback=function()end,
                OnChangedCallback=function()end,
            }, cfg or {})

            local h = cfg.Description and 58 or 40
            local card, strip, stroke = makeElemFrame(container, h)

            newText({
                Text     = cfg.Name,
                Size     = UDim2.new(1,-114,0,15),
                Position = UDim2.new(0,14,0, cfg.Description and 9 or 11),
                Font     = Enum.Font.GothamBold,
                TextSize = FS.ElemName,
                Color    = T.TextHi,
                Z        = 5,
                Parent   = card,
            })
            if cfg.Description then
                newText({
                    Text     = cfg.Description,
                    Size     = UDim2.new(1,-114,0,13),
                    Position = UDim2.new(0,14,0,28),
                    Font     = Enum.Font.Gotham,
                    TextSize = FS.ElemDesc,
                    Color    = T.TextMid,
                    Z        = 5,
                    Parent   = card,
                })
            end

            -- Key badge (glass keyboard key look)
            local keyPill = newFrame({
                Size      = UDim2.new(0,0,0,24),
                Position  = UDim2.new(1,-12,0.5,0),
                AnchorPoint=Vector2.new(1,0.5),
                Color     = T.BG3,
                Alpha     = 0,
                Radius    = 5,
                Z         = 5,
                AutoX     = true,
                Parent    = card,
            })
            newPadding(keyPill, 0,0,10,10)
            local keyStroke = newStroke(keyPill, T.BorderGl, 1, 0.45)

            -- Inset shadow top (keyboard depth)
            newFrame({
                Size   = UDim2.new(1,0,0,2),
                Color  = T.BG0,
                Alpha  = 0.55,
                Z      = 6,
                Parent = keyPill,
            })

            local keyLabel = newText({
                Text     = cfg.CurrentBind,
                Size     = UDim2.new(0,0,1,0),
                Font     = Enum.Font.Code,
                TextSize = FS.ElemValue,
                Color    = accent,
                AlignX   = Enum.TextXAlignment.Center,
                AutoX    = true,
                Z        = 7,
                Parent   = keyPill,
            })

            -- HOLD badge
            if cfg.HoldToInteract then
                local hBadge = newFrame({
                    Size      = UDim2.new(0,0,0,10),
                    Position  = UDim2.new(1,-12,1,-2),
                    AnchorPoint=Vector2.new(1,1),
                    Color     = T.IceLo,
                    Alpha     = 0,
                    Radius    = 2,
                    Z         = 6,
                    AutoX     = true,
                    Parent    = card,
                })
                newPadding(hBadge, 0,0,3,3)
                newStroke(hBadge, accent, 1, 0.55)
                newText({
                    Text     = "HOLD",
                    Size     = UDim2.new(0,0,1,0),
                    Font     = Enum.Font.GothamBold,
                    TextSize = 8,
                    Color    = accent,
                    AlignX   = Enum.TextXAlignment.Center,
                    AutoX    = true,
                    Z        = 7,
                    Parent   = hBadge,
                })
            end

            local BV = {CurrentBind=cfg.CurrentBind, Type="Bind", Settings=cfg}
            local listening = false
            local holdActive = false

            local function setListening(v)
                listening = v
                if v then
                    tw(keyPill,   {BackgroundColor3=T.IceLo, BackgroundTransparency=0}, TI_FAST)
                    tw(keyStroke, {Color=accent, Transparency=0.1},                      TI_FAST)
                    keyLabel.Text = "···"
                    tw(keyLabel,  {TextColor3=secondary},                                TI_FAST)
                else
                    tw(keyPill,   {BackgroundColor3=T.BG3, BackgroundTransparency=0},    TI_FAST)
                    tw(keyStroke, {Color=T.BorderGl, Transparency=0.45},                TI_FAST)
                    keyLabel.Text = BV.CurrentBind
                    tw(keyLabel,  {TextColor3=accent},                                  TI_FAST)
                end
            end

            local pillBtn = newButton(keyPill, 8)
            pillBtn.MouseButton1Click:Connect(function()
                if listening then setListening(false); return end
                setListening(true)
            end)

            track(UIS.InputBegan:Connect(function(inp, processed)
                if listening then
                    if inp.UserInputType == Enum.UserInputType.Keyboard then
                        local name = inp.KeyCode.Name
                        if name == "Escape" then setListening(false); return end
                        BV.CurrentBind = name
                        setListening(false)
                        safe(cfg.OnChangedCallback, name)
                    end
                    return
                end
                if processed then return end
                if inp.UserInputType == Enum.UserInputType.Keyboard
                   and inp.KeyCode.Name == BV.CurrentBind then
                    holdActive = true
                    safe(cfg.Callback, true)
                end
            end))
            track(UIS.InputEnded:Connect(function(inp)
                if cfg.HoldToInteract
                   and inp.UserInputType == Enum.UserInputType.Keyboard
                   and inp.KeyCode.Name == BV.CurrentBind
                   and holdActive then
                    holdActive = false
                    safe(cfg.Callback, false)
                end
            end))

            addHover(card, strip, stroke)

            function BV:Set(k)
                BV.CurrentBind = k
                keyLabel.Text  = k
                safe(cfg.OnChangedCallback, k)
            end
            function BV:Destroy() card:Destroy() end
            if cfg.Flag then Sentence.Flags[cfg.Flag]=BV; Sentence.Options[cfg.Flag]=BV end
            return BV
        end
        Sec.CreateKeybind = Sec.CreateBind

        -- ── Input ─────────────────────────────────────────────────────────────
        function Sec:CreateInput(cfg)
            cfg = merge({
                Name="Input", Description=nil,
                PlaceholderText="Enter value…",
                CurrentValue="",
                Numeric=false, MaxCharacters=nil,
                Enter=false, RemoveTextAfterFocusLost=false,
                Flag=nil, Callback=function()end,
            }, cfg or {})

            local h = cfg.Description and 72 or 56
            local card, strip, stroke = makeElemFrame(container, h)
            strip.BackgroundTransparency = 0

            newText({
                Text     = cfg.Name,
                Size     = UDim2.new(1,-24,0,15),
                Position = UDim2.new(0,14,0,7),
                Font     = Enum.Font.GothamBold,
                TextSize = FS.ElemName,
                Color    = T.TextHi,
                Z        = 5,
                Parent   = card,
            })
            if cfg.Description then
                newText({
                    Text     = cfg.Description,
                    Size     = UDim2.new(1,-24,0,13),
                    Position = UDim2.new(0,14,0,24),
                    Font     = Enum.Font.Gotham,
                    TextSize = FS.ElemDesc,
                    Color    = T.TextMid,
                    Z        = 5,
                    Parent   = card,
                })
            end

            local fieldY = cfg.Description and 40 or 26
            local fieldH = 22

            local fieldBg = newFrame({
                Size     = UDim2.new(1,-28,0,fieldH),
                Position = UDim2.new(0,14,0,fieldY),
                Color    = T.BG1,
                Alpha    = 0,
                Radius   = 3,
                Z        = 5,
                Parent   = card,
            })
            newPadding(fieldBg, 0,0,8,0)
            local fieldStroke = newStroke(fieldBg, T.Border, 1, 0.45)

            -- Left pip
            newFrame({
                Size   = UDim2.new(0,2,1,0),
                Color  = accent,
                Alpha  = 0.5,
                Z      = 6,
                Parent = fieldBg,
            })

            local tb = Instance.new("TextBox")
            tb.Name               = "InputBox"
            tb.Size               = UDim2.new(1,0,1,0)
            tb.BackgroundTransparency = 1
            tb.BorderSizePixel    = 0
            tb.PlaceholderText    = cfg.PlaceholderText
            tb.PlaceholderColor3  = T.TextLo
            tb.Text               = cfg.CurrentValue
            tb.Font               = Enum.Font.Code
            tb.TextSize           = FS.ElemValue
            tb.TextColor3         = T.TextHi
            tb.TextXAlignment     = Enum.TextXAlignment.Left
            tb.ClearTextOnFocus   = false
            tb.ZIndex             = 7
            tb.Parent             = fieldBg

            local IV = {CurrentValue=cfg.CurrentValue, Type="Input", Settings=cfg}

            tb.Focused:Connect(function()
                tw(fieldStroke, {Color=accent, Transparency=0.0}, TI_FAST)
                tw(fieldBg,     {BackgroundColor3=T.BG2},         TI_FAST)
                tw(stroke,      {Transparency=0.30, Color=accent}, TI_FAST)
            end)
            tb.FocusLost:Connect(function(enterPressed)
                tw(fieldStroke, {Color=T.Border, Transparency=0.45}, TI_FAST)
                tw(fieldBg,     {BackgroundColor3=T.BG1},             TI_FAST)
                tw(stroke,      {Transparency=0.78, Color=T.BorderGl},TI_FAST)
                local val = tb.Text
                if cfg.Numeric then
                    val = val:gsub("[^%d%.%-]","")
                    tb.Text = val
                end
                if cfg.MaxCharacters and #val > cfg.MaxCharacters then
                    val = val:sub(1, cfg.MaxCharacters)
                    tb.Text = val
                end
                IV.CurrentValue = val
                if cfg.RemoveTextAfterFocusLost then tb.Text=""; IV.CurrentValue="" end
                if cfg.Enter then
                    if enterPressed then safe(cfg.Callback, val) end
                else
                    safe(cfg.Callback, val)
                end
            end)

            if cfg.MaxCharacters then
                tb:GetPropertyChangedSignal("Text"):Connect(function()
                    if #tb.Text > cfg.MaxCharacters then
                        tb.Text = tb.Text:sub(1, cfg.MaxCharacters)
                    end
                end)
            end

            addHover(card, strip, stroke)

            function IV:Set(v)
                v = tostring(v)
                if cfg.MaxCharacters and #v > cfg.MaxCharacters then v = v:sub(1,cfg.MaxCharacters) end
                tb.Text = v; IV.CurrentValue = v
            end
            function IV:Destroy() card:Destroy() end
            if cfg.Flag then Sentence.Flags[cfg.Flag]=IV; Sentence.Options[cfg.Flag]=IV end
            return IV
        end

        -- ── Dropdown ──────────────────────────────────────────────────────────
        function Sec:CreateDropdown(cfg)
            cfg = merge({
                Name="Dropdown", Description=nil,
                Options={"Option 1","Option 2"},
                CurrentOption=nil, MultipleOptions=false,
                SpecialType=nil, Flag=nil,
                Callback=function()end,
            }, cfg or {})

            local function resolveOptions()
                if cfg.SpecialType == "Player" then
                    local t = {}
                    for _,p in ipairs(Plrs:GetPlayers()) do t[#t+1] = p.Name end
                    return t
                end
                return cfg.Options
            end

            local opts = resolveOptions()
            local function defaultSel()
                if cfg.MultipleOptions then return {} end
                return opts[1] or ""
            end
            local currentSel = cfg.CurrentOption ~= nil and cfg.CurrentOption or defaultSel()

            local baseH = cfg.Description and 72 or 56
            local card, strip, stroke = makeElemFrame(container, baseH, true)

            newText({
                Text     = cfg.Name,
                Size     = UDim2.new(1,-24,0,15),
                Position = UDim2.new(0,14,0,7),
                Font     = Enum.Font.GothamBold,
                TextSize = FS.ElemName,
                Color    = T.TextHi,
                Z        = 5,
                Parent   = card,
            })
            if cfg.Description then
                newText({
                    Text     = cfg.Description,
                    Size     = UDim2.new(1,-24,0,13),
                    Position = UDim2.new(0,14,0,24),
                    Font     = Enum.Font.Gotham,
                    TextSize = FS.ElemDesc,
                    Color    = T.TextMid,
                    Z        = 5,
                    Parent   = card,
                })
            end

            local headerY = cfg.Description and 35 or 22
            local headerH = 20

            local header = newFrame({
                Size     = UDim2.new(1,-28,0,headerH),
                Position = UDim2.new(0,14,0,headerY),
                Color    = T.BG1,
                Alpha    = 0,
                Radius   = 4,
                Z        = 5,
                Parent   = card,
            })
            newPadding(header, 0,0,8,26)
            local headerStroke = newStroke(header, T.Border, 1, 0.45)

            -- Left pip
            newFrame({
                Size   = UDim2.new(0,2,1,0),
                Color  = accent,
                Alpha  = 0.5,
                Z      = 6,
                Parent = header,
            })

            local displayText = newText({
                Text     = "",
                Size     = UDim2.new(1,0,1,0),
                Font     = Enum.Font.Code,
                TextSize = FS.ElemValue,
                Color    = T.TextHi,
                Z        = 6,
                Parent   = header,
            })

            -- Chevron icon
            local chevron = newImage({
                Icon      = "chevD",
                Size      = UDim2.new(0,9,0,9),
                Position  = UDim2.new(1,-14,0.5,0),
                AnchorPoint=Vector2.new(0.5,0.5),
                Color     = T.TextMid,
                Z         = 7,
                Parent    = header,
            })

            -- Drop panel (staggered row reveal)
            local panel = newFrame({
                Size     = UDim2.new(1,-24,0,0),
                Position = UDim2.new(0,12,0, headerY+headerH+3),
                Color    = T.BG1,
                Alpha    = 0,
                Radius   = 5,
                Clip     = true,
                Z        = 10,
                Parent   = card,
            })
            panel.Visible = false
            local panelStroke = newStroke(panel, accent, 1, 0.55)

            local scroll = Instance.new("ScrollingFrame")
            scroll.Size               = UDim2.new(1,0,1,0)
            scroll.BackgroundTransparency = 1
            scroll.BorderSizePixel    = 0
            scroll.ScrollBarThickness = 2
            scroll.ScrollBarImageColor3 = T.Border
            scroll.CanvasSize         = UDim2.new()
            scroll.AutomaticCanvasSize= Enum.AutomaticSize.Y
            scroll.ZIndex             = 11
            scroll.Parent             = panel
            newLayout(scroll, 2)
            newPadding(scroll, 3,3,4,4)

            local DV = {CurrentOption=currentSel, Type="Dropdown", _open=false, _items={}}

            local function dispStr()
                if cfg.MultipleOptions then
                    if type(currentSel)=="table" and #currentSel>0 then
                        return table.concat(currentSel,", ")
                    end
                    return "None"
                end
                return tostring(currentSel)
            end
            local function isSelected(opt)
                if cfg.MultipleOptions then
                    for _,v in ipairs(currentSel) do if v==opt then return true end end
                    return false
                end
                return currentSel == opt
            end

            local rebuildRows
            local function openPanel()
                DV._open = true
                panel.Visible = true
                local count = math.min(#DV._items, 5)
                local panH = count * 23 + (count+1)*2 + 6
                tw(panel,    {Size=UDim2.new(1,-24,0,panH), BackgroundTransparency=0}, TI_SPRING)
                tw(chevron,  {Rotation=180, ImageColor3=accent},                       TI_FAST)
                tw(headerStroke, {Color=accent, Transparency=0.2},                     TI_FAST)

                -- Stagger each row in
                for i, row in ipairs(DV._items) do
                    task.spawn(function()
                        task.wait((i-1)*0.035)
                        row.Position = UDim2.new(0,8,0, row.Position.Y.Offset)
                        row.BackgroundTransparency = 1
                        tw(row, {Position=UDim2.new(0,0,0,row.Position.Y.Offset), BackgroundTransparency=0.92}, TI_FAST)
                    end)
                end
            end
            local function closePanel()
                DV._open = false
                tw(panel,    {Size=UDim2.new(1,-24,0,0), BackgroundTransparency=1},
                    TI_MED, function() panel.Visible=false end)
                tw(chevron,  {Rotation=0, ImageColor3=T.TextMid},  TI_FAST)
                tw(headerStroke, {Color=T.Border, Transparency=0.45}, TI_FAST)
            end

            rebuildRows = function()
                for _,row in ipairs(DV._items) do pcall(function() row:Destroy() end) end
                DV._items = {}
                for _, opt in ipairs(resolveOptions()) do
                    local sel = isSelected(opt)
                    local row = newFrame({
                        Size   = UDim2.new(1,0,0,23),
                        Color  = sel and T.IceLo or T.BG2,
                        Alpha  = 1,
                        Radius = 3,
                        Z      = 12,
                        Parent = scroll,
                    })

                    local rowStroke = newStroke(row, sel and accent or T.Border, 1, sel and 0.55 or 0.78)

                    -- Checkmark
                    local tick = newImage({
                        Icon    = "ok",
                        Size    = UDim2.new(0,8,0,8),
                        Position= UDim2.new(1,-12,0.5,0),
                        AnchorPoint=Vector2.new(0.5,0.5),
                        Color   = accent,
                        Alpha   = sel and 0 or 1,
                        Z       = 13,
                        Parent  = row,
                    })

                    newText({
                        Text     = opt,
                        Size     = UDim2.new(1,-26,1,0),
                        Position = UDim2.new(0,9,0,0),
                        Font     = Enum.Font.GothamSemibold,
                        TextSize = 11,
                        Color    = sel and T.TextHi or T.TextMid,
                        Z        = 13,
                        Parent   = row,
                    })

                    local rowBtn = newButton(row, 14)
                    row.MouseEnter:Connect(function()
                        if not isSelected(opt) then
                            tw(row,      {BackgroundColor3=T.GlassHi, BackgroundTransparency=0.7}, TI_FAST)
                            tw(rowStroke,{Color=accent, Transparency=0.6},                         TI_FAST)
                        end
                    end)
                    row.MouseLeave:Connect(function()
                        if not isSelected(opt) then
                            tw(row,      {BackgroundColor3=T.BG2, BackgroundTransparency=1},   TI_FAST)
                            tw(rowStroke,{Color=T.Border, Transparency=0.78},                  TI_FAST)
                        end
                    end)
                    rowBtn.MouseButton1Click:Connect(function()
                        if cfg.MultipleOptions then
                            if type(currentSel) ~= "table" then currentSel = {} end
                            local found = false
                            for i2,v in ipairs(currentSel) do
                                if v == opt then table.remove(currentSel, i2); found=true; break end
                            end
                            if not found then currentSel[#currentSel+1] = opt end
                            DV.CurrentOption = currentSel
                            displayText.Text = dispStr()
                            safe(cfg.Callback, currentSel)
                            rebuildRows()
                        else
                            currentSel = opt
                            DV.CurrentOption = opt
                            displayText.Text = dispStr()
                            safe(cfg.Callback, opt)
                            closePanel()
                        end
                    end)
                    DV._items[#DV._items+1] = row
                end
            end

            rebuildRows()
            displayText.Text = dispStr()

            local headerBtn = newButton(header, 8)
            headerBtn.MouseButton1Click:Connect(function()
                if DV._open then closePanel() else openPanel() end
            end)
            header.MouseEnter:Connect(function() tw(header,{BackgroundColor3=T.BG2},TI_FAST) end)
            header.MouseLeave:Connect(function() tw(header,{BackgroundColor3=T.BG1},TI_FAST) end)

            addHover(card, strip, stroke)

            function DV:Set(opts2)
                currentSel = cfg.MultipleOptions
                    and (type(opts2)=="table" and opts2 or {opts2})
                    or opts2
                DV.CurrentOption = currentSel
                displayText.Text = dispStr()
                if DV._open then rebuildRows() end
                safe(cfg.Callback, currentSel)
            end
            function DV:Refresh(newOpts)
                cfg.Options = newOpts or cfg.Options
                local was = DV._open; if was then closePanel() end
                currentSel = defaultSel(); DV.CurrentOption = currentSel
                displayText.Text = dispStr()
                rebuildRows()
                if was then task.wait(0.05); openPanel() end
            end
            function DV:Destroy() card:Destroy() end
            if cfg.Flag then Sentence.Flags[cfg.Flag]=DV; Sentence.Options[cfg.Flag]=DV end
            return DV
        end

        return Sec
    end

    -- Default section shortcut (no header)
    local _defaultSection
    local function getDefault()
        if not _defaultSection then _defaultSection = API:CreateSection("") end
        return _defaultSection
    end
    for _, method in ipairs({
        "CreateButton","CreateLabel","CreateParagraph","CreateToggle",
        "CreateSlider","CreateDivider","CreateColorPicker",
        "CreateBind","CreateKeybind","CreateInput","CreateDropdown",
    }) do
        API[method] = function(self, ...)
            return getDefault()[method](getDefault(), ...)
        end
    end
    return API
end

-- ══════════════════════════════════════════════════════════════════════════════
-- NOTIFICATIONS — Frosted top-right toasts with stacking
-- ══════════════════════════════════════════════════════════════════════════════
local NotifColors = {
    Info    = {fg=T.Ice,     stroke=T.Ice,     badge=T.IceLo,    icon="·"},
    Success = {fg=T.Success, stroke=T.Success, badge=T.TealLo,   icon="✓"},
    Warning = {fg=T.Warning, stroke=T.Warning, badge=T.BG3,      icon="!"},
    Error   = {fg=T.Error,   stroke=T.Error,   badge=T.BG3,      icon="✕"},
}

function Sentence:Notify(data)
    task.spawn(function()
        data = merge({
            Title="Notice", Content="", Type="Info",
            Duration=5, Icon=nil
        }, data)

        local pal = NotifColors[data.Type] or NotifColors.Info

        -- Card width constant
        local CARD_W = 300

        -- Card (glass) — starts off-screen to the right
        local card = newFrame({
            Name    = "Notif",
            Size    = UDim2.new(0,CARD_W,0,0),
            Position= UDim2.new(0,CARD_W+20,0,0),
            Color   = T.BG2,
            Alpha   = 0,
            Radius  = 6,
            Clip    = true,
            Z       = 1,
            Parent  = self._notifHolder,
        })

        -- Glass shimmer overlay
        local shimmer = newFrame({
            Size   = UDim2.new(1,0,1,0),
            Color  = T.TextHi,
            Alpha  = 1,
            Radius = 6,
            Z      = 1,
            Parent = card,
        })
        newGradient(shimmer, nil, NumberSequence.new{
            NumberSequenceKeypoint.new(0,   0.94),
            NumberSequenceKeypoint.new(0.6, 0.97),
            NumberSequenceKeypoint.new(1,   1.00),
        }, 100)

        local cardStroke = newStroke(card, pal.stroke, 1, 1)

        -- Bottom accent bar (replaces left bar — more modern)
        local accentBar = newFrame({
            Size     = UDim2.new(1,0,0,2),
            Position = UDim2.new(0,0,1,-2),
            Color    = pal.fg,
            Alpha    = 0,
            Z        = 6,
            Parent   = card,
        })
        newGradient(accentBar, ColorSequence.new{
            ColorSequenceKeypoint.new(0,   pal.fg),
            ColorSequenceKeypoint.new(0.6, T.Ice),
            ColorSequenceKeypoint.new(1,   T.BorderGl),
        })

        -- Left accent strip (thin)
        local leftBar = newFrame({
            Size   = UDim2.new(0,3,1,0),
            Color  = pal.fg,
            Alpha  = 0,
            Radius = 0,
            Z      = 5,
            Parent = card,
        })

        -- Top-left icon badge
        local iconBox = newFrame({
            Size       = UDim2.new(0,28,0,28),
            Position   = UDim2.new(0,12,0,0),
            AnchorPoint= Vector2.new(0,0.5),
            Color      = T.BG3,
            Alpha      = 0,
            Radius     = 5,
            Z          = 5,
            Parent     = card,
        })
        local iconBoxStroke = newStroke(iconBox, pal.fg, 1, 1)
        local iconLabel = newText({
            Text     = data.Icon or pal.icon,
            Size     = UDim2.new(1,0,1,0),
            Font     = Enum.Font.GothamBold,
            TextSize = 14,
            Color    = pal.fg,
            Alpha    = 1,
            AlignX   = Enum.TextXAlignment.Center,
            Z        = 6,
            Parent   = iconBox,
        })

        -- Content block
        local content = newFrame({
            Size   = UDim2.new(1,0,0,0),
            Color  = T.BG0,
            Alpha  = 1,
            AutoY  = true,
            Z      = 4,
            Parent = card,
        })
        newPadding(content, 10,12,52,28)
        newLayout(content, 3)

        -- Type badge (pill)
        local typeBadge = newFrame({
            Size   = UDim2.new(0,0,0,14),
            Color  = pal.fg,
            Alpha  = 0,
            Radius = 3,
            Z      = 5,
            AutoX  = true,
            Parent = content,
        })
        newPadding(typeBadge, 0,0,5,5)
        local typeLabel = newText({
            Text     = data.Type:upper(),
            Size     = UDim2.new(0,0,1,0),
            Font     = Enum.Font.GothamBold,
            TextSize = FS.NotifType,
            Color    = T.BG1,
            Alpha    = 1,
            AlignX   = Enum.TextXAlignment.Center,
            AutoX    = true,
            Z        = 6,
            Parent   = typeBadge,
        })

        local titleLabel = newText({
            Text     = data.Title,
            Size     = UDim2.new(1,0,0,16),
            Font     = Enum.Font.GothamBold,
            TextSize = FS.NotifTitle,
            Color    = T.TextHi,
            Alpha    = 1,
            Z        = 5,
            Parent   = content,
        })
        local msgLabel = newText({
            Text     = data.Content,
            Size     = UDim2.new(1,0,0,0),
            Font     = Enum.Font.Gotham,
            TextSize = FS.NotifBody,
            Color    = T.TextMid,
            Alpha    = 1,
            Wrap     = true,
            AutoY    = true,
            Z        = 5,
            Parent   = content,
        })

        -- Timer bar (top of card)
        local timerBg = newFrame({
            Size     = UDim2.new(1,0,0,2),
            Position = UDim2.new(0,0,0,0),
            Color    = T.BG3,
            Alpha    = 0,
            Z        = 7,
            Parent   = card,
        })
        local timerFill = newFrame({
            Size   = UDim2.new(1,0,1,0),
            Color  = pal.fg,
            Alpha  = 0,
            Z      = 8,
            Parent = timerBg,
        })
        newGradient(timerFill, ColorSequence.new{
            ColorSequenceKeypoint.new(0,   pal.fg),
            ColorSequenceKeypoint.new(1,   T.Ice),
        })

        -- Close button (top-right)
        local closeBtn = newFrame({
            Size       = UDim2.new(0,16,0,16),
            Position   = UDim2.new(1,-8,0,8),
            AnchorPoint= Vector2.new(1,0),
            Color      = T.BG3,
            Alpha      = 0,
            Radius     = 4,
            Z          = 8,
            Parent     = card,
        })
        newStroke(closeBtn, T.Border, 1, 0.5)
        local closeLabel = newText({
            Text     = "✕",
            Size     = UDim2.new(1,0,1,0),
            Font     = Enum.Font.GothamBold,
            TextSize = 9,
            Color    = T.TextLo,
            Alpha    = 0,
            AlignX   = Enum.TextXAlignment.Center,
            Z        = 9,
            Parent   = closeBtn,
        })
        local closeClick = newButton(closeBtn, 10)
        closeBtn.MouseEnter:Connect(function()
            tw(closeBtn,  {BackgroundColor3=T.Error, BackgroundTransparency=0}, TI_FAST)
            tw(closeLabel,{TextColor3=T.TextHi},                                TI_FAST)
        end)
        closeBtn.MouseLeave:Connect(function()
            tw(closeBtn,  {BackgroundColor3=T.BG3, BackgroundTransparency=0},  TI_FAST)
            tw(closeLabel,{TextColor3=T.TextLo},                               TI_FAST)
        end)

        -- Wait one frame to get real AutoY height
        task.wait()
        local cardH = content.AbsoluteSize.Y + 4
        iconBox.Position = UDim2.new(0,12,0, cardH/2 - 14)
        card.Size        = UDim2.new(0,CARD_W,0, cardH)

        -- All elements start invisible/transparent
        shimmer.BackgroundTransparency   = 1
        accentBar.BackgroundTransparency = 1
        leftBar.BackgroundTransparency   = 1
        iconBox.BackgroundTransparency   = 1
        typeBadge.BackgroundTransparency = 1
        timerBg.BackgroundTransparency   = 1
        timerFill.BackgroundTransparency = 1
        closeBtn.BackgroundTransparency  = 1
        closeLabel.TextTransparency      = 1
        titleLabel.TextTransparency      = 1
        msgLabel.TextTransparency        = 1
        typeLabel.TextTransparency       = 1

        -- ── Entrance: slide in from right (spring) ────────────────────────────
        tw(card, {Position=UDim2.new(0,0,0,0), BackgroundTransparency=0}, TI_SPRING)
        task.wait(0.10)

        local TI_IN = TI(.20, Enum.EasingStyle.Exponential)
        tw(shimmer,        {BackgroundTransparency=0.94},  TI_IN)
        tw(leftBar,        {BackgroundTransparency=0},     TI_IN)
        tw(accentBar,      {BackgroundTransparency=0},     TI_IN)
        tw(iconBox,        {BackgroundTransparency=0},     TI_IN)
        tw(iconBoxStroke,  {Transparency=0.30},             TI_IN)
        tw(cardStroke,     {Transparency=0.50},             TI_IN)
        tw(typeBadge,      {BackgroundTransparency=0},     TI_IN)
        tw(typeLabel,      {TextTransparency=0},            TI_IN)
        tw(titleLabel,     {TextTransparency=0},            TI_IN)
        tw(msgLabel,       {TextTransparency=0},            TI_IN)
        tw(timerBg,        {BackgroundTransparency=0.65},  TI_IN)
        tw(timerFill,      {BackgroundTransparency=0},     TI_IN)
        tw(closeBtn,       {BackgroundTransparency=0},     TI_IN)
        tw(closeLabel,     {TextTransparency=0},            TI_IN)

        -- Timer countdown
        tw(timerFill, {Size=UDim2.new(0,0,1,0)},
            TI(data.Duration, Enum.EasingStyle.Linear))

        local paused    = false
        local dismissed = false
        local elapsed   = 0

        card.MouseEnter:Connect(function()
            paused = true
            tw(card,      {BackgroundColor3=T.BG3},        TI_FAST)
            tw(cardStroke,{Transparency=0.25},              TI_FAST)
        end)
        card.MouseLeave:Connect(function()
            paused = false
            tw(card,      {BackgroundColor3=T.BG2},        TI_FAST)
            tw(cardStroke,{Transparency=0.50},              TI_FAST)
        end)
        closeClick.MouseButton1Click:Connect(function() dismissed = true end)

        repeat
            task.wait(0.05)
            if not paused then elapsed = elapsed + 0.05 end
        until dismissed or elapsed >= data.Duration

        -- ── Exit: slide out to the right ──────────────────────────────────────
        local TI_OUT = TI(.14, Enum.EasingStyle.Quad)
        tw(shimmer,    {BackgroundTransparency=1},  TI_OUT)
        tw(leftBar,    {BackgroundTransparency=1},  TI_OUT)
        tw(accentBar,  {BackgroundTransparency=1},  TI_OUT)
        tw(iconBox,    {BackgroundTransparency=1},  TI_OUT)
        tw(typeBadge,  {BackgroundTransparency=1},  TI_OUT)
        tw(titleLabel, {TextTransparency=1},         TI_OUT)
        tw(msgLabel,   {TextTransparency=1},         TI_OUT)
        tw(typeLabel,  {TextTransparency=1},         TI_OUT)
        tw(timerBg,    {BackgroundTransparency=1},  TI_OUT)
        tw(timerFill,  {BackgroundTransparency=1},  TI_OUT)
        tw(closeBtn,   {BackgroundTransparency=1},  TI_OUT)
        tw(cardStroke, {Transparency=1},             TI_OUT)

        tw(card, {
            Position            = UDim2.new(0,CARD_W+20,0,card.Position.Y.Offset),
            BackgroundTransparency = 1,
        }, TI(.24, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        function()
            tw(card, {Size=UDim2.new(0,CARD_W,0,0)}, TI_MED,
            function() card:Destroy() end)
        end)
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- CREATE WINDOW
-- ══════════════════════════════════════════════════════════════════════════════
function Sentence:CreateWindow(cfg)
    cfg = merge({
        Name           = "SENTENCE",
        Subtitle       = "",
        Icon           = "",
        ToggleBind     = Enum.KeyCode.RightControl,
        LoadingEnabled = true,
        LoadingTitle   = "SENTENCE",
        LoadingSubtitle= "Initializing…",
        ConfigurationSaving = {Enabled=false, FolderName="Sentence", FileName="config"},
    }, cfg)

    local vp   = Cam.ViewportSize
    local WW   = math.clamp(vp.X - 100, 580, 820)
    local WH   = math.clamp(vp.Y -  80, 420, 560)
    local FULL = UDim2.fromOffset(WW, WH)
    local TBH  = 48   -- title bar height (was 38)
    local SBW  = 54   -- sidebar width (was 46)
    local MINI = UDim2.fromOffset(WW, TBH + 2)

    -- ── ScreenGui ─────────────────────────────────────────────────────────────
    local gui = Instance.new("ScreenGui")
    gui.Name             = "SentenceUI"
    gui.DisplayOrder     = 999999999
    gui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
    gui.ResetOnSpawn     = false
    gui.IgnoreGuiInset   = true
    if gethui then
        gui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(gui); gui.Parent = CG
    elseif not IsStudio then
        gui.Parent = CG
    else
        gui.Parent = LP:WaitForChild("PlayerGui")
    end

    -- ── Notification holder (bottom-right, stacks upward) ────────────────────
    local notifHolder = newFrame({
        Name        = "Notifs",
        Size        = UDim2.new(0,300,1,-16),
        Position    = UDim2.new(1,-312,1,-12),
        AnchorPoint = Vector2.new(0,1),
        Color       = T.BG0,
        Alpha       = 1,
        Z           = 200,
        Parent      = gui,
    })
    local nLayout = newLayout(notifHolder, 6, Enum.FillDirection.Vertical)
    nLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    self._notifHolder = notifHolder

    -- ══════════════════════════════════════════════════════════════════════════
    -- SPLASH SCREEN — "Sentence App Style"
    -- ══════════════════════════════════════════════════════════════════════════
    task.spawn(function()
        local splash = newFrame({
            Name   = "Splash",
            Size   = UDim2.new(1,0,1,0),
            Color  = H("#0a0a0a"),
            Alpha  = 0,
            Z      = 1000,
            Clip   = true,
            Parent = gui,
        })
 
        -- Diagonal stripe lines (background texture like app)
        for i = 1, 18 do
            local stripe = newFrame({
                Size        = UDim2.new(0,2,1,400),
                Position    = UDim2.new(0,i*58-40,0,-200),
                AnchorPoint = Vector2.new(0,0),
                Color       = T.TextHi,
                Alpha       = 0.965,
                Z           = 1001,
                Parent      = splash,
            })
            stripe.Rotation = -28
        end
 
        -- Subtle vignette overlay (dark edges)
        local vignette = newFrame({
            Size   = UDim2.new(1,0,1,0),
            Color  = H("#000000"),
            Alpha  = 0,
            Z      = 1002,
            Parent = splash,
        })
        newGradient(vignette, nil, NumberSequence.new{
            NumberSequenceKeypoint.new(0,   0.0),
            NumberSequenceKeypoint.new(0.4, 0.85),
            NumberSequenceKeypoint.new(0.6, 0.85),
            NumberSequenceKeypoint.new(1,   0.0),
        }, 0)
 
        -- Center content holder
        local centerHolder = newFrame({
            Size        = UDim2.new(0,420,0,160),
            Position    = UDim2.new(0.5,0,0.46,0),
            AnchorPoint = Vector2.new(0.5,0.5),
            Color       = H("#0a0a0a"),
            Alpha       = 1,
            Z           = 1005,
            Parent      = splash,
        })
 
        -- Logo image
        local logoBox = newFrame({
            Size        = UDim2.new(0,82,0,82),
            Position    = UDim2.new(0,0,0.5,0),
            AnchorPoint = Vector2.new(0,0.5),
            Color       = H("#0a0a0a"),
            Alpha       = 1,
            Z           = 1006,
            Parent      = centerHolder,
        })
        local logoImg = Instance.new("ImageLabel")
        logoImg.Size                   = UDim2.new(1,0,1,0)
        logoImg.BackgroundTransparency = 1
        logoImg.Image                  = cfg.Icon ~= "" and resolveIcon(cfg.Icon) or LOGO_ID
        logoImg.ScaleType              = Enum.ScaleType.Fit
        logoImg.ImageTransparency      = 1
        logoImg.ImageColor3            = T.TextHi
        logoImg.ZIndex                 = 1007
        logoImg.Parent                 = logoBox
 
        -- Right text block
        local textBlock = newFrame({
            Size        = UDim2.new(0,310,0,80),
            Position    = UDim2.new(0,90,0.5,0),
            AnchorPoint = Vector2.new(0,0.5),
            Color       = H("#0a0a0a"),
            Alpha       = 1,
            Z           = 1006,
            Parent      = centerHolder,
        })
 
        -- Main title
        local titleLabel = newText({
            Text   = cfg.Name:upper(),
            Size   = UDim2.new(1,0,0,48),
            Position = UDim2.new(0,0,0,0),
            Font   = Enum.Font.GothamBold,
            TextSize = 40,
            Color  = T.TextHi,
            Alpha  = 1,
            AlignX = Enum.TextXAlignment.Left,
            Z      = 1007,
            Parent = textBlock,
        })
 
        -- Subtitle line
        local subtitleLabel = newText({
            Text     = cfg.Subtitle ~= "" and cfg.Subtitle:upper() or "THE MOST ADVANCED HUB IN USE",
            Size     = UDim2.new(1,0,0,18),
            Position = UDim2.new(0,0,0,50),
            Font     = Enum.Font.Gotham,
            TextSize = 15,
            Color    = T.TextMid,
            Alpha    = 1,
            AlignX   = Enum.TextXAlignment.Left,
            Z        = 1007,
            Parent   = textBlock,
        })
 
        -- Thin accent line under subtitle
        local accentLine = newFrame({
            Size     = UDim2.new(0,0,0,1),
            Position = UDim2.new(0,0,0,72),
            Color    = T.Ice,
            Alpha    = 1,
            Z        = 1007,
            Parent   = textBlock,
        })
        newGradient(accentLine, ColorSequence.new{
            ColorSequenceKeypoint.new(0,   T.Ice),
            ColorSequenceKeypoint.new(0.6, T.Violet),
            ColorSequenceKeypoint.new(1,   T.Border),
        })
 
        -- Spinner
        local spinnerHolder = newFrame({
            Size        = UDim2.new(0,32,0,32),
            Position    = UDim2.new(0.5,0,0.46,110),
            AnchorPoint = Vector2.new(0.5,0),
            Color       = H("#0a0a0a"),
            Alpha       = 1,
            Radius      = 999,
            Z           = 1006,
            Parent      = splash,
        })
        local spinnerRing = newFrame({
            Size   = UDim2.new(1,0,1,0),
            Color  = H("#0a0a0a"),
            Alpha  = 1,
            Radius = 999,
            Z      = 1007,
            Parent = spinnerHolder,
        })
        local spinStroke = newStroke(spinnerRing, T.Ice, 2, 0)
        local spinnerBg = newFrame({
            Size   = UDim2.new(1,0,1,0),
            Color  = H("#0a0a0a"),
            Alpha  = 1,
            Radius = 999,
            Z      = 1006,
            Parent = spinnerHolder,
        })
        newStroke(spinnerBg, T.Border, 2, 0.6)
 
        -- Status text
        local statusLabel = newText({
            Text        = "initializing…",
            Size        = UDim2.new(0,260,0,14),
            Position    = UDim2.new(0.5,0,0.46,152),
            AnchorPoint = Vector2.new(0.5,0),
            Font        = Enum.Font.Code,
            TextSize    = 10,
            Color       = T.TextLo,
            Alpha       = 1,
            AlignX      = Enum.TextXAlignment.Center,
            Z           = 1006,
            Parent      = splash,
        })
 
        -- Bottom branding bar
        local bottomBar = newFrame({
            Size     = UDim2.new(1,0,0,32),
            Position = UDim2.new(0,0,1,-32),
            Color    = H("#060606"),
            Alpha    = 0,
            Z        = 1006,
            Parent   = splash,
        })
        newFrame({
            Size   = UDim2.new(1,0,0,1),
            Color  = T.Border,
            Alpha  = 0,
            Z      = 1007,
            Parent = bottomBar,
        })
        newText({
            Text     = "Version: "..Sentence.Version.."  ·  Made by DareQPlaysRBX  ·  Powered by SentenceUI",
            Size     = UDim2.new(1,-24,1,0),
            Position = UDim2.new(0,12,0,0),
            Font     = Enum.Font.Gotham,
            TextSize = 10,
            Color    = T.TextLo,
            Alpha    = 1,
            AlignX   = Enum.TextXAlignment.Left,
            Z        = 1007,
            Parent   = bottomBar,
        })
 
        -- ── Spinner rotation loop ─────────────────────────────────────────────
        local spinAlive = true
        local spinConn = RS.RenderStepped:Connect(function(dt)
            if not spinAlive then return end
            spinnerRing.Rotation = spinnerRing.Rotation + 180 * dt
        end)
 
        -- ── Phase 1: Fade in background ───────────────────────────────────────
        tw(splash, {BackgroundTransparency=0}, TI(.24, Enum.EasingStyle.Quad))
        task.wait(0.20)
 
        -- Phase 2: Bottom bar slides in
        tw(bottomBar, {BackgroundTransparency=0.15}, TI_MED)
        task.wait(0.12)
 
        -- Phase 3: Logo appears
        tw(logoImg, {ImageTransparency=0}, TI(.32, Enum.EasingStyle.Exponential))
        task.wait(0.14)
 
        -- Phase 4: Title fades in
        tw(titleLabel, {TextTransparency=0}, TI(.28, Enum.EasingStyle.Exponential))
        task.wait(0.10)
 
        -- Phase 5: Subtitle + accent line
        tw(subtitleLabel, {TextTransparency=0.25}, TI_MED)
        tw(accentLine, {
            Size                   = UDim2.new(0,280,0,1),
            BackgroundTransparency = 0,
        }, TI(.40, Enum.EasingStyle.Exponential))
        task.wait(0.18)
 
        -- Phase 6: Spinner appears
        tw(spinStroke, {Transparency=0.0}, TI_FAST)
        task.wait(0.10)
 
        -- Phase 7: Status steps
        local steps = {
            {label="loading modules…",   wait=0.28},
            {label="injecting scripts…", wait=0.24},
            {label="fetching assets…",   wait=0.22},
            {label="building ui…",       wait=0.20},
            {label="ready.",             wait=0.32},
        }
        for _, step in ipairs(steps) do
            tw(statusLabel, {TextTransparency=1},    TI(.06, Enum.EasingStyle.Quad))
            task.wait(0.07)
            statusLabel.Text = step.label
            tw(statusLabel, {TextTransparency=0.40}, TI(.08, Enum.EasingStyle.Quad))
            task.wait(step.wait)
        end
        task.wait(0.20)
 
        -- ══════════════════════════════════════════════════════════════════════
        -- OUTRO
        -- ══════════════════════════════════════════════════════════════════════
        spinAlive = false
        spinConn:Disconnect()
 
        -- Spinner zmienia kolor na zielony — sygnał "ready"
        tw(spinStroke, {Color=T.Success}, TI_FAST)
        task.wait(0.34)
 
        -- Accent line zwęża się symetrycznie do środka
        tw(accentLine, {
            Size                   = UDim2.new(0,0,0,1),
            Position               = UDim2.new(0.5,0,0,72),
            AnchorPoint            = Vector2.new(0.5,0),
            BackgroundTransparency = 1,
        }, TI(.30, Enum.EasingStyle.Exponential, Enum.EasingDirection.In))
 
        -- Status i spinner gasną
        tw(spinStroke,  {Transparency=1},    TI(.22, Enum.EasingStyle.Quad))
        tw(statusLabel, {TextTransparency=1}, TI(.18, Enum.EasingStyle.Quad))
        task.wait(0.16)
 
        -- Subtitle odpływa w dół
        tw(subtitleLabel, {
            TextTransparency = 1,
            Position         = UDim2.new(0,0,0,58),
        }, TI(.24, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
 
        -- Tytuł odpływa w górę
        tw(titleLabel, {
            TextTransparency = 1,
            Position         = UDim2.new(0,0,0,-12),
        }, TI(.28, Enum.EasingStyle.Exponential, Enum.EasingDirection.In))
 
        -- Logo maleje i znika
        tw(logoImg, {
            ImageTransparency = 1,
            Size              = UDim2.new(0.7,0,0.7,0),
        }, TI(.26, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
        task.wait(0.22)
 
        -- Bottom bar odpływa w dół
        tw(bottomBar, {
            BackgroundTransparency = 1,
            Position               = UDim2.new(0,0,1,8),
        }, TI(.22, Enum.EasingStyle.Quad))
        task.wait(0.12)
 
        -- Biały flash — cinematic punch
        local flash = newFrame({
            Size   = UDim2.new(1,0,1,0),
            Color  = T.TextHi,
            Alpha  = 1,
            Z      = 1020,
            Parent = splash,
        })
        tw(flash, {BackgroundTransparency=0}, TI(.04, Enum.EasingStyle.Quad))
        task.wait(0.05)
        tw(flash, {BackgroundTransparency=1}, TI(.28, Enum.EasingStyle.Exponential))
        task.wait(0.14)
 
        -- Całość fade out
        tw(splash, {BackgroundTransparency=1},
            TI(.26, Enum.EasingStyle.Quad),
            function() splash:Destroy() end)
    end)
  
    -- ══════════════════════════════════════════════════════════════════════════
    -- MAIN WINDOW
    -- ══════════════════════════════════════════════════════════════════════════
    local win = newFrame({
        Name      = "FrostWindow",
        Size      = UDim2.fromOffset(0,0),
        Position  = UDim2.new(0.5,0,0.5,0),
        AnchorPoint=Vector2.new(0.5,0.5),
        Color     = T.BG1,
        Alpha     = 0,
        Radius    = 4,
        Clip      = true,
        Z         = 1,
        Parent    = gui,
    })
    local winStroke = newStroke(win, T.BorderGl, 1, 0.65)

    -- Window ambient glass shimmer
    local winShimmer = newFrame({
        Size   = UDim2.new(1,0,1,0),
        Color  = T.TextHi,
        Alpha  = 1,
        Radius = 8,
        Z      = 0,
        Parent = win,
    })
    newGradient(winShimmer, nil, NumberSequence.new{
        NumberSequenceKeypoint.new(0,   0.96),
        NumberSequenceKeypoint.new(0.5, 0.98),
        NumberSequenceKeypoint.new(1,   1.00),
    }, 120)

    -- Corner glow blob
    local winGlow = newFrame({
        Size     = UDim2.new(0,200,0,120),
        Position = UDim2.new(0,0,0,0),
        Color    = T.Ice,
        Alpha    = 1,
        Radius   = 999,
        Z        = 0,
        Parent   = win,
    })
    newGradient(winGlow, nil, NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.90),
        NumberSequenceKeypoint.new(1, 1.00),
    }, 140)

    -- Top accent line (ice gradient)
    local topLine = newFrame({
        Size   = UDim2.new(1,0,0,1.5),
        Color  = T.Ice,
        Alpha  = 1,
        Z      = 10,
        Parent = win,
    })
    newGradient(topLine, ColorSequence.new{
        ColorSequenceKeypoint.new(0,   T.Ice),
        ColorSequenceKeypoint.new(0.5, T.Violet),
        ColorSequenceKeypoint.new(1,   T.Teal),
    })

    -- ── Title Bar ─────────────────────────────────────────────────────────────
    local titleBar = newFrame({
        Name     = "TitleBar",
        Size     = UDim2.new(1,0,0,TBH),
        Position = UDim2.new(0,0,0,1.5),
        Color    = T.BG1,
        Alpha    = 0,
        Z        = 5,
        Parent   = win,
    })
    makeDraggable(titleBar, win)

    -- Bottom separator
    local tbSep = newFrame({
        Size     = UDim2.new(1,0,0,1),
        Position = UDim2.new(0,0,1,-1),
        Color    = T.Border,
        Alpha    = 0,
        Z        = 6,
        Parent   = titleBar,
    })
    newGradient(tbSep, ColorSequence.new{
        ColorSequenceKeypoint.new(0,   T.Ice),
        ColorSequenceKeypoint.new(0.25,T.Border),
        ColorSequenceKeypoint.new(1,   T.Border),
    })

    -- ── Window Control Buttons ────────────────────────────────────────────────
    local CTRL = {
        {sym="−", ico="minimize", hBg=T.BG4,  hCol=T.Ice},
        {sym="·", ico="hide",     hBg=T.BG4,  hCol=T.Violet},
        {sym="×", ico="close",    hBg=T.Error, hCol=T.TextHi},
    }
    local ctrlButtons = {}
    local BW = 20; local BG = 5; local BM = 10
    for idx, cd in ipairs(CTRL) do
        local fromRight = BM + (3-idx)*(BW+BG)
        local btn = newFrame({
            Size      = UDim2.new(0,BW,0,BW),
            Position  = UDim2.new(1,-fromRight-BW,0.5,0),
            AnchorPoint=Vector2.new(0,0.5),
            Color     = T.BG3,
            Alpha     = 0,
            Radius    = 5,
            Z         = 6,
            Parent    = titleBar,
        })
        local bStroke = newStroke(btn, T.BorderGl, 1, 0.60)
        local bIco = newImage({
            Icon  = cd.ico,
            Size  = UDim2.new(0,9,0,9),
            Color = T.TextLo,
            Alpha = 0,
            Z     = 7,
            Parent= btn,
        })
        task.spawn(function()
            task.wait(0.05)
            tw(bIco, {ImageTransparency=0}, TI_MED)
        end)
        local bClick = newButton(btn, 8)
        btn.MouseEnter:Connect(function()
            tw(btn,    {BackgroundColor3=cd.hBg, BackgroundTransparency=0}, TI_FAST)
            tw(bIco,   {ImageColor3=cd.hCol},                               TI_FAST)
            tw(bStroke,{Color=cd.hBg, Transparency=0.25},                  TI_FAST)
        end)
        btn.MouseLeave:Connect(function()
            tw(btn,    {BackgroundColor3=T.BG3, BackgroundTransparency=0}, TI_FAST)
            tw(bIco,   {ImageColor3=T.TextLo},                             TI_FAST)
            tw(bStroke,{Color=T.BorderGl, Transparency=0.60},             TI_FAST)
        end)
        ctrlButtons[cd.sym] = {frame=btn, click=bClick, ico=bIco}
    end

    -- Logo
    local logoI = Instance.new("ImageLabel")
    logoI.Name  = "WinLogo"
    logoI.Size  = UDim2.new(0,36,0,36)
    logoI.Position  = UDim2.new(0,10,0.5,0)
    logoI.AnchorPoint = Vector2.new(0,0.5)
    logoI.BackgroundTransparency = 1
    logoI.Image = cfg.Icon ~= "" and resolveIcon(cfg.Icon) or LOGO_ID
    logoI.ScaleType = Enum.ScaleType.Fit
    logoI.ImageTransparency = 1
    logoI.ZIndex = 6
    logoI.Parent = titleBar
    Instance.new("UICorner",logoI).CornerRadius = UDim.new(0,5)
    task.spawn(function() tw(logoI,{ImageTransparency=0},TI_MED) end)

    local txOff = 52
    local winName = newText({
        Text     = cfg.Name,
        Size     = UDim2.new(0,240,0,20),
        Position = UDim2.new(0,txOff,0,5),
        Font     = Enum.Font.GothamBold,
        TextSize = FS.WinTitle,
        Color    = T.TextHi,
        Alpha    = 1,
        Z        = 6,
        Parent   = titleBar,
    })
    local subStr = cfg.Subtitle ~= "" and cfg.Subtitle or ("v"..Sentence.Version)
    local winSub = newText({
        Text     = subStr,
        Size     = UDim2.new(0,200,0,13),
        Position = UDim2.new(0,txOff,0,24),
        Font     = Enum.Font.Code,
        TextSize = FS.WinSubtitle,
        Color    = T.TextMid,
        Alpha    = 1,
        Z        = 6,
        Parent   = titleBar,
    })

    -- ── Sidebar ───────────────────────────────────────────────────────────────
    local sidebar = newFrame({
        Name     = "Sidebar",
        Size     = UDim2.new(0,SBW,1,-TBH-1.5),
        Position = UDim2.new(0,0,0,TBH+1.5),
        Color    = T.BG2,
        Alpha    = 0,
        Z        = 4,
        Parent   = win,
    })

    -- Sidebar right border
    local sbBorder = newFrame({
        Size     = UDim2.new(0,1,1,0),
        Position = UDim2.new(1,-1,0,0),
        Color    = T.Border,
        Alpha    = 0,
        Z        = 5,
        Parent   = sidebar,
    })
    newGradient(sbBorder, ColorSequence.new{
        ColorSequenceKeypoint.new(0,   T.Ice),
        ColorSequenceKeypoint.new(0.4, T.Border),
        ColorSequenceKeypoint.new(1,   T.Border),
    }, nil, 90)

    -- Tab icon list
    local tabList = Instance.new("ScrollingFrame")
    tabList.Name                = "TabList"
    tabList.Size                = UDim2.new(1,0,1,-44)
    tabList.Position            = UDim2.new(0,0,0,8)
    tabList.BackgroundTransparency = 1
    tabList.BorderSizePixel     = 0
    tabList.ScrollBarThickness  = 0
    tabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabList.ZIndex              = 5
    tabList.Parent              = sidebar
    newLayout(tabList, 3, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center)
    newPadding(tabList, 4,4,0,0)

    -- Avatar at sidebar bottom
    local avBox = newFrame({
        Size      = UDim2.new(0,28,0,28),
        Position  = UDim2.new(0.5,0,1,-8),
        AnchorPoint=Vector2.new(0.5,1),
        Color     = T.BG3,
        Alpha     = 0,
        Radius    = 5,
        Z         = 5,
        Parent    = sidebar,
    })
    local avImg = Instance.new("ImageLabel")
    avImg.Size               = UDim2.new(1,0,1,0)
    avImg.BackgroundTransparency = 1
    avImg.ZIndex             = 6
    avImg.Parent             = avBox
    Instance.new("UICorner",avImg).CornerRadius = UDim.new(0,5)
    newStroke(avImg, T.Ice, 1, 0.45)
    pcall(function()
        avImg.Image = Plrs:GetUserThumbnailAsync(
            LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    end)

    -- Tooltip (shows on tab hover)
    local tooltip = newFrame({
        Name      = "Tooltip",
        Size      = UDim2.new(0,0,0,22),
        Position  = UDim2.new(0,SBW+6,0,0),
        Color     = T.BG3,
        Alpha     = 0,
        Radius    = 4,
        Z         = 20,
        Visible   = false,
        AutoX     = true,
        Parent    = win,
    })
    newPadding(tooltip, 0,0,8,8)
    newStroke(tooltip, T.Ice, 1, 0.50)
    local tooltipLabel = newText({
        Text     = "",
        Size     = UDim2.new(0,0,1,0),
        Font     = Enum.Font.GothamSemibold,
        TextSize = FS.Tooltip,
        Color    = T.TextHi,
        Z        = 21,
        AutoX    = true,
        Parent   = tooltip,
    })

    -- ── Content Area ──────────────────────────────────────────────────────────
    local contentArea = newFrame({
        Name     = "Content",
        Size     = UDim2.new(1,-SBW-1,1,-TBH-1.5),
        Position = UDim2.new(0,SBW+1,0,TBH+1.5),
        Color    = T.BG1,
        Alpha    = 0,
        Clip     = true,
        Z        = 3,
        Parent   = win,
    })

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

    -- Tab switching (with active pill animation)
    local function switchTab(id)
        for _, tab in ipairs(W._tabs) do
            if tab.id == id then
                tab.page.Visible = true
                tw(tab.bar,    {BackgroundTransparency=0},            TI_FAST)
                tw(tab.icon,   {ImageColor3=T.Ice},                   TI_FAST)
                tw(tab.box,    {BackgroundColor3=T.IceLo, BackgroundTransparency=0}, TI_FAST)
                local s = tab.box:FindFirstChildOfClass("UIStroke")
                if s then tw(s,{Color=T.Ice, Transparency=0.40},     TI_FAST) end
                W._activeTab = id
            else
                tab.page.Visible = false
                tw(tab.bar,    {BackgroundTransparency=1},            TI_FAST)
                tw(tab.icon,   {ImageColor3=T.TextLo},                TI_FAST)
                tw(tab.box,    {BackgroundColor3=T.BG3, BackgroundTransparency=1}, TI_FAST)
                local s = tab.box:FindFirstChildOfClass("UIStroke")
                if s then tw(s,{Color=T.Border, Transparency=0.65},  TI_FAST) end
            end
        end
    end

    -- ── Loading screen ────────────────────────────────────────────────────────
    if cfg.LoadingEnabled then
        local lf = newFrame({
            Name   = "Loading",
            Size   = UDim2.new(1,0,1,0),
            Color  = T.BG1,
            Alpha  = 0,
            Radius = 8,
            Z      = 50,
            Parent = win,
        })

        local lIco = newImage({
            Icon  = cfg.Icon ~= "" and cfg.Icon or LOGO_ID,
            Size  = UDim2.new(0,26,0,26),
            Position=UDim2.new(0.5,0,0.5,-46),
            AnchorPoint=Vector2.new(0.5,0.5),
            Color = T.TextHi,
            Alpha = 1,
            Z     = 51,
            Parent= lf,
        })
        local lT = newText({
            Text     = cfg.LoadingTitle,
            Size     = UDim2.new(1,0,0,22),
            Position = UDim2.new(0.5,0,0.5,-10),
            AnchorPoint=Vector2.new(0.5,0.5),
            Font     = Enum.Font.GothamBold,
            TextSize = FS.LoadTitle,
            Color    = T.TextHi,
            Alpha    = 1,
            AlignX   = Enum.TextXAlignment.Center,
            Z        = 51,
            Parent   = lf,
        })
        local lS = newText({
            Text     = cfg.LoadingSubtitle,
            Size     = UDim2.new(1,0,0,13),
            Position = UDim2.new(0.5,0,0.5,16),
            AnchorPoint=Vector2.new(0.5,0.5),
            Font     = Enum.Font.Code,
            TextSize = FS.LoadSubtitle,
            Color    = T.TextMid,
            Alpha    = 1,
            AlignX   = Enum.TextXAlignment.Center,
            Z        = 51,
            Parent   = lf,
        })

        local pTrk = newFrame({
            Size      = UDim2.new(0,200,0,2),
            Position  = UDim2.new(0.5,0,0.5,40),
            AnchorPoint=Vector2.new(0.5,0.5),
            Color     = T.BG3,
            Alpha     = 0,
            Radius    = 1,
            Z         = 51,
            Parent    = lf,
        })
        local pFl = newFrame({
            Size   = UDim2.new(0,0,1,0),
            Color  = T.Ice,
            Alpha  = 0,
            Radius = 1,
            Z      = 52,
            Parent = pTrk,
        })
        newGradient(pFl, ColorSequence.new{
            ColorSequenceKeypoint.new(0,   T.Ice),
            ColorSequenceKeypoint.new(0.5, T.Violet),
            ColorSequenceKeypoint.new(1,   T.Teal),
        })
        local pPct = newText({
            Text     = "0%",
            Size     = UDim2.new(1,0,0,13),
            Position = UDim2.new(0.5,0,0.5,52),
            AnchorPoint=Vector2.new(0.5,0.5),
            Font     = Enum.Font.Code,
            TextSize = FS.LoadPercent,
            Color    = T.Ice,
            Alpha    = 1,
            AlignX   = Enum.TextXAlignment.Center,
            Z        = 51,
            Parent   = lf,
        })

        tw(win,{Size=FULL},TI_SLOW); task.wait(0.30)
        tw(lT, {TextTransparency=0},TI_MED); task.wait(0.09)
        tw(lS, {TextTransparency=0.30},TI_MED)
        tw(pTrk,{BackgroundTransparency=0.55},TI_FAST)
        tw(pFl, {BackgroundTransparency=0},   TI_FAST)

        local pct = 0
        for _, step in ipairs({0.13,0.09,0.15,0.11,0.17,0.12,0.10,0.13}) do
            pct = math.min(pct+step, 1)
            tw(pFl, {Size=UDim2.new(pct,0,1,0)}, TI(.22, Enum.EasingStyle.Quad))
            pPct.Text = math.floor(pct*100).."%"
            task.wait(0.11 + math.random()*0.08)
        end
        pPct.Text="100%"
        tw(pFl, {Size=UDim2.new(1,0,1,0), BackgroundColor3=T.IceGlow}, TI_FAST)
        task.wait(0.30)

        -- Fade out loading
        tw(lT,  {TextTransparency=1},TI_FAST); tw(lS, {TextTransparency=1},TI_FAST)
        tw(pPct,{TextTransparency=1},TI_FAST); tw(pTrk,{BackgroundTransparency=1},TI_FAST)
        tw(pFl, {BackgroundTransparency=1},TI_FAST)
        task.wait(0.20)
        tw(lf, {BackgroundTransparency=1}, TI_MED, function() lf:Destroy() end)
        task.wait(0.26)
    else
        tw(win, {Size=FULL}, TI_SLOW); task.wait(0.34)
    end

    -- Reveal window chrome
    tw(winStroke,{Transparency=0.52},TI_MED)
    tw(winName,  {TextTransparency=0},TI_MED)
    tw(winSub,   {TextTransparency=0},TI_MED)

    -- ── Window Actions ────────────────────────────────────────────────────────
    local function doClose()
        -- Closing animation overlay
        local ov = newFrame({
            Size   = UDim2.new(1,0,1,0),
            Color  = T.BG0,
            Alpha  = 1,
            Radius = 8,
            Z      = 500,
            Parent = win,
        })
        local oT = newText({
            Text     = cfg.Name,
            Size     = UDim2.new(1,0,0,20),
            Position = UDim2.new(0.5,0,0.5,-10),
            AnchorPoint=Vector2.new(0.5,0.5),
            Font     = Enum.Font.GothamBold,
            TextSize = 18,
            Color    = T.TextHi,
            Alpha    = 1,
            AlignX   = Enum.TextXAlignment.Center,
            Z        = 501,
            Parent   = ov,
        })
        local oS = newText({
            Text     = "closing…",
            Size     = UDim2.new(1,0,0,12),
            Position = UDim2.new(0.5,0,0.5,14),
            AnchorPoint=Vector2.new(0.5,0.5),
            Font     = Enum.Font.Code,
            TextSize = 11,
            Color    = T.TextMid,
            Alpha    = 1,
            AlignX   = Enum.TextXAlignment.Center,
            Z        = 501,
            Parent   = ov,
        })
        local oBar = newFrame({
            Size      = UDim2.new(0,160,0,2),
            Position  = UDim2.new(0.5,0,0.5,34),
            AnchorPoint=Vector2.new(0.5,0.5),
            Color     = T.BG3,
            Alpha     = 0,
            Radius    = 1,
            Z         = 501,
            Parent    = ov,
        })
        local oFl = newFrame({
            Size   = UDim2.new(0,0,1,0),
            Color  = T.Error,
            Alpha  = 0,
            Radius = 1,
            Z      = 502,
            Parent = oBar,
        })

        tw(ov, {BackgroundTransparency=0}, TI(.18, Enum.EasingStyle.Quad))
        tw(oT, {TextTransparency=0}, TI_MED); tw(oS,{TextTransparency=0},TI_MED)
        tw(oBar,{BackgroundTransparency=0.6},TI_FAST); tw(oFl,{BackgroundTransparency=0},TI_FAST)
        task.wait(0.10)
        tw(oFl,{Size=UDim2.new(1,0,1,0)},TI(.46,Enum.EasingStyle.Quad))
        task.wait(0.30); oS.Text="goodbye."
        tw(oFl,{BackgroundColor3=T.TextHi},TI_FAST); task.wait(0.24)

        tw(win,{
            Size=UDim2.fromOffset(WW,0),
            BackgroundTransparency=1,
        },TI(.32,Enum.EasingStyle.Back,Enum.EasingDirection.In))
        tw(winStroke,{Transparency=1},TI(.28))
        task.wait(0.36)
        Sentence:Destroy()
    end

    local function doMinimize()
        if W._minimized then
            W._minimized = false; win.ClipsDescendants=true
            tw(win,{Size=FULL},TI_SPRING,function()
                sidebar.Visible=true; contentArea.Visible=true
            end)
        else
            W._minimized = true
            sidebar.Visible=false; contentArea.Visible=false
            tw(win,{Size=MINI},TI(.20,Enum.EasingStyle.Quad))
        end
    end

    local function hideWindow()
        W._visible = false
        tw(win,{
            Position=UDim2.new(0.5,0,1.4,0),
            Size=UDim2.fromOffset(WW*0.90,WH*0.90),
        },TI(.40,Enum.EasingStyle.Back,Enum.EasingDirection.In),
        function() win.Visible=false; win.Size=W._minimized and MINI or FULL end)
    end
    local function showWindow()
        win.Visible=true; W._visible=true
        win.Position=UDim2.new(0.5,0,1.4,0)
        win.Size=UDim2.fromOffset(WW*0.90,(W._minimized and MINI or FULL).Y.Offset*0.90)
        tw(win,{Position=UDim2.new(0.5,0,0.5,0),Size=W._minimized and MINI or FULL},TI_SPRING)
    end

    ctrlButtons["×"].click.MouseButton1Click:Connect(doClose)
    ctrlButtons["·"].click.MouseButton1Click:Connect(function()
        Sentence:Notify({Title="Hidden",Content=cfg.ToggleBind.Name.." to reopen",Type="Info"})
        hideWindow()
    end)
    ctrlButtons["−"].click.MouseButton1Click:Connect(doMinimize)

    track(UIS.InputBegan:Connect(function(inp, proc)
        if proc then return end
        if inp.KeyCode == cfg.ToggleBind then
            if W._visible then hideWindow() else showWindow() end
        end
    end))

    -- ══════════════════════════════════════════════════════════════════════════
    -- HOME TAB
    -- ══════════════════════════════════════════════════════════════════════════
    function W:CreateHomeTab(hCfg)
        hCfg = merge({Icon="home"}, hCfg or {})
        local id = "Home"

        -- Sidebar tab button
        local hBox = newFrame({
            Name   = "HomeTab",
            Size   = UDim2.new(0,38,0,38),
            Color  = T.BG3,
            Alpha  = 1,
            Radius = 7,
            Z      = 5,
            Parent = tabList,
        })
        local hBar = newFrame({
            Size   = UDim2.new(0,2,0.5,0),
            Position=UDim2.new(0,0,0.25,0),
            Color  = T.Ice,
            Alpha  = 1,
            Z      = 6,
            Parent = hBox,
        })
        newStroke(hBox, T.Border, 1, 0.65)
        local hIco = newImage({
            Icon   = hCfg.Icon,
            Size   = UDim2.new(0,16,0,16),
            Color  = T.TextLo,
            Z      = 6,
            Parent = hBox,
        })
        local hClick = newButton(hBox, 7)

        -- Home page
        local hPage = Instance.new("ScrollingFrame")
        hPage.Name               = "HomePage"
        hPage.Size               = UDim2.new(1,0,1,0)
        hPage.BackgroundTransparency = 1
        hPage.BorderSizePixel    = 0
        hPage.ScrollBarThickness = 2
        hPage.ScrollBarImageColor3 = T.Ice
        hPage.CanvasSize         = UDim2.new()
        hPage.AutomaticCanvasSize= Enum.AutomaticSize.Y
        hPage.ZIndex             = 3
        hPage.Visible            = false
        hPage.Parent             = contentArea
        newLayout(hPage, 8)
        newPadding(hPage, 12,12,12,12)

        -- ── Player Card (glass) ───────────────────────────────────────────────
        local pCard = glassCard(hPage, UDim2.new(1,0,0,76), nil, nil, 8, 3)
        newStroke(pCard:FindFirstChildOfClass("Frame") or pCard, T.Ice, 1, 0.58)

        -- Left accent strip
        newFrame({
            Size   = UDim2.new(0,2,0.65,0),
            Position=UDim2.new(0,0,0.175,0),
            Color  = T.Ice,
            Alpha  = 0,
            Z      = 6,
            Parent = pCard,
        })

        -- Avatar
        local pAv = Instance.new("ImageLabel")
        pAv.Size  = UDim2.new(0,44,0,44)
        pAv.Position = UDim2.new(0,12,0.5,0)
        pAv.AnchorPoint = Vector2.new(0,0.5)
        pAv.BackgroundTransparency = 1
        pAv.ZIndex = 6
        pAv.Parent = pCard
        Instance.new("UICorner",pAv).CornerRadius = UDim.new(0,6)
        newStroke(pAv, T.Ice, 1.5, 0.40)
        pcall(function()
            pAv.Image = Plrs:GetUserThumbnailAsync(
                LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        end)

        newText({
            Text     = LP.DisplayName,
            Size     = UDim2.new(1,-100,0,18),
            Position = UDim2.new(0,68,0,12),
            Font     = Enum.Font.GothamBold,
            TextSize = FS.HomePlayerName,
            Color    = T.TextHi,
            Z        = 6,
            Parent   = pCard,
        })
        newText({
            Text     = "@"..LP.Name,
            Size     = UDim2.new(1,-100,0,13),
            Position = UDim2.new(0,68,0,32),
            Font     = Enum.Font.Code,
            TextSize = FS.HomePlayerUser,
            Color    = T.TextMid,
            Z        = 6,
            Parent   = pCard,
        })

        -- "SENTENCE" badge
        local badge = newFrame({
            Size      = UDim2.new(0,0,0,15),
            Position  = UDim2.new(1,-12,0,10),
            AnchorPoint=Vector2.new(1,0),
            Color     = T.IceLo,
            Alpha     = 0,
            Radius    = 3,
            Z         = 6,
            AutoX     = true,
            Parent    = pCard,
        })
        newPadding(badge,0,0,5,5)
        newStroke(badge, T.Ice, 1, 0.50)
        newText({
            Text     = "SENTENCE UI",
            Size     = UDim2.new(0,0,1,0),
            Font     = Enum.Font.GothamBold,
            TextSize = 9,
            Color    = T.Ice,
            AlignX   = Enum.TextXAlignment.Center,
            AutoX    = true,
            Z        = 7,
            Parent   = badge,
        })

        -- ── Server Stats Card ─────────────────────────────────────────────────
        local sCard = glassCard(hPage, UDim2.new(1,0,0,94), nil, nil, 8, 3)

        -- Card header
        local sHead = newFrame({
            Size   = UDim2.new(1,0,0,20),
            Color  = T.BG0,
            Alpha  = 1,
            Z      = 5,
            Parent = sCard,
        })
        newText({
            Text     = "·  SERVER",
            Size     = UDim2.new(1,-20,1,0),
            Position = UDim2.new(0,12,0,0),
            Font     = Enum.Font.GothamBold,
            TextSize = 10,
            Color    = T.TextMid,
            Z        = 5,
            Parent   = sHead,
        })

        -- Thin divider
        local sDiv = newFrame({
            Size     = UDim2.new(1,-24,0,1),
            Position = UDim2.new(0,12,0,20),
            Color    = T.Border,
            Alpha    = 0,
            Z        = 4,
            Parent   = sCard,
        })
        newGradient(sDiv, ColorSequence.new{
            ColorSequenceKeypoint.new(0, T.Ice),
            ColorSequenceKeypoint.new(1, T.Border),
        })

        local statLabels = {}
        local statDefs = {{"PLAYERS",""}, {"PING",""}, {"UPTIME",""}, {"REGION",""}}
        for i, sd in ipairs(statDefs) do
            local col  = (i-1) % 2
            local row2 = math.floor((i-1) / 2)
            local cW   = (WW - SBW - 48) / 2
            local x    = 12 + col * cW
            local y    = 26 + row2 * 32

            newText({
                Text     = sd[1],
                Size     = UDim2.new(0,120,0,11),
                Position = UDim2.new(0,x,0,y),
                Font     = Enum.Font.GothamBold,
                TextSize = 9,
                Color    = T.TextLo,
                Z        = 5,
                Parent   = sCard,
            })
            statLabels[sd[1]] = newText({
                Text     = "—",
                Size     = UDim2.new(0,160,0,16),
                Position = UDim2.new(0,x,0,y+12),
                Font     = Enum.Font.Code,
                TextSize = 13,
                Color    = T.TextHi,
                Z        = 5,
                Parent   = sCard,
            })
        end

        task.spawn(function()
            while task.wait(1) do
                if not win or not win.Parent then break end
                pcall(function()
                    statLabels["PLAYERS"].Text = #Plrs:GetPlayers().."/"..Plrs.MaxPlayers
                    local ms = math.floor(LP:GetNetworkPing()*1000)
                    statLabels["PING"].Text = ms.."ms"
                    statLabels["PING"].TextColor3 = ms<80 and T.Success or ms<150 and T.Warning or T.Error
                    local t2 = math.floor(time())
                    statLabels["UPTIME"].Text = string.format(
                        "%02d:%02d:%02d",
                        math.floor(t2/3600), math.floor(t2%3600/60), t2%60)
                    pcall(function()
                        statLabels["REGION"].Text =
                            game:GetService("LocalizationService"):GetCountryRegionForPlayerAsync(LP)
                    end)
                end)
            end
        end)

        -- Build section API on home page
        local HomeAPI = buildSectionAPI(hPage, T.Ice, T.Violet)
        HomeAPI.Activate = function() switchTab(id) end

        table.insert(W._tabs, {id=id, box=hBox, page=hPage, bar=hBar, icon=hIco})
        hClick.MouseButton1Click:Connect(function() switchTab(id) end)

        hBox.MouseEnter:Connect(function()
            if W._activeTab ~= id then tw(hBox,{BackgroundTransparency=0.80},TI_FAST) end
            tooltipLabel.Text = "Home"
            tooltip.Visible   = true
            tw(tooltip,{Position=UDim2.new(0,SBW+6,0,
                hBox.AbsolutePosition.Y-win.AbsolutePosition.Y+8)},TI_FAST)
        end)
        hBox.MouseLeave:Connect(function()
            if W._activeTab ~= id then tw(hBox,{BackgroundTransparency=1},TI_FAST) end
            tooltip.Visible = false
        end)

        switchTab(id)
        return HomeAPI
    end

    -- ══════════════════════════════════════════════════════════════════════════
    -- CREATE TAB
    -- ══════════════════════════════════════════════════════════════════════════
    function W:CreateTab(tCfg)
        tCfg = merge({Name="Tab", Icon="unknown", ShowTitle=true}, tCfg or {})
        local Tab = {}
        local id  = tCfg.Name

        -- Sidebar button
        local tBox = newFrame({
            Name   = id.."Tab",
            Size   = UDim2.new(0,38,0,38),
            Color  = T.BG3,
            Alpha  = 1,
            Radius = 7,
            Z      = 5,
            Order  = #W._tabs+1,
            Parent = tabList,
        })
        local tBar = newFrame({
            Size   = UDim2.new(0,2,0.5,0),
            Position=UDim2.new(0,0,0.25,0),
            Color  = T.Ice,
            Alpha  = 1,
            Z      = 6,
            Parent = tBox,
        })
        newStroke(tBox, T.Border, 1, 0.65)
        local tIco = newImage({
            Icon   = tCfg.Icon,
            Size   = UDim2.new(0,16,0,16),
            Color  = T.TextLo,
            Z      = 6,
            Parent = tBox,
        })
        local tClick = newButton(tBox, 7)

        -- Page
        local tPage = Instance.new("ScrollingFrame")
        tPage.Name               = id
        tPage.Size               = UDim2.new(1,0,1,0)
        tPage.BackgroundTransparency = 1
        tPage.BorderSizePixel    = 0
        tPage.ScrollBarThickness = 2
        tPage.ScrollBarImageColor3 = T.Ice
        tPage.CanvasSize         = UDim2.new()
        tPage.AutomaticCanvasSize= Enum.AutomaticSize.Y
        tPage.ZIndex             = 3
        tPage.Visible            = false
        tPage.Parent             = contentArea
        newLayout(tPage, 6)
        newPadding(tPage, 12,12,14,14)

        -- Tab header
        if tCfg.ShowTitle then
            local tHead = newFrame({
                Size   = UDim2.new(1,0,0,26),
                Color  = T.BG0,
                Alpha  = 1,
                Z      = 3,
                Parent = tPage,
            })
            newImage({
                Icon  = tCfg.Icon,
                Size  = UDim2.new(0,12,0,12),
                Position=UDim2.new(0,0,0.5,0),
                AnchorPoint=Vector2.new(0,0.5),
                Color = T.Ice,
                Z     = 4,
                Parent= tHead,
            })
            newText({
                Text     = tCfg.Name:upper(),
                Size     = UDim2.new(1,-20,0,14),
                Position = UDim2.new(0,20,0.5,0),
                AnchorPoint=Vector2.new(0,0.5),
                Font     = Enum.Font.GothamBold,
                TextSize = FS.TabHeader,
                Color    = T.TextHi,
                Z        = 4,
                Parent   = tHead,
            })
            -- Underline
            local headLine = newFrame({
                Size   = UDim2.new(1,0,0,1),
                Position=UDim2.new(0,0,1,-1),
                Color  = T.Ice,
                Alpha  = 0,
                Z      = 4,
                Parent = tHead,
            })
            newGradient(headLine, ColorSequence.new{
                ColorSequenceKeypoint.new(0,   T.Ice),
                ColorSequenceKeypoint.new(0.4, T.Border),
                ColorSequenceKeypoint.new(1,   T.Border),
            })
        end

        -- Build section API
        local secAPI = buildSectionAPI(tPage, T.Ice, T.Violet)
        for k,v in pairs(secAPI) do Tab[k] = v end
        function Tab:Activate() switchTab(id) end

        table.insert(W._tabs, {id=id, box=tBox, page=tPage, bar=tBar, icon=tIco})
        tClick.MouseButton1Click:Connect(function() Tab:Activate() end)

        tBox.MouseEnter:Connect(function()
            if W._activeTab ~= id then tw(tBox,{BackgroundTransparency=0.80},TI_FAST) end
            tooltipLabel.Text = tCfg.Name
            tooltip.Visible   = true
            tw(tooltip,{Position=UDim2.new(0,SBW+6,0,
                tBox.AbsolutePosition.Y-win.AbsolutePosition.Y+8)},TI_FAST)
        end)
        tBox.MouseLeave:Connect(function()
            if W._activeTab ~= id then tw(tBox,{BackgroundTransparency=1},TI_FAST) end
            tooltip.Visible = false
        end)

        return Tab
    end

    function W:SaveConfiguration() end
    function W:LoadConfiguration() end
    return W
end

-- ══════════════════════════════════════════════════════════════════════════════
-- DESTROY
-- ══════════════════════════════════════════════════════════════════════════════
function Sentence:Destroy()
    for _, conn in ipairs(self._conns) do
        pcall(function() conn:Disconnect() end)
    end
    self._conns = {}
    if self._notifHolder and self._notifHolder.Parent then
        self._notifHolder.Parent:Destroy()
    end
    self.Flags   = {}
    self.Options = {}
end

return Sentence

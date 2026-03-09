--[[
╔══════════════════════════════════════════════════════════════════╗
║  SENTENCE GUI · AKUMA EDITION  v3.0                             ║
║  悪魔 — Dark Anime UI Framework                                  ║
║  Compact · Vivid · Masterpiece                                   ║
╚══════════════════════════════════════════════════════════════════╝

  Theme: Deep indigo / neon magenta & cyan HUD aesthetic
  All elements redesigned for compactness and visual impact.
--]]

local Sentence = {
    Version = "3.0",
    Flags   = {},
    Options = {},
    _conns  = {},
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

-- ── Hex Color Helper ──────────────────────────────────────────────────────────
local function H(hex)
    hex = hex:gsub("#", "")
    return Color3.fromRGB(
        tonumber("0x"..hex:sub(1,2)),
        tonumber("0x"..hex:sub(3,4)),
        tonumber("0x"..hex:sub(5,6))
    )
end

-- ── Anime Theme ───────────────────────────────────────────────────────────────
-- Deep purple-black base, neon magenta primary, ice-cyan secondary
local T = {
    BG0      = H("#04040f"),  -- void black
    BG1      = H("#080818"),  -- base dark
    BG2      = H("#0d0d24"),  -- card bg
    BG3      = H("#141432"),  -- elevated
    BG4      = H("#1c1c44"),  -- hover

    Border   = H("#252558"),  -- subtle border
    BorderHi = H("#3a3a80"),  -- active border

    -- Primary: hot magenta (anime energy)
    Accent   = H("#e040fb"),  -- vivid magenta
    AccentDim= H("#8b1faa"),  -- dim magenta
    AccentLo = H("#1e0829"),  -- faint magenta bg

    -- Secondary: ice cyan
    Cyan     = H("#00e5ff"),  -- ice cyan
    CyanDim  = H("#0097a7"),  -- dim cyan
    CyanLo   = H("#021c20"),  -- faint cyan bg

    -- Status
    Success  = H("#00e676"),
    Warning  = H("#ffea00"),
    Error    = H("#ff1744"),

    -- Text
    TextHi   = H("#f0eeff"),  -- warm white
    TextMid  = H("#9090c0"),  -- muted lavender
    TextLo   = H("#3d3d70"),  -- dark lavender

    -- Decorative
    Pink     = H("#ff4081"),  -- sakura pink
    PinkDim  = H("#880e4f"),
}

-- ── Notification Palette ──────────────────────────────────────────────────────
local NotifPalette = {
    Info    = { fg=T.Cyan,    bg=T.BG2, stroke=T.Cyan,    iconBg=T.CyanLo  },
    Success = { fg=T.Success, bg=T.BG2, stroke=T.Success, iconBg=T.BG3     },
    Warning = { fg=T.Warning, bg=T.BG2, stroke=T.Warning, iconBg=T.BG3     },
    Error   = { fg=T.Error,   bg=T.BG2, stroke=T.Error,   iconBg=T.BG3     },
}

-- ── Tween Helpers ─────────────────────────────────────────────────────────────
local function TI(t,s,d) return TweenInfo.new(t or .18, s or Enum.EasingStyle.Exponential, d or Enum.EasingDirection.Out) end
local TI_SNAP   = TI(.10)
local TI_FAST   = TI(.16)
local TI_MED    = TI(.26)
local TI_SLOW   = TI(.46)
local TI_SPRING = TweenInfo.new(.38, Enum.EasingStyle.Back,     Enum.EasingDirection.Out)
local TI_CIRC   = TweenInfo.new(.30, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)
local TI_ELASTIC= TweenInfo.new(.50, Enum.EasingStyle.Elastic,  Enum.EasingDirection.Out)

local function tw(o, p, info, cb)
    local t = TS:Create(o, info or TI_MED, p)
    if cb then t.Completed:Once(cb) end
    t:Play(); return t
end

-- ── Utility ───────────────────────────────────────────────────────────────────
local function merge(d, t)
    t = t or {}
    for k,v in pairs(d) do if t[k] == nil then t[k] = v end end
    return t
end
local function track(c) table.insert(Sentence._conns, c); return c end
local function safe(cb, ...) local ok,e = pcall(cb,...); if not ok then warn("SENTENCE: "..tostring(e)) end end

-- ── Asset IDs ─────────────────────────────────────────────────────────────────
local LOGO  = "rbxassetid://117810891565979"
local ICONS = {
    close="rbxassetid://6031094678",  min="rbxassetid://6031094687",
    hide="rbxassetid://6031075929",   home="rbxassetid://6031079158",
    info="rbxassetid://6026568227",   warn="rbxassetid://6031071053",
    ok="rbxassetid://6031094667",     arr="rbxassetid://6031090995",
    unk="rbxassetid://6031079152",    notif="rbxassetid://6034308946",
    chev_d="rbxassetid://6031094687", chev_u="rbxassetid://6031094679",
    save="rbxassetid://6031280882",   reset="rbxassetid://6031094667",
    keyboard="rbxassetid://6026568227",
}
local function ico(n)
    if not n or n == "" then return "" end
    if n:find("rbxassetid") then return n end
    if tonumber(n) then return "rbxassetid://"..n end
    return ICONS[n] or ICONS.unk
end

-- ══════════════════════════════════════════════════════════════════════════════
-- PRIMITIVE BUILDERS
-- ══════════════════════════════════════════════════════════════════════════════
local function Box(p)
    p = p or {}
    local f = Instance.new("Frame")
    f.Name              = p.Name or "Box"
    f.Size              = p.Sz   or UDim2.new(1,0,0,34)
    f.Position          = p.Pos  or UDim2.new()
    f.AnchorPoint       = p.AP   or Vector2.zero
    f.BackgroundColor3  = p.Bg   or T.BG2
    f.BackgroundTransparency = p.BgA or 0
    f.BorderSizePixel   = 0
    f.ZIndex            = p.Z    or 1
    f.LayoutOrder       = p.Ord  or 0
    f.Visible           = p.Vis  ~= false
    if p.Clip  then f.ClipsDescendants = true end
    if p.AutoY then f.AutomaticSize = Enum.AutomaticSize.Y end
    if p.AutoX then f.AutomaticSize = Enum.AutomaticSize.X end
    if p.R ~= nil then
        local uc = Instance.new("UICorner")
        uc.CornerRadius = type(p.R) == "number" and UDim.new(0,p.R) or (p.R or UDim.new(0,4))
        uc.Parent = f
    end
    if p.Border then
        local s = Instance.new("UIStroke")
        s.Color     = p.BorderCol or T.Border
        s.Transparency = p.BorderA or 0
        s.Thickness = p.BorderW   or 1
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent    = f
    end
    if p.Par then f.Parent = p.Par end
    return f
end

local function Txt(p)
    p = p or {}
    local l = Instance.new("TextLabel")
    l.Name              = p.Name or "Txt"
    l.Text              = p.T    or ""
    l.Size              = p.Sz   or UDim2.new(1,0,0,14)
    l.Position          = p.Pos  or UDim2.new()
    l.AnchorPoint       = p.AP   or Vector2.zero
    l.Font              = p.Font or Enum.Font.GothamSemibold
    l.TextSize          = p.TS   or 14
    l.TextColor3        = p.Col  or T.TextHi
    l.TextTransparency  = p.Alpha or 0
    l.TextXAlignment    = p.AX   or Enum.TextXAlignment.Left
    l.TextYAlignment    = p.AY   or Enum.TextYAlignment.Center
    l.TextWrapped       = p.Wrap or false
    l.RichText          = false
    l.BackgroundTransparency = 1
    l.BorderSizePixel   = 0
    l.ZIndex            = p.Z    or 2
    l.LayoutOrder       = p.Ord  or 0
    if p.AutoY then l.AutomaticSize = Enum.AutomaticSize.Y end
    if p.AutoX then l.AutomaticSize = Enum.AutomaticSize.X end
    if p.Par   then l.Parent = p.Par end
    return l
end

local function Img(p)
    p = p or {}
    local i = Instance.new("ImageLabel")
    i.Name              = p.Name or "Img"
    i.Image             = ico(p.Ico or "")
    i.Size              = p.Sz   or UDim2.new(0,16,0,16)
    i.Position          = p.Pos  or UDim2.new(0.5,0,0.5,0)
    i.AnchorPoint       = p.AP   or Vector2.new(0.5,0.5)
    i.ImageColor3       = p.Col  or T.TextHi
    i.ImageTransparency = p.IA   or 0
    i.BackgroundTransparency = 1
    i.BorderSizePixel   = 0
    i.ZIndex            = p.Z    or 3
    i.ScaleType         = Enum.ScaleType.Fit
    if p.Par then i.Parent = p.Par end
    return i
end

local function Btn(par, z)
    local b = Instance.new("TextButton")
    b.Name   = "Btn"
    b.Size   = UDim2.new(1,0,1,0)
    b.BackgroundTransparency = 1
    b.Text   = ""
    b.ZIndex = z or 8
    b.Parent = par
    return b
end

local function List(par, gap, dir, ha, va)
    local l = Instance.new("UIListLayout")
    l.SortOrder    = Enum.SortOrder.LayoutOrder
    l.Padding      = UDim.new(0, gap or 4)
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

-- Dual-glow UIStroke: primary + inner faint glow layer
local function GlowStroke(parent, col, thick, trans)
    local s = Instance.new("UIStroke")
    s.Color = col or T.Accent
    s.Thickness = thick or 1
    s.Transparency = trans or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

-- Angular "slash" decoration: a thin rotated Frame for anime HUD feel
local function Slash(par, x, y, w, h, col, rot)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0,w,0,h)
    f.Position = UDim2.new(0,x,0,y)
    f.BackgroundColor3 = col or T.Accent
    f.BackgroundTransparency = 0
    f.BorderSizePixel = 0
    f.Rotation = rot or -45
    f.ZIndex = 10
    f.Parent = par
    return f
end

-- Small diamond ✦ decoration box
local function Diamond(par, x, y, sz, col)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0,sz or 5, 0,sz or 5)
    f.Position = UDim2.new(0,x,0,y)
    f.BackgroundColor3 = col or T.Accent
    f.BackgroundTransparency = 0
    f.BorderSizePixel = 0
    f.Rotation = 45
    f.ZIndex = 8
    f.Parent = par
    return f
end

local function Draggable(handle, win)
    local drag, ds, sp = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or
           i.UserInputType == Enum.UserInputType.Touch then
            drag = true; ds = i.Position; sp = win.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if (i.UserInputType == Enum.UserInputType.MouseMovement or
            i.UserInputType == Enum.UserInputType.Touch) and drag then
            local d = i.Position - ds
            TS:Create(win, TweenInfo.new(0.06, Enum.EasingStyle.Sine), {
                Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
            }):Play()
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or
           i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- SHARED SECTION BUILDER — Anime edition
-- Builds a full CreateSection API onto any ScrollingFrame page.
-- ══════════════════════════════════════════════════════════════════════════════
local function BuildSectionAPI(page, accentColor, secondColor)
    accentColor = accentColor or T.Accent
    secondColor = secondColor or T.Cyan
    local _sN = 0
    local API = {}

    -- ── Element base frame ────────────────────────────────────────────────────
    local function Elem(secCon, h, autoY)
        local f = Box({Sz=UDim2.new(1,0,0,h or 36), Bg=T.BG2, BgA=0, R=5, Z=3, Par=secCon})
        if autoY then f.AutomaticSize = Enum.AutomaticSize.Y end
        -- Anime-style: thin glowing left border stripe + subtle stroke
        local stripe = Box({Sz=UDim2.new(0,2,0.7,0), Pos=UDim2.new(0,0,0.15,0),
            Bg=accentColor, BgA=0.3, R=0, Z=5, Par=f})
        local es = GlowStroke(f, accentColor, 1, 0.80)
        return f, stripe, es
    end

    -- Hover animation (brightens bg + stripe + stroke)
    local function HoverEff(f, stripe, stroke)
        f.MouseEnter:Connect(function()
            tw(f, {BackgroundColor3=T.BG3}, TI_FAST)
            if stripe then tw(stripe, {BackgroundTransparency=0, BackgroundColor3=accentColor}, TI_FAST) end
            if stroke then tw(stroke, {Transparency=0.40}, TI_FAST) end
        end)
        f.MouseLeave:Connect(function()
            tw(f, {BackgroundColor3=T.BG2}, TI_FAST)
            if stripe then tw(stripe, {BackgroundTransparency=0.3}, TI_FAST) end
            if stroke then tw(stroke, {Transparency=0.80}, TI_FAST) end
        end)
    end

    -- ── CreateSection ─────────────────────────────────────────────────────────
    function API:CreateSection(sName)
        sName = sName or ""; _sN = _sN + 1
        local Sec = {}

        -- Section header spacer
        local shRow = Box({Name="SH", Sz=UDim2.new(1,0,0, sName~="" and 22 or 4), BgA=1, Z=3, Par=page})

        if sName ~= "" then
            -- Diagonal gradient line
            local line = Instance.new("Frame"); line.Size=UDim2.new(1,0,0,1)
            line.Position=UDim2.new(0,0,1,-1); line.BorderSizePixel=0; line.ZIndex=3; line.Parent=shRow
            local lg = Instance.new("UIGradient")
            lg.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, accentColor),
                ColorSequenceKeypoint.new(0.45, secondColor),
                ColorSequenceKeypoint.new(1, T.Border)}
            lg.Parent = line

            -- Japanese-style section number + name badge
            -- 「第01節」 aesthetic
            local badge = Box({Sz=UDim2.new(0,0,0,16), Pos=UDim2.new(0,0,0.5,0), AP=Vector2.new(0,0.5),
                Bg=T.BG0, R=0, Z=4, Par=shRow})
            badge.AutomaticSize = Enum.AutomaticSize.X; Pad(badge,0,0,0,8)

            local bRow = Instance.new("Frame"); bRow.Size=UDim2.new(0,0,1,0)
            bRow.AutomaticSize=Enum.AutomaticSize.X; bRow.BackgroundTransparency=1; bRow.ZIndex=5; bRow.Parent=badge
            List(bRow,0,Enum.FillDirection.Horizontal,nil,Enum.VerticalAlignment.Center)

            -- "✦ " prefix diamond accent
            local pre = Txt({T="✦ ", Sz=UDim2.new(0,0,1,0), Font=Enum.Font.Code, TS=10,
                Col=accentColor, AX=Enum.TextXAlignment.Center, AutoX=true, Z=5, Par=bRow})

            -- Section number
            local numL = Txt({T=string.format("%02d", _sN).."·", Sz=UDim2.new(0,0,1,0),
                Font=Enum.Font.GothamBold, TS=10, Col=secondColor, AutoX=true, Z=5, Par=bRow})

            -- Section name
            local nmL = Txt({T=" "..sName:upper(), Sz=UDim2.new(0,0,1,0),
                Font=Enum.Font.GothamBold, TS=10, Col=T.TextMid, AutoX=true, Z=5, Par=bRow})
        end

        -- Content container
        local secCon = Box({Name="SC", Sz=UDim2.new(1,0,0,0), BgA=1, Z=3, AutoY=true, Par=page})
        List(secCon, 4)

        -- ── Elements ──────────────────────────────────────────────────────────

        function Sec:CreateDivider()
            local d = Instance.new("Frame"); d.Size=UDim2.new(1,0,0,1)
            d.BackgroundColor3=T.Border; d.BackgroundTransparency=0
            d.BorderSizePixel=0; d.ZIndex=3; d.Parent=secCon
            local dg = Instance.new("UIGradient")
            dg.Color=ColorSequence.new{
                ColorSequenceKeypoint.new(0,accentColor),
                ColorSequenceKeypoint.new(0.5,secondColor),
                ColorSequenceKeypoint.new(1,T.BG1)}
            dg.Parent=d
            return {Destroy=function() d:Destroy() end}
        end

        function Sec:CreateLabel(lc)
            lc = merge({Name="",Text="",Style=1}, lc or {})
            local text = lc.Text~="" and lc.Text or lc.Name or ""
            local cMap = {[1]=T.TextMid, [2]=accentColor, [3]=T.Warning}
            local st   = lc.Style or 1
            local f, stripe, es = Elem(secCon, 30)

            -- Style accent: coloured left bar + tiny diamond
            if st > 1 then
                stripe.BackgroundColor3 = cMap[st]; stripe.BackgroundTransparency=0
                Diamond(f, -3, 30*0.15-2, 4, cMap[st])
            end

            local lb = Txt({T=text, Sz=UDim2.new(1,-24,0,14), Pos=UDim2.new(0,14,0.5,0), AP=Vector2.new(0,0.5),
                Font=Enum.Font.GothamSemibold, TS=13, Col=cMap[st], Z=4, Par=f})
            return {
                Set     = function(_, t2) lb.Text=t2 end,
                Destroy = function() f:Destroy() end,
            }
        end

        function Sec:CreateParagraph(pc)
            pc = merge({Title="Title",Content=""}, pc or {})
            local f, stripe, es = Elem(secCon, 0, true)
            Pad(f, 10, 10, 14, 14); List(f, 3)
            stripe.BackgroundTransparency = 0
            local pt  = Txt({T=pc.Title,   Sz=UDim2.new(1,0,0,16), Font=Enum.Font.GothamBold, TS=14, Col=T.TextHi, Z=4, Par=f})
            local pc2 = Txt({T=pc.Content, Sz=UDim2.new(1,0,0,0),  Font=Enum.Font.Gotham, TS=13, Col=T.TextMid, Z=4, Wrap=true, AutoY=true, Par=f})
            return {
                Set     = function(_,s) if s.Title then pt.Text=s.Title end; if s.Content then pc2.Text=s.Content end end,
                Destroy = function() f:Destroy() end,
            }
        end

        -- ── Button ────────────────────────────────────────────────────────────
        function Sec:CreateButton(bc)
            bc = merge({Name="Button",Description=nil,Callback=function()end}, bc or {})
            local h = bc.Description and 52 or 36
            local f, stripe, es = Elem(secCon, h)
            f.ClipsDescendants = true

            -- Anime sweep fill (left→right ripple on hover)
            local sweep = Box({Sz=UDim2.new(0,0,1,0), Bg=accentColor, BgA=1, R=0, Z=3, Par=f})
            local sweepG = Instance.new("UIGradient")
            sweepG.Transparency=NumberSequence.new{
                NumberSequenceKeypoint.new(0,0.72), NumberSequenceKeypoint.new(1,1)}
            sweepG.Parent = sweep

            -- Active left stripe (always visible, gets brighter on hover)
            stripe.BackgroundTransparency = 0

            -- Name label
            Txt({T=bc.Name,
                Sz=UDim2.new(1,-48,0,15),
                Pos=UDim2.new(0,14, 0, bc.Description and 8 or 10),
                Font=Enum.Font.GothamBold, TS=14, Col=T.TextHi, Z=5, Par=f})

            if bc.Description then
                Txt({T=bc.Description,
                    Sz=UDim2.new(1,-48,0,13),
                    Pos=UDim2.new(0,14,0,26),
                    Font=Enum.Font.Gotham, TS=12, Col=T.TextMid, Z=5, Par=f})
            end

            -- Arrow chevron right
            local arr = Img({Ico="arr", Sz=UDim2.new(0,11,0,11),
                Pos=UDim2.new(1,-16,0.5,0), AP=Vector2.new(0,0.5),
                Col=accentColor, IA=0.55, Z=6, Par=f})

            local cl = Btn(f, 7)

            f.MouseEnter:Connect(function()
                tw(sweep,{Size=UDim2.new(1,0,1,0)},TI(.24,Enum.EasingStyle.Quad))
                tw(stripe,{BackgroundColor3=secondColor},TI_FAST)
                tw(arr,{ImageTransparency=0, ImageColor3=T.TextHi},TI_FAST)
                tw(es,{Transparency=0.25},TI_FAST)
            end)
            f.MouseLeave:Connect(function()
                tw(sweep,{Size=UDim2.new(0,0,1,0)},TI_MED)
                tw(stripe,{BackgroundColor3=accentColor},TI_FAST)
                tw(arr,{ImageTransparency=0.55, ImageColor3=accentColor},TI_FAST)
                tw(es,{Transparency=0.80},TI_FAST)
            end)
            cl.MouseButton1Click:Connect(function()
                -- Click flash
                tw(sweep,{BackgroundColor3=T.TextHi},TI(.06,Enum.EasingStyle.Quad))
                task.wait(0.08)
                tw(sweep,{BackgroundColor3=accentColor,Size=UDim2.new(0,0,1,0)},TI_MED)
                safe(bc.Callback)
            end)
            return {Destroy=function() f:Destroy() end}
        end

        -- ── Toggle ────────────────────────────────────────────────────────────
        function Sec:CreateToggle(tc)
            tc = merge({Name="Toggle",Description=nil,CurrentValue=false,Flag=nil,Callback=function()end}, tc or {})
            local h = tc.Description and 52 or 36
            local f, stripe, es = Elem(secCon, h)

            Txt({T=tc.Name,
                Sz=UDim2.new(1,-68,0,15),
                Pos=UDim2.new(0,14, 0, tc.Description and 8 or 10),
                Font=Enum.Font.GothamBold, TS=14, Col=T.TextHi, Z=5, Par=f})
            if tc.Description then
                Txt({T=tc.Description,
                    Sz=UDim2.new(1,-68,0,13),
                    Pos=UDim2.new(0,14,0,26),
                    Font=Enum.Font.Gotham, TS=12, Col=T.TextMid, Z=5, Par=f})
            end

            -- Track (pill)
            local trk = Box({Sz=UDim2.new(0,40,0,20), Pos=UDim2.new(1,-52,0.5,0), AP=Vector2.new(0,0.5),
                Bg=T.BG3, R=10, Border=true, BorderCol=T.Border, BorderA=0.2, Z=5, Par=f})

            -- Inner glow bg when ON
            local trkGlow = Box({Sz=UDim2.new(1,0,1,0), Bg=accentColor, BgA=1, R=10, Z=5, Par=trk})
            local trkGlowG = Instance.new("UIGradient")
            trkGlowG.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.85),NumberSequenceKeypoint.new(1,1)}
            trkGlowG.Parent=trkGlow

            -- Knob
            local knob = Box({Sz=UDim2.new(0,14,0,14), Pos=UDim2.new(0,3,0.5,0), AP=Vector2.new(0,0.5),
                Bg=T.TextLo, R=7, Z=6, Par=trk})
            -- Knob inner dot
            local kCore = Box({Sz=UDim2.new(0,6,0,6), Pos=UDim2.new(0.5,0,0.5,0), AP=Vector2.new(0.5,0.5),
                Bg=T.TextHi, BgA=1, R=3, Z=7, Par=knob})

            local TV = {CurrentValue=tc.CurrentValue, Type="Toggle", Settings=tc}

            local function upd()
                if TV.CurrentValue then
                    tw(trk,  {BackgroundColor3=T.AccentLo},TI_MED)
                    local s = trk:FindFirstChildOfClass("UIStroke")
                    if s then tw(s,{Color=accentColor,Transparency=0},TI_MED) end
                    tw(trkGlow,{BackgroundTransparency=0.75},TI_MED)
                    tw(knob,{Position=UDim2.new(1,-17,0.5,0), BackgroundColor3=accentColor},TI_SPRING)
                    tw(kCore,{BackgroundTransparency=0},TI_FAST)
                    tw(stripe,{BackgroundColor3=accentColor, BackgroundTransparency=0},TI_FAST)
                    tw(es,{Transparency=0.45},TI_FAST)
                else
                    tw(trk,  {BackgroundColor3=T.BG3},TI_MED)
                    local s = trk:FindFirstChildOfClass("UIStroke")
                    if s then tw(s,{Color=T.Border,Transparency=0.2},TI_MED) end
                    tw(trkGlow,{BackgroundTransparency=1},TI_MED)
                    tw(knob,{Position=UDim2.new(0,3,0.5,0), BackgroundColor3=T.TextLo},TI_SPRING)
                    tw(kCore,{BackgroundTransparency=1},TI_FAST)
                    tw(stripe,{BackgroundTransparency=0.3},TI_FAST)
                    tw(es,{Transparency=0.80},TI_FAST)
                end
            end

            upd()
            HoverEff(f, stripe, es)
            Btn(f,6).MouseButton1Click:Connect(function()
                TV.CurrentValue = not TV.CurrentValue; upd(); safe(tc.Callback, TV.CurrentValue)
            end)
            function TV:Set(v) TV.CurrentValue=v; upd(); safe(tc.Callback,v) end
            if tc.Flag then Sentence.Flags[tc.Flag]=TV; Sentence.Options[tc.Flag]=TV end
            return TV
        end

        -- ── Slider ────────────────────────────────────────────────────────────
        function Sec:CreateSlider(sc)
            sc = merge({Name="Slider",Range={0,100},Increment=1,CurrentValue=50,Suffix="",Flag=nil,Callback=function()end}, sc or {})
            local f, stripe, es = Elem(secCon, 52)
            stripe.BackgroundTransparency = 0

            -- Top row: name
            Txt({T=sc.Name,
                Sz=UDim2.new(1,-90,0,15),
                Pos=UDim2.new(0,14,0,7),
                Font=Enum.Font.GothamBold, TS=14, Col=T.TextHi, Z=5, Par=f})

            -- Value badge (top-right)
            local vc = Box({Sz=UDim2.new(0,0,0,18), Pos=UDim2.new(1,-14,0,7), AP=Vector2.new(1,0),
                Bg=T.AccentLo, R=4,
                Border=true, BorderCol=T.AccentDim, BorderA=0.3,
                Z=5, Par=f})
            vc.AutomaticSize = Enum.AutomaticSize.X; Pad(vc,0,0,7,7)
            local vL = Txt({T=tostring(sc.CurrentValue)..sc.Suffix,
                Sz=UDim2.new(0,0,1,0),
                Font=Enum.Font.Code, TS=13, Col=accentColor,
                AX=Enum.TextXAlignment.Center, Z=6, Par=vc})
            vL.AutomaticSize = Enum.AutomaticSize.X

            -- Track
            local bg = Box({Sz=UDim2.new(1,-28,0,4), Pos=UDim2.new(0,14,0,36),
                Bg=T.BG3, R=2, Z=5, Par=f})

            -- Fill with dual-tone gradient
            local fill = Box({Sz=UDim2.new(0,0,1,0), Bg=accentColor, R=2, Z=6, Par=bg})
            local fillG = Instance.new("UIGradient")
            fillG.Color=ColorSequence.new{
                ColorSequenceKeypoint.new(0, accentColor),
                ColorSequenceKeypoint.new(1, secondColor)}
            fillG.Parent = fill

            -- Thumb (anime: diamond rotated)
            local thumb = Box({Sz=UDim2.new(0,10,0,10), Pos=UDim2.new(0,0,0.5,0), AP=Vector2.new(0.5,0.5),
                Bg=T.TextHi, R=0, Z=7, Par=bg})
            thumb.Rotation = 45
            local thS = GlowStroke(thumb, accentColor, 1.5, 0.3)

            local SV = {CurrentValue=sc.CurrentValue, Type="Slider", Settings=sc}
            local mn, mx, inc = sc.Range[1], sc.Range[2], sc.Increment

            local function setV(v)
                v = math.clamp(v, mn, mx)
                v = math.floor(v/inc + 0.5) * inc
                v = tonumber(string.format("%.10g", v)); SV.CurrentValue = v
                vL.Text = tostring(v)..sc.Suffix
                local pct = (v - mn) / (mx - mn)
                tw(fill,  {Size=UDim2.new(pct,0,1,0)}, TI_FAST)
                tw(thumb, {Position=UDim2.new(pct,0,0.5,0)}, TI_FAST)
            end
            setV(sc.CurrentValue)

            local drag = false
            local bCL = Btn(bg, 9)
            local function fromInp(i)
                local rel = math.clamp((i.Position.X-bg.AbsolutePosition.X)/bg.AbsoluteSize.X, 0, 1)
                setV(mn + (mx-mn)*rel); safe(sc.Callback, SV.CurrentValue)
            end

            bCL.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or
                   i.UserInputType == Enum.UserInputType.Touch then
                    drag = true; fromInp(i)
                    tw(thumb,{Size=UDim2.new(0,13,0,13)},TI_FAST)
                    tw(thS,{Transparency=0, Color=secondColor},TI_FAST)
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or
                   i.UserInputType == Enum.UserInputType.Touch then
                    drag = false
                    tw(thumb,{Size=UDim2.new(0,10,0,10)},TI_FAST)
                    tw(thS,{Transparency=0.3, Color=accentColor},TI_FAST)
                end
            end)
            track(UIS.InputChanged:Connect(function(i)
                if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or
                    i.UserInputType==Enum.UserInputType.Touch) then fromInp(i) end
            end))

            HoverEff(f, stripe, es)
            function SV:Set(v) setV(v); safe(sc.Callback, SV.CurrentValue) end
            if sc.Flag then Sentence.Flags[sc.Flag]=SV; Sentence.Options[sc.Flag]=SV end
            return SV
        end

        -- ── ColorPicker ───────────────────────────────────────────────────────
        function Sec:CreateColorPicker(cc2)
            cc2 = merge({Name="Color",Flag=nil,Color=Color3.new(1,1,1),Callback=function()end}, cc2 or {})
            local f, stripe, es = Elem(secCon, 36)

            Txt({T=cc2.Name, Sz=UDim2.new(1,-56,0,15), Pos=UDim2.new(0,14,0.5,0), AP=Vector2.new(0,0.5),
                Font=Enum.Font.GothamBold, TS=14, Col=T.TextHi, Z=5, Par=f})

            local swatch = Box({Sz=UDim2.new(0,22,0,22), Pos=UDim2.new(1,-38,0.5,0), AP=Vector2.new(0,0.5),
                Bg=cc2.Color, R=4,
                Border=true, BorderCol=T.Border, Z=5, Par=f})
            -- Checkered fallback pattern overlay
            local sS = GlowStroke(swatch, accentColor, 1, 0.5)

            HoverEff(f, stripe, es)
            local CV = {CurrentValue=cc2.Color, Type="ColorPicker", Settings=cc2}
            function CV:Set(c) CV.CurrentValue=c; swatch.BackgroundColor3=c; safe(cc2.Callback,c) end
            if cc2.Flag then Sentence.Flags[cc2.Flag]=CV; Sentence.Options[cc2.Flag]=CV end
            return CV
        end

        -- ── Keybind / CreateBind ──────────────────────────────────────────────
        function Sec:CreateBind(bc)
            bc = merge({
                Name="Keybind", Description=nil,
                CurrentBind="E", HoldToInteract=false,
                Flag=nil, Callback=function()end, OnChangedCallback=function()end,
            }, bc or {})

            local h = bc.Description and 52 or 36
            local f, stripe, es = Elem(secCon, h)

            Txt({T=bc.Name,
                Sz=UDim2.new(1,-104,0,15),
                Pos=UDim2.new(0,14,0, bc.Description and 8 or 10),
                Font=Enum.Font.GothamBold, TS=14, Col=T.TextHi, Z=5, Par=f})

            if bc.Description then
                Txt({T=bc.Description,
                    Sz=UDim2.new(1,-104,0,13),
                    Pos=UDim2.new(0,14,0,26),
                    Font=Enum.Font.Gotham, TS=12, Col=T.TextMid, Z=5, Par=f})
            end

            -- Keyboard key visual (anime HUD style)
            local pill = Box({Sz=UDim2.new(0,0,0,22), Pos=UDim2.new(1,-12,0.5,0), AP=Vector2.new(1,0.5),
                Bg=T.BG3, R=4,
                Border=true, BorderCol=T.AccentDim, BorderA=0.45,
                Z=5, Par=f})
            pill.AutomaticSize = Enum.AutomaticSize.X; Pad(pill,0,0,8,8)

            -- Key top-inset shadow (keyboard feel)
            local keyTop = Box({Sz=UDim2.new(1,0,0,2), Pos=UDim2.new(0,0,0,0),
                Bg=T.BG0, BgA=0.5, R=0, Z=6, Par=pill})

            local keyTxt = Txt({T=bc.CurrentBind,
                Sz=UDim2.new(0,0,1,0),
                Font=Enum.Font.Code, TS=13, Col=accentColor,
                AX=Enum.TextXAlignment.Center, AutoX=true, Z=7, Par=pill})

            -- HOLD badge
            local holdBadge
            if bc.HoldToInteract then
                holdBadge = Box({Sz=UDim2.new(0,0,0,11), Pos=UDim2.new(1,-12,1,-3), AP=Vector2.new(1,1),
                    Bg=T.AccentLo, R=2, Border=true, BorderCol=T.AccentDim, BorderA=0.5, Z=6, Par=f})
                holdBadge.AutomaticSize = Enum.AutomaticSize.X; Pad(holdBadge,0,0,3,3)
                Txt({T="HOLD", Sz=UDim2.new(0,0,1,0), Font=Enum.Font.GothamBold, TS=8,
                    Col=accentColor, AX=Enum.TextXAlignment.Center, AutoX=true, Z=7, Par=holdBadge})
            end

            -- State
            local BV = {CurrentBind=bc.CurrentBind, Type="Bind", Settings=bc}
            local listening = false
            local holdActive = false

            local function setListening(v)
                listening = v
                if v then
                    tw(pill,{BackgroundColor3=T.AccentLo},TI_FAST)
                    local s=pill:FindFirstChildOfClass("UIStroke")
                    if s then tw(s,{Color=accentColor,Transparency=0.1},TI_FAST) end
                    keyTxt.Text = "···"
                    tw(keyTxt,{TextColor3=secondColor},TI_FAST)
                else
                    tw(pill,{BackgroundColor3=T.BG3},TI_FAST)
                    local s=pill:FindFirstChildOfClass("UIStroke")
                    if s then tw(s,{Color=T.AccentDim,Transparency=0.45},TI_FAST) end
                    keyTxt.Text = BV.CurrentBind
                    tw(keyTxt,{TextColor3=accentColor},TI_FAST)
                end
            end

            local pillBtn = Btn(pill, 8)
            pillBtn.MouseButton1Click:Connect(function()
                if listening then setListening(false); return end
                setListening(true)
            end)

            pill.MouseEnter:Connect(function()
                if not listening then
                    local s=pill:FindFirstChildOfClass("UIStroke")
                    if s then tw(s,{Transparency=0.1},TI_FAST) end
                end
            end)
            pill.MouseLeave:Connect(function()
                if not listening then
                    local s=pill:FindFirstChildOfClass("UIStroke")
                    if s then tw(s,{Transparency=0.45},TI_FAST) end
                end
            end)

            track(UIS.InputBegan:Connect(function(inp, proc)
                if listening then
                    if inp.UserInputType == Enum.UserInputType.Keyboard then
                        local kn = inp.KeyCode.Name
                        if kn == "Escape" then setListening(false); return end
                        BV.CurrentBind = kn; setListening(false); safe(bc.OnChangedCallback, kn)
                    end
                    return
                end
                if proc then return end
                if inp.UserInputType == Enum.UserInputType.Keyboard
                   and inp.KeyCode.Name == BV.CurrentBind then
                    holdActive = true; safe(bc.Callback, true)
                end
            end))
            track(UIS.InputEnded:Connect(function(inp)
                if bc.HoldToInteract and inp.UserInputType == Enum.UserInputType.Keyboard
                   and inp.KeyCode.Name == BV.CurrentBind and holdActive then
                    holdActive = false; safe(bc.Callback, false)
                end
            end))

            HoverEff(f, stripe, es)
            function BV:Set(keyName) BV.CurrentBind=keyName; keyTxt.Text=keyName; safe(bc.OnChangedCallback,keyName) end
            function BV:Destroy() f:Destroy() end
            if bc.Flag then Sentence.Flags[bc.Flag]=BV; Sentence.Options[bc.Flag]=BV end
            return BV
        end
        Sec.CreateKeybind = Sec.CreateBind

        -- ── Input ─────────────────────────────────────────────────────────────
        function Sec:CreateInput(ic)
            ic = merge({
                Name="Input", Description=nil,
                PlaceholderText="Type here…", CurrentValue="",
                Numeric=false, MaxCharacters=nil,
                Enter=false, RemoveTextAfterFocusLost=false,
                Flag=nil, Callback=function()end,
            }, ic or {})

            local h = ic.Description and 66 or 52
            local f, stripe, es = Elem(secCon, h)
            stripe.BackgroundTransparency = 0

            Txt({T=ic.Name,
                Sz=UDim2.new(1,-24,0,14),
                Pos=UDim2.new(0,14,0,7),
                Font=Enum.Font.GothamBold, TS=13, Col=T.TextHi, Z=5, Par=f})

            if ic.Description then
                Txt({T=ic.Description,
                    Sz=UDim2.new(1,-24,0,12),
                    Pos=UDim2.new(0,14,0,22),
                    Font=Enum.Font.Gotham, TS=12, Col=T.TextMid, Z=5, Par=f})
            end

            local fieldY = ic.Description and 37 or 24
            local fieldH = 20

            -- Underline-style input field
            local fieldBg = Box({
                Sz=UDim2.new(1,-28,0,fieldH),
                Pos=UDim2.new(0,14,0,fieldY),
                Bg=T.BG1, R=3,
                Border=true, BorderCol=T.Border, BorderA=0.3,
                Z=5, Par=f})
            Pad(fieldBg, 0,0,8, ic.Numeric and 26 or 8)

            -- Left accent pip
            Box({Sz=UDim2.new(0,2,1,0), Pos=UDim2.new(0,0,0,0), Bg=accentColor, BgA=0.5, R=0, Z=6, Par=fieldBg})

            -- Numeric badge
            if ic.Numeric then
                local nb = Box({Sz=UDim2.new(0,18,1,0), Pos=UDim2.new(1,0,0,0), AP=Vector2.new(1,0),
                    Bg=T.AccentLo, R=3, Z=6, Par=fieldBg})
                Txt({T="#", Sz=UDim2.new(1,0,1,0), Font=Enum.Font.GothamBold, TS=10,
                    Col=accentColor, AX=Enum.TextXAlignment.Center, Z=7, Par=nb})
            end

            local tb = Instance.new("TextBox")
            tb.Name="InputBox"; tb.Size=UDim2.new(1,0,1,0)
            tb.BackgroundTransparency=1; tb.BorderSizePixel=0
            tb.PlaceholderText=ic.PlaceholderText; tb.PlaceholderColor3=T.TextLo
            tb.Text=ic.CurrentValue; tb.Font=Enum.Font.Code; tb.TextSize=12
            tb.TextColor3=T.TextHi; tb.TextXAlignment=Enum.TextXAlignment.Left
            tb.ClearTextOnFocus=false; tb.ZIndex=7; tb.Parent=fieldBg

            local IV = {CurrentValue=ic.CurrentValue, Type="Input", Settings=ic}

            tb.Focused:Connect(function()
                local s=fieldBg:FindFirstChildOfClass("UIStroke")
                if s then tw(s,{Color=accentColor,Transparency=0},TI_FAST) end
                tw(fieldBg,{BackgroundColor3=T.BG2},TI_FAST)
                tw(es,{Transparency=0.35},TI_FAST)
            end)
            tb.FocusLost:Connect(function(ep)
                local s=fieldBg:FindFirstChildOfClass("UIStroke")
                if s then tw(s,{Color=T.Border,Transparency=0.3},TI_FAST) end
                tw(fieldBg,{BackgroundColor3=T.BG1},TI_FAST)
                tw(es,{Transparency=0.80},TI_FAST)
                local val=tb.Text
                if ic.Numeric then val=val:gsub("[^%d%.%-]",""); tb.Text=val end
                if ic.MaxCharacters and #val>ic.MaxCharacters then val=val:sub(1,ic.MaxCharacters); tb.Text=val end
                IV.CurrentValue=val
                if ic.RemoveTextAfterFocusLost then tb.Text=""; IV.CurrentValue="" end
                if ic.Enter then if ep then safe(ic.Callback,val) end else safe(ic.Callback,val) end
            end)

            if ic.Numeric then
                tb:GetPropertyChangedSignal("Text"):Connect(function()
                    local c=tb.Text:gsub("[^%d%.%-]",""); if c~=tb.Text then tb.Text=c end
                    if ic.MaxCharacters and #tb.Text>ic.MaxCharacters then tb.Text=tb.Text:sub(1,ic.MaxCharacters) end
                end)
            elseif ic.MaxCharacters then
                tb:GetPropertyChangedSignal("Text"):Connect(function()
                    if #tb.Text>ic.MaxCharacters then tb.Text=tb.Text:sub(1,ic.MaxCharacters) end
                end)
            end

            HoverEff(f, stripe, es)
            function IV:Set(v)
                v=tostring(v)
                if ic.MaxCharacters and #v>ic.MaxCharacters then v=v:sub(1,ic.MaxCharacters) end
                tb.Text=v; IV.CurrentValue=v
            end
            function IV:Destroy() f:Destroy() end
            if ic.Flag then Sentence.Flags[ic.Flag]=IV; Sentence.Options[ic.Flag]=IV end
            return IV
        end

        -- ── Dropdown ──────────────────────────────────────────────────────────
        function Sec:CreateDropdown(dc)
            dc = merge({
                Name="Dropdown", Description=nil,
                Options={"Option 1","Option 2"},
                CurrentOption=nil, MultipleOptions=false,
                SpecialType=nil, Flag=nil,
                Callback=function()end,
            }, dc or {})

            local function resolveOptions()
                if dc.SpecialType == "Player" then
                    local t={}
                    for _,p in ipairs(Plrs:GetPlayers()) do t[#t+1]=p.Name end
                    return t
                end
                return dc.Options
            end

            local opts = resolveOptions()
            local function defaultSel()
                if dc.MultipleOptions then return {} end
                return opts[1] or ""
            end
            local currentSel = dc.CurrentOption ~= nil and dc.CurrentOption or defaultSel()

            local baseH = dc.Description and 66 or 52
            local f, stripe, es = Elem(secCon, baseH, true)

            Txt({T=dc.Name,
                Sz=UDim2.new(1,-24,0,14),
                Pos=UDim2.new(0,14,0,7),
                Font=Enum.Font.GothamBold, TS=13, Col=T.TextHi, Z=5, Par=f})
            if dc.Description then
                Txt({T=dc.Description,
                    Sz=UDim2.new(1,-24,0,12),
                    Pos=UDim2.new(0,14,0,22),
                    Font=Enum.Font.Gotham, TS=12, Col=T.TextMid, Z=5, Par=f})
            end

            local headerY = dc.Description and 37 or 24
            local headerH = 22

            local headerBar = Box({
                Sz=UDim2.new(1,-28,0,headerH),
                Pos=UDim2.new(0,14,0,headerY),
                Bg=T.BG1, R=4,
                Border=true, BorderCol=T.Border, BorderA=0.3,
                Z=5, Par=f})
            Pad(headerBar,0,0,10,30)
            Box({Sz=UDim2.new(0,2,1,0), Pos=UDim2.new(0,0,0,0), Bg=accentColor, BgA=0.5, R=0, Z=6, Par=headerBar})

            local dispTxt = Txt({T="", Sz=UDim2.new(1,0,1,0),
                Font=Enum.Font.Code, TS=12, Col=T.TextHi, Z=6, Par=headerBar})

            -- Chevron
            local chev = Img({Ico="chev_d",
                Sz=UDim2.new(0,10,0,10),
                Pos=UDim2.new(1,-16,0.5,0), AP=Vector2.new(0.5,0.5),
                Col=T.TextLo, Z=7, Par=headerBar})

            -- Drop panel
            local panel = Box({Name="DropPanel",
                Sz=UDim2.new(1,-28,0,0),
                Pos=UDim2.new(0,14,0,headerY+headerH+3),
                Bg=T.BG1, R=4,
                Border=true, BorderCol=T.AccentDim, BorderA=0.3,
                Z=10, Clip=true, Par=f})
            panel.Visible=false; panel.AutomaticSize=Enum.AutomaticSize.None

            local panelScroll = Instance.new("ScrollingFrame")
            panelScroll.Size=UDim2.new(1,0,1,0); panelScroll.BackgroundTransparency=1
            panelScroll.BorderSizePixel=0; panelScroll.ScrollBarThickness=2
            panelScroll.ScrollBarImageColor3=T.Border
            panelScroll.CanvasSize=UDim2.new(0,0,0,0); panelScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
            panelScroll.ZIndex=11; panelScroll.Parent=panel
            List(panelScroll,2); Pad(panelScroll,3,3,4,4)

            local DV = {CurrentOption=currentSel, Type="Dropdown", Settings=dc, _open=false, _items={}}

            local function dispStr()
                if dc.MultipleOptions then
                    if type(currentSel)=="table" and #currentSel>0 then return table.concat(currentSel,", ") end
                    return "None"
                else
                    return tostring(currentSel)
                end
            end
            local function isSelected(opt)
                if dc.MultipleOptions then
                    for _,v in ipairs(currentSel) do if v==opt then return true end end
                    return false
                else
                    return currentSel==opt
                end
            end

            local rebuildItems
            local function openPanel()
                DV._open=true; panel.Visible=true
                local mx2=math.min(#DV._items,5)
                local panH=mx2*24+(mx2+1)*2+6
                panel.Size=UDim2.new(1,-28,0,0)
                tw(panel,{Size=UDim2.new(1,-28,0,panH)},TI_SPRING)
                tw(chev,{Rotation=180, ImageColor3=accentColor},TI_FAST)
                local s=headerBar:FindFirstChildOfClass("UIStroke")
                if s then tw(s,{Color=accentColor,Transparency=0.1},TI_FAST) end
            end
            local function closePanel()
                DV._open=false
                tw(panel,{Size=UDim2.new(1,-28,0,0)},TI_MED,function() panel.Visible=false end)
                tw(chev,{Rotation=0, ImageColor3=T.TextLo},TI_FAST)
                local s=headerBar:FindFirstChildOfClass("UIStroke")
                if s then tw(s,{Color=T.Border,Transparency=0.3},TI_FAST) end
            end

            rebuildItems = function()
                for _,i in ipairs(DV._items) do pcall(function() i:Destroy() end) end
                DV._items={}
                for _,opt in ipairs(resolveOptions()) do
                    local row = Box({Sz=UDim2.new(1,0,0,24), Bg=T.BG2, R=3, Z=12, Par=panelScroll})
                    row.BackgroundTransparency=isSelected(opt) and 0 or 1

                    -- Selected indicator: small left bar
                    local selBar=Box({Sz=UDim2.new(0,2,0.6,0), Pos=UDim2.new(0,0,0.2,0),
                        Bg=accentColor, BgA=isSelected(opt) and 0 or 1, R=0, Z=13, Par=row})

                    local tick=Img({Ico="ok",
                        Sz=UDim2.new(0,9,0,9),
                        Pos=UDim2.new(1,-13,0.5,0), AP=Vector2.new(0.5,0.5),
                        Col=accentColor, IA=isSelected(opt) and 0 or 1,
                        Z=13, Par=row})

                    Txt({T=opt, Sz=UDim2.new(1,-28,1,0), Pos=UDim2.new(0,10,0,0),
                        Font=Enum.Font.GothamSemibold, TS=12,
                        Col=isSelected(opt) and T.TextHi or T.TextMid, Z=13, Par=row})

                    local rowBtn=Btn(row,14)
                    row.MouseEnter:Connect(function()
                        if not isSelected(opt) then tw(row,{BackgroundTransparency=0.7,BackgroundColor3=T.BG3},TI_FAST) end
                    end)
                    row.MouseLeave:Connect(function()
                        if not isSelected(opt) then tw(row,{BackgroundTransparency=1},TI_FAST) end
                    end)
                    rowBtn.MouseButton1Click:Connect(function()
                        if dc.MultipleOptions then
                            if type(currentSel)~="table" then currentSel={} end
                            local found=false
                            for i2,v in ipairs(currentSel) do
                                if v==opt then table.remove(currentSel,i2); found=true; break end
                            end
                            if not found then currentSel[#currentSel+1]=opt end
                            DV.CurrentOption=currentSel; dispTxt.Text=dispStr()
                            safe(dc.Callback,currentSel); rebuildItems()
                        else
                            currentSel=opt; DV.CurrentOption=opt; dispTxt.Text=dispStr()
                            safe(dc.Callback,opt); closePanel()
                        end
                    end)
                    DV._items[#DV._items+1]=row
                end
            end

            rebuildItems(); dispTxt.Text=dispStr()
            local hBtn=Btn(headerBar,8)
            hBtn.MouseButton1Click:Connect(function()
                if DV._open then closePanel() else openPanel() end
            end)
            headerBar.MouseEnter:Connect(function() tw(headerBar,{BackgroundColor3=T.BG2},TI_FAST) end)
            headerBar.MouseLeave:Connect(function() tw(headerBar,{BackgroundColor3=T.BG1},TI_FAST) end)

            function DV:Set(options)
                currentSel=dc.MultipleOptions and (type(options)=="table" and options or {options}) or options
                DV.CurrentOption=currentSel; dispTxt.Text=dispStr()
                if DV._open then rebuildItems() end; safe(dc.Callback,currentSel)
            end
            function DV:Refresh(newOpts)
                dc.Options=newOpts or dc.Options
                local was=DV._open; if was then closePanel() end
                currentSel=defaultSel(); DV.CurrentOption=currentSel; dispTxt.Text=dispStr()
                rebuildItems(); if was then task.wait(0.05); openPanel() end
            end
            function DV:Destroy() f:Destroy() end
            HoverEff(f, stripe, es)
            if dc.Flag then Sentence.Flags[dc.Flag]=DV; Sentence.Options[dc.Flag]=DV end
            return DV
        end

        return Sec
    end

    -- Default section shortcut
    local _ds
    local function gds() if not _ds then _ds=API:CreateSection("") end; return _ds end
    for _,m in ipairs({
        "CreateButton","CreateLabel","CreateParagraph","CreateToggle",
        "CreateSlider","CreateDivider","CreateColorPicker",
        "CreateBind","CreateKeybind","CreateInput","CreateDropdown"
    }) do
        API[m]=function(self,...) return gds()[m](gds(),...) end
    end
    return API
end

-- ══════════════════════════════════════════════════════════════════════════════
-- NOTIFICATIONS  —  Anime floating cards
-- ══════════════════════════════════════════════════════════════════════════════
function Sentence:Notify(data)
    task.spawn(function()
        data = merge({Title="Notice",Content="",Icon="info",Type="Info",Duration=5}, data)
        local pal = NotifPalette[data.Type] or NotifPalette.Info

        local card = Box({Name="NCard", Sz=UDim2.new(0,288,0,0),
            Pos=UDim2.new(-1.2,0,1,0), AP=Vector2.new(0,1),
            Bg=T.BG1, BgA=1, Clip=true, R=6, Par=self._notifHolder})

        -- Glowing border
        local cS = GlowStroke(card, pal.stroke, 1, 1)

        -- Dark anime diagonal bg pattern (subtle)
        local bgFill = Box({Sz=UDim2.new(1,0,1,0), Bg=pal.bg, BgA=1, R=6, Z=1, Par=card})

        -- Left neon bar
        local acBar = Box({Sz=UDim2.new(0,2,1,0), Pos=UDim2.new(0,0,0,0), Bg=pal.fg, BgA=1, R=0, Z=8, Par=card})

        -- Side glow
        local sideG = Box({Sz=UDim2.new(0,70,1,0), Pos=UDim2.new(0,2,0,0), Bg=pal.fg, BgA=1, R=0, Z=2, Par=card})
        local sg=Instance.new("UIGradient")
        sg.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.88),NumberSequenceKeypoint.new(1,1)}
        sg.Parent=sideG

        -- Icon ring
        local iRing = Box({Sz=UDim2.new(0,24,0,24), Pos=UDim2.new(0,10,0,0), AP=Vector2.new(0,0.5),
            Bg=pal.iconBg, BgA=1, R=4, Z=6, Par=card})
        local iRS = GlowStroke(iRing, pal.fg, 1, 1)
        local iIco = Img({Ico=data.Icon, Sz=UDim2.new(0,11,0,11), Col=pal.fg, IA=1, Z=7, Par=iRing})

        -- Content
        local cc = Box({Name="CC", Sz=UDim2.new(1,0,0,0), Pos=UDim2.new(0,0,0,0), BgA=1, AutoY=true, Z=5, Par=card})
        Pad(cc,8,10,46,28); List(cc,1)

        -- Type badge
        local tBadge = Box({Sz=UDim2.new(0,0,0,12), Bg=pal.fg, BgA=1, R=2, Z=6, AutoX=true, Par=cc})
        Pad(tBadge,0,0,4,4)
        local tL=Txt({T=data.Type:upper(), Sz=UDim2.new(0,0,1,0), Font=Enum.Font.GothamBold, TS=9,
            Col=T.BG0, AX=Enum.TextXAlignment.Center, Alpha=1, AutoX=true, Z=7, Par=tBadge})

        local ttl=Txt({T=data.Title, Sz=UDim2.new(1,0,0,15), Font=Enum.Font.GothamBold, TS=13, Col=T.TextHi, Alpha=1, Z=6, Par=cc})
        local msg=Txt({T=data.Content, Sz=UDim2.new(1,0,0,0), Font=Enum.Font.Gotham, TS=12, Col=T.TextMid, Alpha=1, Wrap=true, AutoY=true, Z=6, Par=cc})

        -- Progress bar
        local pTrack=Box({Sz=UDim2.new(1,0,0,1), Pos=UDim2.new(0,0,1,-1), Bg=T.BG3, BgA=1, R=0, Z=6, Par=card})
        local pFill =Box({Sz=UDim2.new(1,0,1,0), Bg=pal.fg, BgA=1, R=0, Z=7, Par=pTrack})

        -- X button
        local xBtn=Box({Sz=UDim2.new(0,14,0,14), Pos=UDim2.new(1,-7,0,7), AP=Vector2.new(1,0),
            Bg=T.BG3, BgA=1, R=3, Z=9, Par=card})
        local xIco=Img({Ico="close", Sz=UDim2.new(0,6,0,6), Col=T.TextLo, Z=10, Par=xBtn})
        local xCL=Btn(xBtn,11)
        xBtn.MouseEnter:Connect(function() tw(xBtn,{BackgroundColor3=T.Error},TI_FAST); tw(xIco,{ImageColor3=T.TextHi},TI_FAST) end)
        xBtn.MouseLeave:Connect(function() tw(xBtn,{BackgroundColor3=T.BG3},TI_FAST); tw(xIco,{ImageColor3=T.TextLo},TI_FAST) end)

        task.wait()
        local cardH = cc.AbsoluteSize.Y + 4
        iRing.Position = UDim2.new(0,10,0,cardH/2-12)
        card.Size = UDim2.new(0,288,0,cardH); card.Position = UDim2.new(-1.2,0,1,0)

        for _,el in ipairs({bgFill,acBar,sideG,iRing,tBadge}) do el.BackgroundTransparency=1 end
        iIco.ImageTransparency=1; tL.TextTransparency=1; ttl.TextTransparency=1
        msg.TextTransparency=1; pTrack.BackgroundTransparency=1; pFill.BackgroundTransparency=1
        xBtn.BackgroundTransparency=1; xIco.ImageTransparency=1

        tw(card,{Position=UDim2.new(0,0,1,0)},TI_CIRC); task.wait(0.07)
        local TI_IN=TI(.20,Enum.EasingStyle.Exponential)
        for _,el in ipairs({bgFill,acBar,sideG,iRing}) do tw(el,{BackgroundTransparency=0},TI_IN) end
        tw(iRS,{Transparency=0.35},TI_IN); tw(iIco,{ImageTransparency=0},TI_IN)
        tw(tBadge,{BackgroundTransparency=0},TI_IN); tw(tL,{TextTransparency=0},TI_IN)
        tw(ttl,{TextTransparency=0},TI_IN); tw(msg,{TextTransparency=0},TI_IN)
        tw(pTrack,{BackgroundTransparency=0.6},TI_IN); tw(pFill,{BackgroundTransparency=0},TI_IN)
        tw(cS,{Transparency=0.45},TI_IN); tw(xBtn,{BackgroundTransparency=0},TI_IN); tw(xIco,{ImageTransparency=0},TI_IN)
        tw(pFill,{Size=UDim2.new(0,0,1,0)},TI(data.Duration,Enum.EasingStyle.Linear))

        local paused,dismissed,elapsed=false,false,0
        card.MouseEnter:Connect(function() paused=true;  tw(card,{BackgroundColor3=T.BG2},TI_FAST) end)
        card.MouseLeave:Connect(function() paused=false; tw(card,{BackgroundColor3=T.BG1},TI_FAST) end)
        xCL.MouseButton1Click:Connect(function() dismissed=true end)
        repeat task.wait(0.05); if not paused then elapsed=elapsed+0.05 end
        until dismissed or elapsed>=data.Duration

        local TI_OUT=TI(.16,Enum.EasingStyle.Quad)
        for _,el in ipairs({bgFill,acBar,sideG,iRing,tBadge,pTrack,pFill,xBtn}) do tw(el,{BackgroundTransparency=1},TI_OUT) end
        tw(iRS,{Transparency=1},TI_OUT); tw(iIco,{ImageTransparency=1},TI_OUT)
        tw(tL,{TextTransparency=1},TI_OUT); tw(ttl,{TextTransparency=1},TI_OUT)
        tw(msg,{TextTransparency=1},TI_OUT); tw(cS,{Transparency=1},TI_OUT); tw(xIco,{ImageTransparency=1},TI_OUT)
        tw(card,{BackgroundColor3=T.BG1,Position=UDim2.new(-1.2,0,1,0)},TI(.20,Enum.EasingStyle.Quad,Enum.EasingDirection.In))
        task.wait(0.22)
        tw(card,{Size=UDim2.new(0,288,0,0)},TI_MED,function() card:Destroy() end)
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
    local WW = math.clamp(vp.X - 90, 560, 780)
    local WH = math.clamp(vp.Y - 70, 400, 520)
    local FULL = UDim2.fromOffset(WW, WH)
    local TB_H = 40      -- compact title bar
    local SB_W = 44      -- compact sidebar
    local MINI = UDim2.fromOffset(WW, TB_H + 2)

    -- ── ScreenGui ─────────────────────────────────────────────────────────────
    local gui = Instance.new("ScreenGui")
    gui.Name="SentenceAkumaUI"; gui.DisplayOrder=999999999
    gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true
    if gethui then gui.Parent=gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(gui); gui.Parent=CG
    elseif not IsStudio then gui.Parent=CG
    else gui.Parent=LP:WaitForChild("PlayerGui") end

    -- ══════════════════════════════════════════════════════════════════════════
    -- ANIME SPLASH SCREEN
    -- Full reimagining: energy rings, katakana, glitch flicker
    -- ══════════════════════════════════════════════════════════════════════════
    task.spawn(function()
        local alive = true
        local spConns = {}

        local splash = Instance.new("Frame")
        splash.Name="Splash"; splash.Size=UDim2.new(1,0,1,0)
        splash.BackgroundColor3=T.BG0; splash.BackgroundTransparency=1
        splash.BorderSizePixel=0; splash.ZIndex=1000; splash.ClipsDescendants=true; splash.Parent=gui

        -- Scanline overlay
        local scanlines = Instance.new("Frame")
        scanlines.Size=UDim2.new(1,0,1,0); scanlines.BackgroundTransparency=1
        scanlines.BorderSizePixel=0; scanlines.ZIndex=1030; scanlines.Parent=splash
        for i=1,28 do
            local sl=Instance.new("Frame")
            sl.Size=UDim2.new(1,0,0,1); sl.Position=UDim2.new(0,0,0,(i-1)/28,0)
            sl.BackgroundColor3=T.BG0; sl.BackgroundTransparency=0.86
            sl.BorderSizePixel=0; sl.ZIndex=1031; sl.Parent=scanlines
        end

        -- Ambient glow background
        local glow = Box({Sz=UDim2.new(0,600,0,300), Pos=UDim2.new(0.5,0,0.5,0),
            AP=Vector2.new(0.5,0.5), Bg=T.Accent, BgA=1, R=999, Z=1001, Par=splash})
        local gg=Instance.new("UIGradient")
        gg.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.78),NumberSequenceKeypoint.new(1,1)}
        gg.Parent=glow

        local glow2 = Box({Sz=UDim2.new(0,400,0,200), Pos=UDim2.new(0.5,0,0.5,0),
            AP=Vector2.new(0.5,0.5), Bg=T.Cyan, BgA=1, R=999, Z=1001, Par=splash})
        local gg2=Instance.new("UIGradient")
        gg2.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.85),NumberSequenceKeypoint.new(1,1)}
        gg2.Parent=glow2

        -- Center logo holder
        local logoHolder = Instance.new("Frame")
        logoHolder.Size=UDim2.new(0,64,0,64)
        logoHolder.Position=UDim2.new(0.5,0,0.44,0); logoHolder.AnchorPoint=Vector2.new(0.5,0.5)
        logoHolder.BackgroundTransparency=1; logoHolder.ZIndex=1005; logoHolder.Parent=splash

        -- Outer energy ring
        local ro1 = Box({Sz=UDim2.new(1,36,1,36), Pos=UDim2.new(0.5,0,0.5,0), AP=Vector2.new(0.5,0.5),
            BgA=1, R=999, Z=1005, Par=logoHolder})
        local ro1S=Instance.new("UIStroke"); ro1S.Color=T.Accent; ro1S.Thickness=1.5; ro1S.Transparency=0.2; ro1S.Parent=ro1
        local ro1G=Instance.new("UIGradient")
        ro1G.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.4,0),NumberSequenceKeypoint.new(0.75,0.9),NumberSequenceKeypoint.new(1,0)}
        ro1G.Parent=ro1S

        -- Inner ring
        local ri1 = Box({Sz=UDim2.new(1,12,1,12), Pos=UDim2.new(0.5,0,0.5,0), AP=Vector2.new(0.5,0.5),
            BgA=1, R=999, Z=1005, Par=logoHolder})
        local ri1S=Instance.new("UIStroke"); ri1S.Color=T.Cyan; ri1S.Thickness=1; ri1S.Transparency=0.35; ri1S.Parent=ri1
        local ri1G=Instance.new("UIGradient")
        ri1G.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.88),NumberSequenceKeypoint.new(0.3,0),NumberSequenceKeypoint.new(0.7,0),NumberSequenceKeypoint.new(1,0.88)}
        ri1G.Parent=ri1S

        -- Logo image
        local limg=Instance.new("ImageLabel"); limg.Size=UDim2.new(1,0,1,0)
        limg.BackgroundTransparency=1; limg.Image=LOGO; limg.ImageTransparency=1
        limg.ScaleType=Enum.ScaleType.Fit; limg.ZIndex=1008; limg.Parent=logoHolder
        Instance.new("UICorner",limg).CornerRadius=UDim.new(0,8)

        -- Corner angle decorators (anime HUD brackets)
        local corners = {
            {ax=0,ay=0,rx=30,ry=30}, {ax=1,ay=0,rx=-30,ry=30},
            {ax=0,ay=1,rx=30,ry=-30},{ax=1,ay=1,rx=-30,ry=-30},
        }
        local cFrames={}
        for _,c in ipairs(corners) do
            local cf=Instance.new("Frame"); cf.Size=UDim2.new(0,22,0,22)
            cf.Position=UDim2.new(c.ax,c.rx,c.ay,c.ry); cf.AnchorPoint=Vector2.new(c.ax,c.ay)
            cf.BackgroundTransparency=1; cf.ZIndex=1010; cf.Parent=splash
            -- Horizontal line
            local hf=Instance.new("Frame"); hf.Size=UDim2.new(1,0,0,1.5)
            hf.Position=c.ay==0 and UDim2.new(0,0,0,0) or UDim2.new(0,0,1,-1)
            hf.BackgroundColor3=T.Accent; hf.BackgroundTransparency=1
            hf.BorderSizePixel=0; hf.ZIndex=1011; hf.Parent=cf
            -- Vertical line
            local vf=Instance.new("Frame"); vf.Size=UDim2.new(0,1.5,1,0)
            vf.Position=c.ax==0 and UDim2.new(0,0,0,0) or UDim2.new(1,-1,0,0)
            vf.BackgroundColor3=T.Cyan; vf.BackgroundTransparency=1
            vf.BorderSizePixel=0; vf.ZIndex=1011; vf.Parent=cf
            cFrames[#cFrames+1]={h=hf,v=vf}
        end

        -- Title word: S-E-N-T-E-N-C-E rendered letter by letter
        local titleRow=Instance.new("Frame"); titleRow.Size=UDim2.new(0,420,0,0)
        titleRow.Position=UDim2.new(0.5,0,0.44,80); titleRow.AnchorPoint=Vector2.new(0.5,0)
        titleRow.BackgroundTransparency=1; titleRow.AutomaticSize=Enum.AutomaticSize.XY; titleRow.ZIndex=1004; titleRow.Parent=splash

        local innerRow=Instance.new("Frame"); innerRow.Size=UDim2.new(0,0,0,0)
        innerRow.BackgroundTransparency=1; innerRow.AutomaticSize=Enum.AutomaticSize.XY; innerRow.ZIndex=1005; innerRow.Parent=titleRow
        innerRow.AnchorPoint=Vector2.new(0.5,0); innerRow.Position=UDim2.new(0.5,0,0,0)
        List(innerRow,0,Enum.FillDirection.Horizontal,nil,Enum.VerticalAlignment.Center)

        local CHARS={"S","E","N","T","E","N","C","E"}; local charLbls={}
        for i,ch in ipairs(CHARS) do
            local l=Instance.new("TextLabel"); l.Text=ch; l.Size=UDim2.new(0,0,0,0)
            l.AutomaticSize=Enum.AutomaticSize.XY
            l.Font=Enum.Font.GothamBold; l.TextSize=44; l.TextColor3=T.TextHi
            l.TextTransparency=1; l.BackgroundTransparency=1; l.BorderSizePixel=0
            l.ZIndex=1006; l.LayoutOrder=i; l.RichText=false; l.Parent=innerRow; charLbls[i]=l
        end
        -- AKUMA suffix
        local spSpc=Instance.new("Frame"); spSpc.Size=UDim2.new(0,12,0,1); spSpc.BackgroundTransparency=1; spSpc.LayoutOrder=9; spSpc.Parent=innerRow
        local akuma=Instance.new("TextLabel"); akuma.Text="悪魔"
        akuma.Size=UDim2.new(0,0,0,0); akuma.AutomaticSize=Enum.AutomaticSize.XY
        akuma.Font=Enum.Font.GothamBold; akuma.TextSize=28; akuma.TextColor3=T.Accent
        akuma.TextTransparency=1; akuma.BackgroundTransparency=1; akuma.BorderSizePixel=0
        akuma.ZIndex=1006; akuma.LayoutOrder=10; akuma.RichText=false; akuma.Parent=innerRow

        -- Accent underline
        local acLine=Instance.new("Frame"); acLine.Size=UDim2.new(0,0,0,1.5)
        acLine.Position=UDim2.new(0.5,0,0,50); acLine.AnchorPoint=Vector2.new(0.5,0)
        acLine.BackgroundColor3=T.Accent; acLine.BackgroundTransparency=1
        acLine.BorderSizePixel=0; acLine.ZIndex=1005; acLine.Parent=titleRow
        local acLG=Instance.new("UIGradient")
        acLG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.Accent),ColorSequenceKeypoint.new(0.5,T.Cyan),ColorSequenceKeypoint.new(1,T.Pink)}
        acLG.Parent=acLine
        Instance.new("UICorner",acLine).CornerRadius=UDim.new(1,0)

        -- Status + progress
        local stat=Instance.new("TextLabel"); stat.Text="初期化中"
        stat.Size=UDim2.new(1,0,0,20); stat.Position=UDim2.new(0.5,0,0,58); stat.AnchorPoint=Vector2.new(0.5,0)
        stat.Font=Enum.Font.Code; stat.TextSize=11; stat.TextColor3=T.TextMid; stat.TextTransparency=1
        stat.BackgroundTransparency=1; stat.BorderSizePixel=0; stat.ZIndex=1005
        stat.TextXAlignment=Enum.TextXAlignment.Center; stat.RichText=false; stat.Parent=titleRow

        local pw=Instance.new("Frame"); pw.Size=UDim2.new(0,240,0,2); pw.Position=UDim2.new(0.5,0,0,82)
        pw.AnchorPoint=Vector2.new(0.5,0); pw.BackgroundColor3=T.BG3; pw.BackgroundTransparency=1
        pw.BorderSizePixel=0; pw.ZIndex=1005; pw.Parent=titleRow
        Instance.new("UICorner",pw).CornerRadius=UDim.new(1,0)
        local pf=Instance.new("Frame"); pf.Size=UDim2.new(0,0,1,0); pf.BackgroundColor3=T.Accent
        pf.BackgroundTransparency=1; pf.BorderSizePixel=0; pf.ZIndex=1006; pf.Parent=pw
        Instance.new("UICorner",pf).CornerRadius=UDim.new(1,0)
        local pfG=Instance.new("UIGradient")
        pfG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.Accent),ColorSequenceKeypoint.new(0.5,T.Cyan),ColorSequenceKeypoint.new(1,T.Pink)}
        pfG.Parent=pf

        -- Floating particles
        local parts={}
        for pi=1,9 do
            local px=Instance.new("Frame"); px.Size=UDim2.new(0,math.random(2,5),0,math.random(2,5))
            px.Position=UDim2.new(math.random(10,90)/100,0,math.random(10,90)/100,0); px.AnchorPoint=Vector2.new(0.5,0.5)
            local col = pi%3==0 and T.Cyan or pi%3==1 and T.Accent or T.Pink
            px.BackgroundColor3=col; px.BackgroundTransparency=0.4+math.random()*0.4
            px.BorderSizePixel=0; px.ZIndex=1002; px.Rotation=45; px.Parent=splash
            Instance.new("UICorner",px).CornerRadius=UDim.new(0,0)
            parts[pi]={f=px,bx=math.random(10,90)/100,by=math.random(10,90)/100,ph=math.random()*math.pi*2,sp=0.22+math.random()*0.32,rg=0.012+math.random()*0.016}
        end

        -- Animation loop
        local rsC = RS.RenderStepped:Connect(function(dt)
            if not alive then return end
            ro1.Rotation = ro1.Rotation + 72 * dt
            ri1.Rotation = ri1.Rotation - 44 * dt
            local pulse = 0.80 + math.sin(tick()*2.8)*0.08
            local mp = UIS:GetMouseLocation(); local vs = Cam.ViewportSize
            glow.Position  = UDim2.new(0.5,(mp.X/vs.X-0.5)*40,0.5,(mp.Y/vs.Y-0.5)*20)
            glow2.Position = UDim2.new(0.5,(mp.X/vs.X-0.5)*-28,0.5,(mp.Y/vs.Y-0.5)*-14)
            for _,p in ipairs(parts) do
                local tt=tick()*p.sp+p.ph
                p.f.Position=UDim2.new(p.bx+math.sin(tt)*p.rg,0,p.by+math.cos(tt*1.3)*p.rg,0)
                p.f.Rotation = p.f.Rotation + 30*dt
            end
        end)
        table.insert(spConns, rsC)

        -- ── Reveal sequence ───────────────────────────────────────────────────
        tw(splash,{BackgroundTransparency=0},TI(.35,Enum.EasingStyle.Quad)); task.wait(0.12)
        for _,c in ipairs(cFrames) do
            tw(c.h,{BackgroundTransparency=0},TI(.40,Enum.EasingStyle.Exponential))
            tw(c.v,{BackgroundTransparency=0},TI(.40,Enum.EasingStyle.Exponential))
        end; task.wait(0.14)
        tw(glow,{BackgroundTransparency=0.76},TI(.55,Enum.EasingStyle.Quad))
        tw(glow2,{BackgroundTransparency=0.82},TI(.55,Enum.EasingStyle.Quad)); task.wait(0.06)
        tw(ro1S,{Transparency=0},TI_MED); tw(ri1S,{Transparency=0},TI_MED)
        tw(logoHolder,{Size=UDim2.new(0,160,0,160)},TI_SPRING)
        tw(limg,{ImageTransparency=0},TI(.45,Enum.EasingStyle.Exponential)); task.wait(0.26)

        for i,l in ipairs(charLbls) do
            task.spawn(function()
                task.wait((i-1)*0.05)
                -- Glitch flicker effect
                l.TextColor3=T.Cyan; tw(l,{TextTransparency=0},TI(.12,Enum.EasingStyle.Back))
                task.wait(0.06); tw(l,{TextColor3=T.TextHi},TI(.10))
            end)
        end; task.wait(0.44)
        tw(akuma,{TextTransparency=0},TI(.30,Enum.EasingStyle.Back)); task.wait(0.12)
        tw(acLine,{Size=UDim2.new(0,300,0,1.5),BackgroundTransparency=0},TI(.40,Enum.EasingStyle.Exponential)); task.wait(0.08)
        tw(stat,{TextTransparency=0.3},TI_MED)
        tw(pw,{BackgroundTransparency=0},TI_FAST); tw(pf,{BackgroundTransparency=0},TI_FAST)

        -- Progress steps with Japanese labels
        local steps={
            {l="モジュール確認中",p=0.20},{l="スクリプト注入中",p=0.42},
            {l="アセット読込中",p=0.64},  {l="UI構築中",p=0.86},
            {l="完了 ✦",p=1.0},
        }
        for _,s in ipairs(steps) do
            tw(stat,{TextTransparency=1},TI(.06,Enum.EasingStyle.Quad)); task.wait(0.07)
            stat.Text=s.l
            tw(stat,{TextTransparency=0.3},TI(.09,Enum.EasingStyle.Quad))
            tw(pf,{Size=UDim2.new(s.p,0,1,0)},TI(.34,Enum.EasingStyle.Quad))
            task.wait(s.p==1 and 0.34 or 0.26)
        end; task.wait(0.36)

        -- ── Outro ─────────────────────────────────────────────────────────────
        alive=false
        for _,c in ipairs(spConns) do pcall(function() c:Disconnect() end) end

        -- Reverse letter hide
        for i=#charLbls,1,-1 do
            task.spawn(function()
                task.wait((#charLbls-i)*0.035)
                tw(charLbls[i],{TextTransparency=1},TI(.14,Enum.EasingStyle.Quad))
            end)
        end
        tw(akuma,{TextTransparency=1},TI(.14,Enum.EasingStyle.Quad))
        tw(acLine,{BackgroundTransparency=1,Size=UDim2.new(0,0,0,1.5)},TI(.28,Enum.EasingStyle.Exponential)); task.wait(0.12)
        tw(stat,{TextTransparency=1},TI_FAST); tw(pf,{BackgroundTransparency=1},TI_FAST); tw(pw,{BackgroundTransparency=1},TI_FAST)
        tw(limg,{ImageTransparency=1},TI(.24,Enum.EasingStyle.Quad))
        tw(ro1S,{Transparency=1},TI(.20)); tw(ri1S,{Transparency=1},TI(.20))
        for _,c in ipairs(cFrames) do tw(c.h,{BackgroundTransparency=1},TI(.18)); tw(c.v,{BackgroundTransparency=1},TI(.18)) end
        for _,p in ipairs(parts) do tw(p.f,{BackgroundTransparency=1},TI(.16)) end; task.wait(0.14)
        tw(glow,{BackgroundTransparency=1},TI(.28,Enum.EasingStyle.Quad))
        tw(glow2,{BackgroundTransparency=1},TI(.28,Enum.EasingStyle.Quad))
        tw(splash,{BackgroundTransparency=1},TI(.38,Enum.EasingStyle.Quad),function() splash:Destroy() end)
    end)

    -- ── Notif holder ──────────────────────────────────────────────────────────
    local notifHolder=Instance.new("Frame"); notifHolder.Name="Notifs"
    notifHolder.Size=UDim2.new(0,298,1,-14); notifHolder.Position=UDim2.new(0,10,1,-7)
    notifHolder.AnchorPoint=Vector2.new(0,1); notifHolder.BackgroundTransparency=1; notifHolder.ZIndex=200; notifHolder.Parent=gui
    local nList=List(notifHolder,5); nList.VerticalAlignment=Enum.VerticalAlignment.Bottom
    self._notifHolder=notifHolder

    -- ══════════════════════════════════════════════════════════════════════════
    -- MAIN WINDOW
    -- ══════════════════════════════════════════════════════════════════════════
    local win=Box({Name="SentenceWin", Sz=UDim2.fromOffset(0,0), Pos=UDim2.new(0.5,0,0.5,0),
        AP=Vector2.new(0.5,0.5), Bg=T.BG1, BgA=0, Clip=true, R=6,
        Border=true, BorderCol=T.Border, BorderA=0, Z=1, Par=gui})

    -- Vivid top accent line: magenta→cyan gradient
    local topLine=Box({Name="TopLine", Sz=UDim2.new(1,0,0,1.5), Pos=UDim2.new(0,0,0,0),
        Bg=T.Accent, BgA=0, Z=10, Par=win})
    local tlG=Instance.new("UIGradient")
    tlG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.Accent),ColorSequenceKeypoint.new(0.5,T.Cyan),ColorSequenceKeypoint.new(1,T.Pink)}
    tlG.Parent=topLine

    -- Corner ambient glow
    local winGlow=Box({Name="WinGlow",Sz=UDim2.new(0,220,0,120),Pos=UDim2.new(0,0,0,0),
        Bg=T.Accent,BgA=0.92,R=0,Z=0,Par=win})
    local wgG=Instance.new("UIGradient"); wgG.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.90),NumberSequenceKeypoint.new(1,1)}; wgG.Rotation=130; wgG.Parent=winGlow

    -- ── Title Bar ─────────────────────────────────────────────────────────────
    local titleBar=Box({Name="TitleBar", Sz=UDim2.new(1,0,0,TB_H), Pos=UDim2.new(0,0,0,1.5),
        Bg=T.BG1, BgA=1, Z=4, Par=win})
    Draggable(titleBar, win)

    -- Bottom separator: gradient bar
    local tbLine=Instance.new("Frame"); tbLine.Size=UDim2.new(1,0,0,1); tbLine.Position=UDim2.new(0,0,1,-1)
    tbLine.BackgroundColor3=T.Border; tbLine.BackgroundTransparency=0; tbLine.BorderSizePixel=0; tbLine.ZIndex=5; tbLine.Parent=titleBar
    local tbLG=Instance.new("UIGradient")
    tbLG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.Accent),ColorSequenceKeypoint.new(0.3,T.Border),ColorSequenceKeypoint.new(1,T.Border)}
    tbLG.Parent=tbLine

    -- ── Window control buttons ────────────────────────────────────────────────
    local ctrlBtns={}
    local CBTN_W=22; local CBTN_GAP=5; local CBTN_MARGIN=10
    local CTRL_DEFS={
        {key="−", ico="rbxassetid://6031094687", hBg=T.AccentDim, hCol=T.TextHi},
        {key="·", ico="rbxassetid://6031075929", hBg=T.BG4,       hCol=T.Cyan  },
        {key="X", ico="rbxassetid://6031094678", hBg=T.Error,     hCol=T.TextHi},
    }
    for idx,cd in ipairs(CTRL_DEFS) do
        local fromR = CBTN_MARGIN + (3-idx)*(CBTN_W+CBTN_GAP)
        local cb = Box({Name=cd.key, Sz=UDim2.new(0,CBTN_W,0,CBTN_W), Pos=UDim2.new(1,-fromR-CBTN_W,0.5,0),
            AP=Vector2.new(0,0.5), Bg=T.BG3, BgA=0, R=4, Z=5, Par=titleBar})
        local cbS = GlowStroke(cb, T.Border, 1, 0.5)
        local cbI = Img({Ico=cd.ico, Sz=UDim2.new(0,10,0,10), Col=T.TextLo, IA=0, Z=6, Par=cb})
        task.spawn(function() tw(cbI,{ImageTransparency=0},TI_MED) end)
        local cl=Btn(cb,7)
        cb.MouseEnter:Connect(function() tw(cb,{BackgroundColor3=cd.hBg,BackgroundTransparency=0},TI_FAST); tw(cbI,{ImageColor3=cd.hCol},TI_FAST); tw(cbS,{Color=cd.hBg,Transparency=0.3},TI_FAST) end)
        cb.MouseLeave:Connect(function() tw(cb,{BackgroundColor3=T.BG3,BackgroundTransparency=0},TI_FAST); tw(cbI,{ImageColor3=T.TextLo},TI_FAST); tw(cbS,{Color=T.Border,Transparency=0.5},TI_FAST) end)
        ctrlBtns[cd.key]={frame=cb,click=cl,ico=cbI}
    end

    -- Logo + Title
    local LSIZ=28; local LCTR=22
    local logoImg=Instance.new("ImageLabel"); logoImg.Name="Logo"
    logoImg.Size=UDim2.new(0,LSIZ,0,LSIZ); logoImg.Position=UDim2.new(0,LCTR-LSIZ/2,0.5,0); logoImg.AnchorPoint=Vector2.new(0,0.5)
    logoImg.BackgroundTransparency=1; logoImg.Image=cfg.Icon~="" and ico(cfg.Icon) or LOGO
    logoImg.ScaleType=Enum.ScaleType.Fit; logoImg.ImageTransparency=1; logoImg.ZIndex=5; logoImg.Parent=titleBar
    Instance.new("UICorner",logoImg).CornerRadius=UDim.new(0,4)
    task.spawn(function() tw(logoImg,{ImageTransparency=0},TI_MED) end)

    local txX = LCTR + LSIZ/2 + 8
    local nameLabel=Txt({T=cfg.Name, Sz=UDim2.new(0,200,0,18), Pos=UDim2.new(0,txX,0,4),
        Font=Enum.Font.GothamBold, TS=15, Col=T.TextHi, Alpha=1, Z=5, Par=titleBar})
    local subStr = cfg.Subtitle~="" and cfg.Subtitle or ("v"..Sentence.Version.." · 悪魔")
    local subLabel=Txt({T=subStr, Sz=UDim2.new(0,180,0,12), Pos=UDim2.new(0,txX,0,23),
        Font=Enum.Font.Code, TS=11, Col=T.TextLo, Alpha=1, Z=5, Par=titleBar})

    -- ── Sidebar ───────────────────────────────────────────────────────────────
    local sidebar=Box({Name="Sidebar", Sz=UDim2.new(0,SB_W,1,-TB_H-1.5), Pos=UDim2.new(0,0,0,TB_H+1.5),
        Bg=T.BG2, BgA=0, Z=3, Par=win})

    -- Sidebar right border (gradient)
    local sbBorder=Instance.new("Frame"); sbBorder.Size=UDim2.new(0,1,1,0); sbBorder.Position=UDim2.new(1,-1,0,0)
    sbBorder.BackgroundColor3=T.Border; sbBorder.BackgroundTransparency=0; sbBorder.BorderSizePixel=0; sbBorder.ZIndex=5; sbBorder.Parent=sidebar
    local sbBG=Instance.new("UIGradient")
    sbBG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.Accent),ColorSequenceKeypoint.new(0.4,T.Border),ColorSequenceKeypoint.new(1,T.Border)}
    sbBG.Rotation=90; sbBG.Parent=sbBorder

    local tabList=Instance.new("ScrollingFrame"); tabList.Name="TabList"
    tabList.Size=UDim2.new(1,0,1,-50); tabList.Position=UDim2.new(0,0,0,12)
    tabList.BackgroundTransparency=1; tabList.BorderSizePixel=0; tabList.ScrollBarThickness=0
    tabList.AutomaticCanvasSize=Enum.AutomaticSize.Y; tabList.ZIndex=4; tabList.Parent=sidebar
    List(tabList,3,Enum.FillDirection.Vertical,Enum.HorizontalAlignment.Center); Pad(tabList,4,4,0,0)

    -- Avatar at bottom of sidebar
    local avBox=Box({Sz=UDim2.new(0,30,0,30), Pos=UDim2.new(0.5,0,1,-10), AP=Vector2.new(0.5,1),
        Bg=T.BG3, R=4, Z=4, Par=sidebar})
    local avImg=Instance.new("ImageLabel"); avImg.Size=UDim2.new(1,0,1,0); avImg.BackgroundTransparency=1; avImg.ZIndex=5; avImg.Parent=avBox
    Instance.new("UICorner",avImg).CornerRadius=UDim.new(0,4)
    local avS=GlowStroke(avImg,T.Accent,1,0.4)
    pcall(function() avImg.Image=Plrs:GetUserThumbnailAsync(LP.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size48x48) end)

    -- Tooltip
    local tooltip=Box({Name="TT", Sz=UDim2.new(0,0,0,24), Pos=UDim2.new(0,SB_W+5,0,0),
        Bg=T.BG3, R=4, Border=true, BorderCol=T.Accent, BorderA=0.5, Z=20, Vis=false, Par=win})
    tooltip.AutomaticSize=Enum.AutomaticSize.X; Pad(tooltip,0,0,9,9)
    local ttL=Txt({T="", Sz=UDim2.new(0,0,1,0), Font=Enum.Font.GothamBold, TS=13, Col=T.TextHi, Z=21, Par=tooltip})
    ttL.AutomaticSize=Enum.AutomaticSize.X

    -- Content area
    local contentArea=Box({Name="Content", Sz=UDim2.new(1,-SB_W-1,1,-TB_H-1.5), Pos=UDim2.new(0,SB_W+1,0,TB_H+1.5),
        Bg=T.BG1, BgA=1, Clip=true, Z=2, Par=win})

    local W={_gui=gui,_win=win,_content=contentArea,_tabs={},_activeTab=nil,_visible=true,_minimized=false,_cfg=cfg}

    -- Tab switcher
    local function SwitchTab(id)
        for _,tab in ipairs(W._tabs) do
            if tab.id==id then
                tab.page.Visible=true
                tw(tab.bar,{BackgroundTransparency=0},TI_FAST)
                tw(tab.ico,{ImageColor3=T.Accent},TI_FAST)
                tw(tab.box,{BackgroundColor3=T.AccentLo,BackgroundTransparency=0},TI_FAST)
                local s=tab.box:FindFirstChildOfClass("UIStroke"); if s then tw(s,{Color=T.Accent,Transparency=0.4},TI_FAST) end
                W._activeTab=id
            else
                tab.page.Visible=false
                tw(tab.bar,{BackgroundTransparency=1},TI_FAST)
                tw(tab.ico,{ImageColor3=T.TextLo},TI_FAST)
                tw(tab.box,{BackgroundColor3=T.BG3,BackgroundTransparency=1},TI_FAST)
                local s=tab.box:FindFirstChildOfClass("UIStroke"); if s then tw(s,{Color=T.Border,Transparency=0.6},TI_FAST) end
            end
        end
    end

    -- ── Loading Screen ────────────────────────────────────────────────────────
    if cfg.LoadingEnabled then
        local lf=Box({Name="Loading",Sz=UDim2.new(1,0,1,0),Bg=T.BG1,BgA=0,Z=50,Par=win})
        Instance.new("UICorner",lf).CornerRadius=UDim.new(0,6)
        local lIco=Img({Ico=cfg.Icon,Sz=UDim2.new(0,28,0,28),Pos=UDim2.new(0.5,0,0.5,-46),AP=Vector2.new(0.5,0.5),Col=T.TextHi,Z=51,Par=lf})
        local lT=Txt({T=cfg.LoadingTitle,    Sz=UDim2.new(1,0,0,24),Pos=UDim2.new(0.5,0,0.5,-12),AP=Vector2.new(0.5,0.5),
            Font=Enum.Font.GothamBold,TS=22,Col=T.TextHi,AX=Enum.TextXAlignment.Center,Alpha=1,Z=51,Par=lf})
        local lS=Txt({T=cfg.LoadingSubtitle, Sz=UDim2.new(1,0,0,14),Pos=UDim2.new(0.5,0,0.5,14),AP=Vector2.new(0.5,0.5),
            Font=Enum.Font.Code,TS=13,Col=T.TextMid,AX=Enum.TextXAlignment.Center,Alpha=1,Z=51,Par=lf})
        local pTrk=Box({Sz=UDim2.new(0.4,0,0,2),Pos=UDim2.new(0.5,0,0.5,40),AP=Vector2.new(0.5,0.5),Bg=T.BG3,R=1,Z=51,Par=lf})
        local pFlL=Box({Sz=UDim2.new(0,0,1,0),Bg=T.Accent,R=1,Z=52,Par=pTrk})
        local pFlG=Instance.new("UIGradient"); pFlG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.Accent),ColorSequenceKeypoint.new(0.5,T.Cyan),ColorSequenceKeypoint.new(1,T.Pink)}; pFlG.Parent=pFlL
        local pctL=Txt({T="0%",Sz=UDim2.new(1,0,0,14),Pos=UDim2.new(0.5,0,0.5,52),AP=Vector2.new(0.5,0.5),
            Font=Enum.Font.Code,TS=12,Col=T.Accent,AX=Enum.TextXAlignment.Center,Z=51,Par=lf})
        tw(win,{Size=FULL},TI_SLOW); task.wait(0.28)
        tw(lT,{TextTransparency=0},TI_MED); task.wait(0.08); tw(lS,{TextTransparency=0.3},TI_MED)
        if cfg.Icon~="" then tw(lIco,{ImageTransparency=0},TI_MED) end
        local pct=0
        for _,s in ipairs({0.12,0.08,0.16,0.10,0.18,0.12,0.10,0.14}) do
            pct=math.min(pct+s,1); tw(pFlL,{Size=UDim2.new(pct,0,1,0)},TI(.24,Enum.EasingStyle.Quad))
            pctL.Text=math.floor(pct*100).."%"; task.wait(0.12+math.random()*0.09)
        end
        pctL.Text="100%"; tw(pFlL,{Size=UDim2.new(1,0,1,0)},TI_FAST); task.wait(0.28)
        tw(pFlL,{BackgroundColor3=T.TextHi},TI_FAST); task.wait(0.07)
        tw(lT,{TextTransparency=1},TI_FAST); tw(lS,{TextTransparency=1},TI_FAST)
        tw(pctL,{TextTransparency=1},TI_FAST); tw(pTrk,{BackgroundTransparency=1},TI_FAST); tw(pFlL,{BackgroundTransparency=1},TI_FAST)
        if cfg.Icon~="" then tw(lIco,{ImageTransparency=1},TI_FAST) end
        task.wait(0.18); tw(lf,{BackgroundTransparency=1},TI_MED,function() lf:Destroy() end); task.wait(0.28)
    else
        tw(win,{Size=FULL},TI_SLOW); task.wait(0.32)
    end

    tw(topLine,{BackgroundTransparency=0},TI_MED)
    tw(nameLabel,{TextTransparency=0},TI_MED)
    tw(subLabel,{TextTransparency=0},TI_MED)

    -- ── Window actions: close / minimize / hide ───────────────────────────────
    local function DoClose()
        local bl=Instance.new("Frame"); bl.Size=UDim2.new(1,0,1,0); bl.BackgroundTransparency=1; bl.ZIndex=900; bl.Parent=gui; Btn(bl,901)
        local ov=Box({Sz=UDim2.new(1,0,1,0),Bg=T.BG0,BgA=1,Z=500,Par=win}); Instance.new("UICorner",ov).CornerRadius=UDim.new(0,6)
        local oL=Instance.new("ImageLabel"); oL.Size=UDim2.new(0,46,0,46); oL.Position=UDim2.new(0.5,0,0.5,-60); oL.AnchorPoint=Vector2.new(0.5,0.5); oL.BackgroundTransparency=1; oL.Image=LOGO; oL.ScaleType=Enum.ScaleType.Fit; oL.ImageTransparency=1; oL.ZIndex=501; oL.Parent=ov
        local oN=Txt({T=cfg.Name,    Sz=UDim2.new(1,0,0,22),Pos=UDim2.new(0.5,0,0.5,-22),AP=Vector2.new(0.5,0.5),Font=Enum.Font.GothamBold,TS=20,Col=T.TextHi,AX=Enum.TextXAlignment.Center,Alpha=1,Z=501,Par=ov})
        local oS=Txt({T="終了中…",   Sz=UDim2.new(1,0,0,14),Pos=UDim2.new(0.5,0,0.5,4), AP=Vector2.new(0.5,0.5),Font=Enum.Font.Code,TS=12,Col=T.TextLo,AX=Enum.TextXAlignment.Center,Alpha=1,Z=501,Par=ov})
        local cl2=Box({Sz=UDim2.new(0,180,0,1.5),Pos=UDim2.new(0.5,0,0.5,28),AP=Vector2.new(0.5,0.5),Bg=T.BG3,R=1,Z=501,Par=ov})
        local cf=Box({Sz=UDim2.new(0,0,1,0),Bg=T.Accent,R=1,Z=502,Par=cl2})
        local cfG=Instance.new("UIGradient"); cfG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.Accent),ColorSequenceKeypoint.new(1,T.Error)}; cfG.Parent=cf
        local ws=win:FindFirstChildOfClass("UIStroke"); if ws then tw(ws,{Color=T.Error,Transparency=0.2},TI_MED) end
        tw(ov,{BackgroundTransparency=0},TI(.18,Enum.EasingStyle.Quad)); tw(oL,{ImageTransparency=0},TI_MED); tw(oN,{TextTransparency=0},TI_MED); tw(oS,{TextTransparency=0},TI_MED); tw(cl2,{BackgroundTransparency=0},TI_FAST); tw(cf,{BackgroundTransparency=0},TI_FAST); task.wait(0.10)
        tw(cf,{Size=UDim2.new(1,0,1,0)},TI(.50,Enum.EasingStyle.Quad)); task.wait(0.26); oS.Text="またね。"; tw(cf,{BackgroundColor3=T.TextHi},TI_FAST); task.wait(0.20)
        tw(win,{Size=UDim2.fromOffset(WW,0),BackgroundTransparency=1},TI(.36,Enum.EasingStyle.Back,Enum.EasingDirection.In))
        if ws then tw(ws,{Transparency=1},TI(.28)) end; task.wait(0.38); Sentence:Destroy()
    end

    local function DoMinimize()
        if W._minimized then
            W._minimized=false; win.ClipsDescendants=true
            tw(win,{Size=FULL},TI_SPRING,function() sidebar.Visible=true; contentArea.Visible=true end)
        else
            W._minimized=true; sidebar.Visible=false; contentArea.Visible=false
            tw(win,{Size=MINI},TI(.22,Enum.EasingStyle.Quad,Enum.EasingDirection.Out))
        end
    end

    local function HideW()
        W._visible=false
        tw(win,{Position=UDim2.new(0.5,0,1.3,0),Size=UDim2.fromOffset(WW*0.88,WH*0.88)},
            TI(.42,Enum.EasingStyle.Back,Enum.EasingDirection.In),
            function() win.Visible=false; win.Size=W._minimized and MINI or FULL end)
    end
    local function ShowW()
        win.Visible=true; W._visible=true; win.Position=UDim2.new(0.5,0,1.3,0)
        win.Size=UDim2.fromOffset(WW*0.88,(W._minimized and MINI or FULL).Y.Offset*0.88)
        tw(win,{Position=UDim2.new(0.5,0,0.5,0),Size=W._minimized and MINI or FULL},TI_SPRING)
    end

    ctrlBtns["X"].click.MouseButton1Click:Connect(DoClose)
    ctrlBtns["·"].click.MouseButton1Click:Connect(function()
        Sentence:Notify({Title="非表示",Content=cfg.ToggleBind.Name.." で再表示",Type="Info"})
        HideW()
    end)
    ctrlBtns["−"].click.MouseButton1Click:Connect(DoMinimize)
    track(UIS.InputBegan:Connect(function(inp,proc)
        if proc then return end
        if inp.KeyCode==cfg.ToggleBind then if W._visible then HideW() else ShowW() end end
    end))

    -- ══════════════════════════════════════════════════════════════════════════
    -- HOME TAB
    -- ══════════════════════════════════════════════════════════════════════════
    function W:CreateHomeTab(hCfg)
        hCfg = merge({Icon="home"}, hCfg or {})
        local id = "Home"

        -- Sidebar tab button
        local hBox=Box({Name="HomeTB", Sz=UDim2.new(0,36,0,36), Bg=T.BG3, BgA=1, R=5,
            Border=true, BorderCol=T.Border, BorderA=0.55, Z=5, Par=tabList})
        local hBar=Box({Sz=UDim2.new(0,2,0.5,0), Pos=UDim2.new(0,0,0.25,0),
            Bg=T.Accent, BgA=1, R=0, Z=6, Par=hBox})
        local hIco=Img({Ico=hCfg.Icon, Sz=UDim2.new(0,16,0,16), Col=T.TextLo, Z=6, Par=hBox})
        local hCL=Btn(hBox,7)

        -- Page scroll
        local hPage=Instance.new("ScrollingFrame"); hPage.Name="HomePage"
        hPage.Size=UDim2.new(1,0,1,0); hPage.BackgroundTransparency=1; hPage.BorderSizePixel=0
        hPage.ScrollBarThickness=2; hPage.ScrollBarImageColor3=T.Accent
        hPage.CanvasSize=UDim2.new(0,0,0,0); hPage.AutomaticCanvasSize=Enum.AutomaticSize.Y
        hPage.ZIndex=3; hPage.Visible=false; hPage.Parent=contentArea
        List(hPage,8); Pad(hPage,14,14,14,14)

        -- ── Player Card ───────────────────────────────────────────────────────
        local pCard=Box({Name="PC", Sz=UDim2.new(1,0,0,78), Bg=T.BG2, BgA=0, R=7, Z=3, Par=hPage})
        local pcS=GlowStroke(pCard, T.Accent, 1, 0.60)
        -- Subtle gradient bg
        local pcBg=Box({Sz=UDim2.new(1,0,1,0), Bg=T.AccentLo, BgA=0, R=7, Z=3, Par=pCard})
        local pcBgG=Instance.new("UIGradient"); pcBgG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.AccentLo),ColorSequenceKeypoint.new(1,T.BG1)}; pcBgG.Parent=pcBg
        -- Left accent stripe
        Box({Sz=UDim2.new(0,2,0.6,0), Pos=UDim2.new(0,0,0.2,0), Bg=T.Accent, R=0, Z=5, Par=pCard})

        -- Diamond decorations
        Diamond(pCard, 3, 3, 5, T.Accent)
        Diamond(pCard, 3, 68, 5, T.Cyan)

        local pAv=Instance.new("ImageLabel"); pAv.Size=UDim2.new(0,46,0,46); pAv.Position=UDim2.new(0,14,0.5,0); pAv.AnchorPoint=Vector2.new(0,0.5)
        pAv.BackgroundTransparency=1; pAv.ZIndex=6; pAv.Parent=pCard
        Instance.new("UICorner",pAv).CornerRadius=UDim.new(0,5)
        local pAS=GlowStroke(pAv, T.Accent, 1.5, 0.35)
        pcall(function() pAv.Image=Plrs:GetUserThumbnailAsync(LP.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size150x150) end)

        Txt({T=LP.DisplayName, Sz=UDim2.new(1,-96,0,20), Pos=UDim2.new(0,74,0,12), Font=Enum.Font.GothamBold, TS=17, Col=T.TextHi, Z=6, Par=pCard})
        Txt({T="@"..LP.Name,   Sz=UDim2.new(1,-96,0,14), Pos=UDim2.new(0,74,0,34), Font=Enum.Font.Code, TS=12, Col=T.TextMid, Z=6, Par=pCard})

        -- Badge: 悪魔HUB
        local badge=Box({Sz=UDim2.new(0,0,0,16), Pos=UDim2.new(1,-12,0,10), AP=Vector2.new(1,0),
            Bg=T.AccentLo, R=3, Z=6, Par=pCard})
        badge.AutomaticSize=Enum.AutomaticSize.X; Pad(badge,0,0,5,5)
        GlowStroke(badge, T.Accent, 1, 0.50)
        Txt({T="悪魔HUB", Sz=UDim2.new(0,0,1,0), Font=Enum.Font.GothamBold, TS=10,
            Col=T.Accent, AX=Enum.TextXAlignment.Center, AutoX=true, Z=7, Par=badge})

        -- ── Server Stats Card ─────────────────────────────────────────────────
        local sCard=Box({Name="SC", Sz=UDim2.new(1,0,0,96), Bg=T.BG2, BgA=0, R=7, Z=3, Par=hPage})
        local scS=GlowStroke(sCard, T.Cyan, 1, 0.60)

        -- Header row
        local scHead=Instance.new("Frame"); scHead.Size=UDim2.new(1,0,0,22); scHead.BackgroundTransparency=1; scHead.ZIndex=4; scHead.Parent=sCard
        Txt({T="✦", Sz=UDim2.new(0,14,1,0), Pos=UDim2.new(0,12,0,0), Font=Enum.Font.Code, TS=11, Col=T.Cyan, Z=4, Par=scHead})
        Txt({T="SRV·STATS", Sz=UDim2.new(1,-50,1,0), Pos=UDim2.new(0,26,0,0), Font=Enum.Font.GothamBold, TS=11, Col=T.TextMid, Z=4, Par=scHead})
        -- Divider
        local sSep=Instance.new("Frame"); sSep.Size=UDim2.new(1,-24,0,1); sSep.Position=UDim2.new(0,12,0,22)
        sSep.BackgroundColor3=T.Border; sSep.BackgroundTransparency=0; sSep.BorderSizePixel=0; sSep.ZIndex=3; sSep.Parent=sCard
        local ssg=Instance.new("UIGradient"); ssg.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.Cyan),ColorSequenceKeypoint.new(1,T.Border)}; ssg.Parent=sSep

        local statVals={}
        local statDefs={{"PLAYERS",""}, {"PING",""}, {"UPTIME",""}, {"REGION",""}}
        for i,sd in ipairs(statDefs) do
            local col=(i-1)%2; local row=math.floor((i-1)/2)
            local cW=(WW-SB_W-50)/2; local x=12+col*cW; local y=28+row*34
            Txt({T=sd[1], Sz=UDim2.new(0,120,0,12), Pos=UDim2.new(0,x,0,y), Font=Enum.Font.GothamBold, TS=10, Col=T.TextLo, Z=4, Par=sCard})
            statVals[sd[1]]=Txt({T="—", Sz=UDim2.new(0,160,0,18), Pos=UDim2.new(0,x,0,y+13), Font=Enum.Font.Code, TS=15, Col=T.TextHi, Z=4, Par=sCard})
        end
        task.spawn(function()
            while task.wait(1) do
                if not win or not win.Parent then break end
                pcall(function()
                    statVals["PLAYERS"].Text=#Plrs:GetPlayers().."/"..Plrs.MaxPlayers
                    local ms=math.floor(LP:GetNetworkPing()*1000)
                    statVals["PING"].Text=ms.."ms"
                    statVals["PING"].TextColor3=ms<80 and T.Success or ms<150 and T.Warning or T.Error
                    local t2=math.floor(time())
                    statVals["UPTIME"].Text=string.format("%02d:%02d:%02d",math.floor(t2/3600),math.floor(t2%3600/60),t2%60)
                    pcall(function() statVals["REGION"].Text=game:GetService("LocalizationService"):GetCountryRegionForPlayerAsync(LP) end)
                end)
            end
        end)

        -- Build full section API on home page
        local HomeObj = BuildSectionAPI(hPage, T.Accent, T.Cyan)
        HomeObj.Activate = function() SwitchTab(id) end

        table.insert(W._tabs,{id=id,box=hBox,page=hPage,bar=hBar,ico=hIco})
        hCL.MouseButton1Click:Connect(function() SwitchTab(id) end)
        hBox.MouseEnter:Connect(function()
            if W._activeTab~=id then tw(hBox,{BackgroundTransparency=0.82},TI_FAST) end
            ttL.Text="Home"; tooltip.Visible=true
            tw(tooltip,{Position=UDim2.new(0,SB_W+5,0,hBox.AbsolutePosition.Y-win.AbsolutePosition.Y+8)},TI_FAST)
        end)
        hBox.MouseLeave:Connect(function()
            if W._activeTab~=id then tw(hBox,{BackgroundTransparency=1},TI_FAST) end
            tooltip.Visible=false
        end)
        SwitchTab(id)
        return HomeObj
    end

    -- ══════════════════════════════════════════════════════════════════════════
    -- CREATE TAB
    -- ══════════════════════════════════════════════════════════════════════════
    function W:CreateTab(tCfg)
        tCfg = merge({Name="Tab",Icon="unk",ShowTitle=true}, tCfg or {})
        local Tab={}; local id=tCfg.Name

        local tBox=Box({Name=id.."TB", Sz=UDim2.new(0,36,0,36), Bg=T.BG3, BgA=1, R=5,
            Border=true, BorderCol=T.Border, BorderA=0.6, Z=5, Ord=#W._tabs+1, Par=tabList})
        local tBar=Box({Sz=UDim2.new(0,2,0.5,0), Pos=UDim2.new(0,0,0.25,0),
            Bg=T.Accent, BgA=1, R=0, Z=6, Par=tBox})
        local tIco=Img({Ico=tCfg.Icon, Sz=UDim2.new(0,16,0,16), Col=T.TextLo, Z=6, Par=tBox})
        local tCL=Btn(tBox,7)

        local tPage=Instance.new("ScrollingFrame"); tPage.Name=id
        tPage.Size=UDim2.new(1,0,1,0); tPage.BackgroundTransparency=1; tPage.BorderSizePixel=0
        tPage.ScrollBarThickness=2; tPage.ScrollBarImageColor3=T.Accent
        tPage.CanvasSize=UDim2.new(0,0,0,0); tPage.AutomaticCanvasSize=Enum.AutomaticSize.Y
        tPage.ZIndex=3; tPage.Visible=false; tPage.Parent=contentArea
        List(tPage,6); Pad(tPage,14,14,16,16)

        -- Tab title header
        if tCfg.ShowTitle then
            local tRow=Box({Sz=UDim2.new(1,0,0,28), BgA=1, Z=3, Par=tPage})
            Img({Ico=tCfg.Icon, Sz=UDim2.new(0,14,0,14), Pos=UDim2.new(0,0,0.5,0), AP=Vector2.new(0,0.5), Col=T.Accent, Z=4, Par=tRow})
            Txt({T=tCfg.Name:upper(), Sz=UDim2.new(1,-22,0,16), Pos=UDim2.new(0,22,0.5,0), AP=Vector2.new(0,0.5),
                Font=Enum.Font.GothamBold, TS=16, Col=T.TextHi, Z=4, Par=tRow})
            -- Decorative diamond after name
            local dtLen = #tCfg.Name * 10 + 26
            Diamond(tRow, dtLen, 11, 4, T.Accent)
        end

        -- Section API
        local secAPI = BuildSectionAPI(tPage, T.Accent, T.Cyan)
        for k,v in pairs(secAPI) do Tab[k]=v end
        function Tab:Activate() SwitchTab(id) end

        table.insert(W._tabs,{id=id,box=tBox,page=tPage,bar=tBar,ico=tIco})
        tCL.MouseButton1Click:Connect(function() Tab:Activate() end)
        tBox.MouseEnter:Connect(function()
            if W._activeTab~=id then tw(tBox,{BackgroundTransparency=0.82},TI_FAST) end
            ttL.Text=tCfg.Name; tooltip.Visible=true
            tw(tooltip,{Position=UDim2.new(0,SB_W+5,0,tBox.AbsolutePosition.Y-win.AbsolutePosition.Y+8)},TI_FAST)
        end)
        tBox.MouseLeave:Connect(function()
            if W._activeTab~=id then tw(tBox,{BackgroundTransparency=1},TI_FAST) end
            tooltip.Visible=false
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
    for _,c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
    self._conns={}
    if self._notifHolder and self._notifHolder.Parent then
        self._notifHolder.Parent:Destroy()
    end
    self.Flags={}; self.Options={}
end

return Sentence

--[[
─────────────────────────────────────────────────────────────────────────────
SENTENCE GUI · AKUMA EDITION v3.0  ·  Quick-start example
─────────────────────────────────────────────────────────────────────────────

local Sentence = loadstring(game:HttpGet("YOUR_URL_HERE"))()

local Win = Sentence:CreateWindow({
    Name        = "AKUMA",
    Subtitle    = "悪魔フレームワーク",
    ToggleBind  = Enum.KeyCode.RightControl,
    LoadingEnabled = true,
    LoadingTitle    = "AKUMA HUB",
    LoadingSubtitle = "初期化中…",
})

local Home = Win:CreateHomeTab({Icon = "home"})

local MainTab = Win:CreateTab({Name = "Combat", Icon = "info"})
local Sec = MainTab:CreateSection("戦闘設定")

Sec:CreateToggle({
    Name = "Auto-Aim",
    Description = "Automatically target nearest enemy",
    CurrentValue = false,
    Callback = function(v) print("Auto-Aim:", v) end,
})

Sec:CreateSlider({
    Name = "Speed",
    Range = {0, 200},
    Increment = 5,
    CurrentValue = 16,
    Suffix = " st/s",
    Callback = function(v) print("Speed:", v) end,
})

Sec:CreateDropdown({
    Name = "Game Mode",
    Options = {"Normal", "Ranked", "Practice"},
    Callback = function(v) print("Mode:", v) end,
})

Sentence:Notify({
    Title   = "起動完了",
    Content = "Akuma GUI has loaded successfully.",
    Type    = "Success",
    Duration = 4,
})
─────────────────────────────────────────────────────────────────────────────
--]]

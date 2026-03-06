--[[
╔══════════════════════════════════════════════════════════════════╗
║  SENTENCE GUI  ·  Liquid Glass Edition  v3.0                     ║
║  Visual system: iOS 26 Liquid Glass                              ║
║    — Translucent glass cards  · Ultra-rounded corners            ║
║    — Spring animations        · Pill-shaped controls             ║
║    — Apple-style typography   · Subtle white-on-dark borders     ║
╚══════════════════════════════════════════════════════════════════╝
--]]

local Sentence = {
    Version = "3.0",
    Flags   = {},
    Options = {},
    _conns  = {},
}

-- ── Services ──────────────────────────────────────────────────────
local TS       = game:GetService("TweenService")
local UIS      = game:GetService("UserInputService")
local RS       = game:GetService("RunService")
local Plrs     = game:GetService("Players")
local CG       = game:GetService("CoreGui")
local LP       = Plrs.LocalPlayer
local Cam      = workspace.CurrentCamera
local IsStudio = RS:IsStudio()

-- ══════════════════════════════════════════════════════════════════
-- iOS 26  LIQUID GLASS  DESIGN TOKENS
-- ══════════════════════════════════════════════════════════════════
local function H(hex)
    hex = hex:gsub("#","")
    return Color3.fromRGB(
        tonumber("0x"..hex:sub(1,2)),
        tonumber("0x"..hex:sub(3,4)),
        tonumber("0x"..hex:sub(5,6))
    )
end

-- Base palette
local T = {
    -- Backgrounds — deep midnight
    Base        = H("#07070f"),   -- root window bg
    Glass0      = H("#0d0d1a"),   -- cards / panels
    Glass1      = H("#13131f"),   -- elevated surface
    Glass2      = H("#1a1a28"),   -- hover
    Glass3      = H("#21212f"),   -- pressed / active fill

    -- "Frost" white used at varying transparencies
    Frost       = H("#ffffff"),

    -- Accent — Apple blue
    Accent      = H("#0A84FF"),
    AccentSoft  = H("#0A84FF"),   -- used at 0.82 alpha → glass tint
    AccentGlow  = H("#4DA6FF"),
    Purple      = H("#BF5AF2"),
    Teal        = H("#32ADE6"),

    -- Semantic
    Success     = H("#30D158"),
    Warning     = H("#FF9F0A"),
    Error       = H("#FF453A"),

    -- Typography — all on dark
    TextPri     = H("#FFFFFF"),   -- primary, full
    TextSec     = H("#EBEBF5"),   -- secondary, 0.60 alpha
    TextTer     = H("#EBEBF5"),   -- tertiary,  0.30 alpha

    -- Separator
    Sep         = H("#FFFFFF"),   -- used at 0.08 alpha
}

-- Transparency constants (used with T.Frost / T.Sep)
local A = {
    GlassBg     = 0.88,  -- card background (very subtle white tint)
    GlassBg2    = 0.84,  -- hover
    GlassBg3    = 0.78,  -- active
    GlassBorder = 0.82,  -- default border (white at 18%)
    GlassBorderHi = 0.72,-- highlight border
    SepLine     = 0.92,  -- separator (white at 8%)

    TextSec     = 0.40,  -- secondary text 60% opacity → transparency 0.40
    TextTer     = 0.70,  -- tertiary text 30%
    AccentGlass = 0.88,  -- accent background tint
}

local NotifPalette = {
    Info    = { fg=T.Accent,  glow=T.Accent,  label="INFO"    },
    Success = { fg=T.Success, glow=T.Success, label="SUCCESS" },
    Warning = { fg=T.Warning, glow=T.Warning, label="WARNING" },
    Error   = { fg=T.Error,   glow=T.Error,   label="ERROR"   },
}

-- ── Tween helpers ─────────────────────────────────────────────────
local function TI(t,s,d)
    return TweenInfo.new(t or .18, s or Enum.EasingStyle.Exponential, d or Enum.EasingDirection.Out)
end
local TI_FAST   = TI(.12)
local TI_MED    = TI(.22)
local TI_SLOW   = TI(.42)
-- iOS-style spring — bouncy, snappy
local TI_SPRING = TweenInfo.new(.44, Enum.EasingStyle.Spring,   Enum.EasingDirection.Out)
local TI_SPRING2= TweenInfo.new(.30, Enum.EasingStyle.Back,     Enum.EasingDirection.Out)
local TI_CIRC   = TweenInfo.new(.28, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)
local TI_SMOOTH = TweenInfo.new(.35, Enum.EasingStyle.Sine,     Enum.EasingDirection.InOut)

local function tw(o,p,info,cb)
    local t = TS:Create(o, info or TI_MED, p)
    if cb then t.Completed:Once(cb) end
    t:Play(); return t
end

-- ── Util ──────────────────────────────────────────────────────────
local function merge(d,t2)
    t2=t2 or {}
    for k,v in pairs(d) do if t2[k]==nil then t2[k]=v end end
    return t2
end
local function track(c) table.insert(Sentence._conns,c); return c end
local function safe(cb,...) local ok,e=pcall(cb,...); if not ok then warn("SENTENCE:"..tostring(e)) end end

local LOGO  = "rbxassetid://117810891565979"
local ICONS = {
    close  = "rbxassetid://6031094678",
    min    = "rbxassetid://6031094687",
    hide   = "rbxassetid://6031075929",
    home   = "rbxassetid://6031079158",
    info   = "rbxassetid://6026568227",
    warn   = "rbxassetid://6031071053",
    ok     = "rbxassetid://6031094667",
    arr    = "rbxassetid://6031090995",
    unk    = "rbxassetid://6031079152",
}
local function ico(n)
    if not n or n=="" then return "" end
    if n:find("rbxassetid") then return n end
    if tonumber(n) then return "rbxassetid://"..n end
    return ICONS[n] or ICONS.unk
end

-- ══════════════════════════════════════════════════════════════════
-- PRIMITIVE BUILDERS — Glass-native versions
-- ══════════════════════════════════════════════════════════════════
local function Box(p)
    p=p or {}
    local f=Instance.new("Frame")
    f.Name               = p.Name or "Box"
    f.Size               = p.Sz   or UDim2.new(1,0,0,36)
    f.Position           = p.Pos  or UDim2.new()
    f.AnchorPoint        = p.AP   or Vector2.zero
    f.BackgroundColor3   = p.Bg   or T.Glass0
    f.BackgroundTransparency = p.BgA or 0
    f.BorderSizePixel    = 0
    f.ZIndex             = p.Z    or 1
    f.LayoutOrder        = p.Ord  or 0
    f.Visible            = p.Vis  ~= false
    if p.Clip  then f.ClipsDescendants = true end
    if p.AutoY then f.AutomaticSize    = Enum.AutomaticSize.Y end
    if p.AutoX then f.AutomaticSize    = Enum.AutomaticSize.X end
    if p.R ~= nil then
        local uc = Instance.new("UICorner")
        uc.CornerRadius = type(p.R)=="number" and UDim.new(0,p.R) or (p.R or UDim.new(0,12))
        uc.Parent = f
    end
    if p.Border then
        local s = Instance.new("UIStroke")
        s.Color           = p.BorderCol or T.Frost
        s.Transparency    = p.BorderA   or A.GlassBorder
        s.Thickness       = p.BorderW   or 1
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent          = f
    end
    if p.Par then f.Parent = p.Par end
    return f
end

local function Txt(p)
    p=p or {}
    local l=Instance.new("TextLabel")
    l.Name               = p.Name or "Txt"
    l.Text               = p.T    or ""
    l.Size               = p.Sz   or UDim2.new(1,0,0,16)
    l.Position           = p.Pos  or UDim2.new()
    l.AnchorPoint        = p.AP   or Vector2.zero
    l.Font               = p.Font or Enum.Font.GothamSemibold
    l.TextSize           = p.TS   or 15
    l.TextColor3         = p.Col  or T.TextPri
    l.TextTransparency   = p.Alpha or 0
    l.TextXAlignment     = p.AX   or Enum.TextXAlignment.Left
    l.TextYAlignment     = p.AY   or Enum.TextYAlignment.Center
    l.TextWrapped        = p.Wrap or false
    l.RichText           = false
    l.BackgroundTransparency = 1
    l.BorderSizePixel    = 0
    l.ZIndex             = p.Z    or 2
    l.LayoutOrder        = p.Ord  or 0
    if p.AutoY then l.AutomaticSize = Enum.AutomaticSize.Y end
    if p.AutoX then l.AutomaticSize = Enum.AutomaticSize.X end
    if p.Par   then l.Parent = p.Par end
    return l
end

local function Img(p)
    p=p or {}
    local i=Instance.new("ImageLabel")
    i.Name               = p.Name or "Img"
    i.Image              = ico(p.Ico or "")
    i.Size               = p.Sz   or UDim2.new(0,18,0,18)
    i.Position           = p.Pos  or UDim2.new(0.5,0,0.5,0)
    i.AnchorPoint        = p.AP   or Vector2.new(0.5,0.5)
    i.ImageColor3        = p.Col  or T.TextPri
    i.ImageTransparency  = p.IA   or 0
    i.BackgroundTransparency = 1
    i.BorderSizePixel    = 0
    i.ZIndex             = p.Z    or 3
    i.ScaleType          = Enum.ScaleType.Fit
    if p.Par then i.Parent = p.Par end
    return i
end

local function Btn(par,z)
    local b=Instance.new("TextButton")
    b.Name="Btn"; b.Size=UDim2.new(1,0,1,0)
    b.BackgroundTransparency=1; b.Text=""
    b.ZIndex=z or 8; b.Parent=par; return b
end

local function List(par,gap,dir,ha,va)
    local l=Instance.new("UIListLayout")
    l.SortOrder=Enum.SortOrder.LayoutOrder
    l.Padding=UDim.new(0,gap or 4)
    l.FillDirection=dir or Enum.FillDirection.Vertical
    if ha then l.HorizontalAlignment=ha end
    if va then l.VerticalAlignment=va end
    l.Parent=par; return l
end

local function Pad(par,top,bot,lft,rgt)
    local p=Instance.new("UIPadding")
    p.PaddingTop=UDim.new(0,top or 0); p.PaddingBottom=UDim.new(0,bot or 0)
    p.PaddingLeft=UDim.new(0,lft or 0); p.PaddingRight=UDim.new(0,rgt or 0)
    p.Parent=par; return p
end

-- Glass card: semi-transparent dark background + frost border
local function GlassCard(p)
    p = p or {}
    local R = p.R or 16
    local f = Box({
        Name   = p.Name or "GCard",
        Sz     = p.Sz   or UDim2.new(1,0,0,44),
        Pos    = p.Pos  or UDim2.new(),
        AP     = p.AP   or Vector2.zero,
        Bg     = p.Bg   or T.Glass0,
        BgA    = p.BgA  or A.GlassBg,
        R      = R,
        Clip   = p.Clip,
        AutoY  = p.AutoY,
        Z      = p.Z    or 3,
        Ord    = p.Ord  or 0,
        Vis    = p.Vis,
        Par    = p.Par,
    })
    -- Frost border
    local s = Instance.new("UIStroke")
    s.Color           = T.Frost
    s.Transparency    = p.BorderA or A.GlassBorder
    s.Thickness       = 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent          = f
    return f, s
end

local function Draggable(handle,win)
    local drag,ds,sp=false,nil,nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; ds=i.Position; sp=win.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-ds
            TS:Create(win,TweenInfo.new(0.06,Enum.EasingStyle.Sine),{
                Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
            }):Play()
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
end

-- ══════════════════════════════════════════════════════════════════
-- SHARED SECTION API  (Glass Edition)
-- ══════════════════════════════════════════════════════════════════
local function BuildSectionAPI(page)
    local _sN = 0
    local API = {}

    -- Glass element factory
    local function Elem(secCon, h, autoY)
        local f,s = GlassCard({
            Sz    = UDim2.new(1,0,0,h or 44),
            BgA   = A.GlassBg,
            R     = 14,
            Z     = 3,
            Par   = secCon,
        })
        if autoY then f.AutomaticSize=Enum.AutomaticSize.Y end
        return f, s
    end

    local function HoverEff(f)
        f.MouseEnter:Connect(function()
            tw(f,{BackgroundColor3=T.Glass2, BackgroundTransparency=A.GlassBg2},TI_FAST)
            local s=f:FindFirstChildOfClass("UIStroke")
            if s then tw(s,{Transparency=A.GlassBorderHi},TI_FAST) end
        end)
        f.MouseLeave:Connect(function()
            tw(f,{BackgroundColor3=T.Glass0, BackgroundTransparency=A.GlassBg},TI_FAST)
            local s=f:FindFirstChildOfClass("UIStroke")
            if s then tw(s,{Transparency=A.GlassBorder},TI_FAST) end
        end)
    end

    -- ── CreateSection ──────────────────────────────────────────────
    function API:CreateSection(sName)
        sName = sName or ""; _sN = _sN+1
        local Sec = {}

        -- Section header — clean, minimal
        local shRow = Box({
            Name = "SH",
            Sz   = UDim2.new(1,0,0, sName~="" and 28 or 8),
            BgA  = 1, Bg=T.Base, Z=3, Par=page,
        })

        if sName ~= "" then
            -- Thin separator line
            local sep = Instance.new("Frame")
            sep.Size=UDim2.new(1,0,0,1); sep.Position=UDim2.new(0,0,0.5,0)
            sep.BackgroundColor3=T.Frost; sep.BackgroundTransparency=A.SepLine
            sep.BorderSizePixel=0; sep.ZIndex=3; sep.Parent=shRow

            -- Section label — SF Pro style: uppercase, light, spaced
            local nmL = Txt({
                T    = sName:upper(),
                Sz   = UDim2.new(1,0,0,14),
                Pos  = UDim2.new(0,4,0,0),
                Font = Enum.Font.GothamBold,
                TS   = 11,
                Col  = T.Accent,
                Alpha= 0,
                Z    = 4, Par = shRow,
            })
            -- Letter-spacing illusion via spaces
            nmL.Text = table.concat(({sName:upper():gsub(".",function(c) return c.." " end)}), ""):sub(1,-2)
        end

        -- Content container
        local secCon = Box({
            Name="SC", Sz=UDim2.new(1,0,0,0), BgA=1, Bg=T.Base, Z=3, AutoY=true,
            Ord=shRow.LayoutOrder+1, Par=page,
        })
        List(secCon,6)

        -- ── Elements ────────────────────────────────────────────────

        function Sec:CreateDivider()
            local d=Instance.new("Frame"); d.Size=UDim2.new(1,-28,0,1)
            d.Position=UDim2.new(0,14,0,0)
            d.BackgroundColor3=T.Frost; d.BackgroundTransparency=A.SepLine
            d.BorderSizePixel=0; d.ZIndex=3; d.Parent=secCon
            return {Destroy=function() d:Destroy() end}
        end

        function Sec:CreateLabel(lc)
            lc = merge({Name="",Text="",Style=1},lc or {})
            local text = lc.Text~="" and lc.Text or lc.Name or ""
            local cMap = {[1]=T.TextSec, [2]=T.Accent, [3]=T.Warning}
            local aMap = {[1]=A.TextSec, [2]=0,         [3]=0}
            local st   = lc.Style or 1

            local f,fs = Elem(secCon,38)
            Pad(f,0,0,16,16)

            -- Accent style: small colored dot prefix
            if st == 2 then
                -- Left soft glow stripe
                local stripe = Box({Sz=UDim2.new(0,3,0.55,0), Pos=UDim2.new(0,0,0.225,0), Bg=T.Accent, R=2, Z=5, Par=f})
                -- Tint the card background slightly
                tw(f,{BackgroundColor3=H("#0d1a2d"), BackgroundTransparency=0.72},TI_FAST)
            elseif st == 3 then
                local stripe = Box({Sz=UDim2.new(0,3,0.55,0), Pos=UDim2.new(0,0,0.225,0), Bg=T.Warning, R=2, Z=5, Par=f})
                tw(f,{BackgroundColor3=H("#1f1500"), BackgroundTransparency=0.72},TI_FAST)
            end

            local xo = st>1 and 18 or 0
            local lb = Txt({
                T    = text,
                Sz   = UDim2.new(1,-xo,0,16),
                Pos  = UDim2.new(0,xo,0.5,0), AP=Vector2.new(0,0.5),
                Font = Enum.Font.Gotham,
                TS   = 14,
                Col  = cMap[st],
                Alpha= aMap[st],
                Z    = 4, Par = f,
            })
            return {
                Set     = function(_,t3) lb.Text=t3 end,
                Destroy = function() f:Destroy() end,
            }
        end

        function Sec:CreateParagraph(pc)
            pc = merge({Title="Title",Content=""},pc or {})
            local f,fs = Elem(secCon,0,true)
            Pad(f,14,14,16,16); List(f,6)
            local pt  = Txt({T=pc.Title,   Sz=UDim2.new(1,0,0,20), Font=Enum.Font.GothamBold, TS=17, Col=T.TextPri, Z=4, Par=f})
            local pc2 = Txt({T=pc.Content, Sz=UDim2.new(1,0,0,0),  Font=Enum.Font.Gotham,     TS=14, Col=T.TextSec, Alpha=A.TextSec, Z=4, Wrap=true, AutoY=true, Par=f})
            return {
                Set=function(_,s) if s.Title then pt.Text=s.Title end; if s.Content then pc2.Text=s.Content end end,
                Destroy=function() f:Destroy() end,
            }
        end

        function Sec:CreateButton(bc)
            bc = merge({Name="Button",Description=nil,Callback=function()end},bc or {})
            local h = bc.Description and 62 or 44
            local f,fs = Elem(secCon, h)
            f.ClipsDescendants=true

            -- Ripple fill — accent glass
            local rip = Box({Sz=UDim2.new(0,0,1,0), Pos=UDim2.new(0.5,0,0,0), AP=Vector2.new(0.5,0),
                Bg=T.Accent, BgA=1, R=14, Z=3, Par=f})
            local ripG = Instance.new("UIGradient")
            ripG.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.82),NumberSequenceKeypoint.new(1,1)}
            ripG.Parent=rip

            -- Content
            local nameY = bc.Description and 12 or 14
            Txt({T=bc.Name, Sz=UDim2.new(1,-52,0,18), Pos=UDim2.new(0,18,0,nameY),
                Font=Enum.Font.GothamSemibold, TS=15, Col=T.TextPri, Z=5, Par=f})
            if bc.Description then
                Txt({T=bc.Description, Sz=UDim2.new(1,-52,0,15), Pos=UDim2.new(0,18,0,nameY+20),
                    Font=Enum.Font.Gotham, TS=13, Col=T.TextSec, Alpha=A.TextSec, Z=5, Par=f})
            end

            -- Chevron →
            local chev = Box({Sz=UDim2.new(0,22,0,22), Pos=UDim2.new(1,-14,0.5,0), AP=Vector2.new(1,0.5),
                Bg=T.Frost, BgA=0.88, R=11, Z=5, Par=f})
            Img({Ico="arr", Sz=UDim2.new(0,10,0,10), Col=T.Accent, IA=0, Z=6, Par=chev})

            local cl=Btn(f,7)
            f.MouseEnter:Connect(function()
                tw(rip,{Size=UDim2.new(1,0,1,0), BackgroundTransparency=0},TI(.26,Enum.EasingStyle.Quad))
                tw(chev,{BackgroundColor3=T.Accent, BackgroundTransparency=0},TI_FAST)
                local ci=chev:FindFirstChildOfClass("ImageLabel"); if ci then tw(ci,{ImageColor3=T.TextPri,ImageTransparency=0},TI_FAST) end
                if fs then tw(fs,{Transparency=A.GlassBorderHi},TI_FAST) end
                tw(f,{BackgroundColor3=T.Glass2,BackgroundTransparency=A.GlassBg2},TI_FAST)
            end)
            f.MouseLeave:Connect(function()
                tw(rip,{Size=UDim2.new(0,0,1,0), BackgroundTransparency=1},TI_MED)
                tw(chev,{BackgroundColor3=T.Frost, BackgroundTransparency=0.88},TI_FAST)
                local ci=chev:FindFirstChildOfClass("ImageLabel"); if ci then tw(ci,{ImageColor3=T.Accent,ImageTransparency=0},TI_FAST) end
                if fs then tw(fs,{Transparency=A.GlassBorder},TI_FAST) end
                tw(f,{BackgroundColor3=T.Glass0,BackgroundTransparency=A.GlassBg},TI_FAST)
            end)
            cl.MouseButton1Click:Connect(function()
                tw(f,{BackgroundColor3=T.Glass3,BackgroundTransparency=A.GlassBg3},TI(.08))
                task.wait(0.09)
                tw(f,{BackgroundColor3=T.Glass0,BackgroundTransparency=A.GlassBg},TI_MED)
                tw(rip,{Size=UDim2.new(0,0,1,0),BackgroundTransparency=1},TI_MED)
                safe(bc.Callback)
            end)
            return {Destroy=function() f:Destroy() end}
        end

        function Sec:CreateToggle(tc)
            tc = merge({Name="Toggle",Description=nil,CurrentValue=false,Flag=nil,Callback=function()end},tc or {})
            local h = tc.Description and 62 or 44
            local f,fs = Elem(secCon, h)

            local nameY = tc.Description and 12 or 14
            Txt({T=tc.Name, Sz=UDim2.new(1,-80,0,18), Pos=UDim2.new(0,18,0,nameY),
                Font=Enum.Font.GothamSemibold, TS=15, Col=T.TextPri, Z=5, Par=f})
            if tc.Description then
                Txt({T=tc.Description, Sz=UDim2.new(1,-80,0,15), Pos=UDim2.new(0,18,0,nameY+20),
                    Font=Enum.Font.Gotham, TS=13, Col=T.TextSec, Alpha=A.TextSec, Z=5, Par=f})
            end

            -- iOS-style pill toggle
            local trk = Box({Sz=UDim2.new(0,50,0,28), Pos=UDim2.new(1,-16,0.5,0), AP=Vector2.new(1,0.5),
                Bg=T.Glass2, BgA=0, R=14, Z=5, Par=f})
            -- Track border
            local trkS=Instance.new("UIStroke"); trkS.Color=T.Frost; trkS.Transparency=0.78; trkS.Thickness=1; trkS.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; trkS.Parent=trk
            -- Knob — white circle, iOS style
            local knob = Box({Sz=UDim2.new(0,22,0,22), Pos=UDim2.new(0,3,0.5,0), AP=Vector2.new(0,0.5),
                Bg=T.TextPri, BgA=0, R=11, Z=7, Par=trk})
            -- Knob shadow suggestion via inner ring
            local kShadow=Instance.new("UIStroke"); kShadow.Color=H("#000000"); kShadow.Transparency=0.75; kShadow.Thickness=1; kShadow.Parent=knob

            local TV={CurrentValue=tc.CurrentValue,Type="Toggle",Settings=tc}
            local function upd(anim)
                local TW = anim==false and TI(.001) or TI_SPRING
                if TV.CurrentValue then
                    tw(trk,{BackgroundColor3=T.Accent, BackgroundTransparency=0},TI_MED)
                    tw(trkS,{Transparency=1},TI_MED)
                    tw(knob,{Position=UDim2.new(1,-25,0.5,0), BackgroundTransparency=0},TW)
                else
                    tw(trk,{BackgroundColor3=T.Glass2, BackgroundTransparency=0.30},TI_MED)
                    tw(trkS,{Transparency=0.78},TI_MED)
                    tw(knob,{Position=UDim2.new(0,3,0.5,0), BackgroundTransparency=0.1},TW)
                end
            end
            upd(false)
            HoverEff(f)
            Btn(f,6).MouseButton1Click:Connect(function()
                TV.CurrentValue=not TV.CurrentValue
                -- Haptic squeeze effect
                tw(knob,{Size=UDim2.new(0,19,0,22)},TI(.07))
                task.wait(0.08); tw(knob,{Size=UDim2.new(0,22,0,22)},TI_SPRING2)
                upd(); safe(tc.Callback,TV.CurrentValue)
            end)
            function TV:Set(v) TV.CurrentValue=v; upd(); safe(tc.Callback,v) end
            if tc.Flag then Sentence.Flags[tc.Flag]=TV; Sentence.Options[tc.Flag]=TV end
            return TV
        end

        function Sec:CreateSlider(sc)
            sc=merge({Name="Slider",Range={0,100},Increment=1,CurrentValue=50,Suffix="",Flag=nil,Callback=function()end},sc or {})
            local f,fs = Elem(secCon,64)
            Txt({T=sc.Name, Sz=UDim2.new(1,-120,0,18), Pos=UDim2.new(0,18,0,10),
                Font=Enum.Font.GothamSemibold, TS=15, Col=T.TextPri, Z=5, Par=f})

            -- Value pill
            local vc=Box({Sz=UDim2.new(0,0,0,24), Pos=UDim2.new(1,-14,0,8), AP=Vector2.new(1,0),
                Bg=T.Accent, BgA=0.85, R=12, Z=5, Par=f})
            vc.AutomaticSize=Enum.AutomaticSize.X; Pad(vc,0,0,10,10)
            local vL=Txt({T=tostring(sc.CurrentValue)..sc.Suffix, Sz=UDim2.new(0,0,1,0),
                Font=Enum.Font.GothamBold, TS=13, Col=T.TextPri, AX=Enum.TextXAlignment.Center, Z=6, Par=vc})
            vL.AutomaticSize=Enum.AutomaticSize.X

            -- Track
            local trackBg=Box({Sz=UDim2.new(1,-36,0,4), Pos=UDim2.new(0,18,0,42),
                Bg=T.Frost, BgA=0.88, R=2, Z=5, Par=f})
            -- Active fill — gradient
            local fill=Box({Sz=UDim2.new(0,0,1,0), Bg=T.Accent, R=2, Z=6, Par=trackBg})
            local fillG=Instance.new("UIGradient")
            fillG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.Teal),ColorSequenceKeypoint.new(1,T.Accent)}
            fillG.Parent=fill
            -- Thumb — glass circle with blue glow ring
            local thumb=Box({Sz=UDim2.new(0,18,0,18), Pos=UDim2.new(0,0,0.5,0), AP=Vector2.new(0.5,0.5),
                Bg=T.TextPri, BgA=0, R=9, Z=7, Par=trackBg})
            local thS=Instance.new("UIStroke"); thS.Color=T.Accent; thS.Thickness=2; thS.Transparency=0.4; thS.Parent=thumb

            local SV={CurrentValue=sc.CurrentValue,Type="Slider",Settings=sc}
            local mn,mx,inc=sc.Range[1],sc.Range[2],sc.Increment
            local function setV(v)
                v=math.clamp(v,mn,mx); v=math.floor(v/inc+0.5)*inc
                v=tonumber(string.format("%.10g",v)); SV.CurrentValue=v
                vL.Text=tostring(v)..sc.Suffix
                local pct=(v-mn)/(mx-mn)
                tw(fill,{Size=UDim2.new(pct,0,1,0)},TI_FAST)
                tw(thumb,{Position=UDim2.new(pct,0,0.5,0)},TI_FAST)
            end
            setV(sc.CurrentValue)

            local drag=false; local bCL=Btn(trackBg,9)
            local function fromInp(i)
                local rel=math.clamp((i.Position.X-trackBg.AbsolutePosition.X)/trackBg.AbsoluteSize.X,0,1)
                setV(mn+(mx-mn)*rel); safe(sc.Callback,SV.CurrentValue)
            end
            bCL.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                    drag=true; fromInp(i)
                    tw(thumb,{Size=UDim2.new(0,22,0,22)},TI_FAST); tw(thS,{Transparency=0.1},TI_FAST)
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                    drag=false
                    tw(thumb,{Size=UDim2.new(0,18,0,18)},TI_SPRING2); tw(thS,{Transparency=0.4},TI_FAST)
                end
            end)
            track(UIS.InputChanged:Connect(function(i)
                if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then fromInp(i) end
            end))
            HoverEff(f)
            function SV:Set(v) setV(v); safe(sc.Callback,SV.CurrentValue) end
            if sc.Flag then Sentence.Flags[sc.Flag]=SV; Sentence.Options[sc.Flag]=SV end
            return SV
        end

        function Sec:CreateColorPicker(cc)
            cc=merge({Name="Color",Flag=nil,Color=Color3.new(1,1,1),Callback=function()end},cc or {})
            local f,fs = Elem(secCon,44)
            Txt({T=cc.Name, Sz=UDim2.new(1,-70,0,18), Pos=UDim2.new(0,18,0,13),
                Font=Enum.Font.GothamSemibold, TS=15, Col=T.TextPri, Z=5, Par=f})
            local sw=Box({Sz=UDim2.new(0,26,0,26), Pos=UDim2.new(1,-16,0.5,0), AP=Vector2.new(1,0.5),
                Bg=cc.Color, R=8, Border=true, BorderCol=T.Frost, BorderA=0.75, Z=5, Par=f})
            local CV={CurrentValue=cc.Color,Type="ColorPicker",Settings=cc}
            function CV:Set(c) CV.CurrentValue=c; sw.BackgroundColor3=c; safe(cc.Callback,c) end
            if cc.Flag then Sentence.Flags[cc.Flag]=CV; Sentence.Options[cc.Flag]=CV end
            return CV
        end

        return Sec
    end -- CreateSection

    -- Default section shortcut proxy
    local _ds
    local function gds() if not _ds then _ds=API:CreateSection("") end; return _ds end
    for _,m in ipairs({"CreateButton","CreateLabel","CreateParagraph","CreateToggle","CreateSlider","CreateDivider","CreateColorPicker"}) do
        API[m]=function(self,...) return gds()[m](gds(),...) end
    end
    return API
end

-- ══════════════════════════════════════════════════════════════════
-- NOTIFICATIONS  — Liquid Glass style
-- ══════════════════════════════════════════════════════════════════
function Sentence:Notify(data)
    task.spawn(function()
        data=merge({Title="Notice",Content="",Icon="info",Type="Info",Duration=5},data)
        local pal=NotifPalette[data.Type] or NotifPalette.Info

        -- Glass notification card
        local card=Box({
            Name="NCard", Sz=UDim2.new(0,320,0,0), Pos=UDim2.new(-1.1,0,1,0),
            AP=Vector2.new(0,1), Bg=T.Glass1, BgA=1, Clip=true, R=18, Par=self._notifHolder,
        })
        local cardStroke=Instance.new("UIStroke")
        cardStroke.Color=T.Frost; cardStroke.Thickness=1; cardStroke.Transparency=1
        cardStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; cardStroke.Parent=card

        -- Subtle colored top rim
        local topRim=Box({Sz=UDim2.new(1,0,0,2), Bg=pal.fg, BgA=1, R=0, Z=6, Par=card})

        -- Glow tint on left side
        local glowTint=Box({Sz=UDim2.new(0,4,1,0), Bg=pal.fg, BgA=1, R=0, Z=4, Par=card})
        local gG=Instance.new("UIGradient")
        gG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,pal.fg),ColorSequenceKeypoint.new(1,T.Glass1)}
        gG.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.55),NumberSequenceKeypoint.new(1,1)}; gG.Parent=glowTint

        -- Icon pill
        local iconPill=Box({Sz=UDim2.new(0,30,0,30), Pos=UDim2.new(0,14,0,0), AP=Vector2.new(0,0.5),
            Bg=pal.fg, BgA=1, R=15, Z=6, Par=card})
        local iPillS=Instance.new("UIStroke"); iPillS.Color=T.Frost; iPillS.Transparency=0.75; iPillS.Thickness=1; iPillS.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; iPillS.Parent=iconPill
        local iconImg=Img({Ico=data.Icon, Sz=UDim2.new(0,14,0,14), Col=T.TextPri, IA=1, Z=7, Par=iconPill})

        -- Content
        local cc=Box({Name="CC",Sz=UDim2.new(1,0,0,0),BgA=1,AutoY=true,Z=5,Par=card})
        Pad(cc,12,12,56,40); List(cc,3)

        local typeL=Txt({T=pal.label, Sz=UDim2.new(1,0,0,12), Font=Enum.Font.GothamBold, TS=11,
            Col=pal.fg, Alpha=1, Z=6, Par=cc})
        local ttl=Txt({T=data.Title,   Sz=UDim2.new(1,0,0,18), Font=Enum.Font.GothamBold,  TS=15, Col=T.TextPri, Alpha=1, Z=6, Par=cc})
        local msg=Txt({T=data.Content, Sz=UDim2.new(1,0,0,0),  Font=Enum.Font.Gotham,      TS=13, Col=T.TextSec, Alpha=1, Wrap=true, AutoY=true, Z=6, Par=cc})

        -- Progress bar — thin bottom line
        local pTrack=Box({Sz=UDim2.new(1,0,0,2), Pos=UDim2.new(0,0,1,-2), Bg=T.Frost, BgA=1, R=0, Z=6, Par=card})
        local pFill=Box({Sz=UDim2.new(1,0,1,0), Bg=pal.fg, BgA=1, R=0, Z=7, Par=pTrack})

        -- Dismiss  ×
        local xBtn=Box({Sz=UDim2.new(0,20,0,20), Pos=UDim2.new(1,-10,0,10), AP=Vector2.new(1,0),
            Bg=T.Frost, BgA=0.88, R=10, Z=9, Par=card})
        local xIco=Img({Ico="close", Sz=UDim2.new(0,8,0,8), Col=T.TextSec, IA=0, Z=10, Par=xBtn})
        local xCL=Btn(xBtn,11)
        xBtn.MouseEnter:Connect(function() tw(xBtn,{BackgroundColor3=T.Error,BackgroundTransparency=0.1},TI_FAST); tw(xIco,{ImageColor3=T.TextPri},TI_FAST) end)
        xBtn.MouseLeave:Connect(function() tw(xBtn,{BackgroundColor3=T.Frost,BackgroundTransparency=0.88},TI_FAST); tw(xIco,{ImageColor3=T.TextSec},TI_FAST) end)

        task.wait()
        local cardH=cc.AbsoluteSize.Y+4
        iconPill.Position=UDim2.new(0,14,0,cardH/2-15)
        card.Size=UDim2.new(0,320,0,cardH); card.Position=UDim2.new(-1.1,0,1,0)

        -- All invisible initially
        for _,el in ipairs({topRim,glowTint,iconPill,typeBadge or typeL,pTrack,pFill,xBtn}) do
            pcall(function() el.BackgroundTransparency=1 end)
        end
        iconImg.ImageTransparency=1; typeL.TextTransparency=1; ttl.TextTransparency=1
        msg.TextTransparency=1; xIco.ImageTransparency=1

        -- Slide in from left
        tw(card,{Position=UDim2.new(0,0,1,0)},TI_CIRC); task.wait(0.1)

        local TI_IN=TI(.20,Enum.EasingStyle.Exponential)
        tw(card,{BackgroundColor3=T.Glass1,BackgroundTransparency=A.GlassBg},TI_IN)
        tw(cardStroke,{Transparency=A.GlassBorder},TI_IN)
        tw(topRim,{BackgroundTransparency=0},TI_IN)
        tw(glowTint,{BackgroundTransparency=0},TI_IN)
        tw(iconPill,{BackgroundTransparency=0},TI_IN)
        tw(iPillS,{Transparency=0.6},TI_IN)
        tw(iconImg,{ImageTransparency=0},TI_IN)
        tw(typeL,{TextTransparency=0.3},TI_IN)
        tw(ttl,{TextTransparency=0},TI_IN)
        tw(msg,{TextTransparency=A.TextSec},TI_IN)
        tw(pTrack,{BackgroundTransparency=0.88},TI_IN)
        tw(pFill,{BackgroundTransparency=0},TI_IN)
        tw(xBtn,{BackgroundTransparency=0.88},TI_IN)
        tw(xIco,{ImageTransparency=0.4},TI_IN)
        tw(pFill,{Size=UDim2.new(0,0,1,0)},TI(data.Duration,Enum.EasingStyle.Linear))

        local paused,dismissed,elapsed=false,false,0
        card.MouseEnter:Connect(function() paused=true;  tw(card,{BackgroundTransparency=A.GlassBg2},TI_FAST) end)
        card.MouseLeave:Connect(function() paused=false; tw(card,{BackgroundTransparency=A.GlassBg},TI_FAST) end)
        xCL.MouseButton1Click:Connect(function() dismissed=true end)
        repeat task.wait(0.05); if not paused then elapsed=elapsed+0.05 end
        until dismissed or elapsed>=data.Duration

        -- Fade out
        local TI_OUT=TI(.16,Enum.EasingStyle.Quad)
        tw(card,{BackgroundTransparency=1, Position=UDim2.new(-1.1,0,1,0)},TI(.22,Enum.EasingStyle.Quad,Enum.EasingDirection.In))
        tw(cardStroke,{Transparency=1},TI_OUT)
        tw(topRim,{BackgroundTransparency=1},TI_OUT)
        tw(ttl,{TextTransparency=1},TI_OUT); tw(msg,{TextTransparency=1},TI_OUT)
        task.wait(0.24)
        tw(card,{Size=UDim2.new(0,320,0,0)},TI_MED,function() card:Destroy() end)
    end)
end

-- ══════════════════════════════════════════════════════════════════
-- CREATE WINDOW
-- ══════════════════════════════════════════════════════════════════
function Sentence:CreateWindow(cfg)
    cfg=merge({
        Name="SENTENCE", Subtitle="", Icon="",
        ToggleBind=Enum.KeyCode.RightControl,
        LoadingEnabled=true, LoadingTitle="SENTENCE", LoadingSubtitle="INITIALISING",
        ConfigurationSaving={Enabled=false,FolderName="Sentence",FileName="config"},
    },cfg)

    local vp   = Cam.ViewportSize
    local WW   = math.clamp(vp.X-100,616,825)
    local WH   = math.clamp(vp.Y-80, 440,550)
    local FULL = UDim2.fromOffset(WW,WH)
    local TB_H = 50   -- slightly taller title bar
    local MINI = UDim2.fromOffset(WW,TB_H+2)

    -- ── ScreenGui ─────────────────────────────────────────────────
    local gui=Instance.new("ScreenGui")
    gui.Name="OGSentenceUI"; gui.DisplayOrder=999999999
    gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true
    if     gethui                  then gui.Parent=gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(gui); gui.Parent=CG
    elseif not IsStudio            then gui.Parent=CG
    else                                gui.Parent=LP:WaitForChild("PlayerGui") end

    -- ══════════════════════════════════════════════════════════════
    -- SPLASH  —  Liquid Glass Intro
    -- ══════════════════════════════════════════════════════════════
    task.spawn(function()
        local alive=true; local splashConns={}
        local splash=Instance.new("Frame"); splash.Name="Splash"
        splash.Size=UDim2.new(1,0,1,0); splash.BackgroundColor3=T.Base
        splash.BackgroundTransparency=1; splash.BorderSizePixel=0; splash.ZIndex=1000; splash.ClipsDescendants=true; splash.Parent=gui

        -- Corner crosshair lines (keep from original)
        local cLines={}
        local function MkCorner(ax,ay,rx,ry)
            local r=Instance.new("Frame"); r.Size=UDim2.new(0,36,0,36); r.Position=UDim2.new(ax,rx,ay,ry); r.AnchorPoint=Vector2.new(ax,ay); r.BackgroundTransparency=1; r.ZIndex=1002; r.Parent=splash
            local h2=Instance.new("Frame"); h2.Size=UDim2.new(1,0,0,1); h2.Position=ay==0 and UDim2.new(0,0,0,0) or UDim2.new(0,0,1,-1); h2.BackgroundColor3=T.Accent; h2.BackgroundTransparency=1; h2.BorderSizePixel=0; h2.ZIndex=1003; h2.Parent=r
            local v=Instance.new("Frame"); v.Size=UDim2.new(0,1,1,0); v.Position=ax==0 and UDim2.new(0,0,0,0) or UDim2.new(1,-1,0,0); v.BackgroundColor3=T.Accent; v.BackgroundTransparency=1; v.BorderSizePixel=0; v.ZIndex=1003; v.Parent=r
            table.insert(cLines,h2); table.insert(cLines,v)
        end
        MkCorner(0,0,24,24); MkCorner(1,0,-24,24); MkCorner(0,1,24,-24); MkCorner(1,1,-24,-24)

        -- Central glow orb
        local orb=Instance.new("Frame"); orb.Size=UDim2.new(0,320,0,320); orb.Position=UDim2.new(0.5,0,0.5,0); orb.AnchorPoint=Vector2.new(0.5,0.5); orb.BackgroundColor3=T.Accent; orb.BackgroundTransparency=1; orb.BorderSizePixel=0; orb.ZIndex=1001; orb.Parent=splash; Instance.new("UICorner",orb).CornerRadius=UDim.new(1,0)
        local orbG=Instance.new("UIGradient"); orbG.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.72),NumberSequenceKeypoint.new(1,1)}; orbG.Parent=orb

        -- Logo glass card
        local lCard=Box({Sz=UDim2.new(0,96,0,96), Pos=UDim2.new(0.5,0,0.46,0), AP=Vector2.new(0.5,0.5),
            Bg=T.Glass1, BgA=1, R=28, Border=true, BorderCol=T.Frost, BorderA=A.GlassBorder, Z=1004, Par=splash})
        -- Inner glow
        local lGlow=Box({Sz=UDim2.new(0.8,0,0.8,0), Pos=UDim2.new(0.5,0,0.1,0), AP=Vector2.new(0.5,0),
            Bg=T.Accent, BgA=1, R=14, Z=1003, Par=lCard})
        local lgG=Instance.new("UIGradient"); lgG.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.78),NumberSequenceKeypoint.new(1,1)}; lgG.Parent=lGlow
        local limg=Instance.new("ImageLabel"); limg.Size=UDim2.new(0.7,0,0.7,0); limg.Position=UDim2.new(0.5,0,0.5,0); limg.AnchorPoint=Vector2.new(0.5,0.5); limg.BackgroundTransparency=1; limg.Image=LOGO; limg.ImageTransparency=1; limg.ScaleType=Enum.ScaleType.Fit; limg.ZIndex=1006; limg.Parent=lCard; Instance.new("UICorner",limg).CornerRadius=UDim.new(0,8)

        -- Rotating ring
        local ro=Instance.new("Frame"); ro.Size=UDim2.new(1,22,1,22); ro.Position=UDim2.new(0.5,0,0.5,0); ro.AnchorPoint=Vector2.new(0.5,0.5); ro.BackgroundTransparency=1; ro.BorderSizePixel=0; ro.ZIndex=1005; ro.Parent=lCard; Instance.new("UICorner",ro).CornerRadius=UDim.new(1,0)
        local so=Instance.new("UIStroke"); so.Color=T.Accent; so.Thickness=1.5; so.Transparency=0.15; so.Parent=ro
        local goR=Instance.new("UIGradient"); goR.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.45,0),NumberSequenceKeypoint.new(0.75,0.92),NumberSequenceKeypoint.new(1,0)}; goR.Parent=so

        -- Title
        local tw2f=Instance.new("Frame"); tw2f.Size=UDim2.new(0,400,0,0); tw2f.Position=UDim2.new(0.5,0,0.46,76); tw2f.AnchorPoint=Vector2.new(0.5,0); tw2f.BackgroundTransparency=1; tw2f.AutomaticSize=Enum.AutomaticSize.Y; tw2f.ZIndex=1004; tw2f.Parent=splash
        local tRow=Instance.new("Frame"); tRow.Size=UDim2.new(1,0,0,0); tRow.BackgroundTransparency=1; tRow.AutomaticSize=Enum.AutomaticSize.XY; tRow.ZIndex=1005; tRow.Parent=tw2f
        local trl=Instance.new("UIListLayout"); trl.FillDirection=Enum.FillDirection.Horizontal; trl.HorizontalAlignment=Enum.HorizontalAlignment.Center; trl.VerticalAlignment=Enum.VerticalAlignment.Center; trl.Padding=UDim.new(0,0); trl.SortOrder=Enum.SortOrder.LayoutOrder; trl.Parent=tRow
        local CHARS={"S","E","N","T","E","N","C","E"}; local charLbls={}
        for i,ch in ipairs(CHARS) do
            local l=Instance.new("TextLabel"); l.Text=ch; l.Size=UDim2.new(0,0,0,0); l.AutomaticSize=Enum.AutomaticSize.XY; l.Font=Enum.Font.GothamBold; l.TextSize=52; l.TextColor3=T.TextPri; l.TextTransparency=1; l.BackgroundTransparency=1; l.BorderSizePixel=0; l.ZIndex=1006; l.LayoutOrder=i; l.RichText=false; l.Parent=tRow; charLbls[i]=l
        end
        local sp=Instance.new("Frame"); sp.Size=UDim2.new(0,16,0,1); sp.BackgroundTransparency=1; sp.BorderSizePixel=0; sp.LayoutOrder=9; sp.Parent=tRow
        local hub=Instance.new("TextLabel"); hub.Text="HUB"; hub.Size=UDim2.new(0,0,0,0); hub.AutomaticSize=Enum.AutomaticSize.XY; hub.Font=Enum.Font.GothamBold; hub.TextSize=52; hub.TextColor3=T.Accent; hub.TextTransparency=1; hub.BackgroundTransparency=1; hub.BorderSizePixel=0; hub.ZIndex=1006; hub.LayoutOrder=10; hub.RichText=false; hub.Parent=tRow

        local acLine=Instance.new("Frame"); acLine.Size=UDim2.new(0,0,0,1); acLine.Position=UDim2.new(0.5,0,0,60); acLine.AnchorPoint=Vector2.new(0.5,0); acLine.BackgroundColor3=T.Frost; acLine.BackgroundTransparency=1; acLine.BorderSizePixel=0; acLine.ZIndex=1005; acLine.Parent=tw2f; Instance.new("UICorner",acLine).CornerRadius=UDim.new(1,0)
        local stat=Instance.new("TextLabel"); stat.Text="INITIALISING CORE"; stat.Size=UDim2.new(1,0,0,20); stat.Position=UDim2.new(0,0,0,68); stat.Font=Enum.Font.Gotham; stat.TextSize=12; stat.TextColor3=T.TextSec; stat.TextTransparency=1; stat.BackgroundTransparency=1; stat.BorderSizePixel=0; stat.ZIndex=1005; stat.TextXAlignment=Enum.TextXAlignment.Center; stat.RichText=false; stat.Parent=tw2f
        local pw=Instance.new("Frame"); pw.Size=UDim2.new(0,240,0,3); pw.Position=UDim2.new(0.5,0,0,92); pw.AnchorPoint=Vector2.new(0.5,0); pw.BackgroundColor3=T.Frost; pw.BackgroundTransparency=1; pw.BorderSizePixel=0; pw.ZIndex=1005; pw.Parent=tw2f; Instance.new("UICorner",pw).CornerRadius=UDim.new(1,0)
        local pf=Instance.new("Frame"); pf.Size=UDim2.new(0,0,1,0); pf.BackgroundColor3=T.Accent; pf.BackgroundTransparency=1; pf.BorderSizePixel=0; pf.ZIndex=1006; pf.Parent=pw; Instance.new("UICorner",pf).CornerRadius=UDim.new(1,0)
        local pfG=Instance.new("UIGradient"); pfG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.Teal),ColorSequenceKeypoint.new(1,T.AccentGlow)}; pfG.Parent=pf

        -- Floating particles
        local parts={}
        for pi=1,10 do
            local px=Instance.new("Frame"); px.Size=UDim2.new(0,math.random(2,5),0,math.random(2,5)); px.Position=UDim2.new(math.random(10,90)/100,0,math.random(10,90)/100,0); px.AnchorPoint=Vector2.new(0.5,0.5); px.BackgroundColor3=math.random()<0.5 and T.Accent or T.Purple; px.BackgroundTransparency=0.55+math.random()*0.35; px.BorderSizePixel=0; px.ZIndex=1002; px.Parent=splash; Instance.new("UICorner",px).CornerRadius=UDim.new(1,0)
            parts[pi]={f=px,bx=math.random(10,90)/100,by=math.random(10,90)/100,ph=math.random()*math.pi*2,sp=0.22+math.random()*0.35,rg=0.012+math.random()*0.018}
        end

        -- Animate in
        tw(splash,{BackgroundTransparency=0},TI(.35,Enum.EasingStyle.Quad)); task.wait(0.12)
        for _,l in ipairs(cLines) do tw(l,{BackgroundTransparency=0.3},TI(.4,Enum.EasingStyle.Expo)) end; task.wait(0.14)
        tw(orb,{BackgroundTransparency=0.76},TI(.55,Enum.EasingStyle.Quad)); task.wait(0.06)
        tw(so,{Transparency=0.1},TI_MED)
        tw(lCard,{Size=UDim2.new(0,160,0,160)},TI_SPRING); tw(lGlow,{BackgroundTransparency=0.82},TI(.5))
        tw(limg,{ImageTransparency=0},TI(.45,Enum.EasingStyle.Exponential)); task.wait(0.28)
        for i,l in ipairs(charLbls) do task.spawn(function() task.wait((i-1)*0.048); tw(l,{TextTransparency=0},TI_SPRING2) end) end; task.wait(0.42)
        tw(hub,{TextTransparency=0},TI_SPRING2); task.wait(0.12)
        tw(acLine,{Size=UDim2.new(0,260,0,1),BackgroundTransparency=0.82},TI(.40,Enum.EasingStyle.Exponential)); task.wait(0.08)
        tw(stat,{TextTransparency=A.TextSec},TI_MED); tw(pw,{BackgroundTransparency=0.90},TI_FAST); tw(pf,{BackgroundTransparency=0},TI_FAST)

        local rsC=RS.RenderStepped:Connect(function(dt)
            if not alive then return end
            ro.Rotation=ro.Rotation+72*dt
            local pulse=0.76+math.sin(tick()*1.8)*0.06; lGlow.BackgroundTransparency=1-(1-0.82)*pulse
            local mp=UIS:GetMouseLocation(); local vs=Cam.ViewportSize
            orb.Position=UDim2.new(0.5,(mp.X/vs.X-0.5)*44,0.5,(mp.Y/vs.Y-0.5)*22)
            for _,p in ipairs(parts) do local t2=tick()*p.sp+p.ph; p.f.Position=UDim2.new(p.bx+math.sin(t2)*p.rg,0,p.by+math.cos(t2*1.3)*p.rg,0) end
        end); table.insert(splashConns,rsC)

        local steps={{l="VERIFYING MODULES",p=0.20},{l="INJECTING SCRIPTS",p=0.42},{l="LOADING ASSETS",p=0.64},{l="BUILDING INTERFACE",p=0.86},{l="COMPLETE",p=1.0}}
        for _,s in ipairs(steps) do
            tw(stat,{TextTransparency=1},TI(.06)); task.wait(0.07); stat.Text=s.l
            tw(stat,{TextTransparency=A.TextSec},TI(.10)); tw(pf,{Size=UDim2.new(s.p,0,1,0)},TI(.32,Enum.EasingStyle.Quad))
            task.wait(s.p==1 and 0.32 or 0.26)
        end; task.wait(0.38)

        alive=false
        for _,c in ipairs(splashConns) do pcall(function() c:Disconnect() end) end
        for i=#charLbls,1,-1 do task.spawn(function() task.wait((#charLbls-i)*0.032); tw(charLbls[i],{TextTransparency=1},TI(.16)) end) end
        tw(hub,{TextTransparency=1},TI(.16)); tw(acLine,{BackgroundTransparency=1,Size=UDim2.new(0,0,0,1)},TI(.28,Enum.EasingStyle.Exponential)); task.wait(0.12)
        tw(stat,{TextTransparency=1},TI_FAST); tw(pf,{BackgroundTransparency=1},TI_FAST); tw(pw,{BackgroundTransparency=1},TI_FAST)
        tw(limg,{ImageTransparency=1},TI(.24)); tw(so,{Transparency=1},TI(.20))
        tw(lGlow,{BackgroundTransparency=1},TI(.24)); tw(lCard,{BackgroundTransparency=1},TI(.28))
        for _,l in ipairs(cLines) do tw(l,{BackgroundTransparency=1},TI(.18)) end
        for _,p in ipairs(parts)  do tw(p.f,{BackgroundTransparency=1},TI(.16)) end; task.wait(0.14)
        tw(orb,{BackgroundTransparency=1},TI(.28))
        tw(splash,{BackgroundTransparency=1},TI(.38),function() splash:Destroy() end)
    end)

    -- Notif holder
    local notifHolder=Instance.new("Frame"); notifHolder.Name="Notifs"
    notifHolder.Size=UDim2.new(0,330,1,-16); notifHolder.Position=UDim2.new(0,12,1,-10)
    notifHolder.AnchorPoint=Vector2.new(0,1); notifHolder.BackgroundTransparency=1; notifHolder.ZIndex=200; notifHolder.Parent=gui
    local nList=List(notifHolder,6); nList.VerticalAlignment=Enum.VerticalAlignment.Bottom
    self._notifHolder=notifHolder

    -- ══════════════════════════════════════════════════════════════
    -- MAIN WINDOW  —  Liquid Glass
    -- ══════════════════════════════════════════════════════════════
    -- Outer glow backdrop
    local winBackdrop=Instance.new("Frame"); winBackdrop.Name="WinBackdrop"
    winBackdrop.Size=UDim2.fromOffset(WW+60,WH+60)
    winBackdrop.Position=UDim2.new(0.5,0,0.5,0); winBackdrop.AnchorPoint=Vector2.new(0.5,0.5)
    winBackdrop.BackgroundColor3=T.Accent; winBackdrop.BackgroundTransparency=0.94
    winBackdrop.BorderSizePixel=0; winBackdrop.ZIndex=0; winBackdrop.Parent=gui
    Instance.new("UICorner",winBackdrop).CornerRadius=UDim.new(0,28)

    local win=Box({
        Name="OGSentenceWin", Sz=UDim2.fromOffset(0,0),
        Pos=UDim2.new(0.5,0,0.5,0), AP=Vector2.new(0.5,0.5),
        Bg=T.Glass0, BgA=0, Clip=true, R=20,
        Border=true, BorderCol=T.Frost, BorderA=0, Z=1, Par=gui,
    })

    -- Subtle inner top glow
    local topAccent=Box({Name="TopAccent", Sz=UDim2.new(1,-80,0,1), Pos=UDim2.new(0.5,0,0,0), AP=Vector2.new(0.5,0),
        Bg=T.Frost, BgA=0, R=0, Z=6, Par=win})

    -- ── TITLE BAR — glass pill ────────────────────────────────────
    local titleBar=Box({
        Name="TitleBar", Sz=UDim2.new(1,0,0,TB_H),
        Pos=UDim2.new(0,0,0,0), Bg=T.Glass1, BgA=0, Z=4, Par=win,
    })
    Draggable(titleBar,win)

    -- TB bottom separator
    local tbSep=Instance.new("Frame"); tbSep.Size=UDim2.new(1,0,0,1); tbSep.Position=UDim2.new(0,0,1,-1)
    tbSep.BackgroundColor3=T.Frost; tbSep.BackgroundTransparency=A.SepLine; tbSep.BorderSizePixel=0; tbSep.ZIndex=5; tbSep.Parent=titleBar

    -- Window control buttons — pill group (iOS style)
    local ctrlGroup=Box({Sz=UDim2.new(0,0,0,28), Pos=UDim2.new(1,-12,0.5,0), AP=Vector2.new(1,0.5),
        Bg=T.Glass2, BgA=0.35, R=14, Z=5, Par=titleBar})
    ctrlGroup.AutomaticSize=Enum.AutomaticSize.X; Pad(ctrlGroup,0,0,6,6)
    local ctrlList=List(ctrlGroup,4,Enum.FillDirection.Horizontal,nil,Enum.VerticalAlignment.Center)

    local ctrlBtns={}
    local CTRL_DEFS={
        {key="−",ico="rbxassetid://6031094687",hoverBg=T.Accent,  hoverCol=T.TextPri},
        {key="·",ico="rbxassetid://6031075929",hoverBg=T.Warning,  hoverCol=T.TextPri},
        {key="X",ico="rbxassetid://6031094678",hoverBg=T.Error,    hoverCol=T.TextPri},
    }
    for idx,cd in ipairs(CTRL_DEFS) do
        local cb=Box({Name=cd.key, Sz=UDim2.new(0,24,0,24), Bg=T.Frost, BgA=0.88, R=12, Z=6, Ord=idx, Par=ctrlGroup})
        local cbIco=Img({Ico=cd.ico, Sz=UDim2.new(0,10,0,10), Col=T.TextSec, IA=0.3, Z=7, Par=cb})
        local cl=Btn(cb,8)
        cb.MouseEnter:Connect(function()
            tw(cb,{BackgroundColor3=cd.hoverBg,BackgroundTransparency=0},TI_FAST)
            tw(cbIco,{ImageColor3=cd.hoverCol,ImageTransparency=0},TI_FAST)
        end)
        cb.MouseLeave:Connect(function()
            tw(cb,{BackgroundColor3=T.Frost,BackgroundTransparency=0.88},TI_FAST)
            tw(cbIco,{ImageColor3=T.TextSec,ImageTransparency=0.3},TI_FAST)
        end)
        ctrlBtns[cd.key]={frame=cb,click=cl,ico=cbIco}
    end

    -- Logo + name
    local LOGO_SIZE=30; local LOGO_CENTER=56; local LOGO_GAP=10
    local logoImg=Instance.new("ImageLabel"); logoImg.Name="LogoImg"; logoImg.Size=UDim2.new(0,LOGO_SIZE,0,LOGO_SIZE)
    logoImg.Position=UDim2.new(0,LOGO_CENTER-LOGO_SIZE/2,0.5,0); logoImg.AnchorPoint=Vector2.new(0,0.5)
    logoImg.BackgroundTransparency=1; logoImg.Image=cfg.Icon~="" and ico(cfg.Icon) or LOGO
    logoImg.ScaleType=Enum.ScaleType.Fit; logoImg.ImageTransparency=1; logoImg.ZIndex=5; logoImg.Parent=titleBar
    Instance.new("UICorner",logoImg).CornerRadius=UDim.new(0,8)
    task.spawn(function() tw(logoImg,{ImageTransparency=0},TI_MED) end)

    local txtX=LOGO_CENTER+LOGO_SIZE/2+LOGO_GAP
    local nameLabel=Txt({T=cfg.Name, Sz=UDim2.new(0,240,0,20), Pos=UDim2.new(0,txtX,0,7),
        Font=Enum.Font.GothamBold, TS=16, Col=T.TextPri, Alpha=1, Z=5, Par=titleBar})
    local subLabel=Txt({T=cfg.Subtitle~="" and cfg.Subtitle or "v"..Sentence.Version,
        Sz=UDim2.new(0,200,0,13), Pos=UDim2.new(0,txtX,0,28),
        Font=Enum.Font.Gotham, TS=12, Col=T.TextSec, Alpha=A.TextSec, Z=5, Par=titleBar})

    -- ── SIDEBAR — slick icon rail ──────────────────────────────────
    local SW=56
    local sidebar=Box({Name="Sidebar", Sz=UDim2.new(0,SW,1,-TB_H), Pos=UDim2.new(0,0,0,TB_H),
        Bg=T.Glass1, BgA=0.60, Z=3, Par=win})

    -- Sidebar right separator
    local sbSep=Instance.new("Frame"); sbSep.Size=UDim2.new(0,1,1,0); sbSep.Position=UDim2.new(1,-1,0,0)
    sbSep.BackgroundColor3=T.Frost; sbSep.BackgroundTransparency=A.SepLine; sbSep.BorderSizePixel=0; sbSep.ZIndex=4; sbSep.Parent=sidebar

    local tabList=Instance.new("ScrollingFrame"); tabList.Name="TabList"
    tabList.Size=UDim2.new(1,0,1,-50); tabList.Position=UDim2.new(0,0,0,10)
    tabList.BackgroundTransparency=1; tabList.BorderSizePixel=0; tabList.ScrollBarThickness=0
    tabList.AutomaticCanvasSize=Enum.AutomaticSize.Y; tabList.ZIndex=4; tabList.Parent=sidebar
    List(tabList,2,Enum.FillDirection.Vertical,Enum.HorizontalAlignment.Center); Pad(tabList,4,4,0,0)

    -- Avatar at bottom of sidebar
    local avWrap=Box({Sz=UDim2.new(0,36,0,36), Pos=UDim2.new(0.5,0,1,-10), AP=Vector2.new(0.5,1),
        Bg=T.Glass2, BgA=0.50, R=18, Z=4, Par=sidebar})
    local avImg=Instance.new("ImageLabel"); avImg.Size=UDim2.new(1,0,1,0); avImg.BackgroundTransparency=1; avImg.ZIndex=5; avImg.Parent=avWrap; Instance.new("UICorner",avImg).CornerRadius=UDim.new(0,18)
    local avS=Instance.new("UIStroke"); avS.Color=T.Frost; avS.Thickness=1.5; avS.Transparency=0.65; avS.Parent=avWrap
    pcall(function() avImg.Image=Plrs:GetUserThumbnailAsync(LP.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size48x48) end)

    -- Tooltip
    local tooltip=Box({Name="TT", Sz=UDim2.new(0,0,0,28), Pos=UDim2.new(0,SW+8,0,0),
        Bg=T.Glass2, BgA=0.40, R=14, Z=20, Vis=false, Par=win})
    tooltip.AutomaticSize=Enum.AutomaticSize.X; Pad(tooltip,0,0,12,12)
    local ttBorder=Instance.new("UIStroke"); ttBorder.Color=T.Frost; ttBorder.Transparency=A.GlassBorder; ttBorder.Thickness=1; ttBorder.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; ttBorder.Parent=tooltip
    local ttL=Txt({T="", Sz=UDim2.new(0,0,1,0), Font=Enum.Font.GothamSemibold, TS=13, Col=T.TextPri, Z=21, Par=tooltip}); ttL.AutomaticSize=Enum.AutomaticSize.X

    local contentArea=Box({Name="Content", Sz=UDim2.new(1,-SW,1,-TB_H), Pos=UDim2.new(0,SW,0,TB_H),
        Bg=T.Base, BgA=0, Clip=true, Z=2, Par=win})

    local W={_gui=gui,_win=win,_content=contentArea,_tabs={},_activeTab=nil,_visible=true,_minimized=false,_cfg=cfg}

    local function SwitchTab(id)
        for _,tab in ipairs(W._tabs) do
            local on=tab.id==id
            tab.page.Visible=on
            if on then
                tw(tab.box,{BackgroundColor3=T.Accent,BackgroundTransparency=0},TI_MED)
                tw(tab.ico,{ImageColor3=T.TextPri,ImageTransparency=0},TI_MED)
                local bs=tab.box:FindFirstChildOfClass("UIStroke"); if bs then tw(bs,{Transparency=1},TI_MED) end
                W._activeTab=id
            else
                tw(tab.box,{BackgroundColor3=T.Frost,BackgroundTransparency=0.90},TI_MED)
                tw(tab.ico,{ImageColor3=T.TextSec,ImageTransparency=A.TextSec},TI_MED)
                local bs=tab.box:FindFirstChildOfClass("UIStroke"); if bs then tw(bs,{Transparency=A.GlassBorder},TI_FAST) end
            end
        end
    end

    -- ── Loading Screen ─────────────────────────────────────────────
    if cfg.LoadingEnabled then
        local lf=Box({Name="Loading",Sz=UDim2.new(1,0,1,0),Bg=T.Base,BgA=0,Z=50,Par=win}); Instance.new("UICorner",lf).CornerRadius=UDim.new(0,20)
        local lLogo=Img({Ico=cfg.Icon,Sz=UDim2.new(0,32,0,32),Pos=UDim2.new(0.5,0,0.5,-54),AP=Vector2.new(0.5,0.5),Col=T.TextPri,Z=51,Par=lf})
        local lT=Txt({T=cfg.LoadingTitle,    Sz=UDim2.new(1,0,0,28),Pos=UDim2.new(0.5,0,0.5,-14),AP=Vector2.new(0.5,0.5),Font=Enum.Font.GothamBold,TS=26,Col=T.TextPri,AX=Enum.TextXAlignment.Center,Alpha=1,Z=51,Par=lf})
        local lS=Txt({T=cfg.LoadingSubtitle, Sz=UDim2.new(1,0,0,17),Pos=UDim2.new(0.5,0,0.5, 18),AP=Vector2.new(0.5,0.5),Font=Enum.Font.Gotham,TS=14,Col=T.TextSec,AX=Enum.TextXAlignment.Center,Alpha=1,Z=51,Par=lf})
        local pTrack=Box({Sz=UDim2.new(0.42,0,0,3),Pos=UDim2.new(0.5,0,0.5,48),AP=Vector2.new(0.5,0.5),Bg=T.Frost,BgA=0.92,R=2,Z=51,Par=lf})
        local pFill=Box({Sz=UDim2.new(0,0,1,0),Bg=T.Accent,R=2,Z=52,Par=pTrack})
        local pfG2=Instance.new("UIGradient"); pfG2.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.Teal),ColorSequenceKeypoint.new(1,T.AccentGlow)}; pfG2.Parent=pFill
        local pctL=Txt({T="0%",Sz=UDim2.new(1,0,0,16),Pos=UDim2.new(0.5,0,0.5,58),AP=Vector2.new(0.5,0.5),Font=Enum.Font.Gotham,TS=13,Col=T.Accent,AX=Enum.TextXAlignment.Center,Z=51,Par=lf})
        tw(win,{Size=FULL},TI_SLOW); tw(winBackdrop,{Size=UDim2.fromOffset(WW+60,WH+60)},TI_SLOW); task.wait(0.3)
        tw(lT,{TextTransparency=0},TI_MED); task.wait(0.1); tw(lS,{TextTransparency=A.TextSec},TI_MED)
        if cfg.Icon~="" then tw(lLogo,{ImageTransparency=0},TI_MED) end
        local pct=0
        for _,s in ipairs({0.12,0.08,0.15,0.1,0.18,0.12,0.1,0.15}) do
            pct=math.min(pct+s,1); tw(pFill,{Size=UDim2.new(pct,0,1,0)},TI(.25,Enum.EasingStyle.Quad))
            pctL.Text=math.floor(pct*100).."%"; task.wait(0.13+math.random()*0.1)
        end
        pctL.Text="100%"; tw(pFill,{Size=UDim2.new(1,0,1,0)},TI_FAST); task.wait(0.3)
        tw(lT,{TextTransparency=1},TI_FAST); tw(lS,{TextTransparency=1},TI_FAST); tw(pctL,{TextTransparency=1},TI_FAST)
        tw(pTrack,{BackgroundTransparency=1},TI_FAST); tw(pFill,{BackgroundTransparency=1},TI_FAST)
        if cfg.Icon~="" then tw(lLogo,{ImageTransparency=1},TI_FAST) end
        task.wait(0.18); tw(lf,{BackgroundTransparency=1},TI_MED,function() lf:Destroy() end); task.wait(0.28)
    else
        tw(win,{Size=FULL},TI_SLOW); tw(winBackdrop,{Size=UDim2.fromOffset(WW+60,WH+60)},TI_SLOW); task.wait(0.35)
    end

    -- Reveal title bar elements
    tw(win:FindFirstChildOfClass("UIStroke"),{Transparency=A.GlassBorder},TI_MED)
    tw(topAccent,{BackgroundTransparency=0.82},TI_MED)
    tw(nameLabel,{TextTransparency=0},TI_MED)
    tw(subLabel,{TextTransparency=A.TextSec},TI_MED)

    -- ── Window actions ─────────────────────────────────────────────
    local function DoClose()
        local blocker=Instance.new("Frame"); blocker.Size=UDim2.new(1,0,1,0); blocker.BackgroundTransparency=1; blocker.ZIndex=900; blocker.Parent=gui; Btn(blocker,901)
        local ov=Box({Sz=UDim2.new(1,0,1,0),Bg=T.Base,BgA=1,Z=500,Par=win}); Instance.new("UICorner",ov).CornerRadius=UDim.new(0,20)
        local oLogo=Instance.new("ImageLabel"); oLogo.Size=UDim2.new(0,54,0,54); oLogo.Position=UDim2.new(0.5,0,0.5,-72); oLogo.AnchorPoint=Vector2.new(0.5,0.5); oLogo.BackgroundTransparency=1; oLogo.Image=LOGO; oLogo.ScaleType=Enum.ScaleType.Fit; oLogo.ImageTransparency=1; oLogo.ZIndex=501; oLogo.Parent=ov
        local oName=Txt({T=cfg.Name,    Sz=UDim2.new(1,0,0,26),Pos=UDim2.new(0.5,0,0.5,-26),AP=Vector2.new(0.5,0.5),Font=Enum.Font.GothamBold,TS=24,Col=T.TextPri,AX=Enum.TextXAlignment.Center,Alpha=1,Z=501,Par=ov})
        local oSub =Txt({T="See you soon",Sz=UDim2.new(1,0,0,17),Pos=UDim2.new(0.5,0,0.5,6),AP=Vector2.new(0.5,0.5),Font=Enum.Font.Gotham,TS=14,Col=T.TextSec,AX=Enum.TextXAlignment.Center,Alpha=A.TextSec,Z=501,Par=ov})
        local cl2=Box({Sz=UDim2.new(0,180,0,2),Pos=UDim2.new(0.5,0,0.5,32),AP=Vector2.new(0.5,0.5),Bg=T.Frost,BgA=0.90,R=1,Z=501,Par=ov})
        local cf=Box({Sz=UDim2.new(0,0,1,0),Bg=T.Accent,R=1,Z=502,Par=cl2})
        local pfG3=Instance.new("UIGradient"); pfG3.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.Teal),ColorSequenceKeypoint.new(1,T.AccentGlow)}; pfG3.Parent=cf
        tw(ov,{BackgroundTransparency=0},TI(.2)); tw(oLogo,{ImageTransparency=0},TI_MED); tw(oName,{TextTransparency=0},TI_MED); tw(oSub,{TextTransparency=A.TextSec},TI_MED); tw(cl2,{BackgroundTransparency=0.90},TI_FAST); tw(cf,{BackgroundTransparency=0},TI_FAST); task.wait(0.12)
        tw(cf,{Size=UDim2.new(1,0,1,0)},TI(.55,Enum.EasingStyle.Quad)); task.wait(0.32)
        tw(win,{Size=UDim2.fromOffset(WW,0),BackgroundTransparency=1},TI(.38,Enum.EasingStyle.Back,Enum.EasingDirection.In))
        tw(winBackdrop,{BackgroundTransparency=1},TI(.38)); task.wait(0.42); Sentence:Destroy()
    end

    local function DoMinimize()
        if W._minimized then
            W._minimized=false; win.ClipsDescendants=true
            tw(win,{Size=FULL},TI_SPRING,function() sidebar.Visible=true; contentArea.Visible=true; win.ClipsDescendants=true end)
            tw(winBackdrop,{Size=UDim2.fromOffset(WW+60,WH+60)},TI_SPRING)
        else
            W._minimized=true; sidebar.Visible=false; contentArea.Visible=false
            tw(win,{Size=MINI},TI(.26,Enum.EasingStyle.Back,Enum.EasingDirection.Out))
            tw(winBackdrop,{Size=UDim2.fromOffset(WW+40,MINI.Y.Offset+40)},TI(.26))
        end
    end

    local function HideW()
        W._visible=false
        tw(win,{Position=UDim2.new(0.5,0,1.3,0),Size=UDim2.fromOffset(WW*0.88,WH*0.88),BackgroundTransparency=1},TI(.40,Enum.EasingStyle.Back,Enum.EasingDirection.In),function() win.Visible=false; win.Size=W._minimized and MINI or FULL; win.BackgroundTransparency=A.GlassBg end)
        tw(winBackdrop,{BackgroundTransparency=1},TI(.32))
    end
    local function ShowW()
        win.Visible=true; W._visible=true
        win.Position=UDim2.new(0.5,0,1.3,0); win.Size=UDim2.fromOffset(WW*0.88,(W._minimized and MINI or FULL).Y.Offset*0.88); win.BackgroundTransparency=1
        tw(win,{Position=UDim2.new(0.5,0,0.5,0),Size=W._minimized and MINI or FULL,BackgroundTransparency=A.GlassBg},TI_SPRING)
        winBackdrop.BackgroundTransparency=0.94; tw(winBackdrop,{BackgroundTransparency=0.94},TI_SPRING)
    end

    ctrlBtns["X"].click.MouseButton1Click:Connect(DoClose)
    ctrlBtns["·"].click.MouseButton1Click:Connect(function() Sentence:Notify({Title="Hidden",Content="Press "..cfg.ToggleBind.Name.." to restore.",Type="Info"}); HideW() end)
    ctrlBtns["−"].click.MouseButton1Click:Connect(DoMinimize)
    track(UIS.InputBegan:Connect(function(inp,proc)
        if proc then return end
        if inp.KeyCode==cfg.ToggleBind then if W._visible then HideW() else ShowW() end end
    end))

    -- Apply initial window transparency after loading
    task.defer(function()
        tw(win,{BackgroundTransparency=A.GlassBg},TI_MED)
        tw(titleBar,{BackgroundTransparency=0.55},TI_MED)
        tw(sidebar,{BackgroundTransparency=0.60},TI_MED)
    end)

    -- ══════════════════════════════════════════════════════════════
    -- HOME TAB  —  Liquid Glass layout
    -- ══════════════════════════════════════════════════════════════
    function W:CreateHomeTab(hCfg)
        hCfg=merge({Icon="home"},hCfg or {})
        local id="Home"

        -- Pill tab icon
        local hBox=Box({Name="HomeTB", Sz=UDim2.new(0,40,0,40),
            Bg=T.Frost, BgA=0.90, R=12, Z=5, Par=tabList})
        local hIco=Img({Ico=hCfg.Icon, Sz=UDim2.new(0,18,0,18), Col=T.TextSec, IA=A.TextSec, Z=6, Par=hBox})
        local hCL=Btn(hBox,7)
        -- No visible bar — active state is full bg fill (iOS style)
        local hBar=Box({Sz=UDim2.new(0,0,0,0), BgA=1, Z=1, Par=hBox}) -- dummy for SwitchTab compat

        -- Scrollable page
        local hPage=Instance.new("ScrollingFrame"); hPage.Name="HomePage"
        hPage.Size=UDim2.new(1,0,1,0); hPage.BackgroundTransparency=1; hPage.BorderSizePixel=0
        hPage.ScrollBarThickness=2; hPage.ScrollBarImageColor3=T.Frost
        hPage.ScrollBarImageTransparency=0.75
        hPage.CanvasSize=UDim2.new(0,0,0,0); hPage.AutomaticCanvasSize=Enum.AutomaticSize.Y
        hPage.ZIndex=3; hPage.Visible=false; hPage.Parent=contentArea
        List(hPage,12); Pad(hPage,18,18,16,16)

        -- ── PLAYER IDENTITY CARD ──────────────────────────────────
        local pCard,pcS=GlassCard({Name="PlayerCard", Sz=UDim2.new(1,0,0,92), BgA=A.GlassBg, R=18, Z=3, Par=hPage})
        -- Gradient tint — subtle accent wash
        local pcGrad=Instance.new("UIGradient")
        pcGrad.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,H("#0d1a30")),ColorSequenceKeypoint.new(1,T.Glass0)}
        pcGrad.Rotation=0; pcGrad.Parent=pCard

        -- Avatar
        local pAv=Instance.new("ImageLabel"); pAv.Size=UDim2.new(0,56,0,56); pAv.Position=UDim2.new(0,16,0.5,0); pAv.AnchorPoint=Vector2.new(0,0.5)
        pAv.BackgroundTransparency=1; pAv.ZIndex=6; pAv.Parent=pCard; Instance.new("UICorner",pAv).CornerRadius=UDim.new(0,28)
        local pAvR=Instance.new("UIStroke"); pAvR.Color=T.Frost; pAvR.Thickness=2; pAvR.Transparency=0.60; pAvR.Parent=pAv
        pcall(function() pAv.Image=Plrs:GetUserThumbnailAsync(LP.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size150x150) end)

        Txt({T=LP.DisplayName, Sz=UDim2.new(1,-130,0,22), Pos=UDim2.new(0,86,0,16), Font=Enum.Font.GothamBold, TS=20, Col=T.TextPri, Z=6, Par=pCard})
        Txt({T="@"..LP.Name,   Sz=UDim2.new(1,-130,0,16), Pos=UDim2.new(0,86,0,42), Font=Enum.Font.Gotham, TS=14, Col=T.TextSec, Alpha=A.TextSec, Z=6, Par=pCard})

        -- Version badge — pill
        local vBadge=Box({Sz=UDim2.new(0,0,0,20), Pos=UDim2.new(1,-14,0,12), AP=Vector2.new(1,0),
            Bg=T.Accent, BgA=0.82, R=10, Z=6, Par=pCard})
        vBadge.AutomaticSize=Enum.AutomaticSize.X; Pad(vBadge,0,0,8,8)
        Txt({T="SENTENCE v"..Sentence.Version, Sz=UDim2.new(0,0,1,0), Font=Enum.Font.GothamBold,
            TS=11, Col=T.TextPri, AX=Enum.TextXAlignment.Center, AutoX=true, Z=7, Par=vBadge})

        -- ── SERVER STATS CARD ─────────────────────────────────────
        local sCard,scS=GlassCard({Name="ServerCard", Sz=UDim2.new(1,0,0,120), BgA=A.GlassBg, R=18, Z=3, Par=hPage})
        -- Header
        local sHdr=Box({Sz=UDim2.new(1,0,0,34), Bg=T.Frost, BgA=0.97, R=0, Z=3, Par=sCard})
        -- Inner corner clip
        Instance.new("UICorner",sHdr).CornerRadius=UDim.new(0,18)
        Txt({T="SERVER", Sz=UDim2.new(0,0,0,14), Pos=UDim2.new(0,16,0.5,0), AP=Vector2.new(0,0.5),
            Font=Enum.Font.GothamBold, TS=11, Col=T.Accent, AutoX=true, Z=4, Par=sHdr})
        Txt({T="STATISTICS", Sz=UDim2.new(0,0,0,14), Pos=UDim2.new(0,80,0.5,0), AP=Vector2.new(0,0.5),
            Font=Enum.Font.GothamBold, TS=11, Col=T.TextSec, Alpha=A.TextSec, AutoX=true, Z=4, Par=sHdr})

        -- 2×2 stat grid
        local statVals={}
        local statDefs={{"PLAYERS",""},{"PING",""},{"UPTIME",""},{"REGION",""}}
        for i,sd in ipairs(statDefs) do
            local col=(i-1)%2; local row=math.floor((i-1)/2)
            local cW=(WW-SW)/2-8; local x=14+col*cW; local y=38+row*40
            Txt({T=sd[1], Sz=UDim2.new(0,130,0,12), Pos=UDim2.new(0,x,0,y),
                Font=Enum.Font.GothamBold, TS=11, Col=T.TextSec, Alpha=A.TextSec, Z=4, Par=sCard})
            statVals[sd[1]]=Txt({T="—", Sz=UDim2.new(0,170,0,22), Pos=UDim2.new(0,x,0,y+13),
                Font=Enum.Font.GothamBold, TS=18, Col=T.TextPri, Z=4, Par=sCard})
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

        -- Section API
        local HomeObj=BuildSectionAPI(hPage)
        HomeObj.Activate=function() SwitchTab(id) end

        table.insert(W._tabs,{id=id,box=hBox,page=hPage,bar=hBar,ico=hIco})
        hCL.MouseButton1Click:Connect(function() SwitchTab(id) end)
        hBox.MouseEnter:Connect(function()
            if W._activeTab~=id then tw(hBox,{BackgroundTransparency=0.80},TI_FAST) end
            ttL.Text="Home"; tooltip.Visible=true
            tw(tooltip,{Position=UDim2.new(0,SW+8,0,hBox.AbsolutePosition.Y-win.AbsolutePosition.Y+8)},TI_FAST)
        end)
        hBox.MouseLeave:Connect(function()
            if W._activeTab~=id then tw(hBox,{BackgroundTransparency=0.90},TI_FAST) end
            tooltip.Visible=false
        end)
        SwitchTab(id)
        return HomeObj
    end

    -- ══════════════════════════════════════════════════════════════
    -- CREATE TAB
    -- ══════════════════════════════════════════════════════════════
    function W:CreateTab(tCfg)
        tCfg=merge({Name="Tab",Icon="unk",ShowTitle=true},tCfg or {})
        local id=tCfg.Name

        local tBox=Box({Name=id.."TB", Sz=UDim2.new(0,40,0,40),
            Bg=T.Frost, BgA=0.90, R=12, Z=5, Ord=#W._tabs+1, Par=tabList})
        local tIco=Img({Ico=tCfg.Icon, Sz=UDim2.new(0,18,0,18), Col=T.TextSec, IA=A.TextSec, Z=6, Par=tBox})
        local tCL=Btn(tBox,7)
        local tBar=Box({Sz=UDim2.new(0,0,0,0),BgA=1,Z=1,Par=tBox})

        local tPage=Instance.new("ScrollingFrame"); tPage.Name=id
        tPage.Size=UDim2.new(1,0,1,0); tPage.BackgroundTransparency=1; tPage.BorderSizePixel=0
        tPage.ScrollBarThickness=2; tPage.ScrollBarImageColor3=T.Frost; tPage.ScrollBarImageTransparency=0.75
        tPage.CanvasSize=UDim2.new(0,0,0,0); tPage.AutomaticCanvasSize=Enum.AutomaticSize.Y
        tPage.ZIndex=3; tPage.Visible=false; tPage.Parent=contentArea
        List(tPage,10); Pad(tPage,18,18,16,16)

        if tCfg.ShowTitle then
            local tRow=Box({Sz=UDim2.new(1,0,0,36), Bg=T.Base, BgA=0, Z=3, Par=tPage})
            Img({Ico=tCfg.Icon, Sz=UDim2.new(0,16,0,16), Pos=UDim2.new(0,0,0.5,0), AP=Vector2.new(0,0.5), Col=T.Accent, Z=4, Par=tRow})
            Txt({T=tCfg.Name:upper(), Sz=UDim2.new(1,-24,0,20), Pos=UDim2.new(0,24,0.5,0), AP=Vector2.new(0,0.5),
                Font=Enum.Font.GothamBold, TS=19, Col=T.TextPri, Z=4, Par=tRow})
        end

        local Tab=BuildSectionAPI(tPage)
        function Tab:Activate() SwitchTab(id) end

        table.insert(W._tabs,{id=id,box=tBox,page=tPage,bar=tBar,ico=tIco})
        tCL.MouseButton1Click:Connect(function() Tab:Activate() end)
        tBox.MouseEnter:Connect(function()
            if W._activeTab~=id then tw(tBox,{BackgroundTransparency=0.80},TI_FAST) end
            ttL.Text=tCfg.Name; tooltip.Visible=true
            tw(tooltip,{Position=UDim2.new(0,SW+8,0,tBox.AbsolutePosition.Y-win.AbsolutePosition.Y+8)},TI_FAST)
        end)
        tBox.MouseLeave:Connect(function()
            if W._activeTab~=id then tw(tBox,{BackgroundTransparency=0.90},TI_FAST) end
            tooltip.Visible=false
        end)
        return Tab
    end

    function W:SaveConfiguration() end
    function W:LoadConfiguration() end
    return W
end

-- ══════════════════════════════════════════════════════════════════
-- DESTROY
-- ══════════════════════════════════════════════════════════════════
function Sentence:Destroy()
    for _,c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
    self._conns={}
    if self._notifHolder and self._notifHolder.Parent then self._notifHolder.Parent:Destroy() end
    self.Flags={}; self.Options={}
end

return Sentence

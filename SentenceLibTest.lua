--[[
╔═══════════════════════════════════════════════════════════╗
║  SENTENCE GUI · OG Sentence Edition  v2.2                 ║
╚═══════════════════════════════════════════════════════════╝
--]]

local Sentence = {
    Version = "2.2",
    Flags   = {},
    Options = {},
    _conns  = {},
}

-- ── Serwisy ──────────────────────────────────────────────────────────────────
local TS    = game:GetService("TweenService")
local UIS   = game:GetService("UserInputService")
local RS    = game:GetService("RunService")
local Plrs  = game:GetService("Players")
local CG    = game:GetService("CoreGui")
local LP    = Plrs.LocalPlayer
local Cam   = workspace.CurrentCamera
local IsStudio = RS:IsStudio()

-- ── Motyw ─────────────────────────────────────────────────────────────────────
local function H(hex)
    hex = hex:gsub("#","")
    return Color3.fromRGB(
        tonumber("0x"..hex:sub(1,2)),
        tonumber("0x"..hex:sub(3,4)),
        tonumber("0x"..hex:sub(5,6))
    )
end

local T = {
    BG0      = H("#0e0e0e"),  -- najgłębsze tło
    BG1      = H("#121212"),  -- główne tło okna
    BG2      = H("#161616"),  -- sidebar / karta
    BG3      = H("#1c1c1c"),  -- element kontrolki
    BG4      = H("#222222"),  -- hover elementu
    Border   = H("#2a2a2a"),
    BorderHi = H("#3a3a3a"),
    Accent   = H("#5A9FE8"),
    AccentDim= H("#3a6fa8"),
    AccentLo = H("#1e3d5c"),
    Success  = H("#22c55e"),
    Warning  = H("#f59e0b"),
    Error    = H("#ef4444"),
    TextHi   = H("#f0f0f0"),
    TextMid  = H("#b0b0b0"),
    TextLo   = H("#606060"),
}

local NotifPalette = {
    Info    = { fg=T.Accent,   bg=H("#0d1e30"), bar=T.Accent   },
    Success = { fg=T.Success,  bg=H("#0d2218"), bar=T.Success  },
    Warning = { fg=T.Warning,  bg=H("#261c08"), bar=T.Warning  },
    Error   = { fg=T.Error,    bg=H("#280a0a"), bar=T.Error    },
}

-- ── Tween helpers ─────────────────────────────────────────────────────────────
local function TI(t,s,d) return TweenInfo.new(t or .2, s or Enum.EasingStyle.Exponential, d or Enum.EasingDirection.Out) end
local TI_FAST   = TI(.14)
local TI_MED    = TI(.24)
local TI_SLOW   = TI(.50)
local TI_SPRING = TweenInfo.new(.40, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
local TI_BOUNCE = TweenInfo.new(.32, Enum.EasingStyle.Back,  Enum.EasingDirection.Out, 0, true, 0)
local TI_CIRC   = TweenInfo.new(.32, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)

local function tw(o,p,info,cb)
    local t = TS:Create(o, info or TI_MED, p)
    if cb then t.Completed:Once(cb) end
    t:Play(); return t
end

-- ── Util ──────────────────────────────────────────────────────────────────────
local function merge(d,t)
    t=t or {}
    for k,v in pairs(d) do if t[k]==nil then t[k]=v end end
    return t
end
local function track(c) table.insert(Sentence._conns,c); return c end
local function safe(cb,...) local ok,e=pcall(cb,...); if not ok then warn("SENTENCE:"..tostring(e)) end end

local LOGO  = "rbxassetid://117810891565979"
local ICONS = {
    close="rbxassetid://6031094678", min="rbxassetid://6031094687",
    hide="rbxassetid://6031075929",  home="rbxassetid://6031079158",
    info="rbxassetid://6026568227",  warn="rbxassetid://6031071053",
    ok="rbxassetid://6031094667",    arr="rbxassetid://6031090995",
    unk="rbxassetid://6031079152",   notif="rbxassetid://6034308946",
    chev_d="rbxassetid://6031094687",chev_u="rbxassetid://6031094679",
}
local function ico(n)
    if not n or n=="" then return "" end
    if n:find("rbxassetid") then return n end
    if tonumber(n) then return "rbxassetid://"..n end
    return ICONS[n] or ICONS.unk
end

-- ══════════════════════════════════════════════════════════════════════════════
-- PRIMITIVE BUILDERS
-- ══════════════════════════════════════════════════════════════════════════════
local function Box(p)
    p=p or {}
    local f=Instance.new("Frame")
    f.Name=p.Name or "Box"; f.Size=p.Sz or UDim2.new(1,0,0,36)
    f.Position=p.Pos or UDim2.new(); f.AnchorPoint=p.AP or Vector2.zero
    f.BackgroundColor3=p.Bg or T.BG2; f.BackgroundTransparency=p.BgA or 0
    f.BorderSizePixel=0; f.ZIndex=p.Z or 1; f.LayoutOrder=p.Ord or 0
    f.Visible=p.Vis~=false
    if p.Clip  then f.ClipsDescendants=true end
    if p.AutoY then f.AutomaticSize=Enum.AutomaticSize.Y end
    if p.AutoX then f.AutomaticSize=Enum.AutomaticSize.X end
    if p.R~=nil then
        local uc=Instance.new("UICorner")
        uc.CornerRadius=type(p.R)=="number" and UDim.new(0,p.R) or (p.R or UDim.new(0,5))
        uc.Parent=f
    end
    if p.Border then
        local s=Instance.new("UIStroke")
        s.Color=p.BorderCol or T.Border; s.Transparency=p.BorderA or 0
        s.Thickness=1; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=f
    end
    if p.Par then f.Parent=p.Par end
    return f
end

local function Txt(p)
    p=p or {}
    local l=Instance.new("TextLabel")
    l.Name=p.Name or "Txt"; l.Text=p.T or ""; l.Size=p.Sz or UDim2.new(1,0,0,16)
    l.Position=p.Pos or UDim2.new(); l.AnchorPoint=p.AP or Vector2.zero
    l.Font=p.Font or Enum.Font.GothamSemibold; l.TextSize=p.TS or 15
    l.TextColor3=p.Col or T.TextHi; l.TextTransparency=p.Alpha or 0
    l.TextXAlignment=p.AX or Enum.TextXAlignment.Left
    l.TextYAlignment=p.AY or Enum.TextYAlignment.Center
    l.TextWrapped=p.Wrap or false; l.RichText=false
    l.BackgroundTransparency=1; l.BorderSizePixel=0
    l.ZIndex=p.Z or 2; l.LayoutOrder=p.Ord or 0
    if p.AutoY then l.AutomaticSize=Enum.AutomaticSize.Y end
    if p.AutoX then l.AutomaticSize=Enum.AutomaticSize.X end
    if p.Par   then l.Parent=p.Par end
    return l
end

local function Img(p)
    p=p or {}
    local i=Instance.new("ImageLabel")
    i.Name=p.Name or "Img"; i.Image=ico(p.Ico or "")
    i.Size=p.Sz or UDim2.new(0,18,0,18); i.Position=p.Pos or UDim2.new(0.5,0,0.5,0)
    i.AnchorPoint=p.AP or Vector2.new(0.5,0.5); i.ImageColor3=p.Col or T.TextHi
    i.ImageTransparency=p.IA or 0; i.BackgroundTransparency=1
    i.BorderSizePixel=0; i.ZIndex=p.Z or 3; i.ScaleType=Enum.ScaleType.Fit
    if p.Par then i.Parent=p.Par end
    return i
end

local function Btn(par,z)
    local b=Instance.new("TextButton")
    b.Name="Btn"; b.Size=UDim2.new(1,0,1,0)
    b.BackgroundTransparency=1; b.Text=""; b.ZIndex=z or 8; b.Parent=par
    return b
end

local function List(par,gap,dir,ha,va)
    local l=Instance.new("UIListLayout")
    l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,gap or 4)
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

local function Wire(par,vert)
    local f=Instance.new("Frame"); f.BackgroundColor3=T.Border
    f.BackgroundTransparency=0; f.BorderSizePixel=0; f.ZIndex=2
    f.Size=vert and UDim2.new(0,1,1,0) or UDim2.new(1,0,0,1)
    f.Parent=par; return f
end

local function Gradient(par,c0,c1,rot)
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,c0),ColorSequenceKeypoint.new(1,c1)}
    g.Rotation=rot or 0; g.Parent=par; return g
end

local function Draggable(handle,win)
    local drag=false; local ds,sp
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; ds=i.Position; sp=win.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) and drag then
            local d=i.Position-ds
            TS:Create(win,TweenInfo.new(0.07,Enum.EasingStyle.Sine),{
                Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
            }):Play()
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- NOTIFIKACJE — przeprojektowane
-- ══════════════════════════════════════════════════════════════════════════════
function Sentence:Notify(data)
    task.spawn(function()
        data = merge({Title="Notice",Content="",Icon="info",Type="Info",Duration=5},data)
        local pal = NotifPalette[data.Type] or NotifPalette.Info

        -- Karta
        local card = Box({
            Name="NCard", Sz=UDim2.new(0,310,0,0), Pos=UDim2.new(0,0,1,0),
            AP=Vector2.new(0,1), Bg=T.BG1, BgA=1, Clip=true, R=6,
            Border=true, BorderCol=T.Border, BorderA=1, Par=self._notifHolder,
        })

        -- Akcent: cienki górny pasek koloru
        local topAccent = Box({Sz=UDim2.new(1,0,0,2),Pos=UDim2.new(0,0,0,0),Bg=pal.fg,BgA=1,R=0,Z=8,Par=card})

        -- Delikatne tło akcentu (subtone)
        local bgTint = Box({Sz=UDim2.new(1,0,1,0),Bg=pal.bg,BgA=0,R=6,Z=2,Par=card})

        -- Subtelny gradient boczny
        local sideGlow = Box({Sz=UDim2.new(0,80,1,0),Pos=UDim2.new(0,0,0,0),Bg=pal.fg,BgA=1,R=0,Z=3,Par=card})
        Gradient(sideGlow, pal.fg, T.BG1, 0)
        local sideGradG=Instance.new("UIGradient")
        sideGradG.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.88),NumberSequenceKeypoint.new(1,1)}
        sideGradG.Parent=sideGlow

        -- Kółko ikony
        local iconBg = Box({
            Sz=UDim2.new(0,34,0,34), Pos=UDim2.new(0,14,0,0), AP=Vector2.new(0,0.5),
            Bg=pal.bg, BgA=0, R=8, Border=true, BorderCol=pal.fg, BorderA=0.65,
            Z=6, Par=card,
        })
        -- anchorpoint w Y = 0.5 nie działa bez relative parent — ustawimy przez pozycję po zmierzeniu
        local iconImg = Img({Ico=data.Icon,Sz=UDim2.new(0,16,0,16),Col=pal.fg,IA=1,Z=7,Par=iconBg})

        -- Treść
        local cc = Box({Name="CC",Sz=UDim2.new(1,0,0,0),Pos=UDim2.new(0,0,0,0),BgA=1,AutoY=true,Z=5,Par=card})
        Pad(cc,12,14,60,14)
        List(cc,3)

        local ttl = Txt({T=data.Title,Sz=UDim2.new(1,0,0,18),Font=Enum.Font.GothamBold,TS=15,Col=T.TextHi,Alpha=1,Z=6,Par=cc})
        local msg = Txt({T=data.Content,Sz=UDim2.new(1,0,0,0),Font=Enum.Font.Gotham,TS=13,Col=T.TextMid,Alpha=1,Wrap=true,AutoY=true,Z=6,Par=cc})

        -- Progress bar czasu trwania (u dołu)
        local pBar = Box({Sz=UDim2.new(1,0,0,2),Pos=UDim2.new(0,0,1,-2),Bg=T.Border,BgA=0,R=0,Z=6,Par=card})
        local pFill = Box({Sz=UDim2.new(1,0,1,0),Bg=pal.fg,BgA=1,R=0,Z=7,Par=pBar})

        -- Przycisk zamknięcia
        local closeBtn = Box({Sz=UDim2.new(0,18,0,18),Pos=UDim2.new(1,-10,0,10),AP=Vector2.new(1,0),Bg=T.BG3,BgA=1,R=4,Z=8,Par=card})
        local closeIco = Img({Ico="close",Sz=UDim2.new(0,8,0,8),Col=T.TextLo,Z=9,Par=closeBtn})
        local closeCL  = Btn(closeBtn,10)
        closeBtn.MouseEnter:Connect(function() tw(closeBtn,{BackgroundColor3=T.Error},TI_FAST); tw(closeIco,{ImageColor3=T.TextHi},TI_FAST) end)
        closeBtn.MouseLeave:Connect(function() tw(closeBtn,{BackgroundColor3=T.BG3},TI_FAST); tw(closeIco,{ImageColor3=T.TextLo},TI_FAST) end)

        -- ── Animacja wejścia ──────────────────────────────────────────────────
        task.wait()
        local cardH = cc.AbsoluteSize.Y
        iconBg.Position = UDim2.new(0,14,0, cardH/2 - 17)

        -- Wjazd z prawej strony
        card.Position = UDim2.new(1.1,0,1,0)
        tw(card,{Size=UDim2.new(0,310,0,cardH)},TI_MED)
        tw(card,{BackgroundTransparency=0,Position=UDim2.new(0,0,1,0)},TI_CIRC)
        tw(bgTint,{BackgroundTransparency=0},TI_FAST)
        task.wait(0.06)
        tw(card.UIStroke,{Transparency=0.55},TI_FAST)
        tw(topAccent,{BackgroundTransparency=0},TI_FAST)
        tw(iconBg,{BackgroundTransparency=0},TI_FAST)
        if iconBg.UIStroke then tw(iconBg.UIStroke,{Transparency=0.2},TI_FAST) end
        tw(iconImg,{ImageTransparency=0},TI_MED)
        tw(ttl,{TextTransparency=0},TI_MED)
        tw(msg,{TextTransparency=0},TI_MED)
        tw(pBar,{BackgroundTransparency=0},TI_FAST)
        tw(closeBtn,{BackgroundTransparency=0},TI_FAST)

        -- Progress bar odlicza czas
        tw(pFill,{Size=UDim2.new(0,0,1,0)},TI(data.Duration,Enum.EasingStyle.Linear))

        -- Hover — zatrzymuje auto-zamknięcie
        local paused = false
        local pausedPct = 1
        card.MouseEnter:Connect(function()
            paused=true
            tw(card,{BackgroundColor3=T.BG3},TI_FAST)
        end)
        card.MouseLeave:Connect(function()
            paused=false
            tw(card,{BackgroundColor3=T.BG1},TI_FAST)
        end)

        -- ── Czekaj na czas lub klik zamknij ──────────────────────────────────
        local dismissed = false
        closeCL.MouseButton1Click:Connect(function() dismissed=true end)

        local elapsed=0
        repeat task.wait(0.05); if not paused then elapsed=elapsed+0.05 end
        until dismissed or elapsed >= data.Duration

        -- ── Animacja wyjścia — wyjeżdża w prawo ──────────────────────────────
        tw(ttl,{TextTransparency=1},TI_FAST); tw(msg,{TextTransparency=1},TI_FAST)
        tw(iconImg,{ImageTransparency=1},TI_FAST); tw(pFill,{BackgroundTransparency=1},TI_FAST)
        tw(pBar,{BackgroundTransparency=1},TI_FAST); tw(topAccent,{BackgroundTransparency=1},TI_FAST)
        tw(bgTint,{BackgroundTransparency=1},TI_FAST)
        tw(card,{BackgroundTransparency=1},TI_FAST)
        if card.UIStroke then tw(card.UIStroke,{Transparency=1},TI_FAST) end
        tw(card,{Position=UDim2.new(1.1,0,1,0)},TI_CIRC)
        task.wait(0.28)
        tw(card,{Size=UDim2.new(0,310,0,0)},TI_MED,function() card:Destroy() end)
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
    },cfg)

    local vp = Cam.ViewportSize
    local WW = math.clamp(vp.X-100,616,825)
    local WH = math.clamp(vp.Y-80, 440,550)
    local FULL = UDim2.fromOffset(WW,WH)
    local MINI = UDim2.fromOffset(WW,44)

    -- ── ScreenGui ────────────────────────────────────────────────────────────
    local gui=Instance.new("ScreenGui")
    gui.Name="OGSentenceUI"; gui.DisplayOrder=999999999
    gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true
    if gethui then gui.Parent=gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(gui);gui.Parent=CG
    elseif not IsStudio then gui.Parent=CG
    else gui.Parent=LP:WaitForChild("PlayerGui") end

    -- ══════════════════════════════════════════════════════════════════════════
    -- SPLASH SCREEN
    -- ══════════════════════════════════════════════════════════════════════════
    task.spawn(function()
        local splashConns={};  local alive=true

        local splash=Instance.new("Frame")
        splash.Name="Splash"; splash.Size=UDim2.new(1,0,1,0)
        splash.BackgroundColor3=H("#080c10"); splash.BackgroundTransparency=1
        splash.BorderSizePixel=0; splash.ZIndex=1000; splash.ClipsDescendants=true
        splash.Parent=gui

        -- Narożniki
        local cLines={}
        local function MkCorner(ax,ay,rx,ry)
            local r=Instance.new("Frame"); r.Size=UDim2.new(0,36,0,36)
            r.Position=UDim2.new(ax,rx,ay,ry); r.AnchorPoint=Vector2.new(ax,ay)
            r.BackgroundTransparency=1; r.ZIndex=1002; r.Parent=splash
            local h=Instance.new("Frame"); h.Size=UDim2.new(1,0,0,1)
            h.Position=ay==0 and UDim2.new(0,0,0,0) or UDim2.new(0,0,1,-1)
            h.BackgroundColor3=T.Accent; h.BackgroundTransparency=1
            h.BorderSizePixel=0; h.ZIndex=1003; h.Parent=r
            local v=Instance.new("Frame"); v.Size=UDim2.new(0,1,1,0)
            v.Position=ax==0 and UDim2.new(0,0,0,0) or UDim2.new(1,-1,0,0)
            v.BackgroundColor3=T.Accent; v.BackgroundTransparency=1
            v.BorderSizePixel=0; v.ZIndex=1003; v.Parent=r
            table.insert(cLines,h); table.insert(cLines,v)
        end
        MkCorner(0,0,24,24); MkCorner(1,0,-24,24)
        MkCorner(0,1,24,-24); MkCorner(1,1,-24,-24)

        -- Glow blob (parallax)
        local glow=Instance.new("Frame"); glow.Size=UDim2.new(0,540,0,270)
        glow.Position=UDim2.new(0.5,0,0.5,0); glow.AnchorPoint=Vector2.new(0.5,0.5)
        glow.BackgroundColor3=T.Accent; glow.BackgroundTransparency=1
        glow.BorderSizePixel=0; glow.ZIndex=1001; glow.Parent=splash
        Instance.new("UICorner",glow).CornerRadius=UDim.new(1,0)
        local gg=Instance.new("UIGradient")
        gg.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.74),NumberSequenceKeypoint.new(1,1)}
        gg.Parent=glow

        -- Linia skanowania
        local scan=Instance.new("Frame"); scan.Size=UDim2.new(0,2,1,0)
        scan.Position=UDim2.new(-0.02,0,0,0); scan.BackgroundColor3=T.Accent
        scan.BackgroundTransparency=0.5; scan.BorderSizePixel=0; scan.ZIndex=1020; scan.Parent=splash
        local sg=Instance.new("UIGradient")
        sg.Transparency=NumberSequence.new{
            NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.38,0.35),
            NumberSequenceKeypoint.new(0.62,0.35),NumberSequenceKeypoint.new(1,1)}
        sg.Rotation=90; sg.Parent=scan

        -- Logo wrapper (spring: 48→160)
        local lw=Instance.new("Frame"); lw.Name="LW"; lw.Size=UDim2.new(0,48,0,48)
        lw.Position=UDim2.new(0.5,0,0.44,0); lw.AnchorPoint=Vector2.new(0.5,0.5)
        lw.BackgroundTransparency=1; lw.ZIndex=1004; lw.Parent=splash

        local lglow=Instance.new("Frame"); lglow.Size=UDim2.new(2,0,2,0)
        lglow.Position=UDim2.new(0.5,0,0.5,0); lglow.AnchorPoint=Vector2.new(0.5,0.5)
        lglow.BackgroundColor3=T.Accent; lglow.BackgroundTransparency=1
        lglow.BorderSizePixel=0; lglow.ZIndex=1003; lglow.Parent=lw
        Instance.new("UICorner",lglow).CornerRadius=UDim.new(1,0)
        local lgg=Instance.new("UIGradient")
        lgg.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.78),NumberSequenceKeypoint.new(1,1)}
        lgg.Parent=lglow

        -- Pierścień zewnętrzny
        local ro=Instance.new("Frame"); ro.Size=UDim2.new(1,28,1,28)
        ro.Position=UDim2.new(0.5,0,0.5,0); ro.AnchorPoint=Vector2.new(0.5,0.5)
        ro.BackgroundTransparency=1; ro.BorderSizePixel=0; ro.ZIndex=1005; ro.Parent=lw
        Instance.new("UICorner",ro).CornerRadius=UDim.new(1,0)
        local so=Instance.new("UIStroke"); so.Color=T.Accent; so.Thickness=1.5; so.Transparency=0.15; so.Parent=ro
        local go=Instance.new("UIGradient")
        go.Transparency=NumberSequence.new{
            NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.3,0),
            NumberSequenceKeypoint.new(0.65,0.88),NumberSequenceKeypoint.new(1,0)}
        go.Parent=so

        -- Pierścień wewnętrzny
        local ri=Instance.new("Frame"); ri.Size=UDim2.new(1,-16,1,-16)
        ri.Position=UDim2.new(0.5,0,0.5,0); ri.AnchorPoint=Vector2.new(0.5,0.5)
        ri.BackgroundTransparency=1; ri.BorderSizePixel=0; ri.ZIndex=1005; ri.Parent=lw
        Instance.new("UICorner",ri).CornerRadius=UDim.new(1,0)
        local si=Instance.new("UIStroke"); si.Color=H("#4580C9"); si.Thickness=1; si.Transparency=0.45; si.Parent=ri
        local gi=Instance.new("UIGradient")
        gi.Transparency=NumberSequence.new{
            NumberSequenceKeypoint.new(0,0.85),NumberSequenceKeypoint.new(0.28,0),
            NumberSequenceKeypoint.new(0.72,0),NumberSequenceKeypoint.new(1,0.85)}
        gi.Parent=si

        -- Obrazek loga
        local limg=Instance.new("ImageLabel"); limg.Size=UDim2.new(1,0,1,0)
        limg.BackgroundTransparency=1; limg.Image=LOGO; limg.ImageTransparency=1
        limg.ScaleType=Enum.ScaleType.Fit; limg.ZIndex=1006; limg.Parent=lw
        Instance.new("UICorner",limg).CornerRadius=UDim.new(0,10)

        -- Tekst SENTENCE HUB
        local tw2=Instance.new("Frame"); tw2.Size=UDim2.new(0,420,0,0)
        tw2.Position=UDim2.new(0.5,0,0.44,110); tw2.AnchorPoint=Vector2.new(0.5,0)
        tw2.BackgroundTransparency=1; tw2.AutomaticSize=Enum.AutomaticSize.Y
        tw2.ZIndex=1004; tw2.Parent=splash

        local tRow=Instance.new("Frame"); tRow.Size=UDim2.new(1,0,0,0)
        tRow.BackgroundTransparency=1; tRow.AutomaticSize=Enum.AutomaticSize.XY
        tRow.ZIndex=1005; tRow.Parent=tw2
        local trl=Instance.new("UIListLayout"); trl.FillDirection=Enum.FillDirection.Horizontal
        trl.HorizontalAlignment=Enum.HorizontalAlignment.Center
        trl.VerticalAlignment=Enum.VerticalAlignment.Center
        trl.Padding=UDim.new(0,0); trl.SortOrder=Enum.SortOrder.LayoutOrder; trl.Parent=tRow

        local CHARS={"S","E","N","T","E","N","C","E"}; local charLbls={}
        for i,ch in ipairs(CHARS) do
            local l=Instance.new("TextLabel"); l.Text=ch
            l.Size=UDim2.new(0,0,0,0); l.AutomaticSize=Enum.AutomaticSize.XY
            l.Font=Enum.Font.GothamBold; l.TextSize=48; l.TextColor3=T.TextHi
            l.TextTransparency=1; l.BackgroundTransparency=1; l.BorderSizePixel=0
            l.ZIndex=1006; l.LayoutOrder=i; l.RichText=false; l.Parent=tRow
            charLbls[i]=l
        end
        local sp=Instance.new("Frame"); sp.Size=UDim2.new(0,14,0,1)
        sp.BackgroundTransparency=1; sp.BorderSizePixel=0; sp.LayoutOrder=9; sp.Parent=tRow
        local hub=Instance.new("TextLabel"); hub.Text="HUB"
        hub.Size=UDim2.new(0,0,0,0); hub.AutomaticSize=Enum.AutomaticSize.XY
        hub.Font=Enum.Font.GothamBold; hub.TextSize=48; hub.TextColor3=T.Accent
        hub.TextTransparency=1; hub.BackgroundTransparency=1; hub.BorderSizePixel=0
        hub.ZIndex=1006; hub.LayoutOrder=10; hub.RichText=false; hub.Parent=tRow

        local acLine=Instance.new("Frame"); acLine.Size=UDim2.new(0,0,0,2)
        acLine.Position=UDim2.new(0.5,0,0,56); acLine.AnchorPoint=Vector2.new(0.5,0)
        acLine.BackgroundColor3=T.Accent; acLine.BackgroundTransparency=1
        acLine.BorderSizePixel=0; acLine.ZIndex=1005; acLine.Parent=tw2
        Instance.new("UICorner",acLine).CornerRadius=UDim.new(1,0)

        local stat=Instance.new("TextLabel"); stat.Text="INITIALISING CORE"
        stat.Size=UDim2.new(1,0,0,22); stat.Position=UDim2.new(0,0,0,64)
        stat.Font=Enum.Font.Code; stat.TextSize=12; stat.TextColor3=T.TextMid
        stat.TextTransparency=1; stat.BackgroundTransparency=1; stat.BorderSizePixel=0
        stat.ZIndex=1005; stat.TextXAlignment=Enum.TextXAlignment.Center
        stat.RichText=false; stat.Parent=tw2

        local pw=Instance.new("Frame"); pw.Size=UDim2.new(0,260,0,3)
        pw.Position=UDim2.new(0.5,0,0,90); pw.AnchorPoint=Vector2.new(0.5,0)
        pw.BackgroundColor3=H("#1a1f28"); pw.BackgroundTransparency=1
        pw.BorderSizePixel=0; pw.ZIndex=1005; pw.Parent=tw2
        Instance.new("UICorner",pw).CornerRadius=UDim.new(1,0)
        local pf=Instance.new("Frame"); pf.Size=UDim2.new(0,0,1,0)
        pf.BackgroundColor3=T.Accent; pf.BackgroundTransparency=1
        pf.BorderSizePixel=0; pf.ZIndex=1006; pf.Parent=pw
        Instance.new("UICorner",pf).CornerRadius=UDim.new(1,0)
        local pfg=Instance.new("UIGradient")
        pfg.Color=ColorSequence.new{
            ColorSequenceKeypoint.new(0,H("#4580C9")),
            ColorSequenceKeypoint.new(0.6,H("#5A9FE8")),
            ColorSequenceKeypoint.new(1,H("#8BC4FF"))}
        pfg.Parent=pf

        -- Cząsteczki
        local parts={}
        for pi=1,7 do
            local px=Instance.new("Frame"); px.Size=UDim2.new(0,math.random(2,4),0,math.random(2,4))
            px.Position=UDim2.new(math.random(15,85)/100,0,math.random(15,85)/100,0)
            px.AnchorPoint=Vector2.new(0.5,0.5); px.BackgroundColor3=T.Accent
            px.BackgroundTransparency=0.55+math.random()*0.35
            px.BorderSizePixel=0; px.ZIndex=1002; px.Parent=splash
            Instance.new("UICorner",px).CornerRadius=UDim.new(1,0)
            parts[pi]={f=px,bx=math.random(15,85)/100,by=math.random(15,85)/100,
                ph=math.random()*math.pi*2,sp=0.28+math.random()*0.38,
                rg=0.011+math.random()*0.017}
        end

        -- ── Animacja splash ───────────────────────────────────────────────────
        tw(splash,{BackgroundTransparency=0},TI(.38,Enum.EasingStyle.Quad)); task.wait(0.14)
        for _,l in ipairs(cLines) do tw(l,{BackgroundTransparency=0},TI(.48,Enum.EasingStyle.Exponential)) end
        task.wait(0.16)
        tw(scan,{Position=UDim2.new(1.02,0,0,0)},TI(.85,Enum.EasingStyle.Quad)); task.wait(0.08)
        tw(glow,{BackgroundTransparency=0.76},TI(.6,Enum.EasingStyle.Quad)); task.wait(0.06)
        tw(so,{Transparency=0},TI_MED); tw(si,{Transparency=0},TI_MED)
        tw(lw,{Size=UDim2.new(0,160,0,160)},TI_SPRING)
        tw(lglow,{BackgroundTransparency=0.82},TI(.5,Enum.EasingStyle.Quad))
        tw(limg,{ImageTransparency=0},TI(.5,Enum.EasingStyle.Exponential)); task.wait(0.24)
        for i,l in ipairs(charLbls) do
            task.spawn(function() task.wait((i-1)*0.055); tw(l,{TextTransparency=0},TI(.28,Enum.EasingStyle.Back)) end)
        end
        task.wait(0.38)
        tw(hub,{TextTransparency=0},TI(.32,Enum.EasingStyle.Back)); task.wait(0.14)
        tw(acLine,{Size=UDim2.new(0,280,0,2),BackgroundTransparency=0},TI(.45,Enum.EasingStyle.Exponential)); task.wait(0.1)
        tw(stat,{TextTransparency=0.3},TI_MED); tw(pw,{BackgroundTransparency=0},TI_FAST); tw(pf,{BackgroundTransparency=0},TI_FAST)

        local rsC=RS.RenderStepped:Connect(function(dt)
            if not alive then return end
            ro.Rotation=ro.Rotation+88*dt; ri.Rotation=ri.Rotation-52*dt
            local pulse=0.82+math.sin(tick()*2.2)*0.07
            lglow.BackgroundTransparency=1-(1-0.82)*pulse
            local mp=UIS:GetMouseLocation(); local vs=Cam.ViewportSize
            glow.Position=UDim2.new(0.5,(mp.X/vs.X-0.5)*38,0.5,(mp.Y/vs.Y-0.5)*18)
            for _,p in ipairs(parts) do
                local t2=tick()*p.sp+p.ph
                p.f.Position=UDim2.new(p.bx+math.sin(t2)*p.rg,0,p.by+math.cos(t2*1.4)*p.rg,0)
            end
        end)
        table.insert(splashConns,rsC)

        local steps={
            {l="VERIFYING MODULES",p=0.20},{l="INJECTING SCRIPTS",p=0.42},
            {l="LOADING ASSETS",p=0.64},{l="BUILDING INTERFACE",p=0.86},{l="COMPLETE",p=1.0},
        }
        for _,s in ipairs(steps) do
            tw(stat,{TextTransparency=1},TI(.07,Enum.EasingStyle.Quad)); task.wait(0.08)
            stat.Text=s.l
            tw(stat,{TextTransparency=0.3},TI(.1,Enum.EasingStyle.Quad))
            tw(pf,{Size=UDim2.new(s.p,0,1,0)},TI(.36,Enum.EasingStyle.Quad))
            tw(limg,{ImageTransparency=0.22},TI(.06,Enum.EasingStyle.Quad)); task.wait(0.07)
            tw(limg,{ImageTransparency=0},TI(.1,Enum.EasingStyle.Quad))
            task.wait(s.p==1 and 0.3 or 0.28)
        end
        task.wait(0.38)

        alive=false
        for _,c in ipairs(splashConns) do pcall(function() c:Disconnect() end) end
        for i=#charLbls,1,-1 do
            task.spawn(function() task.wait((#charLbls-i)*0.038); tw(charLbls[i],{TextTransparency=1},TI(.18,Enum.EasingStyle.Quad)) end)
        end
        tw(hub,{TextTransparency=1},TI(.18,Enum.EasingStyle.Quad))
        tw(acLine,{BackgroundTransparency=1,Size=UDim2.new(0,0,0,2)},TI(.3,Enum.EasingStyle.Exponential)); task.wait(0.14)
        tw(stat,{TextTransparency=1},TI_FAST); tw(pf,{BackgroundTransparency=1},TI_FAST); tw(pw,{BackgroundTransparency=1},TI_FAST)
        tw(limg,{ImageTransparency=1},TI(.26,Enum.EasingStyle.Quad))
        tw(so,{Transparency=1},TI(.22,Enum.EasingStyle.Quad)); tw(si,{Transparency=1},TI(.22,Enum.EasingStyle.Quad))
        tw(lglow,{BackgroundTransparency=1},TI(.28,Enum.EasingStyle.Quad))
        for _,l in ipairs(cLines) do tw(l,{BackgroundTransparency=1},TI(.2,Enum.EasingStyle.Quad)) end
        for _,p in ipairs(parts) do tw(p.f,{BackgroundTransparency=1},TI(.18,Enum.EasingStyle.Quad)) end
        task.wait(0.16)
        tw(glow,{BackgroundTransparency=1},TI(.32,Enum.EasingStyle.Quad))
        tw(splash,{BackgroundTransparency=1},TI(.42,Enum.EasingStyle.Quad),function() splash:Destroy() end)
    end)

    -- ── Notif Holder ─────────────────────────────────────────────────────────
    local notifHolder=Instance.new("Frame"); notifHolder.Name="Notifs"
    notifHolder.Size=UDim2.new(0,320,1,-16); notifHolder.Position=UDim2.new(0,10,0,8)
    notifHolder.BackgroundTransparency=1; notifHolder.ZIndex=200; notifHolder.Parent=gui
    local nList=List(notifHolder,8); nList.VerticalAlignment=Enum.VerticalAlignment.Bottom
    self._notifHolder=notifHolder

    -- ══════════════════════════════════════════════════════════════════════════
    -- GŁÓWNE OKNO
    -- ══════════════════════════════════════════════════════════════════════════
    local win=Box({
        Name="OGSentenceWin",Sz=UDim2.fromOffset(0,0),
        Pos=UDim2.new(0.5,0,0.5,0),AP=Vector2.new(0.5,0.5),
        Bg=T.BG1,BgA=0,Clip=true,R=6,
        Border=true,BorderCol=T.Border,BorderA=0,Z=1,Par=gui,
    })

    -- Górna linia akcentu
    local topLine=Box({Name="TopLine",Sz=UDim2.new(1,0,0,2),Pos=UDim2.new(0,0,0,0),Bg=T.Accent,BgA=0,Z=6,Par=win})

    -- Gradient w lewym górnym rogu (subtelny blask)
    local winGlow=Box({Name="WinGlow",Sz=UDim2.new(0,260,0,140),Pos=UDim2.new(0,0,0,0),Bg=T.Accent,BgA=0.9,R=0,Z=0,Par=win})
    local wgG=Instance.new("UIGradient")
    wgG.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.88),NumberSequenceKeypoint.new(1,1)}
    wgG.Rotation=130; wgG.Parent=winGlow

    -- ── Title Bar ─────────────────────────────────────────────────────────────
    local TB_H=44
    local titleBar=Box({Name="TitleBar",Sz=UDim2.new(1,0,0,TB_H),Pos=UDim2.new(0,0,0,2),Bg=T.BG1,BgA=1,Z=4,Par=win})
    Draggable(titleBar,win)

    -- Subtelna linia gradientu pod tytułem
    local tbLine=Instance.new("Frame"); tbLine.Size=UDim2.new(1,0,0,1)
    tbLine.Position=UDim2.new(0,0,1,-1); tbLine.BackgroundColor3=T.Border
    tbLine.BackgroundTransparency=0; tbLine.BorderSizePixel=0; tbLine.ZIndex=5; tbLine.Parent=titleBar
    local tbLineG=Instance.new("UIGradient")
    tbLineG.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,T.Accent),
        ColorSequenceKeypoint.new(0.3,T.Border),
        ColorSequenceKeypoint.new(1,T.Border)}
    tbLineG.Parent=tbLine

    -- Przyciski sterowania
    local CTRL={{"X","close",T.Error},{"−","min",T.TextMid},{"·","hide",T.TextMid}}
    local ctrlBtns={}
    for idx,cd in ipairs(CTRL) do
        local xp=10+(idx-1)*30
        local cb=Box({Name=cd[1],Sz=UDim2.new(0,22,0,22),Pos=UDim2.new(0,xp,0.5,0),AP=Vector2.new(0,0.5),Bg=T.BG3,BgA=0.7,R=5,Border=true,BorderCol=T.Border,BorderA=0.2,Z=5,Par=titleBar})
        local ci=Img({Ico=cd[2],Sz=UDim2.new(0,11,0,11),Col=T.TextLo,Z=6,Par=cb})
        local cl=Btn(cb,7)
        cb.MouseEnter:Connect(function()
            tw(cb,{BackgroundColor3=cd[3],BackgroundTransparency=0},TI_FAST)
            tw(ci,{ImageColor3=T.TextHi},TI_FAST)
            if cb.UIStroke then tw(cb.UIStroke,{Color=cd[3],Transparency=0.3},TI_FAST) end
        end)
        cb.MouseLeave:Connect(function()
            tw(cb,{BackgroundColor3=T.BG3,BackgroundTransparency=0.7},TI_FAST)
            tw(ci,{ImageColor3=T.TextLo},TI_FAST)
            if cb.UIStroke then tw(cb.UIStroke,{Color=T.Border,Transparency=0.2},TI_FAST) end
        end)
        ctrlBtns[cd[1]]={frame=cb,click=cl}
    end

    -- Ikona + tytuł
    local IX,IS=108,24
    Img({Ico=cfg.Icon,Sz=UDim2.new(0,IS,0,IS),Pos=UDim2.new(0,IX,0.5,0),AP=Vector2.new(0,0.5),Col=T.TextHi,Z=5,Par=titleBar})
    local nOff=cfg.Icon~="" and (IX+IS+6) or IX
    local nameLabel=Txt({T=cfg.Name,Sz=UDim2.new(0,220,0,20),Pos=UDim2.new(0,nOff,0,4),Font=Enum.Font.GothamBold,TS=17,Col=T.TextHi,Alpha=1,Z=5,Par=titleBar})
    local subLabel =Txt({T=cfg.Subtitle~="" and "/ "..cfg.Subtitle or "/ v"..Sentence.Version,Sz=UDim2.new(0,200,0,13),Pos=UDim2.new(0,nOff,0,25),Font=Enum.Font.Gotham,TS=13,Col=T.TextLo,Alpha=1,Z=5,Par=titleBar})

    -- Stat chips (ping / players)
    local statWrap=Box({Sz=UDim2.new(0,160,0,26),Pos=UDim2.new(1,-10,0.5,0),AP=Vector2.new(1,0.5),Bg=T.BG3,BgA=0,R=5,Z=5,Par=titleBar})
    local pingL=Txt({T="— ms",Sz=UDim2.new(0,72,1,0),Pos=UDim2.new(0,0,0,0),Font=Enum.Font.Code,TS=13,Col=T.TextMid,AX=Enum.TextXAlignment.Right,Z=6,Par=statWrap})
    local sepL =Txt({T="|",   Sz=UDim2.new(0,14,1,0),Pos=UDim2.new(0,74,0,0), Font=Enum.Font.Gotham,TS=12,Col=T.TextLo,AX=Enum.TextXAlignment.Center,Z=6,Par=statWrap})
    local plrsL=Txt({T="—/—", Sz=UDim2.new(0,64,1,0),Pos=UDim2.new(0,90,0,0), Font=Enum.Font.Code,TS=13,Col=T.TextMid,Z=6,Par=statWrap})

    task.spawn(function()
        while task.wait(1.5) do
            if not win or not win.Parent then break end
            pcall(function()
                local ms=math.floor(LP:GetNetworkPing()*1000)
                pingL.Text=ms.."ms"
                pingL.TextColor3 = ms<80 and T.Success or ms<150 and T.Warning or T.Error
                plrsL.Text=#Plrs:GetPlayers().."/"..Plrs.MaxPlayers
            end)
        end
    end)

    -- ── Sidebar ───────────────────────────────────────────────────────────────
    local SW=50
    local sidebar=Box({Name="Sidebar",Sz=UDim2.new(0,SW,1,-TB_H-2),Pos=UDim2.new(0,0,0,TB_H+2),Bg=T.BG2,BgA=0,Z=3,Par=win})

    -- Gradient pionowy na sidebarze
    local sbg=Instance.new("UIGradient")
    sbg.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.BG2),ColorSequenceKeypoint.new(1,T.BG1)}
    sbg.Rotation=90

    local sbWire=Wire(sidebar,true); sbWire.Position=UDim2.new(1,-1,0,0); sbWire.BackgroundColor3=T.Border

    local tabList=Instance.new("ScrollingFrame"); tabList.Name="TabList"
    tabList.Size=UDim2.new(1,0,1,-56); tabList.Position=UDim2.new(0,0,0,14)
    tabList.BackgroundTransparency=1; tabList.BorderSizePixel=0
    tabList.ScrollBarThickness=0; tabList.AutomaticCanvasSize=Enum.AutomaticSize.Y
    tabList.ZIndex=4; tabList.Parent=sidebar
    List(tabList,4,Enum.FillDirection.Vertical,Enum.HorizontalAlignment.Center)
    Pad(tabList,4,4,0,0)

    -- Avatar
    local avBox=Box({Sz=UDim2.new(0,34,0,34),Pos=UDim2.new(0.5,0,1,-12),AP=Vector2.new(0.5,1),Bg=T.BG2,R=5,Z=4,Par=sidebar})
    local avImg=Instance.new("ImageLabel"); avImg.Size=UDim2.new(1,0,1,0)
    avImg.BackgroundTransparency=1; avImg.ZIndex=5; avImg.Parent=avBox
    Instance.new("UICorner",avImg).CornerRadius=UDim.new(0,5)
    local avS=Instance.new("UIStroke"); avS.Color=T.Accent; avS.Thickness=1.5; avS.Transparency=0.5; avS.Parent=avImg
    pcall(function() avImg.Image=Plrs:GetUserThumbnailAsync(LP.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size48x48) end)

    -- Tooltip
    local tooltip=Box({Name="TT",Sz=UDim2.new(0,0,0,28),Pos=UDim2.new(0,SW+6,0,0),Bg=T.BG3,R=5,Border=true,BorderCol=T.Border,BorderA=0,Z=20,Vis=false,Par=win})
    tooltip.AutomaticSize=Enum.AutomaticSize.X
    Pad(tooltip,0,0,10,10)
    local ttL=Txt({T="",Sz=UDim2.new(0,0,1,0),Font=Enum.Font.GothamSemibold,TS=14,Col=T.TextHi,Z=21,Par=tooltip})
    ttL.AutomaticSize=Enum.AutomaticSize.X
    local ttStroke=Instance.new("UIStroke"); ttStroke.Color=T.Accent; ttStroke.Thickness=1; ttStroke.Transparency=0.6; ttStroke.Parent=tooltip

    local contentArea=Box({Name="Content",Sz=UDim2.new(1,-SW-1,1,-TB_H-2),Pos=UDim2.new(0,SW+1,0,TB_H+2),Bg=T.BG1,BgA=1,Clip=true,Z=2,Par=win})

    local W={_gui=gui,_win=win,_content=contentArea,_tabs={},_activeTab=nil,_visible=true,_minimized=false,_cfg=cfg}

    local function SwitchTab(id)
        for _,tab in ipairs(W._tabs) do
            if tab.id==id then
                tab.page.Visible=true
                tw(tab.bar,{BackgroundTransparency=0},TI_FAST)
                tw(tab.ico,{ImageColor3=T.Accent},TI_FAST)
                tw(tab.box,{BackgroundColor3=T.AccentLo,BackgroundTransparency=0},TI_FAST)
                if tab.box.UIStroke then tw(tab.box.UIStroke,{Color=T.Accent,Transparency=0.5},TI_FAST) end
                W._activeTab=id
            else
                tab.page.Visible=false
                tw(tab.bar,{BackgroundTransparency=1},TI_FAST)
                tw(tab.ico,{ImageColor3=T.TextLo},TI_FAST)
                tw(tab.box,{BackgroundColor3=T.BG3,BackgroundTransparency=1},TI_FAST)
                if tab.box.UIStroke then tw(tab.box.UIStroke,{Color=T.Border,Transparency=0.6},TI_FAST) end
            end
        end
    end

    -- ── Ekran ładowania ───────────────────────────────────────────────────────
    if cfg.LoadingEnabled then
        local lf=Box({Name="Loading",Sz=UDim2.new(1,0,1,0),Bg=T.BG1,BgA=0,Z=50,Par=win})
        Instance.new("UICorner",lf).CornerRadius=UDim.new(0,6)
        local lLogo=Img({Ico=cfg.Icon,Sz=UDim2.new(0,32,0,32),Pos=UDim2.new(0.5,0,0.5,-52),AP=Vector2.new(0.5,0.5),Col=T.TextHi,Z=51,Par=lf})
        local lT=Txt({T=cfg.LoadingTitle,    Sz=UDim2.new(1,0,0,26),Pos=UDim2.new(0.5,0,0.5,-14),AP=Vector2.new(0.5,0.5),Font=Enum.Font.GothamBold,TS=24,Col=T.TextHi,AX=Enum.TextXAlignment.Center,Alpha=1,Z=51,Par=lf})
        local lS=Txt({T=cfg.LoadingSubtitle, Sz=UDim2.new(1,0,0,16),Pos=UDim2.new(0.5,0,0.5, 16),AP=Vector2.new(0.5,0.5),Font=Enum.Font.Code,TS=14,Col=T.TextMid,AX=Enum.TextXAlignment.Center,Alpha=1,Z=51,Par=lf})
        local pTrack=Box({Sz=UDim2.new(0.45,0,0,3),Pos=UDim2.new(0.5,0,0.5,44),AP=Vector2.new(0.5,0.5),Bg=T.BG3,R=2,Z=51,Par=lf})
        local pFill=Box({Sz=UDim2.new(0,0,1,0),Bg=T.Accent,R=2,Z=52,Par=pTrack})
        local pctL=Txt({T="0%",Sz=UDim2.new(1,0,0,16),Pos=UDim2.new(0.5,0,0.5,54),AP=Vector2.new(0.5,0.5),Font=Enum.Font.Code,TS=13,Col=T.Accent,AX=Enum.TextXAlignment.Center,Z=51,Par=lf})
        tw(win,{Size=FULL},TI_SLOW); task.wait(0.3)
        tw(lT,{TextTransparency=0},TI_MED); task.wait(0.1); tw(lS,{TextTransparency=0.3},TI_MED)
        if cfg.Icon~="" then tw(lLogo,{ImageTransparency=0},TI_MED) end
        local pct=0
        for _,s in ipairs({0.12,0.08,0.15,0.1,0.18,0.12,0.1,0.15}) do
            pct=math.min(pct+s,1)
            tw(pFill,{Size=UDim2.new(pct,0,1,0)},TI(.25,Enum.EasingStyle.Quad))
            pctL.Text=math.floor(pct*100).."%"; task.wait(0.13+math.random()*0.1)
        end
        pctL.Text="100%"; tw(pFill,{Size=UDim2.new(1,0,1,0)},TI_FAST); task.wait(0.3)
        tw(pFill,{BackgroundColor3=T.TextHi},TI_FAST); task.wait(0.08)
        tw(lT,{TextTransparency=1},TI_FAST); tw(lS,{TextTransparency=1},TI_FAST)
        tw(pctL,{TextTransparency=1},TI_FAST); tw(pTrack,{BackgroundTransparency=1},TI_FAST)
        tw(pFill,{BackgroundTransparency=1},TI_FAST)
        if cfg.Icon~="" then tw(lLogo,{ImageTransparency=1},TI_FAST) end
        task.wait(0.2); tw(lf,{BackgroundTransparency=1},TI_MED,function() lf:Destroy() end); task.wait(0.3)
    else
        tw(win,{Size=FULL},TI_SLOW); task.wait(0.35)
    end

    tw(topLine,  {BackgroundTransparency=0},TI_MED)
    tw(nameLabel,{TextTransparency=0},      TI_MED)
    tw(subLabel, {TextTransparency=0},      TI_MED)

    -- ── Zamknięcie (close screen) ─────────────────────────────────────────────
    local function DoClose()
        -- Blokuj interakcję
        local blocker=Instance.new("Frame"); blocker.Size=UDim2.new(1,0,1,0)
        blocker.BackgroundTransparency=1; blocker.ZIndex=900; blocker.Parent=gui
        Btn(blocker,901)

        -- Overlay ze SENTENCE HUB na srodku
        local ov=Box({Sz=UDim2.new(1,0,1,0),Bg=T.BG0,BgA=1,Z=500,Par=win})
        Instance.new("UICorner",ov).CornerRadius=UDim.new(0,6)

        -- Logo
        local oLogo=Instance.new("ImageLabel"); oLogo.Size=UDim2.new(0,54,0,54)
        oLogo.Position=UDim2.new(0.5,0,0.5,-70); oLogo.AnchorPoint=Vector2.new(0.5,0.5)
        oLogo.BackgroundTransparency=1; oLogo.Image=LOGO; oLogo.ScaleType=Enum.ScaleType.Fit
        oLogo.ImageTransparency=1; oLogo.ZIndex=501; oLogo.Parent=ov

        local oName=Txt({T=cfg.Name,Sz=UDim2.new(1,0,0,24),Pos=UDim2.new(0.5,0,0.5,-26),AP=Vector2.new(0.5,0.5),Font=Enum.Font.GothamBold,TS=22,Col=T.TextHi,AX=Enum.TextXAlignment.Center,Alpha=1,Z=501,Par=ov})
        local oSub =Txt({T="Closing...",Sz=UDim2.new(1,0,0,16),Pos=UDim2.new(0.5,0,0.5, 4),AP=Vector2.new(0.5,0.5),Font=Enum.Font.Code,TS=13,Col=T.TextLo,AX=Enum.TextXAlignment.Center,Alpha=1,Z=501,Par=ov})

        -- Linia postępu zamykania
        local cl2=Box({Sz=UDim2.new(0,200,0,2),Pos=UDim2.new(0.5,0,0.5,30),AP=Vector2.new(0.5,0.5),Bg=T.BG3,R=2,Z=501,Par=ov})
        local cf =Box({Sz=UDim2.new(0,0,1,0),Bg=T.Accent,R=2,Z=502,Par=cl2})

        -- Czerwona obwódka okna
        if win.UIStroke then
            tw(win.UIStroke,{Color=T.Error,Transparency=0.2},TI_MED)
        end

        -- Animacja pojawiania się overlay
        tw(ov,{BackgroundTransparency=0},TI(.2,Enum.EasingStyle.Quad))
        tw(oLogo,{ImageTransparency=0},TI_MED)
        tw(oName,{TextTransparency=0},TI_MED)
        tw(oSub, {TextTransparency=0},TI_MED)
        tw(cl2,  {BackgroundTransparency=0},TI_FAST)
        tw(cf,   {BackgroundTransparency=0},TI_FAST)
        task.wait(0.12)

        -- Pasek postępu wypełnia się
        tw(cf,{Size=UDim2.new(1,0,1,0)},TI(.55,Enum.EasingStyle.Quad))
        task.wait(0.28)

        -- Zmiana tekstu
        oSub.Text="See you soon."
        tw(cf,{BackgroundColor3=T.TextHi},TI_FAST)
        task.wait(0.22)

        -- Cały win kurczy się i zanika jednocześnie
        tw(win,{Size=UDim2.fromOffset(WW,0),BackgroundTransparency=1},TI(.4,Enum.EasingStyle.Back,Enum.EasingDirection.In))
        if win.UIStroke then tw(win.UIStroke,{Transparency=1},TI(.3,Enum.EasingStyle.Quad)) end
        task.wait(0.42)

        Sentence:Destroy()
    end

    -- Minimalizacja — nowa animacja (squeeze + bounce)
    local function DoMinimize()
        if W._minimized then
            -- Rozwijanie: najpierw szerokość, potem pełna wysokość z bounce
            W._minimized=false
            win.ClipsDescendants=true
            tw(win,{Size=FULL},TI_SPRING,function()
                sidebar.Visible=true; contentArea.Visible=true
                win.ClipsDescendants=true
            end)
        else
            W._minimized=true
            sidebar.Visible=false; contentArea.Visible=false
            -- Zwijanie z efektem "squish"
            local squishH=MINI.Y.Offset+6
            tw(win,{Size=UDim2.fromOffset(WW,squishH)},TI(.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out))
            task.wait(0.10)
            tw(win,{Size=MINI},TI(.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out))
        end
    end

    local function HideW()
        W._visible=false
        -- Wyjazd okna w dół ekranu
        tw(win,{Position=UDim2.new(0.5,0,1.2,0),Size=UDim2.fromOffset(WW*0.85,WH*0.85)},TI(.45,Enum.EasingStyle.Back,Enum.EasingDirection.In),function()
            win.Visible=false
            win.Size=W._minimized and MINI or FULL
        end)
    end
    local function ShowW()
        win.Visible=true; W._visible=true
        win.Position=UDim2.new(0.5,0,1.2,0)
        win.Size=UDim2.fromOffset(WW*0.85, (W._minimized and MINI or FULL).Y.Offset*0.85)
        tw(win,{Position=UDim2.new(0.5,0,0.5,0),Size=W._minimized and MINI or FULL},TI_SPRING)
    end

    ctrlBtns["X"].click.MouseButton1Click:Connect(DoClose)
    ctrlBtns["·"].click.MouseButton1Click:Connect(function()
        Sentence:Notify({Title="Hidden",Content="Press "..cfg.ToggleBind.Name.." to restore.",Type="Info"})
        HideW()
    end)
    ctrlBtns["−"].click.MouseButton1Click:Connect(DoMinimize)

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
        hCfg=merge({Icon="home"},hCfg or {})
        local id="Home"
        local hBox=Box({Name="HomeTB",Sz=UDim2.new(0,40,0,40),Bg=T.BG3,BgA=1,R=6,Border=true,BorderCol=T.Border,BorderA=0.5,Z=5,Par=tabList})
        local hBar=Box({Sz=UDim2.new(0,3,0.55,0),Pos=UDim2.new(0,0,0.225,0),Bg=T.Accent,BgA=1,R=0,Z=6,Par=hBox})
        local hIco=Img({Ico=hCfg.Icon,Sz=UDim2.new(0,18,0,18),Col=T.TextLo,Z=6,Par=hBox})
        local hCL=Btn(hBox,7)

        local hPage=Instance.new("ScrollingFrame"); hPage.Name="HomePage"
        hPage.Size=UDim2.new(1,0,1,0); hPage.BackgroundTransparency=1; hPage.BorderSizePixel=0
        hPage.ScrollBarThickness=2; hPage.ScrollBarImageColor3=T.Border
        hPage.CanvasSize=UDim2.new(0,0,0,0); hPage.AutomaticCanvasSize=Enum.AutomaticSize.Y
        hPage.ZIndex=3; hPage.Visible=false; hPage.Parent=contentArea
        List(hPage,12); Pad(hPage,18,18,18,18)

        -- ── Banner / karta profilu ──────────────────────────────────────────
        local pCard=Box({Name="PCard",Sz=UDim2.new(1,0,0,86),Bg=T.BG2,BgA=0,R=6,Border=true,BorderCol=T.Border,Z=3,Par=hPage})
        -- Gradient w tle karty
        local pcBg=Box({Sz=UDim2.new(1,0,1,0),Bg=T.AccentLo,BgA=0,R=6,Z=3,Par=pCard})
        local pcBgG=Instance.new("UIGradient")
        pcBgG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.AccentLo),ColorSequenceKeypoint.new(1,T.BG2)}
        pcBgG.Rotation=0; pcBgG.Parent=pcBg
        -- Lewa linia akcentu
        Box({Sz=UDim2.new(0,3,0.7,0),Pos=UDim2.new(0,0,0.15,0),Bg=T.Accent,R=0,Z=5,Par=pCard})
        local pAv=Instance.new("ImageLabel"); pAv.Size=UDim2.new(0,52,0,52)
        pAv.Position=UDim2.new(0,16,0.5,0); pAv.AnchorPoint=Vector2.new(0,0.5)
        pAv.BackgroundTransparency=1; pAv.ZIndex=6; pAv.Parent=pCard
        Instance.new("UICorner",pAv).CornerRadius=UDim.new(0,5)
        local pAS=Instance.new("UIStroke"); pAS.Color=T.Accent; pAS.Thickness=1.5; pAS.Transparency=0.45; pAS.Parent=pAv
        pcall(function() pAv.Image=Plrs:GetUserThumbnailAsync(LP.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size150x150) end)
        Txt({T=LP.DisplayName,Sz=UDim2.new(1,-96,0,22),Pos=UDim2.new(0,82,0,14),Font=Enum.Font.GothamBold,TS=19,Col=T.TextHi,Z=6,Par=pCard})
        Txt({T="@"..LP.Name,  Sz=UDim2.new(1,-96,0,16),Pos=UDim2.new(0,82,0,38),Font=Enum.Font.Code,TS=14,Col=T.TextMid,Z=6,Par=pCard})

        -- ── Karta statystyk ─────────────────────────────────────────────────
        local sCard=Box({Name="SCard",Sz=UDim2.new(1,0,0,108),Bg=T.BG2,BgA=0,R=6,Border=true,BorderCol=T.Border,Z=3,Par=hPage})
        Txt({T="SRV",       Sz=UDim2.new(0,32,0,14),Pos=UDim2.new(0,14,0,10),Font=Enum.Font.GothamBold,TS=12,Col=T.Accent,Z=4,Par=sCard})
        Txt({T="STATISTICS",Sz=UDim2.new(1,-50,0,14),Pos=UDim2.new(0,48,0,10),Font=Enum.Font.GothamBold,TS=12,Col=T.TextLo,Z=4,Par=sCard})
        -- Separator
        local sSep=Instance.new("Frame"); sSep.Size=UDim2.new(1,-28,0,1); sSep.Position=UDim2.new(0,14,0,28)
        sSep.BackgroundColor3=T.Border; sSep.BackgroundTransparency=0; sSep.BorderSizePixel=0; sSep.ZIndex=3; sSep.Parent=sCard
        local statVals={}
        for i,sd in ipairs({{"PLAYERS",""},{"PING",""},{"UPTIME",""},{"REGION",""}}) do
            local col=(i-1)%2; local row=math.floor((i-1)/2)
            local cW=(WW-SW-50)/2; local x=14+col*cW; local y=34+row*36
            Txt({T=sd[1],Sz=UDim2.new(0,130,0,13),Pos=UDim2.new(0,x,0,y),Font=Enum.Font.GothamBold,TS=12,Col=T.TextLo,Z=4,Par=sCard})
            statVals[sd[1]]=Txt({T="—",Sz=UDim2.new(0,170,0,19),Pos=UDim2.new(0,x,0,y+14),Font=Enum.Font.Code,TS=17,Col=T.TextHi,Z=4,Par=sCard})
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

        table.insert(W._tabs,{id=id,box=hBox,page=hPage,bar=hBar,ico=hIco})
        hCL.MouseButton1Click:Connect(function() SwitchTab(id) end)
        hBox.MouseEnter:Connect(function()
            if W._activeTab~=id then tw(hBox,{BackgroundTransparency=0.88},TI_FAST) end
            ttL.Text="Home"; tooltip.Visible=true
            tw(tooltip,{Position=UDim2.new(0,SW+6,0,hBox.AbsolutePosition.Y-win.AbsolutePosition.Y+8)},TI_FAST)
        end)
        hBox.MouseLeave:Connect(function()
            if W._activeTab~=id then tw(hBox,{BackgroundTransparency=1},TI_FAST) end
            tooltip.Visible=false
        end)
        SwitchTab(id)
        return {Activate=function() SwitchTab(id) end}
    end

    -- ══════════════════════════════════════════════════════════════════════════
    -- CREATE TAB
    -- ══════════════════════════════════════════════════════════════════════════
    function W:CreateTab(tCfg)
        tCfg=merge({Name="Tab",Icon="unk",ShowTitle=true},tCfg or {})
        local Tab={}; local id=tCfg.Name

        local tBox=Box({Name=id.."TB",Sz=UDim2.new(0,40,0,40),Bg=T.BG3,BgA=1,R=6,Border=true,BorderCol=T.Border,BorderA=0.6,Z=5,Ord=#W._tabs+1,Par=tabList})
        local tBar=Box({Sz=UDim2.new(0,3,0.55,0),Pos=UDim2.new(0,0,0.225,0),Bg=T.Accent,BgA=1,R=0,Z=6,Par=tBox})
        local tIco=Img({Ico=tCfg.Icon,Sz=UDim2.new(0,18,0,18),Col=T.TextLo,Z=6,Par=tBox})
        local tCL=Btn(tBox,7)

        local tPage=Instance.new("ScrollingFrame"); tPage.Name=id
        tPage.Size=UDim2.new(1,0,1,0); tPage.BackgroundTransparency=1; tPage.BorderSizePixel=0
        tPage.ScrollBarThickness=2; tPage.ScrollBarImageColor3=T.Border
        tPage.CanvasSize=UDim2.new(0,0,0,0); tPage.AutomaticCanvasSize=Enum.AutomaticSize.Y
        tPage.ZIndex=3; tPage.Visible=false; tPage.Parent=contentArea
        List(tPage,8); Pad(tPage,16,16,18,18)

        if tCfg.ShowTitle then
            local tRow=Box({Sz=UDim2.new(1,0,0,32),BgA=1,Z=3,Par=tPage})
            Img({Ico=tCfg.Icon,Sz=UDim2.new(0,16,0,16),Pos=UDim2.new(0,0,0.5,0),AP=Vector2.new(0,0.5),Col=T.Accent,Z=4,Par=tRow})
            Txt({T=tCfg.Name:upper(),Sz=UDim2.new(1,-24,0,18),Pos=UDim2.new(0,24,0.5,0),AP=Vector2.new(0,0.5),Font=Enum.Font.GothamBold,TS=18,Col=T.TextHi,Z=4,Par=tRow})
        end

        table.insert(W._tabs,{id=id,box=tBox,page=tPage,bar=tBar,ico=tIco})
        function Tab:Activate() SwitchTab(id) end
        tCL.MouseButton1Click:Connect(function() Tab:Activate() end)
        tBox.MouseEnter:Connect(function()
            if W._activeTab~=id then tw(tBox,{BackgroundTransparency=0.88},TI_FAST) end
            ttL.Text=tCfg.Name; tooltip.Visible=true
            tw(tooltip,{Position=UDim2.new(0,SW+6,0,tBox.AbsolutePosition.Y-win.AbsolutePosition.Y+8)},TI_FAST)
        end)
        tBox.MouseLeave:Connect(function()
            if W._activeTab~=id then tw(tBox,{BackgroundTransparency=1},TI_FAST) end
            tooltip.Visible=false
        end)

        -- ── CreateSection ─────────────────────────────────────────────────────
        local _sN=0
        function Tab:CreateSection(sName)
            sName=sName or ""; _sN=_sN+1; local Sec={}
            local shRow=Box({Name="SH",Sz=UDim2.new(1,0,0,sName~="" and 22 or 6),BgA=1,Z=3,Par=tPage,Ord=#tPage:GetChildren()})

            if sName~="" then
                local line=Instance.new("Frame"); line.Size=UDim2.new(1,0,0,1)
                line.Position=UDim2.new(0,0,1,-1); line.BorderSizePixel=0; line.ZIndex=3; line.Parent=shRow
                local lineG=Instance.new("UIGradient")
                lineG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.Accent),ColorSequenceKeypoint.new(0.4,T.Border),ColorSequenceKeypoint.new(1,T.Border)}
                lineG.Parent=line

                local badge=Box({Sz=UDim2.new(0,0,0,18),Pos=UDim2.new(0,0,0.5,0),AP=Vector2.new(0,0.5),Bg=T.BG1,R=0,Z=4,Par=shRow})
                badge.AutomaticSize=Enum.AutomaticSize.X; Pad(badge,0,0,0,8)
                local bRow=Instance.new("Frame"); bRow.Size=UDim2.new(0,0,1,0)
                bRow.AutomaticSize=Enum.AutomaticSize.X; bRow.BackgroundTransparency=1; bRow.ZIndex=5; bRow.Parent=badge
                List(bRow,0,Enum.FillDirection.Horizontal,nil,Enum.VerticalAlignment.Center)
                local nL=Instance.new("TextLabel"); nL.Text="#"..string.format("%02d",_sN).." "
                nL.Size=UDim2.new(0,0,1,0); nL.AutomaticSize=Enum.AutomaticSize.X
                nL.Font=Enum.Font.GothamBold; nL.TextSize=12; nL.TextColor3=T.Accent
                nL.BackgroundTransparency=1; nL.BorderSizePixel=0; nL.ZIndex=5; nL.RichText=false; nL.Parent=bRow
                local nmL=Instance.new("TextLabel"); nmL.Text=sName:upper()
                nmL.Size=UDim2.new(0,0,1,0); nmL.AutomaticSize=Enum.AutomaticSize.X
                nmL.Font=Enum.Font.GothamBold; nmL.TextSize=12; nmL.TextColor3=T.TextLo
                nmL.BackgroundTransparency=1; nmL.BorderSizePixel=0; nmL.ZIndex=5; nmL.RichText=false; nmL.Parent=bRow
            end

            local secCon=Box({Name="SC",Sz=UDim2.new(1,0,0,0),BgA=1,Z=3,AutoY=true,Ord=shRow.LayoutOrder+1,Par=tPage})
            List(secCon,5)

            local function Elem(h,autoY)
                local f=Box({Sz=UDim2.new(1,0,0,h or 40),Bg=T.BG2,BgA=0,R=6,Border=true,BorderCol=T.Border,Z=3,Par=secCon})
                if autoY then f.AutomaticSize=Enum.AutomaticSize.Y end
                -- Subtelny gradient tła
                local fg=Instance.new("UIGradient"); fg.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.BG3),ColorSequenceKeypoint.new(1,T.BG2)}
                fg.Rotation=180; fg.Parent=f
                return f
            end
            local function HoverEff(f)
                f.MouseEnter:Connect(function()
                    tw(f,{BackgroundColor3=T.BG3},TI_FAST)
                    if f.UIStroke then tw(f.UIStroke,{Color=T.BorderHi},TI_FAST) end
                end)
                f.MouseLeave:Connect(function()
                    tw(f,{BackgroundColor3=T.BG2},TI_FAST)
                    if f.UIStroke then tw(f.UIStroke,{Color=T.Border},TI_FAST) end
                end)
            end

            function Sec:CreateDivider()
                local d=Instance.new("Frame"); d.Size=UDim2.new(1,0,0,1)
                local dG=Instance.new("UIGradient")
                dG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.Border),ColorSequenceKeypoint.new(1,T.BG1)}
                dG.Parent=d; d.BackgroundColor3=T.Border; d.BackgroundTransparency=0
                d.BorderSizePixel=0; d.ZIndex=3; d.Parent=secCon
                return {Destroy=function() d:Destroy() end}
            end

            function Sec:CreateLabel(lc)
                lc=merge({Text="Label",Style=1},lc or {})
                local cMap={[1]=T.TextMid,[2]=T.Accent,[3]=T.Warning}
                local f=Elem(32); local xo=lc.Style>1 and 14 or 10
                if lc.Style>1 then Box({Sz=UDim2.new(0,3,0.7,0),Pos=UDim2.new(0,0,0.15,0),Bg=cMap[lc.Style],R=0,Z=5,Par=f}) end
                local lb=Txt({T=lc.Text,Sz=UDim2.new(1,-xo-6,0,15),Pos=UDim2.new(0,xo,0.5,0),AP=Vector2.new(0,0.5),Font=Enum.Font.GothamSemibold,TS=15,Col=cMap[lc.Style],Z=4,Par=f})
                return {Set=function(self,t) lb.Text=t end, Destroy=function() f:Destroy() end}
            end

            function Sec:CreateParagraph(pc)
                pc=merge({Title="Title",Content=""},pc or {})
                local f=Elem(0,true); Pad(f,12,12,14,14); List(f,4)
                local pt=Txt({T=pc.Title,  Sz=UDim2.new(1,0,0,18),Font=Enum.Font.GothamBold,TS=16,Col=T.TextHi,Z=4,Par=f})
                local pc2=Txt({T=pc.Content,Sz=UDim2.new(1,0,0,0),Font=Enum.Font.Gotham,TS=15,Col=T.TextMid,Z=4,Wrap=true,AutoY=true,Par=f})
                return {
                    Set=function(self,s) if s.Title then pt.Text=s.Title end; if s.Content then pc2.Text=s.Content end end,
                    Destroy=function() f:Destroy() end,
                }
            end

            function Sec:CreateButton(bc)
                bc=merge({Name="Button",Description=nil,Callback=function()end},bc or {})
                local f=Elem(bc.Description and 58 or 40); f.ClipsDescendants=true

                -- Ripple fill
                local rFill=Box({Sz=UDim2.new(0,0,1,0),Bg=T.Accent,BgA=1,R=0,Z=3,Par=f})
                local rGrad=Instance.new("UIGradient"); rGrad.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.88),NumberSequenceKeypoint.new(1,1)}; rGrad.Parent=rFill

                -- Akcent lewa krawędź
                local pip=Box({Sz=UDim2.new(0,3,1,0),Pos=UDim2.new(0,0,0,0),Bg=T.Accent,BgA=1,R=0,Z=5,Par=f})

                Txt({T=bc.Name,Sz=UDim2.new(1,-50,0,17),Pos=UDim2.new(0,16,0,bc.Description and 10 or 12),Font=Enum.Font.GothamSemibold,TS=16,Col=T.TextHi,Z=5,Par=f})
                if bc.Description then
                    Txt({T=bc.Description,Sz=UDim2.new(1,-50,0,15),Pos=UDim2.new(0,16,0,30),Font=Enum.Font.Gotham,TS=14,Col=T.TextMid,Z=5,Par=f})
                end
                -- Chevron
                local arr=Img({Ico="arr",Sz=UDim2.new(0,13,0,13),Pos=UDim2.new(1,-20,0.5,0),AP=Vector2.new(0,0.5),Col=T.Accent,IA=0.5,Z=6,Par=f})

                local cl=Btn(f,7)
                f.MouseEnter:Connect(function()
                    tw(rFill,{Size=UDim2.new(1,0,1,0),BackgroundTransparency=0},TI(.28,Enum.EasingStyle.Quad))
                    tw(pip,{BackgroundTransparency=0},TI_FAST)
                    tw(arr,{ImageTransparency=0,ImageColor3=T.TextHi},TI_FAST)
                    if f.UIStroke then tw(f.UIStroke,{Color=T.Accent,Transparency=0.55},TI_FAST) end
                end)
                f.MouseLeave:Connect(function()
                    tw(rFill,{Size=UDim2.new(0,0,1,0),BackgroundTransparency=1},TI_MED)
                    tw(pip,{BackgroundTransparency=1},TI_FAST)
                    tw(arr,{ImageTransparency=0.5,ImageColor3=T.Accent},TI_FAST)
                    if f.UIStroke then tw(f.UIStroke,{Color=T.Border,Transparency=0},TI_FAST) end
                end)
                cl.MouseButton1Click:Connect(function()
                    tw(rFill,{BackgroundColor3=T.TextHi},TI(.08,Enum.EasingStyle.Quad))
                    task.wait(0.10)
                    tw(rFill,{BackgroundColor3=T.Accent,Size=UDim2.new(0,0,1,0),BackgroundTransparency=1},TI_MED)
                    safe(bc.Callback)
                end)
                return {Destroy=function() f:Destroy() end}
            end

            function Sec:CreateToggle(tc)
                tc=merge({Name="Toggle",Description=nil,CurrentValue=false,Flag=nil,Callback=function()end},tc or {})
                local f=Elem(tc.Description and 58 or 40)
                Txt({T=tc.Name,Sz=UDim2.new(1,-72,0,17),Pos=UDim2.new(0,14,0,tc.Description and 10 or 12),Font=Enum.Font.GothamSemibold,TS=16,Col=T.TextHi,Z=5,Par=f})
                if tc.Description then
                    Txt({T=tc.Description,Sz=UDim2.new(1,-72,0,15),Pos=UDim2.new(0,14,0,30),Font=Enum.Font.Gotham,TS=14,Col=T.TextMid,Z=5,Par=f})
                end
                -- Track
                local trk=Box({Sz=UDim2.new(0,46,0,24),Pos=UDim2.new(1,-58,0.5,0),AP=Vector2.new(0,0.5),Bg=T.BG3,R=12,Border=true,BorderCol=T.Border,Z=5,Par=f})
                -- Knob
                local knob=Box({Sz=UDim2.new(0,18,0,18),Pos=UDim2.new(0,3,0.5,0),AP=Vector2.new(0,0.5),Bg=T.TextLo,R=9,Z=6,Par=trk})
                -- Knob wewnętrzna kropka (highlight)
                local kDot=Box({Sz=UDim2.new(0,6,0,6),Pos=UDim2.new(0.5,0,0.5,0),AP=Vector2.new(0.5,0.5),Bg=T.TextHi,BgA=0.6,R=3,Z=7,Par=knob})

                local TV={CurrentValue=tc.CurrentValue,Type="Toggle",Settings=tc}
                local function upd()
                    if TV.CurrentValue then
                        tw(trk,{BackgroundColor3=T.AccentLo},TI_MED)
                        if trk.UIStroke then tw(trk.UIStroke,{Color=T.Accent,Transparency=0.3},TI_MED) end
                        tw(knob,{Position=UDim2.new(1,-21,0.5,0),BackgroundColor3=T.Accent},TI_SPRING)
                        tw(kDot,{BackgroundTransparency=0},TI_FAST)
                    else
                        tw(trk,{BackgroundColor3=T.BG3},TI_MED)
                        if trk.UIStroke then tw(trk.UIStroke,{Color=T.Border,Transparency=0},TI_MED) end
                        tw(knob,{Position=UDim2.new(0,3,0.5,0),BackgroundColor3=T.TextLo},TI_SPRING)
                        tw(kDot,{BackgroundTransparency=1},TI_FAST)
                    end
                end
                upd(); HoverEff(f)
                Btn(f,6).MouseButton1Click:Connect(function()
                    TV.CurrentValue=not TV.CurrentValue; upd(); safe(tc.Callback,TV.CurrentValue)
                end)
                function TV:Set(v) TV.CurrentValue=v; upd(); safe(tc.Callback,v) end
                if tc.Flag then Sentence.Flags[tc.Flag]=TV; Sentence.Options[tc.Flag]=TV end
                return TV
            end

            function Sec:CreateSlider(sc)
                sc=merge({Name="Slider",Range={0,100},Increment=1,CurrentValue=50,Suffix="",Flag=nil,Callback=function()end},sc or {})
                local f=Elem(58)
                Txt({T=sc.Name,Sz=UDim2.new(1,-120,0,17),Pos=UDim2.new(0,14,0,9),Font=Enum.Font.GothamSemibold,TS=16,Col=T.TextHi,Z=5,Par=f})

                local vc=Box({Sz=UDim2.new(0,0,0,22),Pos=UDim2.new(1,-13,0,7),AP=Vector2.new(1,0),Bg=T.AccentLo,R=5,Border=true,BorderCol=T.AccentDim,BorderA=0.4,Z=5,Par=f})
                vc.AutomaticSize=Enum.AutomaticSize.X; Pad(vc,0,0,8,8)
                local vL=Txt({T=tostring(sc.CurrentValue)..sc.Suffix,Sz=UDim2.new(0,0,1,0),Font=Enum.Font.Code,TS=14,Col=T.Accent,AX=Enum.TextXAlignment.Center,Z=6,Par=vc})
                vL.AutomaticSize=Enum.AutomaticSize.X

                -- Track
                local bg=Box({Sz=UDim2.new(1,-28,0,5),Pos=UDim2.new(0,14,0,38),Bg=T.BG3,R=3,Z=5,Par=f})
                local fill=Box({Sz=UDim2.new(0,0,1,0),Bg=T.Accent,R=3,Z=6,Par=bg})
                local fillG=Instance.new("UIGradient"); fillG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,H("#4580C9")),ColorSequenceKeypoint.new(1,H("#8BC4FF"))}; fillG.Parent=fill
                local thumb=Box({Sz=UDim2.new(0,12,0,12),Pos=UDim2.new(0,0,0.5,0),AP=Vector2.new(0.5,0.5),Bg=T.TextHi,R=6,Z=7,Par=bg})
                -- Glow na kciuku
                local thG=Instance.new("UIStroke"); thG.Color=T.Accent; thG.Thickness=2; thG.Transparency=0.5; thG.Parent=thumb

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
                local drag=false; local bCL=Btn(bg,9)
                local function fromInp(i)
                    local rel=math.clamp((i.Position.X-bg.AbsolutePosition.X)/bg.AbsoluteSize.X,0,1)
                    setV(mn+(mx-mn)*rel); safe(sc.Callback,SV.CurrentValue)
                end
                bCL.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                        drag=true; fromInp(i)
                        tw(thumb,{Size=UDim2.new(0,14,0,14)},TI_FAST); tw(thG,{Transparency=0.2},TI_FAST)
                    end
                end)
                UIS.InputEnded:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                        drag=false
                        tw(thumb,{Size=UDim2.new(0,12,0,12)},TI_FAST); tw(thG,{Transparency=0.5},TI_FAST)
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

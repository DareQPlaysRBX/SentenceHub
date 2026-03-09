--[[
╔══════════════════════════════════════════════════════════════════════╗
║  SENTENCE GUI  ·  NEON GRID EDITION  v4.0                          ║
║  Brutalist-Tech / Terminal aesthetic                                 ║
║  Sharp cuts · Segmented controls · Monospace soul                   ║
║                                                                      ║
║  Design language:                                                    ║
║    · Zero rounded corners on controls (raw geometry)                ║
║    · Segmented/stepped UI elements instead of pills                 ║
║    · Scanline texture + grid overlays                               ║
║    · "CRT terminal" color theory: phosphor green + amber + white    ║
║    · Every control reinvented structurally, not just recolored      ║
╚══════════════════════════════════════════════════════════════════════╝
--]]

local Sentence = {
    Version = "4.0",
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

-- ── Color helper ──────────────────────────────────────────────────────────────
local function H(hex)
    hex = hex:gsub("#","")
    return Color3.fromRGB(
        tonumber("0x"..hex:sub(1,2)),
        tonumber("0x"..hex:sub(3,4)),
        tonumber("0x"..hex:sub(5,6))
    )
end

-- ══════════════════════════════════════════════════════════════════════════════
-- THEME  —  CRT Terminal / Brutalist Tech
-- Phosphor green primary, amber secondary, deep charcoal base
-- ══════════════════════════════════════════════════════════════════════════════
local T = {
    -- Base surfaces (very dark, near-black charcoal)
    BG0    = H("#060608"),   -- void
    BG1    = H("#0a0b0e"),   -- window bg
    BG2    = H("#0f1014"),   -- panel
    BG3    = H("#141519"),   -- element
    BG4    = H("#1a1b21"),   -- hover

    -- Structure lines
    Grid   = H("#1a1c24"),   -- grid lines
    Wire   = H("#22242e"),   -- border
    WireHi = H("#363a4a"),   -- active border

    -- Phosphor Green (primary)
    Green  = H("#00ff88"),   -- vivid phosphor
    GreenD = H("#00cc66"),   -- dim
    GreenL = H("#00ff88"),
    GreenBg= H("#001f11"),   -- tint bg

    -- Amber (secondary / warning)
    Amber  = H("#ffaa00"),   -- amber
    AmberD = H("#cc7700"),
    AmberBg= H("#1f1400"),

    -- Ice white (tertiary / labels)
    Ice    = H("#c8d8ff"),   -- cool white
    IceDim = H("#6878a0"),
    IceLo  = H("#2a3050"),

    -- Status
    Ok     = H("#00ff88"),
    Warn   = H("#ffaa00"),
    Err    = H("#ff3355"),

    -- Text
    TxtHi  = H("#e8eeff"),
    TxtMid = H("#7080a8"),
    TxtLo  = H("#2e3550"),
}

local NotifPal = {
    Info    = {fg=T.Ice,   bg=T.BG2, border=T.Ice,  glow=T.IceLo},
    Success = {fg=T.Green, bg=T.BG2, border=T.Green, glow=T.GreenBg},
    Warning = {fg=T.Amber, bg=T.BG2, border=T.Amber, glow=T.AmberBg},
    Error   = {fg=T.Err,  bg=T.BG2, border=T.Err,   glow=T.BG2},
}

-- ── Tweens ────────────────────────────────────────────────────────────────────
local function TI(t,s,d) return TweenInfo.new(t or .16, s or Enum.EasingStyle.Quad, d or Enum.EasingDirection.Out) end
local TF = TI(.12)
local TM = TI(.22)
local TS_ = TI(.40)
local TK = TweenInfo.new(.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local function tw(o,p,i,cb) local t=TS:Create(o,i or TM,p); if cb then t.Completed:Once(cb) end; t:Play(); return t end

-- ── Utilities ─────────────────────────────────────────────────────────────────
local function merge(d,t) t=t or {}; for k,v in pairs(d) do if t[k]==nil then t[k]=v end end; return t end
local function track(c) table.insert(Sentence._conns,c); return c end
local function safe(cb,...) local ok,e=pcall(cb,...); if not ok then warn("SG:"..tostring(e)) end end

local LOGO = "rbxassetid://117810891565979"
local ICONS = {
    close="rbxassetid://6031094678", home="rbxassetid://6031079158",
    info="rbxassetid://6026568227",  warn="rbxassetid://6031071053",
    ok="rbxassetid://6031094667",    arr="rbxassetid://6031090995",
    unk="rbxassetid://6031079152",   min="rbxassetid://6031094687",
    hide="rbxassetid://6031075929",  chev="rbxassetid://6031094687",
    key="rbxassetid://6026568227",
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
    f.Name=p.Name or "Box"; f.Size=p.Sz or UDim2.new(1,0,0,32)
    f.Position=p.Pos or UDim2.new(); f.AnchorPoint=p.AP or Vector2.zero
    f.BackgroundColor3=p.Bg or T.BG2; f.BackgroundTransparency=p.BgA or 0
    f.BorderSizePixel=0; f.ZIndex=p.Z or 1; f.LayoutOrder=p.Ord or 0
    f.Visible=p.Vis~=false
    if p.Clip  then f.ClipsDescendants=true end
    if p.AutoY then f.AutomaticSize=Enum.AutomaticSize.Y end
    if p.AutoX then f.AutomaticSize=Enum.AutomaticSize.X end
    if p.R then
        local uc=Instance.new("UICorner")
        uc.CornerRadius=type(p.R)=="number" and UDim.new(0,p.R) or UDim.new(0,4)
        uc.Parent=f
    end
    if p.Par then f.Parent=p.Par end
    return f
end

local function Txt(p)
    p=p or {}
    local l=Instance.new("TextLabel")
    l.Name=p.Name or "L"; l.Text=p.T or ""; l.Size=p.Sz or UDim2.new(1,0,0,14)
    l.Position=p.Pos or UDim2.new(); l.AnchorPoint=p.AP or Vector2.zero
    l.Font=p.Font or Enum.Font.Code; l.TextSize=p.TS or 13
    l.TextColor3=p.Col or T.TxtHi; l.TextTransparency=p.Alpha or 0
    l.TextXAlignment=p.AX or Enum.TextXAlignment.Left
    l.TextYAlignment=p.AY or Enum.TextYAlignment.Center
    l.TextWrapped=p.Wrap or false; l.RichText=false
    l.BackgroundTransparency=1; l.BorderSizePixel=0
    l.ZIndex=p.Z or 2; l.LayoutOrder=p.Ord or 0
    if p.AutoY then l.AutomaticSize=Enum.AutomaticSize.Y end
    if p.AutoX then l.AutomaticSize=Enum.AutomaticSize.X end
    if p.Par then l.Parent=p.Par end
    return l
end

local function Img(p)
    p=p or {}
    local i=Instance.new("ImageLabel")
    i.Name=p.Name or "Img"; i.Image=ico(p.Ico or "")
    i.Size=p.Sz or UDim2.new(0,14,0,14)
    i.Position=p.Pos or UDim2.new(0.5,0,0.5,0); i.AnchorPoint=p.AP or Vector2.new(0.5,0.5)
    i.ImageColor3=p.Col or T.TxtHi; i.ImageTransparency=p.IA or 0
    i.BackgroundTransparency=1; i.BorderSizePixel=0
    i.ZIndex=p.Z or 3; i.ScaleType=Enum.ScaleType.Fit
    if p.Par then i.Parent=p.Par end
    return i
end

local function Btn(par,z)
    local b=Instance.new("TextButton"); b.Name="Btn"
    b.Size=UDim2.new(1,0,1,0); b.BackgroundTransparency=1
    b.Text=""; b.ZIndex=z or 8; b.Parent=par; return b
end

local function List(par,gap,dir,ha,va)
    local l=Instance.new("UIListLayout"); l.SortOrder=Enum.SortOrder.LayoutOrder
    l.Padding=UDim.new(0,gap or 0); l.FillDirection=dir or Enum.FillDirection.Vertical
    if ha then l.HorizontalAlignment=ha end; if va then l.VerticalAlignment=va end
    l.Parent=par; return l
end

local function Pad(par,t,b,l,r)
    local p=Instance.new("UIPadding")
    p.PaddingTop=UDim.new(0,t or 0); p.PaddingBottom=UDim.new(0,b or 0)
    p.PaddingLeft=UDim.new(0,l or 0); p.PaddingRight=UDim.new(0,r or 0)
    p.Parent=par; return p
end

-- Sharp 1-px border (no UICorner) — the brutalist look
local function Border(par, col, thick, trans)
    local s=Instance.new("UIStroke")
    s.Color=col or T.Wire; s.Thickness=thick or 1
    s.Transparency=trans or 0
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=par; return s
end

-- Corner notch: a tiny cut-corner decoration (Frame rotated in corner)
local function Notch(par, corner, sz, col)
    -- corner: "tl","tr","bl","br"
    sz = sz or 6; col = col or T.Green
    local n = Instance.new("Frame"); n.Size=UDim2.new(0,sz,0,sz)
    n.BackgroundColor3=col; n.BackgroundTransparency=0; n.BorderSizePixel=0; n.ZIndex=10
    if corner=="tl" then n.Position=UDim2.new(0,0,0,0)
    elseif corner=="tr" then n.Position=UDim2.new(1,-sz,0,0)
    elseif corner=="bl" then n.Position=UDim2.new(0,0,1,-sz)
    elseif corner=="br" then n.Position=UDim2.new(1,-sz,1,-sz) end
    n.Parent=par; return n
end

-- Horizontal scan line fill
local function ScanFill(par, density, col, trans)
    density = density or 4; col = col or T.Grid; trans = trans or 0.85
    local host = Instance.new("Frame"); host.Size=UDim2.new(1,0,1,0)
    host.BackgroundTransparency=1; host.BorderSizePixel=0; host.ZIndex=0; host.ClipsDescendants=true; host.Parent=par
    for i=1,40 do
        local sl=Instance.new("Frame"); sl.Size=UDim2.new(1,0,0,1)
        sl.Position=UDim2.new(0,0,0,(i-1)*density); sl.BackgroundColor3=col
        sl.BackgroundTransparency=trans; sl.BorderSizePixel=0; sl.ZIndex=0; sl.Parent=host
    end
    return host
end

-- Vertical tick-mark grid
local function TickRow(par, count, col)
    col = col or T.GreenD
    local host = Instance.new("Frame"); host.Size=UDim2.new(1,0,1,0)
    host.BackgroundTransparency=1; host.BorderSizePixel=0; host.ZIndex=2; host.Parent=par
    for i=1,count do
        local t=Instance.new("Frame"); t.Size=UDim2.new(0,1,0.4,0)
        t.Position=UDim2.new((i-1)/(count-1),0,0.3,0); t.BackgroundColor3=col
        t.BackgroundTransparency=0.6; t.BorderSizePixel=0; t.ZIndex=2; t.Parent=host
    end
    return host
end

local function Draggable(handle, win)
    local drag,ds,sp=false,nil,nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; ds=i.Position; sp=win.Position end
    end)
    UIS.InputChanged:Connect(function(i)
        if (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) and drag then
            local d=i.Position-ds
            TS:Create(win,TweenInfo.new(0.05,Enum.EasingStyle.Linear),{
                Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)}):Play()
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- BUILD SECTION API
-- Brutalist-tech: every control has a completely different visual structure
-- ══════════════════════════════════════════════════════════════════════════════
local function BuildSectionAPI(page, ac, sc)
    ac = ac or T.Green
    sc = sc or T.Amber
    local _sN = 0
    local API = {}

    -- ── Base element shell ────────────────────────────────────────────────────
    -- Sharp-cornered panel with accent notch in top-left
    local function Elem(con, h, autoY)
        local f = Box({Sz=UDim2.new(1,0,0,h or 34), Bg=T.BG3, Z=3, Par=con})
        if autoY then f.AutomaticSize=Enum.AutomaticSize.Y end
        ScanFill(f, 5, T.Grid, 0.92)   -- subtle scan texture
        local bs = Border(f, T.Wire, 1, 0)
        -- Top-left notch accent
        local notch = Notch(f, "tl", 5, ac)
        notch.BackgroundTransparency = 0.6
        return f, bs, notch
    end

    local function HoverEff(f, bs, notch)
        f.MouseEnter:Connect(function()
            tw(f,{BackgroundColor3=T.BG4},TF)
            if bs then tw(bs,{Color=ac,Transparency=0.3},TF) end
            if notch then tw(notch,{BackgroundTransparency=0},TF) end
        end)
        f.MouseLeave:Connect(function()
            tw(f,{BackgroundColor3=T.BG3},TF)
            if bs then tw(bs,{Color=T.Wire,Transparency=0},TF) end
            if notch then tw(notch,{BackgroundTransparency=0.6},TF) end
        end)
    end

    -- ── CreateSection ─────────────────────────────────────────────────────────
    function API:CreateSection(sName)
        sName = sName or ""; _sN = _sN+1; local Sec = {}

        -- Section header: ruler-style with segment marks
        local hRow = Box({Sz=UDim2.new(1,0,0, sName~="" and 20 or 4), BgA=1, Z=3, Par=page})

        if sName ~= "" then
            -- Full-width 2-tone line
            local topL = Box({Sz=UDim2.new(1,0,0,1), Pos=UDim2.new(0,0,0,0), Bg=ac, BgA=0, Z=4, Par=hRow})
            local tlG  = Instance.new("UIGradient")
            tlG.Color=ColorSequence.new{
                ColorSequenceKeypoint.new(0,ac),
                ColorSequenceKeypoint.new(0.5,sc),
                ColorSequenceKeypoint.new(1,T.Wire)}
            tlG.Parent=topL; tw(topL,{BackgroundTransparency=0},TM)

            -- Ruler tick marks along the top
            TickRow(hRow, 24, ac)

            -- Section label: bold monospace tag, flush-left
            local tag = Box({Sz=UDim2.new(0,0,0,14), Pos=UDim2.new(0,8,0.5,0), AP=Vector2.new(0,0.5),
                Bg=T.BG0, BgA=0, Z=5, Par=hRow})
            tag.AutomaticSize=Enum.AutomaticSize.X; Pad(tag,0,0,3,3)
            local tagRow = Instance.new("Frame"); tagRow.Size=UDim2.new(0,0,1,0)
            tagRow.AutomaticSize=Enum.AutomaticSize.X; tagRow.BackgroundTransparency=1; tagRow.ZIndex=6; tagRow.Parent=tag
            List(tagRow,0,Enum.FillDirection.Horizontal,nil,Enum.VerticalAlignment.Center)
            Txt({T="["..string.format("%02d",_sN).."] ", Sz=UDim2.new(0,0,1,0), Font=Enum.Font.Code, TS=10,
                Col=ac, AutoX=true, Z=6, Par=tagRow})
            Txt({T=sName:upper(), Sz=UDim2.new(0,0,1,0), Font=Enum.Font.Code, TS=10,
                Col=T.TxtMid, AutoX=true, Z=6, Par=tagRow})
            Txt({T=" //", Sz=UDim2.new(0,0,1,0), Font=Enum.Font.Code, TS=10,
                Col=T.TxtLo, AutoX=true, Z=6, Par=tagRow})
        end

        local con = Box({Sz=UDim2.new(1,0,0,0), BgA=1, AutoY=true, Z=3, Par=page})
        List(con, 3)

        -- ── DIVIDER ───────────────────────────────────────────────────────────
        -- Two parallel lines with gap (double-rule)
        function Sec:CreateDivider()
            local d = Box({Sz=UDim2.new(1,0,0,5), Bg=T.BG1, BgA=0, Z=3, Par=con})
            local l1 = Box({Sz=UDim2.new(1,0,0,1), Pos=UDim2.new(0,0,0,0), Bg=ac, BgA=0, Z=4, Par=d})
            local l2 = Box({Sz=UDim2.new(1,0,0,1), Pos=UDim2.new(0,0,0,4), Bg=sc, BgA=0, Z=4, Par=d})
            local g1=Instance.new("UIGradient"); g1.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,0.7)}; g1.Parent=l1
            local g2=Instance.new("UIGradient"); g2.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.4),NumberSequenceKeypoint.new(0.6,0),NumberSequenceKeypoint.new(1,1)}; g2.Parent=l2
            tw(l1,{BackgroundTransparency=0},TM); tw(l2,{BackgroundTransparency=0},TM)
            return {Destroy=function() d:Destroy() end}
        end

        -- ── LABEL ─────────────────────────────────────────────────────────────
        -- Terminal-style prefix: "> " or "// " or "!! "
        function Sec:CreateLabel(lc)
            lc = merge({Name="",Text="",Style=1}, lc or {})
            local text = lc.Text~="" and lc.Text or lc.Name or ""
            local prefMap = {[1]="> ", [2]="// ", [3]="!! "}
            local colMap  = {[1]=T.TxtMid, [2]=ac, [3]=sc}
            local st = lc.Style or 1
            local f,bs,notch = Elem(con, 28)

            local row = Instance.new("Frame"); row.Size=UDim2.new(1,0,1,0)
            row.BackgroundTransparency=1; row.ZIndex=5; row.Parent=f
            List(row,0,Enum.FillDirection.Horizontal,nil,Enum.VerticalAlignment.Center)
            Pad(row,0,0,10,0)

            Txt({T=prefMap[st], Sz=UDim2.new(0,0,1,0), Font=Enum.Font.Code, TS=12,
                Col=colMap[st], AutoX=true, Z=5, Par=row})
            local lb=Txt({T=text, Sz=UDim2.new(1,0,1,0), Font=Enum.Font.Code, TS=12,
                Col=colMap[st], Z=5, Par=row})
            HoverEff(f,bs,notch)
            return {Set=function(_,t2) lb.Text=t2 end, Destroy=function() f:Destroy() end}
        end

        -- ── PARAGRAPH ─────────────────────────────────────────────────────────
        -- Looks like a terminal read-out block with header bar
        function Sec:CreateParagraph(pc)
            pc = merge({Title="Title",Content=""}, pc or {})
            local f,bs,notch = Elem(con, 0, true)
            -- Header strip: solid accent bar with title
            local hdr = Box({Sz=UDim2.new(1,0,0,20), Bg=ac, BgA=0, Z=5, Par=f})
            local hdrG = Instance.new("UIGradient")
            hdrG.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.75),NumberSequenceKeypoint.new(1,1)}
            hdrG.Parent=hdr
            local hLine = Box({Sz=UDim2.new(1,0,0,1), Pos=UDim2.new(0,0,0,0), Bg=ac, Z=6, Par=f})
            local pt = Txt({T="▌ "..pc.Title, Sz=UDim2.new(1,-10,1,0), Pos=UDim2.new(0,10,0,0),
                Font=Enum.Font.GothamBold, TS=12, Col=T.TxtHi, Z=6, Par=hdr})
            -- Content block
            local body = Box({Sz=UDim2.new(1,0,0,0), Pos=UDim2.new(0,0,0,20), BgA=1, AutoY=true, Z=5, Par=f})
            Pad(body,6,8,12,12)
            local pc2 = Txt({T=pc.Content, Sz=UDim2.new(1,0,0,0), Font=Enum.Font.Gotham, TS=12,
                Col=T.TxtMid, Wrap=true, AutoY=true, Z=5, Par=body})
            Border(f, ac, 1, 0.7)
            return {
                Set=function(_,s) if s.Title then pt.Text="▌ "..s.Title end; if s.Content then pc2.Text=s.Content end end,
                Destroy=function() f:Destroy() end,
            }
        end

        -- ── BUTTON ────────────────────────────────────────────────────────────
        -- Redesign: full-width "EXECUTE" style terminal command button
        -- Shows a > prompt, command name, and status indicator on right
        function Sec:CreateButton(bc)
            bc = merge({Name="Button",Description=nil,Callback=function()end}, bc or {})
            local h = bc.Description and 50 or 34
            local f,bs,notch = Elem(con, h)
            f.ClipsDescendants=true

            -- Left "gutter" column (like vim line numbers)
            local gutter = Box({Sz=UDim2.new(0,28,1,0), Pos=UDim2.new(0,0,0,0),
                Bg=T.BG2, Z=5, Par=f})
            local gutterLine = Box({Sz=UDim2.new(0,1,1,0), Pos=UDim2.new(1,-1,0,0),
                Bg=ac, BgA=0.7, Z=6, Par=gutter})
            -- Prompt symbol in gutter
            Txt({T=">", Sz=UDim2.new(1,0,1,0), Font=Enum.Font.Code, TS=13,
                Col=ac, AX=Enum.TextXAlignment.Center, Z=6, Par=gutter})

            -- Command text area
            local nameL = Txt({T=bc.Name, Sz=UDim2.new(1,-80,0,bc.Description and 16 or 20),
                Pos=UDim2.new(0,34,0, bc.Description and 6 or 7),
                Font=Enum.Font.Code, TS=13, Col=T.TxtHi, Z=5, Par=f})
            if bc.Description then
                Txt({T="-- "..bc.Description, Sz=UDim2.new(1,-80,0,12),
                    Pos=UDim2.new(0,34,0,24), Font=Enum.Font.Code, TS=11,
                    Col=T.TxtLo, Z=5, Par=f})
            end

            -- Right: status chip (shows READY → EXEC → DONE)
            local chip = Box({Sz=UDim2.new(0,44,0,16), Pos=UDim2.new(1,-52,0.5,0),
                AP=Vector2.new(0,0.5), Bg=T.GreenBg, Z=6, Par=f})
            Border(chip, ac, 1, 0.4)
            local chipL = Txt({T="READY", Sz=UDim2.new(1,0,1,0), Font=Enum.Font.Code, TS=9,
                Col=ac, AX=Enum.TextXAlignment.Center, Z=7, Par=chip})

            -- Execution flash overlay
            local flash = Box({Sz=UDim2.new(1,0,1,0), Bg=ac, BgA=1, Z=4, Par=f})

            local cl = Btn(f, 9)
            f.MouseEnter:Connect(function()
                tw(f,{BackgroundColor3=T.BG4},TF)
                tw(gutter,{BackgroundColor3=T.GreenBg},TF)
                tw(bs,{Color=ac,Transparency=0},TF)
                chipL.Text="RUN?"; tw(chip,{BackgroundColor3=ac},TF); tw(chipL,{TextColor3=T.BG0},TF)
                tw(notch,{BackgroundTransparency=0},TF)
            end)
            f.MouseLeave:Connect(function()
                tw(f,{BackgroundColor3=T.BG3},TF)
                tw(gutter,{BackgroundColor3=T.BG2},TF)
                tw(bs,{Color=T.Wire,Transparency=0},TF)
                chipL.Text="READY"; tw(chip,{BackgroundColor3=T.GreenBg},TF); tw(chipL,{TextColor3=ac},TF)
                tw(notch,{BackgroundTransparency=0.6},TF)
            end)
            cl.MouseButton1Click:Connect(function()
                chipL.Text="EXEC"
                tw(flash,{BackgroundTransparency=0.85},TI(.05,Enum.EasingStyle.Linear),function()
                    tw(flash,{BackgroundTransparency=1},TI(.12,Enum.EasingStyle.Linear))
                end)
                task.spawn(function()
                    task.wait(0.15); chipL.Text="DONE"
                    task.wait(0.6); chipL.Text="READY"
                end)
                safe(bc.Callback)
            end)
            return {Destroy=function() f:Destroy() end}
        end

        -- ── TOGGLE ────────────────────────────────────────────────────────────
        -- Redesign: segmented ON/OFF switch — two separate labeled blocks
        -- that highlight alternately (like a physical rocker switch)
        function Sec:CreateToggle(tc)
            tc = merge({Name="Toggle",Description=nil,CurrentValue=false,Flag=nil,Callback=function()end}, tc or {})
            local h = tc.Description and 50 or 34
            local f,bs,notch = Elem(con, h)

            -- Name label (left, monospace)
            Txt({T=tc.Name, Sz=UDim2.new(1,-96,0,tc.Description and 16 or 20),
                Pos=UDim2.new(0,10, 0, tc.Description and 6 or 7),
                Font=Enum.Font.Code, TS=13, Col=T.TxtHi, Z=5, Par=f})
            if tc.Description then
                Txt({T="-- "..tc.Description, Sz=UDim2.new(1,-96,0,12),
                    Pos=UDim2.new(0,10,0,24), Font=Enum.Font.Code, TS=10,
                    Col=T.TxtLo, Z=5, Par=f})
            end

            -- Rocker switch container
            local rockerW = 80
            local rocker = Box({Sz=UDim2.new(0,rockerW,0,20), Pos=UDim2.new(1,-rockerW-8,0.5,0),
                AP=Vector2.new(0,0.5), Bg=T.BG2, Z=5, Par=f})
            Border(rocker, T.WireHi, 1, 0)

            -- OFF segment (left half)
            local offSeg = Box({Sz=UDim2.new(0.5,0,1,0), Pos=UDim2.new(0,0,0,0), Bg=T.Err, Z=6, Par=rocker})
            local offL   = Txt({T="OFF", Sz=UDim2.new(1,0,1,0), Font=Enum.Font.Code, TS=10,
                Col=T.TxtHi, AX=Enum.TextXAlignment.Center, Z=7, Par=offSeg})

            -- ON segment (right half)
            local onSeg = Box({Sz=UDim2.new(0.5,0,1,0), Pos=UDim2.new(0.5,0,0,0), Bg=ac, Z=6, Par=rocker})
            local onL   = Txt({T="ON", Sz=UDim2.new(1,0,1,0), Font=Enum.Font.Code, TS=10,
                Col=T.TxtHi, AX=Enum.TextXAlignment.Center, Z=7, Par=onSeg})

            -- Separator notch between segments
            local sep = Box({Sz=UDim2.new(0,1,1,0), Pos=UDim2.new(0.5,0,0,0), Bg=T.BG0, Z=8, Par=rocker})

            -- State indicator dot above rocker
            local ind = Box({Sz=UDim2.new(0,5,0,5), Pos=UDim2.new(1,-rockerW-8+40-2,0.5,-14),
                Bg=ac, BgA=1, Z=6, Par=f})

            local TV = {CurrentValue=tc.CurrentValue, Type="Toggle", Settings=tc}

            local function upd()
                if TV.CurrentValue then
                    -- ON: right segment lit, left dim
                    tw(onSeg, {BackgroundColor3=ac, BackgroundTransparency=0}, TF)
                    tw(onL,   {TextColor3=T.BG0}, TF)
                    tw(offSeg,{BackgroundColor3=T.BG2, BackgroundTransparency=0}, TF)
                    tw(offL,  {TextColor3=T.TxtLo}, TF)
                    tw(ind,   {BackgroundColor3=ac, Size=UDim2.new(0,5,0,5)}, TK)
                    tw(bs,{Color=ac,Transparency=0.2},TF)
                    tw(notch,{BackgroundTransparency=0},TF)
                else
                    -- OFF: left segment lit (red), right dim
                    tw(offSeg,{BackgroundColor3=T.Err, BackgroundTransparency=0}, TF)
                    tw(offL,  {TextColor3=T.TxtHi}, TF)
                    tw(onSeg, {BackgroundColor3=T.BG2, BackgroundTransparency=0}, TF)
                    tw(onL,   {TextColor3=T.TxtLo}, TF)
                    tw(ind,   {BackgroundColor3=T.Err}, TK)
                    tw(bs,{Color=T.Err,Transparency=0.5},TF)
                    tw(notch,{BackgroundColor3=T.Err,BackgroundTransparency=0.6},TF)
                end
            end

            upd()
            Btn(f,7).MouseButton1Click:Connect(function()
                TV.CurrentValue=not TV.CurrentValue; upd(); safe(tc.Callback,TV.CurrentValue)
            end)
            function TV:Set(v) TV.CurrentValue=v; upd(); safe(tc.Callback,v) end
            if tc.Flag then Sentence.Flags[tc.Flag]=TV; Sentence.Options[tc.Flag]=TV end
            return TV
        end

        -- ── SLIDER ────────────────────────────────────────────────────────────
        -- Redesign: "level meter" — segmented bar (like VU/EQ meter)
        -- 16 segments light up progressively + numeric readout at top
        function Sec:CreateSlider(sc_)
            sc_ = merge({Name="Slider",Range={0,100},Increment=1,CurrentValue=50,Suffix="",Flag=nil,Callback=function()end}, sc_ or {})
            local f,bs,notch = Elem(con, 56)
            notch.BackgroundTransparency=0

            -- Name (top-left, monospace)
            Txt({T=sc_.Name, Sz=UDim2.new(1,-80,0,13),
                Pos=UDim2.new(0,10,0,5),
                Font=Enum.Font.Code, TS=12, Col=T.TxtHi, Z=5, Par=f})

            -- Value display (top-right, large mono)
            local vBox = Box({Sz=UDim2.new(0,68,0,18), Pos=UDim2.new(1,-76,0,4),
                Bg=T.BG2, Z=5, Par=f})
            Border(vBox, ac, 1, 0.5)
            local vL = Txt({T="", Sz=UDim2.new(1,-4,1,0), Pos=UDim2.new(0,4,0,0),
                Font=Enum.Font.Code, TS=13, Col=ac,
                AX=Enum.TextXAlignment.Right, Z=6, Par=vBox})

            -- Segment bar
            local SEGS = 18
            local barHost = Box({Sz=UDim2.new(1,-20,0,18), Pos=UDim2.new(0,10,0,30),
                Bg=T.BG2, Z=5, Par=f})
            Border(barHost, T.Wire, 1, 0)
            local segs = {}
            for i=1,SEGS do
                -- Color transitions: green → amber → red across segments
                local pct = (i-1)/(SEGS-1)
                local col = pct<0.65 and ac or pct<0.85 and sc_ or T.Err
                local s = Box({
                    Sz=UDim2.new(1/SEGS,-1,1,-2),
                    Pos=UDim2.new((i-1)/SEGS,1,0,1),
                    Bg=col, BgA=0.88, Z=6, Par=barHost
                })
                segs[i] = {f=s, col=col}
            end
            -- Invisible drag handle over the bar
            local dragHandle = Btn(barHost, 9)

            local SV = {CurrentValue=sc_.CurrentValue, Type="Slider", Settings=sc_}
            local mn,mx,inc = sc_.Range[1],sc_.Range[2],sc_.Increment
            local drag=false

            local function setV(v)
                v=math.clamp(v,mn,mx); v=math.floor(v/inc+0.5)*inc
                v=tonumber(string.format("%.10g",v)); SV.CurrentValue=v
                vL.Text=tostring(v)..sc_.Suffix
                local pct=(v-mn)/(mx-mn)
                local litCount = math.floor(pct*SEGS+0.5)
                for i,sg in ipairs(segs) do
                    if i<=litCount then
                        tw(sg.f,{BackgroundTransparency=0,BackgroundColor3=sg.col},TF)
                    else
                        tw(sg.f,{BackgroundTransparency=0.88},TF)
                    end
                end
            end
            setV(sc_.CurrentValue)

            local function fromPos(i)
                local rel=math.clamp((i.Position.X-barHost.AbsolutePosition.X)/barHost.AbsoluteSize.X,0,1)
                setV(mn+(mx-mn)*rel); safe(sc_.Callback,SV.CurrentValue)
            end
            dragHandle.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                    drag=true; fromPos(i)
                    tw(bs,{Color=ac,Transparency=0.1},TF)
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                    drag=false; tw(bs,{Color=T.Wire,Transparency=0},TF) end
            end)
            track(UIS.InputChanged:Connect(function(i)
                if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or
                    i.UserInputType==Enum.UserInputType.Touch) then fromPos(i) end
            end))
            HoverEff(f,bs,notch)
            function SV:Set(v) setV(v); safe(sc_.Callback,SV.CurrentValue) end
            if sc_.Flag then Sentence.Flags[sc_.Flag]=SV; Sentence.Options[sc_.Flag]=SV end
            return SV
        end

        -- ── COLOR PICKER ──────────────────────────────────────────────────────
        -- Redesign: hex color code display with RGB readout chips
        function Sec:CreateColorPicker(cc)
            cc = merge({Name="Color",Flag=nil,Color=Color3.new(1,1,1),Callback=function()end}, cc or {})
            local f,bs,notch = Elem(con, 34)

            Txt({T=cc.Name, Sz=UDim2.new(1,-120,0,20), Pos=UDim2.new(0,10,0.5,0), AP=Vector2.new(0,0.5),
                Font=Enum.Font.Code, TS=12, Col=T.TxtHi, Z=5, Par=f})

            -- Color block (large flat square)
            local block = Box({Sz=UDim2.new(0,24,0,24), Pos=UDim2.new(1,-30,0.5,0),
                AP=Vector2.new(0,0.5), Bg=cc.Color, Z=6, Par=f})
            Border(block, T.WireHi, 1, 0)

            -- Hex readout label
            local function colToHex(c)
                return string.format("#%02X%02X%02X",
                    math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
            end
            local hexL = Txt({T=colToHex(cc.Color), Sz=UDim2.new(0,62,0,20),
                Pos=UDim2.new(1,-98,0.5,0), AP=Vector2.new(0,0.5),
                Font=Enum.Font.Code, TS=11, Col=ac, Z=5, Par=f})

            HoverEff(f,bs,notch)
            local CV = {CurrentValue=cc.Color, Type="ColorPicker", Settings=cc}
            function CV:Set(c)
                CV.CurrentValue=c; block.BackgroundColor3=c; hexL.Text=colToHex(c)
                safe(cc.Callback,c)
            end
            if cc.Flag then Sentence.Flags[cc.Flag]=CV; Sentence.Options[cc.Flag]=CV end
            return CV
        end

        -- ── KEYBIND / BIND ────────────────────────────────────────────────────
        -- Redesign: looks like a keyboard shortcut entry in a settings JSON file
        -- Shows: "BIND_NAME": [KEY] with a bracket-style key display
        function Sec:CreateBind(bc)
            bc = merge({
                Name="Keybind", Description=nil, CurrentBind="E",
                HoldToInteract=false, Flag=nil,
                Callback=function()end, OnChangedCallback=function()end,
            }, bc or {})

            local h = bc.Description and 50 or 34
            local f,bs,notch = Elem(con, h)

            -- JSON-style label
            Txt({T='"'..bc.Name..'":', Sz=UDim2.new(1,-100,0,bc.Description and 16 or 20),
                Pos=UDim2.new(0,10,0,bc.Description and 6 or 7),
                Font=Enum.Font.Code, TS=12, Col=T.IceDim, Z=5, Par=f})
            if bc.Description then
                Txt({T="// "..bc.Description, Sz=UDim2.new(1,-100,0,12),
                    Pos=UDim2.new(0,10,0,24), Font=Enum.Font.Code, TS=10,
                    Col=T.TxtLo, Z=5, Par=f})
            end

            -- Key display: bracket style [ KEY ]
            local keyHost = Box({Sz=UDim2.new(0,0,0,22), Pos=UDim2.new(1,-10,0.5,0),
                AP=Vector2.new(1,0.5), Bg=T.BG2, Z=5, Par=f})
            keyHost.AutomaticSize=Enum.AutomaticSize.X; Pad(keyHost,0,0,8,8)
            local kBS = Border(keyHost, ac, 1, 0.5)

            -- Bracket decorators
            local lBrk = Txt({T="[", Sz=UDim2.new(0,10,1,0), Pos=UDim2.new(0,0,0,0),
                Font=Enum.Font.Code, TS=13, Col=ac, Z=6, Par=keyHost})
            local kTxt = Txt({T=bc.CurrentBind, Sz=UDim2.new(0,0,1,0), Pos=UDim2.new(0,10,0,0),
                Font=Enum.Font.Code, TS=13, Col=T.TxtHi, AutoX=true, Z=6, Par=keyHost})
            local rBrk = Txt({T="]", Sz=UDim2.new(0,0,1,0), Pos=UDim2.new(1,0,0,0), AP=Vector2.new(1,0),
                Font=Enum.Font.Code, TS=13, Col=ac, Z=6, Par=keyHost})

            -- HOLD flag
            if bc.HoldToInteract then
                local hTag = Box({Sz=UDim2.new(0,0,0,10), Pos=UDim2.new(1,-10,1,2),
                    AP=Vector2.new(1,0), Bg=T.AmberBg, Z=6, Par=f})
                hTag.AutomaticSize=Enum.AutomaticSize.X; Pad(hTag,0,0,3,3)
                Border(hTag, sc, 1, 0)
                Txt({T="HOLD", Sz=UDim2.new(0,0,1,0), Font=Enum.Font.Code, TS=8,
                    Col=sc, AutoX=true, Z=7, Par=hTag})
            end

            local BV={CurrentBind=bc.CurrentBind, Type="Bind", Settings=bc}
            local listening=false; local holdActive=false

            local function setListen(v)
                listening=v
                if v then
                    kTxt.Text="???"; tw(keyHost,{BackgroundColor3=T.AmberBg},TF)
                    tw(kBS,{Color=sc,Transparency=0},TF)
                    tw(lBrk,{TextColor3=sc},TF); tw(rBrk,{TextColor3=sc},TF)
                else
                    kTxt.Text=BV.CurrentBind; tw(keyHost,{BackgroundColor3=T.BG2},TF)
                    tw(kBS,{Color=ac,Transparency=0.5},TF)
                    tw(lBrk,{TextColor3=ac},TF); tw(rBrk,{TextColor3=ac},TF)
                end
            end

            local kBtn=Btn(keyHost,8)
            kBtn.MouseButton1Click:Connect(function()
                if listening then setListen(false); return end; setListen(true)
            end)

            track(UIS.InputBegan:Connect(function(inp,proc)
                if listening then
                    if inp.UserInputType==Enum.UserInputType.Keyboard then
                        local kn=inp.KeyCode.Name
                        if kn=="Escape" then setListen(false); return end
                        BV.CurrentBind=kn; setListen(false); safe(bc.OnChangedCallback,kn)
                    end; return
                end
                if proc then return end
                if inp.UserInputType==Enum.UserInputType.Keyboard
                    and inp.KeyCode.Name==BV.CurrentBind then
                    holdActive=true; safe(bc.Callback,true)
                end
            end))
            track(UIS.InputEnded:Connect(function(inp)
                if bc.HoldToInteract and inp.UserInputType==Enum.UserInputType.Keyboard
                    and inp.KeyCode.Name==BV.CurrentBind and holdActive then
                    holdActive=false; safe(bc.Callback,false) end
            end))

            HoverEff(f,bs,notch)
            function BV:Set(k) BV.CurrentBind=k; kTxt.Text=k; safe(bc.OnChangedCallback,k) end
            function BV:Destroy() f:Destroy() end
            if bc.Flag then Sentence.Flags[bc.Flag]=BV; Sentence.Options[bc.Flag]=BV end
            return BV
        end
        Sec.CreateKeybind = Sec.CreateBind

        -- ── INPUT ─────────────────────────────────────────────────────────────
        -- Redesign: command-line style entry with animated blinking cursor bar
        -- Shows: $ NAME  ___________________  [ENTER]
        function Sec:CreateInput(ic)
            ic = merge({
                Name="Input", Description=nil,
                PlaceholderText="…", CurrentValue="",
                Numeric=false, MaxCharacters=nil,
                Enter=false, RemoveTextAfterFocusLost=false,
                Flag=nil, Callback=function()end,
            }, ic or {})

            local h = ic.Description and 60 or 46
            local f,bs,notch = Elem(con, h)

            -- $ prompt label + name
            local promptRow = Instance.new("Frame"); promptRow.Size=UDim2.new(1,0,0,16)
            promptRow.Position=UDim2.new(0,0,0,6); promptRow.BackgroundTransparency=1; promptRow.ZIndex=5; promptRow.Parent=f
            List(promptRow,0,Enum.FillDirection.Horizontal,nil,Enum.VerticalAlignment.Center)
            Pad(promptRow,0,0,10,0)
            Txt({T="$ ", Sz=UDim2.new(0,14,1,0), Font=Enum.Font.Code, TS=12, Col=ac, Z=5, Par=promptRow})
            Txt({T=ic.Name..(ic.Numeric and " [num]" or ""), Sz=UDim2.new(1,0,1,0),
                Font=Enum.Font.Code, TS=12, Col=T.TxtMid, Z=5, Par=promptRow})

            -- Input field: styled as terminal line
            local fieldY = ic.Description and 38 or 24
            local fieldH = ic.Description and 16 or 16
            local fieldBg = Box({Sz=UDim2.new(1,-20,0,fieldH), Pos=UDim2.new(0,10,0,fieldY),
                Bg=T.BG0, Z=5, Par=f})
            local fieldBS = Border(fieldBg, T.Wire, 1, 0)

            -- Bottom underline accent (active when focused)
            local uline = Box({Sz=UDim2.new(0,0,0,1), Pos=UDim2.new(0,0,1,0),
                Bg=ac, BgA=1, Z=7, Par=fieldBg})

            -- Numeric marker
            if ic.Numeric then
                local nm = Box({Sz=UDim2.new(0,22,1,0), Pos=UDim2.new(1,0,0,0),
                    AP=Vector2.new(1,0), Bg=T.AmberBg, Z=6, Par=fieldBg})
                Border(nm, sc, 1, 0); Pad(nm,0,0,2,2)
                Txt({T="0-9", Sz=UDim2.new(1,0,1,0), Font=Enum.Font.Code, TS=8,
                    Col=sc, AX=Enum.TextXAlignment.Center, Z=7, Par=nm})
            end

            local tb = Instance.new("TextBox"); tb.Name="TB"
            tb.Size=UDim2.new(1, ic.Numeric and -24 or -2, 1,0)
            tb.BackgroundTransparency=1; tb.BorderSizePixel=0
            tb.PlaceholderText=ic.PlaceholderText; tb.PlaceholderColor3=T.TxtLo
            tb.Text=ic.CurrentValue; tb.Font=Enum.Font.Code; tb.TextSize=12
            tb.TextColor3=T.TxtHi; tb.ClearTextOnFocus=false; tb.ZIndex=7
            tb.TextXAlignment=Enum.TextXAlignment.Left; tb.Parent=fieldBg
            Pad(tb, 0, 0, 4, 0)

            -- Description
            if ic.Description then
                Txt({T="-- "..ic.Description, Sz=UDim2.new(1,-20,0,12), Pos=UDim2.new(0,10,0,24),
                    Font=Enum.Font.Code, TS=10, Col=T.TxtLo, Z=5, Par=f})
            end

            local IV={CurrentValue=ic.CurrentValue, Type="Input", Settings=ic}

            tb.Focused:Connect(function()
                tw(fieldBS,{Color=ac,Transparency=0},TF)
                tw(fieldBg,{BackgroundColor3=T.GreenBg},TF)
                tw(uline,{Size=UDim2.new(1,0,0,1),BackgroundTransparency=0},TI(.2,Enum.EasingStyle.Back))
                tw(bs,{Color=ac,Transparency=0.1},TF)
            end)
            tb.FocusLost:Connect(function(ep)
                tw(fieldBS,{Color=T.Wire,Transparency=0},TF)
                tw(fieldBg,{BackgroundColor3=T.BG0},TF)
                tw(uline,{Size=UDim2.new(0,0,0,1)},TM)
                tw(bs,{Color=T.Wire,Transparency=0},TF)
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

            HoverEff(f,bs,notch)
            function IV:Set(v)
                v=tostring(v)
                if ic.MaxCharacters and #v>ic.MaxCharacters then v=v:sub(1,ic.MaxCharacters) end
                tb.Text=v; IV.CurrentValue=v
            end
            function IV:Destroy() f:Destroy() end
            if ic.Flag then Sentence.Flags[ic.Flag]=IV; Sentence.Options[ic.Flag]=IV end
            return IV
        end

        -- ── DROPDOWN ──────────────────────────────────────────────────────────
        -- Redesign: tabbed selector — options laid out as horizontal tabs
        -- (up to 4 visible; scrollable list for more)
        function Sec:CreateDropdown(dc)
            dc = merge({
                Name="Dropdown", Description=nil,
                Options={"Option 1","Option 2"},
                CurrentOption=nil, MultipleOptions=false,
                SpecialType=nil, Flag=nil,
                Callback=function()end,
            }, dc or {})

            local function resolveOpts()
                if dc.SpecialType=="Player" then
                    local t={}; for _,p in ipairs(Plrs:GetPlayers()) do t[#t+1]=p.Name end; return t
                end
                return dc.Options
            end
            local opts=resolveOpts()
            local function defSel() return dc.MultipleOptions and {} or (opts[1] or "") end
            local cur = dc.CurrentOption~=nil and dc.CurrentOption or defSel()

            local baseH = dc.Description and 58 or 44
            local f,bs,notch = Elem(con, baseH, true)

            -- Name + type tag
            local nameRow = Instance.new("Frame"); nameRow.Size=UDim2.new(1,0,0,14)
            nameRow.Position=UDim2.new(0,0,0,6); nameRow.BackgroundTransparency=1; nameRow.ZIndex=5; nameRow.Parent=f
            List(nameRow,0,Enum.FillDirection.Horizontal,nil,Enum.VerticalAlignment.Center); Pad(nameRow,0,0,10,0)
            Txt({T="SELECT ", Sz=UDim2.new(0,0,1,0), Font=Enum.Font.Code, TS=9, Col=ac, AutoX=true, Z=5, Par=nameRow})
            Txt({T=dc.Name..(dc.MultipleOptions and " [multi]" or ""), Sz=UDim2.new(1,0,1,0),
                Font=Enum.Font.Code, TS=10, Col=T.TxtMid, Z=5, Par=nameRow})

            if dc.Description then
                Txt({T="// "..dc.Description, Sz=UDim2.new(1,-20,0,11), Pos=UDim2.new(0,10,0,21),
                    Font=Enum.Font.Code, TS=9, Col=T.TxtLo, Z=5, Par=f})
            end

            local tabY = dc.Description and 34 or 22
            local tabH = 18

            -- Tab bar (scrolling horizontal frame)
            local tabBar = Box({Sz=UDim2.new(1,-20,0,tabH), Pos=UDim2.new(0,10,0,tabY),
                Bg=T.BG2, Z=5, Par=f})
            Border(tabBar, T.Wire, 1, 0)

            -- Panel (drops down below tab bar when in list mode for multi/many options)
            local panel = Box({Sz=UDim2.new(1,-20,0,0), Pos=UDim2.new(0,10,0,tabY+tabH+2),
                Bg=T.BG2, Z=10, Clip=true, Par=f})
            panel.Visible=false; panel.AutomaticSize=Enum.AutomaticSize.None
            Border(panel, ac, 1, 0.4)
            local pScroll = Instance.new("ScrollingFrame"); pScroll.Size=UDim2.new(1,0,1,0)
            pScroll.BackgroundTransparency=1; pScroll.BorderSizePixel=0
            pScroll.ScrollBarThickness=2; pScroll.ScrollBarImageColor3=ac
            pScroll.CanvasSize=UDim2.new(0,0,0,0); pScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
            pScroll.ZIndex=11; pScroll.Parent=panel
            List(pScroll,1); Pad(pScroll,2,2,3,3)

            local DV={CurrentOption=cur,Type="Dropdown",Settings=dc,_open=false,_tabs={},_rows={}}

            local function dispStr()
                if dc.MultipleOptions then
                    return type(cur)=="table" and #cur>0 and table.concat(cur,", ") or "NONE"
                end; return tostring(cur)
            end
            local function isSel(opt)
                if dc.MultipleOptions then for _,v in ipairs(cur) do if v==opt then return true end end; return false
                end; return cur==opt
            end

            local rebuildTabs
            local function openPanel()
                DV._open=true; panel.Visible=true
                local mx=math.min(#DV._rows,4)
                tw(panel,{Size=UDim2.new(1,-20,0,mx*18+mx+4)},TK)
                tw(bs,{Color=ac,Transparency=0.1},TF)
            end
            local function closePanel()
                DV._open=false
                tw(panel,{Size=UDim2.new(1,-20,0,0)},TM,function() panel.Visible=false end)
                tw(bs,{Color=T.Wire,Transparency=0},TF)
            end

            rebuildTabs = function()
                -- Clear tab chips
                for _,t in ipairs(DV._tabs) do pcall(function() t:Destroy() end) end
                DV._tabs={}
                for _,r in ipairs(DV._rows) do pcall(function() r:Destroy() end) end
                DV._rows={}

                local allOpts=resolveOpts()
                local USE_TABS = #allOpts<=5 and not dc.MultipleOptions

                if USE_TABS then
                    -- Horizontal tab chips inside tabBar
                    local chipW = math.floor(tabBar.AbsoluteSize.X/#allOpts - 1)
                    for i,opt in ipairs(allOpts) do
                        local chip = Box({Sz=UDim2.new(0,chipW,1,0), Pos=UDim2.new(0,(i-1)*(chipW+1),0,0),
                            Bg=isSel(opt) and ac or T.BG3, Z=6, Par=tabBar})
                        local chipL = Txt({T=opt, Sz=UDim2.new(1,0,1,0), Font=Enum.Font.Code, TS=10,
                            Col=isSel(opt) and T.BG0 or T.TxtMid,
                            AX=Enum.TextXAlignment.Center, Z=7, Par=chip})
                        local chipBtn=Btn(chip,8)
                        chip.MouseEnter:Connect(function()
                            if not isSel(opt) then tw(chip,{BackgroundColor3=T.BG4},TF) end
                        end)
                        chip.MouseLeave:Connect(function()
                            if not isSel(opt) then tw(chip,{BackgroundColor3=T.BG3},TF) end
                        end)
                        chipBtn.MouseButton1Click:Connect(function()
                            cur=opt; DV.CurrentOption=opt; safe(dc.Callback,opt); rebuildTabs()
                        end)
                        DV._tabs[#DV._tabs+1]=chip
                    end
                else
                    -- Header bar shows current, click → dropdown list
                    -- Clear tabBar and show current value + arrow
                    for _,c in ipairs(tabBar:GetChildren()) do
                        if not c:IsA("UIStroke") and not c:IsA("UICorner") then pcall(function() c:Destroy() end) end
                    end
                    local dispL = Txt({T=dispStr(), Sz=UDim2.new(1,-18,1,0), Pos=UDim2.new(0,6,0,0),
                        Font=Enum.Font.Code, TS=10, Col=T.TxtHi, Z=6, Par=tabBar})
                    local arrL = Txt({T=DV._open and "▲" or "▼", Sz=UDim2.new(0,14,1,0),
                        Pos=UDim2.new(1,-14,0,0), Font=Enum.Font.Code, TS=9,
                        Col=ac, AX=Enum.TextXAlignment.Center, Z=6, Par=tabBar})
                    Btn(tabBar,9).MouseButton1Click:Connect(function()
                        if DV._open then closePanel() else openPanel() end
                        arrL.Text=DV._open and "▲" or "▼"
                    end)
                    DV._tabs[1]=dispL; DV._tabs[2]=arrL

                    -- Build list rows
                    for _,opt in ipairs(allOpts) do
                        local row = Box({Sz=UDim2.new(1,0,0,17), Bg=isSel(opt) and T.GreenBg or T.BG3,
                            Z=12, Par=pScroll})
                        local selBar = Box({Sz=UDim2.new(0,isSel(opt) and 3 or 0,1,0), Bg=ac, Z=13, Par=row})
                        Txt({T=(dc.MultipleOptions and (isSel(opt) and "[x] " or "[ ] ") or "")..opt,
                            Sz=UDim2.new(1,-8,1,0), Pos=UDim2.new(0,6,0,0),
                            Font=Enum.Font.Code, TS=10, Col=isSel(opt) and T.TxtHi or T.TxtMid, Z=13, Par=row})
                        Btn(row,14).MouseButton1Click:Connect(function()
                            if dc.MultipleOptions then
                                if type(cur)~="table" then cur={} end
                                local found=false
                                for i2,v in ipairs(cur) do if v==opt then table.remove(cur,i2); found=true; break end end
                                if not found then cur[#cur+1]=opt end
                                DV.CurrentOption=cur; safe(dc.Callback,cur); rebuildTabs()
                            else
                                cur=opt; DV.CurrentOption=opt; safe(dc.Callback,opt); closePanel(); rebuildTabs()
                            end
                        end)
                        DV._rows[#DV._rows+1]=row
                    end
                end
            end

            rebuildTabs()
            HoverEff(f,bs,notch)

            function DV:Set(opts2)
                cur=dc.MultipleOptions and (type(opts2)=="table" and opts2 or {opts2}) or opts2
                DV.CurrentOption=cur; rebuildTabs(); safe(dc.Callback,cur)
            end
            function DV:Refresh(newOpts)
                dc.Options=newOpts or dc.Options
                local was=DV._open; if was then closePanel() end
                cur=defSel(); DV.CurrentOption=cur; rebuildTabs()
                if was then task.wait(0.05); openPanel() end
            end
            function DV:Destroy() f:Destroy() end
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
-- NOTIFICATIONS  —  Terminal-style log entries
-- ══════════════════════════════════════════════════════════════════════════════
function Sentence:Notify(data)
    task.spawn(function()
        data = merge({Title="Notice",Content="",Icon="info",Type="Info",Duration=5}, data)
        local pal = NotifPal[data.Type] or NotifPal.Info

        local card = Box({Sz=UDim2.new(0,300,0,0), Pos=UDim2.new(-1.1,0,1,0),
            AP=Vector2.new(0,1), Bg=T.BG1, BgA=1, Clip=true, Par=self._notifHolder})
        ScanFill(card, 6, T.Grid, 0.90)

        local cardBS = Border(card, pal.border, 1, 1)
        Notch(card,"tl",7,pal.fg)
        Notch(card,"br",5,pal.fg)

        -- Left bar (type indicator)
        local lBar = Box({Sz=UDim2.new(0,3,1,0), Bg=pal.fg, BgA=1, Z=8, Par=card})

        -- Glow strip
        local glow = Box({Sz=UDim2.new(0,60,1,0), Pos=UDim2.new(0,3,0,0), Bg=pal.fg, BgA=1, Z=2, Par=card})
        local glG=Instance.new("UIGradient"); glG.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.88),NumberSequenceKeypoint.new(1,1)}; glG.Parent=glow

        -- Type stamp (top-left)
        local stamp = Box({Sz=UDim2.new(0,0,0,13), Pos=UDim2.new(0,12,0,8), BgA=0, AutoX=true, Z=7, Par=card})
        Pad(stamp,0,0,4,4)
        local stL = Txt({T="["..data.Type:upper().."]", Sz=UDim2.new(0,0,1,0), Font=Enum.Font.Code, TS=9,
            Col=pal.fg, AutoX=true, Alpha=1, Z=8, Par=stamp})

        -- Title
        local ttl = Txt({T=data.Title, Sz=UDim2.new(1,-20,0,14), Pos=UDim2.new(0,12,0,22),
            Font=Enum.Font.Code, TS=12, Col=T.TxtHi, Alpha=1, Z=7, Par=card})

        -- Content
        local msg = Txt({T=data.Content, Sz=UDim2.new(1,-20,0,0), Pos=UDim2.new(0,12,0,38),
            Font=Enum.Font.Code, TS=10, Col=T.TxtMid, Alpha=1, Wrap=true, AutoY=true, Z=7, Par=card})

        -- Progress line (bottom)
        local pTrk = Box({Sz=UDim2.new(1,-3,0,1), Pos=UDim2.new(0,3,1,-1), Bg=T.BG3, BgA=1, Z=6, Par=card})
        local pFil = Box({Sz=UDim2.new(1,0,1,0), Bg=pal.fg, BgA=1, Z=7, Par=pTrk})

        -- Close (X) corner button
        local xBtn = Box({Sz=UDim2.new(0,16,0,14), Pos=UDim2.new(1,0,0,0), AP=Vector2.new(1,0),
            Bg=T.BG3, BgA=1, Z=9, Par=card})
        local xL = Txt({T="×", Sz=UDim2.new(1,0,1,0), Font=Enum.Font.Code, TS=12,
            Col=T.TxtLo, AX=Enum.TextXAlignment.Center, Alpha=1, Z=10, Par=xBtn})
        local xCL=Btn(xBtn,11)
        xBtn.MouseEnter:Connect(function() tw(xBtn,{BackgroundColor3=T.Err},TF); tw(xL,{TextColor3=T.TxtHi},TF) end)
        xBtn.MouseLeave:Connect(function() tw(xBtn,{BackgroundColor3=T.BG3},TF); tw(xL,{TextColor3=T.TxtLo},TF) end)

        task.wait()
        local cardH = 42 + (data.Content~="" and msg.AbsoluteSize.Y or 0) + 6
        card.Size=UDim2.new(0,300,0,cardH); card.Position=UDim2.new(-1.1,0,1,0)
        for _,el in ipairs({lBar,glow,pTrk,pFil,xBtn}) do el.BackgroundTransparency=1 end
        stL.TextTransparency=1; ttl.TextTransparency=1; msg.TextTransparency=1; xL.TextTransparency=1

        local TIC=TweenInfo.new(0.28,Enum.EasingStyle.Quad)
        tw(card,{Position=UDim2.new(0,0,1,0)},TIC); task.wait(0.06)
        for _,el in ipairs({lBar,glow,pTrk,pFil,xBtn}) do tw(el,{BackgroundTransparency=0},TIC) end
        tw(cardBS,{Transparency=0.3},TIC)
        tw(stL,{TextTransparency=0},TIC); tw(ttl,{TextTransparency=0},TIC)
        tw(msg,{TextTransparency=0},TIC); tw(xL,{TextTransparency=0},TIC)
        tw(pFil,{Size=UDim2.new(0,0,1,0)},TI(data.Duration,Enum.EasingStyle.Linear))

        local paused,dismissed,elapsed=false,false,0
        card.MouseEnter:Connect(function() paused=true; tw(card,{BackgroundColor3=T.BG2},TF) end)
        card.MouseLeave:Connect(function() paused=false; tw(card,{BackgroundColor3=T.BG1},TF) end)
        xCL.MouseButton1Click:Connect(function() dismissed=true end)
        repeat task.wait(0.05); if not paused then elapsed=elapsed+0.05 end
        until dismissed or elapsed>=data.Duration

        local TOUT=TweenInfo.new(0.18,Enum.EasingStyle.Quad)
        for _,el in ipairs({lBar,glow,pTrk,pFil,xBtn}) do tw(el,{BackgroundTransparency=1},TOUT) end
        tw(cardBS,{Transparency=1},TOUT); tw(stL,{TextTransparency=1},TOUT)
        tw(ttl,{TextTransparency=1},TOUT); tw(msg,{TextTransparency=1},TOUT); tw(xL,{TextTransparency=1},TOUT)
        tw(card,{Position=UDim2.new(-1.1,0,1,0)},TweenInfo.new(0.22,Enum.EasingStyle.Quad,Enum.EasingDirection.In))
        task.wait(0.24)
        tw(card,{Size=UDim2.new(0,300,0,0)},TM,function() card:Destroy() end)
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- CREATE WINDOW
-- ══════════════════════════════════════════════════════════════════════════════
function Sentence:CreateWindow(cfg)
    cfg = merge({
        Name="SENTENCE", Subtitle="", Icon="",
        ToggleBind=Enum.KeyCode.RightControl,
        LoadingEnabled=true,
        LoadingTitle="SENTENCE", LoadingSubtitle="BOOTING",
        ConfigurationSaving={Enabled=false},
    }, cfg)

    local vp = Cam.ViewportSize
    local WW = math.clamp(vp.X-80, 580, 800)
    local WH = math.clamp(vp.Y-60, 410, 530)
    local FULL = UDim2.fromOffset(WW,WH)
    local TB_H = 38
    local SB_W = 46
    local MINI = UDim2.fromOffset(WW, TB_H+1)

    -- ── ScreenGui ─────────────────────────────────────────────────────────────
    local gui=Instance.new("ScreenGui"); gui.Name="SentenceNeonGrid"
    gui.DisplayOrder=999999999; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true
    if gethui then gui.Parent=gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(gui); gui.Parent=CG
    elseif not IsStudio then gui.Parent=CG
    else gui.Parent=LP:WaitForChild("PlayerGui") end

    -- ══════════════════════════════════════════════════════════════════════════
    -- BOOT / SPLASH SCREEN  —  Terminal boot sequence
    -- ══════════════════════════════════════════════════════════════════════════
    task.spawn(function()
        local alive=true; local spConns={}

        local splash=Instance.new("Frame"); splash.Name="Boot"
        splash.Size=UDim2.new(1,0,1,0); splash.BackgroundColor3=T.BG0
        splash.BackgroundTransparency=1; splash.BorderSizePixel=0; splash.ZIndex=1000
        splash.ClipsDescendants=true; splash.Parent=gui

        -- Grid overlay
        for i=1,40 do
            local sl=Instance.new("Frame"); sl.Size=UDim2.new(1,0,0,1)
            sl.Position=UDim2.new(0,0,0,(i-1)*14); sl.BackgroundColor3=T.Grid
            sl.BackgroundTransparency=0.85; sl.BorderSizePixel=0; sl.ZIndex=1001; sl.Parent=splash
        end
        for i=1,60 do
            local cl=Instance.new("Frame"); cl.Size=UDim2.new(0,1,1,0)
            cl.Position=UDim2.new(0,(i-1)*22,0,0); cl.BackgroundColor3=T.Grid
            cl.BackgroundTransparency=0.92; cl.BorderSizePixel=0; cl.ZIndex=1001; cl.Parent=splash
        end

        -- Vignette (dark edges)
        local vig=Box({Sz=UDim2.new(1,0,1,0), Bg=T.BG0, BgA=0, Z=1002, Par=splash})
        local vigG=Instance.new("UIGradient")
        vigG.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.4,1),NumberSequenceKeypoint.new(0.6,1),NumberSequenceKeypoint.new(1,0)}
        vigG.Rotation=90; vigG.Parent=vig

        -- Center logo box (terminal window frame)
        local logoBox = Box({Sz=UDim2.new(0,360,0,200),
            Pos=UDim2.new(0.5,0,0.5,-20), AP=Vector2.new(0.5,0.5),
            Bg=T.BG1, BgA=1, Z=1004, Par=splash})
        Border(logoBox, T.Green, 1, 1)
        Notch(logoBox,"tl",10,T.Green)
        Notch(logoBox,"tr",10,T.Amber)
        Notch(logoBox,"bl",10,T.Amber)
        Notch(logoBox,"br",10,T.Green)

        -- Title bar of terminal window
        local titleBar2 = Box({Sz=UDim2.new(1,0,0,18), Bg=T.Green, BgA=1, Z=1005, Par=logoBox})
        local titleBarG=Instance.new("UIGradient"); titleBarG.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.7),NumberSequenceKeypoint.new(1,1)}; titleBarG.Parent=titleBar2
        Txt({T="SENTENCE GUI :: BOOT SEQUENCE", Sz=UDim2.new(1,-60,1,0), Pos=UDim2.new(0,8,0,0),
            Font=Enum.Font.Code, TS=10, Col=T.BG0, Z=1006, Par=titleBar2})
        Txt({T="[×][−][ ]", Sz=UDim2.new(0,50,1,0), Pos=UDim2.new(1,0,0,0), AP=Vector2.new(1,0),
            Font=Enum.Font.Code, TS=9, Col=T.BG0, AX=Enum.TextXAlignment.Right, Z=1006, Par=titleBar2})

        -- Boot log area (scrolling text)
        local logArea = Box({Sz=UDim2.new(1,-16,1,-46), Pos=UDim2.new(0,8,0,22),
            Bg=T.BG0, Z=1005, Par=logoBox})
        Border(logArea, T.Wire, 1, 0)
        local logList = Instance.new("ScrollingFrame"); logList.Size=UDim2.new(1,0,1,0)
        logList.BackgroundTransparency=1; logList.BorderSizePixel=0
        logList.ScrollBarThickness=0; logList.CanvasSize=UDim2.new(0,0,0,0)
        logList.AutomaticCanvasSize=Enum.AutomaticSize.Y; logList.ZIndex=1006; logList.Parent=logArea
        List(logList,0); Pad(logList,4,4,6,6)

        -- Progress bar at bottom
        local pTrack = Box({Sz=UDim2.new(1,-16,0,3), Pos=UDim2.new(0,8,1,-8), AP=Vector2.new(0,1),
            Bg=T.BG3, Z=1005, Par=logoBox})
        local pFill = Box({Sz=UDim2.new(0,0,1,0), Bg=T.Green, Z=1006, Par=pTrack})
        local pFG=Instance.new("UIGradient"); pFG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.Green),ColorSequenceKeypoint.new(0.7,T.Amber),ColorSequenceKeypoint.new(1,T.Green)}; pFG.Parent=pFill

        local function addLog(txt, col)
            local l=Instance.new("TextLabel"); l.Text=txt; l.Size=UDim2.new(1,0,0,0)
            l.AutomaticSize=Enum.AutomaticSize.Y; l.Font=Enum.Font.Code; l.TextSize=10
            l.TextColor3=col or T.TxtMid; l.TextXAlignment=Enum.TextXAlignment.Left
            l.TextWrapped=true; l.RichText=false; l.BackgroundTransparency=1
            l.BorderSizePixel=0; l.ZIndex=1007; l.Parent=logList
            logList.CanvasPosition=Vector2.new(0,99999)
        end

        -- Cursor blink
        local cursorLbl=Instance.new("TextLabel"); cursorLbl.Text="█"
        cursorLbl.Size=UDim2.new(0,8,0,10); cursorLbl.Font=Enum.Font.Code; cursorLbl.TextSize=10
        cursorLbl.TextColor3=T.Green; cursorLbl.BackgroundTransparency=1; cursorLbl.BorderSizePixel=0
        cursorLbl.ZIndex=1008; cursorLbl.Parent=logArea

        -- Animated cursor blinking
        local blinkConn = RS.RenderStepped:Connect(function()
            cursorLbl.Visible = (math.floor(tick()*2)%2==0)
            -- Pulse glow border
            local p=0.2+math.abs(math.sin(tick()*1.4))*0.5
            local bs2=logoBox:FindFirstChildOfClass("UIStroke")
            if bs2 then bs2.Transparency=p end
        end)
        table.insert(spConns, blinkConn)

        -- Reveal
        tw(splash,{BackgroundTransparency=0},TI(.3,Enum.EasingStyle.Quad)); task.wait(0.15)
        local lbBS=logoBox:FindFirstChildOfClass("UIStroke")
        if lbBS then tw(lbBS,{Transparency=0},TM) end; task.wait(0.1)

        local bootLog = {
            {t="SENTENCE GUI v4.0 — NEON GRID EDITION", c=T.Green},
            {t="(c) 2025 Sentence Framework. All rights reserved.", c=T.TxtLo},
            {t="", c=T.TxtLo},
            {t=">> Initialising core subsystems...", c=T.TxtMid},
            {t="   [OK] Memory allocator", c=T.Green},
            {t="   [OK] Render pipeline", c=T.Green},
            {t="   [OK] Input handler", c=T.Green},
            {t=">> Loading UI components...", c=T.TxtMid},
            {t="   [OK] Theme engine", c=T.Green},
            {t="   [OK] Section builder", c=T.Green},
            {t="   [OK] Control factory", c=T.Green},
            {t=">> Connecting services...", c=T.TxtMid},
            {t="   [OK] Player context", c=T.Green},
            {t="   [OK] Network monitor", c=T.Green},
            {t=">> "..cfg.LoadingTitle.." ready.", c=T.Amber},
            {t="", c=T.TxtLo},
            {t="BOOT COMPLETE — LAUNCHING INTERFACE", c=T.Green},
        }
        for i,entry in ipairs(bootLog) do
            addLog(entry.t, entry.c)
            tw(pFill,{Size=UDim2.new(i/#bootLog,0,1,0)},TI(.2,Enum.EasingStyle.Linear))
            task.wait(i<4 and 0.04 or 0.06)
        end
        task.wait(0.4)

        -- Outro: flash + collapse
        alive=false
        for _,c in ipairs(spConns) do pcall(function() c:Disconnect() end) end
        tw(logoBox,{BackgroundColor3=T.Green,BackgroundTransparency=0.7},TI(.08,Enum.EasingStyle.Linear),function()
            tw(logoBox,{BackgroundColor3=T.BG1,BackgroundTransparency=1},TI(.24,Enum.EasingStyle.Quad))
        end)
        if lbBS then tw(lbBS,{Transparency=1},TI(.24)) end
        task.wait(0.18)
        tw(splash,{BackgroundTransparency=1},TI(.3,Enum.EasingStyle.Quad),function() splash:Destroy() end)
    end)

    -- ── Notif holder ──────────────────────────────────────────────────────────
    local notifHolder=Instance.new("Frame"); notifHolder.Name="Notifs"
    notifHolder.Size=UDim2.new(0,310,1,-12); notifHolder.Position=UDim2.new(0,8,1,-6)
    notifHolder.AnchorPoint=Vector2.new(0,1); notifHolder.BackgroundTransparency=1
    notifHolder.ZIndex=200; notifHolder.Parent=gui
    local nL=List(notifHolder,4); nL.VerticalAlignment=Enum.VerticalAlignment.Bottom
    self._notifHolder=notifHolder

    -- ══════════════════════════════════════════════════════════════════════════
    -- MAIN WINDOW  —  Hard-edged terminal panel
    -- ══════════════════════════════════════════════════════════════════════════
    local win=Box({Name="SGWin", Sz=UDim2.fromOffset(0,0), Pos=UDim2.new(0.5,0,0.5,0),
        AP=Vector2.new(0.5,0.5), Bg=T.BG1, BgA=0, Clip=true, Z=1, Par=gui})
    local winBS = Border(win, T.Wire, 1, 1)

    -- Corner notches on main window
    Notch(win,"tl",8,T.Green)
    Notch(win,"tr",8,T.Amber)
    Notch(win,"br",5,T.IceDim)

    -- Top accent bar
    local topBar = Box({Sz=UDim2.new(1,0,0,2), Pos=UDim2.new(0,0,0,0), Bg=T.Green, BgA=1, Z=9, Par=win})
    local topBarG=Instance.new("UIGradient"); topBarG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.Green),ColorSequenceKeypoint.new(0.5,T.Amber),ColorSequenceKeypoint.new(1,T.Ice)}; topBarG.Parent=topBar

    -- Ambient corner glow
    local cornerGlow=Box({Sz=UDim2.new(0,180,0,80), Bg=T.Green, BgA=0.95, Z=0, Par=win})
    local cgG=Instance.new("UIGradient"); cgG.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.92),NumberSequenceKeypoint.new(1,1)}; cgG.Rotation=135; cgG.Parent=cornerGlow

    -- ── Title bar ─────────────────────────────────────────────────────────────
    local titleBar=Box({Name="TB", Sz=UDim2.new(1,0,0,TB_H), Pos=UDim2.new(0,0,0,2),
        Bg=T.BG0, Z=4, Par=win})
    Draggable(titleBar, win)
    Border(titleBar, T.Wire, 1, 0)
    ScanFill(titleBar, 4, T.Grid, 0.88)

    -- Title bar bottom separator
    local tbSep=Box({Sz=UDim2.new(1,0,0,1), Pos=UDim2.new(0,0,1,0), Bg=T.Green, BgA=0, Z=5, Par=titleBar})
    local tbSepG=Instance.new("UIGradient"); tbSepG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.Green),ColorSequenceKeypoint.new(0.5,T.Amber),ColorSequenceKeypoint.new(1,T.Wire)}; tbSepG.Parent=tbSep

    -- Window controls (left side, macOS style but square)
    local CTRL_SIZE=14; local CTRL_GAP=5; local CTRL_PAD=10
    local ctrlDefs={
        {key="X", bg=T.Err, hBg=T.Err, label="×"},
        {key="M", bg=T.Wire, hBg=T.Amber, label="−"},
        {key="H", bg=T.Wire, hBg=T.IceDim, label="▪"},
    }
    local ctrlBtns={}
    for i,cd in ipairs(ctrlDefs) do
        local x=CTRL_PAD+(i-1)*(CTRL_SIZE+CTRL_GAP)
        local cb=Box({Sz=UDim2.new(0,CTRL_SIZE,0,CTRL_SIZE), Pos=UDim2.new(0,x,0.5,0),
            AP=Vector2.new(0,0.5), Bg=cd.bg, BgA=0, Z=5, Par=titleBar})
        Border(cb, cd.bg, 1, 0.3)
        local cbL=Txt({T=cd.label, Sz=UDim2.new(1,0,1,0), Font=Enum.Font.Code, TS=10,
            Col=T.TxtLo, AX=Enum.TextXAlignment.Center, Alpha=1, Z=6, Par=cb})
        local cl=Btn(cb,7)
        cb.MouseEnter:Connect(function() tw(cb,{BackgroundColor3=cd.hBg,BackgroundTransparency=0},TF); tw(cbL,{TextColor3=T.BG0},TF) end)
        cb.MouseLeave:Connect(function() tw(cb,{BackgroundColor3=cd.bg,BackgroundTransparency=0},TF); tw(cbL,{TextColor3=T.TxtLo},TF) end)
        ctrlBtns[cd.key]={f=cb,cl=cl,l=cbL}
    end

    -- Logo
    local logX=CTRL_PAD+3*(CTRL_SIZE+CTRL_GAP)+8
    local logoImg=Instance.new("ImageLabel"); logoImg.Size=UDim2.new(0,24,0,24)
    logoImg.Position=UDim2.new(0,logX,0.5,0); logoImg.AnchorPoint=Vector2.new(0,0.5)
    logoImg.BackgroundTransparency=1; logoImg.Image=cfg.Icon~="" and ico(cfg.Icon) or LOGO
    logoImg.ScaleType=Enum.ScaleType.Fit; logoImg.ImageTransparency=1; logoImg.ZIndex=5; logoImg.Parent=titleBar
    task.spawn(function() tw(logoImg,{ImageTransparency=0},TM) end)

    -- Name + subtitle
    local nX=logX+28
    local nameL=Txt({T=cfg.Name, Sz=UDim2.new(0,200,0,16), Pos=UDim2.new(0,nX,0,3),
        Font=Enum.Font.Code, TS=14, Col=T.Green, Alpha=1, Z=5, Par=titleBar})
    local subStr=cfg.Subtitle~="" and cfg.Subtitle or ("v"..Sentence.Version.." // NEON GRID")
    local subL=Txt({T=subStr, Sz=UDim2.new(0,200,0,11), Pos=UDim2.new(0,nX,0,21),
        Font=Enum.Font.Code, TS=10, Col=T.TxtLo, Alpha=1, Z=5, Par=titleBar})

    -- System time display (right side of titlebar)
    local clockL=Txt({T="00:00:00", Sz=UDim2.new(0,60,0,14), Pos=UDim2.new(1,-68,0.5,0),
        AP=Vector2.new(0,0.5), Font=Enum.Font.Code, TS=10, Col=T.Amber, Alpha=0,
        AX=Enum.TextXAlignment.Right, Z=5, Par=titleBar})
    task.spawn(function()
        tw(clockL,{TextTransparency=0},TM)
        while clockL and clockL.Parent do
            local h2=os.date("%H"); local m2=os.date("%M"); local s2=os.date("%S")
            if clockL and clockL.Parent then clockL.Text=h2..":"..m2..":"..s2 end
            task.wait(1)
        end
    end)

    -- ── Sidebar ───────────────────────────────────────────────────────────────
    local sidebar=Box({Name="SB", Sz=UDim2.new(0,SB_W,1,-TB_H-2), Pos=UDim2.new(0,0,0,TB_H+2),
        Bg=T.BG0, Z=3, Par=win})
    ScanFill(sidebar, 4, T.Grid, 0.88)

    -- Right border of sidebar: double-line
    local sbR1=Box({Sz=UDim2.new(0,1,1,0), Pos=UDim2.new(1,-2,0,0), Bg=T.Wire, Z=5, Par=sidebar})
    local sbR2=Box({Sz=UDim2.new(0,1,1,0), Pos=UDim2.new(1,-1,0,0), Bg=T.GreenBg, Z=5, Par=sidebar})
    local sbRG=Instance.new("UIGradient"); sbRG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.Green),ColorSequenceKeypoint.new(0.5,T.Amber),ColorSequenceKeypoint.new(1,T.Wire)}; sbRG.Rotation=90; sbRG.Parent=sbR1

    local tabList=Instance.new("ScrollingFrame"); tabList.Name="TL"
    tabList.Size=UDim2.new(1,0,1,-44); tabList.Position=UDim2.new(0,0,0,8)
    tabList.BackgroundTransparency=1; tabList.BorderSizePixel=0
    tabList.ScrollBarThickness=0; tabList.AutomaticCanvasSize=Enum.AutomaticSize.Y
    tabList.ZIndex=4; tabList.Parent=sidebar
    List(tabList,2,Enum.FillDirection.Vertical,Enum.HorizontalAlignment.Center); Pad(tabList,4,4,0,0)

    -- Avatar at bottom
    local avBox=Box({Sz=UDim2.new(0,28,0,28), Pos=UDim2.new(0.5,0,1,-8), AP=Vector2.new(0.5,1),
        Bg=T.BG2, Z=4, Par=sidebar})
    Border(avBox, T.Green, 1, 0.5)
    local avImg=Instance.new("ImageLabel"); avImg.Size=UDim2.new(1,0,1,0)
    avImg.BackgroundTransparency=1; avImg.ZIndex=5; avImg.Parent=avBox
    pcall(function() avImg.Image=Plrs:GetUserThumbnailAsync(LP.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size48x48) end)

    -- Tooltip
    local tooltip=Box({Name="TT", Sz=UDim2.new(0,0,0,18), Pos=UDim2.new(0,SB_W+3,0,0),
        Bg=T.BG0, Z=20, Vis=false, Par=win})
    tooltip.AutomaticSize=Enum.AutomaticSize.X; Pad(tooltip,0,0,6,6)
    Border(tooltip, T.Green, 1, 0)
    local ttL=Txt({T="", Sz=UDim2.new(0,0,1,0), Font=Enum.Font.Code, TS=11, Col=T.Green,
        AutoX=true, Z=21, Par=tooltip})

    -- Content area
    local contentArea=Box({Name="CA", Sz=UDim2.new(1,-SB_W-1,1,-TB_H-2), Pos=UDim2.new(0,SB_W+1,0,TB_H+2),
        Bg=T.BG1, BgA=1, Clip=true, Z=2, Par=win})
    ScanFill(contentArea, 6, T.Grid, 0.96)

    local W={_gui=gui,_win=win,_content=contentArea,_tabs={},_activeTab=nil,_visible=true,_minimized=false,_cfg=cfg}

    local function SwitchTab(id)
        for _,tab in ipairs(W._tabs) do
            local active = tab.id==id
            tab.page.Visible=active
            local ac2=active and T.Green or T.Wire
            tw(tab.box,{BackgroundColor3=active and T.GreenBg or T.BG0, BackgroundTransparency=active and 0 or 1},TF)
            tw(tab.ico,{ImageColor3=active and T.Green or T.TxtLo},TF)
            local tbs=tab.box:FindFirstChildOfClass("UIStroke")
            if tbs then tw(tbs,{Color=active and T.Green or T.Wire, Transparency=active and 0 or 0.6},TF) end
            if active then W._activeTab=id end
        end
    end

    -- ── Loading screen ────────────────────────────────────────────────────────
    if cfg.LoadingEnabled then
        local lf=Box({Sz=UDim2.new(1,0,1,0),Bg=T.BG1,BgA=0,Z=50,Par=win})
        ScanFill(lf,5,T.Grid,0.9)
        Notch(lf,"tl",10,T.Green); Notch(lf,"br",10,T.Amber)
        local lT=Txt({T=cfg.LoadingTitle, Sz=UDim2.new(1,0,0,22),
            Pos=UDim2.new(0.5,0,0.5,-16), AP=Vector2.new(0.5,0.5),
            Font=Enum.Font.Code, TS=20, Col=T.Green, AX=Enum.TextXAlignment.Center, Alpha=1, Z=51, Par=lf})
        local lS=Txt({T=cfg.LoadingSubtitle, Sz=UDim2.new(1,0,0,12),
            Pos=UDim2.new(0.5,0,0.5,10), AP=Vector2.new(0.5,0.5),
            Font=Enum.Font.Code, TS=10, Col=T.TxtMid, AX=Enum.TextXAlignment.Center, Alpha=1, Z=51, Par=lf})
        local pT=Box({Sz=UDim2.new(0.4,0,0,2), Pos=UDim2.new(0.5,0,0.5,32), AP=Vector2.new(0.5,0.5),
            Bg=T.BG3, Z=51, Par=lf})
        local pF=Box({Sz=UDim2.new(0,0,1,0), Bg=T.Green, Z=52, Par=pT})
        local pFG2=Instance.new("UIGradient"); pFG2.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.Green),ColorSequenceKeypoint.new(1,T.Amber)}; pFG2.Parent=pF
        local pctL=Txt({T="0%", Sz=UDim2.new(1,0,0,12), Pos=UDim2.new(0.5,0,0.5,42),
            AP=Vector2.new(0.5,0.5), Font=Enum.Font.Code, TS=10, Col=T.Amber,
            AX=Enum.TextXAlignment.Center, Z=51, Par=lf})
        tw(win,{Size=FULL},TS_); task.wait(0.25)
        local pct=0
        for _,s in ipairs({0.12,0.08,0.16,0.10,0.18,0.12,0.10,0.14}) do
            pct=math.min(pct+s,1); tw(pF,{Size=UDim2.new(pct,0,1,0)},TI(.22,Enum.EasingStyle.Quad))
            pctL.Text=math.floor(pct*100).."% "; task.wait(0.12+math.random()*0.08)
        end
        pctL.Text="100% "; tw(pF,{Size=UDim2.new(1,0,1,0)},TF); task.wait(0.26)
        tw(pF,{BackgroundColor3=T.TxtHi},TF); task.wait(0.06)
        tw(lT,{TextTransparency=1},TF); tw(lS,{TextTransparency=1},TF)
        tw(pctL,{TextTransparency=1},TF); tw(pT,{BackgroundTransparency=1},TF); tw(pF,{BackgroundTransparency=1},TF)
        task.wait(0.15); tw(lf,{BackgroundTransparency=1},TM,function() lf:Destroy() end); task.wait(0.24)
    else
        tw(win,{Size=FULL},TS_); task.wait(0.3)
    end

    tw(winBS,{Transparency=0},TM)
    tw(topBar,{BackgroundTransparency=0},TM)
    tw(tbSep,{BackgroundTransparency=0},TM)
    tw(nameL,{TextTransparency=0},TM)
    tw(subL,{TextTransparency=0},TM)

    -- ── Close / Minimize / Hide ───────────────────────────────────────────────
    local function DoClose()
        local bl=Instance.new("Frame"); bl.Size=UDim2.new(1,0,1,0); bl.BackgroundTransparency=1; bl.ZIndex=900; bl.Parent=gui; Btn(bl,901)
        local ov=Box({Sz=UDim2.new(1,0,1,0),Bg=T.BG0,BgA=0,Z=500,Par=win})
        ScanFill(ov,5,T.Grid,0.88); Notch(ov,"tl",10,T.Err)
        local oT=Txt({T=cfg.Name, Sz=UDim2.new(1,0,0,20),Pos=UDim2.new(0.5,0,0.5,-16),AP=Vector2.new(0.5,0.5),
            Font=Enum.Font.Code,TS=18,Col=T.Err,AX=Enum.TextXAlignment.Center,Alpha=1,Z=501,Par=ov})
        local oS=Txt({T="SHUTTING DOWN...", Sz=UDim2.new(1,0,0,12),Pos=UDim2.new(0.5,0,0.5,6),AP=Vector2.new(0.5,0.5),
            Font=Enum.Font.Code,TS=10,Col=T.TxtLo,AX=Enum.TextXAlignment.Center,Alpha=1,Z=501,Par=ov})
        local oP=Box({Sz=UDim2.new(0.35,0,0,2),Pos=UDim2.new(0.5,0,0.5,26),AP=Vector2.new(0.5,0.5),Bg=T.BG3,Z=501,Par=ov})
        local oPF=Box({Sz=UDim2.new(0,0,1,0),Bg=T.Err,Z=502,Par=oP})
        tw(ov,{BackgroundTransparency=0},TI(.2,Enum.EasingStyle.Quad)); task.wait(0.1)
        tw(oPF,{Size=UDim2.new(1,0,1,0)},TI(.4,Enum.EasingStyle.Quad)); task.wait(0.25)
        oS.Text="TERMINATED"; tw(oPF,{BackgroundColor3=T.TxtHi},TF); task.wait(0.22)
        tw(win,{Size=UDim2.fromOffset(WW,0),BackgroundTransparency=1},TI(.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In))
        task.wait(0.32); Sentence:Destroy()
    end

    local function DoMinimize()
        if W._minimized then
            W._minimized=false; sidebar.Visible=true; contentArea.Visible=true
            tw(win,{Size=FULL},TK)
        else
            W._minimized=true; sidebar.Visible=false; contentArea.Visible=false
            tw(win,{Size=MINI},TI(.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out))
        end
    end

    local function HideW()
        W._visible=false
        tw(win,{Position=UDim2.new(0.5,0,1.25,0),Size=UDim2.fromOffset(WW*0.9,WH*0.9)},
            TI(.38,Enum.EasingStyle.Back,Enum.EasingDirection.In),
            function() win.Visible=false; win.Size=W._minimized and MINI or FULL end)
    end
    local function ShowW()
        win.Visible=true; W._visible=true
        win.Position=UDim2.new(0.5,0,1.25,0)
        win.Size=UDim2.fromOffset(WW*0.9,(W._minimized and MINI or FULL).Y.Offset*0.9)
        tw(win,{Position=UDim2.new(0.5,0,0.5,0),Size=W._minimized and MINI or FULL},TK)
    end

    ctrlBtns["X"].cl.MouseButton1Click:Connect(DoClose)
    ctrlBtns["M"].cl.MouseButton1Click:Connect(DoMinimize)
    ctrlBtns["H"].cl.MouseButton1Click:Connect(function()
        Sentence:Notify({Title="HIDDEN",Content="Press "..cfg.ToggleBind.Name.." to restore.",Type="Info"}); HideW()
    end)
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

        -- Sidebar icon button (square with icon)
        local hBox=Box({Sz=UDim2.new(0,34,0,34), Bg=T.BG0, BgA=1, Z=5, Par=tabList})
        Border(hBox, T.Wire, 1, 0.4)
        local hBar=Box({Sz=UDim2.new(0,3,1,0), Pos=UDim2.new(0,0,0,0), Bg=T.Green, BgA=1, Z=6, Par=hBox})
        local hIco=Img({Ico=hCfg.Icon, Sz=UDim2.new(0,14,0,14), Col=T.TxtLo, Z=6, Par=hBox})
        local hCL=Btn(hBox,7)

        local hPage=Instance.new("ScrollingFrame"); hPage.Name="HP"
        hPage.Size=UDim2.new(1,0,1,0); hPage.BackgroundTransparency=1; hPage.BorderSizePixel=0
        hPage.ScrollBarThickness=2; hPage.ScrollBarImageColor3=T.Green
        hPage.CanvasSize=UDim2.new(0,0,0,0); hPage.AutomaticCanvasSize=Enum.AutomaticSize.Y
        hPage.ZIndex=3; hPage.Visible=false; hPage.Parent=contentArea
        List(hPage,6); Pad(hPage,12,12,12,12)

        -- ── Player card ───────────────────────────────────────────────────────
        local pCard=Box({Sz=UDim2.new(1,0,0,72), Bg=T.BG2, Z=3, Par=hPage})
        Border(pCard, T.Wire, 1, 0)
        ScanFill(pCard, 6, T.Grid, 0.90)
        Notch(pCard,"tl",7,T.Green); Notch(pCard,"br",7,T.Amber)

        -- Green top accent strip
        local pcTop=Box({Sz=UDim2.new(1,0,0,2), Bg=T.Green, Z=5, Par=pCard})
        local pcTopG=Instance.new("UIGradient"); pcTopG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.Green),ColorSequenceKeypoint.new(0.5,T.Amber),ColorSequenceKeypoint.new(1,T.Wire)}; pcTopG.Parent=pcTop

        local pAv=Instance.new("ImageLabel"); pAv.Size=UDim2.new(0,42,0,42)
        pAv.Position=UDim2.new(0,12,0.5,0); pAv.AnchorPoint=Vector2.new(0,0.5)
        pAv.BackgroundTransparency=1; pAv.ZIndex=6; pAv.Parent=pCard
        Border(pAv, T.Green, 1, 0)
        pcall(function() pAv.Image=Plrs:GetUserThumbnailAsync(LP.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size150x150) end)

        Txt({T=LP.DisplayName, Sz=UDim2.new(1,-90,0,18), Pos=UDim2.new(0,68,0,14),
            Font=Enum.Font.Code, TS=15, Col=T.Green, Z=6, Par=pCard})
        Txt({T="USER::"..LP.Name:upper(), Sz=UDim2.new(1,-90,0,12), Pos=UDim2.new(0,68,0,34),
            Font=Enum.Font.Code, TS=10, Col=T.TxtMid, Z=6, Par=pCard})
        Txt({T="ID:"..LP.UserId, Sz=UDim2.new(1,-90,0,10), Pos=UDim2.new(0,68,0,48),
            Font=Enum.Font.Code, TS=9, Col=T.TxtLo, Z=6, Par=pCard})

        -- System tag
        local tag=Box({Sz=UDim2.new(0,0,0,14), Pos=UDim2.new(1,-10,0,8), AP=Vector2.new(1,0),
            Bg=T.GreenBg, Z=6, Par=pCard})
        tag.AutomaticSize=Enum.AutomaticSize.X; Pad(tag,0,0,4,4); Border(tag,T.Green,1,0.4)
        Txt({T="[SENTENCE v"..Sentence.Version.."]", Sz=UDim2.new(0,0,1,0), Font=Enum.Font.Code,
            TS=9, Col=T.Green, AutoX=true, Z=7, Par=tag})

        -- ── Server stats ──────────────────────────────────────────────────────
        local sCard=Box({Sz=UDim2.new(1,0,0,88), Bg=T.BG2, Z=3, Par=hPage})
        Border(sCard, T.Wire, 1, 0)
        ScanFill(sCard, 6, T.Grid, 0.90)
        Notch(sCard,"tl",7,T.Amber)

        local sHead=Box({Sz=UDim2.new(1,0,0,18), Bg=T.Amber, BgA=0, Z=5, Par=sCard})
        local shG=Instance.new("UIGradient"); shG.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.7),NumberSequenceKeypoint.new(1,1)}; shG.Parent=sHead
        Box({Sz=UDim2.new(1,0,0,1), Bg=T.Amber, Z=6, Par=sCard})
        Txt({T="▌ SYS::STATS", Sz=UDim2.new(1,-60,1,0), Pos=UDim2.new(0,8,0,0),
            Font=Enum.Font.Code, TS=10, Col=T.Amber, Z=6, Par=sHead})

        local statVals={}
        local statDefs={{"PLAYERS",""}, {"PING",""}, {"UPTIME",""}, {"REGION",""}}
        for i,sd in ipairs(statDefs) do
            local col=(i-1)%2; local row=math.floor((i-1)/2)
            local cW=(WW-SB_W-44)/2; local x=8+col*cW; local y=22+row*32
            Txt({T=sd[1]..":", Sz=UDim2.new(0,120,0,11), Pos=UDim2.new(0,x,0,y),
                Font=Enum.Font.Code, TS=9, Col=T.TxtLo, Z=4, Par=sCard})
            statVals[sd[1]]=Txt({T="--", Sz=UDim2.new(0,160,0,16), Pos=UDim2.new(0,x,0,y+11),
                Font=Enum.Font.Code, TS=13, Col=T.Amber, Z=4, Par=sCard})
        end
        task.spawn(function()
            while task.wait(1) do
                if not win or not win.Parent then break end
                pcall(function()
                    statVals["PLAYERS"].Text=#Plrs:GetPlayers().."/"..Plrs.MaxPlayers
                    local ms=math.floor(LP:GetNetworkPing()*1000)
                    statVals["PING"].Text=ms.."ms"
                    statVals["PING"].TextColor3=ms<80 and T.Ok or ms<150 and T.Warn or T.Err
                    local t2=math.floor(time())
                    statVals["UPTIME"].Text=string.format("%02d:%02d:%02d",math.floor(t2/3600),math.floor(t2%3600/60),t2%60)
                    pcall(function() statVals["REGION"].Text=game:GetService("LocalizationService"):GetCountryRegionForPlayerAsync(LP) end)
                end)
            end
        end)

        local HomeObj=BuildSectionAPI(hPage, T.Green, T.Amber)
        HomeObj.Activate=function() SwitchTab(id) end

        table.insert(W._tabs,{id=id,box=hBox,page=hPage,bar=hBar,ico=hIco})
        hCL.MouseButton1Click:Connect(function() SwitchTab(id) end)
        hBox.MouseEnter:Connect(function()
            if W._activeTab~=id then tw(hBox,{BackgroundTransparency=0.85},TF) end
            ttL.Text="> Home"; tooltip.Visible=true
            tw(tooltip,{Position=UDim2.new(0,SB_W+3,0,hBox.AbsolutePosition.Y-win.AbsolutePosition.Y+8)},TF)
        end)
        hBox.MouseLeave:Connect(function()
            if W._activeTab~=id then tw(hBox,{BackgroundTransparency=1},TF) end
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

        local tBox=Box({Sz=UDim2.new(0,34,0,34), Bg=T.BG0, BgA=1, Z=5, Ord=#W._tabs+1, Par=tabList})
        Border(tBox, T.Wire, 1, 0.5)
        local tBar=Box({Sz=UDim2.new(0,3,1,0), Pos=UDim2.new(0,0,0,0), Bg=T.Green, BgA=1, Z=6, Par=tBox})
        local tIco=Img({Ico=tCfg.Icon, Sz=UDim2.new(0,14,0,14), Col=T.TxtLo, Z=6, Par=tBox})
        local tCL=Btn(tBox,7)

        local tPage=Instance.new("ScrollingFrame"); tPage.Name=id
        tPage.Size=UDim2.new(1,0,1,0); tPage.BackgroundTransparency=1; tPage.BorderSizePixel=0
        tPage.ScrollBarThickness=2; tPage.ScrollBarImageColor3=T.Green
        tPage.CanvasSize=UDim2.new(0,0,0,0); tPage.AutomaticCanvasSize=Enum.AutomaticSize.Y
        tPage.ZIndex=3; tPage.Visible=false; tPage.Parent=contentArea
        List(tPage,5); Pad(tPage,12,12,12,12)

        if tCfg.ShowTitle then
            local tRow=Box({Sz=UDim2.new(1,0,0,22), Bg=T.BG2, Z=3, Par=tPage})
            Border(tRow, T.Wire, 1, 0)
            ScanFill(tRow, 4, T.Grid, 0.88)
            Txt({T=">> "..tCfg.Name:upper().." //", Sz=UDim2.new(1,-14,1,0), Pos=UDim2.new(0,10,0,0),
                Font=Enum.Font.Code, TS=13, Col=T.Green, Z=4, Par=tRow})
        end

        local secAPI=BuildSectionAPI(tPage, T.Green, T.Amber)
        for k,v in pairs(secAPI) do Tab[k]=v end
        function Tab:Activate() SwitchTab(id) end

        table.insert(W._tabs,{id=id,box=tBox,page=tPage,bar=tBar,ico=tIco})
        tCL.MouseButton1Click:Connect(function() Tab:Activate() end)
        tBox.MouseEnter:Connect(function()
            if W._activeTab~=id then tw(tBox,{BackgroundTransparency=0.85},TF) end
            ttL.Text="> "..tCfg.Name; tooltip.Visible=true
            tw(tooltip,{Position=UDim2.new(0,SB_W+3,0,tBox.AbsolutePosition.Y-win.AbsolutePosition.Y+8)},TF)
        end)
        tBox.MouseLeave:Connect(function()
            if W._activeTab~=id then tw(tBox,{BackgroundTransparency=1},TF) end
            tooltip.Visible=false
        end)
        return Tab
    end

    function W:SaveConfiguration() end
    function W:LoadConfiguration() end
    return W
end

-- ── Destroy ───────────────────────────────────────────────────────────────────
function Sentence:Destroy()
    for _,c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
    self._conns={}
    if self._notifHolder and self._notifHolder.Parent then self._notifHolder.Parent:Destroy() end
    self.Flags={}; self.Options={}
end

return Sentence

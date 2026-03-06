--[[
╔═══════════════════════════════════════════════════════════╗
║  SENTENCE GUI · OG Sentence Edition  v2.7                 ║
║  Home page rewrite — full CreateSection API               ║
║  + CreateBind / CreateInput / CreateDropdown              ║
╚═══════════════════════════════════════════════════════════╝
--]]

local Sentence = {
    Version = "2.7",
    Flags   = {},
    Options = {},
    _conns  = {},
}

-- ── Services ──────────────────────────────────────────────────────────────────
local TS    = game:GetService("TweenService")
local UIS   = game:GetService("UserInputService")
local RS    = game:GetService("RunService")
local Plrs  = game:GetService("Players")
local CG    = game:GetService("CoreGui")
local LP    = Plrs.LocalPlayer
local Cam   = workspace.CurrentCamera
local IsStudio = RS:IsStudio()

-- ── Theme ─────────────────────────────────────────────────────────────────────
local function H(hex)
    hex = hex:gsub("#","")
    return Color3.fromRGB(
        tonumber("0x"..hex:sub(1,2)),
        tonumber("0x"..hex:sub(3,4)),
        tonumber("0x"..hex:sub(5,6))
    )
end

local T = {
    BG0      = H("#0e0e0e"),
    BG1      = H("#121212"),
    BG2      = H("#161616"),
    BG3      = H("#1c1c1c"),
    BG4      = H("#222222"),
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
    Info    = { fg=T.Accent,  bg=T.BG2, stroke=T.Accent,  iconBg=T.BG3 },
    Success = { fg=T.Success, bg=T.BG2, stroke=T.Success, iconBg=T.BG3 },
    Warning = { fg=T.Warning, bg=T.BG2, stroke=T.Warning, iconBg=T.BG3 },
    Error   = { fg=T.Error,   bg=T.BG2, stroke=T.Error,   iconBg=T.BG3 },
}

-- ── Tween helpers ─────────────────────────────────────────────────────────────
local function TI(t,s,d) return TweenInfo.new(t or .2, s or Enum.EasingStyle.Exponential, d or Enum.EasingDirection.Out) end
local TI_FAST   = TI(.14)
local TI_MED    = TI(.24)
local TI_SLOW   = TI(.50)
local TI_SPRING = TweenInfo.new(.40, Enum.EasingStyle.Back,        Enum.EasingDirection.Out)
local TI_CIRC   = TweenInfo.new(.32, Enum.EasingStyle.Circular,    Enum.EasingDirection.Out)

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
    save="rbxassetid://6031280882",  reset="rbxassetid://6031094667",
    copy="rbxassetid://6034509993",  refresh="rbxassetid://6031094679",
    keyboard="rbxassetid://6026568227",
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
-- SHARED SECTION BUILDER
-- Builds a full CreateSection API onto any ScrollingFrame page.
-- Used by both CreateTab and CreateHomeTab.
-- ══════════════════════════════════════════════════════════════════════════════
local function BuildSectionAPI(page, accentColor)
    accentColor = accentColor or T.Accent
    local _sN = 0
    local API = {}

    -- ── Shared element helpers ─────────────────────────────────────────────
    local function Elem(secCon, h, autoY)
        local f = Box({Sz=UDim2.new(1,0,0,h or 40), Bg=T.BG2, BgA=0, R=6, Z=3, Par=secCon})
        if autoY then f.AutomaticSize=Enum.AutomaticSize.Y end
        local es=Instance.new("UIStroke")
        es.Color=accentColor; es.Thickness=1; es.Transparency=0.72
        es.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; es.Parent=f
        return f
    end

    local function HoverEff(f)
        f.MouseEnter:Connect(function()
            tw(f,{BackgroundColor3=T.BG3},TI_FAST)
            local s=f:FindFirstChildOfClass("UIStroke")
            if s then tw(s,{Transparency=0.45},TI_FAST) end
        end)
        f.MouseLeave:Connect(function()
            tw(f,{BackgroundColor3=T.BG2},TI_FAST)
            local s=f:FindFirstChildOfClass("UIStroke")
            if s then tw(s,{Transparency=0.72},TI_FAST) end
        end)
    end

    -- ── CreateSection ──────────────────────────────────────────────────────
    function API:CreateSection(sName)
        sName = sName or ""; _sN = _sN+1; local Sec = {}

        -- Section header row
        local shRow = Box({Name="SH", Sz=UDim2.new(1,0,0,sName~="" and 24 or 6), BgA=1, Z=3, Par=page})

        if sName ~= "" then
            -- Full-width separator line with accent→border gradient
            local line = Instance.new("Frame"); line.Size=UDim2.new(1,0,0,1)
            line.Position=UDim2.new(0,0,1,-1); line.BorderSizePixel=0; line.ZIndex=3; line.Parent=shRow
            local lineG = Instance.new("UIGradient")
            lineG.Color=ColorSequence.new{
                ColorSequenceKeypoint.new(0,accentColor),
                ColorSequenceKeypoint.new(0.35,T.Border),
                ColorSequenceKeypoint.new(1,T.Border)}
            lineG.Parent=line

            -- Badge: "#01 SECTION NAME"
            local badge = Box({Sz=UDim2.new(0,0,0,18), Pos=UDim2.new(0,0,0.5,0), AP=Vector2.new(0,0.5), Bg=T.BG1, R=0, Z=4, Par=shRow})
            badge.AutomaticSize=Enum.AutomaticSize.X; Pad(badge,0,0,0,10)
            local bRow = Instance.new("Frame"); bRow.Size=UDim2.new(0,0,1,0)
            bRow.AutomaticSize=Enum.AutomaticSize.X; bRow.BackgroundTransparency=1; bRow.ZIndex=5; bRow.Parent=badge
            List(bRow,0,Enum.FillDirection.Horizontal,nil,Enum.VerticalAlignment.Center)
            local nL = Instance.new("TextLabel"); nL.Text="#"..string.format("%02d",_sN).." "
            nL.Size=UDim2.new(0,0,1,0); nL.AutomaticSize=Enum.AutomaticSize.X
            nL.Font=Enum.Font.GothamBold; nL.TextSize=12; nL.TextColor3=accentColor
            nL.BackgroundTransparency=1; nL.BorderSizePixel=0; nL.ZIndex=5; nL.RichText=false; nL.Parent=bRow
            local nmL = Instance.new("TextLabel"); nmL.Text=sName:upper()
            nmL.Size=UDim2.new(0,0,1,0); nmL.AutomaticSize=Enum.AutomaticSize.X
            nmL.Font=Enum.Font.GothamBold; nmL.TextSize=12; nmL.TextColor3=T.TextLo
            nmL.BackgroundTransparency=1; nmL.BorderSizePixel=0; nmL.ZIndex=5; nmL.RichText=false; nmL.Parent=bRow
        end

        -- Content container
        local secCon = Box({Name="SC", Sz=UDim2.new(1,0,0,0), BgA=1, Z=3, AutoY=true, Par=page})
        List(secCon,5)

        -- ── Elements ───────────────────────────────────────────────────────
        function Sec:CreateDivider()
            local d = Instance.new("Frame"); d.Size=UDim2.new(1,0,0,1)
            local dG = Instance.new("UIGradient")
            dG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.Border),ColorSequenceKeypoint.new(1,T.BG1)}
            dG.Parent=d; d.BackgroundColor3=T.Border; d.BackgroundTransparency=0
            d.BorderSizePixel=0; d.ZIndex=3; d.Parent=secCon
            return {Destroy=function() d:Destroy() end}
        end

        function Sec:CreateLabel(lc)
            lc = merge({Name="",Text="",Style=1},lc or {})
            local text = lc.Text~="" and lc.Text or lc.Name or ""
            -- Style 1=grey, 2=accent blue, 3=warning yellow
            local cMap = {[1]=T.TextMid, [2]=accentColor, [3]=T.Warning}
            local st   = lc.Style or 1
            local f    = Elem(secCon, 32)
            local xo   = st>1 and 16 or 12
            if st>1 then
                Box({Sz=UDim2.new(0,3,0.65,0), Pos=UDim2.new(0,0,0.175,0), Bg=cMap[st], R=0, Z=5, Par=f})
            end
            local lb = Txt({T=text, Sz=UDim2.new(1,-xo-6,0,15), Pos=UDim2.new(0,xo,0.5,0), AP=Vector2.new(0,0.5),
                Font=Enum.Font.GothamSemibold, TS=15, Col=cMap[st], Z=4, Par=f})
            return {
                Set     = function(_,t) lb.Text=t end,
                Destroy = function() f:Destroy() end,
            }
        end

        function Sec:CreateParagraph(pc)
            pc = merge({Title="Title",Content=""},pc or {})
            local f = Elem(secCon,0,true); Pad(f,12,12,14,14); List(f,4)
            local pt  = Txt({T=pc.Title,   Sz=UDim2.new(1,0,0,18), Font=Enum.Font.GothamBold, TS=16, Col=T.TextHi,  Z=4, Par=f})
            local pc2 = Txt({T=pc.Content, Sz=UDim2.new(1,0,0,0),  Font=Enum.Font.Gotham,     TS=15, Col=T.TextMid, Z=4, Wrap=true, AutoY=true, Par=f})
            return {
                Set     = function(_,s) if s.Title then pt.Text=s.Title end; if s.Content then pc2.Text=s.Content end end,
                Destroy = function() f:Destroy() end,
            }
        end

        function Sec:CreateButton(bc)
            bc = merge({Name="Button",Description=nil,Callback=function()end},bc or {})
            local f = Elem(secCon, bc.Description and 58 or 40); f.ClipsDescendants=true

            local rFill = Box({Sz=UDim2.new(0,0,1,0), Bg=accentColor, BgA=1, R=0, Z=3, Par=f})
            local rGrad = Instance.new("UIGradient")
            rGrad.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.88),NumberSequenceKeypoint.new(1,1)}
            rGrad.Parent=rFill

            local pip = Box({Sz=UDim2.new(0,3,1,0), Pos=UDim2.new(0,0,0,0), Bg=accentColor, BgA=1, R=0, Z=5, Par=f})
            Txt({T=bc.Name, Sz=UDim2.new(1,-50,0,17), Pos=UDim2.new(0,16,0,bc.Description and 10 or 12),
                Font=Enum.Font.GothamSemibold, TS=16, Col=T.TextHi, Z=5, Par=f})
            if bc.Description then
                Txt({T=bc.Description, Sz=UDim2.new(1,-50,0,15), Pos=UDim2.new(0,16,0,30),
                    Font=Enum.Font.Gotham, TS=14, Col=T.TextMid, Z=5, Par=f})
            end
            local arr = Img({Ico="arr", Sz=UDim2.new(0,13,0,13), Pos=UDim2.new(1,-20,0.5,0), AP=Vector2.new(0,0.5),
                Col=accentColor, IA=0.5, Z=6, Par=f})

            local cl = Btn(f,7)
            f.MouseEnter:Connect(function()
                tw(rFill,{Size=UDim2.new(1,0,1,0),BackgroundTransparency=0},TI(.28,Enum.EasingStyle.Quad))
                tw(pip,{BackgroundTransparency=0},TI_FAST)
                tw(arr,{ImageTransparency=0,ImageColor3=T.TextHi},TI_FAST)
                local s=f:FindFirstChildOfClass("UIStroke"); if s then tw(s,{Transparency=0.3},TI_FAST) end
            end)
            f.MouseLeave:Connect(function()
                tw(rFill,{Size=UDim2.new(0,0,1,0),BackgroundTransparency=1},TI_MED)
                tw(pip,{BackgroundTransparency=1},TI_FAST)
                tw(arr,{ImageTransparency=0.5,ImageColor3=accentColor},TI_FAST)
                local s=f:FindFirstChildOfClass("UIStroke"); if s then tw(s,{Transparency=0.72},TI_FAST) end
            end)
            cl.MouseButton1Click:Connect(function()
                tw(rFill,{BackgroundColor3=T.TextHi},TI(.08,Enum.EasingStyle.Quad))
                task.wait(0.10)
                tw(rFill,{BackgroundColor3=accentColor,Size=UDim2.new(0,0,1,0),BackgroundTransparency=1},TI_MED)
                safe(bc.Callback)
            end)
            return {Destroy=function() f:Destroy() end}
        end

        function Sec:CreateToggle(tc)
            tc=merge({Name="Toggle",Description=nil,CurrentValue=false,Flag=nil,Callback=function()end},tc or {})
            local f = Elem(secCon, tc.Description and 58 or 40)
            Txt({T=tc.Name, Sz=UDim2.new(1,-72,0,17), Pos=UDim2.new(0,14,0,tc.Description and 10 or 12),
                Font=Enum.Font.GothamSemibold, TS=16, Col=T.TextHi, Z=5, Par=f})
            if tc.Description then
                Txt({T=tc.Description, Sz=UDim2.new(1,-72,0,15), Pos=UDim2.new(0,14,0,30),
                    Font=Enum.Font.Gotham, TS=14, Col=T.TextMid, Z=5, Par=f})
            end
            local trk  = Box({Sz=UDim2.new(0,46,0,24), Pos=UDim2.new(1,-58,0.5,0), AP=Vector2.new(0,0.5),
                Bg=T.BG3, R=12, Border=true, BorderCol=T.Border, Z=5, Par=f})
            local knob = Box({Sz=UDim2.new(0,18,0,18), Pos=UDim2.new(0,3,0.5,0), AP=Vector2.new(0,0.5),
                Bg=T.TextLo, R=9, Z=6, Par=trk})
            local kDot = Box({Sz=UDim2.new(0,6,0,6), Pos=UDim2.new(0.5,0,0.5,0), AP=Vector2.new(0.5,0.5),
                Bg=T.TextHi, BgA=0.6, R=3, Z=7, Par=knob})

            local TV = {CurrentValue=tc.CurrentValue, Type="Toggle", Settings=tc}
            local function upd()
                if TV.CurrentValue then
                    tw(trk,{BackgroundColor3=T.AccentLo},TI_MED)
                    local s=trk:FindFirstChildOfClass("UIStroke"); if s then tw(s,{Color=accentColor,Transparency=0.3},TI_MED) end
                    tw(knob,{Position=UDim2.new(1,-21,0.5,0),BackgroundColor3=accentColor},TI_SPRING)
                    tw(kDot,{BackgroundTransparency=0},TI_FAST)
                else
                    tw(trk,{BackgroundColor3=T.BG3},TI_MED)
                    local s=trk:FindFirstChildOfClass("UIStroke"); if s then tw(s,{Color=T.Border,Transparency=0},TI_MED) end
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
            local f = Elem(secCon, 58)
            Txt({T=sc.Name, Sz=UDim2.new(1,-120,0,17), Pos=UDim2.new(0,14,0,9),
                Font=Enum.Font.GothamSemibold, TS=16, Col=T.TextHi, Z=5, Par=f})

            local vc = Box({Sz=UDim2.new(0,0,0,22), Pos=UDim2.new(1,-13,0,7), AP=Vector2.new(1,0),
                Bg=T.AccentLo, R=5, Border=true, BorderCol=T.AccentDim, BorderA=0.4, Z=5, Par=f})
            vc.AutomaticSize=Enum.AutomaticSize.X; Pad(vc,0,0,8,8)
            local vL = Txt({T=tostring(sc.CurrentValue)..sc.Suffix, Sz=UDim2.new(0,0,1,0),
                Font=Enum.Font.Code, TS=14, Col=accentColor, AX=Enum.TextXAlignment.Center, Z=6, Par=vc})
            vL.AutomaticSize=Enum.AutomaticSize.X

            local bg    = Box({Sz=UDim2.new(1,-28,0,5), Pos=UDim2.new(0,14,0,38), Bg=T.BG3, R=3, Z=5, Par=f})
            local fill  = Box({Sz=UDim2.new(0,0,1,0), Bg=accentColor, R=3, Z=6, Par=bg})
            local fillG = Instance.new("UIGradient")
            fillG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,H("#4580C9")),ColorSequenceKeypoint.new(1,H("#8BC4FF"))}
            fillG.Parent=fill
            local thumb = Box({Sz=UDim2.new(0,12,0,12), Pos=UDim2.new(0,0,0.5,0), AP=Vector2.new(0.5,0.5),
                Bg=T.TextHi, R=6, Z=7, Par=bg})
            local thG   = Instance.new("UIStroke"); thG.Color=accentColor; thG.Thickness=2; thG.Transparency=0.5; thG.Parent=thumb

            local SV = {CurrentValue=sc.CurrentValue, Type="Slider", Settings=sc}
            local mn,mx,inc = sc.Range[1],sc.Range[2],sc.Increment
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

        function Sec:CreateColorPicker(cc2)
            cc2=merge({Name="Color",Flag=nil,Color=Color3.new(1,1,1),Callback=function()end},cc2 or {})
            local f = Elem(secCon,40)
            Txt({T=cc2.Name, Sz=UDim2.new(1,-60,0,17), Pos=UDim2.new(0,14,0,12),
                Font=Enum.Font.GothamSemibold, TS=16, Col=T.TextHi, Z=5, Par=f})
            local swatch = Box({Sz=UDim2.new(0,24,0,24), Pos=UDim2.new(1,-42,0.5,0), AP=Vector2.new(0,0.5),
                Bg=cc2.Color, R=5, Border=true, BorderCol=T.Border, Z=5, Par=f})
            local CV = {CurrentValue=cc2.Color, Type="ColorPicker", Settings=cc2}
            function CV:Set(c) CV.CurrentValue=c; swatch.BackgroundColor3=c; safe(cc2.Callback,c) end
            if cc2.Flag then Sentence.Flags[cc2.Flag]=CV; Sentence.Options[cc2.Flag]=CV end
            return CV
        end

        -- ══════════════════════════════════════════════════════════════════════
        -- CreateBind / CreateKeybind
        -- ══════════════════════════════════════════════════════════════════════
        function Sec:CreateBind(bc)
            bc = merge({
                Name             = "Keybind",
                Description      = nil,
                CurrentBind      = "E",
                HoldToInteract   = false,
                Flag             = nil,
                Callback         = function() end,
                OnChangedCallback= function() end,
            }, bc or {})

            local h = bc.Description and 58 or 40
            local f = Elem(secCon, h)

            -- Name label
            Txt({T=bc.Name,
                Sz=UDim2.new(1,-110,0,17),
                Pos=UDim2.new(0,14,0,bc.Description and 10 or 12),
                Font=Enum.Font.GothamSemibold, TS=16, Col=T.TextHi, Z=5, Par=f})

            -- Description (optional)
            if bc.Description then
                Txt({T=bc.Description,
                    Sz=UDim2.new(1,-110,0,15),
                    Pos=UDim2.new(0,14,0,30),
                    Font=Enum.Font.Gotham, TS=14, Col=T.TextMid, Z=5, Par=f})
            end

            -- Hold-to-interact badge (small, top-right corner of key pill, only when enabled)
            -- Key display pill
            local pill = Box({
                Sz=UDim2.new(0,0,0,26),
                Pos=UDim2.new(1,-12,0.5,0),
                AP=Vector2.new(1,0.5),
                Bg=T.BG3, R=5,
                Border=true, BorderCol=T.AccentDim, BorderA=0.4,
                Z=5, Par=f
            })
            pill.AutomaticSize = Enum.AutomaticSize.X
            Pad(pill, 0, 0, 10, 10)

            local keyTxt = Txt({
                T = bc.CurrentBind,
                Sz=UDim2.new(0,0,1,0),
                Font=Enum.Font.Code, TS=14,
                Col=accentColor,
                AX=Enum.TextXAlignment.Center,
                AutoX=true, Z=6, Par=pill
            })

            -- Optional "HOLD" micro-badge beneath pill
            local holdBadge
            if bc.HoldToInteract then
                holdBadge = Box({
                    Sz=UDim2.new(0,0,0,13),
                    Pos=UDim2.new(1,-12,1,-4),
                    AP=Vector2.new(1,1),
                    Bg=T.AccentLo, R=3,
                    Border=true, BorderCol=T.AccentDim, BorderA=0.55,
                    Z=6, Par=f
                })
                holdBadge.AutomaticSize = Enum.AutomaticSize.X
                Pad(holdBadge,0,0,4,4)
                Txt({T="HOLD", Sz=UDim2.new(0,0,1,0),
                    Font=Enum.Font.GothamBold, TS=9,
                    Col=accentColor,
                    AX=Enum.TextXAlignment.Center,
                    AutoX=true, Z=7, Par=holdBadge})
            end

            -- State
            local BV = {CurrentBind=bc.CurrentBind, Type="Bind", Settings=bc}
            local listening    = false
            local holdActive   = false
            local holdConn

            -- Listening state visuals
            local function setListening(v)
                listening = v
                if v then
                    tw(pill, {BackgroundColor3=T.AccentLo}, TI_FAST)
                    local s = pill:FindFirstChildOfClass("UIStroke")
                    if s then tw(s,{Color=accentColor,Transparency=0.15},TI_FAST) end
                    keyTxt.Text = "..."
                else
                    tw(pill, {BackgroundColor3=T.BG3}, TI_FAST)
                    local s = pill:FindFirstChildOfClass("UIStroke")
                    if s then tw(s,{Color=T.AccentDim,Transparency=0.4},TI_FAST) end
                    keyTxt.Text = BV.CurrentBind
                end
            end

            -- Click pill → enter listen mode
            local pillBtn = Btn(pill, 8)
            pillBtn.MouseButton1Click:Connect(function()
                if listening then setListening(false); return end
                setListening(true)
            end)

            -- Hover glow on pill
            pill.MouseEnter:Connect(function()
                if not listening then
                    local s = pill:FindFirstChildOfClass("UIStroke")
                    if s then tw(s,{Transparency=0.1},TI_FAST) end
                end
            end)
            pill.MouseLeave:Connect(function()
                if not listening then
                    local s = pill:FindFirstChildOfClass("UIStroke")
                    if s then tw(s,{Transparency=0.4},TI_FAST) end
                end
            end)

            -- Global key capture
            track(UIS.InputBegan:Connect(function(inp, proc)
                -- While listening: capture next key press as new bind
                if listening then
                    if inp.UserInputType == Enum.UserInputType.Keyboard then
                        local kn = inp.KeyCode.Name
                        if kn == "Escape" then setListening(false); return end
                        BV.CurrentBind = kn
                        setListening(false)
                        safe(bc.OnChangedCallback, kn)
                    end
                    return
                end

                if proc then return end

                -- Normal trigger: match bound key
                if inp.UserInputType == Enum.UserInputType.Keyboard
                    and inp.KeyCode.Name == BV.CurrentBind then

                    if bc.HoldToInteract then
                        holdActive = true
                        safe(bc.Callback, true)
                    else
                        safe(bc.Callback, true)
                    end
                end
            end))

            track(UIS.InputEnded:Connect(function(inp)
                if bc.HoldToInteract
                    and inp.UserInputType == Enum.UserInputType.Keyboard
                    and inp.KeyCode.Name == BV.CurrentBind
                    and holdActive then
                    holdActive = false
                    safe(bc.Callback, false)
                end
            end))

            HoverEff(f)

            function BV:Set(keyName)
                BV.CurrentBind = keyName
                keyTxt.Text    = keyName
                safe(bc.OnChangedCallback, keyName)
            end
            function BV:Destroy() f:Destroy() end

            if bc.Flag then Sentence.Flags[bc.Flag]=BV; Sentence.Options[bc.Flag]=BV end
            return BV
        end

        -- Alias
        Sec.CreateKeybind = Sec.CreateBind

        -- ══════════════════════════════════════════════════════════════════════
        -- CreateInput
        -- ══════════════════════════════════════════════════════════════════════
        function Sec:CreateInput(ic)
            ic = merge({
                Name                   = "Input",
                Description            = nil,
                PlaceholderText        = "Type here...",
                CurrentValue           = "",
                Numeric                = false,
                MaxCharacters          = nil,
                Enter                  = false,
                RemoveTextAfterFocusLost = false,
                Flag                   = nil,
                Callback               = function() end,
            }, ic or {})

            local h = ic.Description and 72 or 56
            local f = Elem(secCon, h)

            -- Name label
            Txt({T=ic.Name,
                Sz=UDim2.new(1,-24,0,16),
                Pos=UDim2.new(0,14,0,8),
                Font=Enum.Font.GothamSemibold, TS=15, Col=T.TextHi, Z=5, Par=f})

            -- Description
            if ic.Description then
                Txt({T=ic.Description,
                    Sz=UDim2.new(1,-24,0,13),
                    Pos=UDim2.new(0,14,0,26),
                    Font=Enum.Font.Gotham, TS=13, Col=T.TextMid, Z=5, Par=f})
            end

            local fieldY = ic.Description and 42 or 28
            local fieldH = 22

            -- Input field background
            local fieldBg = Box({
                Sz=UDim2.new(1,-28,0,fieldH),
                Pos=UDim2.new(0,14,0,fieldY),
                Bg=T.BG1, R=4,
                Border=true, BorderCol=T.Border, BorderA=0.2,
                Z=5, Par=f
            })
            Pad(fieldBg, 0, 0, 8, ic.Numeric and 28 or 8)

            -- Accent left pip on field
            Box({Sz=UDim2.new(0,2,1,0), Pos=UDim2.new(0,0,0,0), Bg=accentColor, BgA=0.6, R=0, Z=6, Par=fieldBg})

            -- "123" badge for numeric mode
            if ic.Numeric then
                local nb = Box({
                    Sz=UDim2.new(0,20,1,0),
                    Pos=UDim2.new(1,0,0,0), AP=Vector2.new(1,0),
                    Bg=T.AccentLo, R=4, Z=6, Par=fieldBg
                })
                Txt({T="#",
                    Sz=UDim2.new(1,0,1,0),
                    Font=Enum.Font.GothamBold, TS=11,
                    Col=accentColor, AX=Enum.TextXAlignment.Center,
                    Z=7, Par=nb})
            end

            -- Actual TextBox
            local tb = Instance.new("TextBox")
            tb.Name         = "InputBox"
            tb.Size         = UDim2.new(1,0,1,0)
            tb.BackgroundTransparency = 1
            tb.BorderSizePixel = 0
            tb.PlaceholderText = ic.PlaceholderText
            tb.PlaceholderColor3 = T.TextLo
            tb.Text         = ic.CurrentValue
            tb.Font         = Enum.Font.Code
            tb.TextSize     = 13
            tb.TextColor3   = T.TextHi
            tb.TextXAlignment = Enum.TextXAlignment.Left
            tb.ClearTextOnFocus = false
            tb.ZIndex       = 7
            tb.Parent       = fieldBg

            local IV = {CurrentValue=ic.CurrentValue, Type="Input", Settings=ic}

            -- Focus / unfocus styling
            tb.Focused:Connect(function()
                local s = fieldBg:FindFirstChildOfClass("UIStroke")
                if s then tw(s,{Color=accentColor,Transparency=0},TI_FAST) end
                tw(fieldBg,{BackgroundColor3=T.BG2},TI_FAST)
            end)

            tb.FocusLost:Connect(function(enterPressed)
                local s = fieldBg:FindFirstChildOfClass("UIStroke")
                if s then tw(s,{Color=T.Border,Transparency=0.2},TI_FAST) end
                tw(fieldBg,{BackgroundColor3=T.BG1},TI_FAST)

                local val = tb.Text

                -- Numeric filter
                if ic.Numeric then
                    val = val:gsub("[^%d%.%-]","")
                    tb.Text = val
                end

                -- Max characters
                if ic.MaxCharacters and #val > ic.MaxCharacters then
                    val = val:sub(1,ic.MaxCharacters)
                    tb.Text = val
                end

                IV.CurrentValue = val

                if ic.RemoveTextAfterFocusLost then
                    tb.Text = ""
                    IV.CurrentValue = ""
                end

                -- Fire callback: either on Enter-only or always on focus lost
                if ic.Enter then
                    if enterPressed then safe(ic.Callback, val) end
                else
                    safe(ic.Callback, val)
                end
            end)

            -- Live numeric filter while typing
            if ic.Numeric then
                tb:GetPropertyChangedSignal("Text"):Connect(function()
                    local clean = tb.Text:gsub("[^%d%.%-]","")
                    if clean ~= tb.Text then tb.Text = clean end
                    if ic.MaxCharacters and #tb.Text > ic.MaxCharacters then
                        tb.Text = tb.Text:sub(1,ic.MaxCharacters)
                    end
                end)
            elseif ic.MaxCharacters then
                tb:GetPropertyChangedSignal("Text"):Connect(function()
                    if #tb.Text > ic.MaxCharacters then
                        tb.Text = tb.Text:sub(1,ic.MaxCharacters)
                    end
                end)
            end

            HoverEff(f)

            function IV:Set(v)
                v = tostring(v)
                if ic.MaxCharacters and #v > ic.MaxCharacters then v = v:sub(1,ic.MaxCharacters) end
                tb.Text        = v
                IV.CurrentValue = v
            end
            function IV:Destroy() f:Destroy() end

            if ic.Flag then Sentence.Flags[ic.Flag]=IV; Sentence.Options[ic.Flag]=IV end
            return IV
        end

        -- ══════════════════════════════════════════════════════════════════════
        -- CreateDropdown
        -- ══════════════════════════════════════════════════════════════════════
        function Sec:CreateDropdown(dc)
            dc = merge({
                Name            = "Dropdown",
                Description     = nil,
                Options         = {"Option 1","Option 2"},
                CurrentOption   = nil,
                MultipleOptions = false,
                SpecialType     = nil,
                Flag            = nil,
                Callback        = function() end,
            }, dc or {})

            -- Player special type: auto-populate from server
            local function resolveOptions()
                if dc.SpecialType == "Player" then
                    local t={}
                    for _,p in ipairs(Plrs:GetPlayers()) do t[#t+1]=p.Name end
                    return t
                end
                return dc.Options
            end

            -- Normalise current selection
            local opts = resolveOptions()
            local function defaultSel()
                if dc.MultipleOptions then return {} end
                return opts[1] or ""
            end
            local currentSel  -- string (single) or table (multi)
            if dc.CurrentOption ~= nil then
                currentSel = dc.CurrentOption
            else
                currentSel = defaultSel()
            end

            -- ── Frame ────────────────────────────────────────────────────────
            local baseH = dc.Description and 72 or 56
            local f = Elem(secCon, baseH, true)

            -- Name
            Txt({T=dc.Name,
                Sz=UDim2.new(1,-24,0,16),
                Pos=UDim2.new(0,14,0,8),
                Font=Enum.Font.GothamSemibold, TS=15, Col=T.TextHi, Z=5, Par=f})

            if dc.Description then
                Txt({T=dc.Description,
                    Sz=UDim2.new(1,-24,0,13),
                    Pos=UDim2.new(0,14,0,26),
                    Font=Enum.Font.Gotham, TS=13, Col=T.TextMid, Z=5, Par=f})
            end

            local headerY = dc.Description and 42 or 28
            local headerH = 24

            -- Display bar (closed state)
            local headerBar = Box({
                Sz=UDim2.new(1,-28,0,headerH),
                Pos=UDim2.new(0,14,0,headerY),
                Bg=T.BG1, R=5,
                Border=true, BorderCol=T.Border, BorderA=0.2,
                Z=5, Par=f
            })
            Pad(headerBar,0,0,10,34)

            -- Left accent pip on bar
            Box({Sz=UDim2.new(0,2,1,0), Pos=UDim2.new(0,0,0,0), Bg=accentColor, BgA=0.6, R=0, Z=6, Par=headerBar})

            -- Current value text
            local dispTxt = Txt({
                T="",
                Sz=UDim2.new(1,0,1,0),
                Font=Enum.Font.Code, TS=13, Col=T.TextHi,
                Z=6, Par=headerBar
            })

            -- Chevron
            local chev = Img({Ico="chev_d",
                Sz=UDim2.new(0,11,0,11),
                Pos=UDim2.new(1,-18,0.5,0), AP=Vector2.new(0.5,0.5),
                Col=T.TextLo, Z=7, Par=headerBar})

            -- Dropdown panel (absolute, sits below header)
            local panel = Box({
                Name="DropPanel",
                Sz=UDim2.new(1,-28,0,0),
                Pos=UDim2.new(0,14,0,headerY+headerH+4),
                Bg=T.BG1, R=5,
                Border=true, BorderCol=T.AccentDim, BorderA=0.3,
                Z=10, Clip=true, Par=f
            })
            panel.Visible = false
            panel.AutomaticSize = Enum.AutomaticSize.None

            local panelScroll = Instance.new("ScrollingFrame")
            panelScroll.Size=UDim2.new(1,0,1,0)
            panelScroll.BackgroundTransparency=1
            panelScroll.BorderSizePixel=0
            panelScroll.ScrollBarThickness=2
            panelScroll.ScrollBarImageColor3=T.Border
            panelScroll.CanvasSize=UDim2.new(0,0,0,0)
            panelScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
            panelScroll.ZIndex=11
            panelScroll.Parent=panel
            List(panelScroll,2); Pad(panelScroll,4,4,4,4)

            local DV = {
                CurrentOption=currentSel,
                Type="Dropdown",
                Settings=dc,
                _open=false,
                _items={}
            }

            -- Helper: get display string
            local function dispStr()
                if dc.MultipleOptions then
                    if type(currentSel)=="table" and #currentSel>0 then
                        return table.concat(currentSel,", ")
                    end
                    return "None"
                else
                    return tostring(currentSel)
                end
            end

            -- Helper: is option selected?
            local function isSelected(opt)
                if dc.MultipleOptions then
                    for _,v in ipairs(currentSel) do if v==opt then return true end end
                    return false
                else
                    return currentSel==opt
                end
            end

            -- Forward-declare rebuild so items can reference toggle
            local rebuildItems

            -- Open / close
            local function openPanel()
                DV._open = true
                panel.Visible = true
                local maxItems = math.min(#DV._items,5)
                local panH = maxItems * 28 + (maxItems+1)*2 + 8
                panel.Size = UDim2.new(1,-28,0,0)
                tw(panel,{Size=UDim2.new(1,-28,0,panH)},TI_SPRING)
                tw(chev,{Rotation=180,ImageColor3=accentColor},TI_FAST)
                local s=headerBar:FindFirstChildOfClass("UIStroke")
                if s then tw(s,{Color=accentColor,Transparency=0.1},TI_FAST) end
            end

            local function closePanel()
                DV._open = false
                tw(panel,{Size=UDim2.new(1,-28,0,0)},TI_MED,function()
                    panel.Visible=false
                end)
                tw(chev,{Rotation=0,ImageColor3=T.TextLo},TI_FAST)
                local s=headerBar:FindFirstChildOfClass("UIStroke")
                if s then tw(s,{Color=T.Border,Transparency=0.2},TI_FAST) end
            end

            -- Build item rows
            rebuildItems = function()
                -- Clear old items
                for _,i in ipairs(DV._items) do pcall(function() i:Destroy() end) end
                DV._items = {}

                local curOpts = resolveOptions()
                for _,opt in ipairs(curOpts) do
                    local row = Box({
                        Sz=UDim2.new(1,0,0,26),
                        Bg=T.BG2, R=4, Z=12, Par=panelScroll
                    })
                    row.BackgroundTransparency = isSelected(opt) and 0 or 1

                    -- Tick mark
                    local tick = Img({Ico="ok",
                        Sz=UDim2.new(0,10,0,10),
                        Pos=UDim2.new(1,-14,0.5,0), AP=Vector2.new(0.5,0.5),
                        Col=accentColor, IA=isSelected(opt) and 0 or 1,
                        Z=13, Par=row})

                    Txt({T=opt,
                        Sz=UDim2.new(1,-30,1,0),
                        Pos=UDim2.new(0,10,0,0),
                        Font=Enum.Font.GothamSemibold, TS=13,
                        Col=isSelected(opt) and T.TextHi or T.TextMid,
                        Z=13, Par=row})

                    local rowBtn = Btn(row,14)
                    row.MouseEnter:Connect(function()
                        if not isSelected(opt) then
                            tw(row,{BackgroundTransparency=0.6,BackgroundColor3=T.BG3},TI_FAST)
                        end
                    end)
                    row.MouseLeave:Connect(function()
                        if not isSelected(opt) then
                            tw(row,{BackgroundTransparency=1},TI_FAST)
                        end
                    end)

                    rowBtn.MouseButton1Click:Connect(function()
                        if dc.MultipleOptions then
                            -- Toggle in list
                            if type(currentSel)~="table" then currentSel={} end
                            local found=false
                            for i2,v in ipairs(currentSel) do
                                if v==opt then table.remove(currentSel,i2); found=true; break end
                            end
                            if not found then currentSel[#currentSel+1]=opt end
                            DV.CurrentOption=currentSel
                            dispTxt.Text=dispStr()
                            safe(dc.Callback,currentSel)
                            -- Refresh ticks without full rebuild
                            rebuildItems()
                        else
                            currentSel=opt
                            DV.CurrentOption=opt
                            dispTxt.Text=dispStr()
                            safe(dc.Callback,opt)
                            closePanel()
                        end
                    end)

                    DV._items[#DV._items+1] = row
                end
            end

            -- Initialise display
            rebuildItems()
            dispTxt.Text = dispStr()

            -- Toggle on header click
            local hBtn = Btn(headerBar, 8)
            hBtn.MouseButton1Click:Connect(function()
                if DV._open then closePanel() else openPanel() end
            end)

            -- Hover on header
            headerBar.MouseEnter:Connect(function()
                tw(headerBar,{BackgroundColor3=T.BG2},TI_FAST)
            end)
            headerBar.MouseLeave:Connect(function()
                tw(headerBar,{BackgroundColor3=T.BG1},TI_FAST)
            end)

            -- Public API
            function DV:Set(options)
                if dc.MultipleOptions then
                    currentSel = type(options)=="table" and options or {options}
                else
                    currentSel = options
                end
                DV.CurrentOption = currentSel
                dispTxt.Text     = dispStr()
                if DV._open then rebuildItems() end
                safe(dc.Callback, currentSel)
            end

            function DV:Refresh(newOptions)
                dc.Options = newOptions or dc.Options
                local wasOpen = DV._open
                if wasOpen then closePanel() end
                -- Reset selection to default
                currentSel  = defaultSel()
                DV.CurrentOption = currentSel
                dispTxt.Text = dispStr()
                rebuildItems()
                if wasOpen then task.wait(0.05); openPanel() end
            end

            function DV:Destroy() f:Destroy() end

            HoverEff(f)

            if dc.Flag then Sentence.Flags[dc.Flag]=DV; Sentence.Options[dc.Flag]=DV end
            return DV
        end

        return Sec
    end

    -- ── Default section shortcut ───────────────────────────────────────────
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
-- NOTIFICATIONS
-- ══════════════════════════════════════════════════════════════════════════════
function Sentence:Notify(data)
    task.spawn(function()
        data = merge({Title="Notice",Content="",Icon="info",Type="Info",Duration=5},data)
        local pal = NotifPalette[data.Type] or NotifPalette.Info

        local card = Box({Name="NCard", Sz=UDim2.new(0,300,0,0), Pos=UDim2.new(-1.1,0,1,0),
            AP=Vector2.new(0,1), Bg=T.BG1, BgA=1, Clip=true, R=7, Par=self._notifHolder})

        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color=pal.stroke; cardStroke.Thickness=1; cardStroke.Transparency=1
        cardStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; cardStroke.Parent=card

        local bgFill    = Box({Sz=UDim2.new(1,0,1,0), Bg=pal.bg, BgA=1, R=7, Z=1, Par=card})
        local accentBar = Box({Sz=UDim2.new(0,2,1,0), Pos=UDim2.new(0,0,0,0), Bg=pal.fg, BgA=1, R=0, Z=8, Par=card})
        local sideGlow  = Box({Sz=UDim2.new(0,80,1,0), Pos=UDim2.new(0,2,0,0), Bg=pal.fg, BgA=1, R=0, Z=2, Par=card})
        local sg=Instance.new("UIGradient")
        sg.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,pal.fg),ColorSequenceKeypoint.new(1,T.BG1)}
        sg.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.90),NumberSequenceKeypoint.new(1,1)}
        sg.Parent=sideGlow

        local iconRing = Box({Sz=UDim2.new(0,28,0,28), Pos=UDim2.new(0,12,0,0), AP=Vector2.new(0,0.5),
            Bg=pal.iconBg, BgA=1, R=5, Z=6, Par=card})
        local iconRingStroke=Instance.new("UIStroke"); iconRingStroke.Color=pal.fg
        iconRingStroke.Thickness=1; iconRingStroke.Transparency=1
        iconRingStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; iconRingStroke.Parent=iconRing
        local iconImg = Img({Ico=data.Icon, Sz=UDim2.new(0,13,0,13), Col=pal.fg, IA=1, Z=7, Par=iconRing})

        local cc = Box({Name="CC", Sz=UDim2.new(1,0,0,0), Pos=UDim2.new(0,0,0,0), BgA=1, AutoY=true, Z=5, Par=card})
        Pad(cc,9,11,52,32); List(cc,2)

        local typeBadge = Box({Sz=UDim2.new(0,0,0,14), Bg=pal.fg, BgA=1, R=3, Z=6, AutoX=true, Par=cc})
        Pad(typeBadge,0,0,5,5)
        local typeL = Txt({T=data.Type:upper(), Sz=UDim2.new(0,0,1,0), Font=Enum.Font.GothamBold, TS=10,
            Col=T.BG1, AX=Enum.TextXAlignment.Center, Alpha=1, AutoX=true, Z=7, Par=typeBadge})
        local ttl = Txt({T=data.Title,   Sz=UDim2.new(1,0,0,17), Font=Enum.Font.GothamBold, TS=14, Col=T.TextHi,  Alpha=1, Z=6, Par=cc})
        local msg = Txt({T=data.Content, Sz=UDim2.new(1,0,0,0),  Font=Enum.Font.Gotham,     TS=13, Col=T.TextMid, Alpha=1, Wrap=true, AutoY=true, Z=6, Par=cc})

        local pTrack = Box({Sz=UDim2.new(1,0,0,2), Pos=UDim2.new(0,0,1,-2), Bg=T.BG3, BgA=1, R=0, Z=6, Par=card})
        local pFill  = Box({Sz=UDim2.new(1,0,1,0), Bg=pal.fg, BgA=1, R=0, Z=7, Par=pTrack})

        local xBtn = Box({Sz=UDim2.new(0,16,0,16), Pos=UDim2.new(1,-8,0,8), AP=Vector2.new(1,0),
            Bg=T.BG3, BgA=1, R=4, Z=9, Par=card})
        local xIco = Img({Ico="close", Sz=UDim2.new(0,7,0,7), Col=T.TextLo, Z=10, Par=xBtn})
        local xCL  = Btn(xBtn,11)
        xBtn.MouseEnter:Connect(function() tw(xBtn,{BackgroundColor3=T.Error},TI_FAST); tw(xIco,{ImageColor3=T.TextHi},TI_FAST) end)
        xBtn.MouseLeave:Connect(function() tw(xBtn,{BackgroundColor3=T.BG3},TI_FAST); tw(xIco,{ImageColor3=T.TextLo},TI_FAST) end)

        task.wait()
        local cardH = cc.AbsoluteSize.Y + 4
        iconRing.Position = UDim2.new(0,12,0,cardH/2-14)
        card.Size=UDim2.new(0,300,0,cardH); card.Position=UDim2.new(-1.1,0,1,0)

        for _,el in ipairs({bgFill,accentBar,sideGlow,iconRing,typeBadge}) do el.BackgroundTransparency=1 end
        iconImg.ImageTransparency=1; typeL.TextTransparency=1; ttl.TextTransparency=1
        msg.TextTransparency=1; pTrack.BackgroundTransparency=1; pFill.BackgroundTransparency=1
        xBtn.BackgroundTransparency=1; xIco.ImageTransparency=1

        tw(card,{Position=UDim2.new(0,0,1,0)},TI_CIRC); task.wait(0.08)
        local TI_IN=TI(.22,Enum.EasingStyle.Exponential)
        for _,el in ipairs({bgFill,accentBar,sideGlow,iconRing}) do tw(el,{BackgroundTransparency=0},TI_IN) end
        tw(iconRingStroke,{Transparency=0.35},TI_IN); tw(iconImg,{ImageTransparency=0},TI_IN)
        tw(typeBadge,{BackgroundTransparency=0},TI_IN); tw(typeL,{TextTransparency=0},TI_IN)
        tw(ttl,{TextTransparency=0},TI_IN); tw(msg,{TextTransparency=0},TI_IN)
        tw(pTrack,{BackgroundTransparency=0.55},TI_IN); tw(pFill,{BackgroundTransparency=0},TI_IN)
        tw(cardStroke,{Transparency=0.55},TI_IN); tw(xBtn,{BackgroundTransparency=0},TI_IN); tw(xIco,{ImageTransparency=0},TI_IN)
        tw(pFill,{Size=UDim2.new(0,0,1,0)},TI(data.Duration,Enum.EasingStyle.Linear))

        local paused,dismissed,elapsed=false,false,0
        card.MouseEnter:Connect(function() paused=true;  tw(card,{BackgroundColor3=T.BG2},TI_FAST) end)
        card.MouseLeave:Connect(function() paused=false; tw(card,{BackgroundColor3=T.BG1},TI_FAST) end)
        xCL.MouseButton1Click:Connect(function() dismissed=true end)
        repeat task.wait(0.05); if not paused then elapsed=elapsed+0.05 end
        until dismissed or elapsed>=data.Duration

        local TI_OUT=TI(.18,Enum.EasingStyle.Quad)
        for _,el in ipairs({bgFill,accentBar,sideGlow,iconRing,typeBadge,pTrack,pFill,xBtn}) do tw(el,{BackgroundTransparency=1},TI_OUT) end
        tw(iconRingStroke,{Transparency=1},TI_OUT); tw(iconImg,{ImageTransparency=1},TI_OUT)
        tw(typeL,{TextTransparency=1},TI_OUT); tw(ttl,{TextTransparency=1},TI_OUT)
        tw(msg,{TextTransparency=1},TI_OUT); tw(cardStroke,{Transparency=1},TI_OUT); tw(xIco,{ImageTransparency=1},TI_OUT)
        tw(card,{BackgroundColor3=T.BG1,Position=UDim2.new(-1.1,0,1,0)},TI(.22,Enum.EasingStyle.Quad,Enum.EasingDirection.In))
        task.wait(0.24)
        tw(card,{Size=UDim2.new(0,300,0,0)},TI_MED,function() card:Destroy() end)
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
    local WH = math.clamp(vp.Y-80,440,550)
    local FULL = UDim2.fromOffset(WW,WH)
    local TB_H = 46
    local MINI = UDim2.fromOffset(WW,TB_H+2)

    -- ── ScreenGui ─────────────────────────────────────────────────────────────
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
        local splashConns={}; local alive=true
        local splash=Instance.new("Frame"); splash.Name="Splash"; splash.Size=UDim2.new(1,0,1,0)
        splash.BackgroundColor3=H("#080c10"); splash.BackgroundTransparency=1
        splash.BorderSizePixel=0; splash.ZIndex=1000; splash.ClipsDescendants=true; splash.Parent=gui

        local cLines={}
        local function MkCorner(ax,ay,rx,ry)
            local r=Instance.new("Frame"); r.Size=UDim2.new(0,36,0,36)
            r.Position=UDim2.new(ax,rx,ay,ry); r.AnchorPoint=Vector2.new(ax,ay)
            r.BackgroundTransparency=1; r.ZIndex=1002; r.Parent=splash
            local h2=Instance.new("Frame"); h2.Size=UDim2.new(1,0,0,1)
            h2.Position=ay==0 and UDim2.new(0,0,0,0) or UDim2.new(0,0,1,-1)
            h2.BackgroundColor3=T.Accent; h2.BackgroundTransparency=1; h2.BorderSizePixel=0; h2.ZIndex=1003; h2.Parent=r
            local v=Instance.new("Frame"); v.Size=UDim2.new(0,1,1,0)
            v.Position=ax==0 and UDim2.new(0,0,0,0) or UDim2.new(1,-1,0,0)
            v.BackgroundColor3=T.Accent; v.BackgroundTransparency=1; v.BorderSizePixel=0; v.ZIndex=1003; v.Parent=r
            table.insert(cLines,h2); table.insert(cLines,v)
        end
        MkCorner(0,0,24,24); MkCorner(1,0,-24,24); MkCorner(0,1,24,-24); MkCorner(1,1,-24,-24)

        local glow=Instance.new("Frame"); glow.Size=UDim2.new(0,540,0,270)
        glow.Position=UDim2.new(0.5,0,0.5,0); glow.AnchorPoint=Vector2.new(0.5,0.5)
        glow.BackgroundColor3=T.Accent; glow.BackgroundTransparency=1; glow.BorderSizePixel=0; glow.ZIndex=1001; glow.Parent=splash
        Instance.new("UICorner",glow).CornerRadius=UDim.new(1,0)
        local gg=Instance.new("UIGradient")
        gg.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.74),NumberSequenceKeypoint.new(1,1)}; gg.Parent=glow

        local scan=Instance.new("Frame"); scan.Size=UDim2.new(0,2,1,0)
        scan.Position=UDim2.new(-0.02,0,0,0); scan.BackgroundColor3=T.Accent
        scan.BackgroundTransparency=0.5; scan.BorderSizePixel=0; scan.ZIndex=1020; scan.Parent=splash
        local sg2=Instance.new("UIGradient")
        sg2.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.38,0.35),NumberSequenceKeypoint.new(0.62,0.35),NumberSequenceKeypoint.new(1,1)}
        sg2.Rotation=90; sg2.Parent=scan

        local lw=Instance.new("Frame"); lw.Name="LW"; lw.Size=UDim2.new(0,48,0,48)
        lw.Position=UDim2.new(0.5,0,0.44,0); lw.AnchorPoint=Vector2.new(0.5,0.5)
        lw.BackgroundTransparency=1; lw.ZIndex=1004; lw.Parent=splash

        local lglow=Instance.new("Frame"); lglow.Size=UDim2.new(2,0,2,0)
        lglow.Position=UDim2.new(0.5,0,0.5,0); lglow.AnchorPoint=Vector2.new(0.5,0.5)
        lglow.BackgroundColor3=T.Accent; lglow.BackgroundTransparency=1; lglow.BorderSizePixel=0; lglow.ZIndex=1003; lglow.Parent=lw
        Instance.new("UICorner",lglow).CornerRadius=UDim.new(1,0)
        local lgg=Instance.new("UIGradient")
        lgg.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.78),NumberSequenceKeypoint.new(1,1)}; lgg.Parent=lglow

        local ro=Instance.new("Frame"); ro.Size=UDim2.new(1,28,1,28)
        ro.Position=UDim2.new(0.5,0,0.5,0); ro.AnchorPoint=Vector2.new(0.5,0.5)
        ro.BackgroundTransparency=1; ro.BorderSizePixel=0; ro.ZIndex=1005; ro.Parent=lw
        Instance.new("UICorner",ro).CornerRadius=UDim.new(1,0)
        local so=Instance.new("UIStroke"); so.Color=T.Accent; so.Thickness=1.5; so.Transparency=0.15; so.Parent=ro
        local go2=Instance.new("UIGradient")
        go2.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.3,0),NumberSequenceKeypoint.new(0.65,0.88),NumberSequenceKeypoint.new(1,0)}
        go2.Parent=so

        local ri=Instance.new("Frame"); ri.Size=UDim2.new(1,-16,1,-16)
        ri.Position=UDim2.new(0.5,0,0.5,0); ri.AnchorPoint=Vector2.new(0.5,0.5)
        ri.BackgroundTransparency=1; ri.BorderSizePixel=0; ri.ZIndex=1005; ri.Parent=lw
        Instance.new("UICorner",ri).CornerRadius=UDim.new(1,0)
        local si=Instance.new("UIStroke"); si.Color=H("#4580C9"); si.Thickness=1; si.Transparency=0.45; si.Parent=ri
        local gi=Instance.new("UIGradient")
        gi.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.85),NumberSequenceKeypoint.new(0.28,0),NumberSequenceKeypoint.new(0.72,0),NumberSequenceKeypoint.new(1,0.85)}
        gi.Parent=si

        local limg=Instance.new("ImageLabel"); limg.Size=UDim2.new(1,0,1,0)
        limg.BackgroundTransparency=1; limg.Image=LOGO; limg.ImageTransparency=1
        limg.ScaleType=Enum.ScaleType.Fit; limg.ZIndex=1006; limg.Parent=lw
        Instance.new("UICorner",limg).CornerRadius=UDim.new(0,10)

        local tw2f=Instance.new("Frame"); tw2f.Size=UDim2.new(0,420,0,0)
        tw2f.Position=UDim2.new(0.5,0,0.44,110); tw2f.AnchorPoint=Vector2.new(0.5,0)
        tw2f.BackgroundTransparency=1; tw2f.AutomaticSize=Enum.AutomaticSize.Y; tw2f.ZIndex=1004; tw2f.Parent=splash

        local tRow=Instance.new("Frame"); tRow.Size=UDim2.new(1,0,0,0)
        tRow.BackgroundTransparency=1; tRow.AutomaticSize=Enum.AutomaticSize.XY; tRow.ZIndex=1005; tRow.Parent=tw2f
        local trl=Instance.new("UIListLayout"); trl.FillDirection=Enum.FillDirection.Horizontal
        trl.HorizontalAlignment=Enum.HorizontalAlignment.Center; trl.VerticalAlignment=Enum.VerticalAlignment.Center
        trl.Padding=UDim.new(0,0); trl.SortOrder=Enum.SortOrder.LayoutOrder; trl.Parent=tRow

        local CHARS={"S","E","N","T","E","N","C","E"}; local charLbls={}
        for i,ch in ipairs(CHARS) do
            local l=Instance.new("TextLabel"); l.Text=ch; l.Size=UDim2.new(0,0,0,0); l.AutomaticSize=Enum.AutomaticSize.XY
            l.Font=Enum.Font.GothamBold; l.TextSize=48; l.TextColor3=T.TextHi
            l.TextTransparency=1; l.BackgroundTransparency=1; l.BorderSizePixel=0
            l.ZIndex=1006; l.LayoutOrder=i; l.RichText=false; l.Parent=tRow; charLbls[i]=l
        end
        local sp2=Instance.new("Frame"); sp2.Size=UDim2.new(0,14,0,1); sp2.BackgroundTransparency=1; sp2.BorderSizePixel=0; sp2.LayoutOrder=9; sp2.Parent=tRow
        local hub=Instance.new("TextLabel"); hub.Text="HUB"; hub.Size=UDim2.new(0,0,0,0); hub.AutomaticSize=Enum.AutomaticSize.XY
        hub.Font=Enum.Font.GothamBold; hub.TextSize=48; hub.TextColor3=T.Accent
        hub.TextTransparency=1; hub.BackgroundTransparency=1; hub.BorderSizePixel=0; hub.ZIndex=1006; hub.LayoutOrder=10; hub.RichText=false; hub.Parent=tRow

        local acLine=Instance.new("Frame"); acLine.Size=UDim2.new(0,0,0,2); acLine.Position=UDim2.new(0.5,0,0,56); acLine.AnchorPoint=Vector2.new(0.5,0)
        acLine.BackgroundColor3=T.Accent; acLine.BackgroundTransparency=1; acLine.BorderSizePixel=0; acLine.ZIndex=1005; acLine.Parent=tw2f
        Instance.new("UICorner",acLine).CornerRadius=UDim.new(1,0)

        local stat=Instance.new("TextLabel"); stat.Text="INITIALISING CORE"; stat.Size=UDim2.new(1,0,0,22); stat.Position=UDim2.new(0,0,0,64)
        stat.Font=Enum.Font.Code; stat.TextSize=12; stat.TextColor3=T.TextMid; stat.TextTransparency=1
        stat.BackgroundTransparency=1; stat.BorderSizePixel=0; stat.ZIndex=1005; stat.TextXAlignment=Enum.TextXAlignment.Center; stat.RichText=false; stat.Parent=tw2f

        local pw=Instance.new("Frame"); pw.Size=UDim2.new(0,260,0,3); pw.Position=UDim2.new(0.5,0,0,90); pw.AnchorPoint=Vector2.new(0.5,0)
        pw.BackgroundColor3=H("#1a1f28"); pw.BackgroundTransparency=1; pw.BorderSizePixel=0; pw.ZIndex=1005; pw.Parent=tw2f
        Instance.new("UICorner",pw).CornerRadius=UDim.new(1,0)
        local pf2=Instance.new("Frame"); pf2.Size=UDim2.new(0,0,1,0); pf2.BackgroundColor3=T.Accent; pf2.BackgroundTransparency=1; pf2.BorderSizePixel=0; pf2.ZIndex=1006; pf2.Parent=pw
        Instance.new("UICorner",pf2).CornerRadius=UDim.new(1,0)
        local pfg=Instance.new("UIGradient")
        pfg.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,H("#4580C9")),ColorSequenceKeypoint.new(0.6,H("#5A9FE8")),ColorSequenceKeypoint.new(1,H("#8BC4FF"))}; pfg.Parent=pf2

        local parts={}
        for pi=1,7 do
            local px=Instance.new("Frame"); px.Size=UDim2.new(0,math.random(2,4),0,math.random(2,4))
            px.Position=UDim2.new(math.random(15,85)/100,0,math.random(15,85)/100,0); px.AnchorPoint=Vector2.new(0.5,0.5)
            px.BackgroundColor3=T.Accent; px.BackgroundTransparency=0.55+math.random()*0.35; px.BorderSizePixel=0; px.ZIndex=1002; px.Parent=splash
            Instance.new("UICorner",px).CornerRadius=UDim.new(1,0)
            parts[pi]={f=px,bx=math.random(15,85)/100,by=math.random(15,85)/100,ph=math.random()*math.pi*2,sp=0.28+math.random()*0.38,rg=0.011+math.random()*0.017}
        end

        tw(splash,{BackgroundTransparency=0},TI(.38,Enum.EasingStyle.Quad)); task.wait(0.14)
        for _,l in ipairs(cLines) do tw(l,{BackgroundTransparency=0},TI(.48,Enum.EasingStyle.Exponential)) end; task.wait(0.16)
        tw(scan,{Position=UDim2.new(1.02,0,0,0)},TI(.85,Enum.EasingStyle.Quad)); task.wait(0.08)
        tw(glow,{BackgroundTransparency=0.76},TI(.6,Enum.EasingStyle.Quad)); task.wait(0.06)
        tw(so,{Transparency=0},TI_MED); tw(si,{Transparency=0},TI_MED)
        tw(lw,{Size=UDim2.new(0,160,0,160)},TI_SPRING)
        tw(lglow,{BackgroundTransparency=0.82},TI(.5,Enum.EasingStyle.Quad))
        tw(limg,{ImageTransparency=0},TI(.5,Enum.EasingStyle.Exponential)); task.wait(0.24)
        for i,l in ipairs(charLbls) do task.spawn(function() task.wait((i-1)*0.055); tw(l,{TextTransparency=0},TI(.28,Enum.EasingStyle.Back)) end) end; task.wait(0.38)
        tw(hub,{TextTransparency=0},TI(.32,Enum.EasingStyle.Back)); task.wait(0.14)
        tw(acLine,{Size=UDim2.new(0,280,0,2),BackgroundTransparency=0},TI(.45,Enum.EasingStyle.Exponential)); task.wait(0.1)
        tw(stat,{TextTransparency=0.3},TI_MED); tw(pw,{BackgroundTransparency=0},TI_FAST); tw(pf2,{BackgroundTransparency=0},TI_FAST)

        local rsC=RS.RenderStepped:Connect(function(dt)
            if not alive then return end
            ro.Rotation=ro.Rotation+88*dt; ri.Rotation=ri.Rotation-52*dt
            local pulse=0.82+math.sin(tick()*2.2)*0.07; lglow.BackgroundTransparency=1-(1-0.82)*pulse
            local mp=UIS:GetMouseLocation(); local vs=Cam.ViewportSize
            glow.Position=UDim2.new(0.5,(mp.X/vs.X-0.5)*38,0.5,(mp.Y/vs.Y-0.5)*18)
            for _,p in ipairs(parts) do local t2=tick()*p.sp+p.ph; p.f.Position=UDim2.new(p.bx+math.sin(t2)*p.rg,0,p.by+math.cos(t2*1.4)*p.rg,0) end
        end); table.insert(splashConns,rsC)

        local steps={{l="VERIFYING MODULES",p=0.20},{l="INJECTING SCRIPTS",p=0.42},{l="LOADING ASSETS",p=0.64},{l="BUILDING INTERFACE",p=0.86},{l="COMPLETE",p=1.0}}
        for _,s in ipairs(steps) do
            tw(stat,{TextTransparency=1},TI(.07,Enum.EasingStyle.Quad)); task.wait(0.08); stat.Text=s.l
            tw(stat,{TextTransparency=0.3},TI(.1,Enum.EasingStyle.Quad)); tw(pf2,{Size=UDim2.new(s.p,0,1,0)},TI(.36,Enum.EasingStyle.Quad))
            tw(limg,{ImageTransparency=0.22},TI(.06,Enum.EasingStyle.Quad)); task.wait(0.07); tw(limg,{ImageTransparency=0},TI(.1,Enum.EasingStyle.Quad))
            task.wait(s.p==1 and 0.3 or 0.28)
        end; task.wait(0.38)

        alive=false
        for _,c in ipairs(splashConns) do pcall(function() c:Disconnect() end) end
        for i=#charLbls,1,-1 do task.spawn(function() task.wait((#charLbls-i)*0.038); tw(charLbls[i],{TextTransparency=1},TI(.18,Enum.EasingStyle.Quad)) end) end
        tw(hub,{TextTransparency=1},TI(.18,Enum.EasingStyle.Quad))
        tw(acLine,{BackgroundTransparency=1,Size=UDim2.new(0,0,0,2)},TI(.3,Enum.EasingStyle.Exponential)); task.wait(0.14)
        tw(stat,{TextTransparency=1},TI_FAST); tw(pf2,{BackgroundTransparency=1},TI_FAST); tw(pw,{BackgroundTransparency=1},TI_FAST)
        tw(limg,{ImageTransparency=1},TI(.26,Enum.EasingStyle.Quad))
        tw(so,{Transparency=1},TI(.22,Enum.EasingStyle.Quad)); tw(si,{Transparency=1},TI(.22,Enum.EasingStyle.Quad))
        tw(lglow,{BackgroundTransparency=1},TI(.28,Enum.EasingStyle.Quad))
        for _,l in ipairs(cLines) do tw(l,{BackgroundTransparency=1},TI(.2,Enum.EasingStyle.Quad)) end
        for _,p in ipairs(parts) do tw(p.f,{BackgroundTransparency=1},TI(.18,Enum.EasingStyle.Quad)) end; task.wait(0.16)
        tw(glow,{BackgroundTransparency=1},TI(.32,Enum.EasingStyle.Quad))
        tw(splash,{BackgroundTransparency=1},TI(.42,Enum.EasingStyle.Quad),function() splash:Destroy() end)
    end)

    -- ── Notif Holder ──────────────────────────────────────────────────────────
    local notifHolder=Instance.new("Frame"); notifHolder.Name="Notifs"
    notifHolder.Size=UDim2.new(0,310,1,-16); notifHolder.Position=UDim2.new(0,10,1,-8)
    notifHolder.AnchorPoint=Vector2.new(0,1); notifHolder.BackgroundTransparency=1; notifHolder.ZIndex=200; notifHolder.Parent=gui
    local nList=List(notifHolder,6); nList.VerticalAlignment=Enum.VerticalAlignment.Bottom
    self._notifHolder=notifHolder

    -- ══════════════════════════════════════════════════════════════════════════
    -- MAIN WINDOW
    -- ══════════════════════════════════════════════════════════════════════════
    local win=Box({Name="OGSentenceWin", Sz=UDim2.fromOffset(0,0), Pos=UDim2.new(0.5,0,0.5,0), AP=Vector2.new(0.5,0.5),
        Bg=T.BG1, BgA=0, Clip=true, R=6, Border=true, BorderCol=T.Border, BorderA=0, Z=1, Par=gui})

    local topLine   = Box({Name="TopLine", Sz=UDim2.new(1,0,0,2), Pos=UDim2.new(0,0,0,0), Bg=T.Accent, BgA=0, Z=6, Par=win})
    local winGlow   = Box({Name="WinGlow", Sz=UDim2.new(0,260,0,140), Pos=UDim2.new(0,0,0,0), Bg=T.Accent, BgA=0.9, R=0, Z=0, Par=win})
    local wgG=Instance.new("UIGradient"); wgG.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.88),NumberSequenceKeypoint.new(1,1)}; wgG.Rotation=130; wgG.Parent=winGlow

    -- ── Title Bar ─────────────────────────────────────────────────────────────
    local titleBar=Box({Name="TitleBar", Sz=UDim2.new(1,0,0,TB_H), Pos=UDim2.new(0,0,0,2), Bg=T.BG1, BgA=1, Z=4, Par=win})
    Draggable(titleBar,win)

    local tbLine=Instance.new("Frame"); tbLine.Size=UDim2.new(1,0,0,1); tbLine.Position=UDim2.new(0,0,1,-1)
    tbLine.BackgroundColor3=T.Border; tbLine.BackgroundTransparency=0; tbLine.BorderSizePixel=0; tbLine.ZIndex=5; tbLine.Parent=titleBar
    local tbLineG=Instance.new("UIGradient")
    tbLineG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.Accent),ColorSequenceKeypoint.new(0.3,T.Border),ColorSequenceKeypoint.new(1,T.Border)}; tbLineG.Parent=tbLine

    -- Control buttons
    local ctrlBtns={}
    local CBTN_W=26; local CBTN_GAP=5; local CBTN_MARGIN=10
    local CTRL_DEFS={
        {key="−", ico="rbxassetid://6031094687", hoverBg=T.AccentDim, hoverCol=T.TextHi},
        {key="·", ico="rbxassetid://6031075929", hoverBg=T.BG4,       hoverCol=T.Accent},
        {key="X", ico="rbxassetid://6031094678", hoverBg=T.Error,      hoverCol=T.TextHi},
    }
    for idx,cd in ipairs(CTRL_DEFS) do
        local fromRight=CBTN_MARGIN+(3-idx)*(CBTN_W+CBTN_GAP)
        local cb=Box({Name=cd.key, Sz=UDim2.new(0,CBTN_W,0,CBTN_W), Pos=UDim2.new(1,-fromRight-CBTN_W,0.5,0), AP=Vector2.new(0,0.5), Bg=T.BG3, BgA=0, R=5, Z=5, Par=titleBar})
        local cbStroke=Instance.new("UIStroke"); cbStroke.Color=T.Border; cbStroke.Thickness=1; cbStroke.Transparency=0.45; cbStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; cbStroke.Parent=cb
        local cbIco=Img({Ico=cd.ico, Sz=UDim2.new(0,12,0,12), Col=T.TextLo, IA=0, Z=6, Par=cb})
        task.spawn(function() tw(cbIco,{ImageTransparency=0},TI_MED) end)
        local cl=Btn(cb,7)
        cb.MouseEnter:Connect(function() tw(cb,{BackgroundColor3=cd.hoverBg,BackgroundTransparency=0},TI_FAST); tw(cbIco,{ImageColor3=cd.hoverCol},TI_FAST); tw(cbStroke,{Color=cd.hoverBg,Transparency=0.4},TI_FAST) end)
        cb.MouseLeave:Connect(function() tw(cb,{BackgroundColor3=T.BG3,BackgroundTransparency=0},TI_FAST); tw(cbIco,{ImageColor3=T.TextLo},TI_FAST); tw(cbStroke,{Color=T.Border,Transparency=0.45},TI_FAST) end)
        ctrlBtns[cd.key]={frame=cb,click=cl,ico=cbIco}
    end

    local LOGO_SIZE=32; local LOGO_CENTER=25; local LOGO_GAP=10
    local logoImg=Instance.new("ImageLabel"); logoImg.Name="LogoImg"; logoImg.Size=UDim2.new(0,LOGO_SIZE,0,LOGO_SIZE)
    logoImg.Position=UDim2.new(0,LOGO_CENTER-LOGO_SIZE/2,0.5,0); logoImg.AnchorPoint=Vector2.new(0,0.5)
    logoImg.BackgroundTransparency=1; logoImg.Image=cfg.Icon~="" and ico(cfg.Icon) or LOGO
    logoImg.ScaleType=Enum.ScaleType.Fit; logoImg.ImageTransparency=1; logoImg.ZIndex=5; logoImg.Parent=titleBar
    Instance.new("UICorner",logoImg).CornerRadius=UDim.new(0,5)
    task.spawn(function() tw(logoImg,{ImageTransparency=0},TI_MED) end)

    local txtX=LOGO_CENTER+LOGO_SIZE/2+LOGO_GAP
    local nameLabel=Txt({T=cfg.Name,         Sz=UDim2.new(0,220,0,20), Pos=UDim2.new(0,txtX,0,5),  Font=Enum.Font.GothamBold, TS=16, Col=T.TextHi, Alpha=1, Z=5, Par=titleBar})
    local subText=cfg.Subtitle~="" and cfg.Subtitle or "v"..Sentence.Version
    local subLabel =Txt({T=subText,           Sz=UDim2.new(0,200,0,13), Pos=UDim2.new(0,txtX,0,26), Font=Enum.Font.Gotham,     TS=12, Col=T.TextLo, Alpha=1, Z=5, Par=titleBar})

    -- ── Sidebar ───────────────────────────────────────────────────────────────
    local SW=50
    local sidebar=Box({Name="Sidebar", Sz=UDim2.new(0,SW,1,-TB_H-2), Pos=UDim2.new(0,0,0,TB_H+2), Bg=T.BG2, BgA=0, Z=3, Par=win})
    local sbWire=Wire(sidebar,true); sbWire.Position=UDim2.new(1,-1,0,0); sbWire.BackgroundColor3=T.Border

    local tabList=Instance.new("ScrollingFrame"); tabList.Name="TabList"
    tabList.Size=UDim2.new(1,0,1,-56); tabList.Position=UDim2.new(0,0,0,14)
    tabList.BackgroundTransparency=1; tabList.BorderSizePixel=0; tabList.ScrollBarThickness=0
    tabList.AutomaticCanvasSize=Enum.AutomaticSize.Y; tabList.ZIndex=4; tabList.Parent=sidebar
    List(tabList,4,Enum.FillDirection.Vertical,Enum.HorizontalAlignment.Center); Pad(tabList,4,4,0,0)

    local avBox=Box({Sz=UDim2.new(0,34,0,34), Pos=UDim2.new(0.5,0,1,-12), AP=Vector2.new(0.5,1), Bg=T.BG2, R=5, Z=4, Par=sidebar})
    local avImg=Instance.new("ImageLabel"); avImg.Size=UDim2.new(1,0,1,0); avImg.BackgroundTransparency=1; avImg.ZIndex=5; avImg.Parent=avBox
    Instance.new("UICorner",avImg).CornerRadius=UDim.new(0,5)
    local avS=Instance.new("UIStroke"); avS.Color=T.Accent; avS.Thickness=1.5; avS.Transparency=0.5; avS.Parent=avImg
    pcall(function() avImg.Image=Plrs:GetUserThumbnailAsync(LP.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size48x48) end)

    local tooltip=Box({Name="TT", Sz=UDim2.new(0,0,0,28), Pos=UDim2.new(0,SW+6,0,0), Bg=T.BG3, R=5, Border=true, BorderCol=T.Border, BorderA=0, Z=20, Vis=false, Par=win})
    tooltip.AutomaticSize=Enum.AutomaticSize.X; Pad(tooltip,0,0,10,10)
    local ttL=Txt({T="", Sz=UDim2.new(0,0,1,0), Font=Enum.Font.GothamSemibold, TS=14, Col=T.TextHi, Z=21, Par=tooltip})
    ttL.AutomaticSize=Enum.AutomaticSize.X
    local ttStroke=Instance.new("UIStroke"); ttStroke.Color=T.Accent; ttStroke.Thickness=1; ttStroke.Transparency=0.6; ttStroke.Parent=tooltip

    local contentArea=Box({Name="Content", Sz=UDim2.new(1,-SW-1,1,-TB_H-2), Pos=UDim2.new(0,SW+1,0,TB_H+2), Bg=T.BG1, BgA=1, Clip=true, Z=2, Par=win})

    local W={_gui=gui,_win=win,_content=contentArea,_tabs={},_activeTab=nil,_visible=true,_minimized=false,_cfg=cfg}

    local function SwitchTab(id)
        for _,tab in ipairs(W._tabs) do
            if tab.id==id then
                tab.page.Visible=true
                tw(tab.bar,{BackgroundTransparency=0},TI_FAST); tw(tab.ico,{ImageColor3=T.Accent},TI_FAST)
                tw(tab.box,{BackgroundColor3=T.AccentLo,BackgroundTransparency=0},TI_FAST)
                local s=tab.box:FindFirstChildOfClass("UIStroke"); if s then tw(s,{Color=T.Accent,Transparency=0.5},TI_FAST) end
                W._activeTab=id
            else
                tab.page.Visible=false
                tw(tab.bar,{BackgroundTransparency=1},TI_FAST); tw(tab.ico,{ImageColor3=T.TextLo},TI_FAST)
                tw(tab.box,{BackgroundColor3=T.BG3,BackgroundTransparency=1},TI_FAST)
                local s=tab.box:FindFirstChildOfClass("UIStroke"); if s then tw(s,{Color=T.Border,Transparency=0.6},TI_FAST) end
            end
        end
    end

    -- ── Loading Screen ────────────────────────────────────────────────────────
    if cfg.LoadingEnabled then
        local lf=Box({Name="Loading",Sz=UDim2.new(1,0,1,0),Bg=T.BG1,BgA=0,Z=50,Par=win})
        Instance.new("UICorner",lf).CornerRadius=UDim.new(0,6)
        local lLogo=Img({Ico=cfg.Icon,Sz=UDim2.new(0,32,0,32),Pos=UDim2.new(0.5,0,0.5,-52),AP=Vector2.new(0.5,0.5),Col=T.TextHi,Z=51,Par=lf})
        local lT=Txt({T=cfg.LoadingTitle,    Sz=UDim2.new(1,0,0,26),Pos=UDim2.new(0.5,0,0.5,-14),AP=Vector2.new(0.5,0.5),Font=Enum.Font.GothamBold,TS=24,Col=T.TextHi,AX=Enum.TextXAlignment.Center,Alpha=1,Z=51,Par=lf})
        local lS=Txt({T=cfg.LoadingSubtitle, Sz=UDim2.new(1,0,0,16),Pos=UDim2.new(0.5,0,0.5, 16),AP=Vector2.new(0.5,0.5),Font=Enum.Font.Code,TS=14,Col=T.TextMid,AX=Enum.TextXAlignment.Center,Alpha=1,Z=51,Par=lf})
        local pTrack=Box({Sz=UDim2.new(0.45,0,0,3),Pos=UDim2.new(0.5,0,0.5,44),AP=Vector2.new(0.5,0.5),Bg=T.BG3,R=2,Z=51,Par=lf})
        local pFillL=Box({Sz=UDim2.new(0,0,1,0),Bg=T.Accent,R=2,Z=52,Par=pTrack})
        local pctL=Txt({T="0%",Sz=UDim2.new(1,0,0,16),Pos=UDim2.new(0.5,0,0.5,54),AP=Vector2.new(0.5,0.5),Font=Enum.Font.Code,TS=13,Col=T.Accent,AX=Enum.TextXAlignment.Center,Z=51,Par=lf})
        tw(win,{Size=FULL},TI_SLOW); task.wait(0.3)
        tw(lT,{TextTransparency=0},TI_MED); task.wait(0.1); tw(lS,{TextTransparency=0.3},TI_MED)
        if cfg.Icon~="" then tw(lLogo,{ImageTransparency=0},TI_MED) end
        local pct=0
        for _,s in ipairs({0.12,0.08,0.15,0.1,0.18,0.12,0.1,0.15}) do
            pct=math.min(pct+s,1); tw(pFillL,{Size=UDim2.new(pct,0,1,0)},TI(.25,Enum.EasingStyle.Quad))
            pctL.Text=math.floor(pct*100).."%"; task.wait(0.13+math.random()*0.1)
        end
        pctL.Text="100%"; tw(pFillL,{Size=UDim2.new(1,0,1,0)},TI_FAST); task.wait(0.3)
        tw(pFillL,{BackgroundColor3=T.TextHi},TI_FAST); task.wait(0.08)
        tw(lT,{TextTransparency=1},TI_FAST); tw(lS,{TextTransparency=1},TI_FAST)
        tw(pctL,{TextTransparency=1},TI_FAST); tw(pTrack,{BackgroundTransparency=1},TI_FAST); tw(pFillL,{BackgroundTransparency=1},TI_FAST)
        if cfg.Icon~="" then tw(lLogo,{ImageTransparency=1},TI_FAST) end
        task.wait(0.2); tw(lf,{BackgroundTransparency=1},TI_MED,function() lf:Destroy() end); task.wait(0.3)
    else
        tw(win,{Size=FULL},TI_SLOW); task.wait(0.35)
    end

    tw(topLine,  {BackgroundTransparency=0},TI_MED)
    tw(nameLabel,{TextTransparency=0},      TI_MED)
    tw(subLabel, {TextTransparency=0},      TI_MED)

    -- ── Close / Minimize / Hide ───────────────────────────────────────────────
    local function DoClose()
        local blocker=Instance.new("Frame"); blocker.Size=UDim2.new(1,0,1,0); blocker.BackgroundTransparency=1; blocker.ZIndex=900; blocker.Parent=gui; Btn(blocker,901)
        local ov=Box({Sz=UDim2.new(1,0,1,0),Bg=T.BG0,BgA=1,Z=500,Par=win}); Instance.new("UICorner",ov).CornerRadius=UDim.new(0,6)
        local oLogo=Instance.new("ImageLabel"); oLogo.Size=UDim2.new(0,54,0,54); oLogo.Position=UDim2.new(0.5,0,0.5,-70); oLogo.AnchorPoint=Vector2.new(0.5,0.5); oLogo.BackgroundTransparency=1; oLogo.Image=LOGO; oLogo.ScaleType=Enum.ScaleType.Fit; oLogo.ImageTransparency=1; oLogo.ZIndex=501; oLogo.Parent=ov
        local oName=Txt({T=cfg.Name,    Sz=UDim2.new(1,0,0,24),Pos=UDim2.new(0.5,0,0.5,-26),AP=Vector2.new(0.5,0.5),Font=Enum.Font.GothamBold,TS=22,Col=T.TextHi,AX=Enum.TextXAlignment.Center,Alpha=1,Z=501,Par=ov})
        local oSub =Txt({T="Closing...",Sz=UDim2.new(1,0,0,16),Pos=UDim2.new(0.5,0,0.5, 4), AP=Vector2.new(0.5,0.5),Font=Enum.Font.Code,    TS=13,Col=T.TextLo, AX=Enum.TextXAlignment.Center,Alpha=1,Z=501,Par=ov})
        local cl2=Box({Sz=UDim2.new(0,200,0,2),Pos=UDim2.new(0.5,0,0.5,30),AP=Vector2.new(0.5,0.5),Bg=T.BG3,R=2,Z=501,Par=ov})
        local cf=Box({Sz=UDim2.new(0,0,1,0),Bg=T.Accent,R=2,Z=502,Par=cl2})
        local ws=win:FindFirstChildOfClass("UIStroke"); if ws then tw(ws,{Color=T.Error,Transparency=0.2},TI_MED) end
        tw(ov,{BackgroundTransparency=0},TI(.2,Enum.EasingStyle.Quad)); tw(oLogo,{ImageTransparency=0},TI_MED); tw(oName,{TextTransparency=0},TI_MED); tw(oSub,{TextTransparency=0},TI_MED); tw(cl2,{BackgroundTransparency=0},TI_FAST); tw(cf,{BackgroundTransparency=0},TI_FAST); task.wait(0.12)
        tw(cf,{Size=UDim2.new(1,0,1,0)},TI(.55,Enum.EasingStyle.Quad)); task.wait(0.28); oSub.Text="See you soon."; tw(cf,{BackgroundColor3=T.TextHi},TI_FAST); task.wait(0.22)
        tw(win,{Size=UDim2.fromOffset(WW,0),BackgroundTransparency=1},TI(.4,Enum.EasingStyle.Back,Enum.EasingDirection.In))
        if ws then tw(ws,{Transparency=1},TI(.3,Enum.EasingStyle.Quad)) end; task.wait(0.42); Sentence:Destroy()
    end

    local function DoMinimize()
        if W._minimized then
            W._minimized=false; win.ClipsDescendants=true
            tw(win,{Size=FULL},TI_SPRING,function() sidebar.Visible=true; contentArea.Visible=true; win.ClipsDescendants=true end)
        else
            W._minimized=true; sidebar.Visible=false; contentArea.Visible=false
            tw(win,{Size=UDim2.fromOffset(WW,MINI.Y.Offset+6)},TI(.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)); task.wait(0.10)
            tw(win,{Size=MINI},TI(.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out))
        end
    end

    local function HideW()
        W._visible=false
        tw(win,{Position=UDim2.new(0.5,0,1.2,0),Size=UDim2.fromOffset(WW*0.85,WH*0.85)},TI(.45,Enum.EasingStyle.Back,Enum.EasingDirection.In),function() win.Visible=false; win.Size=W._minimized and MINI or FULL end)
    end
    local function ShowW()
        win.Visible=true; W._visible=true; win.Position=UDim2.new(0.5,0,1.2,0)
        win.Size=UDim2.fromOffset(WW*0.85,(W._minimized and MINI or FULL).Y.Offset*0.85)
        tw(win,{Position=UDim2.new(0.5,0,0.5,0),Size=W._minimized and MINI or FULL},TI_SPRING)
    end

    ctrlBtns["X"].click.MouseButton1Click:Connect(DoClose)
    ctrlBtns["·"].click.MouseButton1Click:Connect(function() Sentence:Notify({Title="Hidden",Content="Press "..cfg.ToggleBind.Name.." to restore.",Type="Info"}); HideW() end)
    ctrlBtns["−"].click.MouseButton1Click:Connect(DoMinimize)
    track(UIS.InputBegan:Connect(function(inp,proc)
        if proc then return end
        if inp.KeyCode==cfg.ToggleBind then if W._visible then HideW() else ShowW() end end
    end))

    -- ══════════════════════════════════════════════════════════════════════════
    -- HOME TAB  —  full CreateSection API + built-in professional layout
    -- ══════════════════════════════════════════════════════════════════════════
    function W:CreateHomeTab(hCfg)
        hCfg = merge({Icon="home"},hCfg or {})
        local id = "Home"

        local hBox = Box({Name="HomeTB", Sz=UDim2.new(0,40,0,40), Bg=T.BG3, BgA=1, R=6,
            Border=true, BorderCol=T.Border, BorderA=0.5, Z=5, Par=tabList})
        local hBar = Box({Sz=UDim2.new(0,3,0.55,0), Pos=UDim2.new(0,0,0.225,0), Bg=T.Accent, BgA=1, R=0, Z=6, Par=hBox})
        local hIco = Img({Ico=hCfg.Icon, Sz=UDim2.new(0,18,0,18), Col=T.TextLo, Z=6, Par=hBox})
        local hCL  = Btn(hBox,7)

        local hPage = Instance.new("ScrollingFrame"); hPage.Name="HomePage"
        hPage.Size=UDim2.new(1,0,1,0); hPage.BackgroundTransparency=1; hPage.BorderSizePixel=0
        hPage.ScrollBarThickness=2; hPage.ScrollBarImageColor3=T.Border
        hPage.CanvasSize=UDim2.new(0,0,0,0); hPage.AutomaticCanvasSize=Enum.AutomaticSize.Y
        hPage.ZIndex=3; hPage.Visible=false; hPage.Parent=contentArea
        List(hPage,10); Pad(hPage,16,16,16,16)

        -- ── BUILT-IN: Player Card ─────────────────────────────────────────────
        local pCard = Box({Name="PlayerCard", Sz=UDim2.new(1,0,0,86), Bg=T.BG1, BgA=0, R=8, Z=3, Par=hPage})
        local pcStroke=Instance.new("UIStroke"); pcStroke.Color=T.Accent; pcStroke.Thickness=1; pcStroke.Transparency=0.55; pcStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; pcStroke.Parent=pCard
        local pcBg=Box({Sz=UDim2.new(1,0,1,0), Bg=T.AccentLo, BgA=0, R=8, Z=3, Par=pCard})
        local pcBgG=Instance.new("UIGradient"); pcBgG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,T.AccentLo),ColorSequenceKeypoint.new(1,T.BG1)}; pcBgG.Rotation=0; pcBgG.Parent=pcBg
        Box({Sz=UDim2.new(0,3,0.7,0), Pos=UDim2.new(0,0,0.15,0), Bg=T.Accent, R=0, Z=5, Par=pCard})
        local pAv=Instance.new("ImageLabel"); pAv.Size=UDim2.new(0,52,0,52); pAv.Position=UDim2.new(0,16,0.5,0); pAv.AnchorPoint=Vector2.new(0,0.5)
        pAv.BackgroundTransparency=1; pAv.ZIndex=6; pAv.Parent=pCard
        Instance.new("UICorner",pAv).CornerRadius=UDim.new(0,6)
        local pAS=Instance.new("UIStroke"); pAS.Color=T.Accent; pAS.Thickness=1.5; pAS.Transparency=0.4; pAS.Parent=pAv
        pcall(function() pAv.Image=Plrs:GetUserThumbnailAsync(LP.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size150x150) end)
        Txt({T=LP.DisplayName, Sz=UDim2.new(1,-100,0,22), Pos=UDim2.new(0,82,0,14), Font=Enum.Font.GothamBold, TS=19, Col=T.TextHi,  Z=6, Par=pCard})
        Txt({T="@"..LP.Name,   Sz=UDim2.new(1,-100,0,16), Pos=UDim2.new(0,82,0,38), Font=Enum.Font.Code,       TS=14, Col=T.TextMid, Z=6, Par=pCard})
        local badge=Box({Sz=UDim2.new(0,0,0,18), Pos=UDim2.new(1,-12,0,10), AP=Vector2.new(1,0), Bg=T.AccentLo, R=4, Z=6, Par=pCard})
        badge.AutomaticSize=Enum.AutomaticSize.X; Pad(badge,0,0,6,6)
        local bs=Instance.new("UIStroke"); bs.Color=T.Accent; bs.Thickness=1; bs.Transparency=0.55; bs.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; bs.Parent=badge
        Txt({T="SENTENCE HUB", Sz=UDim2.new(0,0,1,0), Font=Enum.Font.GothamBold, TS=11, Col=T.Accent, AX=Enum.TextXAlignment.Center, AutoX=true, Z=7, Par=badge})

        -- ── BUILT-IN: Server Statistics Card ─────────────────────────────────
        local sCard = Box({Name="SrvCard", Sz=UDim2.new(1,0,0,108), Bg=T.BG1, BgA=0, R=8, Z=3, Par=hPage})
        local scStroke=Instance.new("UIStroke"); scStroke.Color=T.Accent; scStroke.Thickness=1; scStroke.Transparency=0.55; scStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; scStroke.Parent=sCard
        Txt({T="SRV",        Sz=UDim2.new(0,32,0,14), Pos=UDim2.new(0,14,0,10), Font=Enum.Font.GothamBold, TS=12, Col=T.Accent,  Z=4, Par=sCard})
        Txt({T="STATISTICS", Sz=UDim2.new(1,-50,0,14), Pos=UDim2.new(0,48,0,10), Font=Enum.Font.GothamBold, TS=12, Col=T.TextLo,  Z=4, Par=sCard})
        local sSep=Instance.new("Frame"); sSep.Size=UDim2.new(1,-28,0,1); sSep.Position=UDim2.new(0,14,0,28)
        sSep.BackgroundColor3=T.Border; sSep.BackgroundTransparency=0; sSep.BorderSizePixel=0; sSep.ZIndex=3; sSep.Parent=sCard
        local statVals={}
        local statDefs={{"PLAYERS",""},{"PING",""},{"UPTIME",""},{"REGION",""}}
        for i,sd in ipairs(statDefs) do
            local col=(i-1)%2; local row=math.floor((i-1)/2)
            local cW=(WW-SW-50)/2; local x=14+col*cW; local y=34+row*36
            Txt({T=sd[1],   Sz=UDim2.new(0,130,0,13), Pos=UDim2.new(0,x,0,y),    Font=Enum.Font.GothamBold, TS=12, Col=T.TextLo, Z=4, Par=sCard})
            statVals[sd[1]]=Txt({T="—", Sz=UDim2.new(0,170,0,19), Pos=UDim2.new(0,x,0,y+14), Font=Enum.Font.Code, TS=17, Col=T.TextHi, Z=4, Par=sCard})
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

        local HomeObj = BuildSectionAPI(hPage, T.Accent)
        HomeObj.Activate = function() SwitchTab(id) end

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
        return HomeObj
    end

    -- ══════════════════════════════════════════════════════════════════════════
    -- CREATE TAB  —  uses shared BuildSectionAPI
    -- ══════════════════════════════════════════════════════════════════════════
    function W:CreateTab(tCfg)
        tCfg = merge({Name="Tab",Icon="unk",ShowTitle=true},tCfg or {})
        local Tab = {}; local id = tCfg.Name

        local tBox=Box({Name=id.."TB", Sz=UDim2.new(0,40,0,40), Bg=T.BG3, BgA=1, R=6, Border=true, BorderCol=T.Border, BorderA=0.6, Z=5, Ord=#W._tabs+1, Par=tabList})
        local tBar=Box({Sz=UDim2.new(0,3,0.55,0), Pos=UDim2.new(0,0,0.225,0), Bg=T.Accent, BgA=1, R=0, Z=6, Par=tBox})
        local tIco=Img({Ico=tCfg.Icon, Sz=UDim2.new(0,18,0,18), Col=T.TextLo, Z=6, Par=tBox})
        local tCL =Btn(tBox,7)

        local tPage=Instance.new("ScrollingFrame"); tPage.Name=id
        tPage.Size=UDim2.new(1,0,1,0); tPage.BackgroundTransparency=1; tPage.BorderSizePixel=0
        tPage.ScrollBarThickness=2; tPage.ScrollBarImageColor3=T.Border
        tPage.CanvasSize=UDim2.new(0,0,0,0); tPage.AutomaticCanvasSize=Enum.AutomaticSize.Y
        tPage.ZIndex=3; tPage.Visible=false; tPage.Parent=contentArea
        List(tPage,8); Pad(tPage,16,16,18,18)

        if tCfg.ShowTitle then
            local tRow=Box({Sz=UDim2.new(1,0,0,32), BgA=1, Z=3, Par=tPage})
            Img({Ico=tCfg.Icon, Sz=UDim2.new(0,16,0,16), Pos=UDim2.new(0,0,0.5,0), AP=Vector2.new(0,0.5), Col=T.Accent, Z=4, Par=tRow})
            Txt({T=tCfg.Name:upper(), Sz=UDim2.new(1,-24,0,18), Pos=UDim2.new(0,24,0.5,0), AP=Vector2.new(0,0.5), Font=Enum.Font.GothamBold, TS=18, Col=T.TextHi, Z=4, Par=tRow})
        end

        local secAPI = BuildSectionAPI(tPage, T.Accent)
        for k,v in pairs(secAPI) do Tab[k]=v end
        function Tab:Activate() SwitchTab(id) end

        table.insert(W._tabs,{id=id,box=tBox,page=tPage,bar=tBar,ico=tIco})
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
    if self._notifHolder and self._notifHolder.Parent then self._notifHolder.Parent:Destroy() end
    self.Flags={}; self.Options={}
end

return Sentence

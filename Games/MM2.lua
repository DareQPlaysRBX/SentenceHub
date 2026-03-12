-- ════════════════════════════════════════════════════════════
-- SENTENCE Hub  -  Murder Mystery 2  v3.0
-- Autor: DareQPlaysRBX
-- ════════════════════════════════════════════════════════════

local Lib    = _G.Lib    or error("[ SENTENCE ] Lib not found in _G")
local Window = _G.Window or error("[ SENTENCE ] Window not found in _G")

-- ════════════════════════════════════════════════════════════
-- SERVICES
-- ════════════════════════════════════════════════════════════
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local TweenService    = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")
local UIS             = game:GetService("UserInputService")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Icons = loadstring(game:HttpGet('https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua'))()

-- ════════════════════════════════════════════════════════════
-- NOTIFY HELPER
-- ════════════════════════════════════════════════════════════
local function Notify(title, content, ntype, duration)
    Lib:Notify({
        Title    = title    or "SentenceHub: MM2",
        Content  = content  or "",
        Type     = ntype    or "Info",
        Duration = duration or 3,
    })
end

-- ════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════
local State = {
    shootOffset    = 1.5,
    killAuraRadius = 7,
    flySpeed       = 60,
    walkSpeed      = 16,
    jumpPower      = 50,
    playerData     = {},
}

local Conn  = {}
local Loops = {}

local function stopLoop(key)
    local v = Loops[key]
    if not v then return end
    if typeof(v) == "RBXScriptConnection" then v:Disconnect() end
    Loops[key] = nil
end

-- ════════════════════════════════════════════════════════════
-- CORE HELPERS
-- ════════════════════════════════════════════════════════════
local function getChar()
    local c = LP.Character
    if not c then return nil, nil, nil end
    return c, c:FindFirstChildOfClass("Humanoid"), c:FindFirstChild("HumanoidRootPart")
end

-- ════════════════════════════════════════════════════════════
-- NOCLIP  (defined early — used by Coin Farm before toggleable loops)
-- ════════════════════════════════════════════════════════════
local function startNoClip()
    if Loops.noClip then return end
    Loops.noClip = RunService.Stepped:Connect(function()
        local c = LP.Character
        if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end
local function stopNoClip()
    stopLoop("noClip")
    local c = LP.Character
    if c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide = true end) end
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- MAP DETECTION
-- ════════════════════════════════════════════════════════════
local MM2_MAPS = {
    Bank2            = true,
    Biolab           = true,
    Factory          = true,
    Hospital3        = true,
    Hotel2           = true,
    House2           = true,
    Mansion2         = true,
    MilBase          = true,
    Office3          = true,
    PoliceStation    = true,
    ResearchFacility = true,
    Workplace        = true,
}

-- Returns the active MM2 map object, or nil if in lobby / unrecognised map
local function getMap()
    for _, obj in ipairs(workspace:GetChildren()) do
        if MM2_MAPS[obj.Name] and obj:FindFirstChild("Spawns") then
            return obj
        end
    end
end

-- True while a known MM2 map is loaded (player is not in lobby)
local function isInGame()
    return getMap() ~= nil
end

-- ════════════════════════════════════════════════════════════
-- COIN FARM  (teleport to each coin — map-validated — noclip)
-- ════════════════════════════════════════════════════════════
local COIN_CONTAINERS  = { "CoinContainer", "CoinAreas" }
local COIN_SPEED       = 28   -- studs/s — prędkość tweena (wygląda jak chód)
local COIN_MIN_TWEEN   = 0.15 -- minimalny czas tweena nawet dla bliskich coinów
local COIN_COOLDOWN    = 1.5  -- sekund pauzy po zebraniu coina
local coinFarmEnabled  = false
local coinTween        = nil

local function cancelCoinTween()
    if coinTween then coinTween:Cancel(); coinTween = nil end
end

local function getAllCoins(mapObj)
    local coins = {}
    for _, containerName in ipairs(COIN_CONTAINERS) do
        local container = mapObj:FindFirstChild(containerName, true)
        if container then
            for _, desc in ipairs(container:GetDescendants()) do
                if desc:IsA("BasePart") and desc.Name == "Coin_Server" and desc.Parent then
                    table.insert(coins, desc)
                end
            end
        end
    end
    return coins
end

local function startCoinFarm()
    if Loops.coinFarm then return end
    coinFarmEnabled = true
    Loops.coinFarm  = true

    task.spawn(function()
        while coinFarmEnabled do

            -- Czekaj na mapę jeśli w lobby
            if not isInGame() then
                Notify("Coin Farm", "W lobby — czekam na rundę...", "Info", 4)
                repeat task.wait(1) until isInGame() or not coinFarmEnabled
                if not coinFarmEnabled then break end
            end

            local map = getMap()
            Notify("Coin Farm", "Mapa: " .. map.Name .. " — zbieram coiny.", "Success", 4)
            startNoClip()

            -- Pobierz listę wszystkich coinów na starcie rundy
            local coins = getAllCoins(map)
            local index = 1

            while coinFarmEnabled do

                -- Sprawdź czy runda nadal trwa
                if not getMap() then
                    cancelCoinTween()
                    stopNoClip()
                    Notify("Coin Farm", "Runda zakończona — pauza.", "Info", 4)
                    break
                end

                -- Pomiń coiny które już zniknęły
                while index <= #coins and (not coins[index] or not coins[index].Parent) do
                    index = index + 1
                end

                -- Lista wyczerpana — odśwież
                if index > #coins then
                    local fresh = getAllCoins(map)
                    if #fresh == 0 then
                        task.wait(1)
                        continue
                    end
                    coins = fresh
                    index = 1
                    continue
                end

                local coin = coins[index]
                index = index + 1

                if not coin or not coin.Parent then continue end

                local _, _, root = getChar()
                if not root then task.wait(0.3); continue end

                -- Oblicz czas tweena na podstawie dystansu
                local dist     = (Vector3.new(coin.Position.X, root.Position.Y, coin.Position.Z) - root.Position).Magnitude
                local duration = math.max(dist / COIN_SPEED, COIN_MIN_TWEEN)
                local targetCF = CFrame.new(coin.Position.X, root.Position.Y, coin.Position.Z)

                -- Tween walk do coina
                cancelCoinTween()
                local ti = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                coinTween = TweenService:Create(root, ti, { CFrame = targetCF })
                coinTween:Play()
                coinTween.Completed:Wait()
                coinTween = nil

                if not coinFarmEnabled then break end

                -- Zbierz przez touch event
                local _, _, root2 = getChar()
                if root2 and coin.Parent then
                    pcall(function()
                        firetouchinterest(root2, coin, 0)
                        task.wait(0.04)
                        firetouchinterest(root2, coin, 1)
                    end)
                end

                -- Cooldown przed następnym coiniem
                task.wait(COIN_COOLDOWN)
            end
        end
    end)

    Notify("Coin Farm", "Uruchomiona.", "Success")
end

local function stopCoinFarm()
    coinFarmEnabled = false
    Loops.coinFarm  = false
    cancelCoinTween()
    stopNoClip()
    Notify("Coin Farm", "Zatrzymana.", "Info")
end

-- ════════════════════════════════════════════════════════════
-- ROLE DETECTION
-- ════════════════════════════════════════════════════════════
local function FindMurderer()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Backpack:FindFirstChild("Knife") then return p end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("Knife") then return p end
    end
    for name, data in pairs(State.playerData) do
        if data.Role == "Murderer" then return Players:FindFirstChild(name) end
    end
end

local function FindSheriff()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Backpack:FindFirstChild("Gun") then return p end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("Gun") then return p end
    end
    for name, data in pairs(State.playerData) do
        if data.Role == "Sheriff" then return Players:FindFirstChild(name) end
    end
end

local function FindSheriffNotMe()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            if p.Backpack:FindFirstChild("Gun") then return p end
            if p.Character and p.Character:FindFirstChild("Gun") then return p end
        end
    end
end

local function FindNearest()
    local _, _, root = getChar()
    if not root then return end
    local best, minD = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - root.Position).Magnitude
                if d < minD then minD = d; best = p end
            end
        end
    end
    return best
end

-- ════════════════════════════════════════════════════════════
-- PREDICTION
-- ════════════════════════════════════════════════════════════
local function GetPredicted(target, offset)
    offset = offset or State.shootOffset
    local c = target.Character
    if not c then return Vector3.zero end
    local torso = c:FindFirstChild("UpperTorso") or c:FindFirstChild("HumanoidRootPart")
    local hum   = c:FindFirstChildOfClass("Humanoid")
    if not torso or not hum then return Vector3.zero end

    -- One-way latency: round-trip ping / 2
    local latency = math.clamp(LP:GetNetworkPing() / 2, 0, 0.5)
    local vel     = torso.AssemblyLinearVelocity * Vector3.new(1, 0.4, 1)

    -- Dynamic aim prediction:
    -- Measures horizontal speed (ignoring vertical/jumping),
    -- then scales the manual offset proportionally to movement.
    -- Standing still  → multiplier ≈ 0 (no extra lead)
    -- Walking (16 st/s) → multiplier ≈ 1.0 (full manual offset)
    -- Sprinting/flung  → clamped at 2.0 (avoids overshooting)
    local horizSpeed  = Vector3.new(vel.X, 0, vel.Z).Magnitude
    local walkRef     = math.max(hum.WalkSpeed, 1)
    local dynMult     = math.clamp(horizSpeed / walkRef, 0, 2.0)

    return torso.Position
        + vel * latency                            -- physics ping compensation
        + hum.MoveDirection * (offset * 0.12 * dynMult) -- dynamic offset
end

-- ════════════════════════════════════════════════════════════
-- EQUIP TOOL  (waits until knife/gun appears in character)
-- ════════════════════════════════════════════════════════════
local function equipTool(name)
    local char, hum = getChar()
    if not char then return false end
    if char:FindFirstChild(name) then return true end
    local tool = LP.Backpack:FindFirstChild(name)
    if hum and tool then
        hum:EquipTool(tool)
        local deadline = tick() + 1
        repeat task.wait() until char:FindFirstChild(name) or tick() > deadline
        return char:FindFirstChild(name) ~= nil
    end
    return false
end

-- ════════════════════════════════════════════════════════════
-- WALLCHECK HELPER
-- ════════════════════════════════════════════════════════════
local function hasLineOfSight(originPos, target)
    local tHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LP.Character}
    local hit = workspace:Raycast(originPos, (tHRP.Position - originPos).Unit * 200, params)
    return not hit or hit.Instance:IsDescendantOf(target.Character)
end

-- ════════════════════════════════════════════════════════════
-- COMBAT FUNCTIONS
-- ════════════════════════════════════════════════════════════

local shootBind     = Enum.KeyCode.E
local shootBindName = "E"

local function ShootAt(target)
    if FindSheriff() ~= LP then Notify("MM2", "You are not the Sheriff.", "Warning") return end
    if not target then Notify("MM2", "No target detected.", "Warning") return end
    local _, _, root = getChar()
    if not root then return end
    -- Wallcheck on manual shoot
    if not hasLineOfSight(root.Position, target) then
        Notify("MM2", "Target behind wall — shot blocked.", "Warning", 2) return
    end
    if not equipTool("Gun") then Notify("MM2", "Gun not found in backpack.", "Error") return end
    local char = LP.Character
    local tHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end
    local rightHand = char:FindFirstChild("RightHand")
    local origin    = CFrame.new(rightHand and rightHand.Position or root.Position)
    local aimPos    = CFrame.new(GetPredicted(target))
    pcall(function() char:WaitForChild("Gun"):WaitForChild("Shoot"):FireServer(origin, aimPos) end)
end

local function ShootAtInstant(target)
    if FindSheriff() ~= LP then Notify("MM2", "You are not the Sheriff.", "Warning") return end
    if not target then Notify("MM2", "No target detected.", "Warning") return end
    if not equipTool("Gun") then Notify("MM2", "Gun not found in backpack.", "Error") return end
    local char = LP.Character
    local tHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end
    char:PivotTo(tHRP.CFrame * CFrame.new(0, 0, 3))
    task.wait(0.06)
    tHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end
    local rightHand = char:FindFirstChild("RightHand")
    local origin    = CFrame.new(rightHand and rightHand.Position or char.HumanoidRootPart.Position)
    pcall(function() char:WaitForChild("Gun"):WaitForChild("Shoot"):FireServer(origin, CFrame.new(tHRP.Position)) end)
    Notify("MM2", "Instant shot fired at " .. target.Name .. ".", "Success", 2)
end

-- Global keybind: Shoot Murderer
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == shootBind then
        ShootAt(FindMurderer())
    end
end)

-- KnifeThrow kept for AutoKnife loop (not exposed as button)
local function KnifeThrow(silent)
    if FindMurderer() ~= LP then
        if not silent then Notify("MM2", "You are not the Murderer.", "Warning") end
        return
    end
    if not equipTool("Knife") then
        if not silent then Notify("MM2", "Knife not found in backpack.", "Error") end
        return
    end
    local nearest = FindNearest()
    if not nearest or not nearest.Character then
        if not silent then Notify("MM2", "No players in range.", "Warning") end
        return
    end
    local tHRP = nearest.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end
    local char  = LP.Character
    local knife = char:FindFirstChild("Knife")
    if not knife then return end
    local rightHand = char:FindFirstChild("RightHand")
    pcall(function()
        knife:WaitForChild("Events"):WaitForChild("KnifeThrown"):FireServer(
            CFrame.new(rightHand and rightHand.Position or char.HumanoidRootPart.Position),
            CFrame.new(GetPredicted(nearest, State.shootOffset + 1))
        )
    end)
end

local function KillNearest()
    if FindMurderer() ~= LP then Notify("MM2", "You are not the Murderer.", "Warning") return end
    if not equipTool("Knife") then Notify("MM2", "Knife not found.", "Error") return end
    local nearest = FindNearest()
    if not nearest or not nearest.Character then Notify("MM2", "No players nearby.", "Warning") return end
    local char, _, root = getChar()
    local tHRP = nearest.Character:FindFirstChild("HumanoidRootPart")
    if not root or not tHRP then return end
    local knife = char:FindFirstChild("Knife")
    if not knife then Notify("MM2", "Knife not equipped.", "Error") return end
    tHRP.Anchored = true
    tHRP.CFrame   = root.CFrame + root.CFrame.LookVector * 2
    task.wait(0.05)
    pcall(function() knife.Stab:FireServer("Slash") end)
    task.delay(0.3, function() pcall(function() tHRP.Anchored = false end) end)
end

local function KillAll()
    if FindMurderer() ~= LP then Notify("MM2", "You are not the Murderer.", "Warning") return end
    if not equipTool("Knife") then Notify("MM2", "Knife not found.", "Error") return end
    local char, _, root = getChar()
    if not root then return end
    local knife = char:FindFirstChild("Knife")
    if not knife then Notify("MM2", "Knife not equipped.", "Error") return end

    local anchored = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- wyłącz kolizję ze wszystkimi częściami ofiary
                for _, part in ipairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        pcall(function() part.CanCollide = false end)
                    end
                end
                hrp.Anchored = true
                hrp.CFrame   = root.CFrame + root.CFrame.LookVector * 1.5
                table.insert(anchored, { hrp = hrp, char = p.Character })
            end
        end
    end

    task.wait(0.05)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                pcall(function() knife.Stab:FireServer("Slash") end)
                pcall(function()
                    workspace[LP.Name].Knife.Events.KnifeStabbed:FireServer()
                end)
            end
        end
    end

    task.delay(0.5, function()
        for _, data in ipairs(anchored) do
            pcall(function() data.hrp.Anchored = false end)
            -- przywróć kolizję
            if data.char and data.char.Parent then
                for _, part in ipairs(data.char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        pcall(function() part.CanCollide = true end)
                    end
                end
            end
        end
    end)

    Notify("MM2", "All players attacked.", "Success")
end

-- ════════════════════════════════════════════════════════════
-- FLING  (SkidFling — ported from YARHM)
-- ════════════════════════════════════════════════════════════
local function Fling(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then
        Notify("MM2", "Invalid target.", "Warning") return
    end
    local lChar, lHum, lHRP = getChar()
    if not lChar or not lHum or not lHRP then return end

    local tChar     = targetPlayer.Character
    local THum      = tChar:FindFirstChildOfClass("Humanoid")
    local TRootPart = THum and THum.RootPart
    local THead     = tChar:FindFirstChild("Head")
    local Acc       = tChar:FindFirstChildOfClass("Accessory")
    local Handle    = Acc and Acc:FindFirstChild("Handle")

    if not tChar:FindFirstChildWhichIsA("BasePart") then
        Notify("MM2", "No valid parts on target.", "Warning") return
    end

    -- Zapisz pozycję powrotu i FPDH
    local savedFPDH = workspace.FallenPartsDestroyHeight
    if lHRP.Velocity.Magnitude < 50 then
        getgenv().OldPos = lHRP.CFrame
    end

    if THead            then workspace.CurrentCamera.CameraSubject = THead
    elseif Handle       then workspace.CurrentCamera.CameraSubject = Handle
    elseif THum         then workspace.CurrentCamera.CameraSubject = THum end

    local FPos = function(BasePart, Pos, Ang)
        lHRP.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
        lChar:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
        lHRP.Velocity    = Vector3.new(9e7, 9e7 * 10, 9e7)
        lHRP.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end

    local SFBasePart = function(BasePart)
        local Time  = tick()
        local Angle = 0
        repeat
            if lHRP and THum then
                if BasePart.Velocity.Magnitude < 50 then
                    Angle = Angle + 100
                    FPos(BasePart, CFrame.new(0, 1.5, 0)    + THum.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0)) task.wait()
                    FPos(BasePart, CFrame.new(0,-1.5, 0)    + THum.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0)) task.wait()
                    FPos(BasePart, CFrame.new(2.25, 1.5,-2.25) + THum.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0)) task.wait()
                    FPos(BasePart, CFrame.new(-2.25,-1.5, 2.25) + THum.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0)) task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THum.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0)) task.wait()
                    FPos(BasePart, CFrame.new(0,-1.5, 0) + THum.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0)) task.wait()
                else
                    FPos(BasePart, CFrame.new(0, 1.5,  THum.WalkSpeed),                     CFrame.Angles(math.rad(90), 0, 0)) task.wait()
                    FPos(BasePart, CFrame.new(0,-1.5, -THum.WalkSpeed),                     CFrame.Angles(0, 0, 0))            task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5,  THum.WalkSpeed),                     CFrame.Angles(math.rad(90), 0, 0)) task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5,  TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0)) task.wait()
                    FPos(BasePart, CFrame.new(0,-1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))            task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5,  TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0)) task.wait()
                    FPos(BasePart, CFrame.new(0,-1.5, 0), CFrame.Angles(math.rad(90),  0, 0)) task.wait()
                    FPos(BasePart, CFrame.new(0,-1.5, 0), CFrame.Angles(0, 0, 0))             task.wait()
                    FPos(BasePart, CFrame.new(0,-1.5, 0), CFrame.Angles(math.rad(-90), 0, 0)) task.wait()
                    FPos(BasePart, CFrame.new(0,-1.5, 0), CFrame.Angles(0, 0, 0))             task.wait()
                end
            else break end
        until BasePart.Velocity.Magnitude > 500
            or BasePart.Parent ~= tChar
            or targetPlayer.Parent ~= Players
            or targetPlayer.Character ~= tChar
            or THum.Sit
            or lHum.Health <= 0
            or tick() > Time + 2
    end

    workspace.FallenPartsDestroyHeight = 0/0

    local BV = Instance.new("BodyVelocity")
    BV.Name     = "FlingVel"
    BV.Parent   = lHRP
    BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
    BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
    lHum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    if TRootPart and THead then
        if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then
            SFBasePart(THead)
        else
            SFBasePart(TRootPart)
        end
    elseif TRootPart then
        SFBasePart(TRootPart)   -- POPRAWKA: oryginał błędnie używał THead tutaj
    elseif THead then
        SFBasePart(THead)
    elseif Handle then
        SFBasePart(Handle)
    else
        Notify("MM2", "Can't find target parts to fling.", "Warning")
    end

    BV:Destroy()
    lHum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    workspace.CurrentCamera.CameraSubject = lHum

    repeat
        lHRP.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
        lChar:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
        lHum:ChangeState("GettingUp")
        for _, x in ipairs(lChar:GetChildren()) do
            if x:IsA("BasePart") then
                x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
            end
        end
        task.wait()
    until (lHRP.Position - getgenv().OldPos.p).Magnitude < 25

    -- Przywróć zapisany FPDH zamiast polegać na getgenv().FPDH
    workspace.FallenPartsDestroyHeight = savedFPDH

    Notify("MM2", "Fling sent to " .. targetPlayer.Name, "Success")
end

-- ════════════════════════════════════════════════════════════
-- TELEPORTS
-- ════════════════════════════════════════════════════════════
local function TeleportToMap()
    local map = getMap()
    if not map then Notify("MM2", "No active map found.", "Warning") return end
    local spawns = map:FindFirstChild("Spawns")
    if not spawns then return end
    local list = spawns:GetChildren()
    local char = LP.Character
    if char and #list > 0 then
        char:MoveTo(list[math.random(#list)].Position)
        Notify("MM2", "Teleported to spawn.", "Success")
    end
end

local function TeleportToGun()
    local map = getMap()
    if not map then Notify("MM2", "No active map found.", "Warning") return end
    local gun = map:FindFirstChild("GunDrop")
    if not gun then Notify("MM2", "No dropped gun on the map.", "Warning") return end
    local char = LP.Character
    if not char then return end
    local prevCF = char:GetPivot()
    char:PivotTo(gun:GetPivot())
    local picked = false
    local conn; conn = LP.Backpack.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and child.Name == "Gun" then
            picked = true; conn:Disconnect()
        end
    end)
    local deadline = tick() + 3
    while not picked and tick() < deadline do task.wait(0.05) end
    pcall(function() conn:Disconnect() end)
    task.wait(0.05)
    char:PivotTo(prevCF)
    if picked then Notify("MM2", "Gun picked up — returned.", "Success")
    else           Notify("MM2", "Gun not picked up (timeout).", "Warning") end
end

local function TeleportToPlayer(target)
    if not target or not target.Character then Notify("MM2", "Player unavailable.", "Warning") return end
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end
    local char = LP.Character
    if char then
        char:PivotTo(tHRP.CFrame + tHRP.CFrame.LookVector * 3)
        Notify("MM2", "Teleported to " .. target.Name .. ".", "Success")
    end
end

-- ════════════════════════════════════════════════════════════
-- BROADCAST ROLES
-- ════════════════════════════════════════════════════════════
local function SendRoles()
    local m = FindMurderer()
    local s = FindSheriff()
    local msg = string.format("🔪 Murderer: %s  |  🔫 Sheriff: %s",
        m and m.Name or "unknown", s and s.Name or "unknown")
    for _, ch in ipairs(TextChatService:WaitForChild("TextChannels"):GetChildren()) do
        if ch.Name ~= "RBXSystem" then pcall(function() ch:SendAsync(msg) end) end
    end
    Notify("MM2", "Roles broadcast to chat.", "Success")
end

-- ════════════════════════════════════════════════════════════
-- TOGGLEABLE LOOPS
-- ════════════════════════════════════════════════════════════

-- Fly
local flyBV, flyBG
local function startFly()
    if Loops.fly then return end
    local char, _, root = getChar()
    if not root then return end
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent   = root
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBG.CFrame    = root.CFrame
    flyBG.Parent    = root
    Loops.fly = RunService.Heartbeat:Connect(function()
        local c2, _, r2 = getChar()
        if not c2 or not r2 then return end
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space)     then dir = dir + Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.yAxis end
        flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * State.flySpeed or Vector3.zero
        flyBG.CFrame   = Camera.CFrame
    end)
    Notify("MM2", "Fly enabled.", "Success")
end
local function stopFly()
    stopLoop("fly")
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    Notify("MM2", "Fly disabled.", "Info")
end

-- Speed / Jump
local function applySpeed(v)
    local _, hum = getChar()
    if hum then pcall(function() hum.WalkSpeed = v end) end
    State.walkSpeed = v
end
local function applyJump(v)
    local _, hum = getChar()
    if hum then pcall(function() hum.JumpPower = v end) end
    State.jumpPower = v
end

LP.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    task.wait(0.2)
    if State.walkSpeed ~= 16 then pcall(function() hum.WalkSpeed = State.walkSpeed end) end
    if State.jumpPower ~= 50 then pcall(function() hum.JumpPower = State.jumpPower end) end
end)

-- Infinite Jump
local function startInfiniteJump()
    if Loops.infJump then return end
    Loops.infJump = UIS.JumpRequest:Connect(function()
        local _, hum = getChar()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end
local function stopInfiniteJump() stopLoop("infJump") end

-- Auto Shoot  (wallcheck always active)
local autoShootLastFire = 0
local AUTO_SHOOT_COOLDOWN = 0.35

local function startAutoShoot()
    if Loops.autoShoot then return end
    Loops.autoShoot = RunService.Heartbeat:Connect(function()
        if FindSheriff() ~= LP then return end
        local now = tick()
        if now - autoShootLastFire < AUTO_SHOOT_COOLDOWN then return end
        local target = FindMurderer() or FindSheriffNotMe()
        if not target or not target.Character then return end
        local _, _, root = getChar()
        local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
        if not root or not tHRP then return end
        -- Wallcheck (always on)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {LP.Character}
        local hit = workspace:Raycast(root.Position, (tHRP.Position - root.Position).Unit * 200, params)
        if hit and not hit.Instance:IsDescendantOf(target.Character) then return end
        autoShootLastFire = now
        ShootAt(target)
    end)
end
local function stopAutoShoot()
    stopLoop("autoShoot")
    autoShootLastFire = 0
end

-- Auto Knife  (fixed 0.3s interval — minimum, no slider)
local function startAutoKnife()
    if Loops.autoKnife then return end
    Loops.autoKnife = true
    task.spawn(function()
        while Loops.autoKnife do
            KnifeThrow(true)
            task.wait(0.3)
        end
    end)
end
local function stopAutoKnife() Loops.autoKnife = false end

-- Kill Aura  (auto-equip knife, instant kill via task.spawn)
local function startKillAura()
    if Loops.killAura then return end
    Loops.killAura = RunService.Heartbeat:Connect(function()
        if FindMurderer() ~= LP then return end
        local char, _, root = getChar()
        if not root then return end
        if not equipTool("Knife") then return end
        local knife = char:FindFirstChild("Knife")
        if not knife then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
                if tHRP and (tHRP.Position - root.Position).Magnitude <= State.killAuraRadius then
                    task.spawn(function()
                        local tChar = p.Character
                        -- wyłącz kolizję
                        for _, part in ipairs(tChar:GetDescendants()) do
                            if part:IsA("BasePart") then
                                pcall(function() part.CanCollide = false end)
                            end
                        end
                        tHRP.Anchored = true
                        tHRP.CFrame   = root.CFrame + root.CFrame.LookVector * 2
                        task.wait(0.03)
                        pcall(function() knife.Stab:FireServer("Slash") end)
                        pcall(function()
                            workspace[LP.Name].Knife.Events.KnifeStabbed:FireServer()
                        end)
                        task.delay(0.15, function()
                            pcall(function() tHRP.Anchored = false end)
                            -- przywróć kolizję
                            if tChar and tChar.Parent then
                                for _, part in ipairs(tChar:GetDescendants()) do
                                    if part:IsA("BasePart") then
                                        pcall(function() part.CanCollide = true end)
                                    end
                                end
                            end
                        end)
                    end)
                end
            end
        end
    end)
end
local function stopKillAura() stopLoop("killAura") end

-- Anti-Fling
local antiFlingLastPos = nil
local function startAntiFling()
    if Loops.antiFling then return end
    Loops.antiFling = RunService.Heartbeat:Connect(function()
        local _, _, root = getChar()
        if not root then return end
        local linMag = root.AssemblyLinearVelocity.Magnitude
        local angMag = root.AssemblyAngularVelocity.Magnitude
        if linMag > 200 or angMag > 200 then
            root.AssemblyLinearVelocity  = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            if antiFlingLastPos then root.CFrame = CFrame.new(antiFlingLastPos) end
            Notify("Anti-Fling", "Fling blocked — position restored.", "Warning", 2)
        elseif linMag < 50 then
            antiFlingLastPos = root.Position
        end
    end)
end
local function stopAntiFling() stopLoop("antiFling") end

-- Follow Player
local function startFollowPlayer(target)
    stopLoop("follow")
    if not target then return end
    Loops.follow = RunService.Heartbeat:Connect(function()
        if not target.Character then return end
        local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
        if not tHRP then return end
        local char = LP.Character
        if char then char:PivotTo(tHRP.CFrame * CFrame.new(0, 0, 3.5)) end
    end)
    Notify("MM2", "Following " .. target.Name .. ".", "Info", 2)
end
local function stopFollowPlayer()
    stopLoop("follow")
    Notify("MM2", "Follow stopped.", "Info", 2)
end

-- ════════════════════════════════════════════════════════════
-- ██████████████  ENHANCED ESP SYSTEM  ██████████████████████
-- ════════════════════════════════════════════════════════════

local ESPCfg = {
    Enabled             = false,
    Chams               = true,
    MurdFill            = Color3.fromRGB(220, 40,  40),
    MurdOutline         = Color3.fromRGB(255, 100, 100),
    SherFill            = Color3.fromRGB(40,  120, 255),
    SherOutline         = Color3.fromRGB(120, 180, 255),
    InnFill             = Color3.fromRGB(40,  200, 80),
    InnOutline          = Color3.fromRGB(100, 255, 140),
    FillTransparency    = 0.55,
    OutlineTransparency = 0.0,
    ShowNames           = true,
    ShowRole            = true,
    ShowDistance        = true,
    ShowHealthBar       = true,
    ShowHealthText      = false,
    ShowBox             = false,
    ShowTracers         = false,
    MaxDistance         = 500,
    TextSize            = 13,
    TracerOrigin        = "Bottom",
    BoxPadding          = 4,
}

local espHighlights = {}

local function removeAllHighlights()
    for _, h in pairs(espHighlights) do pcall(function() h:Destroy() end) end
    espHighlights = {}
end

local function applyESP(player)
    if not player.Character then return end
    if espHighlights[player.Name] then
        espHighlights[player.Name]:Destroy()
        espHighlights[player.Name] = nil
    end
    if not ESPCfg.Chams then return end
    local h = Instance.new("Highlight")
    h.Adornee             = player.Character
    h.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    h.FillTransparency    = ESPCfg.FillTransparency
    h.OutlineTransparency = ESPCfg.OutlineTransparency
    if FindMurderer() == player then
        h.FillColor    = ESPCfg.MurdFill
        h.OutlineColor = ESPCfg.MurdOutline
    elseif FindSheriff() == player then
        h.FillColor    = ESPCfg.SherFill
        h.OutlineColor = ESPCfg.SherOutline
    else
        h.FillColor    = ESPCfg.InnFill
        h.OutlineColor = ESPCfg.InnOutline
    end
    h.Parent = game:GetService("CoreGui")
    espHighlights[player.Name] = h
end

local function reloadHighlights()
    removeAllHighlights()
    if not ESPCfg.Chams then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then applyESP(p) end
    end
end

local espDrawings  = {}
local espCharConns = {}

local function getRole(p)
    if FindMurderer() == p then return "Murderer" end
    if FindSheriff()  == p then return "Sheriff"  end
    return "Innocent"
end

local function roleColors(p)
    local r = getRole(p)
    if r == "Murderer" then return ESPCfg.MurdFill, ESPCfg.MurdOutline end
    if r == "Sheriff"  then return ESPCfg.SherFill, ESPCfg.SherOutline end
    return ESPCfg.InnFill, ESPCfg.InnOutline
end

local function roleTag(p)
    local r = getRole(p)
    if r == "Murderer" then return "🔪 MURDERER" end
    if r == "Sheriff"  then return "🔫 SHERIFF"  end
    return "😊 INNOCENT"
end

local function W2S(pos)
    local s, vis = Camera:WorldToViewportPoint(pos)
    return Vector2.new(s.X, s.Y), s.Z > 0 and vis, s.Z
end

local function newDrawing(dtype, props)
    local ok, obj = pcall(Drawing.new, dtype)
    if not ok then return nil end
    obj.Visible = false
    for k, v in pairs(props or {}) do pcall(function() obj[k] = v end) end
    return obj
end

local function removeDrawings(name)
    local d = espDrawings[name]
    if not d then return end
    for _, obj in pairs(d) do
        if type(obj) == "table" then
            for _, line in pairs(obj) do pcall(function() line:Remove() end) end
        else
            pcall(function() obj:Remove() end)
        end
    end
    espDrawings[name] = nil
end

local function removeAllDrawings()
    for name in pairs(espDrawings) do removeDrawings(name) end
end

local function initDrawings(p)
    removeDrawings(p.Name)
    local fill, outline = roleColors(p)
    local d = {}
    d.name = newDrawing("Text", { Font = Drawing.Fonts.GothamBold, Size = ESPCfg.TextSize, Color = Color3.new(1,1,1), Outline = true, OutlineColor = Color3.new(0,0,0), Center = true })
    d.role = newDrawing("Text", { Font = Drawing.Fonts.Gotham, Size = ESPCfg.TextSize - 1, Color = fill, Outline = true, OutlineColor = Color3.new(0,0,0), Center = true })
    d.dist = newDrawing("Text", { Font = Drawing.Fonts.Gotham, Size = ESPCfg.TextSize - 2, Color = Color3.fromRGB(200,200,200), Outline = true, OutlineColor = Color3.new(0,0,0), Center = true })
    d.hpBg  = newDrawing("Line", { Thickness = 4, Color = Color3.fromRGB(30,30,30), Transparency = 0.4 })
    d.hpBar = newDrawing("Line", { Thickness = 4, Color = Color3.fromRGB(80,220,80) })
    d.hpTxt = newDrawing("Text", { Font = Drawing.Fonts.Gotham, Size = ESPCfg.TextSize - 2, Color = Color3.fromRGB(180,255,180), Outline = true, OutlineColor = Color3.new(0,0,0), Center = true })
    d.box = {}
    for i = 1, 4 do d.box[i] = newDrawing("Line", { Thickness = 1.2, Color = outline, Transparency = 0.1 }) end
    d.tracer = newDrawing("Line", { Thickness = 1, Color = fill, Transparency = 0.25 })
    espDrawings[p.Name] = d
end

local function hideAllDrawings(d)
    for _, obj in pairs(d) do
        if type(obj) == "table" then
            for _, l in pairs(obj) do pcall(function() l.Visible = false end) end
        else
            pcall(function() obj.Visible = false end)
        end
    end
end

local function updateESPFrame()
    if not ESPCfg.Enabled then return end
    local vp     = Camera.ViewportSize
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")

    local tracerFrom
    if     ESPCfg.TracerOrigin == "Center" then tracerFrom = Vector2.new(vp.X / 2, vp.Y / 2)
    elseif ESPCfg.TracerOrigin == "Mouse"  then local m = LP:GetMouse(); tracerFrom = Vector2.new(m.X, m.Y)
    else                                         tracerFrom = Vector2.new(vp.X / 2, vp.Y) end

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local d    = espDrawings[p.Name]
        if not d then continue end
        local char = p.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local head = char and char:FindFirstChild("Head")
        if not hrp or not head then hideAllDrawings(d); continue end
        local dist = myRoot and (hrp.Position - myRoot.Position).Magnitude or 0
        if dist > ESPCfg.MaxDistance then hideAllDrawings(d); continue end
        local fill, outline = roleColors(p)
        local headPos, headVis = W2S(head.Position + Vector3.new(0, 0.7, 0))
        local footPos, footVis = W2S(hrp.Position  - Vector3.new(0, 3.0, 0))
        if not headVis and not footVis then hideAllDrawings(d); continue end
        local boxH     = math.abs(headPos.Y - footPos.Y)
        local boxW     = boxH * 0.5
        local pad      = ESPCfg.BoxPadding
        local topLeft  = Vector2.new(headPos.X - boxW/2 - pad, headPos.Y - pad)
        local botRight = Vector2.new(footPos.X + boxW/2 + pad, footPos.Y + pad)
        local topRight = Vector2.new(botRight.X, topLeft.Y)
        local botLeft  = Vector2.new(topLeft.X,  botRight.Y)

        d.name.Visible = ESPCfg.ShowNames;  d.name.Text = p.Name; d.name.Color = Color3.new(1,1,1); d.name.Size = ESPCfg.TextSize; d.name.Position = Vector2.new(headPos.X, topLeft.Y - ESPCfg.TextSize - 2)
        d.role.Visible = ESPCfg.ShowRole;   d.role.Text = roleTag(p); d.role.Color = fill; d.role.Size = ESPCfg.TextSize - 1; d.role.Position = Vector2.new(headPos.X, topLeft.Y - ESPCfg.TextSize * 2 - 4)
        d.dist.Visible = ESPCfg.ShowDistance; d.dist.Text = string.format("[%.0f st]", dist); d.dist.Position = Vector2.new(headPos.X, botRight.Y + 2)

        local hp    = hum and hum.Health    or 0
        local maxHp = hum and hum.MaxHealth or 100
        local hpPct = math.clamp(hp / math.max(maxHp, 1), 0, 1)
        local hpColor = Color3.fromRGB(math.floor(255*(1-hpPct)), math.floor(255*hpPct), 60)
        local barX    = botRight.X + 4
        local barTop  = Vector2.new(barX, topLeft.Y)
        local barBot  = Vector2.new(barX, botRight.Y)
        local barFill = Vector2.new(barX, topLeft.Y + boxH * (1 - hpPct))
        d.hpBg.Visible  = ESPCfg.ShowHealthBar; d.hpBg.From  = barTop;  d.hpBg.To  = barBot
        d.hpBar.Visible = ESPCfg.ShowHealthBar; d.hpBar.From = barFill; d.hpBar.To = barBot; d.hpBar.Color = hpColor
        d.hpTxt.Visible = ESPCfg.ShowHealthText; d.hpTxt.Text = string.format("HP: %d/%d", math.floor(hp), math.floor(maxHp)); d.hpTxt.Position = Vector2.new(barX + 6, (barTop.Y + barBot.Y) / 2 - ESPCfg.TextSize / 2)

        local boxLines = { {topLeft, topRight}, {botLeft, botRight}, {topLeft, botLeft}, {topRight, botRight} }
        for i = 1, 4 do
            d.box[i].Visible = ESPCfg.ShowBox; d.box[i].Color = outline
            if ESPCfg.ShowBox then d.box[i].From = boxLines[i][1]; d.box[i].To = boxLines[i][2] end
        end
        d.tracer.Visible = ESPCfg.ShowTracers; d.tracer.Color = fill
        if ESPCfg.ShowTracers then d.tracer.From = tracerFrom; d.tracer.To = Vector2.new(footPos.X, footPos.Y) end
    end
end

local function startESP()
    if Loops.esp then return end
    reloadHighlights()
    espCharConns = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            initDrawings(p)
            espCharConns[p.Name] = p.CharacterAdded:Connect(function()
                task.wait(0.2); applyESP(p); initDrawings(p)
            end)
        end
    end
    espCharConns["_added"] = Players.PlayerAdded:Connect(function(p)
        task.wait(0.5); applyESP(p); initDrawings(p)
        espCharConns[p.Name] = p.CharacterAdded:Connect(function()
            task.wait(0.2); applyESP(p); initDrawings(p)
        end)
    end)
    espCharConns["_removing"] = Players.PlayerRemoving:Connect(function(p)
        removeDrawings(p.Name)
        if espHighlights[p.Name] then pcall(function() espHighlights[p.Name]:Destroy() end); espHighlights[p.Name] = nil end
        if espCharConns[p.Name]  then espCharConns[p.Name]:Disconnect(); espCharConns[p.Name] = nil end
    end)
    Loops.espChams = true
    task.spawn(function()
        while Loops.espChams do
            if ESPCfg.Enabled then reloadHighlights() end
            task.wait(0.5)
        end
    end)
    Loops.esp = RunService.RenderStepped:Connect(updateESPFrame)
    Notify("MM2", "ESP enabled.", "Success")
end

local function stopESP()
    stopLoop("esp")
    Loops.espChams = false
    removeAllHighlights()
    removeAllDrawings()
    for k, c in pairs(espCharConns) do pcall(function() c:Disconnect() end); espCharConns[k] = nil end
    Notify("MM2", "ESP disabled.", "Info")
end

local function reloadESP()
    if not ESPCfg.Enabled then return end
    stopLoop("esp"); Loops.espChams = false
    removeAllHighlights(); removeAllDrawings()
    for k, c in pairs(espCharConns) do pcall(function() c:Disconnect() end); espCharConns[k] = nil end
    startESP()
end

-- ════════════════════════════════════════════════════════════
-- DROPDOWN AUTO-REFRESH
-- ════════════════════════════════════════════════════════════
local playerDropdowns = {}

local function getPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(names, p.Name) end
    end
    return names
end

local function refreshDropdowns()
    local names = getPlayerNames()
    for _, dd in ipairs(playerDropdowns) do pcall(function() dd:Refresh(names) end) end
end

Players.PlayerAdded:Connect(function()    task.wait(0.5); refreshDropdowns() end)
Players.PlayerRemoving:Connect(function() task.wait(0.2); refreshDropdowns() end)

local gameplay = game.ReplicatedStorage:FindFirstChild("Gameplay")
if gameplay then
    local pdc = gameplay:FindFirstChild("PlayerDataChanged")
    if pdc then
        local c = pdc.OnClientEvent:Connect(function(data)
            State.playerData = data
            if Loops.esp then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP then applyESP(p) end  -- FIXED: was applyHighlight (undefined)
                end
            end
        end)
        table.insert(Conn, c)
    end
end

-- ─────────────────────────────────────────────────────────────
--  TAB  ·  MAIN  (Movement + Player + Coin Farm)
-- ─────────────────────────────────────────────────────────────
local TabMain = Window:CreateTab({ Name = "Main", Icon = Icons['home'] })

-- ── Movement ──────────────────────────────────────────────────
local sMove = TabMain:CreateSection("Movement")

sMove:CreateToggle({
    Name = "Fly", CurrentValue = false, Flag = "UNI_Fly",
    Callback = function(v) if v then startFly() else stopFly() end end,
})
sMove:CreateSlider({
    Name = "Fly Speed", Range = {10, 250}, Increment = 5,
    CurrentValue = 60, Suffix = " st/s", Flag = "UNI_FlySpeed",
    Callback = function(v) State.flySpeed = v end,
})
sMove:CreateToggle({
    Name = "NoClip", CurrentValue = false, Flag = "UNI_NoClip",
    Callback = function(v) if v then startNoClip() else stopNoClip() end end,
})
sMove:CreateToggle({
    Name = "Infinite Jump", CurrentValue = false, Flag = "UNI_InfJump",
    Callback = function(v) if v then startInfiniteJump() else stopInfiniteJump() end end,
})
sMove:CreateSlider({
    Name = "Walk Speed", Range = {4, 200}, Increment = 2,
    CurrentValue = 16, Suffix = " st/s", Flag = "UNI_WalkSpeed",
    Callback = function(v) applySpeed(v) end,
})
sMove:CreateSlider({
    Name = "Jump Power", Range = {10, 300}, Increment = 5,
    CurrentValue = 50, Suffix = " pw", Flag = "UNI_JumpPower",
    Callback = function(v) applyJump(v) end,
})

-- ── Player ────────────────────────────────────────────────────
local sPlayerMain = TabMain:CreateSection("Player")

sPlayerMain:CreateToggle({
    Name = "Anti-Fling", CurrentValue = false, Flag = "UNI_AntiFling",
    Callback = function(v) if v then startAntiFling() else stopAntiFling() end end,
})

-- ── Coin Farm ─────────────────────────────────────────────────
local sCoinMain = TabMain:CreateSection("Coin Farm")

sCoinMain:CreateToggle({
    Name = "Enable Coin Farm", CurrentValue = false, Flag = "MM2_CoinFarm",
    Callback = function(v) if v then startCoinFarm() else stopCoinFarm() end end,
})

-- ─────────────────────────────────────────────────────────────
--  TAB  ·  COMBAT
-- ─────────────────────────────────────────────────────────────
local TabCombat = Window:CreateTab({ Name = "Combat", Icon = Icons['swords'] })

-- ── Murderer ─────────────────────────────────────────────────
local sMurd = TabCombat:CreateSection("Murderer")

-- Knife Throw button removed (point 1)
sMurd:CreateButton({ Name = "Kill Nearest Player", Callback = KillNearest })
sMurd:CreateButton({ Name = "Kill All Players",    Callback = KillAll     })

sMurd:CreateToggle({
    Name = "Auto Knife Throw", CurrentValue = false, Flag = "MM2_AutoKnife",
    Callback = function(v) if v then startAutoKnife() else stopAutoKnife() end end,
})
-- Knife Interval slider removed (point 1) — hardcoded to 0.3s

sMurd:CreateToggle({
    Name = "Kill Aura", CurrentValue = false, Flag = "MM2_KillAura",
    Callback = function(v) if v then startKillAura() else stopKillAura() end end,
})
sMurd:CreateSlider({
    Name = "Aura Radius", Range = {3, 25}, Increment = 0.5,
    CurrentValue = 7, Suffix = " st", Flag = "MM2_KillAuraRadius",
    Callback = function(v) State.killAuraRadius = v end,
})

-- ── Sheriff ──────────────────────────────────────────────────
local sSher = TabCombat:CreateSection("Sheriff")

sSher:CreateBind({
    Name = "Shoot Murderer", CurrentBind = shootBindName, Flag = "MM2_ShootBind",
    Callback = function(key)
        local kc = Enum.KeyCode[tostring(key)]
        if kc then
            shootBind     = kc
            shootBindName = tostring(key)  -- FIXED: now both values stay in sync
        end
    end,
})
sSher:CreateButton({
    Name = "Shoot Murderer  [Instant — TP]",
    Callback = function() ShootAtInstant(FindMurderer()) end,
})
sSher:CreateToggle({
    Name = "Auto-Shoot  [Wallcheck: ON]", CurrentValue = false, Flag = "MM2_AutoShoot",
    Callback = function(v) if v then startAutoShoot() else stopAutoShoot() end end,
})
sSher:CreateSlider({
    Name = "Aim Prediction", Range = {0, 8}, Increment = 0.1,
    CurrentValue = 1.5, Flag = "MM2_ShootOffset",
    Callback = function(v) State.shootOffset = v end,
})
sSher:CreateButton({
    Name = "Pick Up Dropped Gun",
    Callback = TeleportToGun,
})

-- ─────────────────────────────────────────────────────────────
--  TAB  ·  PLAYERS
-- ─────────────────────────────────────────────────────────────
local TabPlayers = Window:CreateTab({ Name = "Players", Icon = Icons['circle-user-round'] })

-- ── Game Info ─────────────────────────────────────────────────
-- Show Timer removed (point 7)
local sInfo = TabPlayers:CreateSection("GAME INFO")

sInfo:CreateButton({ Name = "Broadcast Roles", Callback = SendRoles })
sInfo:CreateButton({
    Name = "Display Roles",
    Callback = function()
        local m, s = FindMurderer(), FindSheriff()
        Notify("Roles", string.format("Murderer: %s\nSheriff: %s",
            m and m.Name or "unknown", s and s.Name or "unknown"), "Info", 6)
    end,
})

-- ── Teleport ─────────────────────────────────────────────────
local sTP      = TabPlayers:CreateSection("Teleport")
local tpTarget = nil

local tpDrop = sTP:CreateDropdown({
    Name = "Target Player", Options = getPlayerNames(),
    CurrentOption = nil, Flag = "MM2_TPTarget",
    Callback = function(v) tpTarget = v end,
})
table.insert(playerDropdowns, tpDrop)

sTP:CreateButton({ Name = "→ Murderer",        Callback = function() TeleportToPlayer(FindMurderer()) end })
sTP:CreateButton({ Name = "→ Sheriff",         Callback = function() TeleportToPlayer(FindSheriff())  end })
sTP:CreateButton({
    Name = "→ Selected Player",
    Callback = function()
        if not tpTarget then Notify("MM2", "Select a player first.", "Warning") return end
        TeleportToPlayer(Players:FindFirstChild(tpTarget))
    end,
})
sTP:CreateButton({ Name = "→ Random Spawn", Callback = TeleportToMap })

-- ── Follow ───────────────────────────────────────────────────
local sFollow      = TabPlayers:CreateSection("Follow")
local followTarget = nil

local followDrop = sFollow:CreateDropdown({
    Name = "Follow Target", Options = getPlayerNames(),
    CurrentOption = nil, Flag = "MM2_FollowTarget",
    Callback = function(v) followTarget = v end,
})
table.insert(playerDropdowns, followDrop)

sFollow:CreateToggle({
    Name = "Follow Player", CurrentValue = false, Flag = "MM2_Follow",
    Callback = function(v)
        if v then
            local p = followTarget and Players:FindFirstChild(followTarget)
            if not p then Notify("MM2", "Select a follow target first.", "Warning") return end
            startFollowPlayer(p)
        else
            stopFollowPlayer()
        end
    end,
})

-- ── Fling ─────────────────────────────────────────────────────
local sFling      = TabPlayers:CreateSection("Fling")
local flingTarget = nil

local flingDrop = sFling:CreateDropdown({
    Name = "Fling Target", Options = getPlayerNames(),
    CurrentOption = nil, Flag = "MM2_FlingTarget",
    Callback = function(v) flingTarget = v end,
})
table.insert(playerDropdowns, flingDrop)

sFling:CreateButton({ Name = "Fling Murderer", Callback = function()
    local m = FindMurderer()
    if not m then Notify("MM2", "Murderer not found.", "Warning") return end
    Fling(m)
end })
sFling:CreateButton({ Name = "Fling Sheriff", Callback = function()
    local s = FindSheriff()
    if not s then Notify("MM2", "Sheriff not found.", "Warning") return end
    Fling(s)
end })
sFling:CreateButton({
    Name = "Fling Selected",
    Callback = function()
        if not flingTarget then Notify("MM2", "Select a target first.", "Warning") return end
        Fling(Players:FindFirstChild(flingTarget))
    end,
})
sFling:CreateButton({ Name = "Fling Nearest", Callback = function() Fling(FindNearest()) end })

-- ─────────────────────────────────────────────────────────────
--  TAB  ·  ESP
-- ─────────────────────────────────────────────────────────────
local TabESP = Window:CreateTab({ Name = "ESP", Icon = Icons['eye'] })

local sESPMaster = TabESP:CreateSection("ESP Control")

sESPMaster:CreateToggle({
    Name = "Enable ESP", CurrentValue = false, Flag = "MM2_ESP",
    Callback = function(v)
        ESPCfg.Enabled = v
        if v then startESP() else stopESP() end
    end,
})
sESPMaster:CreateSlider({
    Name = "Max Distance", Range = {50, 1000}, Increment = 10,
    CurrentValue = 500, Suffix = " st", Flag = "MM2_ESPMaxDist",
    Callback = function(v) ESPCfg.MaxDistance = v end,
})
sESPMaster:CreateSlider({
    Name = "Text Size", Range = {9, 22}, Increment = 1,
    CurrentValue = 13, Flag = "MM2_ESPTextSize",
    Callback = function(v) ESPCfg.TextSize = v end,
})

local sESPLayers = TabESP:CreateSection("Overlay Layers")

sESPLayers:CreateToggle({ Name = "Show Names",       CurrentValue = true,  Flag = "MM2_ESPNames",   Callback = function(v) ESPCfg.ShowNames      = v end })
sESPLayers:CreateToggle({ Name = "Show Role Tag",    CurrentValue = true,  Flag = "MM2_ESPRole",    Callback = function(v) ESPCfg.ShowRole       = v end })
sESPLayers:CreateToggle({ Name = "Show Distance",    CurrentValue = true,  Flag = "MM2_ESPDist",    Callback = function(v) ESPCfg.ShowDistance   = v end })
sESPLayers:CreateToggle({ Name = "Show Health Bar",  CurrentValue = true,  Flag = "MM2_ESPHPBar",   Callback = function(v) ESPCfg.ShowHealthBar  = v end })
sESPLayers:CreateToggle({ Name = "Show Health Text", CurrentValue = false, Flag = "MM2_ESPHPTxt",   Callback = function(v) ESPCfg.ShowHealthText = v end })
sESPLayers:CreateToggle({ Name = "Show Box",         CurrentValue = false, Flag = "MM2_ESPBox",     Callback = function(v) ESPCfg.ShowBox        = v end })
sESPLayers:CreateToggle({ Name = "Show Tracers",     CurrentValue = false, Flag = "MM2_ESPTracers", Callback = function(v) ESPCfg.ShowTracers    = v end })
sESPLayers:CreateDropdown({
    Name = "Tracer Origin",
    Options = {"Bottom", "Center", "Mouse"},
    CurrentOption = "Bottom",
    Flag = "MM2_ESPTracerOrigin",
    Callback = function(v) ESPCfg.TracerOrigin = v end,
})

local sESPChams = TabESP:CreateSection("Chams (Highlight)")

sESPChams:CreateToggle({
    Name = "Enable Chams", CurrentValue = true, Flag = "MM2_ESPChams",
    Callback = function(v) ESPCfg.Chams = v; reloadHighlights() end,
})
sESPChams:CreateSlider({
    Name = "Fill Transparency", Range = {0, 100}, Increment = 5,
    CurrentValue = 55, Suffix = "%", Flag = "MM2_ESPFillTrans",
    Callback = function(v) ESPCfg.FillTransparency = v / 100 end,
})
sESPChams:CreateSlider({
    Name = "Outline Transparency", Range = {0, 100}, Increment = 5,
    CurrentValue = 0, Suffix = "%", Flag = "MM2_ESPOutlineTrans",
    Callback = function(v) ESPCfg.OutlineTransparency = v / 100 end,
})

local sESPColors = TabESP:CreateSection("Role Colors")

sESPColors:CreateColorPicker({ Name = "Murderer Fill",    Color = ESPCfg.MurdFill,    Flag = "MM2_ESPMurdFill",    Callback = function(c) ESPCfg.MurdFill    = c end })
sESPColors:CreateColorPicker({ Name = "Murderer Outline", Color = ESPCfg.MurdOutline, Flag = "MM2_ESPMurdOutline", Callback = function(c) ESPCfg.MurdOutline = c end })
sESPColors:CreateColorPicker({ Name = "Sheriff Fill",     Color = ESPCfg.SherFill,    Flag = "MM2_ESPSherFill",    Callback = function(c) ESPCfg.SherFill    = c end })
sESPColors:CreateColorPicker({ Name = "Sheriff Outline",  Color = ESPCfg.SherOutline, Flag = "MM2_ESPSherOutline", Callback = function(c) ESPCfg.SherOutline = c end })
sESPColors:CreateColorPicker({ Name = "Innocent Fill",    Color = ESPCfg.InnFill,     Flag = "MM2_ESPInnFill",     Callback = function(c) ESPCfg.InnFill     = c end })
sESPColors:CreateColorPicker({ Name = "Innocent Outline", Color = ESPCfg.InnOutline,  Flag = "MM2_ESPInnOutline",  Callback = function(c) ESPCfg.InnOutline  = c end })

-- ════════════════════════════════════════════════════════════
-- READY
-- ════════════════════════════════════════════════════════════
Notify("Murder Mystery 2", "v3.0 — ready.", "Success", 4)

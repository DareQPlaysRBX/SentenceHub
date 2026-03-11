-- ─────────────────────────────────────────────────
--  SERVICES
-- ─────────────────────────────────────────────────
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextChatService  = game:GetService("TextChatService")

local LocalPlayer  = Players.LocalPlayer
local Character    = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Camera       = workspace.CurrentCamera

-- ─────────────────────────────────────────────────
--  MODULE TABLE
-- ─────────────────────────────────────────────────
local MM2 = {}
MM2.__index = MM2
MM2.Name    = "Murder Mystery 2"
MM2.GameId  = 142823291   -- oficjalne GameId MM2

-- ─────────────────────────────────────────────────
--  WEWNĘTRZNY STAN
-- ─────────────────────────────────────────────────
local State = {
    -- ESP
    playerESP   = false,
    gunDropESP  = false,
    trapESP     = false,

    -- Mechaniki
    autoShoot        = false,
    autoKnifeThrow   = false,
    killAura         = false,
    antiFling        = false,
    noClip           = false,
    roundTimer       = false,

    -- Predykcja
    shootOffset        = 2.8,
    offsetToPingMult   = 1.0,

    -- Coin farm (placeholder, firetouchinterest wymagane)
    coinFarm  = false,

    -- Dane ról (z eventu PlayerDataChanged)
    playerData = {},
}

-- Aktywne połączenia RBX (do czyszczenia)
local Connections = {}

-- Referencja do hub-notify (ustawiana przez :Init)
local HubNotify = function(msg, color)
    print("[MM2] " .. tostring(msg))
end
local HubDialog = function(title, desc, buttons)
    -- fallback — zwraca pierwszy przycisk
    return buttons[1]
end

-- ─────────────────────────────────────────────────
--  HELPERS — CHARAKTER
-- ─────────────────────────────────────────────────
local function getLocalChar()
    return LocalPlayer.Character
end

local function getLocalHRP()
    local c = getLocalChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getLocalHumanoid()
    local c = getLocalChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ─────────────────────────────────────────────────
--  HELPERS — MAPA
-- ─────────────────────────────────────────────────

--- Zwraca aktualną mapę (model z CoinContainer + Spawns).
local function getMap()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:FindFirstChild("CoinContainer") and obj:FindFirstChild("Spawns") then
            return obj
        end
    end
    return nil
end

--- Zwraca najbliższy model z listy do podanego gracza.
---@param player Player
---@param models table  tablica Instance
---@return Instance|nil, number
local function getClosestModel(player, models)
    local char = player.Character
    if not char then return nil, math.huge end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil, math.huge end

    local closest, minDist = nil, math.huge
    for _, model in ipairs(models) do
        local pivot = model:IsA("Model") and model:GetPivot().Position
                      or (model:IsA("BasePart") and model.Position)
        if pivot then
            local d = (pivot - root.Position).Magnitude
            if d < minDist then
                minDist = d
                closest = model
            end
        end
    end
    return closest, minDist
end

-- ─────────────────────────────────────────────────
--  HELPERS — ROLE
-- ─────────────────────────────────────────────────

--- Zwraca gracza-mordercę (sprawdza Backpack, Character, playerData).
function MM2:FindMurderer()
    -- 1) Knife w Backpack
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Backpack:FindFirstChild("Knife") then return p end
    end
    -- 2) Knife w Character
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("Knife") then return p end
    end
    -- 3) Dane ról
    for name, data in pairs(State.playerData) do
        if data.Role == "Murderer" then
            local p = Players:FindFirstChild(name)
            if p then return p end
        end
    end
    return nil
end

--- Zwraca gracza-szeryfa.
function MM2:FindSheriff()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Backpack:FindFirstChild("Gun") then return p end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("Gun") then return p end
    end
    for name, data in pairs(State.playerData) do
        if data.Role == "Sheriff" then
            local p = Players:FindFirstChild(name)
            if p then return p end
        end
    end
    return nil
end

--- Zwraca szeryfa innego niż localPlayer.
function MM2:FindSheriffNotMe()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Backpack:FindFirstChild("Gun") then return p end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Gun") then return p end
    end
    return nil
end

--- Zwraca gracza najbliższego localPlayer (wyklucza samego siebie).
function MM2:FindNearestPlayer()
    local root = getLocalHRP()
    if not root then return nil end

    local nearest, minDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - root.Position).Magnitude
                if d < minDist then
                    minDist = d
                    nearest  = p
                end
            end
        end
    end
    return nearest
end

-- ─────────────────────────────────────────────────
--  PREDYKCJA POZYCJI
-- ─────────────────────────────────────────────────

--- Przewiduje pozycję gracza na podstawie prędkości + MoveDirection.
---@param targetPlayer Player
---@param offset number   mnożnik przesunięcia (domyślnie State.shootOffset)
---@return Vector3
function MM2:GetPredictedPosition(targetPlayer, offset)
    offset = offset or State.shootOffset
    local char = targetPlayer.Character
    if not char then return Vector3.zero end

    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
    local hum   = char:FindFirstChildOfClass("Humanoid")
    if not torso or not hum then return Vector3.zero end

    local vel      = torso.AssemblyLinearVelocity
    local moveDir  = hum.MoveDirection
    local pingMult = ((LocalPlayer:GetNetworkPing() * 1000) * ((State.offsetToPingMult - 1) * 0.01)) + 1

    local predicted = torso.Position
        + (vel * Vector3.new(0.75, 0.5, 0.75)) * (offset / 15)
        + moveDir * offset

    return predicted * pingMult
end

-- ─────────────────────────────────────────────────
--  SHOOT (SHERIFF → MURDERER)
-- ─────────────────────────────────────────────────

--- Strzela do celu (wymaga narzędzia Gun w Character).
---@param target Player
---@param instantKill boolean  (opcjonalne) — strzał bezpośrednio w HRP
function MM2:ShootAt(target, instantKill)
    if self:FindSheriff() ~= LocalPlayer then
        HubNotify("Nie jesteś szeryfem!", Color3.fromRGB(255,80,80))
        return
    end
    if not target then
        HubNotify("Brak celu do strzału.")
        return
    end

    local char = getLocalChar()
    if not char:FindFirstChild("Gun") then
        local hum = getLocalHumanoid()
        if hum and LocalPlayer.Backpack:FindFirstChild("Gun") then
            hum:EquipTool(LocalPlayer.Backpack:FindFirstChild("Gun"))
            task.wait(0.1)
        else
            HubNotify("Nie masz pistoletu!")
            return
        end
    end

    local tHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then
        HubNotify("Nie znaleziono HRP celu.")
        return
    end

    local origin = CFrame.new(char.RightHand.Position)
    local aimPos

    if instantKill then
        -- Strzał bezpośrednio w HRP (wykrywalny)
        aimPos = CFrame.new(tHRP.Position)
    else
        aimPos = CFrame.new(self:GetPredictedPosition(target))
    end

    char:WaitForChild("Gun"):WaitForChild("Shoot"):FireServer(origin, aimPos)
end

-- ─────────────────────────────────────────────────
--  KNIFE THROW (MURDERER → NEAREST)
-- ─────────────────────────────────────────────────

--- Rzuca nożem w kierunku najbliższego gracza.
---@param silent boolean  jeśli true — brak powiadomień o błędach
function MM2:KnifeThrow(silent)
    if self:FindMurderer() ~= LocalPlayer then
        if not silent then HubNotify("Nie jesteś mordercą!") end
        return
    end

    local char = getLocalChar()
    if not char:FindFirstChild("Knife") then
        local hum = getLocalHumanoid()
        if hum and LocalPlayer.Backpack:FindFirstChild("Knife") then
            hum:EquipTool(LocalPlayer.Backpack:FindFirstChild("Knife"))
            task.wait(0.1)
        else
            if not silent then HubNotify("Nie masz noża!") end
            return
        end
    end

    local nearest = self:FindNearestPlayer()
    if not nearest or not nearest.Character then
        if not silent then HubNotify("Brak graczy w pobliżu!") end
        return
    end

    local tHRP = nearest.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end

    local knife    = char:WaitForChild("Knife")
    local origin   = CFrame.new(char.RightHand.Position)
    local aimPos   = self:GetPredictedPosition(nearest, State.shootOffset + 1)

    knife:WaitForChild("Events"):WaitForChild("KnifeThrown"):FireServer(origin, CFrame.new(aimPos))
end

-- ─────────────────────────────────────────────────
--  KILL CLOSEST (MURDERER SLASH)
-- ─────────────────────────────────────────────────

--- Teleportuje cel obok gracza i uderza (Stab).
function MM2:KillNearest()
    if self:FindMurderer() ~= LocalPlayer then
        HubNotify("Nie jesteś mordercą!")
        return
    end

    local char = getLocalChar()
    if not char:FindFirstChild("Knife") then
        local hum = getLocalHumanoid()
        if hum and LocalPlayer.Backpack:FindFirstChild("Knife") then
            hum:EquipTool(LocalPlayer.Backpack:FindFirstChild("Knife"))
            task.wait(0.1)
        else
            HubNotify("Nie masz noża!")
            return
        end
    end

    local nearest = self:FindNearestPlayer()
    if not nearest or not nearest.Character then
        HubNotify("Brak gracza w pobliżu!")
        return
    end

    local root = getLocalHRP()
    local tHRP = nearest.Character:FindFirstChild("HumanoidRootPart")
    if not root or not tHRP then return end

    tHRP.Anchored = true
    tHRP.CFrame = root.CFrame + root.CFrame.LookVector * 2
    task.wait(0.05)

    char.Knife.Stab:FireServer("Slash")

    task.delay(0.3, function()
        pcall(function() tHRP.Anchored = false end)
    end)
end

-- ─────────────────────────────────────────────────
--  KILL ALL (MURDERER)
-- ─────────────────────────────────────────────────

--- Skupia wszystkich graczy przed localPlayem i uderza raz.
function MM2:KillAll()
    if self:FindMurderer() ~= LocalPlayer then
        HubNotify("Nie jesteś mordercą!")
        return
    end

    local char = getLocalChar()
    local root = getLocalHRP()
    if not char or not root then return end

    if not char:FindFirstChild("Knife") then
        local hum = getLocalHumanoid()
        if hum and LocalPlayer.Backpack:FindFirstChild("Knife") then
            hum:EquipTool(LocalPlayer.Backpack:FindFirstChild("Knife"))
            task.wait(0.1)
        end
    end

    local anchored = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Anchored = true
                hrp.CFrame = root.CFrame + root.CFrame.LookVector * 1.5
                table.insert(anchored, hrp)
            end
        end
    end

    task.wait(0.05)
    char.Knife.Stab:FireServer("Slash")

    task.delay(0.5, function()
        for _, hrp in ipairs(anchored) do
            pcall(function() hrp.Anchored = false end)
        end
    end)

    HubNotify("Zaatakowano wszystkich graczy.")
end

-- ─────────────────────────────────────────────────
--  MINI FLING
-- ─────────────────────────────────────────────────

--- Flinguje wybranego gracza (klasyczna metoda BodyVelocity).
---@param targetPlayer Player
function MM2:Fling(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then
        HubNotify("Nieprawidłowy cel flinga.")
        return
    end

    local lChar = getLocalChar()
    local lHRP  = getLocalHRP()
    local lHum  = getLocalHumanoid()
    if not lChar or not lHRP or not lHum then return end

    local tChar = targetPlayer.Character
    local tHum  = tChar:FindFirstChildOfClass("Humanoid")
    local tHRP  = tHum and tHum.RootPart
    local tHead = tChar:FindFirstChild("Head")

    if not tChar:FindFirstChildWhichIsA("BasePart") then
        HubNotify("Cel nie ma BasePart.")
        return
    end

    -- Zapisz pozycję powrotu
    local oldPos = lHRP.CFrame

    -- Ustaw kamerę na celu
    Camera.CameraSubject = tHead or tHum

    local bv = Instance.new("BodyVelocity")
    bv.Velocity  = Vector3.new(9e8, 9e8, 9e8)
    bv.MaxForce  = Vector3.new(1/0, 1/0, 1/0)
    bv.Parent    = lHRP

    lHum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    local basePart = tHRP or tHead
    if not basePart then
        bv:Destroy()
        HubNotify("Nie znaleziono BasePart celu.")
        return
    end

    workspace.FallenPartsDestroyHeight = 0/0

    local deadline = tick() + 2
    local angle    = 0

    repeat
        if not lHRP or not tHum then break end
        angle = angle + 100
        local offsets = {
            CFrame.new(0, 1.5, 0),  CFrame.new(0,-1.5, 0),
            CFrame.new(2.25,1.5,-2.25), CFrame.new(-2.25,-1.5,2.25),
        }
        for _, off in ipairs(offsets) do
            lHRP.CFrame = CFrame.new(basePart.Position) * off * CFrame.Angles(math.rad(angle),0,0)
            lChar:SetPrimaryPartCFrame(lHRP.CFrame)
            lHRP.Velocity    = Vector3.new(9e7, 9e7*10, 9e7)
            lHRP.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
            task.wait()
        end
    until basePart.Velocity.Magnitude > 500
       or basePart.Parent ~= tChar
       or targetPlayer.Parent ~= Players
       or tHum.Sit
       or lHum.Health <= 0
       or tick() > deadline

    bv:Destroy()
    lHum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    Camera.CameraSubject = lHum

    -- Powrót na poprzednią pozycję
    local t0 = tick()
    repeat
        lHRP.CFrame = oldPos * CFrame.new(0, 0.5, 0)
        lChar:SetPrimaryPartCFrame(lHRP.CFrame)
        lHum:ChangeState(Enum.HumanoidStateType.GettingUp)
        for _, part in ipairs(lChar:GetChildren()) do
            if part:IsA("BasePart") then
                part.Velocity, part.RotVelocity = Vector3.zero, Vector3.zero
            end
        end
        task.wait()
    until (lHRP.Position - oldPos.p).Magnitude < 25 or tick() - t0 > 3

    workspace.FallenPartsDestroyHeight = -500
    HubNotify("Fling zakończony.")
end

-- ─────────────────────────────────────────────────
--  NOCLIP
-- ─────────────────────────────────────────────────
local noclipConn = nil

function MM2:EnableNoClip()
    if noclipConn then return end
    noclipConn = RunService.Stepped:Connect(function()
        local c = getLocalChar()
        if not c then return end
        for _, part in ipairs(c:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end)
    State.noClip = true
    HubNotify("NoClip włączony.")
end

function MM2:DisableNoClip()
    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end
    State.noClip = false
    HubNotify("NoClip wyłączony. Zresetuj postać jeśli utkąłeś.")
end

-- ─────────────────────────────────────────────────
--  AUTO SHOOT (pętla)
-- ─────────────────────────────────────────────────
local autoShootConn = nil

function MM2:StartAutoShoot()
    if autoShootConn then return end
    State.autoShoot = true

    autoShootConn = RunService.Heartbeat:Connect(function()
        if self:FindSheriff() ~= LocalPlayer then return end

        local murderer = self:FindMurderer() or self:FindSheriffNotMe()
        if not murderer or not murderer.Character then return end

        local root = getLocalHRP()
        local tHRP = murderer.Character:FindFirstChild("HumanoidRootPart")
        if not root or not tHRP then return end

        -- Sprawdź LOS (line of sight)
        local dir    = (tHRP.Position - root.Position).Unit * 60
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { getLocalChar() }

        local hit = workspace:Raycast(root.Position, dir, params)
        if hit and hit.Instance.Parent ~= murderer.Character then return end

        self:ShootAt(murderer)
    end)

    HubNotify("Auto-shoot włączony.")
end

function MM2:StopAutoShoot()
    if autoShootConn then
        autoShootConn:Disconnect()
        autoShootConn = nil
    end
    State.autoShoot = false
    HubNotify("Auto-shoot wyłączony.")
end

-- ─────────────────────────────────────────────────
--  AUTO KNIFE THROW (pętla)
-- ─────────────────────────────────────────────────
local knifeThrowTask = nil

function MM2:StartAutoKnifeThrow(interval)
    interval = interval or 1.5
    State.autoKnifeThrow = true

    task.spawn(function()
        while State.autoKnifeThrow do
            self:KnifeThrow(true)
            task.wait(interval)
        end
    end)

    HubNotify("Auto knife throw włączony (co " .. interval .. "s).")
end

function MM2:StopAutoKnifeThrow()
    State.autoKnifeThrow = false
    HubNotify("Auto knife throw wyłączony.")
end

-- ─────────────────────────────────────────────────
--  KILL AURA (pętla)
-- ─────────────────────────────────────────────────
local killAuraConn = nil

function MM2:StartKillAura(radius)
    radius = radius or 7
    if killAuraConn then return end

    killAuraConn = RunService.Heartbeat:Connect(function()
        if self:FindMurderer() ~= LocalPlayer then return end
        local root = getLocalHRP()
        if not root then return end

        local char = getLocalChar()
        if not char:FindFirstChild("Knife") then
            local hum = getLocalHumanoid()
            if hum and LocalPlayer.Backpack:FindFirstChild("Knife") then
                hum:EquipTool(LocalPlayer.Backpack:FindFirstChild("Knife"))
            end
            return
        end

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
                if tHRP and (tHRP.Position - root.Position).Magnitude < radius then
                    tHRP.Anchored = true
                    tHRP.CFrame   = root.CFrame + root.CFrame.LookVector * 2
                    task.wait(0.05)
                    pcall(function() char.Knife.Stab:FireServer("Slash") end)
                    task.delay(0.2, function() pcall(function() tHRP.Anchored = false end) end)
                    return
                end
            end
        end
    end)

    State.killAura = true
    HubNotify("Kill aura włączona (zasięg: " .. radius .. " studs).")
end

function MM2:StopKillAura()
    if killAuraConn then
        killAuraConn:Disconnect()
        killAuraConn = nil
    end
    State.killAura = false
    HubNotify("Kill aura wyłączona.")
end

-- ─────────────────────────────────────────────────
--  ANTI-FLING
-- ─────────────────────────────────────────────────
local antiFlingConn  = nil
local antiFlingLastPos = Vector3.zero

function MM2:StartAntiFling()
    if antiFlingConn then return end

    antiFlingConn = RunService.Heartbeat:Connect(function()
        local root = getLocalHRP()
        if not root then return end

        if root.AssemblyLinearVelocity.Magnitude > 250
        or root.AssemblyAngularVelocity.Magnitude > 250 then
            root.AssemblyLinearVelocity  = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            if antiFlingLastPos ~= Vector3.zero then
                root.CFrame = CFrame.new(antiFlingLastPos)
            end
            HubNotify("Anti-fling: zablokowano wylot!", Color3.fromRGB(255,200,0))
        else
            antiFlingLastPos = root.Position
        end
    end)

    State.antiFling = true
    HubNotify("Anti-fling włączony.")
end

function MM2:StopAntiFling()
    if antiFlingConn then
        antiFlingConn:Disconnect()
        antiFlingConn = nil
    end
    State.antiFling = false
    HubNotify("Anti-fling wyłączony.")
end

-- ─────────────────────────────────────────────────
--  ROUND TIMER
-- ─────────────────────────────────────────────────
local timerLabel    = nil
local timerTask     = nil

local function secondsToTime(s)
    if s <= 0 then return "0:00" end
    return string.format("%d:%02d", math.floor(s/60), s % 60)
end

function MM2:ShowRoundTimer(screenGui)
    if timerLabel then return end

    timerLabel = Instance.new("TextLabel")
    timerLabel.BackgroundTransparency = 0.45
    timerLabel.BackgroundColor3  = Color3.fromRGB(15, 15, 15)
    timerLabel.TextColor3        = Color3.fromRGB(255, 255, 255)
    timerLabel.Font              = Enum.Font.GothamBold
    timerLabel.TextScaled        = true
    timerLabel.AnchorPoint       = Vector2.new(0.5, 0)
    timerLabel.Position          = UDim2.fromScale(0.5, 0.04)
    timerLabel.Size              = UDim2.fromOffset(130, 40)
    timerLabel.Text              = "⏱ --:--"
    timerLabel.ZIndex            = 10
    Instance.new("UICorner", timerLabel).CornerRadius = UDim.new(0, 8)
    timerLabel.Parent = screenGui or game:GetService("CoreGui")

    timerTask = task.spawn(function()
        while timerLabel and timerLabel.Parent do
            local ok, t = pcall(function()
                return game.ReplicatedStorage
                    :WaitForChild("Remotes", 2)
                    :WaitForChild("Extras", 2)
                    :WaitForChild("GetTimer", 2)
                    :InvokeServer()
            end)
            timerLabel.Text = ok and ("⏱ " .. secondsToTime(t or 0)) or "⏱ --:--"
            task.wait(0.5)
        end
    end)

    HubNotify("Timer rundy aktywny.")
end

function MM2:HideRoundTimer()
    if timerLabel then timerLabel:Destroy() timerLabel = nil end
    if timerTask  then task.cancel(timerTask) timerTask = nil end
end

-- ─────────────────────────────────────────────────
--  TELEPORTACJE
-- ─────────────────────────────────────────────────

--- Teleportuje do losowego spawna na mapie.
function MM2:TeleportToMap()
    local map = getMap()
    if not map then HubNotify("Brak mapy.") return end
    local spawns = map:FindFirstChild("Spawns")
    if not spawns then HubNotify("Brak spawna na mapie.") return end
    local list = spawns:GetChildren()
    local target = list[math.random(#list)]
    local char = getLocalChar()
    if char then char:MoveTo(target.Position) end
end

--- Teleportuje do upuszczonego pistoletu i wraca.
function MM2:TeleportToDroppedGun()
    local map = getMap()
    if not map then HubNotify("Brak mapy.") return end
    local gun = map:FindFirstChild("GunDrop")
    if not gun then HubNotify("Brak upuszczonego pistoletu.") return end
    local char = getLocalChar()
    if not char then return end
    local prevCF = char:GetPivot()
    char:PivotTo(gun:GetPivot())
    LocalPlayer.Backpack.ChildAdded:Wait()
    task.wait(0.1)
    char:PivotTo(prevCF)
    HubNotify("Podniesiono pistolet i powrócono.")
end

--- Teleportuje do innego gracza.
---@param targetPlayer Player
function MM2:TeleportToPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then
        HubNotify("Gracz niedostępny.")
        return
    end
    local tHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then HubNotify("Brak HRP celu.") return end
    local char = getLocalChar()
    if char then
        char:PivotTo(tHRP.CFrame + tHRP.CFrame.LookVector * 3)
        HubNotify("Teleportowano do " .. targetPlayer.Name)
    end
end

-- ─────────────────────────────────────────────────
--  SEND ROLES TO CHAT
-- ─────────────────────────────────────────────────

--- Wysyła do chatu imiona mordercy i szeryfa.
function MM2:SendRolesToChat()
    local murderer = self:FindMurderer()
    local sheriff  = self:FindSheriff()
    local msg = string.format(
        "🔪 Morderca: %s | 🔫 Szeryf: %s",
        murderer and murderer.Name or "?",
        sheriff  and sheriff.Name  or "?"
    )
    local channels = TextChatService:WaitForChild("TextChannels"):GetChildren()
    for _, ch in ipairs(channels) do
        if ch.Name ~= "RBXSystem" then
            pcall(function() ch:SendAsync(msg) end)
        end
    end
    HubNotify("Role wysłane do chatu.")
end

-- ─────────────────────────────────────────────────
--  ESP (wymaga zewnętrznego ESPIndicator)
-- ─────────────────────────────────────────────────

--- Buduje konfigurację ESP na podstawie roli gracza.
---@param player Player
---@param espModule table  instancja ESPIndicator.new(...)
function MM2:AddPlayerToESP(player, espModule)
    if not player.Character then return end
    local char = player.Character

    if player == self:FindMurderer() then
        espModule:Add(char, {
            AccentColor      = Color3.fromRGB(255, 30, 30),
            ArrowShow        = true,
            ArrowMinDistance = 999999,
            ArrowSize        = UDim2.new(0, 42, 0, 42),
            LabelText        = "🔪 Morderca",
            ShowLabel        = true,
            GroupName        = "players",
        })
    elseif player == self:FindSheriff() then
        espModule:Add(char, {
            AccentColor = Color3.fromRGB(30, 170, 255),
            ArrowShow   = false,
            ShowLabel   = false,
            GroupName   = "players",
        })
    else
        espModule:Add(char, {
            AccentColor = Color3.fromRGB(50, 255, 80),
            ArrowShow   = false,
            ShowLabel   = false,
            GroupName   = "players",
        })
    end
end

--- Przeładowuje ESP wszystkich graczy.
---@param espModule table
function MM2:ReloadPlayerESP(espModule)
    espModule:RemoveGroup("players")
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            self:AddPlayerToESP(p, espModule)
        end
    end
end

--- Dodaje ESP na upuszczony pistolet.
---@param espModule table
function MM2:EnableGunDropESP(espModule)
    local map = getMap()
    if map and map:FindFirstChild("GunDrop") then
        espModule:Add(map:FindFirstChild("GunDrop"), {
            AccentColor      = Color3.fromRGB(255, 255, 40),
            ArrowShow        = true,
            ArrowMinDistance = 999999,
            ArrowSize        = UDim2.new(0, 38, 0, 38),
            LabelText        = "🔫 Pistolet",
            ShowLabel        = true,
            GroupName        = "gun",
        })
        HubNotify("Pistolet leży — żółty highlight!")
    end
end

--- Dodaje ESP na pułapki.
---@param espModule table
function MM2:EnableTrapESP(espModule)
    for _, v in ipairs(workspace:GetDescendants()) do
        if v.Name == "Trap" and v.Parent:IsA("Folder") then
            pcall(function() v.Transparency = 0 end)
            espModule:Add(v, {
                AccentColor = Color3.fromRGB(255, 100, 10),
                ArrowShow   = false,
                ShowLabel   = true,
                LabelText   = "⚠ Pułapka",
                GroupName   = "trap",
            })
        end
    end
    HubNotify("Trap ESP włączony.")
end

-- ─────────────────────────────────────────────────
--  PODŁĄCZENIE EVENTÓW MM2
-- ─────────────────────────────────────────────────

--- Subskrybuje eventy MM2 (PlayerDataChanged, GunDrop, Trap, mapa).
---@param espModule table|nil  opcjonalny — jeśli podany, auto-odświeża ESP
function MM2:SubscribeGameEvents(espModule)
    -- PlayerDataChanged → aktualizacja ról
    local remotes = game.ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local pdc = remotes:FindFirstChild("Gameplay")
                 and remotes.Gameplay:FindFirstChild("PlayerDataChanged")
        if pdc then
            local c = pdc.OnClientEvent:Connect(function(data)
                State.playerData = data
                if espModule and State.playerESP then
                    self:ReloadPlayerESP(espModule)
                end
            end)
            table.insert(Connections, c)
        end
    end

    -- GunDrop pojawia się w workspace
    local c2 = workspace.DescendantAdded:Connect(function(obj)
        if obj.Name == "GunDrop" and State.gunDropESP and espModule then
            self:EnableGunDropESP(espModule)
            HubNotify("Pistolet upuszczony!")
        end
        if obj.Name == "Trap" and obj.Parent:IsA("Folder") and State.trapESP and espModule then
            pcall(function() obj.Transparency = 0 end)
            espModule:Add(obj, {
                AccentColor = Color3.fromRGB(255,100,10),
                ArrowShow   = false, ShowLabel = true,
                LabelText   = "⚠ Pułapka", GroupName = "trap",
            })
            HubNotify("Morderca postawił pułapkę!")
        end
    end)
    table.insert(Connections, c2)

    -- GunDrop znika
    local c3 = workspace.DescendantRemoving:Connect(function(obj)
        if obj.Name == "GunDrop" and espModule then
            espModule:RemoveGroup("gun")
            HubNotify("Pistolet podniesiony.")
        end
    end)
    table.insert(Connections, c3)

    HubNotify("MM2 nasłuchuje eventów gry.")
end

-- ─────────────────────────────────────────────────
--  GETTERY STANU (przydatne do UI)
-- ─────────────────────────────────────────────────

function MM2:GetState()
    return State
end

function MM2:SetShootOffset(v)
    State.shootOffset = tonumber(v) or 2.8
    HubNotify("Offset strzału: " .. State.shootOffset)
end

function MM2:SetPingMultiplier(v)
    State.offsetToPingMult = tonumber(v) or 1.0
    HubNotify("Ping multiplier: " .. State.offsetToPingMult)
end

-- ─────────────────────────────────────────────────
--  CZYSZCZENIE
-- ─────────────────────────────────────────────────

function MM2:Destroy()
    -- Rozłącz wszystkie połączenia
    for _, c in ipairs(Connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(Connections)

    self:StopAutoShoot()
    self:StopAutoKnifeThrow()
    self:StopKillAura()
    self:StopAntiFling()
    self:DisableNoClip()
    self:HideRoundTimer()

    HubNotify("MM2 moduł wyczyszczony.")
end

-- ─────────────────────────────────────────────────
--  INIT (podpięcie do SentenceHub)
-- ─────────────────────────────────────────────────

---Inicjalizuje moduł z SentenceHub.
---@param hub table  { notify: function, dialog: function }
function MM2:Init(hub)
    if hub then
        if hub.notify then HubNotify = hub.notify end
        if hub.dialog  then HubDialog = hub.dialog  end
    end
    HubNotify("Murder Mystery 2 załadowany ✓")
    return self
end

return MM2

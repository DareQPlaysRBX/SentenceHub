-- ════════════════════════════════════════════════════════════
-- SENTENCE Hub — Murder Mystery 2
-- Place ID: 142823291
-- ════════════════════════════════════════════════════════════

-- ── Services ──────────────────────────────────────────────────────────────────
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LP            = Players.LocalPlayer
local Lib           = _G.Lib
local Window        = _G.Window

-- ════════════════════════════════════════════════════════════
-- TABS
-- ════════════════════════════════════════════════════════════
local TabESP   = Window:CreateTab({ Name = "ESP",    Icon = "rbxassetid://11780939099" })
local TabTools = Window:CreateTab({ Name = "Tools",  Icon = "rbxassetid://10002373478" })
local TabFun   = Window:CreateTab({ Name = "Fun",    Icon = "rbxassetid://11604833061" })

-- ════════════════════════════════════════════════════════════
-- STATE / FLAGS
-- ════════════════════════════════════════════════════════════
local playerESP        = false
local gunDropESP       = false
local trapDetection    = false
local autoShooting     = false
local instakillshoot   = false
local spawnAtPlayer    = false
local loopThrow        = false
local autoGetDroppedGun = false
local simulateKnifeThrow = false
local roundTimerEnabled = false

local shootOffset      = 2.8
local offsetToPingMult = 1

local playerData       = {}
local espContainer     = {}   -- highlight pool: espContainer[adornee] = Highlight
local timerLabel       = nil
local timerTask        = nil
local killAuraCon      = nil
local aimlockCon       = nil

-- ════════════════════════════════════════════════════════════
-- HELPERS — ESP (Highlight-based, no external module needed)
-- ════════════════════════════════════════════════════════════
local function addESP(adornee, color, label, alwaysOnTop)
    if not adornee or not adornee.Parent then return end
    if espContainer[adornee] then return end

    local h = Instance.new("Highlight")
    h.Name              = "SentenceESP"
    h.Adornee           = adornee
    h.FillColor         = color or Color3.new(0, 1, 0)
    h.OutlineColor      = color or Color3.new(0, 1, 0)
    h.FillTransparency  = 0.65
    h.OutlineTransparency = 0
    h.DepthMode         = alwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop
                                       or Enum.HighlightDepthMode.Occluded
    h.Parent            = game:GetService("CoreGui")
    espContainer[adornee] = h

    if label then
        local bg = Instance.new("BillboardGui")
        bg.AlwaysOnTop  = true
        bg.MaxDistance  = 300
        bg.Size         = UDim2.new(0, 80, 0, 24)
        bg.StudsOffset  = Vector3.new(0, 2.5, 0)
        bg.Adornee      = adornee
        bg.Parent       = game:GetService("CoreGui")
        local tl = Instance.new("TextLabel", bg)
        tl.Size              = UDim2.new(1, 0, 1, 0)
        tl.BackgroundTransparency = 1
        tl.Text              = label
        tl.TextColor3        = color or Color3.new(1, 1, 1)
        tl.Font              = Enum.Font.GothamBold
        tl.TextScaled        = true
        espContainer[adornee .. "_bgui"] = bg
    end
end

local function removeESP(adornee)
    local h = espContainer[adornee]
    if h then h:Destroy(); espContainer[adornee] = nil end
    local bg = espContainer[adornee .. "_bgui"]
    if bg then bg:Destroy(); espContainer[adornee .. "_bgui"] = nil end
end

local function clearAllESP()
    for key, obj in pairs(espContainer) do
        pcall(function() obj:Destroy() end)
        espContainer[key] = nil
    end
end

-- ════════════════════════════════════════════════════════════
-- HELPERS — Role detection
-- ════════════════════════════════════════════════════════════
local function findMurderer()
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl.Backpack:FindFirstChild("Knife") then return pl end
        if pl.Character and pl.Character:FindFirstChild("Knife") then return pl end
    end
    if playerData then
        for name, data in pairs(playerData) do
            if data.Role == "Murderer" then
                return Players:FindFirstChild(name)
            end
        end
    end
    return nil
end

local function findSheriff()
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl.Backpack:FindFirstChild("Gun") then return pl end
        if pl.Character and pl.Character:FindFirstChild("Gun") then return pl end
    end
    if playerData then
        for name, data in pairs(playerData) do
            if data.Role == "Sheriff" then
                return Players:FindFirstChild(name)
            end
        end
    end
    return nil
end

local function findSheriffNotMe()
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl == LP then continue end
        if pl.Backpack:FindFirstChild("Gun") then return pl end
        if pl.Character and pl.Character:FindFirstChild("Gun") then return pl end
    end
    return nil
end

local function findNearestPlayer()
    local lpRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not lpRoot then return nil end
    local nearest, shortest = nil, math.huge
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl == LP or not pl.Character then continue end
        local r = pl.Character:FindFirstChild("HumanoidRootPart")
        if r then
            local d = (lpRoot.Position - r.Position).Magnitude
            if d < shortest then shortest = d; nearest = pl end
        end
    end
    return nearest
end

local function getMap()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:FindFirstChild("CoinContainer") and obj:FindFirstChild("Spawns") then
            return obj
        end
    end
    return nil
end

-- ════════════════════════════════════════════════════════════
-- HELPERS — Prediction & Shooting
-- ════════════════════════════════════════════════════════════
local function getPredictedPosition(player)
    local char = player.Character
    if not char then return Vector3.new(0, 0, 0) end
    local hrp = char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return Vector3.new(0, 0, 0) end

    local vel = hrp.AssemblyLinearVelocity
    local moveDir = hum.MoveDirection
    local predicted = hrp.Position
        + (vel * Vector3.new(0.75, 0.5, 0.75)) * (shootOffset / 15)
        + moveDir * shootOffset
    predicted = predicted * (((LP:GetNetworkPing() * 1000) * ((offsetToPingMult - 1) * 0.01)) + 1)
    return predicted
end

local function equipTool(toolName)
    local char = LP.Character
    if not char then return false end
    if char:FindFirstChild(toolName) then return true end
    local tool = LP.Backpack:FindFirstChild(toolName)
    if tool then
        char:FindFirstChildOfClass("Humanoid"):EquipTool(tool)
        return true
    end
    return false
end

local function shootMurderer(instakill)
    if findSheriff() ~= LP then
        Lib:Notify({ Title = "MM2", Content = "You are not the sheriff/hero.", Type = "Warning", Duration = 3 })
        return
    end
    local target = findMurderer() or findSheriffNotMe()
    if not target then
        Lib:Notify({ Title = "MM2", Content = "No murderer found.", Type = "Warning", Duration = 3 })
        return
    end
    if not equipTool("Gun") then
        Lib:Notify({ Title = "MM2", Content = "You don't have the gun.", Type = "Error", Duration = 3 })
        return
    end

    local hrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local gun = LP.Character:FindFirstChild("Gun")
    if not gun then return end

    local args
    if instakill then
        args = {
            CFrame.new(hrp.Position + Vector3.new(0, 1, 0)),
            CFrame.new(hrp.Position)
        }
    else
        local rh = LP.Character:FindFirstChild("RightHand")
        args = {
            CFrame.new(rh and rh.Position or hrp.Position),
            CFrame.new(getPredictedPosition(target))
        }
    end

    local shoot = gun:FindFirstChild("Shoot")
    if shoot then
        shoot:FireServer(unpack(args))
    end
end

local function knifeThrow(silent)
    if findMurderer() ~= LP then
        if not silent then
            Lib:Notify({ Title = "MM2", Content = "You are not the murderer.", Type = "Warning", Duration = 3 })
        end
        return
    end
    if not equipTool("Knife") then
        if not silent then
            Lib:Notify({ Title = "MM2", Content = "You don't have the knife.", Type = "Error", Duration = 3 })
        end
        return
    end

    local target = findNearestPlayer()
    if not target or not target.Character then
        if not silent then
            Lib:Notify({ Title = "MM2", Content = "No valid target found.", Type = "Warning", Duration = 3 })
        end
        return
    end

    local nearHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not nearHRP then return end

    local knife = LP.Character:FindFirstChild("Knife")
    if not knife then return end

    local predictedPos = getPredictedPosition(target)
    local throwOrigin  = spawnAtPlayer
        and CFrame.new(nearHRP.Position + nearHRP.CFrame.LookVector * 5)
        or  CFrame.new(LP.Character:FindFirstChild("RightHand") and LP.Character.RightHand.Position or nearHRP.Position)

    local knifeThrown = knife:FindFirstChild("Events") and knife.Events:FindFirstChild("KnifeThrown")
    if knifeThrown then
        knifeThrown:FireServer(throwOrigin, CFrame.new(predictedPos))
    end
end

-- ════════════════════════════════════════════════════════════
-- HELPERS — ESP reload
-- ════════════════════════════════════════════════════════════
local function reloadPlayerESP()
    -- Clear existing player ESPs
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl.Character then removeESP(pl.Character) end
    end
    if not playerESP then return end

    for _, pl in ipairs(Players:GetPlayers()) do
        if not pl.Character then continue end
        local char = pl.Character
        if pl == findMurderer() then
            addESP(char, Color3.new(1, 0, 0.02), "Murderer", true)
        elseif pl == findSheriff() then
            addESP(char, Color3.new(0, 0.6, 1), nil, false)
        else
            addESP(char, Color3.new(0, 1, 0.03), nil, false)
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- REMOTES LISTENER
-- ════════════════════════════════════════════════════════════
task.spawn(function()
    local remotes = game.ReplicatedStorage:WaitForChild("Remotes", 5)
    if not remotes then return end

    local gameplay = remotes:WaitForChild("Gameplay", 5)
    if not gameplay then return end

    local pdc = gameplay:WaitForChild("PlayerDataChanged", 5)
    if pdc then
        pdc.OnClientEvent:Connect(function(data)
            playerData = data
            if playerESP then
                task.spawn(reloadPlayerESP)
            end
        end)
    end
end)

-- ════════════════════════════════════════════════════════════
-- WORKSPACE LISTENERS
-- ════════════════════════════════════════════════════════════
workspace.DescendantAdded:Connect(function(ch)
    -- Trap detection
    if trapDetection and ch.Name == "Trap" and ch.Parent and ch.Parent:IsA("Folder") then
        pcall(function() ch.Transparency = 0 end)
        addESP(ch, Color3.new(1, 0, 0.02), "Trap!", true)
        Lib:Notify({ Title = "MM2", Content = "Murderer placed a trap!", Type = "Warning", Duration = 4 })
    end

    -- Dropped Gun ESP
    if gunDropESP and ch.Name == "GunDrop" then
        addESP(ch, Color3.new(0.95, 1, 0.07), "Dropped Gun!", true)
        Lib:Notify({ Title = "MM2", Content = "Gun was dropped! Yellow highlight added.", Type = "Info", Duration = 4 })

        if autoGetDroppedGun then
            task.spawn(function()
                task.wait(1)
                local map = getMap()
                if not map then return end
                local drop = map:FindFirstChild("GunDrop")
                if not drop then return end
                local prevCF = LP.Character and LP.Character:GetPivot()
                LP.Character:MoveTo(drop.Position)
                LP.Backpack.ChildAdded:Wait()
                if prevCF then LP.Character:PivotTo(prevCF) end
            end)
        end
    end
end)

workspace.DescendantRemoving:Connect(function(ch)
    if ch.Name == "GunDrop" then
        removeESP(ch)
        Lib:Notify({ Title = "MM2", Content = "Dropped gun was picked up.", Type = "Info", Duration = 3 })
        if playerESP then
            task.spawn(function()
                task.wait(1)
                reloadPlayerESP()
            end)
        end
    end
end)

-- ════════════════════════════════════════════════════════════
-- AUTO-SHOOT LOOP
-- ════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(1)
        if autoShooting and findSheriff() == LP then
            repeat
                task.wait(0.1)
                local murderer = findMurderer() or findSheriffNotMe()
                if not murderer or not murderer.Character then continue end
                local lpRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                local mRoot  = murderer.Character:FindFirstChild("HumanoidRootPart")
                if not lpRoot or not mRoot then continue end

                local rayDir = (mRoot.Position - lpRoot.Position).Unit * 50
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = {LP.Character}

                local hit = workspace:Raycast(lpRoot.Position, rayDir, params)
                if not hit or hit.Instance:IsDescendantOf(murderer.Character) then
                    if not equipTool("Gun") then continue end
                    local gun = LP.Character:FindFirstChild("Gun")
                    if not gun then continue end
                    local shoot = gun:FindFirstChild("Shoot")
                    if shoot then
                        local rh = LP.Character:FindFirstChild("RightHand")
                        shoot:FireServer(
                            CFrame.new(rh and rh.Position or lpRoot.Position),
                            CFrame.new(getPredictedPosition(murderer))
                        )
                    end
                end
            until not autoShooting or findSheriff() ~= LP
        end
    end
end)

-- ════════════════════════════════════════════════════════════
-- AUTO KNIFE THROW LOOP
-- ════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(1.5)
        if loopThrow then knifeThrow(true) end
    end
end)

-- ════════════════════════════════════════════════════════════
-- ROUND TIMER UTILITY
-- ════════════════════════════════════════════════════════════
local function secondsToMinutes(s)
    if s == -1 then return "--:--" end
    return string.format("%dm %ds", math.floor(s / 60), s % 60)
end

-- ════════════════════════════════════════════════════════════
-- TAB: ESP
-- ════════════════════════════════════════════════════════════
local S_ESP = TabESP:CreateSection("Player Roles")

S_ESP:CreateToggle({
    Name     = "Player ESP",
    Default  = false,
    Callback = function(v)
        playerESP = v
        if v then
            if not findMurderer() and not findSheriff() then
                Lib:Notify({ Title = "MM2", Content = "No roles detected yet. Will update when found.", Type = "Info", Duration = 4 })
            end
            reloadPlayerESP()
        else
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl.Character then removeESP(pl.Character) end
            end
        end
    end,
})

S_ESP:CreateButton({
    Name     = "Reload Player ESP",
    Callback = function()
        reloadPlayerESP()
        Lib:Notify({ Title = "MM2", Content = "ESP reloaded.", Type = "Success", Duration = 2 })
    end,
})

local S_Items = TabESP:CreateSection("Items")

S_Items:CreateToggle({
    Name     = "Dropped Gun ESP",
    Default  = false,
    Callback = function(v)
        gunDropESP = v
        if v then
            local map = getMap()
            if map then
                local drop = map:FindFirstChild("GunDrop")
                if drop then addESP(drop, Color3.new(0.95, 1, 0.07), "Dropped Gun!", true) end
            end
        else
            local map = getMap()
            if map then
                local drop = map:FindFirstChild("GunDrop")
                if drop then removeESP(drop) end
            end
        end
    end,
})

S_Items:CreateToggle({
    Name     = "Trap ESP / Detection",
    Default  = false,
    Callback = function(v)
        trapDetection = v
        if v then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name == "Trap" and obj.Parent and obj.Parent:IsA("Folder") then
                    pcall(function() obj.Transparency = 0 end)
                    addESP(obj, Color3.new(1, 0, 0.02), "Trap!", true)
                end
            end
        else
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name == "Trap" then removeESP(obj) end
            end
        end
    end,
})

S_Items:CreateButton({
    Name     = "Clear All ESP",
    Callback = function()
        clearAllESP()
        Lib:Notify({ Title = "MM2", Content = "All ESP cleared.", Type = "Info", Duration = 2 })
    end,
})

-- ════════════════════════════════════════════════════════════
-- TAB: Tools
-- ════════════════════════════════════════════════════════════
local S_Sheriff = TabTools:CreateSection("Sheriff / Hero")

S_Sheriff:CreateButton({
    Name     = "Shoot Murderer",
    Callback = function()
        shootMurderer(instakillshoot)
    end,
})

S_Sheriff:CreateButton({
    Name     = "Delayed Shoot (Ray-based)",
    Callback = function()
        if findSheriff() ~= LP then
            Lib:Notify({ Title = "MM2", Content = "You are not the sheriff/hero.", Type = "Warning", Duration = 3 })
            return
        end
        local murderer = findMurderer() or findSheriffNotMe()
        if not murderer then
            Lib:Notify({ Title = "MM2", Content = "No murderer found.", Type = "Warning", Duration = 3 })
            return
        end
        if not equipTool("Gun") then return end
        Lib:Notify({ Title = "MM2", Content = "Waiting for clear line of sight...", Type = "Info", Duration = 3 })

        local con
        con = RunService.Stepped:Connect(function()
            if not murderer.Character then con:Disconnect() return end
            local lpRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            local mRoot  = murderer.Character:FindFirstChild("HumanoidRootPart")
            if not lpRoot or not mRoot then return end

            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {LP.Character}

            local dir = (Vector3.new(mRoot.Position.X, lpRoot.Position.Y, mRoot.Position.Z) - lpRoot.Position).Unit * 1000
            local hit = workspace:Raycast(lpRoot.Position, dir, params)

            if hit and hit.Instance:IsDescendantOf(murderer.Character) then
                local gun = LP.Character:FindFirstChild("Gun")
                if gun then
                    local rh = LP.Character:FindFirstChild("RightHand")
                    local shoot = gun:FindFirstChild("Shoot")
                    if shoot then
                        shoot:FireServer(
                            CFrame.new(rh and rh.Position or lpRoot.Position),
                            CFrame.new(getPredictedPosition(murderer))
                        )
                    end
                end
                con:Disconnect()
            end
        end)
    end,
})

S_Sheriff:CreateToggle({
    Name        = "Auto Shoot Murderer",
    Description = "Shoots automatically when line of sight is clear",
    Default     = false,
    Callback    = function(v) autoShooting = v end,
})

S_Sheriff:CreateToggle({
    Name        = "Instakill Shot (Detectable)",
    Description = "Warps bullet origin to murderer position",
    Default     = false,
    Callback    = function(v) instakillshoot = v end,
})

S_Sheriff:CreateSlider({
    Name         = "Shoot Offset",
    Range        = { 0, 10 },
    Default      = 2.8,
    Increment    = 0.1,
    Suffix       = "",
    Callback     = function(v) shootOffset = v end,
})

S_Sheriff:CreateSlider({
    Name         = "Offset-to-Ping Multiplier",
    Range        = { 0, 5 },
    Default      = 1,
    Increment    = 0.1,
    Suffix       = "x",
    Callback     = function(v) offsetToPingMult = v end,
})

local S_Murd = TabTools:CreateSection("Murderer")

S_Murd:CreateButton({
    Name     = "Knife Throw to Closest",
    Callback = function() knifeThrow(false) end,
})

S_Murd:CreateToggle({
    Name     = "Auto Knife Throw Loop",
    Default  = false,
    Callback = function(v) loopThrow = v end,
})

S_Murd:CreateToggle({
    Name        = "Spawn Knife Near Player",
    Description = "Makes throw origin appear near target",
    Default     = false,
    Callback    = function(v) spawnAtPlayer = v end,
})

S_Murd:CreateButton({
    Name     = "Kill Closest Player",
    Callback = function()
        if findMurderer() ~= LP then
            Lib:Notify({ Title = "MM2", Content = "You are not the murderer.", Type = "Warning", Duration = 3 })
            return
        end
        if not equipTool("Knife") then
            Lib:Notify({ Title = "MM2", Content = "No knife found.", Type = "Error", Duration = 3 })
            return
        end
        local target = findNearestPlayer()
        if not target or not target.Character then
            Lib:Notify({ Title = "MM2", Content = "No valid target.", Type = "Warning", Duration = 3 })
            return
        end
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        local lpHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp or not lpHRP then return end

        hrp.Anchored = true
        hrp.CFrame = lpHRP.CFrame + lpHRP.CFrame.LookVector * 2
        task.wait(0.1)

        local knife = LP.Character:FindFirstChild("Knife")
        if knife then
            local stab = knife:FindFirstChild("Stab")
            if stab then stab:FireServer("Slash") end
        end
    end,
})

S_Murd:CreateButton({
    Name     = "Kill EVERYONE (Detectable)",
    Callback = function()
        if findMurderer() ~= LP then
            Lib:Notify({ Title = "MM2", Content = "You are not the murderer.", Type = "Warning", Duration = 3 })
            return
        end
        if not equipTool("Knife") then return end
        local lpHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not lpHRP then return end

        for _, pl in ipairs(Players:GetPlayers()) do
            if pl == LP or not pl.Character then continue end
            local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Anchored = true
                hrp.CFrame = lpHRP.CFrame + lpHRP.CFrame.LookVector * 1
            end
        end

        local knife = LP.Character:FindFirstChild("Knife")
        if knife then
            local stab = knife:FindFirstChild("Stab")
            if stab then stab:FireServer("Slash") end
        end
    end,
})

S_Murd:CreateToggle({
    Name     = "Murderer Kill Aura",
    Default  = false,
    Callback = function(v)
        if v then
            if killAuraCon then killAuraCon:Disconnect() end
            killAuraCon = RunService.Heartbeat:Connect(function()
                if findMurderer() ~= LP then return end
                if not equipTool("Knife") then return end
                local lpHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if not lpHRP then return end
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl == LP or not pl.Character then continue end
                    local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp.Position - lpHRP.Position).Magnitude < 7 then
                        hrp.Anchored = true
                        hrp.CFrame = lpHRP.CFrame + lpHRP.CFrame.LookVector * 2
                        task.wait(0.1)
                        local knife = LP.Character:FindFirstChild("Knife")
                        if knife then
                            local stab = knife:FindFirstChild("Stab")
                            if stab then stab:FireServer("Slash") end
                        end
                    end
                end
            end)
        else
            if killAuraCon then killAuraCon:Disconnect(); killAuraCon = nil end
        end
    end,
})

local S_Util = TabTools:CreateSection("Utility")

S_Util:CreateToggle({
    Name        = "Auto Get Dropped Gun",
    Description = "Teleport to gun when dropped, return after pickup",
    Default     = false,
    Callback    = function(v) autoGetDroppedGun = v end,
})

S_Util:CreateButton({
    Name     = "Teleport to Dropped Gun",
    Callback = function()
        local map = getMap()
        if not map or not map:FindFirstChild("GunDrop") then
            Lib:Notify({ Title = "MM2", Content = "No dropped gun found.", Type = "Warning", Duration = 3 })
            return
        end
        local prevCF = LP.Character and LP.Character:GetPivot()
        LP.Character:MoveTo(map.GunDrop.Position)
        LP.Backpack.ChildAdded:Wait()
        if prevCF then LP.Character:PivotTo(prevCF) end
        Lib:Notify({ Title = "MM2", Content = "Teleported to gun and returned.", Type = "Success", Duration = 3 })
    end,
})

S_Util:CreateButton({
    Name     = "Teleport to Lobby",
    Callback = function()
        if LP.Character then
            LP.Character:MoveTo(Vector3.new(-107, 152, 41))
        end
    end,
})

S_Util:CreateButton({
    Name     = "Teleport to Map Spawn",
    Callback = function()
        local map = getMap()
        if not map then
            Lib:Notify({ Title = "MM2", Content = "No active map found.", Type = "Warning", Duration = 3 })
            return
        end
        local spawns = map:FindFirstChild("Spawns")
        if spawns and #spawns:GetChildren() > 0 then
            local sp = spawns:GetChildren()
            LP.Character:MoveTo(sp[math.random(1, #sp)].Position)
        end
    end,
})

S_Util:CreateToggle({
    Name     = "Round Timer Display",
    Default  = false,
    Callback = function(v)
        roundTimerEnabled = v
        if v then
            if timerLabel then timerLabel:Destroy() end
            timerLabel = Instance.new("TextLabel")
            timerLabel.Parent               = game:GetService("CoreGui"):FindFirstChildOfClass("ScreenGui") or Instance.new("ScreenGui", game:GetService("CoreGui"))
            timerLabel.BackgroundTransparency = 1
            timerLabel.TextColor3           = Color3.new(1, 1, 1)
            timerLabel.TextScaled           = true
            timerLabel.AnchorPoint          = Vector2.new(0.5, 0)
            timerLabel.Position             = UDim2.fromScale(0.5, 0.08)
            timerLabel.Size                 = UDim2.fromOffset(200, 40)
            timerLabel.Font                 = Enum.Font.GothamBold
            timerLabel.ZIndex               = 10

            timerTask = task.spawn(function()
                local remotes = game.ReplicatedStorage:FindFirstChild("Remotes")
                if not remotes then return end
                local extras = remotes:FindFirstChild("Extras")
                if not extras then return end
                local getTimer = extras:FindFirstChild("GetTimer")
                if not getTimer then return end

                while roundTimerEnabled and task.wait(0.5) do
                    local ok, t = pcall(function() return getTimer:InvokeServer() end)
                    if ok and timerLabel and timerLabel.Parent then
                        timerLabel.Text = secondsToMinutes(t)
                    end
                end
            end)
        else
            if timerLabel then timerLabel:Destroy(); timerLabel = nil end
            if timerTask then task.cancel(timerTask); timerTask = nil end
        end
    end,
})

S_Util:CreateButton({
    Name     = "Copy Murderer Username",
    Callback = function()
        local m = findMurderer()
        if not m then
            Lib:Notify({ Title = "MM2", Content = "No murderer detected.", Type = "Warning", Duration = 3 })
            return
        end
        if setclipboard then setclipboard(m.Name) end
        Lib:Notify({ Title = "MM2", Content = "Murderer: " .. m.Name .. " (copied)", Type = "Success", Duration = 3 })
    end,
})

S_Util:CreateButton({
    Name     = "Copy Sheriff Username",
    Callback = function()
        local s = findSheriff()
        if not s then
            Lib:Notify({ Title = "MM2", Content = "No sheriff detected.", Type = "Warning", Duration = 3 })
            return
        end
        if setclipboard then setclipboard(s.Name) end
        Lib:Notify({ Title = "MM2", Content = "Sheriff: " .. s.Name .. " (copied)", Type = "Success", Duration = 3 })
    end,
})

S_Util:CreateButton({
    Name     = "Send Roles to Chat",
    Callback = function()
        local textChannels = game:GetService("TextChatService"):WaitForChild("TextChannels"):GetChildren()
        local mName = findMurderer() and findMurderer().Name or "Unknown"
        local sName = findSheriff()  and findSheriff().Name  or "Unknown"
        local msg   = string.format("Murderer: %s | Sheriff: %s | <<SentenceHub>>", mName, sName)
        for _, ch in ipairs(textChannels) do
            if ch.Name ~= "RBXSystem" then
                pcall(function() ch:SendAsync(msg) end)
            end
        end
    end,
})

-- ════════════════════════════════════════════════════════════
-- TAB: Fun
-- ════════════════════════════════════════════════════════════
local S_Fun = TabFun:CreateSection("Fun / Trolling")

S_Fun:CreateButton({
    Name     = "Hold Everyone Hostage (Murderer)",
    Callback = function()
        if findMurderer() ~= LP then
            Lib:Notify({ Title = "MM2", Content = "Only useful as murderer.", Type = "Info", Duration = 3 })
        end
        local lpHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not lpHRP then return end
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl == LP or not pl.Character then continue end
            local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Anchored = true
                hrp.CFrame = lpHRP.CFrame + lpHRP.CFrame.LookVector * 5
            end
        end
        Lib:Notify({ Title = "MM2", Content = "Everyone gathered. Stab when ready.", Type = "Success", Duration = 4 })
    end,
})

S_Fun:CreateButton({
    Name     = "Fling Sheriff",
    Callback = function()
        local sheriff = findSheriff()
        if not sheriff then
            Lib:Notify({ Title = "MM2", Content = "No sheriff to fling.", Type = "Warning", Duration = 3 })
            return
        end
        -- Basic fling
        local lpHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local sHRP  = sheriff.Character and sheriff.Character:FindFirstChild("HumanoidRootPart")
        if not lpHRP or not sHRP then return end

        local bv = Instance.new("BodyVelocity")
        bv.Velocity  = Vector3.new(9e7, 9e7, 9e7)
        bv.MaxForce  = Vector3.new(1/0, 1/0, 1/0)
        bv.Parent    = lpHRP
        task.wait(0.05)
        bv:Destroy()

        Lib:Notify({ Title = "MM2", Content = "Flung sheriff!", Type = "Success", Duration = 2 })
    end,
})

S_Fun:CreateButton({
    Name     = "Fling Murderer",
    Callback = function()
        local murd = findMurderer()
        if not murd then
            Lib:Notify({ Title = "MM2", Content = "No murderer to fling.", Type = "Warning", Duration = 3 })
            return
        end
        local lpHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not lpHRP then return end

        local bv = Instance.new("BodyVelocity")
        bv.Velocity  = Vector3.new(9e7, 9e7, 9e7)
        bv.MaxForce  = Vector3.new(1/0, 1/0, 1/0)
        bv.Parent    = lpHRP
        task.wait(0.05)
        bv:Destroy()

        Lib:Notify({ Title = "MM2", Content = "Flung murderer!", Type = "Success", Duration = 2 })
    end,
})

-- ════════════════════════════════════════════════════════════
-- DONE
-- ════════════════════════════════════════════════════════════
print("[ SENTENCE ] MM2 v1.0 loaded — YARHM port by SentenceHub.")
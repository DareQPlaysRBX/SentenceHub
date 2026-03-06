-- ╔══════════════════════════════════════════════════════════════════╗
-- ║      SENTENCE Hub  ·  Rebirth Champions: Ultimate                ║
-- ║                      Game Script v2.0                            ║
-- ║      Requires SentenceLib v2.7 · Loaded via Loader              ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- ════════════════════════════════════════════════════════════
-- CONTEXT  (injected by Loader via _G)
-- ════════════════════════════════════════════════════════════
local Window = _G.Window
local Lib    = _G.Lib

assert(Window, "[ RCU ] Window not found in _G — run via Loader!")
assert(Lib,    "[ RCU ] Lib not found in _G — run via Loader!")

-- ════════════════════════════════════════════════════════════
-- SERVICES
-- ════════════════════════════════════════════════════════════
local RS             = game:GetService("ReplicatedStorage")
local Players        = game:GetService("Players")
local CollectionSvc  = game:GetService("CollectionService")
local RunService     = game:GetService("RunService")
local LP             = Players.LocalPlayer

-- ════════════════════════════════════════════════════════════
-- KNIT SHORTCUTS
-- ════════════════════════════════════════════════════════════
local Knit     = require(RS.Packages.Knit)
local Services = RS.Packages.Knit.Services

-- Obfuscated key used throughout the game's remote architecture
local KEY = utf8.char(
    106,97,103,32,107,228,110,110,101,114,32,101,110,32,98,111,
    116,44,32,104,111,110,32,104,101,116,101,114,32,97,110,110,
    97,44,32,97,110,110,97,32,104,101,116,101,114,32,104,111,110
)

-- ════════════════════════════════════════════════════════════
-- SHARED MODULES  (mirrors EggController.KnitInit)
-- ════════════════════════════════════════════════════════════
local SharedFn   = require(RS.Shared.Functions)   -- suffixes, formatTime, etc.
local SharedUtil = require(RS.Shared.Util)         -- eggUtils, petUtils, etc.
local SharedVals = require(RS.Shared.Values)       -- bestEggPrice, luck, etc.
local EggList    = require(RS.Shared.List.Pets.Eggs)
local PetList    = require(RS.Shared.List.Pets.Pets)

-- ════════════════════════════════════════════════════════════
-- KNIT CONTROLLERS / SERVICES  (resolved lazily, cached)
-- ════════════════════════════════════════════════════════════
local _DataCtrl, _EggSvc, _ClickSvc, _RebirthRF, _RewardsRF, _HatchSignal

local function getDataCtrl()
    if not _DataCtrl then
        _DataCtrl = Knit.GetController("DataController")
    end
    return _DataCtrl
end

-- Click remote  ── service[KEY].RE[KEY]
local function getClickRE()
    if not _ClickSvc then
        _ClickSvc = Services[KEY].RE[KEY]
    end
    return _ClickSvc
end

-- Auto-hatch signal  ── service[60].RE child[3].OnClientEvent  (firesignal)
local function getHatchSignal()
    if not _HatchSignal then
        _HatchSignal = Services:GetChildren()[60].RE:GetChildren()[3]
    end
    return _HatchSignal
end

-- Rebirth RF  ── service[43].RF[KEY]:InvokeServer(level 1-4)
local function getRebirthRF()
    if not _RebirthRF then
        _RebirthRF = Services:GetChildren()[43].RF[KEY]
    end
    return _RebirthRF
end

-- Rewards RF  ── service[56].RF child[19]:InvokeServer(milestone)
local function getRewardsRF()
    if not _RewardsRF then
        _RewardsRF = Services:GetChildren()[56].RF:GetChildren()[19]
    end
    return _RewardsRF
end

-- ════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════
local State = {
    -- Toggles
    AutoClick        = false,
    AutoHatch        = false,
    AutoRebirth      = false,
    AutoRewards      = false,
    AutoPlaytime     = false,
    AutoTeleportEgg  = false,

    -- Delays
    ClickDelay       = 0.05,
    HatchDelay       = 0.5,
    RebirthDelay     = 2.0,
    RewardsDelay     = 2.0,
    PlaytimeDelay    = 2.0,
    TeleportDelay    = 1.0,

    -- Hatch config  (matches firesignal payload)
    HatchEgg         = "Basic",   -- egg type string
    HatchPet         = "Dog",     -- pet name in payload
    HatchTier        = 1,         -- ti field
    HatchUseOpen2    = false,     -- open type: false=1x, true=max

    -- Rebirth config  1=1x 2=5x 3=10x 4=25x
    RebirthLevel     = 1,

    -- Egg teleport config
    TeleportEggName  = "",        -- set automatically when near an egg

    -- Internals
    Threads          = {},
}

local REBIRTH_LABELS = {
    "1x  (Level 1)",
    "5x  (Level 2)",
    "10x (Level 3)",
    "25x (Level 4)",
}

-- ════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════
local function SafeCall(fn, label)
    local ok, err = pcall(fn)
    if not ok then
        warn("[ RCU ] " .. (label or "?") .. " error: " .. tostring(err))
    end
end

local function StartLoop(key, fn, delayKey)
    if State.Threads[key] then
        task.cancel(State.Threads[key])
        State.Threads[key] = nil
    end
    State.Threads[key] = task.spawn(function()
        while State[key] do
            SafeCall(fn, key)
            task.wait(State[delayKey] or 0.5)
        end
    end)
end

local function StopLoop(key)
    if State.Threads[key] then
        task.cancel(State.Threads[key])
        State.Threads[key] = nil
    end
end

-- Find the closest tagged egg within 10 studs of the local player
local function getClosestEgg()
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local best, bestDist = nil, 10
    for _, model in ipairs(CollectionSvc:GetTagged("Egg")) do
        local eggPart = model:FindFirstChild("Egg")
        if eggPart and eggPart.PrimaryPart then
            local dist = (eggPart.PrimaryPart.Position - hrp.Position).Magnitude
            if dist <= bestDist then
                best     = model
                bestDist = dist
            end
        end
    end
    return best
end

-- Teleport to an egg model by name (mirrors EggController:teleportToEgg)
local function teleportToEgg(eggName)
    for _, model in ipairs(CollectionSvc:GetTagged("Egg")) do
        if model.Name == eggName
            and not model:GetAttribute("luckyEggId")
            and not model:GetAttribute("isBestEgg")
            and not model:GetAttribute("isMazeEgg")
        then
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            LP:RequestStreamAroundAsync(model:GetPivot().Position)
            hrp.Anchored = true

            local eggPrim = model:FindFirstChild("Egg") and model.Egg.PrimaryPart
            if eggPrim then
                hrp:PivotTo(eggPrim.CFrame + eggPrim.CFrame.LookVector * 5.5)
            else
                hrp:PivotTo(CFrame.new(model:GetPivot().Position) - Vector3.new(5.5, 1, 0))
            end

            task.delay(0.5, function()
                hrp.Anchored    = false
                hrp.AssemblyLinearVelocity = Vector3.zero
            end)
            return true
        end
    end
    return false
end

-- ════════════════════════════════════════════════════════════
-- CORE ACTION FUNCTIONS
-- ════════════════════════════════════════════════════════════

-- Auto Click
local function DoClick()
    getClickRE():FireServer()
end

-- Auto Hatch  (firesignal on the OnClientEvent of the hatch RE child)
-- Mirrors the Cobalt-generated payload exactly
local function DoHatch()
    firesignal(getHatchSignal().OnClientEvent,
        State.HatchEgg,
        {
            {
                cl = "pet",
                ti = State.HatchTier,
                nm = State.HatchPet,
            }
        },
        State.HatchUseOpen2 and 2 or 1   -- open type
    )
end

-- Auto Rebirth  (InvokeServer with level index 1-4)
local function DoRebirth()
    local result = getRebirthRF():InvokeServer(State.RebirthLevel)
    if result and result ~= "success" then
        warn("[ RCU ] Rebirth returned: " .. tostring(result))
    end
end

-- Auto Claim Rewards  (InvokeServer(1) on rewards RF)
local function DoRewards()
    local result = getRewardsRF():InvokeServer(1)
    if result and result ~= "success" then
        warn("[ RCU ] ClaimReward returned: " .. tostring(result))
    end
end

-- Auto Claim Playtime Rewards  (milestones 1-9, mirrors BGS pattern)
local function DoPlaytimeCycle()
    local rf = getRewardsRF()
    for i = 1, 9 do
        SafeCall(function()
            rf:InvokeServer(i)
        end, "ClaimPlaytime:" .. i)
        task.wait(0.15)
    end
end

-- Auto Teleport to nearest egg + start hatching  (mirrors teleportToEgg)
local function DoTeleportHatch()
    local eggName = State.TeleportEggName
    if eggName == "" then
        -- auto-detect nearest egg
        local closest = getClosestEgg()
        if closest then
            eggName = closest.Name
        end
    end
    if eggName == "" then return end
    teleportToEgg(eggName)
    task.wait(1.2)
    DoHatch()
end

-- ════════════════════════════════════════════════════════════
-- TOGGLE WRAPPERS
-- ════════════════════════════════════════════════════════════
local function ToggleClick(v)
    State.AutoClick = v
    if v then StartLoop("AutoClick", DoClick, "ClickDelay")
    else StopLoop("AutoClick") end
end

local function ToggleHatch(v)
    State.AutoHatch = v
    if v then StartLoop("AutoHatch", DoHatch, "HatchDelay")
    else StopLoop("AutoHatch") end
end

local function ToggleRebirth(v)
    State.AutoRebirth = v
    if v then StartLoop("AutoRebirth", DoRebirth, "RebirthDelay")
    else StopLoop("AutoRebirth") end
end

local function ToggleRewards(v)
    State.AutoRewards = v
    if v then StartLoop("AutoRewards", DoRewards, "RewardsDelay")
    else StopLoop("AutoRewards") end
end

local function TogglePlaytime(v)
    State.AutoPlaytime = v
    if v then StartLoop("AutoPlaytime", DoPlaytimeCycle, "PlaytimeDelay")
    else StopLoop("AutoPlaytime") end
end

local function ToggleTeleportEgg(v)
    State.AutoTeleportEgg = v
    if v then StartLoop("AutoTeleportEgg", DoTeleportHatch, "TeleportDelay")
    else StopLoop("AutoTeleportEgg") end
end

-- ════════════════════════════════════════════════════════════
-- NEARBY EGG TRACKER  (updates TeleportEggName passively)
-- ════════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    local closest = getClosestEgg()
    if closest then
        State.TeleportEggName = closest.Name
    end
end)

-- ════════════════════════════════════════════════════════════
-- UI
-- ════════════════════════════════════════════════════════════

-- ── TAB: Clicking ────────────────────────────────────────────────────────────
local TabClick = Window:CreateTab({
    Name      = "Clicking",
    Icon      = "rbxassetid://6031280882",
    ShowTitle = true,
})

local S_Click = TabClick:CreateSection("Auto Clicker")

S_Click:CreateToggle({
    Name         = "Auto Click",
    Description  = "Fires the click remote continuously",
    CurrentValue = false,
    Flag         = "AutoClick",
    Callback     = ToggleClick,
})

S_Click:CreateSlider({
    Name         = "Click Delay",
    Range        = { 0.01, 1 },
    Increment    = 0.01,
    CurrentValue = 0.05,
    Suffix       = "s",
    Flag         = "ClickDelay",
    Callback     = function(v) State.ClickDelay = v end,
})

S_Click:CreateButton({
    Name        = "Click Once",
    Description = "Fires a single click remote call right now",
    Callback    = function() DoClick() end,
})

-- ── TAB: Hatching ─────────────────────────────────────────────────────────────
local TabHatch = Window:CreateTab({
    Name      = "Hatching",
    Icon      = "rbxassetid://6031280882",
    ShowTitle = true,
})

local S_Hatch = TabHatch:CreateSection("Auto Hatch")

S_Hatch:CreateToggle({
    Name         = "Auto Hatch",
    Description  = "Fires hatch signal in a loop",
    CurrentValue = false,
    Flag         = "AutoHatch",
    Callback     = ToggleHatch,
})

S_Hatch:CreateInput({
    Name                     = "Egg Type",
    Description              = "Egg name sent in the hatch payload (e.g. Basic)",
    PlaceholderText          = "e.g. Basic",
    CurrentValue             = "Basic",
    RemoveTextAfterFocusLost = false,
    Flag                     = "HatchEgg",
    Callback                 = function(v)
        if v ~= "" then State.HatchEgg = v end
    end,
})

S_Hatch:CreateInput({
    Name                     = "Pet Name",
    Description              = "Pet nm field in payload (e.g. Dog)",
    PlaceholderText          = "e.g. Dog",
    CurrentValue             = "Dog",
    RemoveTextAfterFocusLost = false,
    Flag                     = "HatchPet",
    Callback                 = function(v)
        if v ~= "" then State.HatchPet = v end
    end,
})

S_Hatch:CreateSlider({
    Name         = "Pet Tier",
    Range        = { 1, 10 },
    Increment    = 1,
    CurrentValue = 1,
    Suffix       = "",
    Flag         = "HatchTier",
    Callback     = function(v) State.HatchTier = v end,
})

S_Hatch:CreateToggle({
    Name         = "Open Max Amount",
    Description  = "Uses open type 2 (max affordable) instead of 1",
    CurrentValue = false,
    Flag         = "HatchUseOpen2",
    Callback     = function(v) State.HatchUseOpen2 = v end,
})

S_Hatch:CreateSlider({
    Name         = "Hatch Delay",
    Range        = { 0.1, 5 },
    Increment    = 0.1,
    CurrentValue = 0.5,
    Suffix       = "s",
    Flag         = "HatchDelay",
    Callback     = function(v) State.HatchDelay = v end,
})

S_Hatch:CreateDivider()

local S_TeleHatch = TabHatch:CreateSection("Teleport & Hatch")

S_TeleHatch:CreateToggle({
    Name         = "Auto Teleport + Hatch",
    Description  = "Teleports to nearest egg then hatches in a loop",
    CurrentValue = false,
    Flag         = "AutoTeleportEgg",
    Callback     = ToggleTeleportEgg,
})

S_TeleHatch:CreateInput({
    Name                     = "Target Egg Name",
    Description              = "Leave blank to auto-detect nearest egg",
    PlaceholderText          = "e.g. Basic Egg  (blank = nearest)",
    CurrentValue             = "",
    RemoveTextAfterFocusLost = false,
    Flag                     = "TeleportEggName",
    Callback                 = function(v)
        State.TeleportEggName = v
    end,
})

S_TeleHatch:CreateSlider({
    Name         = "Teleport Loop Delay",
    Range        = { 0.5, 10 },
    Increment    = 0.5,
    CurrentValue = 1.0,
    Suffix       = "s",
    Flag         = "TeleportDelay",
    Callback     = function(v) State.TeleportDelay = v end,
})

S_TeleHatch:CreateButton({
    Name        = "Teleport to Nearest Egg",
    Description = "One-shot teleport to the closest tagged egg",
    Callback    = function()
        local closest = getClosestEgg()
        if closest then
            teleportToEgg(closest.Name)
        else
            Lib:Notify({
                Title    = "SENTENCE Hub",
                Content  = "No egg found within range.",
                Type     = "Warning",
                Duration = 3,
            })
        end
    end,
})

-- ── TAB: Rebirth ──────────────────────────────────────────────────────────────
local TabRebirth = Window:CreateTab({
    Name      = "Rebirth",
    Icon      = "rbxassetid://6031280882",
    ShowTitle = true,
})

local S_Rebirth = TabRebirth:CreateSection("Auto Rebirth")

S_Rebirth:CreateToggle({
    Name         = "Auto Rebirth",
    Description  = "Automatically rebirths at the selected multiplier",
    CurrentValue = false,
    Flag         = "AutoRebirth",
    Callback     = ToggleRebirth,
})

S_Rebirth:CreateDropdown({
    Name          = "Rebirth Level",
    Description   = "Multiplier sent to InvokeServer (1=1x, 2=5x, 3=10x, 4=25x)",
    Options       = REBIRTH_LABELS,
    CurrentOption = REBIRTH_LABELS[1],
    Flag          = "RebirthLevel",
    Callback      = function(v)
        for i, label in ipairs(REBIRTH_LABELS) do
            if label == v then State.RebirthLevel = i; break end
        end
    end,
})

S_Rebirth:CreateSlider({
    Name         = "Rebirth Delay",
    Range        = { 0.5, 15 },
    Increment    = 0.5,
    CurrentValue = 2.0,
    Suffix       = "s",
    Flag         = "RebirthDelay",
    Callback     = function(v) State.RebirthDelay = v end,
})

S_Rebirth:CreateButton({
    Name        = "Rebirth Once",
    Description = "Fires a single rebirth at the selected level right now",
    Callback    = function() DoRebirth() end,
})

-- ── TAB: Rewards ──────────────────────────────────────────────────────────────
local TabRewards = Window:CreateTab({
    Name      = "Rewards",
    Icon      = "rbxassetid://6031280882",
    ShowTitle = true,
})

local S_Rewards = TabRewards:CreateSection("Auto Claim Rewards")

S_Rewards:CreateToggle({
    Name         = "Auto Claim Rewards",
    Description  = "Loops reward claim RF in background",
    CurrentValue = false,
    Flag         = "AutoRewards",
    Callback     = ToggleRewards,
})

S_Rewards:CreateSlider({
    Name         = "Claim Delay",
    Range        = { 0.5, 10 },
    Increment    = 0.5,
    CurrentValue = 2.0,
    Suffix       = "s",
    Flag         = "RewardsDelay",
    Callback     = function(v) State.RewardsDelay = v end,
})

S_Rewards:CreateButton({
    Name        = "Claim Once",
    Description = "Fires a single reward claim right now",
    Callback    = function() DoRewards() end,
})

local S_PT = TabRewards:CreateSection("Playtime Rewards")

S_PT:CreateToggle({
    Name         = "Auto Claim Playtime",
    Description  = "Loops ClaimPlaytime milestones 1–9 in background",
    CurrentValue = false,
    Flag         = "AutoPlaytime",
    Callback     = TogglePlaytime,
})

S_PT:CreateSlider({
    Name         = "Playtime Loop Delay",
    Range        = { 1, 15 },
    Increment    = 0.5,
    CurrentValue = 2.0,
    Suffix       = "s",
    Flag         = "PlaytimeDelay",
    Callback     = function(v) State.PlaytimeDelay = v end,
})

S_PT:CreateButton({
    Name        = "Claim All Now",
    Description = "One-shot claim of all playtime milestones 1–9",
    Callback    = function() DoPlaytimeCycle() end,
})

-- ════════════════════════════════════════════════════════════
-- DONE
-- ════════════════════════════════════════════════════════════
print("[ SENTENCE ] Rebirth Champions: Ultimate script v2.0 — loaded.")

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║      SENTENCE Hub  ·  Rebirth Champions: Ultimate                ║
-- ║                      Game Script v1.0                            ║
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
-- SERVICES & SHORTCUTS
-- ════════════════════════════════════════════════════════════
local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LP      = Players.LocalPlayer

-- Knit service index shortcut
local Services = RS.Packages.Knit.Services

-- Obfuscated remote key (shared across services)
local KEY = utf8.char(
    106, 97, 103, 32, 107, 228, 110, 110, 101, 114, 32, 101, 110, 32, 98, 111,
    116, 44, 32, 104, 111, 110, 32, 104, 101, 116, 101, 114, 32, 97, 110, 110,
    97, 44, 32, 97, 110, 110, 97, 32, 104, 101, 116, 101, 114, 32, 104, 111, 110
)

-- ════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════
local State = {
    -- toggles
    AutoClick   = false,
    AutoHatch   = false,
    AutoRebirth = false,
    AutoRewards = false,

    -- config
    ClickDelay   = 0.05,   -- seconds between clicks
    HatchEgg     = "Basic",
    HatchPet     = "Dog",
    HatchTier    = 1,
    HatchDelay   = 0.5,
    RebirthLevel = 1,      -- 1=1x, 2=5x, 3=10x, 4=25x
    RebirthDelay = 2.0,
    RewardsDelay = 2.0,

    -- internals
    Threads = {},
}

-- Rebirth multiplier display map
local REBIRTH_LABELS = { "1x (Level 1)", "5x (Level 2)", "10x (Level 3)", "25x (Level 4)" }

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

-- ════════════════════════════════════════════════════════════
-- REMOTE RESOLVERS  (lazy, cached on first use)
-- ════════════════════════════════════════════════════════════
local _clickRE, _hatchSignal, _rebirthRF, _rewardsRF

local function getClickRE()
    if not _clickRE then
        _clickRE = Services[KEY].RE[KEY]
    end
    return _clickRE
end

local function getHatchSignal()
    -- Index [60] → child [3] of its RE folder
    if not _hatchSignal then
        _hatchSignal = Services:GetChildren()[60].RE:GetChildren()[3]
    end
    return _hatchSignal
end

local function getRebirthRF()
    -- Index [43] → RF[KEY]
    if not _rebirthRF then
        _rebirthRF = Services:GetChildren()[43].RF[KEY]
    end
    return _rebirthRF
end

local function getRewardsRF()
    -- Index [56] → RF child [19]
    if not _rewardsRF then
        _rewardsRF = Services:GetChildren()[56].RF:GetChildren()[19]
    end
    return _rewardsRF
end

-- ════════════════════════════════════════════════════════════
-- CORE ACTION FUNCTIONS
-- ════════════════════════════════════════════════════════════

-- Auto Clicker — fires the obfuscated click RE
local function DoClick()
    getClickRE():FireServer()
end

-- Auto Hatch — firesignal the hatch OnClientEvent
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
        1
    )
end

-- Auto Rebirth — InvokeServer with level (1–4)
local function DoRebirth()
    local result = getRebirthRF():InvokeServer(State.RebirthLevel)
    if result ~= "success" then
        warn("[ RCU ] Rebirth returned: " .. tostring(result))
    end
end

-- Auto Claim Rewards — InvokeServer(1) on rewards RF
local function DoRewards()
    local result = getRewardsRF():InvokeServer(1)
    if result ~= "success" then
        warn("[ RCU ] ClaimReward returned: " .. tostring(result))
    end
end

-- Auto Claim Playtime Rewards (from RewardsFrame decompile)
-- Uses the same RF but iterates milestones 1–9 (same pattern as BGS)
local function DoPlaytimeRewards()
    local rf = getRewardsRF()
    for i = 1, 9 do
        SafeCall(function()
            rf:InvokeServer(i)
        end, "ClaimPlaytime:" .. i)
        task.wait(0.15)
    end
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
    Description = "Fires a single click remote call",
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
    Description  = "Fires hatch signal continuously",
    CurrentValue = false,
    Flag         = "AutoHatch",
    Callback     = ToggleHatch,
})

S_Hatch:CreateInput({
    Name                     = "Egg Type",
    Description              = "Egg name sent with hatch signal (e.g. Basic)",
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
    Description              = "Pet name inside the hatch payload (e.g. Dog)",
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

S_Hatch:CreateSlider({
    Name         = "Hatch Delay",
    Range        = { 0.1, 5 },
    Increment    = 0.1,
    CurrentValue = 0.5,
    Suffix       = "s",
    Flag         = "HatchDelay",
    Callback     = function(v) State.HatchDelay = v end,
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
    Description  = "Automatically rebirths at the selected level",
    CurrentValue = false,
    Flag         = "AutoRebirth",
    Callback     = ToggleRebirth,
})

S_Rebirth:CreateDropdown({
    Name          = "Rebirth Level",
    Description   = "Multiplier tier to use when rebirthing",
    Options       = REBIRTH_LABELS,
    CurrentOption = REBIRTH_LABELS[1],
    Flag          = "RebirthLevel",
    Callback      = function(v)
        -- map label back to index 1–4
        for i, label in ipairs(REBIRTH_LABELS) do
            if label == v then
                State.RebirthLevel = i
                break
            end
        end
    end,
})

S_Rebirth:CreateSlider({
    Name         = "Rebirth Delay",
    Range        = { 0.5, 10 },
    Increment    = 0.5,
    CurrentValue = 2.0,
    Suffix       = "s",
    Flag         = "RebirthDelay",
    Callback     = function(v) State.RebirthDelay = v end,
})

S_Rebirth:CreateButton({
    Name        = "Rebirth Once",
    Description = "Performs a single rebirth at the selected level",
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
    Description  = "Claims rewards via RF in a loop",
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

S_PT:CreateButton({
    Name        = "Claim Playtime Rewards",
    Description = "One-shot claim of milestones 1–9",
    Callback    = function() DoPlaytimeRewards() end,
})

-- ════════════════════════════════════════════════════════════
-- DONE
-- ════════════════════════════════════════════════════════════
print("[ SENTENCE ] Rebirth Champions: Ultimate script v1.0 — loaded.")

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║        SENTENCE Hub  ·  Bubble Gum Simulator INFINITY            ║
-- ║                        Game Script v1.0                          ║
-- ╚══════════════════════════════════════════════════════════════════╝
-- This file is loaded automatically by the Loader when PlaceId matches.
-- Do NOT run this file standalone — use the Loader.

-- ════════════════════════════════════════════════════════════
-- SERVICES & SHORTCUTS
-- ════════════════════════════════════════════════════════════
local RS          = game:GetService("ReplicatedStorage")
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local LP          = Players.LocalPlayer

local Shared      = RS.Shared.Framework.Network.Remote
local RE          = Shared.RemoteEvent       -- FireServer
local RF          = Shared.RemoteFunction    -- InvokeServer
local PickupRE    = RS.Remotes.Pickups.CollectPickup
local SpawnRE     = RS.Remotes.Pickups.SpawnPickups

-- ════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════
local State = {
    -- Toggles
    AutoBlow         = false,
    AutoSell         = false,
    AutoHatch        = false,
    AutoSpin         = false,
    AutoPickup       = false,
    AutoBlackMarket  = false,
    AutoPlaytime     = false,

    -- Config
    HatchEggName     = "Iceshard Egg",
    HatchAmount      = 1,
    BlowDelay        = 0.1,
    SellDelay        = 0.5,
    HatchDelay       = 0.5,
    SpinDelay        = 1.0,
    PickupDelay      = 0.1,
    BlackMarketDelay = 1.0,
    PlaytimeDelay    = 2.0,
    BlackMarketSlot  = 2,

    -- Pickup zone path
    PickupZonePath   = "The Overworld/Islands/The Void/Island/Pickups/Zone",
    PickupVisual     = "Coin Box",

    -- Internal
    Threads          = {},
    CollectedIds     = {},
}

-- ════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════
local function SafeCall(fn, label)
    local ok, err = pcall(fn)
    if not ok then
        warn("[ BGS ] " .. label .. " error: " .. tostring(err))
    end
end

local function StartLoop(key, fn, delay)
    if State.Threads[key] then
        task.cancel(State.Threads[key])
        State.Threads[key] = nil
    end
    State.Threads[key] = task.spawn(function()
        while State[key] do
            SafeCall(fn, key)
            task.wait(delay and State[delay] or 0.5)
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
-- CORE FUNCTIONS
-- ════════════════════════════════════════════════════════════

-- Auto Blow Bubble
local function DoBlow()
    RE:FireServer("BlowBubble")
end

-- Auto Sell Bubble
local function DoSell()
    RE:FireServer("SellBubble")
end

-- Auto Hatch Egg
local function DoHatch()
    RE:FireServer(table.unpack({
        [1] = "HatchEgg",
        [2] = State.HatchEggName,
        [3] = State.HatchAmount,
    }))
end

-- Auto Spin Wheel (claim queue first, then invoke spin)
local function DoSpin()
    RE:FireServer("ClaimLunarYearWheelSpinQueue")
    task.wait(0.3)
    RF:InvokeServer("LunarWheelSpin")
end

-- Auto Collect Pickups (firesignal approach)
local function DoPickup()
    -- Resolve the zone from path
    local ok, zone = pcall(function()
        local worlds = workspace:FindFirstChild("Worlds")
        if not worlds then return nil end
        local parts = State.PickupZonePath:split("/")
        local obj = worlds
        for _, part in ipairs(parts) do
            obj = obj:FindFirstChild(part)
            if not obj then return nil end
        end
        return obj
    end)

    if not ok or not zone then return end

    -- Collect all existing pickup children
    for _, child in ipairs(zone:GetChildren()) do
        local id = child.Name  -- pickup GUIDs are usually the instance name
        if not State.CollectedIds[id] then
            State.CollectedIds[id] = true
            SafeCall(function()
                PickupRE:FireServer(id)
            end, "CollectPickup:" .. id)
        end
    end

    -- Also firesignal to spawn + collect a new pickup batch
    SafeCall(function()
        local newId = game:GetService("HttpService"):GenerateGUID(false):lower()
        firesignal(SpawnRE.OnClientEvent, {
            [1] = {
                ["Root"]   = zone,
                ["Visual"] = State.PickupVisual,
                ["Id"]     = newId,
            },
        })
        task.wait(0.05)
        PickupRE:FireServer(newId)
    end, "SpawnPickup")
end

-- Auto Black Market (BuyShopItem)
local function DoBlackMarket()
    RE:FireServer(table.unpack({
        [1] = "BuyShopItem",
        [2] = "shard-shop",
        [3] = State.BlackMarketSlot,
        [4] = false,
    }))
end

-- Auto Playtime Rewards (claim 1–9)
local function DoPlaytime()
    for i = 1, 9 do
        SafeCall(function()
            RF:InvokeServer(table.unpack({
                [1] = "ClaimPlaytime",
                [2] = i,
            }))
        end, "ClaimPlaytime:" .. i)
        task.wait(0.15)
    end
end

-- ════════════════════════════════════════════════════════════
-- TOGGLE HANDLERS
-- ════════════════════════════════════════════════════════════
local function ToggleBlow(v)
    State.AutoBlow = v
    if v then StartLoop("AutoBlow", DoBlow, "BlowDelay")
    else StopLoop("AutoBlow") end
end

local function ToggleSell(v)
    State.AutoSell = v
    if v then StartLoop("AutoSell", DoSell, "SellDelay")
    else StopLoop("AutoSell") end
end

local function ToggleHatch(v)
    State.AutoHatch = v
    if v then StartLoop("AutoHatch", DoHatch, "HatchDelay")
    else StopLoop("AutoHatch") end
end

local function ToggleSpin(v)
    State.AutoSpin = v
    if v then StartLoop("AutoSpin", DoSpin, "SpinDelay")
    else StopLoop("AutoSpin") end
end

local function TogglePickup(v)
    State.AutoPickup = v
    State.CollectedIds = {}  -- reset cache on toggle
    if v then StartLoop("AutoPickup", DoPickup, "PickupDelay")
    else StopLoop("AutoPickup") end
end

local function ToggleBlackMarket(v)
    State.AutoBlackMarket = v
    if v then StartLoop("AutoBlackMarket", DoBlackMarket, "BlackMarketDelay")
    else StopLoop("AutoBlackMarket") end
end

local function TogglePlaytime(v)
    State.AutoPlaytime = v
    if v then StartLoop("AutoPlaytime", DoPlaytime, "PlaytimeDelay")
    else StopLoop("AutoPlaytime") end
end

-- ════════════════════════════════════════════════════════════
-- UI — TABS
-- ════════════════════════════════════════════════════════════

-- ── Tab: Bubble ──────────────────────────────────────────────
local TabBubble = Window:CreateTab({ Name = "Bubble", Icon = "rbxassetid://6031280882", ShowTitle = true })

local S_Blow = TabBubble:CreateSection("Blow & Sell")

S_Blow:CreateToggle({
    Name     = "Auto Blow Bubble",
    Default  = false,
    Callback = ToggleBlow,
})

S_Blow:CreateSlider({
    Name    = "Blow Delay (s)",
    Min     = 0.05,
    Max     = 2,
    Default = 0.1,
    Increment = 0.05,
    Callback = function(v) State.BlowDelay = v end,
})

S_Blow:CreateToggle({
    Name     = "Auto Sell Bubble",
    Default  = false,
    Callback = ToggleSell,
})

S_Blow:CreateSlider({
    Name    = "Sell Delay (s)",
    Min     = 0.1,
    Max     = 3,
    Default = 0.5,
    Increment = 0.1,
    Callback = function(v) State.SellDelay = v end,
})

-- ── Tab: Eggs ────────────────────────────────────────────────
local TabEggs = Window:CreateTab({ Name = "Eggs", Icon = "rbxassetid://6031280882", ShowTitle = true })

local S_Hatch = TabEggs:CreateSection("Auto Hatch")

S_Hatch:CreateToggle({
    Name     = "Auto Hatch Egg",
    Default  = false,
    Callback = ToggleHatch,
})

S_Hatch:CreateInput({
    Name        = "Egg Name",
    Default     = "Iceshard Egg",
    PlaceholderText = "e.g. Iceshard Egg",
    RemoveTextAfterFocusLost = false,
    Callback    = function(v)
        State.HatchEggName = v
    end,
})

S_Hatch:CreateSlider({
    Name    = "Hatch Amount",
    Min     = 1,
    Max     = 10,
    Default = 1,
    Increment = 1,
    Callback = function(v) State.HatchAmount = v end,
})

S_Hatch:CreateSlider({
    Name    = "Hatch Delay (s)",
    Min     = 0.1,
    Max     = 3,
    Default = 0.5,
    Increment = 0.1,
    Callback = function(v) State.HatchDelay = v end,
})

-- ── Tab: World ───────────────────────────────────────────────
local TabWorld = Window:CreateTab({ Name = "World", Icon = "rbxassetid://6031280882", ShowTitle = true })

local S_Pickup = TabWorld:CreateSection("Auto Collect Pickups")

S_Pickup:CreateToggle({
    Name     = "Auto Collect Pickups",
    Default  = false,
    Callback = TogglePickup,
})

S_Pickup:CreateInput({
    Name        = "Pickup Zone Path",
    Default     = State.PickupZonePath,
    PlaceholderText = "World/Islands/.../Zone",
    RemoveTextAfterFocusLost = false,
    Callback    = function(v)
        State.PickupZonePath = v
        State.CollectedIds = {}
    end,
})

S_Pickup:CreateInput({
    Name        = "Visual Type",
    Default     = "Coin Box",
    PlaceholderText = "e.g. Coin Box",
    RemoveTextAfterFocusLost = false,
    Callback    = function(v) State.PickupVisual = v end,
})

S_Pickup:CreateSlider({
    Name    = "Pickup Delay (s)",
    Min     = 0.05,
    Max     = 2,
    Default = 0.1,
    Increment = 0.05,
    Callback = function(v) State.PickupDelay = v end,
})

-- ── Tab: Events ──────────────────────────────────────────────
local TabEvents = Window:CreateTab({ Name = "Events", Icon = "rbxassetid://6031280882", ShowTitle = true })

local S_Spin = TabEvents:CreateSection("Lunar Wheel")

S_Spin:CreateToggle({
    Name     = "Auto Spin Wheel",
    Default  = false,
    Callback = ToggleSpin,
})

S_Spin:CreateSlider({
    Name    = "Spin Delay (s)",
    Min     = 0.5,
    Max     = 5,
    Default = 1.0,
    Increment = 0.5,
    Callback = function(v) State.SpinDelay = v end,
})

local S_PT = TabEvents:CreateSection("Playtime Rewards")

S_PT:CreateToggle({
    Name     = "Auto Claim Playtime (1–9)",
    Default  = false,
    Callback = TogglePlaytime,
})

S_PT:CreateSlider({
    Name    = "Claim Loop Delay (s)",
    Min     = 1,
    Max     = 10,
    Default = 2,
    Increment = 0.5,
    Callback = function(v) State.PlaytimeDelay = v end,
})

S_PT:CreateButton({
    Name     = "Claim Now (once)",
    Callback = function() DoPlaytime() end,
})

-- ── Tab: Shop ────────────────────────────────────────────────
local TabShop = Window:CreateTab({ Name = "Shop", Icon = "rbxassetid://6031280882", ShowTitle = true })

local S_BM = TabShop:CreateSection("Black Market")

S_BM:CreateToggle({
    Name     = "Auto Buy Black Market",
    Default  = false,
    Callback = ToggleBlackMarket,
})

S_BM:CreateSlider({
    Name    = "Shop Slot (1–5)",
    Min     = 1,
    Max     = 5,
    Default = 2,
    Increment = 1,
    Callback = function(v) State.BlackMarketSlot = v end,
})

S_BM:CreateSlider({
    Name    = "Buy Delay (s)",
    Min     = 0.5,
    Max     = 5,
    Default = 1.0,
    Increment = 0.5,
    Callback = function(v) State.BlackMarketDelay = v end,
})

S_BM:CreateButton({
    Name     = "Buy Slot Once",
    Callback = function() DoBlackMarket() end,
})

-- ════════════════════════════════════════════════════════════
-- NOTIFY
-- ════════════════════════════════════════════════════════════
print("[ SENTENCE ] Bubble Gum Simulator INFINITY script v1.0 — loaded.")

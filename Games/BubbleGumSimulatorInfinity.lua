-- ╔══════════════════════════════════════════════════════════════════╗
-- ║        SENTENCE Hub  ·  Bubble Gum Simulator INFINITY            ║
-- ║                        Game Script v2.0                          ║
-- ║        Requires SentenceLib v2.7 · Loaded via Loader             ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- CONTEXT  (injected by Loader via _G)
-- ════════════════════════════════════════════════════════════
local Window = _G.Window
local Lib    = _G.Lib

assert(Window, "[ BGS ] Window not found in _G — run via Loader!")
assert(Lib,    "[ BGS ] Lib not found in _G — run via Loader!")

-- SERVICES & REMOTES
-- ════════════════════════════════════════════════════════════
local RS         = game:GetService("ReplicatedStorage")
local Players    = game:GetService("Players")
local HttpSvc    = game:GetService("HttpService")
local LP         = Players.LocalPlayer

local Shared     = RS.Shared.Framework.Network.Remote
local RE         = Shared.RemoteEvent       -- :FireServer(...)
local RF         = Shared.RemoteFunction    -- :InvokeServer(...)
local PickupRE   = RS.Remotes.Pickups.CollectPickup
local SpawnRE    = RS.Remotes.Pickups.SpawnPickups

-- ════════════════════════════════════════════════════════════
-- STATE  (single source of truth for all feature config)
-- ════════════════════════════════════════════════════════════
local State = {
    -- feature switches (driven by toggles)
    AutoBlow        = false,
    AutoSell        = false,
    AutoHatch       = false,
    AutoSpin        = false,
    AutoPickup      = false,
    AutoBlackMarket = false,
    AutoPlaytime    = false,

    -- delays (seconds)
    BlowDelay        = 0.1,
    SellDelay        = 0.5,
    HatchDelay       = 0.5,
    SpinDelay        = 1.0,
    PickupDelay      = 0.1,
    BlackMarketDelay = 1.0,
    PlaytimeDelay    = 2.0,

    -- hatch config
    HatchEggName  = "Iceshard Egg",
    HatchAmount   = 1,

    -- black market config
    BlackMarketSlot = 2,

    -- pickup config
    PickupZonePath = "The Overworld/Islands/The Void/Island/Pickups/Zone",
    PickupVisual   = "Coin Box",

    -- internals
    Threads      = {},
    CollectedIds = {},
}

-- ════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════
local function SafeCall(fn, label)
    local ok, err = pcall(fn)
    if not ok then
        warn("[ BGS ] " .. (label or "?") .. " error: " .. tostring(err))
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
-- CORE ACTION FUNCTIONS
-- ════════════════════════════════════════════════════════════
local function DoBlow()
    RE:FireServer("BlowBubble")
end

local function DoSell()
    RE:FireServer("SellBubble")
end

local function DoHatch()
    RE:FireServer(table.unpack({
        [1] = "HatchEgg",
        [2] = State.HatchEggName,
        [3] = State.HatchAmount,
    }))
end

local function DoSpin()
    RE:FireServer("ClaimLunarYearWheelSpinQueue")
    task.wait(0.3)
    RF:InvokeServer("LunarWheelSpin")
end

local function DoPickup()
    local ok, zone = pcall(function()
        local worlds = workspace:FindFirstChild("Worlds")
        if not worlds then return nil end
        local obj = worlds
        for _, part in ipairs(State.PickupZonePath:split("/")) do
            obj = obj:FindFirstChild(part)
            if not obj then return nil end
        end
        return obj
    end)
    if not ok or not zone then return end

    for _, child in ipairs(zone:GetChildren()) do
        local id = child.Name
        if not State.CollectedIds[id] then
            State.CollectedIds[id] = true
            SafeCall(function() PickupRE:FireServer(id) end, "CollectPickup")
        end
    end

    SafeCall(function()
        local newId = HttpSvc:GenerateGUID(false):lower()
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

local function DoBlackMarket()
    RE:FireServer(table.unpack({
        [1] = "BuyShopItem",
        [2] = "shard-shop",
        [3] = State.BlackMarketSlot,
        [4] = false,
    }))
end

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
-- TOGGLE WRAPPERS
-- ════════════════════════════════════════════════════════════
local function ToggleBlow(v)
    State.AutoBlow = v
    if v then StartLoop("AutoBlow", DoBlow, "BlowDelay") else StopLoop("AutoBlow") end
end
local function ToggleSell(v)
    State.AutoSell = v
    if v then StartLoop("AutoSell", DoSell, "SellDelay") else StopLoop("AutoSell") end
end
local function ToggleHatch(v)
    State.AutoHatch = v
    if v then StartLoop("AutoHatch", DoHatch, "HatchDelay") else StopLoop("AutoHatch") end
end
local function ToggleSpin(v)
    State.AutoSpin = v
    if v then StartLoop("AutoSpin", DoSpin, "SpinDelay") else StopLoop("AutoSpin") end
end
local function TogglePickup(v)
    State.AutoPickup = v
    State.CollectedIds = {}
    if v then StartLoop("AutoPickup", DoPickup, "PickupDelay") else StopLoop("AutoPickup") end
end
local function ToggleBlackMarket(v)
    State.AutoBlackMarket = v
    if v then StartLoop("AutoBlackMarket", DoBlackMarket, "BlackMarketDelay") else StopLoop("AutoBlackMarket") end
end
local function TogglePlaytime(v)
    State.AutoPlaytime = v
    if v then StartLoop("AutoPlaytime", DoPlaytime, "PlaytimeDelay") else StopLoop("AutoPlaytime") end
end

-- ════════════════════════════════════════════════════════════
-- UI  —  Window is provided by the Loader as `Window`
-- ════════════════════════════════════════════════════════════

-- ── TAB: Bubble ──────────────────────────────────────────────────────────────
local TabBubble = Window:CreateTab({
    Name      = "Bubble",
    Icon      = "rbxassetid://6031280882",
    ShowTitle = true,
})

local S_Blow = TabBubble:CreateSection("Blow & Sell")

S_Blow:CreateToggle({
    Name         = "Auto Blow Bubble",
    Description  = "Continuously fires BlowBubble remote",
    CurrentValue = false,
    Flag         = "AutoBlow",
    Callback     = ToggleBlow,
})

S_Blow:CreateSlider({
    Name         = "Blow Delay",
    Range        = { 0.05, 2 },
    Increment    = 0.05,
    CurrentValue = 0.1,
    Suffix       = "s",
    Flag         = "BlowDelay",
    Callback     = function(v) State.BlowDelay = v end,
})

S_Blow:CreateDivider()

S_Blow:CreateToggle({
    Name         = "Auto Sell Bubble",
    Description  = "Continuously fires SellBubble remote",
    CurrentValue = false,
    Flag         = "AutoSell",
    Callback     = ToggleSell,
})

S_Blow:CreateSlider({
    Name         = "Sell Delay",
    Range        = { 0.1, 3 },
    Increment    = 0.1,
    CurrentValue = 0.5,
    Suffix       = "s",
    Flag         = "SellDelay",
    Callback     = function(v) State.SellDelay = v end,
})

-- ── TAB: Eggs ─────────────────────────────────────────────────────────────────
local TabEggs = Window:CreateTab({
    Name      = "Eggs",
    Icon      = "rbxassetid://6031280882",
    ShowTitle = true,
})

local S_Hatch = TabEggs:CreateSection("Auto Hatch")

S_Hatch:CreateToggle({
    Name         = "Auto Hatch Egg",
    Description  = "Sends HatchEgg remote in a loop",
    CurrentValue = false,
    Flag         = "AutoHatch",
    Callback     = ToggleHatch,
})

S_Hatch:CreateInput({
    Name                     = "Egg Name",
    Description              = "Exact in-game name of the egg",
    PlaceholderText          = "e.g. Iceshard Egg",
    CurrentValue             = "Iceshard Egg",
    RemoveTextAfterFocusLost = false,
    Flag                     = "HatchEggName",
    Callback                 = function(v)
        if v ~= "" then State.HatchEggName = v end
    end,
})

S_Hatch:CreateSlider({
    Name         = "Hatch Amount",
    Range        = { 1, 10 },
    Increment    = 1,
    CurrentValue = 1,
    Suffix       = "x",
    Flag         = "HatchAmount",
    Callback     = function(v) State.HatchAmount = v end,
})

S_Hatch:CreateSlider({
    Name         = "Hatch Delay",
    Range        = { 0.1, 3 },
    Increment    = 0.1,
    CurrentValue = 0.5,
    Suffix       = "s",
    Flag         = "HatchDelay",
    Callback     = function(v) State.HatchDelay = v end,
})

-- ── TAB: World ────────────────────────────────────────────────────────────────
local TabWorld = Window:CreateTab({
    Name      = "World",
    Icon      = "rbxassetid://6031280882",
    ShowTitle = true,
})

local S_Pickup = TabWorld:CreateSection("Auto Collect Pickups")

S_Pickup:CreateToggle({
    Name         = "Auto Collect Pickups",
    Description  = "Collects pickups inside the specified zone",
    CurrentValue = false,
    Flag         = "AutoPickup",
    Callback     = TogglePickup,
})

S_Pickup:CreateInput({
    Name                     = "Zone Path",
    Description              = "Path inside workspace.Worlds/... to Pickups Zone",
    PlaceholderText          = "The Overworld/Islands/The Void/Island/Pickups/Zone",
    CurrentValue             = "The Overworld/Islands/The Void/Island/Pickups/Zone",
    RemoveTextAfterFocusLost = false,
    Flag                     = "PickupZonePath",
    Callback                 = function(v)
        if v ~= "" then
            State.PickupZonePath = v
            State.CollectedIds   = {}
        end
    end,
})

S_Pickup:CreateInput({
    Name                     = "Visual Type",
    Description              = "Visual identifier sent with SpawnPickups signal",
    PlaceholderText          = "e.g. Coin Box",
    CurrentValue             = "Coin Box",
    RemoveTextAfterFocusLost = false,
    Flag                     = "PickupVisual",
    Callback                 = function(v)
        if v ~= "" then State.PickupVisual = v end
    end,
})

S_Pickup:CreateSlider({
    Name         = "Pickup Delay",
    Range        = { 0.05, 2 },
    Increment    = 0.05,
    CurrentValue = 0.1,
    Suffix       = "s",
    Flag         = "PickupDelay",
    Callback     = function(v) State.PickupDelay = v end,
})

-- ── TAB: Events ───────────────────────────────────────────────────────────────
local TabEvents = Window:CreateTab({
    Name      = "Events",
    Icon      = "rbxassetid://6031280882",
    ShowTitle = true,
})

local S_Spin = TabEvents:CreateSection("Lunar New Year Wheel")

S_Spin:CreateToggle({
    Name         = "Auto Spin Wheel",
    Description  = "Claims spin queue then invokes LunarWheelSpin",
    CurrentValue = false,
    Flag         = "AutoSpin",
    Callback     = ToggleSpin,
})

S_Spin:CreateSlider({
    Name         = "Spin Delay",
    Range        = { 0.5, 10 },
    Increment    = 0.5,
    CurrentValue = 1.0,
    Suffix       = "s",
    Flag         = "SpinDelay",
    Callback     = function(v) State.SpinDelay = v end,
})

S_Spin:CreateButton({
    Name        = "Spin Once",
    Description = "Fires a single wheel spin right now",
    Callback    = function() DoSpin() end,
})

local S_PT = TabEvents:CreateSection("Playtime Rewards")

S_PT:CreateToggle({
    Name         = "Auto Claim Playtime",
    Description  = "Loops ClaimPlaytime for milestones 1 through 9",
    CurrentValue = false,
    Flag         = "AutoPlaytime",
    Callback     = TogglePlaytime,
})

S_PT:CreateSlider({
    Name         = "Claim Loop Delay",
    Range        = { 1, 15 },
    Increment    = 0.5,
    CurrentValue = 2.0,
    Suffix       = "s",
    Flag         = "PlaytimeDelay",
    Callback     = function(v) State.PlaytimeDelay = v end,
})

S_PT:CreateButton({
    Name        = "Claim All Now",
    Description = "One-shot: claims milestones 1–9 immediately",
    Callback    = function() DoPlaytime() end,
})

-- ── TAB: Shop ─────────────────────────────────────────────────────────────────
local TabShop = Window:CreateTab({
    Name      = "Shop",
    Icon      = "rbxassetid://6031280882",
    ShowTitle = true,
})

local S_BM = TabShop:CreateSection("Black Market")

S_BM:CreateToggle({
    Name         = "Auto Buy Black Market",
    Description  = "Buys the selected slot from shard-shop in a loop",
    CurrentValue = false,
    Flag         = "AutoBlackMarket",
    Callback     = ToggleBlackMarket,
})

S_BM:CreateDropdown({
    Name          = "Shop Slot",
    Description   = "Which item slot to purchase (1 = first listing)",
    Options       = { "1", "2", "3", "4", "5" },
    CurrentOption = "2",
    Flag          = "BlackMarketSlot",
    Callback      = function(v)
        State.BlackMarketSlot = tonumber(v) or 2
    end,
})

S_BM:CreateSlider({
    Name         = "Buy Delay",
    Range        = { 0.5, 10 },
    Increment    = 0.5,
    CurrentValue = 1.0,
    Suffix       = "s",
    Flag         = "BlackMarketDelay",
    Callback     = function(v) State.BlackMarketDelay = v end,
})

S_BM:CreateButton({
    Name        = "Buy Slot Once",
    Description = "Fires a single BuyShopItem call right now",
    Callback    = function() DoBlackMarket() end,
})

-- ════════════════════════════════════════════════════════════
-- DONE
-- ════════════════════════════════════════════════════════════
print("[ SENTENCE ] BGS INFINITY script v2.0 — loaded.")

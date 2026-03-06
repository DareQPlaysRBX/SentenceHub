-- ════════════════════════════════════════════════════════════
-- LIBRARY
-- ════════════════════════════════════════════════════════════
local Lib = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/DareQPlaysRBX/SentenceHub/refs/heads/main/SentenceLibTest.lua"
))()

-- ════════════════════════════════════════════════════════════
-- SERVICES
-- ════════════════════════════════════════════════════════════
local RS         = game:GetService("RunService")
local Players    = game:GetService("Players")
local RepStorage = game:GetService("ReplicatedStorage")
local LP         = Players.LocalPlayer

-- ════════════════════════════════════════════════════════════
-- GAME REGISTRY  (PlaceId → script URL)
-- ════════════════════════════════════════════════════════════
local SUPPORTED_GAMES = {
    [2753915549] = {
        name   = "Blox Fruits",
        url    = "https://raw.githubusercontent.com/DareQPlaysRBX/SentenceHub/refs/heads/main/Games/BloxFruits.lua",
        config = "bloxfruits",
    },
    [142823291]  = {
        name   = "Murder Mystery 2",
        url    = "https://raw.githubusercontent.com/DareQPlaysRBX/SentenceHub/refs/heads/main/Games/MurderMystery2.lua",
        config = "mm2",
    },
    [1962086868] = {
        name   = "Pet Simulator X",
        url    = "https://raw.githubusercontent.com/DareQPlaysRBX/SentenceHub/refs/heads/main/Games/PetSimX.lua",
        config = "petsimx",
    },
}

-- ════════════════════════════════════════════════════════════
-- AUTO-DETECTION
-- ════════════════════════════════════════════════════════════
local placeId   = game.PlaceId
local gameData  = SUPPORTED_GAMES[placeId]
local isSupported = gameData ~= nil

local GAME_NAME   = isSupported and gameData.name   or "Universal"
local CONFIG_FILE = isSupported and gameData.config  or "universal"

-- ════════════════════════════════════════════════════════════
-- MAIN WINDOW
-- ════════════════════════════════════════════════════════════
local Window = Lib:CreateWindow({
    Name            = "SENTENCE Hub",
    Subtitle        = isSupported and ("Game: " .. GAME_NAME) or "Universal Mode",
    Icon            = "117810891565979",
    LoadingEnabled  = true,
    LoadingTitle    = "SENTENCE HUB",
    LoadingSubtitle = isSupported
        and ("Loading " .. GAME_NAME .. " script…")
        or  "Loading Universal script…",
    ToggleBind      = Enum.KeyCode.RightControl,
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "SentenceHub",
        FileName   = CONFIG_FILE,
    },
})

-- ════════════════════════════════════════════════════════════
-- HOME TAB
-- ════════════════════════════════════════════════════════════
local Home = Window:CreateHomeTab({ Icon = "rbxassetid://117810891565979" })

-- Welcome section
local S_Welcome = Home:CreateSection("Welcome")
S_Welcome:CreateLabel({ Name = "SENTENCE Hub  ·  " .. GAME_NAME .. " Script", Style = 2 })
S_Welcome:CreateLabel({ Name = "Toggle UI:  RightControl  ·  Config auto-saved on teleport" })

if isSupported then
    S_Welcome:CreateLabel({ Name = "✔  Supported game detected — full feature set active." })
else
    S_Welcome:CreateLabel({ Name = "⚠  Unsupported game — running in Universal mode." })
    S_Welcome:CreateLabel({ Name = "Place ID: " .. tostring(placeId) })
end

-- Changelog section
local S_CL = Home:CreateSection("Changelog")
S_CL:CreateLabel({ Name = "v2.0 — Auto game-detection, per-game config saving." })
S_CL:CreateLabel({ Name = "v1.0 — Initial universal release." })

-- Credits section
local S_Cred = Home:CreateSection("Credits")
S_Cred:CreateLabel({ Name = "Developer:   DareQPlaysRBX",           Style = 2 })
S_Cred:CreateLabel({ Name = "Library:       SentenceLib  v2.6"                })
S_Cred:CreateLabel({ Name = "GitHub:        DareQPlaysRBX/SentenceHub"        })
S_Cred:CreateLabel({ Name = "Discord:       discord.gg/gQt5WeS5kn"            })

-- ════════════════════════════════════════════════════════════
-- GAME-SPECIFIC SCRIPT LOADER
-- ════════════════════════════════════════════════════════════
if isSupported then
    -- ── Supported game: load dedicated script ──────────────
    print("[ SENTENCE ] Detected supported game: " .. GAME_NAME .. " (PlaceId: " .. placeId .. ")")

    local success, err = pcall(function()
        loadstring(game:HttpGet(gameData.url))()
    end)

    if not success then
        warn("[ SENTENCE ] Failed to load game script for " .. GAME_NAME .. ": " .. tostring(err))

        Lib:Notify({
            Title    = "SENTENCE Hub",
            Content  = "Failed to load " .. GAME_NAME .. " script. Falling back to Universal.",
            Type     = "Error",
            Duration = 6,
        })

        -- Fallback: show universal tab
        local TabMain = Window:CreateTab({ Name = "Auto Farm", Icon = "rbxassetid://6031280882", ShowTitle = true })
    end

else
    -- ── Unsupported game: Universal tab ───────────────────
    print("[ SENTENCE ] Unsupported game (PlaceId: " .. placeId .. ") — Universal mode.")

    local TabMain = Window:CreateTab({ Name = "Auto Farm", Icon = "rbxassetid://6031280882", ShowTitle = true })

    -- You can add universal features here, e.g.:
    -- local S_Movement = TabMain:CreateSection("Movement")
    -- S_Movement:CreateToggle({ Name = "Infinite Jump", ... })
end

-- ════════════════════════════════════════════════════════════
-- WELCOME NOTIFICATION
-- ════════════════════════════════════════════════════════════
task.wait(1)

if isSupported then
    Lib:Notify({
        Title    = "SENTENCE Hub",
        Content  = GAME_NAME .. " script loaded! Press RightControl to toggle UI.",
        Type     = "Success",
        Duration = 5,
    })
else
    Lib:Notify({
        Title    = "SENTENCE Hub",
        Content  = "Universal Script loaded — game not supported yet. Press RightControl to toggle UI.",
        Type     = "Info",
        Duration = 6,
    })
end

print(string.format(
    "[ SENTENCE ] Loader v2.0 — %s | PlaceId: %d | Config: %s",
    GAME_NAME, placeId, CONFIG_FILE
))

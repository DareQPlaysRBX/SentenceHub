local Lib = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/DareQPlaysRBX/SentenceHub/refs/heads/main/SentenceUI.lua"
))()

-- ════════════════════════════════════════════════════════════
-- SERVICES
-- ════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local LP      = Players.LocalPlayer

-- ════════════════════════════════════════════════════════════
-- GAME REGISTRY
-- ════════════════════════════════════════════════════════════
local SUPPORTED_GAMES = {
    [85896571713843] = {
        name   = "Bubble Gum Simulator INFINITY",
        url    = "https://raw.githubusercontent.com/DareQPlaysRBX/SentenceHub/refs/heads/main/Games/Bubblegumsimulatorinfinity.lua",
        config = "bgs-infinity",
    },
    [142823291] = {
        name   = "Murder Mystery 2",
        url    = "https://raw.githubusercontent.com/DareQPlaysRBX/SentenceHub/refs/heads/main/Games/MurderMystery2.lua",
        config = "bgs-infinity",
    },
}

-- ════════════════════════════════════════════════════════════
-- AUTO-DETECTION
-- ════════════════════════════════════════════════════════════
local placeId     = game.PlaceId
local gameData    = SUPPORTED_GAMES[placeId]
local isSupported = gameData ~= nil

local GAME_NAME   = isSupported and gameData.name   or "Universal"
local CONFIG_FILE = isSupported and gameData.config  or "universal"
local SCRIPT_URL  = isSupported
    and gameData.url
    or  "https://raw.githubusercontent.com/DareQPlaysRBX/SentenceHub/refs/heads/main/Games/Universal.lua"

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
        and ("Loading " .. GAME_NAME .. " script...")
        or  "Loading Universal script...",
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

local S_Welcome = Home:CreateSection("Welcome")
S_Welcome:CreateLabel({ Name = "SENTENCE Hub  ·  " .. GAME_NAME .. " Script", Style = 2 })
S_Welcome:CreateLabel({ Name = "Toggle UI:  RightControl" })

if isSupported then
    S_Welcome:CreateLabel({ Name = "Supported game detected — full feature set active." })
else
    S_Welcome:CreateLabel({ Name = "Unsupported game — Universal mode loaded automatically." })
    S_Welcome:CreateLabel({ Name = "Place ID: " .. tostring(placeId) })
    S_Welcome:CreateLabel({ Name = "Main & Visuals tabs contain all universal features." })
end

local S_CL = Home:CreateSection("Changelog")
S_CL:CreateLabel({ Name = "v3.0 — Universal script is now a separate file, auto-loaded." })
S_CL:CreateLabel({ Name = "v2.3 — OG Sentence theme, Corner boxes default, scaled fonts." })
S_CL:CreateLabel({ Name = "v2.2 — ESP rewrite: Highlight chams, modern boxes." })
S_CL:CreateLabel({ Name = "v2.1 — Universal ESP (Visuals tab) added." })
S_CL:CreateLabel({ Name = "v2.0 — Auto game-detection, per-game config saving." })

local S_Cred = Home:CreateSection("Credits")
S_Cred:CreateLabel({ Name = "Developer: DareQPlaysRBX",         Style = 2 })
S_Cred:CreateLabel({ Name = "Library: SentenceLib  v2.6"               })
S_Cred:CreateLabel({ Name = "GitHub: DareQPlaysRBX/SentenceHub"        })
S_Cred:CreateLabel({ Name = "Discord: discord.gg/gQt5WeS5kn"           })

-- ════════════════════════════════════════════════════════════
-- SCRIPT LOADER
-- ════════════════════════════════════════════════════════════
print(string.format(
    "[ SENTENCE ] Loader v3.0 | PlaceId: %d | Mode: %s | Config: %s",
    placeId, GAME_NAME, CONFIG_FILE
))

_G.Window = Window
_G.Lib    = Lib

local success, err = pcall(function()
    loadstring(game:HttpGet(SCRIPT_URL))()
end)

_G.Window = nil
_G.Lib    = nil

if not success then
    warn("[ SENTENCE ] Script load failed: " .. tostring(err))

    Lib:Notify({
        Title    = "SENTENCE Hub",
        Content  = "Failed to load " .. GAME_NAME .. " script. Check HTTP settings.",
        Type     = "Error",
        Duration = 6,
    })

    -- Fallback do Universal tylko jeśli załadowany game script się wywalił
    if isSupported then
        warn("[ SENTENCE ] Falling back to Universal...")

        _G.Window = Window
        _G.Lib    = Lib

        local ok2, err2 = pcall(function()
            loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/DareQPlaysRBX/SentenceHub/refs/heads/main/Games/Universal.lua"
            ))()
        end)

        _G.Window = nil
        _G.Lib    = nil

        if not ok2 then
            warn("[ SENTENCE ] Universal fallback also failed: " .. tostring(err2))
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- WELCOME NOTIFICATION
-- ════════════════════════════════════════════════════════════
task.wait(1)

if success then
    Lib:Notify({
        Title    = "SENTENCE Hub",
        Content  = isSupported
            and (GAME_NAME .. " script loaded! Press RightControl to toggle UI.")
            or  "Universal Script loaded! Press RightControl to toggle UI.",
        Type     = isSupported and "Success" or "Info",
        Duration = 5,
    })
end

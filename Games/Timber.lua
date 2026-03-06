-- ╔══════════════════════════════════════════════════════════════════╗
-- ║        SENTENCE Hub  ·  Timber                                   ║
-- ║                        Game Script v1.0                          ║
-- ║        Requires SentenceLib v2.7 · Loaded via Loader             ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- CONTEXT  (injected by Loader via _G)
-- ════════════════════════════════════════════════════════════
local Window = _G.Window
local Lib    = _G.Lib

assert(Window, "[ TIMBER ] Window not found in _G — run via Loader!")
assert(Lib,    "[ TIMBER ] Lib not found in _G — run via Loader!")

-- SERVICES
-- ════════════════════════════════════════════════════════════
local RS         = game:GetService("ReplicatedStorage")
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer
local Char       = LP.Character or LP.CharacterAdded:Wait()
local HRP        = Char:WaitForChild("HumanoidRootPart")
local Humanoid   = Char:WaitForChild("Humanoid")

-- REMOTES
-- ════════════════════════════════════════════════════════════
local ByteNet    = RS:WaitForChild("ByteNetReliable")

-- ════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════
local State = {
    -- feature switches
    AutoChop        = false,
    AutoPlant       = false,
    AutoReturn      = false,

    -- delays
    ChopDelay       = 0.1,
    PlantDelay      = 1.0,
    ReturnDelay     = 0.5,

    -- chop config
    ChopOffset      = Vector3.new(0, 0, -3),   -- how close to teleport to tree
    HitsPerTree     = 10,                       -- swings before moving to next
    TreeTypes       = { "oak", "birch", "pine", "redoak" }, -- prefixes to farm

    -- plant config
    PlotPath        = "",   -- e.g. "DareQPlaysRBX"  (workspace child name)
    PlantTreeName   = "Red Oak",

    -- internals
    Threads         = {},
    CurrentTree     = nil,
    TreeIndex       = 1,
    OriginalCFrame  = nil,
}

-- ════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════
local function SafeCall(fn, label)
    local ok, err = pcall(fn)
    if not ok then
        warn("[ TIMBER ] " .. (label or "?") .. " error: " .. tostring(err))
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

-- Teleport to a position safely (respects noclip workaround)
local function TeleportTo(cf)
    if HRP and HRP.Parent then
        HRP.CFrame = cf
        task.wait(0.05)
    end
end

-- ════════════════════════════════════════════════════════════
-- TREE UTILITIES
-- ════════════════════════════════════════════════════════════

-- Returns a list of all valid tree models in Workspace.Trees
local function GetTrees()
    local treesFolder = workspace:FindFirstChild("Trees")
    if not treesFolder then return {} end

    local list = {}
    for _, obj in ipairs(treesFolder:GetChildren()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            -- Filter by configured prefixes
            local nameLower = obj.Name:lower()
            local valid = false
            for _, prefix in ipairs(State.TreeTypes) do
                if nameLower:find(prefix:lower(), 1, true) then
                    valid = true
                    break
                end
            end
            if valid then
                table.insert(list, obj)
            end
        end
    end
    return list
end

-- Get the world CFrame of a tree (uses PrimaryPart or first BasePart)
local function GetTreeCFrame(tree)
    if tree:IsA("Model") then
        local primary = tree.PrimaryPart
        if primary then return primary.CFrame end
        local part = tree:FindFirstChildWhichIsA("BasePart")
        if part then return part.CFrame end
    elseif tree:IsA("BasePart") then
        return tree.CFrame
    end
    return nil
end

-- ════════════════════════════════════════════════════════════
-- CORE ACTION FUNCTIONS
-- ════════════════════════════════════════════════════════════

-- Simulate a single axe swing via tool activation
-- Since chop buffers are dynamic (generated server-side per swing),
-- we activate the equipped tool so the server generates the buffer itself.
local function SwingAxe()
    local tool = Char:FindFirstChildWhichIsA("Tool")
    if not tool then
        -- Also check backpack
        tool = LP.Backpack:FindFirstChildWhichIsA("Tool")
        if tool then
            -- Equip the tool
            Humanoid:EquipTool(tool)
            task.wait(0.2)
        else
            warn("[ TIMBER ] No tool found — equip an axe!")
            return
        end
    end

    -- Activate the tool (triggers server-side chop event with correct buffer)
    local handle = tool:FindFirstChild("Handle")
    if handle then
        -- Fire tool activation remotely through the tool's own remote if present
        local toolRemote = tool:FindFirstChildWhichIsA("RemoteEvent")
        if toolRemote then
            SafeCall(function() toolRemote:FireServer() end, "ToolRemote")
        end
    end

    -- Also trigger via UserInputService simulation path
    SafeCall(function()
        tool:Activate()
    end, "ToolActivate")
end

-- Move to next available tree in the folder
local function MoveToNextTree()
    local trees = GetTrees()
    if #trees == 0 then
        warn("[ TIMBER ] No trees found in Workspace.Trees!")
        return false
    end

    -- Advance index, wrap around
    State.TreeIndex = State.TreeIndex % #trees + 1
    local tree = trees[State.TreeIndex]

    local cf = GetTreeCFrame(tree)
    if not cf then return false end

    -- Teleport slightly in front of the tree
    local targetCF = cf * CFrame.new(State.ChopOffset)
    TeleportTo(targetCF)

    State.CurrentTree = tree
    return true
end

-- Main chop loop tick
local function DoChop()
    -- Refresh character reference (respawn safe)
    Char = LP.Character
    if not Char then return end
    HRP       = Char:FindFirstChild("HumanoidRootPart")
    Humanoid  = Char:FindFirstChild("Humanoid")
    if not HRP or not Humanoid then return end

    -- Ensure we have a target tree
    if not State.CurrentTree or not State.CurrentTree.Parent then
        MoveToNextTree()
        return
    end

    -- Check if tree still exists (cut down = removed from folder)
    if not State.CurrentTree.Parent then
        task.wait(0.3)
        MoveToNextTree()
        return
    end

    -- Teleport close to tree every tick to stay in hit range
    local cf = GetTreeCFrame(State.CurrentTree)
    if cf then
        TeleportTo(cf * CFrame.new(State.ChopOffset))
    end

    -- Swing
    SwingAxe()
end

-- Plant tree on player's plot
local function DoPlant()
    local plotPath = State.PlotPath
    if plotPath == "" then
        warn("[ TIMBER ] Plot path is empty — set it in the Plant tab!")
        return
    end

    local plot = workspace:FindFirstChild(plotPath)
    if not plot then
        warn("[ TIMBER ] Plot '" .. plotPath .. "' not found in workspace!")
        return
    end

    local treeObj = plot:FindFirstChild(State.PlantTreeName)
    if not treeObj then
        warn("[ TIMBER ] Tree '" .. State.PlantTreeName .. "' not found on plot!")
        return
    end

    -- Send plant/grow remote (matches the format from your provided data)
    SafeCall(function()
        ByteNet:FireServer(table.unpack({
            [1] = buffer.create(8),  -- grow buffer placeholder
            [2] = {
                [1] = treeObj,
            },
        }))
    end, "DoPlant")
end

-- Return to original spawn position
local function DoReturn()
    if State.OriginalCFrame then
        TeleportTo(State.OriginalCFrame)
    else
        warn("[ TIMBER ] No saved position — save your position first!")
    end
end

-- ════════════════════════════════════════════════════════════
-- TOGGLE WRAPPERS
-- ════════════════════════════════════════════════════════════
local function ToggleChop(v)
    State.AutoChop = v
    if v then
        -- Save current position before starting
        if HRP then
            State.OriginalCFrame = HRP.CFrame
        end
        MoveToNextTree()
        StartLoop("AutoChop", DoChop, "ChopDelay")
    else
        StopLoop("AutoChop")
    end
end

local function TogglePlant(v)
    State.AutoPlant = v
    if v then StartLoop("AutoPlant", DoPlant, "PlantDelay") else StopLoop("AutoPlant") end
end

local function ToggleReturn(v)
    State.AutoReturn = v
    if v then
        DoReturn()
        State.AutoReturn = false
    end
end

-- ════════════════════════════════════════════════════════════
-- UI
-- ════════════════════════════════════════════════════════════

-- ── TAB: Chop ─────────────────────────────────────────────────────────────────
local TabChop = Window:CreateTab({
    Name      = "Chop",
    Icon      = "rbxassetid://6031280882",
    ShowTitle = true,
})

local S_Farm = TabChop:CreateSection("Auto Chop Trees")

S_Farm:CreateToggle({
    Name         = "Auto Chop",
    Description  = "Teleports to each tree and swings axe automatically",
    CurrentValue = false,
    Flag         = "AutoChop",
    Callback     = ToggleChop,
})

S_Farm:CreateSlider({
    Name         = "Chop Delay",
    Range        = { 0.05, 2 },
    Increment    = 0.05,
    CurrentValue = 0.1,
    Suffix       = "s",
    Flag         = "ChopDelay",
    Callback     = function(v) State.ChopDelay = v end,
})

S_Farm:CreateDivider()

local S_TreeFilter = TabChop:CreateSection("Tree Filter")

S_TreeFilter:CreateInput({
    Name                     = "Tree Types (comma separated)",
    Description              = "Tree name prefixes to farm, e.g: oak,birch,pine",
    PlaceholderText          = "oak,birch,pine,redoak",
    CurrentValue             = "oak,birch,pine,redoak",
    RemoveTextAfterFocusLost = false,
    Flag                     = "TreeTypes",
    Callback                 = function(v)
        if v ~= "" then
            local types = {}
            for part in v:gmatch("[^,]+") do
                table.insert(types, part:match("^%s*(.-)%s*$")) -- trim spaces
            end
            if #types > 0 then
                State.TreeTypes = types
            end
        end
    end,
})

S_TreeFilter:CreateSlider({
    Name         = "Chop Offset (studs)",
    Range        = { 1, 8 },
    Increment    = 0.5,
    CurrentValue = 3,
    Suffix       = " st",
    Flag         = "ChopOffsetDist",
    Callback     = function(v)
        State.ChopOffset = Vector3.new(0, 0, -v)
    end,
})

S_TreeFilter:CreateButton({
    Name        = "Move to Next Tree",
    Description = "Manually teleports to the next tree in queue",
    Callback    = function() MoveToNextTree() end,
})

-- ── TAB: Plant ────────────────────────────────────────────────────────────────
local TabPlant = Window:CreateTab({
    Name      = "Plant",
    Icon      = "rbxassetid://6031280882",
    ShowTitle = true,
})

local S_Plant = TabPlant:CreateSection("Auto Plant (Your Plot)")

S_Plant:CreateToggle({
    Name         = "Auto Plant Trees",
    Description  = "Sends grow remote for trees on your plot",
    CurrentValue = false,
    Flag         = "AutoPlant",
    Callback     = TogglePlant,
})

S_Plant:CreateInput({
    Name                     = "Plot Name",
    Description              = "Exact name of your plot in workspace (e.g. DareQPlaysRBX)",
    PlaceholderText          = "e.g. DareQPlaysRBX",
    CurrentValue             = "",
    RemoveTextAfterFocusLost = false,
    Flag                     = "PlotPath",
    Callback                 = function(v)
        if v ~= "" then State.PlotPath = v end
    end,
})

S_Plant:CreateInput({
    Name                     = "Tree Name",
    Description              = "Exact name of the tree object on your plot",
    PlaceholderText          = "e.g. Red Oak",
    CurrentValue             = "Red Oak",
    RemoveTextAfterFocusLost = false,
    Flag                     = "PlantTreeName",
    Callback                 = function(v)
        if v ~= "" then State.PlantTreeName = v end
    end,
})

S_Plant:CreateSlider({
    Name         = "Plant Delay",
    Range        = { 0.5, 10 },
    Increment    = 0.5,
    CurrentValue = 1.0,
    Suffix       = "s",
    Flag         = "PlantDelay",
    Callback     = function(v) State.PlantDelay = v end,
})

S_Plant:CreateButton({
    Name        = "Plant Once",
    Description = "Fires a single grow remote right now",
    Callback    = function() DoPlant() end,
})

-- ── TAB: Utils ────────────────────────────────────────────────────────────────
local TabUtils = Window:CreateTab({
    Name      = "Utils",
    Icon      = "rbxassetid://6031280882",
    ShowTitle = true,
})

local S_Pos = TabUtils:CreateSection("Position Manager")

S_Pos:CreateButton({
    Name        = "Save Current Position",
    Description = "Saves your current location to return to later",
    Callback    = function()
        Char = LP.Character
        if Char then
            HRP = Char:FindFirstChild("HumanoidRootPart")
            if HRP then
                State.OriginalCFrame = HRP.CFrame
                print("[ TIMBER ] Position saved: " .. tostring(HRP.Position))
            end
        end
    end,
})

S_Pos:CreateButton({
    Name        = "Return to Saved Position",
    Description = "Teleports back to your saved position",
    Callback    = function() DoReturn() end,
})

S_Pos:CreateDivider()

local S_Debug = TabUtils:CreateSection("Debug")

S_Debug:CreateButton({
    Name        = "Print Tree List",
    Description = "Prints all found trees to console",
    Callback    = function()
        local trees = GetTrees()
        print("[ TIMBER ] Found " .. #trees .. " trees:")
        for i, tree in ipairs(trees) do
            print("  [" .. i .. "] " .. tree.Name)
        end
    end,
})

S_Debug:CreateButton({
    Name        = "Print Current Tree",
    Description = "Prints the currently targeted tree",
    Callback    = function()
        if State.CurrentTree and State.CurrentTree.Parent then
            print("[ TIMBER ] Current target: " .. State.CurrentTree.Name)
        else
            print("[ TIMBER ] No tree currently targeted.")
        end
    end,
})

-- ════════════════════════════════════════════════════════════
-- CHARACTER RESPAWN HANDLER
-- ════════════════════════════════════════════════════════════
LP.CharacterAdded:Connect(function(newChar)
    Char     = newChar
    HRP      = newChar:WaitForChild("HumanoidRootPart")
    Humanoid = newChar:WaitForChild("Humanoid")

    -- Restart active loops after respawn
    task.wait(1)
    if State.AutoChop then
        MoveToNextTree()
        StartLoop("AutoChop", DoChop, "ChopDelay")
    end
    if State.AutoPlant then
        StartLoop("AutoPlant", DoPlant, "PlantDelay")
    end
end)

-- ════════════════════════════════════════════════════════════
-- DONE
-- ════════════════════════════════════════════════════════════
print("[ SENTENCE ] TIMBER script v1.0 — loaded.")

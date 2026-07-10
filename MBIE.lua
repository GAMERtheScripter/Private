-- auto0.6 – Refactored variable management
-- Grouped into tables to stay well below Roblox's 200-local limit.
-- Logic identical to original.

-- ── Load Fluent UI library (bulletproof multi‑URL loader) ────────
local Fluent = loadstring(game:HttpGet(
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
))()

-- ── Services ─────────────────────────────────────────────────
local Services = {
    RunService           = game:GetService("RunService"),
    UserInputService     = game:GetService("UserInputService"),
    ProximityPrompt      = game:GetService("ProximityPromptService")
}

-- ── Remote events ────────────────────────────────────────────
local Remotes = {}
Remotes.meleeHit       = game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("meleeHitRemote")
Remotes.collect        = game:GetService("ReplicatedStorage"):WaitForChild("Engine"):WaitForChild("Service"):WaitForChild("ItemCollect"):WaitForChild("collectRemote")
Remotes.dropItem       = game:GetService("ReplicatedStorage"):WaitForChild("Engine"):WaitForChild("Service"):WaitForChild("PlayerInventory"):WaitForChild("dropItemRemote")
Remotes.escape         = game:GetService("ReplicatedStorage"):WaitForChild("Engine"):WaitForChild("Service"):WaitForChild("GameResult"):WaitForChild("escapeRemote")
Remotes.LobbyTeleport  = game:GetService("ReplicatedStorage"):WaitForChild("Module"):WaitForChild("ActiveService"):WaitForChild("LobbyTeleport"):WaitForChild("RemoteEvent")
Remotes.RequestOpenChest = game:GetService("ReplicatedStorage"):WaitForChild("Engine"):WaitForChild("Service"):WaitForChild("ChestService"):WaitForChild("RequestOpenEvent")
-- addWoodRemote & matchmaking remotes are set later in their respective sections.

-- ── Collectable item name lists ──────────────────────────────
local Names = {
    Wood        = { "Log", "Wood", "Madeira", "Trunk" },
    Coco        = { "Coconut", "Coco" },
    Egg         = { "Egg", "Ovo" },
    CookedEgg   = { "Cooked Egg" },
    Meat        = { "Meat", "Carne" },
    CookedMeat  = { "Cooked Meat" },
    Stone       = { "Stone", "Rock", "Pedra" },
    BearPelt    = { "Bear Pelt" },
    Feather     = { "Chicken Feather" },
    Crab        = { "Crab" },
    CookedCrab  = { "Cooked Crab" },
    IronOre     = { "Iron Ore" },
    RedBerries  = { "Red Berries" },
    SnakeTooth  = { "Snake Tooth" },
    SpiderWeb   = { "Spider Web" },
    IronIngot   = { "Iron Ingot" }
}

-- ── Script state (all booleans & numbers) ─────────────────────
local State = {
    VIPCutAllTrees        = false,
    VIPBreakAllIronStones = false,
    VIPBreakAllStones     = false,
    VIPBreakAllBushes     = false,
    AutoCutTree           = true,
    TreeRange             = 35,

    AutoCollectAll        = false,
    CollectWood           = false,
    CollectCoco           = false,
    CollectEgg            = false,
    CollectCookedEgg      = false,
    CollectMeat           = false,
    CollectCookedMeat     = false,
    CollectStone          = false,
    CollectBearPelt       = false,
    CollectFeather        = false,
    CollectCrab           = false,
    CollectCookedCrab     = false,
    CollectIronOre        = false,
    CollectRedBerries     = false,
    CollectSnakeTooth     = false,
    CollectSpiderWeb      = false,
    CollectIronIngot      = false,

    AutoKill              = true,
    KillRange             = 35,

    AutoOpenCollect       = false,
    AutoQuestEnabled      = false,
    ESPEnabled            = false,

    NoclipEnabled         = false,
    TPWalkEnabled         = false,
    TPWalkSpeed           = 3,
    JumpPowerEnabled      = false,
    JumpPowerValue        = 40,
    FlyEnabled            = false,
    FlySpeed              = 50,
    -- DoNotEscape 
    DoNotEscape           = false,

    -- Collector limits (mutable from sliders)
    CollectToolLimit      = 1,
    CollectResLimit       = 5,
    CollectFoodLimit      = 5
}

-- ── UI element references (toggles, sliders, paragraphs) ─────
local Toggles = {}
local GUIRefs = {}

-- ── Constant lists for collection / equipping / dropping ─────
local Lists = {
    Tools     = {
        "Wooden Axe", "Stone Axe", "Iron Axe",
        "Wooden Pickaxe", "Stone Pickaxe", "Iron Pickaxe",
        "Wooden Spear", "Stone Spear", "Iron Spear", "Golden Spear",
        "Slingshot", "Pistol", "Shotgun", "Crossbow",
        "Blue Fire Wand", "Red Fire Wand", "Purple Fire Wand",
        "Vampire Sword", "Vampiric Scimitar", "Flame Blade",
        "Torch", "Fishing Rod"
    },
    Resources = { "Stone", "Wood", "Iron Ore", "Iron Ingot", "Bear Pelt", "Chicken Feather", "Grass", "Plastic Bucket", "Snake Tooth", "Spider Web" },
    Food      = { "Bandage", "Coconut", "Cooked Crab", "Cooked Egg", "Cooked Fish", "Cooked Meat", "Crab", "Egg", "Fish", "Meat", "Red Berries" },

    -- Equip priorities
    AxePrior     = {"Iron Axe", "Stone Axe", "Wooden Axe"},
    PickPrior    = {"Iron Pickaxe", "Stone Pickaxe", "Wooden Pickaxe"},
    SpearPrior   = {"Golden Spear", "Iron Spear", "Stone Spear", "Wooden Spear"},
    GunPrior     = {"Shotgun", "Pistol", "Slingshot", "Crossbow"},
    WandPrior    = {"Purple Fire Wand", "Red Fire Wand", "Blue Fire Wand"},
    SwordPrior   = {"Vampiric Scimitar", "Vampire Sword", "Flame Blade"},
    WeaponPrior  = {"Shotgun", "Pistol", "Slingshot", "Crossbow", "Vampiric Scimitar", "Vampire Sword", "Flame Blade", "Golden Spear", "Iron Spear", "Iron Pickaxe", "Iron Axe", "Stone Spear", "Stone Pickaxe", "Stone Axe", "Wooden Spear", "Wooden Pickaxe", "Wooden Axe"}
}

-- ── Collector state (queues, toggle‑tables, running flags) ───
local Collector = {
    Tool = {
        Toggles = {},
        Queue   = {},
        Running = false,
        LimitSlider = nil
    },
    Res = {
        Toggles = {},
        Queue   = {},
        Running = false,
        LimitSlider = nil
    },
    Food = {
        Toggles = {},
        Queue   = {},
        Running = false,
        LimitSlider = nil
    }
}

-- ── Mobile‑UI / Fly globals ───────────────────────────────────
local Mobile = {
    flyKeyDown = nil,
    flyKeyUp   = nil,
    mobileFlyConnection = nil,
    FLYING     = false
}

-- ── Auto‑build state ─────────────────────────────────────────
local Build = {
    AutoBuildEnabled   = false,
    AutoBuildThread    = nil,
    furnacePrepared    = false,
    boatWoodStoneDone  = false,
    treeCuttingDone    = false,
    ironStoneBreakingDone = false,
    autoOpenCollectDone = false,
    autoQuestDone      = false,

    -- Furnace teleport offsets
    TargetFurnacePart  = "SuckArea",
    OFFSET_X = 5,  OFFSET_Y = 0,  OFFSET_Z = 3,
    ROTATE_X = 0,  ROTATE_Y = 0,  ROTATE_Z = 0
}

-- ── VIP farming parameters ────────────────────────────────────
local VIP = {
    FarmTargetAmount = 25,
    FarmAmountSlider = nil,
    TreeNames    = {"Tree", "Coconut Tree", "Cocunut Tree"},
    IronStoneNames = {"Iron Stone"},
    StoneNames   = {"Stone"},
    BushNames    = {"Bush"}
}

-- ── Helpers ──────────────────────────────────────────────────
Services.ProximityPrompt.PromptButtonHoldBegan:Connect(function(prompt)
    pcall(function()
        prompt.HoldDuration = 0
        prompt:InputHoldBegin()
        task.spawn(function()
            task.wait(0.05)
            prompt:InputHoldEnd()
        end)
    end)
end)
Services.ProximityPrompt.PromptTriggered:Connect(function(prompt)
    print("[PoC] Prompt Triggered (instant):", prompt:GetFullName())
end)

local function tableContains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then return true end
    end
    return false
end

local function shouldCollect(itemName)
    if State.AutoCollectAll then return true end
    if State.CollectWood       and tableContains(Names.Wood,       itemName) then return true end
    if State.CollectCoco       and tableContains(Names.Coco,       itemName) then return true end
    if State.CollectEgg        and tableContains(Names.Egg,        itemName) then return true end
    if State.CollectCookedEgg  and tableContains(Names.CookedEgg,  itemName) then return true end
    if State.CollectMeat       and tableContains(Names.Meat,       itemName) then return true end
    if State.CollectCookedMeat and tableContains(Names.CookedMeat, itemName) then return true end
    if State.CollectStone      and tableContains(Names.Stone,      itemName) then return true end
    if State.CollectBearPelt   and tableContains(Names.BearPelt,   itemName) then return true end
    if State.CollectFeather    and tableContains(Names.Feather,    itemName) then return true end
    if State.CollectCrab       and tableContains(Names.Crab,       itemName) then return true end
    if State.CollectCookedCrab and tableContains(Names.CookedCrab, itemName) then return true end
    if State.CollectIronOre    and tableContains(Names.IronOre,    itemName) then return true end
    if State.CollectRedBerries and tableContains(Names.RedBerries, itemName) then return true end
    if State.CollectSnakeTooth and tableContains(Names.SnakeTooth, itemName) then return true end
    if State.CollectSpiderWeb  and tableContains(Names.SpiderWeb,  itemName) then return true end
    if State.CollectIronIngot  and tableContains(Names.IronIngot,  itemName) then return true end
    return false
end

local function getCharacter()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        return char
    end
    return nil
end

local function getGameFolder(name)
    local gameFolder = workspace:FindFirstChild("Game")
    if gameFolder then
        return gameFolder:FindFirstChild(name)
    end
    return nil
end

local function isBagFull()
    local success, isFull = pcall(function()
        local label = game:GetService("Players").LocalPlayer.PlayerGui["99Backpack"].bg.BackpackSlot.BagButton.BagCap
        local text = label.Text
        local current, max = text:match("(%d+)%s*/%s*(%d+)")
        if current and max then
            return tonumber(current) >= tonumber(max)
        end
        return false
    end)
    return success and isFull
end

local function notify(title, content, duration)
    Fluent:Notify({
        Title    = title,
        Content  = content,
        Duration = duration or 2,
    })
end

-- ================================================================
-- CREATE WINDOW
-- ================================================================
local Window = Fluent:CreateWindow({
    Title       = "Developed by : GAMER",
    SubTitle    = "The King",
    TabWidth    = 160,
    Size        = UDim2.fromOffset(520, 240),
    Acrylic     = false,
    Theme       = "Aqua",
    MinimizeKey = Enum.KeyCode.LeftAlt,
})

local Tabs = {
    VIP            = Window:AddTab({ Title = "VIP",          Icon = "crown"             }),
    Collect        = Window:AddTab({ Title = "Collect",      Icon = "archive"           }),
    Chests         = Window:AddTab({ Title = "Chests",       Icon = "inbox"             }),
    Quest          = Window:AddTab({ Title = "Quest ",       Icon = "clipboard-check"   }),
    Teleport       = Window:AddTab({ Title = "Teleport",     Icon = "map-pin"           }),
    Player         = Window:AddTab({ Title = "Player",       Icon = "user-cog"          }),
    Farm           = Window:AddTab({ Title = "Farm",         Icon = "axe"               }),
    Combat         = Window:AddTab({ Title = "Combat",       Icon = "sword"             }),
    ESP            = Window:AddTab({ Title = "Esp",          Icon = "eye"               }),
    EquipFood      = Window:AddTab({ Title = "Equip Food ",  Icon = "utensils"          }),
    DropFood       = Window:AddTab({ Title = "Drop Food ",   Icon = "trash"             }),
    EquipResource  = Window:AddTab({ Title = "Equip Res.",   Icon = "package"           }),
    DropRes        = Window:AddTab({ Title = "Drop Res.",    Icon = "trash"             }),
    EquipTool      = Window:AddTab({ Title = "Equip Tool ",  Icon = "wrench"            }),
    DropTool       = Window:AddTab({ Title = "Drop Tool ",   Icon = "trash"             }),
    Settings       = Window:AddTab({ Title = "Settings",     Icon = "settings"          }),
    Auto           = Window:AddTab({ Title =  "Auto ",       Icon =  "play"             }),
}

-- ================================================================
-- COLLECT TOOL TAB (Instant-Start Queue Collection)
-- ================================================================
local CollectToolTab = Window:AddTab({ Title = "Collect Tool", Icon = "wrench" })

Collector.Tool.LimitSlider = CollectToolTab:AddSlider("CollectToolLimitSlider", {
    Title = "Collection Limit",
    Description = "Stops after collecting this many of each tool.",
    Default = 1, Min = 1, Max = 5, Rounding = 0,
    Callback = function(v) State.CollectToolLimit = v end
})

local COLLECT_TOOL_ITEMS = Lists.Tools  -- reuse

local function runToolCollectorThread()
    local char = getCharacter()
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        Collector.Tool.Running = false
        return
    end
    
    local startPos = char.HumanoidRootPart.CFrame
    local cam = workspace.CurrentCamera
    local oldCamType = cam.CameraType
    pcall(function() cam.CameraType = Enum.CameraType.Scriptable end)
    
    local function cleanup()
        pcall(function() cam.CameraType = oldCamType end)
        char = getCharacter()
        if char and char:FindFirstChild("HumanoidRootPart") then
            pcall(function() char.HumanoidRootPart.CFrame = startPos end)
        end
        Collector.Tool.Running = false
    end

    local status, err = xpcall(function()
        while #Collector.Tool.Queue > 0 do
            local targetToolName = Collector.Tool.Queue[1]
            
            if not Collector.Tool.Toggles[targetToolName] or not Collector.Tool.Toggles[targetToolName].Value then
                if Collector.Tool.Queue[1] == targetToolName then table.remove(Collector.Tool.Queue, 1) end
                continue
            end
            
            local collectedCount = 0
            local targetCount = State.CollectToolLimit
            
            while collectedCount < targetCount do
                if not Collector.Tool.Toggles[targetToolName] or not Collector.Tool.Toggles[targetToolName].Value then break end
                
                local dropFolder = getGameFolder("DroppedItems")
                if not dropFolder then task.wait(1) continue end
                
                local targetItem = nil
                local targetPart = nil
                local minDist = math.huge
                
                char = getCharacter()
                if not char or not char:FindFirstChild("HumanoidRootPart") then break end
                
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health <= 0 then break end
                
                for _, item in pairs(dropFolder:GetChildren()) do
                    if item:IsA("Model") and item.Name == targetToolName then
                        if item:GetAttribute("collecting") then continue end
                        
                        local part = item:FindFirstChildWhichIsA("BasePart", true) or item.PrimaryPart
                        if part then
                            local dist = (char.HumanoidRootPart.Position - part.Position).Magnitude
                            if dist < minDist then
                                minDist = dist
                                targetItem = item
                                targetPart = part
                            end
                        end
                    end
                end
                
                if not targetItem then break end
                
                local success = false
                local maxAttempts = 5
                
                for attempt = 1, maxAttempts do
                    if not Collector.Tool.Toggles[targetToolName] or not Collector.Tool.Toggles[targetToolName].Value then break end
                    if not targetItem.Parent then success = true; break end
                    if targetItem:GetAttribute("collecting") then break end
                    
                    pcall(function()
                        char.HumanoidRootPart.CFrame = targetPart.CFrame * CFrame.new(0, 3, 0)
                    end)
                    task.wait(0.15)
                    
                    pcall(function()
                        Remotes.collect:FireServer(targetItem)
                    end)
                    
                    local waitTime = 0
                    while targetItem.Parent and waitTime < 1.5 do
                        task.wait(0.1)
                        waitTime = waitTime + 0.1
                    end
                    
                    if not targetItem.Parent then
                        success = true
                        break
                    end
                end
                
                if success then
                    collectedCount = collectedCount + 1
                end
                
                task.wait(0.1)
            end
            
            if Collector.Tool.Queue[1] == targetToolName then
                table.remove(Collector.Tool.Queue, 1)
            end
            
            if Collector.Tool.Toggles[targetToolName] and Collector.Tool.Toggles[targetToolName].Value then
                pcall(function() Collector.Tool.Toggles[targetToolName]:SetValue(false) end)
            end
        end
    end, function(errorMsg)
        warn("[Collect Tool] Critical Error in loop: " .. tostring(errorMsg))
    end)
    
    cleanup()
end

local function addToolToQueue(toolName)
    for _, v in ipairs(Collector.Tool.Queue) do
        if v == toolName then return end
    end
    table.insert(Collector.Tool.Queue, toolName)
    
    if not Collector.Tool.Running then
        Collector.Tool.Running = true
        task.spawn(runToolCollectorThread)
    end
end

local function removeToolFromQueue(toolName)
    for i, v in ipairs(Collector.Tool.Queue) do
        if v == toolName then
            table.remove(Collector.Tool.Queue, i)
            break
        end
    end
end

Toggles.CollectToolAll = CollectToolTab:AddToggle("CollectToolAllToggle", {
    Title = "Collect ALL Tools",
    Description = "Instantly queues all tools for collection.",
    Default = false,
    Callback = function(v)
        for _, toggle in pairs(Collector.Tool.Toggles) do
            if toggle.Value ~= v then
                pcall(function() toggle:SetValue(v) end)
            end
        end
    end
})

for _, toolName in ipairs(Lists.Tools) do
    local toggle = CollectToolTab:AddToggle("ToolFilter_" .. toolName:gsub("%s+", ""), {
        Title = "Collect " .. toolName,
        Default = false,
        Callback = function(enabled)
            if enabled then
                addToolToQueue(toolName)
            else
                removeToolFromQueue(toolName)
            end
        end
    })
    Collector.Tool.Toggles[toolName] = toggle
end

-- ================================================================
-- COLLECT RES TAB (Instant-Start Queue Collection)
-- ================================================================
local CollectResTab = Window:AddTab({ Title = "Collect Res", Icon = "package" })

Collector.Res.LimitSlider = CollectResTab:AddSlider("CollectResLimitSlider", {
    Title = "Collection Limit",
    Description = "Stops after collecting this many items per resource.",
    Default = 5, Min = 1, Max = 20, Rounding = 0,
    Callback = function(v) State.CollectResLimit = v end
})

local function runCollectorThread()
    local char = getCharacter()
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        Collector.Res.Running = false
        return
    end
    
    local startPos = char.HumanoidRootPart.CFrame
    local cam = workspace.CurrentCamera
    local oldCamType = cam.CameraType
    pcall(function() cam.CameraType = Enum.CameraType.Scriptable end)
    
    local function cleanup()
        pcall(function() cam.CameraType = oldCamType end)
        char = getCharacter()
        if char and char:FindFirstChild("HumanoidRootPart") then
            pcall(function() char.HumanoidRootPart.CFrame = startPos end)
        end
        Collector.Res.Running = false
    end

    local status, err = xpcall(function()
        while #Collector.Res.Queue > 0 do
            local targetResName = Collector.Res.Queue[1]
            
            if not Collector.Res.Toggles[targetResName] or not Collector.Res.Toggles[targetResName].Value then
                if Collector.Res.Queue[1] == targetResName then table.remove(Collector.Res.Queue, 1) end
                continue
            end
            
            local collectedCount = 0
            local targetCount = State.CollectResLimit
            
            while collectedCount < targetCount do
                if not Collector.Res.Toggles[targetResName] or not Collector.Res.Toggles[targetResName].Value then break end
                if isBagFull() then break end
                
                local dropFolder = getGameFolder("DroppedItems")
                if not dropFolder then task.wait(1) continue end
                
                local targetItem = nil
                local targetPart = nil
                local minDist = math.huge
                
                char = getCharacter()
                if not char or not char:FindFirstChild("HumanoidRootPart") then break end
                
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health <= 0 then break end
                
                for _, item in pairs(dropFolder:GetChildren()) do
                    if item:IsA("Model") and item.Name == targetResName then
                        if item:GetAttribute("collecting") then continue end
                        
                        local part = item:FindFirstChildWhichIsA("BasePart", true) or item.PrimaryPart
                        if part then
                            local dist = (char.HumanoidRootPart.Position - part.Position).Magnitude
                            if dist < minDist then
                                minDist = dist
                                targetItem = item
                                targetPart = part
                            end
                        end
                    end
                end
                
                if not targetItem then break end
                
                local success = false
                local maxAttempts = 5
                
                for attempt = 1, maxAttempts do
                    if not Collector.Res.Toggles[targetResName] or not Collector.Res.Toggles[targetResName].Value then break end
                    if not targetItem.Parent then success = true; break end
                    if targetItem:GetAttribute("collecting") then break end
                    
                    pcall(function()
                        char.HumanoidRootPart.CFrame = targetPart.CFrame * CFrame.new(0, 3, 0)
                    end)
                    task.wait(0.15)
                    
                    pcall(function()
                        Remotes.collect:FireServer(targetItem)
                    end)
                    
                    local waitTime = 0
                    while targetItem.Parent and waitTime < 1.5 do
                        task.wait(0.1)
                        waitTime = waitTime + 0.1
                    end
                    
                    if not targetItem.Parent then
                        success = true
                        break
                    end
                end
                
                if success then
                    collectedCount = collectedCount + 1
                end
                
                task.wait(0.1)
            end
            
            if Collector.Res.Queue[1] == targetResName then
                table.remove(Collector.Res.Queue, 1)
            end
            
            if Collector.Res.Toggles[targetResName] and Collector.Res.Toggles[targetResName].Value then
                pcall(function() Collector.Res.Toggles[targetResName]:SetValue(false) end)
            end
        end
    end, function(errorMsg)
        warn("[Collect Res] Critical Error in loop: " .. tostring(errorMsg))
    end)
    
    cleanup()
end

local function addToQueue(resName)
    for _, v in ipairs(Collector.Res.Queue) do
        if v == resName then return end
    end
    table.insert(Collector.Res.Queue, resName)
    
    if not Collector.Res.Running then
        Collector.Res.Running = true
        task.spawn(runCollectorThread)
    end
end

local function removeFromQueue(resName)
    for i, v in ipairs(Collector.Res.Queue) do
        if v == resName then
            table.remove(Collector.Res.Queue, i)
            break
        end
    end
end

Toggles.CollectResAll = CollectResTab:AddToggle("CollectResAllToggle", {
    Title = "Collect ALL Resources",
    Description = "Instantly queues all resources for collection.",
    Default = false,
    Callback = function(v)
        for _, toggle in pairs(Collector.Res.Toggles) do
            if toggle.Value ~= v then
                pcall(function() toggle:SetValue(v) end)
            end
        end
    end
})

for _, resName in ipairs(Lists.Resources) do
    local toggle = CollectResTab:AddToggle("Filter_" .. resName:gsub("%s+", ""), {
        Title = "Collect " .. resName,
        Default = false,
        Callback = function(enabled)
            if enabled then
                addToQueue(resName)
            else
                removeFromQueue(resName)
            end
        end
    })
    Collector.Res.Toggles[resName] = toggle
end

-- ================================================================
-- COLLECT FOOD TAB (Instant-Start Queue Collection)
-- ================================================================
local CollectFoodTab = Window:AddTab({ Title = "Collect Food", Icon = "utensils" })

Collector.Food.LimitSlider = CollectFoodTab:AddSlider("CollectFoodLimitSlider", {
    Title = "Collection Limit",
    Description = "Stops after collecting this many items per food.",
    Default = 5, Min = 1, Max = 20, Rounding = 0,
    Callback = function(v) State.CollectFoodLimit = v end
})

local function runFoodCollectorThread()
    local char = getCharacter()
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        Collector.Food.Running = false
        return
    end
    
    local startPos = char.HumanoidRootPart.CFrame
    local cam = workspace.CurrentCamera
    local oldCamType = cam.CameraType
    pcall(function() cam.CameraType = Enum.CameraType.Scriptable end)
    
    local function cleanup()
        pcall(function() cam.CameraType = oldCamType end)
        char = getCharacter()
        if char and char:FindFirstChild("HumanoidRootPart") then
            pcall(function() char.HumanoidRootPart.CFrame = startPos end)
        end
        Collector.Food.Running = false
    end

    local status, err = xpcall(function()
        while #Collector.Food.Queue > 0 do
            local targetFoodName = Collector.Food.Queue[1]
            
            if not Collector.Food.Toggles[targetFoodName] or not Collector.Food.Toggles[targetFoodName].Value then
                if Collector.Food.Queue[1] == targetFoodName then table.remove(Collector.Food.Queue, 1) end
                continue
            end
            
            local collectedCount = 0
            local targetCount = State.CollectFoodLimit
            
            while collectedCount < targetCount do
                if not Collector.Food.Toggles[targetFoodName] or not Collector.Food.Toggles[targetFoodName].Value then break end
                if isBagFull() then break end
                
                local dropFolder = getGameFolder("DroppedItems")
                if not dropFolder then task.wait(1) continue end
                
                local targetItem = nil
                local targetPart = nil
                local minDist = math.huge
                
                char = getCharacter()
                if not char or not char:FindFirstChild("HumanoidRootPart") then break end
                
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health <= 0 then break end
                
                for _, item in pairs(dropFolder:GetChildren()) do
                    if item:IsA("Model") and item.Name == targetFoodName then
                        if item:GetAttribute("collecting") then continue end
                        
                        local part = item:FindFirstChildWhichIsA("BasePart", true) or item.PrimaryPart
                        if part then
                            local dist = (char.HumanoidRootPart.Position - part.Position).Magnitude
                            if dist < minDist then
                                minDist = dist
                                targetItem = item
                                targetPart = part
                            end
                        end
                    end
                end
                
                if not targetItem then break end
                
                local success = false
                local maxAttempts = 5
                
                for attempt = 1, maxAttempts do
                    if not Collector.Food.Toggles[targetFoodName] or not Collector.Food.Toggles[targetFoodName].Value then break end
                    if not targetItem.Parent then success = true; break end
                    if targetItem:GetAttribute("collecting") then break end
                    
                    pcall(function()
                        char.HumanoidRootPart.CFrame = targetPart.CFrame * CFrame.new(0, 3, 0)
                    end)
                    task.wait(0.15)
                    
                    pcall(function()
                        Remotes.collect:FireServer(targetItem)
                    end)
                    
                    local waitTime = 0
                    while targetItem.Parent and waitTime < 1.5 do
                        task.wait(0.1)
                        waitTime = waitTime + 0.1
                    end
                    
                    if not targetItem.Parent then
                        success = true
                        break
                    end
                end
                
                if success then
                    collectedCount = collectedCount + 1
                end
                
                task.wait(0.1)
            end
            
            if Collector.Food.Queue[1] == targetFoodName then
                table.remove(Collector.Food.Queue, 1)
            end
            
            if Collector.Food.Toggles[targetFoodName] and Collector.Food.Toggles[targetFoodName].Value then
                pcall(function() Collector.Food.Toggles[targetFoodName]:SetValue(false) end)
            end
        end
    end, function(errorMsg)
        warn("[Collect Food] Critical Error in loop: " .. tostring(errorMsg))
    end)
    
    cleanup()
end

local function addFoodToQueue(foodName)
    for _, v in ipairs(Collector.Food.Queue) do
        if v == foodName then return end
    end
    table.insert(Collector.Food.Queue, foodName)
    
    if not Collector.Food.Running then
        Collector.Food.Running = true
        task.spawn(runFoodCollectorThread)
    end
end

local function removeFoodFromQueue(foodName)
    for i, v in ipairs(Collector.Food.Queue) do
        if v == foodName then
            table.remove(Collector.Food.Queue, i)
            break
        end
    end
end

Toggles.CollectFoodAll = CollectFoodTab:AddToggle("CollectFoodAllToggle", {
    Title = "Collect ALL Food",
    Description = "Instantly queues all food items for collection.",
    Default = false,
    Callback = function(v)
        for _, toggle in pairs(Collector.Food.Toggles) do
            if toggle.Value ~= v then
                pcall(function() toggle:SetValue(v) end)
            end
        end
    end
})

for _, foodName in ipairs(Lists.Food) do
    local toggle = CollectFoodTab:AddToggle("FoodFilter_" .. foodName:gsub("%s+", ""), {
        Title = "Collect " .. foodName,
        Default = false,
        Callback = function(enabled)
            if enabled then
                addFoodToQueue(foodName)
            else
                removeFoodFromQueue(foodName)
            end
        end
    })
    Collector.Food.Toggles[foodName] = toggle
end

-- ================================================================
-- Collect TAB
-- ================================================================
Toggles.CollectWood = Tabs.Collect:AddToggle("CollectWood", {
    Title    = "Collect Wood", Default  = State.CollectWood,
    Callback = function(enabled) State.CollectWood = enabled end,
})

Toggles.CollectStone = Tabs.Collect:AddToggle("CollectStone", {
    Title    = "Collect Stone", Default  = State.CollectStone,
    Callback = function(enabled) State.CollectStone = enabled end,
})

Toggles.CollectIronOre = Tabs.Collect:AddToggle("CollectIronOre", {
    Title    = "Collect Iron Ore", Default  = State.CollectIronOre,
    Callback = function(enabled) State.CollectIronOre = enabled end,
})

Toggles.CollectIronIngot = Tabs.Collect:AddToggle("CollectIronIngot", {
    Title    = "Collect Iron Ingot", Default  = State.CollectIronIngot,
    Callback = function(enabled) State.CollectIronIngot = enabled end,
})

Tabs.Collect:AddToggle("CollectCoco", { Title = "Collect Coconut", Default = State.CollectCoco, Callback = function(e) State.CollectCoco = e end })
Tabs.Collect:AddToggle("CollectEgg", { Title = "Collect Egg", Default = State.CollectEgg, Callback = function(e) State.CollectEgg = e end })
Tabs.Collect:AddToggle("CollectCookedEgg", { Title = "Collect Cooked Egg", Default = State.CollectCookedEgg, Callback = function(e) State.CollectCookedEgg = e end })
Tabs.Collect:AddToggle("CollectMeat", { Title = "Collect Meat", Default = State.CollectMeat, Callback = function(e) State.CollectMeat = e end })
Tabs.Collect:AddToggle("CollectCookedMeat", { Title = "Collect Cooked Meat", Default = State.CollectCookedMeat, Callback = function(e) State.CollectCookedMeat = e end })
Tabs.Collect:AddToggle("CollectBearPelt", { Title = "Collect Bear Pelt", Default = State.CollectBearPelt, Callback = function(e) State.CollectBearPelt = e end })
Tabs.Collect:AddToggle("CollectFeather", { Title = "Collect Chicken Feather", Default = State.CollectFeather, Callback = function(e) State.CollectFeather = e end })
Tabs.Collect:AddToggle("CollectCrab", { Title = "Collect Crab", Default = State.CollectCrab, Callback = function(e) State.CollectCrab = e end })
Tabs.Collect:AddToggle("CollectCookedCrab", { Title = "Collect Cooked Crab", Default = State.CollectCookedCrab, Callback = function(e) State.CollectCookedCrab = e end })
Tabs.Collect:AddToggle("CollectRedBerries", { Title = "Collect Red Berries", Default = State.CollectRedBerries, Callback = function(e) State.CollectRedBerries = e end })
Tabs.Collect:AddToggle("CollectSnakeTooth", { Title = "Collect Snake Tooth", Default = State.CollectSnakeTooth, Callback = function(e) State.CollectSnakeTooth = e end })
Tabs.Collect:AddToggle("CollectSpiderWeb", { Title = "Collect Spider Web", Default = State.CollectSpiderWeb, Callback = function(e) State.CollectSpiderWeb = e end })

Tabs.Collect:AddParagraph({ Title = "All Item Collection", Content = "Disable 'Collect ALL' to use specific filters." })
Tabs.Collect:AddToggle("AutoCollectAll", { Title = "Auto Collect All Items", Default = State.AutoCollectAll, Callback = function(e) State.AutoCollectAll = e end })

task.spawn(function()
    while true do
        task.wait(0.15)
        if (State.AutoCollectAll or State.CollectWood or State.CollectCoco or State.CollectEgg or State.CollectCookedEgg or State.CollectMeat or State.CollectCookedMeat or State.CollectStone
            or State.CollectBearPelt or State.CollectFeather or State.CollectCrab or State.CollectCookedCrab or State.CollectIronOre
            or State.CollectRedBerries or State.CollectSnakeTooth or State.CollectSpiderWeb or State.CollectIronIngot) and not isBagFull() then
            local char = getCharacter()
            local itemFolder = getGameFolder("DroppedItems")
            if char and itemFolder then
                for _, item in pairs(itemFolder:GetChildren()) do
                    if item:IsA("Model") and not isBagFull() then
                        local part = item:FindFirstChildWhichIsA("BasePart", true)
                        if part and shouldCollect(item.Name) then
                            local savedCFrame = char.HumanoidRootPart.CFrame
                            local cam = workspace.CurrentCamera
                            cam.CameraType = Enum.CameraType.Scriptable
                            char.HumanoidRootPart.CFrame = part.CFrame
                            task.wait(0.2)
                            Remotes.collect:FireServer(item)
                            task.wait(0.1)
                            char.HumanoidRootPart.CFrame = savedCFrame
                            cam.CameraType = Enum.CameraType.Custom
                        end
                    end
                    if isBagFull() then task.wait(4) end
                end
            end
        end
    end
end)

-- ================================================================
-- FARM TAB
-- ================================================================
Tabs.Farm:AddToggle("AutoCut", {
    Title = "Auto Cut Trees & Break Stones", Default = State.AutoCutTree,
    Callback = function(enabled)
        State.AutoCutTree = enabled
        task.spawn(function()
            while State.AutoCutTree do
                task.wait(0.001)
                local char = getCharacter()
                local staticFolder = getGameFolder("Static")
                if char and staticFolder then
                    for _, obj in pairs(staticFolder:GetChildren()) do
                        if obj.Name == "Coconut Tree" or obj.Name == "Tree" or obj.Name == "Iron Stone" or obj.Name == "Stone" or obj.Name == "Bush" then
                            local part = obj:FindFirstChildWhichIsA("BasePart", true)
                            if part then
                                local dist = (char.HumanoidRootPart.Position - part.Position).Magnitude
                                if dist <= State.TreeRange + 5 then
                                    Remotes.meleeHit:FireServer({}, {obj})
                                end
                            end
                        end
                    end
                end
            end
        end)
    end,
})

-- ================================================================
-- COMBAT TAB
-- ================================================================
Tabs.Combat:AddToggle("AutoKill", {
    Title = "Kill Aura Animals", Default = State.AutoKill,
    Callback = function(enabled)
        State.AutoKill = enabled
        task.spawn(function()
            while State.AutoKill do
                task.wait(0.1)
                local char = getCharacter()
                local entitiesFolder = getGameFolder("Entities")
                if char and entitiesFolder then
                    for _, entity in pairs(entitiesFolder:GetChildren()) do
                        if entity:IsA("Model") and entity:FindFirstChild("HumanoidRootPart") and entity:FindFirstChild("Humanoid") and entity.Humanoid.Health > 0 then
                            local dist = (char.HumanoidRootPart.Position - entity.HumanoidRootPart.Position).Magnitude
                            if dist <= State.KillRange then
                                Remotes.meleeHit:FireServer({entity}, {})
                            end
                        end
                    end
                end
            end
        end)
    end,
})

-- ================================================================
-- ESP TAB
-- ================================================================
Tabs.ESP:AddToggle("ESPAnimals", {
    Title = "Enable Entity ESP", Default = State.ESPEnabled,
    Callback = function(enabled)
        State.ESPEnabled = enabled
        if not State.ESPEnabled then
            local entitiesFolder = getGameFolder("Entities")
            if entitiesFolder then
                for _, entity in pairs(entitiesFolder:GetChildren()) do
                    local existing = entity:FindFirstChild("ESPHighlight")
                    if existing then existing:Destroy() end
                end
            end
        end
    end,
})

task.spawn(function()
    while true do
        task.wait(1)
        if State.ESPEnabled then
            local entitiesFolder = getGameFolder("Entities")
            if entitiesFolder then
                for _, entity in pairs(entitiesFolder:GetChildren()) do
                    if entity:IsA("Model") and not entity:FindFirstChild("ESPHighlight") then
                        local highlight = Instance.new("Highlight")
                        highlight.Name = "ESPHighlight"
                        highlight.FillTransparency = 0.5
                        highlight.OutlineTransparency = 0
                        highlight.FillColor = Color3.fromRGB(255, 0, 135)
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.Parent = entity
                    end
                end
            end
        end
    end
end)

-- ================================================================
-- TELEPORT TAB
-- ================================================================
Tabs.Teleport:AddButton({
    Title = "🔥 TP to Campfire",
    Callback = function()
        local char = getCharacter()
        if not char then return end
        local campfire = workspace:FindFirstChild("Campfire", true) or workspace:FindFirstChild("Camp Fire", true) or workspace:FindFirstChild("Fogueira", true)
        if campfire then
            local part = campfire:FindFirstChildWhichIsA("BasePart", true) or (campfire:IsA("Model") and campfire.PrimaryPart)
            if part then
                char.HumanoidRootPart.CFrame = part.CFrame * CFrame.new(0, 3, 0)
                notify("Success", "Teleported to the campfire!", 2)
            end
        else
            notify("Error", "Campfire not found on the map.", 2)
        end
    end,
})

local function teleportToNamedObject(objectName)
    local char = getCharacter()
    if not char then return end
    local tilesFolder = getGameFolder("Tiles")
    if not tilesFolder then notify("Error", objectName .. " not found. Wait for the map to generate it.", 4); return end
    local obj = tilesFolder:FindFirstChild(objectName, true)
    if obj and obj:IsA("Model") then
        local part = obj:FindFirstChildWhichIsA("BasePart", true) or obj.PrimaryPart
        if part then
            char.HumanoidRootPart.CFrame = part.CFrame * CFrame.new(0, 3, 0)
            notify("Success", "Teleported to " .. objectName .. "!", 3)
        end
    else
        notify("Error", objectName .. " not found. Wait for the map to generate it.", 4)
    end
end

Tabs.Teleport:AddButton({ Title = "🥛 TP to Plastic Bucket", Callback = function() teleportToNamedObject("Plastic Bucket") end })
Tabs.Teleport:AddButton({ Title = "📻 TP to Radio", Callback = function() teleportToNamedObject("Radio") end })
Tabs.Teleport:AddButton({ Title = "🧭 TP to Compass", Callback = function() teleportToNamedObject("Compass") end })
Tabs.Teleport:AddButton({ Title = "🗺️ TP to Map", Callback = function() teleportToNamedObject("Map") end })

-- ================================================================
-- PLAYER TAB
-- ================================================================
function applyJumpPower()
    local char = getCharacter()
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    if State.JumpPowerEnabled then
        pcall(function()
            if humanoid.UseJumpPower then humanoid.JumpPower = State.JumpPowerValue else humanoid.JumpHeight = State.JumpPowerValue end
        end)
    else
        pcall(function() humanoid.JumpPower = 50 end)
        pcall(function() humanoid.JumpHeight = 7.2 end)
    end
end

local function stopFly()
    Mobile.FLYING = false
    if Mobile.flyKeyDown then Mobile.flyKeyDown:Disconnect() Mobile.flyKeyDown = nil end
    if Mobile.flyKeyUp then Mobile.flyKeyUp:Disconnect() Mobile.flyKeyUp = nil end
    if Mobile.mobileFlyConnection then Mobile.mobileFlyConnection:Disconnect() Mobile.mobileFlyConnection = nil end
    local char = getCharacter()
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.PlatformStand = false end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            if hrp:FindFirstChild("FlyVelocity") then hrp.FlyVelocity:Destroy() end
            if hrp:FindFirstChild("FlyGyro") then hrp.FlyGyro:Destroy() end
        end
    end
    pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
end

local function startFly()
    stopFly()
    Mobile.FLYING = true
    local char = getCharacter()
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end
    humanoid.PlatformStand = true
    pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Track end)
    local BodyGyro = Instance.new("BodyGyro")
    BodyGyro.Name = "FlyGyro"; BodyGyro.P = 9e4; BodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9); BodyGyro.CFrame = hrp.CFrame; BodyGyro.Parent = hrp
    local BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.Name = "FlyVelocity"; BodyVelocity.Velocity = Vector3.new(0, 0, 0); BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9); BodyVelocity.Parent = hrp
    local isMobile = Services.UserInputService.TouchEnabled and not Services.UserInputService.KeyboardEnabled
    if isMobile then
        local controlModule = nil
        pcall(function() controlModule = require(game.Players.LocalPlayer.PlayerScripts.PlayerModule:WaitForChild("ControlModule")) end)
        Mobile.mobileFlyConnection = Services.RunService.RenderStepped:Connect(function()
            if not Mobile.FLYING then return end
            char = getCharacter(); if not char then return end
            hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            BodyGyro.CFrame = workspace.CurrentCamera.CFrame; BodyVelocity.Velocity = Vector3.new(0, 0, 0)
            if controlModule then
                local direction = controlModule:GetMoveVector()
                local cam = workspace.CurrentCamera
                if direction.X > 0 then BodyVelocity.Velocity = BodyVelocity.Velocity + cam.CFrame.RightVector * (direction.X * State.FlySpeed) end
                if direction.X < 0 then BodyVelocity.Velocity = BodyVelocity.Velocity + cam.CFrame.RightVector * (direction.X * State.FlySpeed) end
                if direction.Z > 0 then BodyVelocity.Velocity = BodyVelocity.Velocity - cam.CFrame.LookVector * (direction.Z * State.FlySpeed) end
                if direction.Z < 0 then BodyVelocity.Velocity = BodyVelocity.Velocity - cam.CFrame.LookVector * (direction.Z * State.FlySpeed) end
            end
        end)
    else
        local CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
        local lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
        local SPEED = 0
        Mobile.flyKeyDown = Services.UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.W then CONTROL.F = 1
            elseif input.KeyCode == Enum.KeyCode.S then CONTROL.B = -1
            elseif input.KeyCode == Enum.KeyCode.A then CONTROL.L = -1
            elseif input.KeyCode == Enum.KeyCode.D then CONTROL.R = 1
            elseif input.KeyCode == Enum.KeyCode.E then CONTROL.Q = 1
            elseif input.KeyCode == Enum.KeyCode.Q then CONTROL.E = -1 end
        end)
        Mobile.flyKeyUp = Services.UserInputService.InputEnded:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.W then CONTROL.F = 0
            elseif input.KeyCode == Enum.KeyCode.S then CONTROL.B = 0
            elseif input.KeyCode == Enum.KeyCode.A then CONTROL.L = 0
            elseif input.KeyCode == Enum.KeyCode.D then CONTROL.R = 0
            elseif input.KeyCode == Enum.KeyCode.E then CONTROL.Q = 0
            elseif input.KeyCode == Enum.KeyCode.Q then CONTROL.E = 0 end
        end)
        task.spawn(function()
            repeat task.wait()
                local camera = workspace.CurrentCamera
                if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then SPEED = State.FlySpeed
                elseif SPEED ~= 0 then SPEED = 0 end
                if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
                    BodyVelocity.Velocity = ((camera.CFrame.LookVector * (CONTROL.F + CONTROL.B)) + ((camera.CFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - camera.CFrame.p)) * SPEED
                    lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
                elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and (CONTROL.Q + CONTROL.E) == 0 and SPEED ~= 0 then
                    BodyVelocity.Velocity = ((camera.CFrame.LookVector * (lCONTROL.F + lCONTROL.B)) + ((camera.CFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - camera.CFrame.p)) * SPEED
                else
                    BodyVelocity.Velocity = Vector3.new(0, 0, 0)
                end
                BodyGyro.CFrame = camera.CFrame
            until not Mobile.FLYING
        end)
    end
end

Tabs.Player:AddToggle("Noclip", { Title = "Noclip", Default = State.NoclipEnabled, Callback = function(e) State.NoclipEnabled = e end })
Tabs.Player:AddToggle("TPWalk", { Title = "TP Walk", Default = State.TPWalkEnabled, Callback = function(e) State.TPWalkEnabled = e end })
Tabs.Player:AddSlider("TPWalkSpeed", { Title = "TP Walk Speed", Default = State.TPWalkSpeed, Min = 1, Max = 10, Rounding = 0, Callback = function(v) State.TPWalkSpeed = v end })
Tabs.Player:AddToggle("JumpPowerToggle", { Title = "Enable Jump Power", Default = State.JumpPowerEnabled, Callback = function(e) State.JumpPowerEnabled = e; applyJumpPower() end })
Tabs.Player:AddSlider("JumpPowerSlider", { Title = "Jump Power / Height", Default = State.JumpPowerValue, Min = 0, Max = 150, Rounding = 0, Callback = function(v) State.JumpPowerValue = v; applyJumpPower() end })
Tabs.Player:AddToggle("FlyToggle", { Title = "Fly", Description = "PC: WASD + QE. Mobile: Joystick.", Default = false, Callback = function(e) State.FlyEnabled = e; if e then startFly() else stopFly() end end })
Tabs.Player:AddSlider("FlySpeedSlider", { Title = "Fly Speed", Default = 50, Min = 10, Max = 200, Rounding = 0, Callback = function(v) State.FlySpeed = v end })

game.Players.LocalPlayer.CharacterAdded:Connect(function(newChar)
    local humanoid = newChar:WaitForChild("Humanoid", 5)
    if humanoid and State.JumpPowerEnabled then
        pcall(function()
            if humanoid.UseJumpPower then humanoid.JumpPower = State.JumpPowerValue else humanoid.JumpHeight = State.JumpPowerValue end
        end)
    end
end)

game.Players.LocalPlayer.CharacterAdded:Connect(function()
    if State.FlyEnabled then task.wait(1); startFly() end
end)

Services.RunService.Stepped:Connect(function()
    local char = getCharacter()
    if not char then return end
    if State.NoclipEnabled then
        for _, part in pairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
    end
    if State.TPWalkEnabled then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if hrp and humanoid and humanoid.MoveDirection.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + (humanoid.MoveDirection * State.TPWalkSpeed)
        end
    end
end)

applyJumpPower()

-- ================================================================
-- SETTINGS & MOBILE TOGGLE
-- ================================================================
Tabs.Settings:AddParagraph({ Title = "PC -> Menu Show/Hide Key: Alt\nMobile -> Use the floating 'W' button to Hide/Show." })

local CoreGui = game:GetService("CoreGui")
local existing = CoreGui:FindFirstChild("MobileButtonUI")
if existing then existing:Destroy() end

local mobileGui = Instance.new("ScreenGui"); mobileGui.Name = "MobileButtonUI"; mobileGui.Parent = CoreGui
local toggleBtn = Instance.new("TextButton"); toggleBtn.Name = "Toggle"; toggleBtn.Parent = mobileGui
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0); toggleBtn.Position = UDim2.new(0.5, -25, 0.1, 0)
toggleBtn.Size = UDim2.new(0, 50, 0, 50); toggleBtn.Font = Enum.Font.GothamBold; toggleBtn.Text = "G"
toggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0); toggleBtn.TextSize = 35; toggleBtn.Active = true; toggleBtn.Draggable = true

local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1, 0); corner.Parent = toggleBtn
local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(0, 255, 0); stroke.Thickness = 1.5; stroke.Parent = toggleBtn

local fluentScreenGui
task.spawn(function()
    while not fluentScreenGui do
        task.wait(0.5)
        for _, gui in pairs(CoreGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                for _, descendant in pairs(gui:GetDescendants()) do
                    if descendant:IsA("TextLabel") and string.find(descendant.Text, "MrBeast Island Escape") then
                        fluentScreenGui = gui; break
                    end
                end
            end
            if fluentScreenGui then break end
        end
    end
end)

toggleBtn.MouseButton1Click:Connect(function()
    if fluentScreenGui then
        for _, child in pairs(fluentScreenGui:GetChildren()) do
            if child:IsA("Frame") or child:IsA("CanvasGroup") then child.Visible = not child.Visible end
        end
    end
end)

-- ================================================================
-- EQUIP FOOD TAB
-- ================================================================
local function findToolByName(name)
    local player = game.Players.LocalPlayer
    local cleanName = name:gsub("%s+$", "")
    if player.Character then
        for _, tool in pairs(player.Character:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:gsub("%s+$", "") == cleanName then return tool end
        end
    end
    for _, tool in pairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:gsub("%s+$", "") == cleanName then return tool end
    end
    return nil
end

local function handleEquip(toolName, shouldEquip)
    local char = getCharacter()
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local tool = findToolByName(toolName)
    if shouldEquip then
        if tool and tool.Parent ~= char then pcall(function() humanoid:EquipTool(tool) end) end
    else
        if tool and tool.Parent == char then pcall(function() humanoid:UnequipTools() end) end
    end
end

local EquipFoodToggles = {}
for _, itemName in ipairs(Lists.Food) do
    local toggleVarName = "Toggle" .. itemName:gsub("%s+", "")
    EquipFoodToggles[itemName] = Tabs.EquipFood:AddToggle(toggleVarName, {
        Title = "Auto Equip " .. itemName, Description = "Automatically equips " .. itemName .. " when available.", Default = false,
        Callback = function(enabled) handleEquip(itemName, enabled) end,
    })
end

task.spawn(function()
    while true do
        task.wait(1)
        for itemName, toggleObj in pairs(EquipFoodToggles) do if toggleObj.Value then handleEquip(itemName, true) end end
    end
end)

-- ================================================================
-- EQUIP RESOURCE TAB
-- ================================================================
local function findResourceByName(name)
    local player = game.Players.LocalPlayer
    local cleanName = name:gsub("%s+$", "")
    if player.Character then
        for _, tool in pairs(player.Character:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:gsub("%s+$", "") == cleanName then return tool end
        end
    end
    for _, tool in pairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:gsub("%s+$", "") == cleanName then return tool end
    end
    return nil
end

local function handleResourceEquip(resourceName, shouldEquip)
    local char = getCharacter()
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local tool = findResourceByName(resourceName)
    if shouldEquip then
        if tool and tool.Parent ~= char then pcall(function() humanoid:EquipTool(tool) end) end
    else
        if tool and tool.Parent == char then pcall(function() humanoid:UnequipTools() end) end
    end
end

local ResourceEquipToggles = {}
for _, itemName in ipairs(Lists.Resources) do
    local toggleVarName = "ResToggle" .. itemName:gsub("%s+", "")
    ResourceEquipToggles[itemName] = Tabs.EquipResource:AddToggle(toggleVarName, {
        Title = "Equip " .. itemName, Description = "Holds " .. itemName .. " in hand.", Default = false,
        Callback = function(enabled) handleResourceEquip(itemName, enabled) end,
    })
end

task.spawn(function()
    while true do
        task.wait(0.5)
        for itemName, toggleObj in pairs(ResourceEquipToggles) do if toggleObj.Value then handleResourceEquip(itemName, true) end end
    end
end)

-- ================================================================
-- EQUIP TOOL TAB
-- ================================================================
Tabs.EquipTool:AddParagraph({ Title = "Specific Tools", Content = "Toggle to equip/unequip a specific item." })

local EquipToolToggles = {}
for _, toolName in ipairs(Lists.Tools) do
    local toggleVarName = "Toggle" .. toolName:gsub("%s+", "")
    EquipToolToggles[toolName] = Tabs.EquipTool:AddToggle(toggleVarName, {
        Title = "Equip " .. toolName, Description = "Automatically equips " .. toolName .. " when enabled.", Default = false,
        Callback = function(enabled) handleEquip(toolName, enabled) end,
    })
end

Tabs.EquipTool:AddParagraph({ Title = "Smart Auto-Equip", Content = "Automatically finds the best version of a tool type." })

local function getBestToolFromList(toolList)
    for _, name in ipairs(toolList) do local tool = findToolByName(name); if tool then return tool end end
    return nil
end

local function equipBestTool(toolList, typeName)
    local tool = getBestToolFromList(toolList)
    if tool then
        local char = getCharacter()
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then pcall(function() humanoid:EquipTool(tool) end); notify("Equipped Best", typeName .. ": " .. tool.Name, 1) end
        end
    else
        notify("Error", "No " .. typeName .. " found!", 2)
    end
end

Toggles.BestAxe    = Tabs.EquipTool:AddToggle("ToggleBestAxe",    { Title = "⚔️ Equip Best Axe",    Description = "Equips the highest tier axe available.", Default = false, Callback = function(e) if e then equipBestTool(Lists.AxePrior, "Axe") end end })
Toggles.BestPickaxe = Tabs.EquipTool:AddToggle("ToggleBestPickaxe",{ Title = "⛏️ Equip Best Pickaxe", Description = "Equips the highest tier pickaxe available.", Default = false, Callback = function(e) if e then equipBestTool(Lists.PickPrior, "Pickaxe") end end })
Toggles.BestSpear   = Tabs.EquipTool:AddToggle("ToggleBestSpear",  { Title = "🔱 Equip Best Spear",   Description = "Equips the highest tier spear available.", Default = false, Callback = function(e) if e then equipBestTool(Lists.SpearPrior, "Spear") end end })
Toggles.BestGun     = Tabs.EquipTool:AddToggle("ToggleBestGun",    { Title = "🔫 Equip Best Gun",     Description = "Equips the highest tier gun available.", Default = false, Callback = function(e) if e then equipBestTool(Lists.GunPrior, "Gun") end end })
Toggles.BestWand    = Tabs.EquipTool:AddToggle("ToggleBestWand",   { Title = "✨ Equip Best Wand",    Description = "Equips the highest tier wand available.", Default = false, Callback = function(e) if e then equipBestTool(Lists.WandPrior, "Wand") end end })
Toggles.BestSword   = Tabs.EquipTool:AddToggle("ToggleBestSword",  { Title = "🗡️ Equip Best Sword",   Description = "Equips the highest tier sword available.", Default = false, Callback = function(e) if e then equipBestTool(Lists.SwordPrior, "Sword") end end })
Toggles.BestWeapon  = Tabs.EquipTool:AddToggle("ToggleBestWeapon", { Title = "🗡️ Equip Best Weapon",  Description = "Equips the highest tier Weapon available.", Default = false, Callback = function(e) if e then equipBestTool(Lists.WeaponPrior, "Weapon") end end })
Tabs.EquipTool:AddToggle("ToggleTorch", { Title = "🔦 Equip Torch", Description = "Equips the Torch for light.", Default = false, Callback = function(e) handleEquip("Torch", e) end })
-- Persistent re‑equip loop (same as Equip Food)
task.spawn(function()
    while true do
        task.wait(0.5)
        for toolName, toggleObj in pairs(EquipToolToggles) do
            if toggleObj.Value then
                handleEquip(toolName, true)
            end
        end
    end
end)
-- ================================================================
-- DROP TOOL TAB (Self‑disabling toggles – exact original logic)
-- ================================================================

Tabs.DropTool:AddParagraph({ Title = "Drop Single Item", Content = "Drops only 1 instance of the tool." })
Toggles.Drop1xTool = {}
for _, toolName in ipairs(Lists.Tools) do
    local cleanKey = "Drop1xTool_" .. toolName:gsub("%s+", "")
    local toggle = Tabs.DropTool:AddToggle(cleanKey, {
        Title = "Drop 1x " .. toolName,
        Description = "Drops ONE " .. toolName .. " and turns off.",
        Default = false,
        Callback = function(enabled)
            if not enabled then return end
            -- Immediately disable to prevent double‑fire
            pcall(function() toggle:SetValue(false) end)
            -- Original 1x button logic
            local tool = findToolByName(toolName)
            if tool then
                pcall(function() Remotes.dropItem:FireServer(tool) end)
                notify("Dropped", "1x " .. toolName, 1)
            else
                notify("Error", toolName .. " not found!", 2)
            end
        end
    })
    Toggles.Drop1xTool[toolName] = toggle
end

Tabs.DropTool:AddParagraph({ Title = "Drop All Items", Content = "Drops ALL instances of the tool from your bag." })
Toggles.DropAllTool = {}
for _, toolName in ipairs(Lists.Tools) do
    local cleanKey = "DropAllTool_" .. toolName:gsub("%s+", "")
    local toggle = Tabs.DropTool:AddToggle(cleanKey, {
        Title = "Drop All " .. toolName,
        Description = "Drops ALL " .. toolName .. " and turns off.",
        Default = false,
        Callback = function(enabled)
            if not enabled then return end
            -- Immediately disable to prevent double‑fire
            pcall(function() toggle:SetValue(false) end)
            -- Original "Drop All" button logic (exactly as before)
            local player = game.Players.LocalPlayer
            local droppedCount = 0
            local function tryDropAll(container)
                for _, tool in pairs(container:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name:gsub("%s+$", "") == toolName:gsub("%s+$", "") then
                        pcall(function() Remotes.dropItem:FireServer(tool) end)
                        droppedCount = droppedCount + 1
                        task.wait(0.05)
                    end
                end
            end
            if player.Character then tryDropAll(player.Character) end
            tryDropAll(player.Backpack)
            if droppedCount > 0 then
                notify("Dropped", droppedCount .. "x " .. toolName, 1)
            else
                notify("Error", toolName .. " not found!", 2)
            end
        end
    })
    Toggles.DropAllTool[toolName] = toggle
end

-- Original master drop function (extracted into a reusable wrapper)
local function dropAllToolsFunc()
    local player = game.Players.LocalPlayer
    local droppedCount = 0
    local function dropAllInContainer(container)
        local toolsToDrop = {}
        for _, tool in pairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(toolsToDrop, tool)
            end
        end
        for _, tool in ipairs(toolsToDrop) do
            pcall(function() Remotes.dropItem:FireServer(tool) end)
            droppedCount = droppedCount + 1
            task.wait(0.05)
        end
    end
    dropAllInContainer(player.Backpack)
    if player.Character then dropAllInContainer(player.Character) end
    if droppedCount > 0 then
        notify("Dropped", "All tools dropped!", 2)
    else
        notify("Info", "No tools found to drop", 2)
    end
end

-- Master toggle (calls the exact same function, then self‑disables)
Toggles.DropAllToolsMaster = Tabs.DropTool:AddToggle("DropAllToolsMaster", {
    Title = "⚠️ Drop ALL Tools",
    Description = "Drops every tool and turns off.",
    Default = false,
    Callback = function(enabled)
        if enabled then
            dropAllToolsFunc()
            pcall(function() Toggles.DropAllToolsMaster:SetValue(false) end)
        end
    end,
})

-- ================================================================
-- DROP RESOURCE TAB (Self‑disabling toggles – exact original logic)
-- ================================================================

Tabs.DropRes:AddParagraph({ Title = "Drop Single Item", Content = "Drops only 1 instance of the resource." })
Toggles.Drop1xRes = {}
for _, resourceName in ipairs(Lists.Resources) do
    local cleanKey = "Drop1xRes_" .. resourceName:gsub("%s+", "")
    local toggle = Tabs.DropRes:AddToggle(cleanKey, {
        Title = "Drop 1x " .. resourceName,
        Description = "Drops ONE " .. resourceName .. " and turns off.",
        Default = false,
        Callback = function(enabled)
            if not enabled then return end
            -- Immediately disable to prevent any double‑fire
            pcall(function() toggle:SetValue(false) end)
            -- Original 1x button logic
            local tool = findResourceByName(resourceName)
            if tool then
                pcall(function() Remotes.dropItem:FireServer(tool) end)
                notify("Dropped", "1x " .. resourceName, 1)
            else
                notify("Error", resourceName .. " not found!", 2)
            end
        end
    })
    Toggles.Drop1xRes[resourceName] = toggle
end

Tabs.DropRes:AddParagraph({ Title = "Drop All Items", Content = "Drops ALL instances of a specific resource." })
Toggles.DropAllRes = {}
for _, resourceName in ipairs(Lists.Resources) do
    local cleanKey = "DropAllRes_" .. resourceName:gsub("%s+", "")
    local toggle = Tabs.DropRes:AddToggle(cleanKey, {
        Title = "Drop All " .. resourceName,
        Description = "Drops ALL " .. resourceName .. " and turns off.",
        Default = false,
        Callback = function(enabled)
            if not enabled then return end
            -- Immediately disable to prevent double‑fire
            pcall(function() toggle:SetValue(false) end)
            -- Original "Drop All" button logic
            local droppedCount = 0
            while true do
                local tool = findResourceByName(resourceName)
                if not tool then break end
                local count = tool:GetAttribute("count") or 1
                for _ = 1, count do
                    if not tool.Parent then break end
                    pcall(function() Remotes.dropItem:FireServer(tool) end)
                    task.wait(0.05)
                end
                droppedCount = droppedCount + count
            end
            if droppedCount > 0 then
                notify("Dropped", droppedCount .. "x " .. resourceName, 1)
            else
                notify("Error", resourceName .. " not found!", 2)
            end
        end
    })
    Toggles.DropAllRes[resourceName] = toggle
end

Tabs.DropRes:AddParagraph({ Title = "Master Drop", Content = "Drops EVERY resource from your inventory." })

-- Original master drop function (unchanged)
local function dropAllResourcesFunc()
    local player = game.Players.LocalPlayer
    local droppedCount = 0
    local resourceSet = {}
    for _, name in ipairs(Lists.Resources) do resourceSet[name:gsub("%s+$", "")] = true end
    local function dropMatchingInContainer(container)
        local foundAny = true
        while foundAny do
            foundAny = false
            for _, tool in pairs(container:GetChildren()) do
                if tool:IsA("Tool") then
                    local clean = tool.Name:gsub("%s+$", "")
                    if resourceSet[clean] then
                        foundAny = true
                        local count = tool:GetAttribute("count") or 1
                        for _ = 1, count do
                            if not tool.Parent then break end
                            pcall(function() Remotes.dropItem:FireServer(tool) end)
                            task.wait(0.05)
                        end
                        droppedCount = droppedCount + count
                    end
                end
            end
            task.wait(0.1)
        end
    end
    dropMatchingInContainer(player.Backpack)
    if player.Character then dropMatchingInContainer(player.Character) end
    if droppedCount > 0 then
        notify("Dropped", droppedCount .. " total resources", 1)
    else
        notify("Info", "No resources found to drop", 2)
    end
end

-- Master toggle (uses the exact same function, self‑disables)
Toggles.DropAllResMaster = Tabs.DropRes:AddToggle("DropAllResMaster", {
    Title = "⚠️ Drop ALL Resources",
    Description = "Drops every resource and turns off.",
    Default = false,
    Callback = function(enabled)
        if enabled then
            dropAllResourcesFunc()
            pcall(function() Toggles.DropAllResMaster:SetValue(false) end)
        end
    end,
})

-- ================================================================
-- DROP FOOD TAB (Self‑disabling toggles – exact replica of button logic)
-- ================================================================

Tabs.DropFood:AddParagraph({ Title = "Drop Single Item", Content = "Drops only 1 instance of the food." })
Toggles.Drop1xFood = {}
for _, foodName in ipairs(Lists.Food) do
    local cleanKey = "Drop1xFood_" .. foodName:gsub("%s+", "")
    local toggle = Tabs.DropFood:AddToggle(cleanKey, {
        Title = "Drop 1x " .. foodName,
        Description = "Drops ONE " .. foodName .. " and turns off.",
        Default = false,
        Callback = function(enabled)
            if not enabled then return end
            -- Immediately disable to prevent double‑fire
            pcall(function() toggle:SetValue(false) end)
            -- Original 1x button logic
            local tool = findFoodByName(foodName)
            if tool then
                pcall(function() Remotes.dropItem:FireServer(tool) end)
                notify("Dropped", "1x " .. foodName, 1)
            else
                notify("Error", foodName .. " not found!", 2)
            end
        end
    })
    Toggles.Drop1xFood[foodName] = toggle
end

Tabs.DropFood:AddParagraph({ Title = "Drop All Specific Items", Content = "Drops ALL instances of a specific food type." })
Toggles.DropAllFood = {}
for _, foodName in ipairs(Lists.Food) do
    local cleanKey = "DropAllFood_" .. foodName:gsub("%s+", "")
    local toggle = Tabs.DropFood:AddToggle(cleanKey, {
        Title = "Drop All " .. foodName,
        Description = "Drops ALL " .. foodName .. " and turns off.",
        Default = false,
        Callback = function(enabled)
            if not enabled then return end
            -- Immediately disable to prevent double‑fire
            pcall(function() toggle:SetValue(false) end)
            -- Original "Drop All" button logic (exactly as before)
            local droppedCount = 0
            while true do
                local tool = findFoodByName(foodName)
                if not tool then break end
                pcall(function() Remotes.dropItem:FireServer(tool) end)
                droppedCount = droppedCount + 1
                task.wait(0.1)
            end
            if droppedCount > 0 then
                notify("Dropped", droppedCount .. "x " .. foodName, 1)
            else
                notify("Error", foodName .. " not found!", 2)
            end
        end
    })
    Toggles.DropAllFood[foodName] = toggle
end

Tabs.DropFood:AddParagraph({ Title = "Master Drop", Content = "Drops every single food item currently in your inventory." })

-- Original master drop function (unchanged, also used as wrapper)
local function dropAllFoodsFunc()
    local player = game.Players.LocalPlayer
    local totalDropped = 0
    local function dropAllFoodsInContainer(container)
        local found = true
        while found do
            found = false
            for _, tool in pairs(container:GetChildren()) do
                if tool:IsA("Tool") then
                    local cleanName = tool.Name:gsub("%s+$", "")
                    for _, foodName in ipairs(Lists.Food) do
                        if cleanName == foodName:gsub("%s+$", "") then
                            pcall(function() Remotes.dropItem:FireServer(tool) end)
                            totalDropped = totalDropped + 1
                            task.wait(0.05)
                            found = true
                            break
                        end
                    end
                end
            end
        end
    end
    dropAllFoodsInContainer(player.Backpack)
    if player.Character then dropAllFoodsInContainer(player.Character) end
    if totalDropped > 0 then
        notify("Dropped", totalDropped .. " total food items", 2)
    else
        notify("Info", "No food items found to drop", 2)
    end
end

-- Master toggle (calls the exact same function, then self‑disables)
Toggles.DropAllFoodsMaster = Tabs.DropFood:AddToggle("DropAllFoodsMaster", {
    Title = "⚠️ Drop ALL Foods",
    Description = "Drops every food item and turns off.",
    Default = false,
    Callback = function(enabled)
        if enabled then
            dropAllFoodsFunc()
            pcall(function() Toggles.DropAllFoodsMaster:SetValue(false) end)
        end
    end,
})

-- ================================================================
-- CHESTS TAB
-- ================================================================
Toggles.AutoOpenCollect = Tabs.Chests:AddToggle("AutoOpenCollect", {
    Title = "Auto Open & Collect Chests", Description = "Teleports to chests, opens them, and collects ALL drops.", Default = false,
    Callback = function(enabled)
        State.AutoOpenCollect = enabled
        if enabled then
            local startPos = getCharacter() and getCharacter().HumanoidRootPart.CFrame
            Toggles.BestWeapon:SetValue(true)
            task.spawn(function()
                local visited = {}
                while State.AutoOpenCollect do
                    task.wait(1)
                    local chestFolder = getGameFolder("Chest")
                    if chestFolder then
                        local children = chestFolder:GetChildren()
                        local totalChests = #children
                        for _, chest in pairs(children) do
                            if not State.AutoOpenCollect then break end
                            if visited[chest] then continue end
                            local promptPart = chest:FindFirstChild("promptPart", true)
                            local part = promptPart or chest:FindFirstChildWhichIsA("BasePart", true)
                            if part then
                                local char = getCharacter()
                                if char then
                                    char.HumanoidRootPart.CFrame = part.CFrame * CFrame.new(0, 2, 0)
                                    task.wait(0.5)
                                    Remotes.RequestOpenChest:FireServer(chest)
                                    visited[chest] = true
                                    local dropsFound = false
                                    for _ = 1, 15 do
                                        task.wait(0.2)
                                        local dropFolder = getGameFolder("DroppedItems")
                                        if dropFolder then
                                            for _, item in pairs(dropFolder:GetChildren()) do
                                                if item:IsA("Model") then
                                                    local itemPart = item:FindFirstChildWhichIsA("BasePart", true)
                                                    if itemPart and (itemPart.Position - part.Position).Magnitude < 15 then
                                                        dropsFound = true; break
                                                    end
                                                end
                                            end
                                        end
                                        if dropsFound then break end
                                    end
                                    if dropsFound then
                                        local dropFolder = getGameFolder("DroppedItems")
                                        if dropFolder then
                                            for _, item in pairs(dropFolder:GetChildren()) do
                                                if item:IsA("Model") then
                                                    local itemPart = item:FindFirstChildWhichIsA("BasePart", true)
                                                    if itemPart and (itemPart.Position - part.Position).Magnitude < 15 then
                                                        local savedCFrame = char.HumanoidRootPart.CFrame
                                                        local cam = workspace.CurrentCamera
                                                        cam.CameraType = Enum.CameraType.Scriptable
                                                        char.HumanoidRootPart.CFrame = itemPart.CFrame
                                                        task.wait(0.1)
                                                        Remotes.collect:FireServer(item)
                                                        task.wait(0.1)
                                                        Remotes.collect:FireServer(item)
                                                        task.wait(0.1)
                                                        char.HumanoidRootPart.CFrame = savedCFrame
                                                        cam.CameraType = Enum.CameraType.Custom
                                                        Toggles.BestWeapon:SetValue(true)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                    task.wait(1)
                                end
                            end
                        end
                        if #visited >= totalChests and totalChests > 0 then break end
                    end
                end
                if startPos and getCharacter() then getCharacter().HumanoidRootPart.CFrame = startPos end
                Toggles.BestWeapon:SetValue(false)
            end)
        end
    end,
})

-- ================================================================
-- QUEST TAB
-- ================================================================
local QUEST_DATA = {
    { block = "Prop Block 01", model = "Map", targets = {"Spider", "Big Spider"} },
    { block = "Prop Block 02", model = "Radio", targets = {"Spider", "Snake"} },
    { block = "Prop Block 03", model = "Compass", targets = {"Spider", "Big Spider"} },
    { block = "Prop Block 04", model = "Plastic Bucket", targets = {"Snake", "Big Snake"} },
}

GUIRefs.questStatusParagraph = Tabs.Quest:AddParagraph({ Title = "Quest Status", Content = "Idle" })

Toggles.AutoQuest = Tabs.Quest:AddToggle("AutoQuestToggle", {
    Title = "Auto Complete Quests", Description = "Kills required entities and collects quest items.", Default = false,
    Callback = function(enabled)
        State.AutoQuestEnabled = enabled
        if enabled then
            local startPos = getCharacter() and getCharacter().HumanoidRootPart.CFrame
            Toggles.BestWeapon:SetValue(true)
            task.spawn(function()
                while State.AutoQuestEnabled do
                    task.wait(0.2)
                    local tilesFolder = getGameFolder("Tiles")
                    if not tilesFolder then continue end
                    local allDone = true
                    for _, quest in ipairs(QUEST_DATA) do
                        if not State.AutoQuestEnabled then break end
                        local block = tilesFolder:FindFirstChild(quest.block)
                        if not block then continue end
                        local questModel = block:FindFirstChild(quest.model)
                        local lock = block:FindFirstChild("Lock")
                        if lock then
                            allDone = false
                            local currentKills, requiredKills = 0, 0
                            local lockUI = lock:FindFirstChild("LockUI")
                            if lockUI then
                                local requires = lockUI:FindFirstChild("requires")
                                if requires then
                                    local unlockLabel = requires:FindFirstChild("unlockLabel")
                                    if unlockLabel and unlockLabel:IsA("TextLabel") then
                                        local c, r = unlockLabel.Text:match("(%d+)%s*/%s*(%d+)")
                                        if c and r then currentKills, requiredKills = tonumber(c), tonumber(r) end
                                    end
                                end
                            end
                            GUIRefs.questStatusParagraph.Content = string.format("%s | Kills: %d/%d", quest.model, currentKills, requiredKills)
                            if currentKills < requiredKills then
                                local entitiesFolder = getGameFolder("Entities")
                                local questPart = questModel and questModel:FindFirstChildWhichIsA("BasePart", true) or block:FindFirstChildWhichIsA("BasePart", true)
                                if entitiesFolder and questPart then
                                    local nearestEntity, nearestDist = nil, math.huge
                                    for _, ent in pairs(entitiesFolder:GetChildren()) do
                                        if ent:IsA("Model") and tableContains(quest.targets, ent.Name) then
                                            local entHRP = ent:FindFirstChild("HumanoidRootPart")
                                            if entHRP then
                                                local dist = (entHRP.Position - questPart.Position).Magnitude
                                                if dist < nearestDist then nearestDist, nearestEntity = dist, ent end
                                            end
                                        end
                                    end
                                    if nearestEntity then
                                        local entHRP = nearestEntity:FindFirstChild("HumanoidRootPart")
                                        local char = getCharacter()
                                        if char and entHRP then
                                            char.HumanoidRootPart.CFrame = entHRP.CFrame * CFrame.new(0, 10, 0)
                                            for _, p in pairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
                                            for _ = 1, 5 do
                                                if not State.AutoQuestEnabled then break end
                                                Remotes.meleeHit:FireServer({nearestEntity}, {})
                                                task.wait(0.1)
                                            end
                                        end
                                    end
                                end
                            end
                        elseif questModel then
                            allDone = false
                            local promptPart = questModel:FindFirstChild("promptPart", true)
                            local part = promptPart or questModel:FindFirstChildWhichIsA("BasePart", true)
                            local char = getCharacter()
                            
                            if part and char then
                                GUIRefs.questStatusParagraph.Content = string.format("Collecting: %s", quest.model)
                                
                                local targetPos = part.Position + Vector3.new(0, 3, 0) + (part.CFrame.RightVector * 2)
                                char.HumanoidRootPart.CFrame = CFrame.lookAt(targetPos, part.Position)
                                
                                local cam = workspace.CurrentCamera
                                local oldCamType = cam.CameraType
                                cam.CameraType = Enum.CameraType.Scriptable
                                cam.CFrame = CFrame.lookAt(targetPos + Vector3.new(0, 2, 0), part.Position)
                                
                                task.wait(0.3)
                                
                                local prompt = promptPart and promptPart:FindFirstChildOfClass("ProximityPrompt")
                                if not prompt then
                                    prompt = questModel:FindFirstChildOfClass("ProximityPrompt", true)
                                end
                                
                                if prompt then
                                    pcall(function()
                                        prompt.HoldDuration = 0
                                        prompt.RequiresLineOfSight = false
                                        prompt.MaxActivationDistance = 100
                                    end)
                                    
                                    local timeout = 0
                                    while questModel.Parent and timeout < 50 do
                                        pcall(function()
                                            prompt:InputHoldBegin()
                                            task.wait(0.05)
                                            prompt:InputHoldEnd()
                                        end)
                                        task.wait(0.1)
                                        timeout = timeout + 1
                                    end
                                else
                                    local timeout = 0
                                    while questModel.Parent and timeout < 50 do task.wait(0.1); timeout = timeout + 1 end
                                end
                                
                                cam.CameraType = oldCamType
                                task.wait(0.5)
                            end
                        end
                    end
                    if allDone then
                        GUIRefs.questStatusParagraph.Content = "All Quests Completed!"
                        State.AutoQuestEnabled = false
                        break
                    end
                end
                if startPos and getCharacter() then getCharacter().HumanoidRootPart.CFrame = startPos end
                Toggles.BestWeapon:SetValue(false)
            end)
        else
            GUIRefs.questStatusParagraph.Content = "Idle"
        end
    end,
})

-- ================================================================
-- VIP TAB
-- ================================================================

VIP.FarmAmountSlider = Tabs.VIP:AddSlider("FarmAmountSlider", {
    Title = "Target Amount", 
    Description = "Auto-stops after cutting/breaking this amount.", 
    Default = 25, Min = 1, Max = 200, Rounding = 0, 
    Callback = function(v) VIP.FarmTargetAmount = v end
})

Tabs.VIP:AddParagraph({ Title = "Farming Controls", Content = "Toggles auto-shutdown when the target is reached or the map is cleared." })

local function isTarget(obj, nameList)
    if not obj or not obj.Name then return false end
    for _, baseName in ipairs(nameList) do
        if obj.Name == baseName or obj.Name == baseName .. " " or obj.Name == baseName .. "  " then
            return true
        end
    end
    return false
end

local function runFarmLoop(nameList, toggleObj, equipToggleObj)
    if not toggleObj or not toggleObj.Value then return end

    local targetAmount = VIP.FarmTargetAmount
    local successCount = 0
    local countedModels = {}   -- prevent double‑counting the same object

    local startPos = nil
    local char = getCharacter()
    if char and char:FindFirstChild("HumanoidRootPart") then
        startPos = char.HumanoidRootPart.CFrame
    end

    if equipToggleObj then pcall(function() equipToggleObj:SetValue(true) end) end

    task.spawn(function()
        while toggleObj.Value do
            if successCount >= targetAmount then break end

            task.wait(0.15)
            local staticFolder = getGameFolder("Static")
            if not staticFolder then continue end

            local targetFound = false

            -- ── ADDED: Gather all valid, uncounted candidates ──
            local candidates = {}
            for _, obj in pairs(staticFolder:GetChildren()) do
                if isTarget(obj, nameList) and not countedModels[obj] then
                    table.insert(candidates, obj)
                end
            end

            if #candidates > 0 then
                -- Determine reference point for distance sorting
                local refPoint = nil
                local spawnLoc = workspace.Game and workspace.Game.Tiles and
                                 workspace.Game.Tiles:FindFirstChild("Basic Block") and
                                 workspace.Game.Tiles["Basic Block"]:FindFirstChild("SpawnLocation")
                if spawnLoc and spawnLoc:IsA("BasePart") then
                    refPoint = spawnLoc.Position
                else
                    -- Fallback: use character's current position (if available)
                    local charNow = getCharacter()
                    if charNow and charNow:FindFirstChild("HumanoidRootPart") then
                        refPoint = charNow.HumanoidRootPart.Position
                    end
                end
                if refPoint then
                    table.sort(candidates, function(a, b)
                        local partA = a:FindFirstChildWhichIsA("BasePart", true)
                        local partB = b:FindFirstChildWhichIsA("BasePart", true)
                        local posA = partA and partA.Position or a:GetPivot().Position
                        local posB = partB and partB.Position or b:GetPivot().Position
                        return (posA - refPoint).Magnitude < (posB - refPoint).Magnitude
                    end)
                end

                -- Pick the nearest (first after sorting) and process exactly ONE object
                local obj = candidates[1]
                if obj and not countedModels[obj] then
                    targetFound = true
                    local part = obj:FindFirstChildWhichIsA("BasePart", true)
                    if part then
                        char = getCharacter()
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            pcall(function()
                                char.HumanoidRootPart.CFrame = part.CFrame * CFrame.new(0, 5, 0)
                            end)
                            task.wait(0.2)

                            local hpCheckSuccess = false
                            local attempts = 0

                            while toggleObj.Value do
                                if not obj.Parent then break end

                                local currentHP = tonumber(obj:GetAttribute("hp"))
                                if currentHP and currentHP <= 0 then
                                    hpCheckSuccess = true
                                    break
                                end

                                pcall(function() Remotes.meleeHit:FireServer({}, {obj}) end)
                                attempts = attempts + 1

                                if attempts > 120 then break end
                                task.wait(0.05)
                            end

                            if hpCheckSuccess then
                                successCount = successCount + 1
                                countedModels[obj] = true
                            end

                            task.wait(0.05)
                        end
                    end
                end
            end
            -- ── END OF ADDED SORTING LOGIC ──

            if not targetFound then
                task.wait(1)
                local foundAny = false
                for _, obj in pairs(staticFolder:GetChildren()) do
                    if isTarget(obj, nameList) then foundAny = true; break end
                end
                if not foundAny then break end
            end
        end

        char = getCharacter()

        if startPos and char and char:FindFirstChild("HumanoidRootPart") then
            pcall(function() char.HumanoidRootPart.CFrame = startPos end)
        end

        if equipToggleObj then pcall(function() equipToggleObj:SetValue(false) end) end

        if toggleObj.Value then
            pcall(function() toggleObj:SetValue(false) end)
        end
    end)
end


Toggles.VIPCutAllTrees = Tabs.VIP:AddToggle("VIPCutAllTrees", {
    Title = "Cut All Trees", Default = false,
    Callback = function(enabled)
        if enabled then runFarmLoop(VIP.TreeNames, Toggles.VIPCutAllTrees, Toggles.BestAxe) end
    end,
})

Toggles.VIPBreakAllIronStones = Tabs.VIP:AddToggle("VIPBreakAllIronStones", {
    Title = "Break All Iron Stones", Default = false,
    Callback = function(enabled)
        if enabled then runFarmLoop(VIP.IronStoneNames, Toggles.VIPBreakAllIronStones, Toggles.BestPickaxe) end
    end,
})

Toggles.VIPBreakAllStones = Tabs.VIP:AddToggle("VIPBreakAllStones", {
    Title = "Break All Stones", Default = false,
    Callback = function(enabled)
        if enabled then runFarmLoop(VIP.StoneNames, Toggles.VIPBreakAllStones, Toggles.BestPickaxe) end
    end,
})

Toggles.VIPBushes = Tabs.VIP:AddToggle("VIPBreakAllBushes", {
    Title = "Break All Bushes", Default = false,
    Callback = function(enabled)
        if enabled then runFarmLoop(VIP.BushNames, Toggles.VIPBushes, Toggles.BestPickaxe) end
    end,
})

-- ================================================================
-- VIP TAB: AUTO-BUILD & ESCAPE
-- ================================================================
Remotes.addWood = nil
pcall(function()
    Remotes.addWood = game:GetService("ReplicatedStorage"):WaitForChild("Engine"):WaitForChild("Service"):WaitForChild("MakeFire"):WaitForChild("addWoodRemote")
end)

local function getInventoryCount(nameList)
    local count = 0
    local player = game.Players.LocalPlayer
    local function check(container)
        for _, tool in pairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                local cleanName = tool.Name:gsub("%s+$", "")
                for _, name in ipairs(nameList) do
                    if cleanName == name:gsub("%s+$", "") then count = count + (tool:GetAttribute("count") or 1); break end
                end
            end
        end
    end
    if player.Character then check(player.Character) end
    check(player.Backpack)
    return count
end

local function firePrompt(prompt)
    pcall(function()
        prompt.HoldDuration = 0; prompt.RequiresLineOfSight = false; prompt.MaxActivationDistance = math.huge
        prompt:InputHoldBegin(); task.wait(0.1); prompt:InputHoldEnd()
    end)
end

local function safeTeleport(targetCFrame)
    local char = getCharacter()
    if not char or not targetCFrame then return false end
    char.HumanoidRootPart.CFrame = targetCFrame * CFrame.new(0, 3, 0)
    task.wait(0.1)
    return true
end

local function depositMaterials(construct, materialNames)
    if not Build.AutoBuildEnabled then return false end
    local char = getCharacter()
    if not char then return false end
    local promptPart = construct:FindFirstChild("promptPart", true)
    if not promptPart then return false end
    safeTeleport(promptPart.CFrame)
    if not Build.AutoBuildEnabled then return false end
    local buildings = getGameFolder("Buildings")
    if not buildings or not buildings:FindFirstChild(construct.Name) then return false end
    local prompt = promptPart:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        task.wait(0.1)
        firePrompt(prompt); task.wait(0.1)
        firePrompt(prompt)
        
        dropAllResourcesFunc()
        return true
    end
    return false
end

local function buildCampfire()
    if not Build.AutoBuildEnabled then return false end
    local buildings = getGameFolder("Buildings")
    if not buildings then return false end
    local construct = buildings:FindFirstChild("Campfire_Construct")
    if not construct then return false end
    local part = construct:FindFirstChildWhichIsA("BasePart", true)
    if not part then return false end
    
    safeTeleport(part.CFrame)
    dropAllResourcesFunc()
    
    State.CollectResLimit = 5
    if Collector.Res.LimitSlider then pcall(function() Collector.Res.LimitSlider:SetValue(5) end) end
    if Collector.Res.Toggles["Wood"] then
        Collector.Res.Toggles["Wood"]:SetValue(true)
        while Collector.Res.Toggles["Wood"].Value do task.wait(0.1) end
    end
    if not Build.AutoBuildEnabled then return false end
    
    return depositMaterials(construct, Names.Wood)
end

local function lightCampfire()
    if not Build.AutoBuildEnabled then return false end
    local buildings = getGameFolder("Buildings")
    if not buildings then return false end
    local campfire = buildings:FindFirstChild("Campfire")
    if not campfire or campfire:GetAttribute("onFire") == true then return false end
    local char = getCharacter()
    if not char then return false end
    local part = campfire:FindFirstChildWhichIsA("BasePart", true)
    if not part then return false end
    
    State.CollectResLimit = 5
    if Collector.Res.LimitSlider then pcall(function() Collector.Res.LimitSlider:SetValue(5) end) end
    if Collector.Res.Toggles["Wood"] then
        Collector.Res.Toggles["Wood"]:SetValue(true)
        while Collector.Res.Toggles["Wood"].Value do task.wait(0.1) end
    end
    if not Build.AutoBuildEnabled then return false end
    
    safeTeleport(part.CFrame)
    if not Build.AutoBuildEnabled then return false end
    
    dropAllResourcesFunc()
    
    if Remotes.addWood then
        pcall(function() Remotes.addWood:FireServer() end)
        task.wait(0.1)
        if campfire:GetAttribute("onFire") == true then return true end
    end
    task.wait(0.2)
    return campfire:GetAttribute("onFire") == true
end

local function buildNest()
    if not Build.AutoBuildEnabled then return false end
    local buildings = getGameFolder("Buildings")
    if not buildings then return false end
    local construct = buildings:FindFirstChild("Nest_Construct")
    if not construct then return false end

    State.CollectResLimit = 3
    if Collector.Res.LimitSlider then pcall(function() Collector.Res.LimitSlider:SetValue(3) end) end
    if Collector.Res.Toggles["Stone"] then
        Collector.Res.Toggles["Stone"]:SetValue(true)
        while Collector.Res.Toggles["Stone"].Value do task.wait(0.1) end
    end
    if not Build.AutoBuildEnabled then return false end
    if not depositMaterials(construct, Names.Stone) then return false end
    buildings = getGameFolder("Buildings")
    if not buildings or not buildings:FindFirstChild("Nest_Construct") then return true end
    
    State.CollectResLimit = 5
    if Collector.Res.LimitSlider then pcall(function() Collector.Res.LimitSlider:SetValue(5) end) end
    if Collector.Res.Toggles["Wood"] then
        Collector.Res.Toggles["Wood"]:SetValue(true)
        while Collector.Res.Toggles["Wood"].Value do task.wait(0.1) end
    end
    if not Build.AutoBuildEnabled then return false end
    if not depositMaterials(construct, Names.Wood) then return false end
    buildings = getGameFolder("Buildings")
    if not buildings or not buildings:FindFirstChild("Nest_Construct") then return true end

    State.CollectResLimit = 1
    if Collector.Res.LimitSlider then pcall(function() Collector.Res.LimitSlider:SetValue(1) end) end
    if Collector.Res.Toggles["Wood"] then
        Collector.Res.Toggles["Wood"]:SetValue(true)
        while Collector.Res.Toggles["Wood"].Value do task.wait(0.1) end
    end
    if not Build.AutoBuildEnabled then return false end
    if not depositMaterials(construct, Names.Wood) then return false end
    buildings = getGameFolder("Buildings")
    if not buildings or not buildings:FindFirstChild("Nest_Construct") then return true end

    return false
end

local function buildTent()
    if not Build.AutoBuildEnabled then return false end
    local buildings = getGameFolder("Buildings")
    if not buildings then return false end
    local construct = buildings:FindFirstChild("Tent_Construct")
    if not construct then return false end

    State.CollectResLimit = 5
    if Collector.Res.LimitSlider then pcall(function() Collector.Res.LimitSlider:SetValue(5) end) end
    if Collector.Res.Toggles["Stone"] then
        Collector.Res.Toggles["Stone"]:SetValue(true)
        while Collector.Res.Toggles["Stone"].Value do task.wait(0.1) end
    end
    if not Build.AutoBuildEnabled then return false end
    if not depositMaterials(construct, Names.Stone) then return false end
    buildings = getGameFolder("Buildings")
    if not buildings or not buildings:FindFirstChild("Tent_Construct") then return true end

    State.CollectResLimit = 4
    if Collector.Res.LimitSlider then pcall(function() Collector.Res.LimitSlider:SetValue(4) end) end
    if Collector.Res.Toggles["Stone"] then
        Collector.Res.Toggles["Stone"]:SetValue(true)
        while Collector.Res.Toggles["Stone"].Value do task.wait(0.1) end
    end
    if not Build.AutoBuildEnabled then return false end
    if not depositMaterials(construct, Names.Stone) then return false end
    buildings = getGameFolder("Buildings")
    if not buildings or not buildings:FindFirstChild("Tent_Construct") then return true end
    
    State.CollectResLimit = 3
    if Collector.Res.LimitSlider then pcall(function() Collector.Res.LimitSlider:SetValue(3) end) end
    if Collector.Res.Toggles["Wood"] then
        Collector.Res.Toggles["Wood"]:SetValue(true)
        while Collector.Res.Toggles["Wood"].Value do task.wait(0.1) end
    end
    if not Build.AutoBuildEnabled then return false end
    if not depositMaterials(construct, Names.Wood) then return false end
    buildings = getGameFolder("Buildings")
    if not buildings or not buildings:FindFirstChild("Tent_Construct") then return true end

    return false
end

local function buildFurnace()
    if not Build.AutoBuildEnabled then return false end
    local buildings = getGameFolder("Buildings")
    if not buildings then return false end
    local construct = buildings:FindFirstChild("Furnace_Construct")
    if not construct then return false end

    for cycle = 1, 4 do
        State.CollectResLimit = 5
        if Collector.Res.LimitSlider then pcall(function() Collector.Res.LimitSlider:SetValue(5) end) end
        if Collector.Res.Toggles["Stone"] then
            Collector.Res.Toggles["Stone"]:SetValue(true)
            while Collector.Res.Toggles["Stone"].Value do task.wait(0.1) end
        end
        if not Build.AutoBuildEnabled then return false end
        if not depositMaterials(construct, Names.Stone) then return false end
        buildings = getGameFolder("Buildings")
        if not buildings or not buildings:FindFirstChild("Furnace_Construct") then return true end
    end
    
    for cycle = 1, 2 do
        State.CollectResLimit = 5
        if Collector.Res.LimitSlider then pcall(function() Collector.Res.LimitSlider:SetValue(5) end) end
        if Collector.Res.Toggles["Wood"] then
            Collector.Res.Toggles["Wood"]:SetValue(true)
            while Collector.Res.Toggles["Wood"].Value do task.wait(0.1) end
        end
        if not Build.AutoBuildEnabled then return false end
        if not depositMaterials(construct, Names.Wood) then return false end
        buildings = getGameFolder("Buildings")
        if not buildings or not buildings:FindFirstChild("Furnace_Construct") then return true end
    end

    return false
end

local function prepareFurnace()
    if Build.furnacePrepared then return true end
    local buildings = getGameFolder("Buildings")
    if not buildings then return false end
    
    local furnace = buildings:FindFirstChild("Furnace")
    if not furnace then return false end
    
    local targetPart = furnace:FindFirstChild(Build.TargetFurnacePart, true)
    if not targetPart then
        print("[AutoBuild] Warning: " .. Build.TargetFurnacePart .. " not found. Using default BasePart.")
        targetPart = furnace:FindFirstChildWhichIsA("BasePart", true)
    end
    if not targetPart then return false end
    
    local targetCFrame = targetPart.CFrame 
        * CFrame.new(Build.OFFSET_X, Build.OFFSET_Y, Build.OFFSET_Z) 
        * CFrame.Angles(math.rad(Build.ROTATE_X), math.rad(Build.ROTATE_Y), math.rad(Build.ROTATE_Z))

    for cycle = 1, 3 do
        safeTeleport(targetCFrame)
        
        State.CollectResLimit = 5
        if Collector.Res.LimitSlider then pcall(function() Collector.Res.LimitSlider:SetValue(5) end) end
        if Collector.Res.Toggles["Iron Ore"] then
            Collector.Res.Toggles["Iron Ore"]:SetValue(true)
            while Collector.Res.Toggles["Iron Ore"].Value do task.wait(0.1) end
        end
        
        safeTeleport(targetCFrame)
        dropAllResourcesFunc()
        
        buildings = getGameFolder("Buildings")
        if not buildings or not buildings:FindFirstChild("Furnace") then Build.furnacePrepared = true; return true end
        
        State.CollectResLimit = 5
        if Collector.Res.LimitSlider then pcall(function() Collector.Res.LimitSlider:SetValue(5) end) end
        if Collector.Res.Toggles["Wood"] then
            Collector.Res.Toggles["Wood"]:SetValue(true)
            while Collector.Res.Toggles["Wood"].Value do task.wait(0.1) end
        end
        
        safeTeleport(targetCFrame)
        dropAllResourcesFunc()
        
        buildings = getGameFolder("Buildings")
        if not buildings or not buildings:FindFirstChild("Furnace") then Build.furnacePrepared = true; return true end
    end
    
    Build.furnacePrepared = true
    return true
end

local function buildBoat()
    if not Build.AutoBuildEnabled then return false end
    local buildings = getGameFolder("Buildings")
    if not buildings then return false end
    local construct = buildings:FindFirstChild("Boat_Construct")
    if not construct then return false end
    local part = construct:FindFirstChildWhichIsA("BasePart", true)
    if not part then return false end

    if not Build.boatWoodStoneDone then
        for cycle = 1, 4 do
            safeTeleport(part.CFrame)
            if not Build.AutoBuildEnabled then return false end
            
            State.CollectResLimit = 5
            if Collector.Res.LimitSlider then pcall(function() Collector.Res.LimitSlider:SetValue(5) end) end
            if Collector.Res.Toggles["Stone"] then
                Collector.Res.Toggles["Stone"]:SetValue(true)
                while Collector.Res.Toggles["Stone"].Value do task.wait(0.1) end
            end
            if not Build.AutoBuildEnabled then return false end
            if not depositMaterials(construct, Names.Stone) then return false end
            buildings = getGameFolder("Buildings")
            if not buildings or not buildings:FindFirstChild("Boat_Construct") then Build.boatWoodStoneDone = true; return true end
            
            State.CollectResLimit = 5
            if Collector.Res.LimitSlider then pcall(function() Collector.Res.LimitSlider:SetValue(5) end) end
            if Collector.Res.Toggles["Wood"] then
                Collector.Res.Toggles["Wood"]:SetValue(true)
                while Collector.Res.Toggles["Wood"].Value do task.wait(0.1) end
            end
            if not Build.AutoBuildEnabled then return false end
            if not depositMaterials(construct, Names.Wood) then return false end
            buildings = getGameFolder("Buildings")
            if not buildings or not buildings:FindFirstChild("Boat_Construct") then Build.boatWoodStoneDone = true; return true end
        end
        Build.boatWoodStoneDone = true
    end

    if not Build.autoQuestDone then
        local startPos = getCharacter() and getCharacter().HumanoidRootPart.Position
        Toggles.AutoQuest:SetValue(true); notify("Completing Quests", "", 1)
        local termination = 0
        while true do
            task.wait(2); termination = termination + 2
            local currentPosition = getCharacter() and getCharacter().HumanoidRootPart.Position                
            if startPos and currentPosition then
                if (startPos - currentPosition).Magnitude <= 3 or termination > 120 then
                    Toggles.AutoQuest:SetValue(false)
                    break
                end
            end
        end
        Build.autoQuestDone = true
    end
    if not Build.AutoBuildEnabled then return end

        local savedIronCollector = State.CollectIronIngot
    State.CollectIronIngot = false

    -- Use the Collect Res system for Iron Ingots in batches of 5
    State.CollectResLimit = 5
    if Collector.Res.LimitSlider then
        pcall(function() Collector.Res.LimitSlider:SetValue(5) end)
    end

    while Build.AutoBuildEnabled do
        buildings = getGameFolder("Buildings")
        if not buildings or not buildings:FindFirstChild("Boat_Construct") then
            State.CollectIronIngot = savedIronCollector
            return true
        end

        -- Start collecting Iron Ingots (automatically stops after 5)
        if Collector.Res.Toggles["Iron Ingot"] then
            -- Ensure a clean start
            pcall(function() Collector.Res.Toggles["Iron Ingot"]:SetValue(false) end)
            task.wait(0.1)
            Collector.Res.Toggles["Iron Ingot"]:SetValue(true)
        end

        -- Wait until the batch is finished (toggle auto-disables)
        while Collector.Res.Toggles["Iron Ingot"] and Collector.Res.Toggles["Iron Ingot"].Value do
            task.wait(0.1)
        end

        if not Build.AutoBuildEnabled then break end

        -- Deposit any collected iron ingots
        if getInventoryCount(Names.IronIngot) > 0 then
            depositMaterials(construct, Names.IronIngot)
        end

        task.wait(1)  -- short pause between batches
    end

    State.CollectIronIngot = savedIronCollector
    return false

end

local function escape()
    if not Build.AutoBuildEnabled then return false end
    local buildings = getGameFolder("Buildings")
    if not buildings then return false end
    local boat = buildings:FindFirstChild("Boat")
    if not boat then return false end
    
    local char = getCharacter()
    if not char then return false end
    
    local promptPart = boat:FindFirstChild("promptPart", true)
    local part = promptPart or boat:FindFirstChildWhichIsA("BasePart", true)
    if part then
        safeTeleport(part.CFrame)
        task.wait(0.5)
    end
    
    local escapeTriggered = false
    for i = 1, 3 do
        pcall(function() Remotes.escape:FireServer() end)
        task.wait(0.5)
        
        local gameResultGui = game.Players.LocalPlayer.PlayerGui:FindFirstChild("GameResult")
        if gameResultGui then
            escapeTriggered = true
            break
        end
    end
    
    if not escapeTriggered then
        print("[AutoBuild] ❌ Failed to trigger escape remote. Retrying later...")
        return false
    end
    
    local gameResultGui = game.Players.LocalPlayer.PlayerGui:FindFirstChild("GameResult")
    if not gameResultGui then return false end
    
    local bg = gameResultGui:FindFirstChild("bg")
    local frame = bg and bg:FindFirstChild("frame")
    local goLobbyBtn = frame and frame:FindFirstChild("goLobbyBtn")
    
    if not goLobbyBtn then
        local success = pcall(function()
            bg = gameResultGui:WaitForChild("bg", 5)
            frame = bg:WaitForChild("frame", 5)
            goLobbyBtn = frame:WaitForChild("goLobbyBtn", 5)
        end)
        if not success or not goLobbyBtn then
            print("[AutoBuild] ❌ Could not find goLobbyBtn.")
            return false
        end
    end
    
    local timeout = 0
    while not goLobbyBtn.Visible and timeout < 10 do
        task.wait(0.1)
        timeout = timeout + 0.1
    end
    
    if not goLobbyBtn.Visible then
        print("[AutoBuild] ❌ goLobbyBtn did not become visible in time.")
        return false
    end
    
    pcall(function() Remotes.LobbyTeleport:FireServer() end)
    
    timeout = 0
    while workspace:FindFirstChild("Game") and timeout < 15 do
        task.wait(0.5)
        timeout = timeout + 0.5
    end
    
    local success = not workspace:FindFirstChild("Game")
    if success then
        print("[AutoBuild] 🎉 Successfully escaped and returned to lobby!")
    else
        print("[AutoBuild] ❌ Escape remote fired, but failed to return to lobby in time.")
    end
    
    return success
end

Toggles.AutoBuild = Tabs.VIP:AddToggle("AutoBuild", {
    Title = "Auto-Build & Escape (V10 Algorithm)", Description = "Fully compliant with the Escape algorithm. Safe in solo/multiplayer.", Default = false,
    Callback = function(enabled)
        if enabled then
            if Build.AutoBuildThread and coroutine.status(Build.AutoBuildThread) ~= "dead" then notify("Auto-Build", "Already running!", 2); return end
            
            Build.AutoBuildEnabled = true
            Build.AutoBuildThread = coroutine.create(function()
                VIP.FarmTargetAmount = 25
                if VIP.FarmAmountSlider then pcall(function() VIP.FarmAmountSlider:SetValue(25) end) end
                if not Build.treeCuttingDone then
                    Toggles.VIPCutAllTrees:SetValue(true)
                    notify("Auto-Build", "Cutting " .. VIP.FarmTargetAmount .. " Trees...", 2)
                    while Toggles.VIPCutAllTrees.Value do task.wait(0.5) end 
                    Build.treeCuttingDone = true
                end

                if not Build.AutoBuildEnabled then return end

                if not Build.autoOpenCollectDone then 
                    Toggles.AutoOpenCollect:SetValue(false); notify("Chest Farm", "", 1); task.wait(0.1); Toggles.AutoOpenCollect:SetValue(false); Build.autoOpenCollectDone = true  
                end

                if not Build.AutoBuildEnabled then return end

                VIP.FarmTargetAmount = 14
                if VIP.FarmAmountSlider then pcall(function() VIP.FarmAmountSlider:SetValue(14) end) end
                if not Build.ironStoneBreakingDone then
                    Toggles.VIPBreakAllIronStones:SetValue(true)
                    notify("Auto-Build", "Breaking " .. VIP.FarmTargetAmount .. " Iron Stones...", 2)
                    while Toggles.VIPBreakAllIronStones.Value do task.wait(0.5) end
                    Build.ironStoneBreakingDone = true
                end
                if not Build.AutoBuildEnabled then return end
                
                notify("Building Started", "", 1)
                print("[AutoBuild] 🚀 Starting V10 Algorithm...")
                while Build.AutoBuildEnabled do
                    task.wait(0.1)
                    local buildings = getGameFolder("Buildings")
                    if not buildings then task.wait(0.1); continue end

                    if buildings:FindFirstChild("Campfire_Construct") then if buildCampfire() then print("[AutoBuild] Campfire building cycle done.") end; continue end
                    if buildings:FindFirstChild("Campfire") and buildings:FindFirstChild("Campfire"):GetAttribute("onFire") ~= true then if lightCampfire() then print("[AutoBuild] Campfire lit.") end; continue end
                    if buildings:FindFirstChild("Nest_Construct") then if buildNest() then print("[AutoBuild] Nest cycle done.") end; continue end
                    if buildings:FindFirstChild("Tent_Construct") then if buildTent() then print("[AutoBuild] Tent cycle done.") end; continue end
                    if buildings:FindFirstChild("Furnace_Construct") then if buildFurnace() then print("[AutoBuild] Furnace built.") end; continue end
                    if buildings:FindFirstChild("Furnace") and not Build.furnacePrepared then if prepareFurnace() then print("[AutoBuild] Furnace prepared (3 cycles).") end; continue end
                    if buildings:FindFirstChild("Boat_Construct") then if buildBoat() then print("[AutoBuild] Boat construction completed.") end; continue end
                    if buildings:FindFirstChild("Boat") then
                        if State.DoNotEscape then
                            notify("Auto‑Build", "Boat built – stopping (escape disabled).", 3)
                            Build.AutoBuildEnabled = false
                            break
                        else
                            if escape() then
                                print("[AutoBuild] 🎉 Escaped successfully!")
                                Build.AutoBuildEnabled = false
                                break
                            end
                        end
                    end                    
                    task.wait(0.1)
                end
                
                print("[AutoBuild] 🛑 Stopped.")
                Build.AutoBuildThread = nil; Build.AutoBuildEnabled = false
            end)
            coroutine.resume(Build.AutoBuildThread)
        else
            Build.AutoBuildEnabled = false
            if Build.AutoBuildThread and coroutine.status(Build.AutoBuildThread) ~= "dead" then
                local waitTime = 0
                while coroutine.status(Build.AutoBuildThread) ~= "dead" and waitTime < 3 do task.wait(0.1); waitTime = waitTime + 0.1 end
            end
            Build.AutoBuildThread = nil; notify("Auto-Build", "Stopped.", 2)
        end
    end
})

Toggles.DoNotEscape = Tabs.VIP:AddToggle("DoNotEscape", {
    Title       = "Do not Escape",
    Description = "When enabled, Auto‑Build will stop after building the Boat without escaping.",
    Default     = State.DoNotEscape,
    Callback    = function(enabled)
        State.DoNotEscape = enabled
    end,
})
-- ================================================================
-- AUTO TAB (Master Context-Aware Control-Death Recovery) - PERSISTENT DAEMON
-- ================================================================
local Match = {
    MatchRoomModule = game:GetService("ReplicatedStorage"):WaitForChild("Module"):WaitForChild("Addons"):WaitForChild("MatchRoom"),
}

Remotes.configRoom = Match.MatchRoomModule:WaitForChild("configRoomRemote")
Remotes.startGame  = Match.MatchRoomModule:WaitForChild("startGameRemote")
Remotes.exitRoom   = Match.MatchRoomModule:WaitForChild("exitRoomRemote")

Match.isGameServer = function()
    return workspace:FindFirstChild("Game") ~= nil
end

Match.isLobby = function()
    return workspace:FindFirstChild("Lobby") ~= nil and not Match.isGameServer()
end

Match.waitForGameServerReady = function(timeout)
    timeout = timeout or 30
    local elapsed = 0
    
    while not workspace:FindFirstChild("Game") and elapsed < timeout do
        task.wait(0.5)
        elapsed = elapsed + 0.5
    end
    
    if not workspace:FindFirstChild("Game") then return false end
    
    local essentialFolders = { "Static", "Entities", "Buildings", "DroppedItems" }
    for _, folderName in ipairs(essentialFolders) do
        while not workspace.Game:FindFirstChild(folderName) and elapsed < timeout do
            task.wait(0.5)
            elapsed = elapsed + 0.5
        end
    end
    
    task.wait(5)
    return true
end

local function AutoJoinSoloDaemon()
    local LocalPlayer = game.Players.LocalPlayer
    
    while Match.isLobby() do
        task.wait(1)
        
        local MatchRooms = workspace:FindFirstChild("Lobby") and workspace.Lobby:FindFirstChild("MatchRooms")
        if not MatchRooms then continue end
        
        local targetRoom = nil
        
        for _, room in ipairs(MatchRooms:GetChildren()) do
            local queueGui = room:FindFirstChild("QueueGui", true)
            if queueGui then
                local timer = queueGui:FindFirstChild("Timer", true)
                if timer and timer:IsA("TextLabel") and string.find(timer.Text, "1%+ Players Required") then
                    targetRoom = room
                    break
                end
            end
        end

        if targetRoom then
            notify("Auto Master", "Found empty room! Entering...", 1)
            
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart")
            
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
            
            local pivot = targetRoom:GetPivot()
            if pivot then
                hrp.CFrame = pivot + Vector3.new(0, 5, 0)
            else
                local part = targetRoom:FindFirstChildWhichIsA("BasePart", true)
                if part then hrp.CFrame = part.CFrame + Vector3.new(0, 5, 0) end
            end
            
            task.wait(0.2)
            
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
            
            local joined = false
            local isOwner = false
            
            for i = 1, 10 do 
                task.wait(0.1)
                if LocalPlayer:GetAttribute("isInMatchRoom") then
                    joined = true
                    if LocalPlayer:GetAttribute("isRoomOwner") then
                        isOwner = true
                        break
                    else
                        break
                    end
                end
            end
            
            if isOwner then
                notify("Auto Master", "Success! Configuring Solo & Starting...", 2)
                Remotes.configRoom:FireServer(1)
                task.wait(0.2)
                Remotes.startGame:FireServer()
                
                for i = 1, 60 do
                    task.wait(0.1)
                    if not Match.isLobby() then break end
                end
                
                if Match.isLobby() then
                    notify("Auto Master", "Teleport delayed. Retrying...", 2)
                else
                    notify("Auto Master", "Left Lobby. Switching to Game Mode.", 3)
                    break
                end
                
            elseif joined then
                notify("Auto Master", "Room sniped! Exiting and retrying...", 1)
                Remotes.exitRoom:FireServer()
                task.wait(1)
            end
        end
    end
end

local function DeathRecoveryDaemon()
    local LocalPlayer = game.Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

    while Match.isGameServer() do
        task.wait(0.5)
        
        local char = getCharacter()
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local isDead = (humanoid and humanoid.Health <= 0)
        
        if isDead then
            notify("Auto Master", "Player died! Waiting for Return Option...", 3)
            
            local deathScreen = PlayerGui:FindFirstChild("DeathScreen")
            local gameResult = PlayerGui:FindFirstChild("GameResult")
            
            local targetGui = deathScreen or gameResult
            
            if targetGui then
                local bg = targetGui:FindFirstChild("bg", true)
                if bg then
                    if not bg.Visible then
                        pcall(function()
                            bg:GetPropertyChangedSignal("Visible"):Wait()
                        end)
                    end
                    
                    if bg.Visible then
                        notify("Auto Master", "Return Option Available! Teleporting to Lobby...", 2)
                        
                        if Remotes.LobbyTeleport then
                            pcall(function()
                                Remotes.LobbyTeleport:FireServer()
                            end)
                        else
                            local goLobbyBtn = nil
                            if targetGui.Name == "DeathScreen" then
                                goLobbyBtn = bg:FindFirstChild("goLobbyBtn", true)
                            elseif targetGui.Name == "GameResult" then
                                local frame = bg:FindFirstChild("frame", true)
                                if frame then
                                    goLobbyBtn = frame:FindFirstChild("goLobbyBtn", true)
                                end
                            end
                            
                            if goLobbyBtn then
                                pcall(function() goLobbyBtn.Activated:Fire() end)
                                task.wait(0.2)
                                pcall(function() goLobbyBtn.MouseButton1Click:Fire() end)
                            end
                        end
                        
                        notify("Auto Master", "Returning to Lobby...", 3)
                        while Match.isGameServer() do
                            task.wait(0.5)
                        end
                        notify("Auto Master", "Back in Lobby! Resuming Solo Search...", 3)
                        break
                    end
                end
            end
        end
    end
end

Toggles.AutoMaster = Tabs.Auto:AddToggle("AutoMaster", {
    Title       = "Master Auto (Lobby Join / Game Build)",
    Description = "In Lobby: Continuously searches for a Solo room. In Game: Starts Auto-Build & Death Recovery.",
    Default     = true,
    Callback    = function(enabled)
        if not enabled then return end
        
        task.spawn(function()
            if Match.isGameServer() then
                notify("Auto Master", "Game Server detected! Waiting for world to load...", 4)
                
                local ready = Match.waitForGameServerReady(30)
                
                if ready then
                    if Toggles.AutoBuild then
                        notify("Auto Master", "World loaded! Starting Auto-Build...", 3)
                        Toggles.AutoBuild:SetValue(true)
                    else
                        notify("Auto Master", "Warning: Could not link AutoBuild toggle.", 3)
                    end
                    
                    notify("Auto Master", "Death Recovery System Active.", 3)
                    task.spawn(DeathRecoveryDaemon)
                else
                    notify("Auto Master", "Timed out waiting for world to load.", 4)
                end
                
            elseif Match.isLobby() then
                notify("Auto Master", "Lobby Detected! Starting persistent search for Solo room...", 3)
                task.spawn(AutoJoinSoloDaemon)
                
            else
                notify("Auto Master", "Unknown environment. Please toggle again.", 2)
            end
        end)
    end,
})

-- Auto-Execute on Script Load
task.spawn(function()
    task.wait(3)
    
    if Toggles.AutoMaster.Value then
        if Match.isGameServer() then
            notify("Auto Master", "Game Server detected! Waiting for world to load...", 4)
            local ready = Match.waitForGameServerReady(30)
            if ready then
                if Toggles.AutoBuild then 
                    notify("Auto Master", "World loaded! Starting Auto-Build...", 3)
                    Toggles.AutoBuild:SetValue(true) 
                end
                notify("Auto Master", "Death Recovery System Active.", 3)
                task.spawn(DeathRecoveryDaemon)
            end
        elseif Match.isLobby() then
            notify("Auto Master", "Lobby Detected! Starting persistent search for Solo room...", 3)
            task.spawn(AutoJoinSoloDaemon)
        end
    end
end)

notify("Script Loaded", "Enjoy VIP Features", 2)

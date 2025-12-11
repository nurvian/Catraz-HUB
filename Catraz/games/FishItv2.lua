-------- WindUI Loadstring --------
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-------- [[ CORE SERVICES & VARIABLES ]] --------
local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    RunService = game:GetService("RunService"),
    TweenService = game:GetService("TweenService"),
    VirtualInputManager = game:GetService("VirtualInputManager"),
    VirtualUser = game:GetService("VirtualUser"),
    HttpService = game:GetService("HttpService"),
    Lighting = game:GetService("Lighting"),
    CoreGui = game:GetService("CoreGui"),
    Stats = game:GetService("Stats")
}

local LocalPlayer = Services.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- [[ FISH IT CORE VARIABLES ]] --
local Events = nil
local AllFishNames = {} 
local RarityListString = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret"}
local GlobalVariants = {"Shiny", "Big", "Sparkling", "Frozen", "Albino", "Dark", "Electric", "Radioactive", "Negative", "Golden", "Rainbow", "Ghost", "Solar", "Sand"}
local ItemInfoCache = {} -- Cache: [150] = "Blob Fish"
local DatabaseIndexed = false 

-- Config State
local Config = {
    AutoFish = false,
    BlatantMode = false,
    FishingMode = "Instant",
    AutoCatch = false,
    AutoSell = false,
    AutoSellMode = "Time", -- "Time" or "Capacity"
    SellThreshold = 2000, 
    GPUSaver = false,
    FishDelay = 0.9,
    CatchDelay = 0.2,
    SellDelay = 30,
    AutoFavorite = false,
    AutoUnfavorite = false, 
    FavInterval = 2,
    FavRarities = {}, 
    FavNames = {},    
    FavVariants = {}, 
    UnfavRarities = {},
    UnfavNames = {},
    UnfavVariants = {}
}

-- Global Settings (From The Forge)
local _G_Settings = {
    Fullbright = false,
    NoFog = false,
    WalkSpeed = 16,
    JumpPower = 50,
    InfJump = false
}

-------- [[ CATRAZ THEME SETUP ]] --------
WindUI:AddTheme({
    Name = "Native Red",
    Accent = Color3.fromHex("#ff5e5e"), 
    Background = Color3.fromHex("#1a0b0b"), 
    BackgroundTransparency = 0.8, 
    Outline = Color3.fromHex("#451a1a"), 
    Text = Color3.fromHex("#fcfcfc"), 
    Placeholder = Color3.fromHex("#8a4b4b"),
    Button = Color3.fromHex("#2b1212"), 
    Icon = Color3.fromHex("#ffcccc"),
    Hover = Color3.fromHex("#3d1a1a"), 
    WindowBackground = Color3.fromHex("#140808"), 
    WindowShadow = Color3.fromHex("#000000"),
    WindowTopbarButtonIcon = Color3.fromHex("#ffcccc"),
    WindowTopbarTitle = Color3.fromHex("#fcfcfc"), 
    WindowTopbarAuthor = Color3.fromHex("#aa5555"),
    WindowTopbarIcon = Color3.fromHex("#ff5e5e"),
    TabBackground = Color3.fromHex("#0f0505"), 
    TabTitle = Color3.fromHex("#fcfcfc"),
    TabIcon = Color3.fromHex("#cc8888"),
    ElementBackground = Color3.fromHex("#260f0f"), 
    ElementTitle = Color3.fromHex("#fcfcfc"),
    ElementDesc = Color3.fromHex("#b36b6b"),
    ElementIcon = Color3.fromHex("#ffcccc"),
    Toggle = Color3.fromHex("#fcfcfc"), 
    ToggleBar = Color3.fromHex("#3d1a1a"),
    Checkbox = Color3.fromHex("#fcfcfc"),
    CheckboxIcon = Color3.fromHex("#1a0b0b"), 
    Slider = Color3.fromHex("#fcfcfc"),
    SliderThumb = Color3.fromHex("#ff5e5e"), 
})

WindUI:SetTheme("Native Red")

local Window = WindUI:CreateWindow({
    Title = "Catraz Hub | Fish It",
    Folder = "CatrazHub",
    Icon = "fish-symbol", 
    NewElements = true,
    Transparent = true,
    Theme = "Native Red",
    HideSearchBar = true,
    BackgroundImageTransparency = 1,
    OpenButton = { Title = "Open Hub", Enabled = false },
    KeySystem = {                                                   
        Note = "Catraz Hub Key System",              
        API = {                                                     
            { 
                Title = "Platoboost",
                Desc = "Click to copy link.", 
                Icon = "key", 
                Type = "platoboost",                                
                ServiceId = 15690, 
                Secret = "6b58c208-1a3e-4085-81f8-44a0ed290b88", 
            },                                                      
        },                                                          
    },                                                              
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function() end,
    },
})

-- [[ VERSION TAG ]] --
Window:Tag({
    Title = "v2.0-FULL",
    Icon = "github", 
    Color = Color3.fromHex("#0a0a0a"), 
})

Window:DisableTopbarButtons({
    "Close", 
    "Minimize", 
    "Fullscreen",
})

WindUI:Notify({
    Title = "Catraz Hub Loaded",
    Content = "Success load Fish It (Full Logic)",
    Duration = 5,
    Icon = "badge-check", 
})

-- [[ CUSTOM TOGGLE UI SYSTEM & MINI DASHBOARD ]] --
task.spawn(function()
    local NameUI = "CatrazHubSystem"
    if Services.CoreGui:FindFirstChild(NameUI) then Services.CoreGui[NameUI]:Destroy() end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = NameUI
    ScreenGui.Parent = Services.CoreGui
    ScreenGui.ResetOnSpawn = false
    
    local IsMenuOpen = true 
    
    -- 1. TOGGLE BUTTON
    local ToggleBtn = Instance.new("ImageButton")
    ToggleBtn.Name = "MainButton"
    ToggleBtn.Parent = ScreenGui
    ToggleBtn.Position = UDim2.new(0.05, 0, 0.45, 0)
    ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
    ToggleBtn.BackgroundColor3 = Color3.fromHex("#140808")
    ToggleBtn.BackgroundTransparency = 0.2
    ToggleBtn.Draggable = true
    ToggleBtn.AutoButtonColor = false 

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0.3, 0)
    BtnCorner.Parent = ToggleBtn

    local BtnStroke = Instance.new("UIStroke")
    BtnStroke.Parent = ToggleBtn
    BtnStroke.Color = Color3.fromHex("#ff5e5e")
    BtnStroke.Thickness = 2.5
    BtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local IconImage = Instance.new("ImageLabel")
    IconImage.Parent = ToggleBtn
    IconImage.BackgroundTransparency = 1 
    IconImage.AnchorPoint = Vector2.new(0.5, 0.5)
    IconImage.Position = UDim2.new(0.5, 0, 0.5, 0)
    IconImage.Size = UDim2.new(0.7, 0, 0.7, 0)
    IconImage.Image = "rbxassetid://124162045221605" 
    IconImage.ScaleType = Enum.ScaleType.Fit
    
    -- 2. MINI DASHBOARD
    local StatusFrame = Instance.new("Frame")
    StatusFrame.Name = "StatusDashboard"
    StatusFrame.Parent = ScreenGui
    StatusFrame.Position = UDim2.new(0.5, 0, 0.05, 0)
    StatusFrame.AnchorPoint = Vector2.new(0.5, 0)
    StatusFrame.Size = UDim2.new(0, 300, 0, 65)
    StatusFrame.BackgroundColor3 = Color3.fromHex("#0f0505")
    StatusFrame.BackgroundTransparency = 0.1
    StatusFrame.Visible = false

    local StatusCorner = Instance.new("UICorner"); StatusCorner.CornerRadius = UDim.new(0, 8); StatusCorner.Parent = StatusFrame
    local StatusStroke = Instance.new("UIStroke"); StatusStroke.Parent = StatusFrame; StatusStroke.Color = Color3.fromHex("#451a1a"); StatusStroke.Thickness = 2
    
    local AccentBar = Instance.new("Frame")
    AccentBar.Parent = StatusFrame
    AccentBar.BackgroundColor3 = Color3.fromHex("#ff5e5e")
    AccentBar.Size = UDim2.new(0, 4, 1, 0)
    AccentBar.BorderSizePixel = 0
    local BarCorner = Instance.new("UICorner"); BarCorner.Parent = AccentBar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Parent = StatusFrame
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position = UDim2.new(0, 15, 0, 5)
    TitleLabel.Size = UDim2.new(1, -20, 0, 20)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = "CATRAZ HUB | <font color='#ff5e5e'>FISH IT</font>"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 14
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.RichText = true

    local StatsLabel = Instance.new("TextLabel")
    StatsLabel.Parent = StatusFrame
    StatsLabel.BackgroundTransparency = 1
    StatsLabel.Position = UDim2.new(0, 15, 0, 28)
    StatsLabel.Size = UDim2.new(1, -20, 0, 30)
    StatsLabel.Font = Enum.Font.GothamMedium
    StatsLabel.Text = "Loading Stats..."
    StatsLabel.TextColor3 = Color3.fromHex("#cccccc")
    StatsLabel.TextSize = 12
    StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Animation & Logic
    local function PlayClickAnim()
        Services.TweenService:Create(ToggleBtn, TweenInfo.new(0.1), {Size = UDim2.new(0, 40, 0, 40)}):Play()
        task.wait(0.1)
        Services.TweenService:Create(ToggleBtn, TweenInfo.new(0.3, Enum.EasingStyle.Elastic), {Size = UDim2.new(0, 50, 0, 50)}):Play()
    end

    local function FormatTime(seconds)
        local h = math.floor(seconds / 3600)
        local m = math.floor((seconds % 3600) / 60)
        local s = math.floor(seconds % 60)
        return string.format("%02d:%02d:%02d", h, m, s)
    end

    ToggleBtn.MouseButton1Click:Connect(function()
        PlayClickAnim()
        Window:Toggle() 
        IsMenuOpen = not IsMenuOpen
        StatusFrame.Visible = not IsMenuOpen 
        
        if not IsMenuOpen then
            StatusFrame.BackgroundTransparency = 1
            TitleLabel.TextTransparency = 1
            StatsLabel.TextTransparency = 1
            Services.TweenService:Create(StatusFrame, TweenInfo.new(0.3), {BackgroundTransparency = 0.1}):Play()
            Services.TweenService:Create(TitleLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
            Services.TweenService:Create(StatsLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
        end
    end)

    Services.RunService.RenderStepped:Connect(function(deltaTime)
        if StatusFrame.Visible then
            local fps = math.floor(1 / deltaTime)
            local ping = math.floor(Services.Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            local runtime = FormatTime(workspace.DistributedGameTime)
            local realTime = os.date("%H:%M:%S")
            StatsLabel.Text = string.format("FPS: %d  |  Ping: %d ms\nTime: %s  |  Runtime: %s", fps, ping, realTime, runtime)
        end
    end)
end)

-------- [[ CORE LOGIC FUNCTIONS (FISH IT ORIGINAL) ]] --------

-- [[ NET EVENTS SETUP ]] --
local function SetupEvents()
    local netPackage = Services.ReplicatedStorage.Packages._Index:FindFirstChild("sleitnick_net@0.2.0")
    
    if netPackage then
        local net = netPackage.net
        Events = {
            fishing = net:WaitForChild("RE/FishingCompleted"),
            sell = net:WaitForChild("RF/SellAllItems"),
            charge = net:WaitForChild("RF/ChargeFishingRod"),
            minigame = net:WaitForChild("RF/RequestFishingMinigameStarted"),
            equip = net:WaitForChild("RE/EquipToolFromHotbar"),
            unequip = net:WaitForChild("RE/UnequipToolFromHotbar"),
            favorite = net:WaitForChild("RE/FavoriteItem"),
            buyBait = net:WaitForChild("RF/PurchaseBait"),
            buyRod = net:WaitForChild("RF/PurchaseFishingRod"),
            buyMerchant = net:WaitForChild("RF/PurchaseMarketItem"),
            buyWeather = net:WaitForChild("RF/PurchaseWeatherEvent"),
            equipInventory = net:WaitForChild("RE/EquipItem"), 
            unequipInventory = net:WaitForChild("RE/UnequipItem"),
            initiateTrade = net:WaitForChild("RF/InitiateTrade"),  
            placeTotem = net:WaitForChild("RE/SpawnTotem"),
        }
        print("✅ Events Loaded Successfully!")
    else
        warn("❌ Critical Error: Net Package not found in ReplicatedStorage!")
    end
end
SetupEvents()

-- [[ DATABASE SCANNER ]] --
local function IndexItemDatabase()
    ItemInfoCache = {} 
    AllItemNames = {}
    FishOnlyNames = {} 
    
    local RS = game:GetService("ReplicatedStorage")
    local ItemsFolder = RS:FindFirstChild("Items")
    local TotemsFolder = RS:FindFirstChild("Totems")
    
    local count = 0
    local totemCount = 0
    
    print("🔍 [DATABASE] Starting Deep Scan...")

    local function ScanDeep(folder, categoryOverride)
        if not folder then return end
        local allObjects = folder:GetDescendants()
        
        for i, obj in ipairs(allObjects) do
            if i % 300 == 0 then task.wait() end

            if obj:IsA("ModuleScript") then
                if string.sub(obj.Name, 1, 3) == "!!!" or obj:FindFirstAncestor("Packages") then
                    -- skip
                else
                    local success, result = pcall(require, obj)
                    
                    if success and type(result) == "table" and result.Data then
                        local d = result.Data
                        if d.Id then
                            local idString = tostring(d.Id) 
                            local itemName = d.Name or obj.Name
                            local itemType = categoryOverride or d.Type or "Unknown"
                            local tierNum = d.Tier or 1
                            local rarityName = RarityListString[tierNum] or "Common"

                            ItemInfoCache[idString] = { 
                                Name = itemName,
                                Type = itemType,
                                Rarity = d.Rarity or "Common",
                                RarityName = rarityName,
                                Tier = tierNum
                            }
                            
                            if not table.find(AllItemNames, itemName) then table.insert(AllItemNames, itemName) end
                            if itemType == "Fish" or itemType == "Fishes" then
                                if not table.find(FishOnlyNames, itemName) then table.insert(FishOnlyNames, itemName) end
                            end
                            if itemType == "Totems" or string.find(itemName, "Totem") then totemCount = totemCount + 1 end
                            
                            count = count + 1
                        end
                    end
                end
            end
        end
    end

    if ItemsFolder then ScanDeep(ItemsFolder, nil) end
    if TotemsFolder then ScanDeep(TotemsFolder, "Totems") end 
    
    table.sort(AllItemNames)
    table.sort(FishOnlyNames)
    DatabaseIndexed = true
    print("✅ Database Done! Total: " .. count .. " | Totem: " .. totemCount)
    return count
end

-- [[ SHOP SCANNER ]] --
local ShopData = { Rods = {}, Baits = {}, RodNames = {}, BaitNames = {} }

local function ScanShopItems()
    ShopData.Rods = {}
    ShopData.Baits = {}
    ShopData.RodNames = {}
    ShopData.BaitNames = {}
    
    local RS = game:GetService("ReplicatedStorage")
    local ItemsFolder = RS:WaitForChild("Items", 5)
    local BaitsFolder = RS:WaitForChild("Baits", 5)
    
    print("🔍 [SMART SHOP] Scanning Rods & Baits...")

    -- 1. SCAN RODS
    if ItemsFolder then
        local items = ItemsFolder:GetChildren()
        for i, obj in ipairs(items) do
            if i % 100 == 0 then task.wait() end 
            
            if obj:IsA("ModuleScript") and string.sub(obj.Name, 1, 3) == "!!!" then
                local success, result = pcall(require, obj)
                if success and result and result.Data then
                    local d = result.Data
                    local cleanName = d.Name or obj.Name
                    local id = d.Id
                    
                    if cleanName and id then
                        ShopData.Rods[cleanName] = id
                        table.insert(ShopData.RodNames, cleanName)
                    end
                end
            end
        end
    end

    -- 2. SCAN BAITS
    if BaitsFolder then
        local baits = BaitsFolder:GetChildren()
        for i, obj in ipairs(baits) do
            if obj:IsA("ModuleScript") then
                local success, result = pcall(require, obj)
                if success and result and result.Data then
                    local d = result.Data
                    local name = d.Name or obj.Name
                    local id = d.Id
                    
                    if name and id then
                        ShopData.Baits[name] = id
                        table.insert(ShopData.BaitNames, name)
                    end
                end
            end
        end
    end
    
    table.sort(ShopData.RodNames)
    table.sort(ShopData.BaitNames)
    print("✅ Shop Ready! Rods: " .. #ShopData.RodNames .. " | Baits: " .. #ShopData.BaitNames)
end
task.spawn(ScanShopItems)

-- [[ MERCHANT SCANNER ]] --
local MerchantCache = { Items = {}, DisplayNames = {} }

local function RefreshMerchantItems()
    MerchantCache.Items = {}
    MerchantCache.DisplayNames = {}
    
    local success, ReplionModule = pcall(function() return require(Services.ReplicatedStorage.Packages.Replion) end)
    local ItemUtility = require(Services.ReplicatedStorage.Shared.ItemUtility)
    local MarketData = require(Services.ReplicatedStorage.Shared.MarketItemData)
    
    if success and ReplionModule then
        local successWait, merchRep = pcall(function() return ReplionModule.Client:GetReplion("Merchant") end)
        
        if successWait and merchRep then
            local currentItems = merchRep:GetExpect("Items") or {}
            
            for _, marketID in ipairs(currentItems) do
                local marketItem = nil
                for _, v in pairs(MarketData) do
                    if v.Id == marketID then marketItem = v break end
                end
                
                if marketItem then
                    local itemData = ItemUtility.GetItemDataFromItemType(marketItem.Type, marketItem.Identifier)
                    if itemData and itemData.Data then
                        local itemName = itemData.Data.Name
                        local price = marketItem.Price or "???"
                        local displayName = itemName .. " (" .. price .. ")"
                        
                        table.insert(MerchantCache.DisplayNames, displayName)
                        MerchantCache.Items[displayName] = marketID 
                    end
                end
            end
            table.sort(MerchantCache.DisplayNames)
        end
    end
    return MerchantCache.DisplayNames
end

-- [[ INVENTORY READER (FULL LOGIC) ]] --
local function GetReplionInventory()
    local RepStorage = game:GetService("ReplicatedStorage")
    local Pkg = RepStorage:FindFirstChild("Packages")
    local ReplionModule = nil
    
    if Pkg then
        ReplionModule = Pkg:FindFirstChild("Replion") or 
                        (Pkg:FindFirstChild("_Index") and Pkg._Index:FindFirstChild("sleitnick_replion@1.2.0") and Pkg._Index["sleitnick_replion@1.2.0"].Replion)
    end
    if not ReplionModule then
        for _, v in pairs(RepStorage:GetDescendants()) do
            if v.Name == "Replion" and v:IsA("ModuleScript") then ReplionModule = v break end
        end
    end
    
    if not ReplionModule then return {} end

    local success, Lib = pcall(require, ReplionModule)
    if success and Lib and Lib.Client then
        local DataContainer = Lib.Client:GetReplion("Data")
        
        if DataContainer and DataContainer.Data and DataContainer.Data.Inventory then
            local mainInv = DataContainer.Data.Inventory
            local compiledInventory = {}
            
            -- Helper: Clone item and Tag Folder Source (CRITICAL FOR TOTEM/TRADE)
            local function AddList(list, categoryTag)
                if type(list) == "table" then
                    for _, item in pairs(list) do
                        local newItem = {
                            Id = item.Id,
                            UUID = item.UUID,
                            Quantity = item.Quantity,
                            Metadata = item.Metadata,
                            Variant = item.Variant,
                            Favorited = item.Favorited,
                            _SourceFolder = categoryTag -- LABEL RAHASIA
                        }
                        table.insert(compiledInventory, newItem)
                    end
                end
            end
            
            AddList(mainInv.Items, "Items")
            AddList(mainInv.Fish, "Fish")
            AddList(mainInv.Totems, "Totems")
            AddList(mainInv.Potions, "Potions")
            AddList(mainInv.Baits, "Baits")
            AddList(mainInv["Fishing Rods"], "Rods")
            
            return compiledInventory
        end
    end
    return {}
end

-- [[ LOCATIONS & EVENTS ]] --
local LOCATIONS = {
    ["Fisherman Island"] = CFrame.new(35, 17, 2851),
    ["Ancient Jungle"] = CFrame.new(1489, 7, -425),
    ["Sacred Temple"] = CFrame.new(1478, -22, -611),
    ["Ancient Ruins"] = CFrame.new(6097, -586, 4665),
    ["Clasic Island"] = CFrame.new(1232, 10, 2843),
    ["Iron Cavern"] = CFrame.new(-8899, -582, 157), 
    ["Iron Cafe"] = CFrame.new(-8642, -548, 161),
    ["Treasure Room"] = CFrame.new(-3600, -267, -1558),
    ["Sisyphus Statue"] = CFrame.new(-3693, -136, -1044),
    ["Crater Island"] = CFrame.new(975, 30, 4950),
    ["Kohana"] = CFrame.new(-635, 16, 595),
    ["Volcano Kohana"] = CFrame.new(-632, 55, 198),
    ["Second Enchant Room"] = CFrame.new(1480, 128, -590),
    ["Enchant Room"] = CFrame.new(3231, -1303, 1402),
    ["Coral Refs"] = CFrame.new(-2855, 47, 1997),
    ["Tropical Grove"] = CFrame.new(-2048, 6, 3657),
}

local EVENT_DATABASE = {
    ["Ghost Shark Hunt"] = {
        TargetNames = {"Ghost Shark", "GhostShark"},
        Coords = { Vector3.new(489.558, -1.35, 25.406), Vector3.new(-1358.2, -1.35, 4100.55), Vector3.new(627.859, -1.35, 3798.08) }
    },
    ["Megalodon Hunt"] = {
        TargetNames = {"Megalodon"},
        Coords = { Vector3.new(-1076.3, -1.4, 1676.19), Vector3.new(-1191.8, -1.4, 3597.30), Vector3.new(412.7, -1.4, 4134.39) }
    },
    ["Shark Hunt"] = {
        TargetNames = {"Great White Shark", "Shark"}, 
        Coords = { Vector3.new(1.65, -1.35, 2095.72), Vector3.new(1369.94, -1.35, 930.125), Vector3.new(-1585.5, -1.35, 1242.87), Vector3.new(-1896.8, -1.35, 2634.37) }
    },
    ["Worm Hunt"] = {
        TargetNames = {"Worm"},
        Coords = { Vector3.new(2190.85, -1.4, 97.57), Vector3.new(-2450.6, -1.4, 139.73), Vector3.new(-267.47, -1.4, 5188.53) }
    },
    ["Admin - Ghost Worm"] = {
        TargetNames = {"Ghost Worm"},
        Coords = { Vector3.new(-327, -1.4, 2422) }
    },
    ["Treasure Hunt"] = {
        TargetNames = {"Shipwreck", "Treasure", "Chest"},
        Coords = {} 
    }
}

local FloatBody = nil
local function ToggleFloat(bool)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    if bool then
        if not hrp:FindFirstChild("CatrazFloat") then
            FloatBody = Instance.new("BodyVelocity")
            FloatBody.Name = "CatrazFloat"
            FloatBody.Parent = hrp
            FloatBody.MaxForce = Vector3.new(0, math.huge, 0)
            FloatBody.Velocity = Vector3.new(0, 0, 0)
        end
        hum.PlatformStand = true
    else
        if hrp:FindFirstChild("CatrazFloat") then
            hrp.CatrazFloat:Destroy()
        end
        if hum then hum.PlatformStand = false end
        FloatBody = nil
    end
end

local function SmartTeleportToEvent(eventName)
    local data = EVENT_DATABASE[eventName]
    if not data then return end

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    -- TAHAP 1: SCANNING MODEL
    local foundModel = nil
    for _, targetName in ipairs(data.TargetNames) do
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == targetName and (obj:IsA("Model") or obj:IsA("BasePart")) then
                foundModel = obj
                break
            end
        end
        if foundModel then break end
    end

    -- JIKA KETEMU MODELNYA
    if foundModel then
        local targetCFrame = foundModel:GetPivot()
        char.HumanoidRootPart.CFrame = targetCFrame + Vector3.new(0, 35, 0) 
        WindUI:Notify({ Title = "Smart Detect", Content = "Found Active " .. foundModel.Name .. "!", Duration = 3 })
        ToggleFloat(true) 
        return true 
    end

    -- TAHAP 2: CEK KOORDINAT
    if #data.Coords > 0 then
        WindUI:Notify({ Title = "Searching...", Content = "Model not found via Scan. Checking Spawns...", Duration = 2 })
        task.spawn(function()
            for i, vec in ipairs(data.Coords) do
                char.HumanoidRootPart.CFrame = CFrame.new(vec) + Vector3.new(0, 35, 0)
                ToggleFloat(true)
                WindUI:Notify({ Title = "Checking Loc " .. i, Content = "Searching area...", Duration = 1 })
                task.wait(1.5) 
                
                local nearby = false
                for _, targetName in ipairs(data.TargetNames) do
                    if workspace:FindFirstChild(targetName) then
                        nearby = true
                        break
                    end
                end
                
                if nearby then
                    WindUI:Notify({ Title = "Found!", Content = "Event is here!", Duration = 3 })
                    return 
                end
            end
            WindUI:Notify({ Title = "Not Found", Content = "Event might not be spawned yet.", Duration = 3 })
        end)
    else
        WindUI:Notify({ Title = "Failed", Content = "No active model & no coordinates found.", Duration = 2 })
    end
end

-- [[ FISHING LOGIC ]] --
local fishingActive = false
local isFishing = false

local function CastRod()
    pcall(function()
        Events.equip:FireServer(1)
        task.wait(0.05)
        Events.charge:InvokeServer(1755848498.4834)
        task.wait(0.02)
        Events.minigame:InvokeServer(1.2854545116425, 1)
    end)
end

-- Mode Instant
local function InstantLoop()
    while fishingActive and not Config.BlatantMode and Config.FishingMode == "Instant" do
        if not isFishing then
            isFishing = true
            CastRod()
            task.wait(Config.FishDelay)
            pcall(function() Events.fishing:FireServer() end)
            task.wait(Config.CatchDelay)
            isFishing = false
        else
            task.wait(0.1)
        end
    end
end

-- Mode Legit
local function LegitLoop()
    while fishingActive and not Config.BlatantMode and Config.FishingMode == "Legit" do
        if not isFishing then
            isFishing = true
            CastRod()
            task.wait(Config.FishDelay) 
            
            local tapDuration = 0.1
            local startTime = tick()
            while tick() - startTime < tapDuration do
                Services.VirtualUser:ClickButton1(Vector2.new(999, 999))
                task.wait(0.08) 
            end
            
            pcall(function() Events.fishing:FireServer() end)
            task.wait(Config.CatchDelay)
            isFishing = false
        else
            task.wait(0.1)
        end
    end
end

-- Blatant Loop
local function BlatantLoop()
    while fishingActive and Config.BlatantMode do
        if not isFishing then
            isFishing = true
            pcall(function()
                Events.equip:FireServer(1)
                task.wait(0.01)
                task.spawn(function()
                    Events.charge:InvokeServer(1)
                    Events.minigame:InvokeServer(1.2854545116425, 1)
                end)
                task.wait(0.05)
                task.spawn(function()
                    Events.charge:InvokeServer(1)
                    Events.minigame:InvokeServer(1.2854545116425, 1)
                end)
            end)
            
            task.wait(Config.FishDelay)
            
            for i = 1, 5 do
                pcall(function() Events.fishing:FireServer() end)
                task.wait(0.01)
            end
            
            task.wait(Config.CatchDelay * 0.5)
            isFishing = false
        else
            task.wait(0.01)
        end
    end
end

local function ToggleFishing(bool)
    fishingActive = bool
    if bool then
        task.spawn(function()
            while fishingActive do
                if Config.BlatantMode then
                    BlatantLoop() 
                elseif Config.FishingMode == "Legit" then
                    LegitLoop()
                else
                    InstantLoop()
                end
                task.wait(0.1)
            end
        end)
        
        task.spawn(function()
            while fishingActive do
                if Config.AutoCatch and not isFishing and Config.FishingMode ~= "Legit" then
                    pcall(function() Events.fishing:FireServer() end)
                end
                task.wait(Config.CatchDelay)
            end
        end)
    else
        pcall(function() Events.unequip:FireServer() end)
    end
end

-- [[ AUTO SELL WORKER ]] --
task.spawn(function()
    while true do
        if Config.AutoSell then
            if Config.AutoSellMode == "Time" then
                pcall(function() Events.sell:InvokeServer() end)
                task.wait(Config.SellDelay)

            elseif Config.AutoSellMode == "Capacity" then
                local inventory = GetReplionInventory() 
                local currentCount = 0
                if inventory then currentCount = #inventory end

                if currentCount >= Config.SellThreshold then
                    WindUI:Notify({ Title = "Auto Sell", Content = "Limit Reached ("..currentCount.."), Selling...", Duration = 2 })
                    pcall(function() Events.sell:InvokeServer() end)
                    task.wait(3) 
                else
                    task.wait(1)
                end
            else
                task.wait(1)
            end
        else
            task.wait(1)
        end
    end
end)

-- [[ TRADE LOGIC (FULL) ]] --
local TradeCache = { GroupedItems = {}, DisplayNames = {} }
local TradeConfig = { TargetPlayer = nil, SelectedItemName = nil, TradeAmount = 1, TradeDelay = 1.5 }

local function RefreshTradeInventory()
    if not DatabaseIndexed then IndexItemDatabase() task.wait(0.1) end
    local inventory = GetReplionInventory() 
    TradeCache.GroupedItems = {}
    TradeCache.DisplayNames = {}
    local ItemCounts = {} 
    
    if not inventory then return {} end
    
    for _, item in pairs(inventory) do
        local validFolders = { ["Items"] = true, ["Fish"] = true }
        
        if item._SourceFolder and validFolders[item._SourceFolder] then
            if type(item) == "table" and item.Id and item.UUID then
                local searchKey = tostring(item.Id) 
                local baseName = "Unknown [" .. searchKey .. "]"
                if ItemInfoCache[searchKey] then baseName = ItemInfoCache[searchKey].Name end

                if item.Metadata and item.Metadata.VariantId then
                    baseName = "[" .. tostring(item.Metadata.VariantId) .. "] " .. baseName
                elseif item.Variant then
                    baseName = "[" .. item.Variant .. "] " .. baseName
                end
                
                local isLocked = item.Favorited or false
                if isLocked then baseName = baseName .. " 🔒" end

                local qty = item.Quantity or 1
                if not TradeCache.GroupedItems[baseName] then
                    TradeCache.GroupedItems[baseName] = {}
                    ItemCounts[baseName] = 0
                end

                table.insert(TradeCache.GroupedItems[baseName], {
                    UUID = item.UUID, Id = item.Id, IsLocked = isLocked, Quantity = qty
                })
                ItemCounts[baseName] = ItemCounts[baseName] + qty
            end
        end
    end

    for name, list in pairs(TradeCache.GroupedItems) do
        local totalAmount = ItemCounts[name] or 0
        local finalLabel = name .. " (x" .. totalAmount .. ")"
        table.insert(TradeCache.DisplayNames, finalLabel)
    end
    table.sort(TradeCache.DisplayNames)
    return TradeCache.DisplayNames
end

local function ExecuteTrade()
    if not TradeConfig.TargetPlayer then return end
    if not TradeConfig.SelectedItemName then return end

    local realName = string.match(TradeConfig.SelectedItemName, "^(.*)%s%(x%d+%)$") or TradeConfig.SelectedItemName
    local itemList = TradeCache.GroupedItems[realName]
    if not itemList then return end
    
    local targetPlr = game:GetService("Players"):FindFirstChild(TradeConfig.TargetPlayer)
    if not targetPlr then return end
    
    local amount = math.min(TradeConfig.TradeAmount, #itemList)
    WindUI:Notify({Title="Trading", Content="Sending " .. amount .. " items...", Duration=2})
    
    task.spawn(function()
        for i = 1, amount do
            local data = itemList[i]
            if not data then break end
            
            if data.IsLocked then
                print("🔒 Item locked, skip: " .. realName)
            else
                pcall(function() Events.equipInventory:FireServer(data.UUID, "Fish") end)
                task.wait(0.3)
                pcall(function() Events.equip:FireServer(5) end)
                task.wait(0.3)
                
                pcall(function() Events.initiateTrade:InvokeServer(targetPlr.UserId, data.UUID) end)
                task.wait(TradeConfig.TradeDelay)
            end
        end
        pcall(function() Events.unequip:FireServer(5) end)
    end)
end

-- [[ TOTEM LOGIC (FULL BUILDER) ]] --
local TotemCache = { Names = {}, Data = {} }
local TotemConfig = { SelectedTotem = nil, Radius = 50 }

local function RefreshTotemList()
    TotemCache.Names = {}
    TotemCache.Data = {}
    local TempGroups = {} 

    if not DatabaseIndexed then IndexItemDatabase() task.wait(0.1) end
    local inventory = GetReplionInventory() 
    if not inventory then return {} end
    
    for _, item in pairs(inventory) do
        if item._SourceFolder == "Totems" and item.Id and item.UUID then
            local idStr = tostring(item.Id)
            local baseName = "Totem [" .. idStr .. "]" 
            if ItemInfoCache[idStr] and ItemInfoCache[idStr].Name then baseName = ItemInfoCache[idStr].Name end
            
            local groupName = "[" .. item._SourceFolder .. "] " .. baseName
            
            if not TempGroups[groupName] then TempGroups[groupName] = { Id = item.Id, UUIDs = {} } end
            table.insert(TempGroups[groupName].UUIDs, item.UUID)
        end
    end

    for name, data in pairs(TempGroups) do
        local totalQty = #data.UUIDs
        local label = name .. " (x" .. totalQty .. ")"
        table.insert(TotemCache.Names, label)
        TotemCache.Data[label] = { Id = data.Id, UUIDs = data.UUIDs }
    end
    table.sort(TotemCache.Names)
    return TotemCache.Names
end

local function ExecuteTotemStrategy()
    local selectedName = TotemConfig.SelectedTotem
    if not selectedName then return end
    local totemData = TotemCache.Data[selectedName]
    if not totemData or not totemData.UUIDs then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    
    hrp.Anchored = false
    hrp.Velocity = Vector3.new(0,0,0)
    
    local originCF = hrp.CFrame
    local r = TotemConfig.Radius or 50.1
    local offsets = {
        {Dir="Front", Vector=Vector3.new(0, 0, -r)},    
        {Dir="Back",  Vector=Vector3.new(0, 0, r)},    
        {Dir="Right", Vector=Vector3.new(r, 0, 0)},     
        {Dir="Left",  Vector=Vector3.new(-r, 0, 0)}     
    }
    
    WindUI:Notify({Title="Strategy", Content="Placing 4-Way...", Duration=3})
    local createdParts = {} 
    
    local function CreatePlatform(position)
        local p = Instance.new("Part")
        p.Name = "TotemPlatform"
        p.Size = Vector3.new(6, 1, 6) 
        p.Position = position - Vector3.new(0, 3.5, 0) 
        p.Anchored = true
        p.CanCollide = true 
        p.Transparency = 0.5 
        p.Color = Color3.fromRGB(0, 255, 0)
        p.Parent = workspace
        table.insert(createdParts, p)
        return p
    end

    for i, data in ipairs(offsets) do
        local currentUUID = totemData.UUIDs[i]
        if not currentUUID then break end
        
        pcall(function() Events.equipInventory:FireServer(currentUUID, "Totems") end)
        task.wait(0.1)
        pcall(function() Events.equip:FireServer(5) end)
        task.wait(0.4) 
        
        local targetPos = originCF.Position + data.Vector
        local plat = CreatePlatform(targetPos)
        
        hrp.CFrame = CFrame.new(targetPos)
        hrp.Velocity = Vector3.new(0,0,0)
        task.wait(0.2) 
        hrp.Anchored = true
        task.wait(0.5)
        
        pcall(function() Events.placeTotem:FireServer(currentUUID) end)
        
        task.wait(4)
        hrp.Anchored = false
        if plat then plat:Destroy() end
        task.wait(0.1)
    end
    
    for _, p in pairs(createdParts) do if p and p.Parent then p:Destroy() end end
    hrp.Anchored = false
    hrp.CFrame = originCF
    pcall(function() Events.unequip:FireServer(5) end)
    RefreshTotemList()
end

-- [[ AUTO FAVORITE LOGIC ]] --
task.spawn(function()
    while true do
        task.wait(Config.FavInterval)
        if Config.AutoFavorite or Config.AutoUnfavorite then
            local inventory = GetReplionInventory()
            if inventory then
                for _, itemData in pairs(inventory) do
                    if type(itemData) == "table" and itemData.Id and itemData.UUID then
                        local idStr = tostring(itemData.Id)
                        local info = ItemInfoCache[idStr] or {Name="Unknown", RarityName="Common", Type="Fish"}
                        local currentVariant = itemData.Variant or "None" 
                        local isFav = itemData.Favorited or false
                        
                        if Config.AutoFavorite and not isFav then
                            local shouldFav = false
                            if Config.FavRarities[info.RarityName] then shouldFav = true end
                            if Config.FavNames[info.Name] then shouldFav = true end
                            if currentVariant ~= "None" and Config.FavVariants[currentVariant] then shouldFav = true end
                            
                            if shouldFav then
                                pcall(function() Events.favorite:FireServer(itemData.UUID, info.Type) end)
                                task.wait(0.1)
                            end
                        end

                        if Config.AutoUnfavorite and isFav then
                            local shouldUnfav = false
                            if Config.UnfavRarities[info.RarityName] then shouldUnfav = true end
                            if Config.UnfavNames[info.Name] then shouldUnfav = true end
                            if currentVariant ~= "None" and Config.UnfavVariants[currentVariant] then shouldUnfav = true end
                            
                            if shouldUnfav then
                                pcall(function() Events.favorite:FireServer(itemData.UUID, info.Type) end)
                                task.wait(0.1)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-------- [[ UI CONSTRUCTION & TABS ]] --------

-- 1. HOME
local HomeTab = Window:Tab({ Title = "Home", Icon = "tv-minimal" })
local InfoSec = HomeTab:Section({ Title = "Community & Support", Opened = true, Box = true })
InfoSec:Section({ Title = "Welcome to Catraz Hub!", TextSize = 24 })
InfoSec:Section({ Title = "Integrated Script for Fish It. Join our Discord for updates.", TextSize = 18, TextTransparency = .35 })
InfoSec:Button({ Title = "Copy Discord Link", Callback = function() setclipboard("https://discord.gg/XVcWDFCYSu") end })
local ChangeSec = HomeTab:Section({ Title = "Changelog v2.0 (Full Logic)", Opened = true, Box = true })
ChangeSec:Section({ Title = "What's New?", TextSize = 24 })
ChangeSec:Section({ Title = "[+] Full Logic Restoration: Trade, Totem, Inventory tagging restored. \n[+] Theme: Native Red (The Forge style). \n[+] Global Settings: Added FPS Boost, Server Hop, etc. \n[+] Language: Translated to English.", TextSize = 18, TextTransparency = .35 })

-- 2. FARMING
local MainTab = Window:Tab({ Title = "Farming", Icon = "fish-symbol" })
local FarmSec = MainTab:Section({ Title = "Auto Farm" })

local AutoFishToggleUI = FarmSec:Toggle({
    Title = "Auto Fish",
    Value = Config.AutoFish,
    Callback = function(v) Config.AutoFish = v; ToggleFishing(v) end
})
FarmSec:Dropdown({ Title = "Fishing Mode", Values = {"Instant", "Legit"}, Callback = function(v) Config.FishingMode = v end })
FarmSec:Toggle({ Title = "Blatant Mode", Desc = "3x Faster (Risk)", Value = Config.BlatantMode, Callback = function(v) Config.BlatantMode = v end })
FarmSec:Input({ Title = "Fish Delay", Default = tostring(Config.FishDelay), Numeric = true, Callback = function(v) Config.FishDelay = tonumber(v) or 0.9 end })
FarmSec:Input({ Title = "Catch Delay", Default = tostring(Config.CatchDelay), Numeric = true, Callback = function(v) Config.CatchDelay = tonumber(v) or 0.2 end })

local EventSec = MainTab:Section({ Title = "Event Farming" })
local EventKeys = {}; for k,_ in pairs(EVENT_DATABASE) do table.insert(EventKeys, k) end; table.sort(EventKeys)
local SelectedEvent = nil
local ManualFloatToggleUI = nil

EventSec:Dropdown({ Title = "Select Event", Values = EventKeys, Callback = function(v) SelectedEvent = v end })
EventSec:Button({
    Title = "Smart Teleport & Farm",
    Desc = "Auto find boss -> Float -> Auto Fish",
    Callback = function()
        if not SelectedEvent then return end
        SmartTeleportToEvent(SelectedEvent)
        ToggleFloat(true); if ManualFloatToggleUI then ManualFloatToggleUI:SetValue(true) end
        if not Config.AutoFish then Config.AutoFish = true; ToggleFishing(true); if AutoFishToggleUI then AutoFishToggleUI:SetValue(true) end end
    end
})
ManualFloatToggleUI = EventSec:Toggle({ Title = "Manual Float", Value = false, Callback = function(v) ToggleFloat(v) end })
EventSec:Button({
    Title = "Force Scan Workspace",
    Desc = "Find ANY boss model",
    Callback = function()
        local keywords = {"Boss", "Shark", "Megalodon", "Meteor", "Chest", "Shipwreck"}
        local found = false
        for _, word in ipairs(keywords) do
            for _, obj in pairs(workspace:GetDescendants()) do
                if string.find(obj.Name, word) and (obj:IsA("Model") or obj:IsA("BasePart")) then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = obj:GetPivot() * CFrame.new(0, 35, 0)
                    ToggleFloat(true); found = true; break
                end
            end
            if found then break end
        end
        if found then WindUI:Notify({Title="Found", Content="Teleported!", Duration=2}) else WindUI:Notify({Title="Failed", Content="No event found.", Duration=2}) end
    end
})

local TotemSec = MainTab:Section({ Title = "Totem Strategy" })
local TotemDrop = TotemSec:Dropdown({ Title = "Select Totem", Values = {}, Callback = function(v) TotemConfig.SelectedTotem = v end })
TotemSec:Button({ Title = "Refresh Totems", Callback = function() TotemDrop:Refresh(RefreshTotemList()) end })
TotemSec:Slider({ Title = "Radius", Value = {Min=30, Max=100, Default=50}, Callback = function(v) TotemConfig.Radius = v end })
TotemSec:Button({ Title = "Start Placement (4-Way)", Desc = "Build platform & place", Callback = ExecuteTotemStrategy })

-- 3. SHOP
local ShopTab = Window:Tab({ Title = "Shop", Icon = "shopping-cart" })
local RodSec = ShopTab:Section({ Title = "Equipment Shop" })
local SelRod, SelBait = nil, nil
RodSec:Dropdown({ Title = "Select Rod", Values = ShopData.RodNames, Callback = function(v) SelRod = v end })
RodSec:Button({ Title = "Buy Rod", Callback = function() if SelRod and ShopData.Rods[SelRod] then Events.buyRod:InvokeServer(ShopData.Rods[SelRod]) end end })
RodSec:Dropdown({ Title = "Select Bait", Values = ShopData.BaitNames, Callback = function(v) SelBait = v end })
RodSec:Button({ Title = "Buy Bait", Callback = function() if SelBait and ShopData.Baits[SelBait] then Events.buyBait:InvokeServer(ShopData.Baits[SelBait]) end end })

local MerchSec = ShopTab:Section({ Title = "Merchant & Weather" })
local SelMerch, SelWeather = nil, {}
local MerchDrop = MerchSec:Dropdown({ Title = "Merchant Stock", Values = RefreshMerchantItems(), Callback = function(v) SelMerch = v end })
MerchSec:Button({ Title = "Refresh Stock", Callback = function() MerchDrop:Refresh(RefreshMerchantItems()) end })
MerchSec:Button({ Title = "Buy Item", Callback = function() if SelMerch and MerchantCache.Items[SelMerch] then Events.buyMerchant:InvokeServer(MerchantCache.Items[SelMerch]) end end })
MerchSec:Button({ Title = "TP to Merchant", Callback = function() 
    local m = workspace:FindFirstChild("TravelingMerchant") or workspace:FindFirstChild("Merchant")
    if m then LocalPlayer.Character.HumanoidRootPart.CFrame = m.HumanoidRootPart.CFrame end 
end })

MerchSec:Dropdown({ Title = "Select Weather", Multi = true, Values = {"Cloudy","Radiant","Snow","Storm","Wind","Shark Hunt"}, Callback = function(v) SelWeather = v end })
MerchSec:Toggle({ Title = "Auto Buy Weather", Callback = function(v) 
    task.spawn(function() while v do for _,w in pairs(SelWeather) do if not v then break end pcall(function() Events.buyWeather:InvokeServer(w) end) task.wait(5) end task.wait(1) end end)
end })

local SellSec = ShopTab:Section({ Title = "Auto Sell" })
SellSec:Toggle({ Title = "Enable Auto Sell", Value = Config.AutoSell, Callback = function(v) Config.AutoSell = v end })
SellSec:Dropdown({ Title = "Mode", Values = {"Time", "Capacity"}, Value = "Time", Callback = function(v) Config.AutoSellMode = v end })
SellSec:Input({ Title = "Time Delay (s)", Default = "30", Numeric = true, Callback = function(v) Config.SellDelay = tonumber(v) or 30 end })
SellSec:Slider({ Title = "Capacity Threshold", Value = {Min=100, Max=5000, Default=2000}, Callback = function(v) Config.SellThreshold = v end })

-- 4. MULTIPLAYER
local MultiTab = Window:Tab({ Title = "Multiplayer", Icon = "users" })
local TradeSec = MultiTab:Section({ Title = "Trade System" })
local TradePlrDrop = TradeSec:Dropdown({ Title = "Select Player", Values = {}, Callback = function(v) TradeConfig.TargetPlayer = v end })
TradeSec:Button({ Title = "Refresh Players", Callback = function() 
    local n = {}; for _,p in pairs(Services.Players:GetPlayers()) do if p~=LocalPlayer then table.insert(n,p.Name) end end table.sort(n)
    TradePlrDrop:Refresh(n) 
end })
local TradeItemDrop = TradeSec:Dropdown({ Title = "Select Item", Values = {}, SearchBarEnabled = true, Callback = function(v) TradeConfig.SelectedItemName = v end })
TradeSec:Button({ Title = "Scan Inventory", Callback = function() TradeItemDrop:Refresh(RefreshTradeInventory()) end })
TradeSec:Slider({ Title = "Quantity", Value = {Min=1, Max=50, Default=1}, Callback = function(v) TradeConfig.TradeAmount = v end })
TradeSec:Button({ Title = "Send Trade", Callback = ExecuteTrade })

local TpSec = MultiTab:Section({ Title = "Teleport" })
local LocKeys = {}; for k,_ in pairs(LOCATIONS) do table.insert(LocKeys, k) end; table.sort(LocKeys)
TpSec:Dropdown({ Title = "Islands", Values = LocKeys, Callback = function(v) if LOCATIONS[v] then LocalPlayer.Character.HumanoidRootPart.CFrame = LOCATIONS[v] end end })
local PlayerTpDrop = TpSec:Dropdown({ Title = "Teleport to Player", Values = {}, Callback = function(v) 
    local t = Services.Players:FindFirstChild(v)
    if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.CFrame = t.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3) end
end })
TpSec:Button({ Title = "Refresh Players", Callback = function() 
    local n = {}; for _,p in pairs(Services.Players:GetPlayers()) do if p~=LocalPlayer then table.insert(n,p.Name) end end table.sort(n)
    PlayerTpDrop:Refresh(n)
end })

-- 5. MANAGER
local ManagerTab = Window:Tab({ Title = "Manager", Icon = "briefcase" })
local FavSec = ManagerTab:Section({ Title = "Auto Favorite (Whitelist)" })
FavSec:Toggle({ Title = "Enable", Value = Config.AutoFavorite, Callback = function(v) Config.AutoFavorite = v end })
FavSec:Dropdown({ Title = "Rarities", Multi = true, Values = RarityListString, Callback = function(v) Config.FavRarities={}; for _,x in pairs(v) do Config.FavRarities[x]=true end end })
FavSec:Dropdown({ Title = "Variants", Multi = true, Values = GlobalVariants, Callback = function(v) Config.FavVariants={}; for _,x in pairs(v) do Config.FavVariants[x]=true end end })
local FavNameDrop = FavSec:Dropdown({ Title = "Names", Multi = true, Values = AllFishNames, SearchBarEnabled = true, Callback = function(v) Config.FavNames={}; for _,x in pairs(v) do Config.FavNames[x]=true end end })
FavSec:Button({ Title = "Refresh Names", Callback = function() IndexItemDatabase(); FavNameDrop:Refresh(AllFishNames) end })

local UnfavSec = ManagerTab:Section({ Title = "Auto Unfavorite (Unlock)" })
UnfavSec:Toggle({ Title = "Enable", Value = Config.AutoUnfavorite, Callback = function(v) Config.AutoUnfavorite = v end })
UnfavSec:Dropdown({ Title = "Rarities", Multi = true, Values = RarityListString, Callback = function(v) Config.UnfavRarities={}; for _,x in pairs(v) do Config.UnfavRarities[x]=true end end })
UnfavSec:Dropdown({ Title = "Variants", Multi = true, Values = GlobalVariants, Callback = function(v) Config.UnfavVariants={}; for _,x in pairs(v) do Config.UnfavVariants[x]=true end end })

-- 6. SETTINGS (FROM THE FORGE)
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })
local VisualSection = SettingsTab:Section({ Title = "Visuals & Performance" })
VisualSection:Toggle({
    Title = "GPU Saver", Desc = "Black screen to save resources", Value = Config.GPUSaver,
    Callback = function(v) 
        Config.GPUSaver = v; Services.RunService:Set3dRenderingEnabled(not v)
        if v then setfpscap(10) else setfpscap(60) end
    end
})
VisualSection:Button({
    Title = "FPS Boost (Potato Mode)", Desc = "Remove textures & effects",
    Callback = function()
        local Terrain = workspace:FindFirstChildOfClass("Terrain")
        if Terrain then Terrain.WaterWaveSize = 0; Terrain.WaterWaveSpeed = 0; Terrain.WaterReflectance = 0; Terrain.WaterTransparency = 0 end
        Services.Lighting.GlobalShadows = false; Services.Lighting.FogEnd = 9e9; settings().Rendering.QualityLevel = 1
        for _, v in pairs(Services.Lighting:GetDescendants()) do if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Cloud") then v:Destroy() end end
        for _, v in pairs(workspace:GetDescendants()) do if v:IsA("BasePart") and not v:IsA("Terrain") then v.Material = Enum.Material.SmoothPlastic; v.CastShadow = false end end
    end
})
VisualSection:Toggle({
    Title = "Fullbright", Desc = "Max brightness", Value = false,
    Callback = function(v) _G_Settings.Fullbright = v; if v then task.spawn(function() while _G_Settings.Fullbright do Services.Lighting.Brightness=2; Services.Lighting.ClockTime=14; task.wait(1) end end) end end
})

local CharSection = SettingsTab:Section({ Title = "Character" })
CharSection:Slider({ Title = "Walk Speed", Value = {Min=16, Max=200, Default=16}, Callback = function(v) _G_Settings.WalkSpeed = v; if LocalPlayer.Character then LocalPlayer.Character.Humanoid.WalkSpeed = v end end })
CharSection:Slider({ Title = "Jump Power", Value = {Min=50, Max=300, Default=50}, Callback = function(v) _G_Settings.JumpPower = v; if LocalPlayer.Character then LocalPlayer.Character.Humanoid.UseJumpPower = true; LocalPlayer.Character.Humanoid.JumpPower = v end end })

local SystemSection = SettingsTab:Section({ Title = "System" })
SystemSection:Button({ Title = "Rejoin Server", Callback = function() Services.TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end })
SystemSection:Button({
    Title = "Server Hop", Callback = function()
        local PlaceId = game.PlaceId; local Api = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
        local function ListServers(cursor) local Raw = game:HttpGet(Api .. ((cursor and "&cursor="..cursor) or "")); return Services.HttpService:JSONDecode(Raw) end
        local Server, Next; repeat local Servers = ListServers(Next); Server = Servers.data[1]; Next = Servers.nextPageCursor until Server
        Services.TeleportService:TeleportToPlaceInstance(PlaceId, Server.id, LocalPlayer)
    end
})
SystemSection:Button({
    Title = "Unload UI", Desc = "Remove Menu & Dashboard",
    Callback = function()
        Config.AutoFish = false; fishingActive = false
        if Services.CoreGui:FindFirstChild("CatrazHubSystem") then Services.CoreGui["CatrazHubSystem"]:Destroy() end
        Window:Destroy()
    end
})

-- [[ GLOBAL LOOPS ]] --
Services.RunService.Stepped:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if LocalPlayer.Character.Humanoid.WalkSpeed ~= _G_Settings.WalkSpeed and _G_Settings.WalkSpeed > 16 then LocalPlayer.Character.Humanoid.WalkSpeed = _G_Settings.WalkSpeed end
        if LocalPlayer.Character.Humanoid.JumpPower ~= _G_Settings.JumpPower and _G_Settings.JumpPower > 50 then LocalPlayer.Character.Humanoid.UseJumpPower = true; LocalPlayer.Character.Humanoid.JumpPower = _G_Settings.JumpPower end
    end
end)

LocalPlayer.Idled:Connect(function() Services.VirtualUser:CaptureController(); Services.VirtualUser:ClickButton2(Vector2.new()) end)
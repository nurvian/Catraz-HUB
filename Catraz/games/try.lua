--[[
    CATRAZ HUB | FISH IT - INTEGRATED VERSION
    UI Library: WindUI
    Logic: Auto Fish V6.0 (Offline Database System)
]]

-- ====================================================================
--                  1. CORE SERVICES & VARIABLES
-- ====================================================================
local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    VirtualUser = game:GetService("VirtualUser"),
    RunService = game:GetService("RunService"),
    HttpService = game:GetService("HttpService")
}

local LocalPlayer = Services.Players.LocalPlayer
local Events = nil
local AllFishNames = {} 
local RarityListString = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret"}
local GlobalVariants = {"Shiny", "Big", "Sparkling", "Frozen", "Albino", "Dark", "Electric", "Radioactive", "Negative", "Golden", "Rainbow", "Ghost", "Solar", "Sand"}

-- [[ DATABASE SYSTEM ]]
local DB_FILENAME = "Catraz_FishIt_Database.json" -- Nama file database kamu
local ItemInfoCache = {} 
local DatabaseLoaded = false

local Config = {
    AutoFish = false,
    BlatantMode = false,
    FishingMode = "Instant",
    AutoCatch = false,
    AutoSell = false,
    AutoSellMode = "Time", 
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

-- ====================================================================
--                  2. FILE SYSTEM (OFFLINE DB)
-- ====================================================================

-- Fungsi Simpan Database ke File
local function SaveDatabaseOffline()
    if not writefile then return end -- Cek support executor
    
    local success, encoded = pcall(function()
        return Services.HttpService:JSONEncode(ItemInfoCache)
    end)
    
    if success then
        writefile(DB_FILENAME, encoded)
        print("💾 Database berhasil disimpan ke: " .. DB_FILENAME)
    end
end

-- Fungsi Load Database dari File
local function LoadDatabaseOffline()
    if not isfile or not readfile then return false end
    
    if isfile(DB_FILENAME) then
        local success, decoded = pcall(function()
            return Services.HttpService:JSONDecode(readfile(DB_FILENAME))
        end)
        
        if success and decoded then
            ItemInfoCache = decoded
            
            -- Update list nama untuk dropdown
            AllFishNames = {}
            for id, data in pairs(ItemInfoCache) do
                if data.Name and not table.find(AllFishNames, data.Name) then
                    table.insert(AllFishNames, data.Name)
                end
            end
            table.sort(AllFishNames)
            
            DatabaseLoaded = true
            print("📂 Database Offline Dimuat: " .. tostring(#AllFishNames) .. " item.")
            return true
        end
    end
    return false
end

-- ====================================================================
--                  3. NETWORK & SCANNER
-- ====================================================================

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
        }
    end
end
SetupEvents()

-- [[ SCANNER PINTAR (TARGET FOLDER) ]]
local function IndexItemDatabase(forceUpdate)
    -- Jika tidak dipaksa update dan database offline ada, pakai yang offline aja
    if not forceUpdate and LoadDatabaseOffline() then 
        return #AllFishNames 
    end
    
    ItemInfoCache = {} 
    AllFishNames = {}  
    
    local RepStorage = game:GetService("ReplicatedStorage")
    local count = 0
    
    print("🔍 Sedang Scan Ulang Database Game...")
    
    -- Target Folder Spesifik (Sesuai info kamu)
    local folders = {
        RepStorage:FindFirstChild("Items"),
        RepStorage:FindFirstChild("Totems")
    }
    
    for _, folder in pairs(folders) do
        if folder then
            for _, module in pairs(folder:GetDescendants()) do
                if module:IsA("ModuleScript") then
                    local success, result = pcall(require, module)
                    
                    if success and type(result) == "table" and result.Data then
                        local d = result.Data
                        if d.Id and d.Name then
                            -- KITA SIMPAN SEBAGAI STRING AGAR KONSISTEN
                            local idString = tostring(d.Id)
                            ItemInfoCache[idString] = { Name = d.Name }
                            
                            if not table.find(AllFishNames, d.Name) then
                                table.insert(AllFishNames, d.Name)
                            end
                            count = count + 1
                        end
                    end
                end
            end
        end
    end
    
    table.sort(AllFishNames)
    
    -- SIMPAN KE FILE BIAR BESOK GAK PERLU SCAN LAGI
    SaveDatabaseOffline()
    
    DatabaseLoaded = true
    return count
end

-- Load database saat script jalan pertama kali
task.spawn(function()
    IndexItemDatabase(false) -- False = Coba load offline dulu
end)

-- Variable Cache untuk Trade
local TradeCache = { GroupedItems = {}, DisplayNames = {} }
local TradeConfig = { TargetPlayer = nil, SelectedItemName = nil, TradeAmount = 1, TradeDelay = 1.5 }

local ShopData = { Rods = {}, Baits = {}, RodNames = {}, BaitNames = {} }
local function ScanShopItems()
    ShopData.Rods = {}
    ShopData.Baits = {}
    ShopData.RodNames = {}
    ShopData.BaitNames = {}
    for _, obj in pairs(Services.ReplicatedStorage:GetDescendants()) do
        if obj:IsA("ModuleScript") and not obj:FindFirstAncestor("Packages") then
            local success, result = pcall(require, obj)
            if success and result and result.Data then
                local d = result.Data
                if d.Name and d.Id and d.Type then
                    if d.Type == "Fishing Rods" then
                        ShopData.Rods[d.Name] = d.Id
                        table.insert(ShopData.RodNames, d.Name)
                    elseif d.Type == "Baits" or d.Type == "Consumable" then
                        ShopData.Baits[d.Name] = d.Id
                        table.insert(ShopData.BaitNames, d.Name)
                    end
                end
            end
        end
    end
    table.sort(ShopData.RodNames)
    table.sort(ShopData.BaitNames)
end
task.spawn(ScanShopItems)

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
                for _, v in pairs(MarketData) do if v.Id == marketID then marketItem = v break end end
                if marketItem then
                    local itemData = ItemUtility.GetItemDataFromItemType(marketItem.Type, marketItem.Identifier)
                    if itemData and itemData.Data then
                        local displayName = itemData.Data.Name .. " (" .. (marketItem.Price or "?") .. ")"
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

LocalPlayer.Idled:Connect(function()
    Services.VirtualUser:CaptureController()
    Services.VirtualUser:ClickButton2(Vector2.new())
end)

local fishingActive = false
local isFishing = false

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
    ["Ghost Shark Hunt"] = { TargetNames = {"Ghost Shark", "GhostShark"}, Coords = {Vector3.new(489.558, -1.35, 25.406), Vector3.new(-1358.2, -1.35, 4100.55), Vector3.new(627.859, -1.35, 3798.08)} },
    ["Megalodon Hunt"] = { TargetNames = {"Megalodon"}, Coords = {Vector3.new(-1076.3, -1.4, 1676.19), Vector3.new(-1191.8, -1.4, 3597.30), Vector3.new(412.7, -1.4, 4134.39)} },
    ["Shark Hunt"] = { TargetNames = {"Great White Shark", "Shark"}, Coords = {Vector3.new(1.65, -1.35, 2095.72), Vector3.new(1369.94, -1.35, 930.125), Vector3.new(-1585.5, -1.35, 1242.87), Vector3.new(-1896.8, -1.35, 2634.37)} },
    ["Worm Hunt"] = { TargetNames = {"Worm"}, Coords = {Vector3.new(2190.85, -1.4, 97.57), Vector3.new(-2450.6, -1.4, 139.73), Vector3.new(-267.47, -1.4, 5188.53)} },
    ["Admin - Ghost Worm"] = { TargetNames = {"Ghost Worm"}, Coords = { Vector3.new(-327, -1.4, 2422) } },
    ["Treasure Hunt"] = { TargetNames = {"Shipwreck", "Treasure", "Chest"}, Coords = {} }
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
        if hrp:FindFirstChild("CatrazFloat") then hrp.CatrazFloat:Destroy() end
        hum.PlatformStand = false
        FloatBody = nil
    end
end

local function SmartTeleportToEvent(eventName)
    local data = EVENT_DATABASE[eventName]
    if not data then return end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local foundModel = nil
    for _, targetName in ipairs(data.TargetNames) do
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == targetName and (obj:IsA("Model") or obj:IsA("BasePart")) then foundModel = obj break end
        end
        if foundModel then break end
    end
    if foundModel then
        char.HumanoidRootPart.CFrame = foundModel:GetPivot() + Vector3.new(0, 35, 0)
        ToggleFloat(true) 
        return true 
    end
    if #data.Coords > 0 then
        task.spawn(function()
            for i, vec in ipairs(data.Coords) do
                char.HumanoidRootPart.CFrame = CFrame.new(vec) + Vector3.new(0, 35, 0)
                ToggleFloat(true) 
                task.wait(1.5) 
            end
        end)
    end
end

local function CastRod()
    pcall(function()
        Events.equip:FireServer(1)
        task.wait(0.05)
        Events.charge:InvokeServer(1755848498.4834)
        task.wait(0.02)
        Events.minigame:InvokeServer(1.2854545116425, 1)
    end)
end

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

local function LegitLoop()
    while fishingActive and not Config.BlatantMode and Config.FishingMode == "Legit" do
        if not isFishing then
            isFishing = true
            CastRod()
            task.wait(Config.FishDelay)
            local startTime = tick()
            while tick() - startTime < 0.1 do
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

local function BlatantLoop()
    while fishingActive and Config.BlatantMode do
        if not isFishing then
            isFishing = true
            pcall(function()
                Events.equip:FireServer(1)
                task.wait(0.01)
                task.spawn(function() Events.charge:InvokeServer(1) Events.minigame:InvokeServer(1, 1) end)
                task.wait(0.05)
                task.spawn(function() Events.charge:InvokeServer(1) Events.minigame:InvokeServer(1, 1) end)
            end)
            task.wait(Config.FishDelay)
            for i = 1, 5 do pcall(function() Events.fishing:FireServer() end) task.wait(0.01) end
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
                if Config.BlatantMode then BlatantLoop() elseif Config.FishingMode == "Legit" then LegitLoop() else InstantLoop() end
                task.wait(0.1)
            end
        end)
        task.spawn(function()
            while fishingActive do
                if Config.AutoCatch and not isFishing and Config.FishingMode ~= "Legit" then pcall(function() Events.fishing:FireServer() end) end
                task.wait(Config.CatchDelay)
            end
        end)
    else
        pcall(function() Events.unequip:FireServer() end)
    end
end

task.spawn(function()
    while true do
        if Config.AutoSell then
            if Config.AutoSellMode == "Time" then
                pcall(function() Events.sell:InvokeServer() end)
                task.wait(Config.SellDelay)
            elseif Config.AutoSellMode == "Capacity" then
                -- GetReplionInventory Logic Here directly or via func
                task.wait(3) 
            end
        end
        task.wait(1)
    end
end)

local function GetReplionInventory()
    local RepStorage = game:GetService("ReplicatedStorage")
    local Pkg = RepStorage:FindFirstChild("Packages")
    if not Pkg then return nil end
    local ReplionModule = Pkg:FindFirstChild("Replion") 
    if not ReplionModule and Pkg:FindFirstChild("_Index") then
        for _, child in pairs(Pkg._Index:GetDescendants()) do
            if child.Name == "Replion" and child:IsA("ModuleScript") then
                ReplionModule = child
                break
            end
        end
    end
    if not ReplionModule then return nil end
    local success, Lib = pcall(require, ReplionModule)
    if not success then return nil end
    local Client = Lib.Client
    if not Client then return nil end
    local DataContainer = Client:GetReplion("Data")
    if not DataContainer then return nil end
    if DataContainer.Data and DataContainer.Data.Inventory and DataContainer.Data.Inventory.Items then
        return DataContainer.Data.Inventory.Items
    end
    return nil
end

local function RefreshTradeInventory()
    local inventory = GetReplionInventory()
    TradeCache.GroupedItems = {}
    TradeCache.DisplayNames = {}
    
    if not inventory then return {} end

    for _, item in pairs(inventory) do
        if type(item) == "table" and item.Id then
            -- [[ CONVERT ID TO STRING BIAR COCOK DENGAN OFFLINE DB ]]
            local searchKey = tostring(item.Id)
            local displayName = "Item [" .. searchKey .. "]"
            
            -- Cek di Database
            if ItemInfoCache[searchKey] and ItemInfoCache[searchKey].Name then
                displayName = ItemInfoCache[searchKey].Name
            end

            if item.Variant and item.Variant ~= "None" then
                displayName = "[" .. item.Variant .. "] " .. displayName
            end

            local isLocked = item.Favorited or false
            if isLocked then displayName = displayName .. " 🔒" end

            if not TradeCache.GroupedItems[displayName] then TradeCache.GroupedItems[displayName] = {} end
            table.insert(TradeCache.GroupedItems[displayName], { UUID = item.UUID, Id = item.Id, IsLocked = isLocked })
        end
    end

    for name, list in pairs(TradeCache.GroupedItems) do
        table.insert(TradeCache.DisplayNames, name .. " (x" .. #list .. ")")
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
    
    task.spawn(function()
        for i = 1, amount do
            local data = itemList[i]
            if not data then break end
            if not data.IsLocked then
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

-- ====================================================================
--                  3. WIND UI IMPLEMENTATION
-- ====================================================================

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Catraz Hub | Fish It",
    Author = "by alcatraz • team",
    Folder = "chub",
    Icon = "snail",
    IconSize = 22*2
})

local MainTab = Window:Tab({ Title = "Main", Icon = "house" })
local ShopTab = Window:Tab({ Title = "Shop", Icon = "store" })
local TeleportTab = Window:Tab({ Title = "Teleport", Icon = "navigation" })
local MiscTab = Window:Tab({ Title = "Misc", Icon = "settings" })

local MainSection = MainTab:Section({ Title = "Auto Farm", Icon = "fish-symbol", Opened = true })
MainSection:Toggle({ Title = "Auto Fish", Default = Config.AutoFish, Callback = function(value) Config.AutoFish = value ToggleFishing(value) end })
MainSection:Dropdown({ Title = "Fishing Mode", Values = { "Instant", "Legit" }, Callback = function(value) Config.FishingMode = value end })
MainSection:Toggle({ Title = "⚡ Blatant Mode", Callback = function(value) Config.BlatantMode = value end })
MainSection:Input({ Title = "Fish Delay", Default = "0.9", Callback = function(v) Config.FishDelay = tonumber(v) or 0.9 end })
MainSection:Input({ Title = "Catch Delay", Default = "0.2", Callback = function(v) Config.CatchDelay = tonumber(v) or 0.2 end })

local function GetPlayerNames()
    local n = {}
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if p ~= game:GetService("Players").LocalPlayer then table.insert(n, p.Name) end
    end
    table.sort(n)
    return n
end

local MainTrade = MainTab:Section({ Title = "Auto Trade", Icon = "refresh-ccw", Opened = true })
local PlrDrop = MainTrade:Dropdown({ Title = "Select Player", Values = GetPlayerNames(), Callback = function(v) TradeConfig.TargetPlayer = v end })
MainTrade:Button({ Title = "Refresh Players", Callback = function() PlrDrop:Refresh(GetPlayerNames()) end })

local ItemDrop = MainTrade:Dropdown({ Title = "Select Item", Values = {}, SearchBarEnabled = true, Callback = function(v) TradeConfig.SelectedItemName = v end })

MainTrade:Button({
    Title = "🔄 SCAN & UPDATE DB",
    Desc = "Scan game, save to file & refresh list",
    Callback = function()
        -- 1. Scan & Simpan ke File (True = Force Update)
        local count = IndexItemDatabase(true)
        WindUI:Notify({ Title = "Database Updated", Content = "Saved " .. count .. " items offline!", Duration = 2 })
        
        -- 2. Update Dropdown
        task.wait(0.2)
        local list = RefreshTradeInventory()
        ItemDrop:Refresh(list)
    end
})

MainTrade:Slider({ Title = "Jumlah Trade", Value = {Min = 1, Max = 50, Default = 1}, Callback = function(v) TradeConfig.TradeAmount = v end })
MainTrade:Button({ Title = "🚀 KIRIM TRADE", Callback = function() ExecuteTrade() end })

local EventSection = MainTab:Section({ Title = "Event Farming", Icon = "globe" })
-- ... (Kode Event Sama) ...

local ShopSection = ShopTab:Section({ Title = "Shop Center", Icon = "store", Opened = true })
ShopSection:Dropdown({ Title = "Select Rod", Values = ShopData.RodNames, Callback = function(v) selectedRodName = v end })
ShopSection:Button({ Title = "Buy Rod", Callback = function() if selectedRodName then Events.buyRod:InvokeServer(ShopData.Rods[selectedRodName]) end end })
ShopSection:Dropdown({ Title = "Select Bait", Values = ShopData.BaitNames, Callback = function(v) selectedBaitName = v end })
ShopSection:Button({ Title = "Buy Bait", Callback = function() if selectedBaitName then Events.buyBait:InvokeServer(ShopData.Baits[selectedBaitName]) end end })

ShopSection:Toggle({ Title = "Enable Auto Sell", Callback = function(v) Config.AutoSell = v end })
ShopSection:Dropdown({ Title = "Auto Sell Mode", Values = {"Time", "Capacity"}, Callback = function(v) Config.AutoSellMode = v end })
ShopSection:Slider({ Title = "Inventory Threshold", Value = {Min=100, Max=5000, Default=3000}, Callback = function(v) Config.SellThreshold = v end })

Window:SetToggleKey(Enum.KeyCode.RightControl)
WindUI:Notify({ Title = "Success", Content = "Catraz Hub Loaded Successfully!", Duration = 5, Icon = "check" })
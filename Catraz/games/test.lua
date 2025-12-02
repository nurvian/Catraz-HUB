--[[
    CATRAZ HUB | FISH IT - INTEGRATED VERSION
    UI Library: WindUI
    Logic: Auto Fish V4.0 (Blatant Mode)
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
local GlobalFishNames = {} 
local GlobalVariants = {"Shiny", "Big", "Sparkling", "Frozen", "Albino", "Dark", "Electric", "Radioactive", "Negative", "Golden", "Rainbow", "Ghost", "Solar", "Sand"}

local Config = {
    AutoFish = false,
    BlatantMode = false,
    FishingMode = "Instant",
    AutoCatch = false,
    AutoSell = false,
    GPUSaver = false,
    AutoFavorite = true,
    FishDelay = 0.9,
    CatchDelay = 0.2,
    SellDelay = 30,
    AutoFavorite = false,
    AutoUnfavorite = false, -- Fitur Baru: Auto Unlock sampah
    FavInterval = 3,
    WhitelistRarities = {}, -- Menyimpan Tier yang mau disimpan (Contoh: [6]=true)
    WhitelistNames = {},    -- Menyimpan Nama Ikan
    WhitelistVariants = {}  -- Menyimpan Variant
}

-- ====================================================================
--                  2. NETWORK & LOGIC FUNCTIONS
-- ====================================================================

-- Get Events Safely (FIXED)
local function SetupEvents()
    -- Ganti nama variable lokal jadi 'netPackage' biar sesuai sama pengecekan di bawah
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
            
            -- SHOP EVENTS (Penting!)
            buyBait = net:WaitForChild("RF/PurchaseBait"),
            buyRod = net:WaitForChild("RF/PurchaseFishingRod"),
            buyMerchant = net:WaitForChild("RF/PurchaseMarketItem"),
            -- NEW: WEATHER EVENT (Tambahkan ini)
            buyWeather = net:WaitForChild("RF/PurchaseWeatherEvent")
        }
        print("✅ Events Loaded Successfully!")
    else
        warn("❌ Critical Error: Net Package not found in ReplicatedStorage!")
    end
end
SetupEvents()

-- ====================================================================
--                  SHOP LOGIC & CONTENT SCANNER
-- ====================================================================

-- Variable Penyimpanan Data Shop
local ShopData = {
    Rods = {},      -- Mapping Nama -> ID
    Baits = {},     -- Mapping Nama -> ID
    RodNames = {},  -- List String untuk Dropdown
    BaitNames = {}  -- List String untuk Dropdown
}

local function ScanShopItems()
    -- 1. Reset Data
    ShopData.Rods = {}
    ShopData.Baits = {}
    ShopData.RodNames = {}
    ShopData.BaitNames = {}
    
    print("🔍 Scanning ReplicatedStorage for Shop Items...")

    -- Kita akan scan seluruh ReplicatedStorage (Deep Scan)
    -- Kita tidak peduli nama filenya (mau ada "!!!" atau tidak), kita cek ISINYA.
    local descendants = Services.ReplicatedStorage:GetDescendants()
    
    for _, obj in pairs(descendants) do
        -- Kita hanya proses ModuleScript
        -- Filter sedikit: Jangan scan folder 'Packages' biar ga ngeleg/error
        if obj:IsA("ModuleScript") and not obj:FindFirstAncestor("Packages") then
            
            -- Coba baca isi Module
            local success, result = pcall(require, obj)
            
            -- Cek apakah module ini punya struktur data item
            if success and result and type(result) == "table" and result.Data then
                local d = result.Data
                local name = d.Name
                local id = d.Id
                local itemType = d.Type 
                
                if name and id and itemType then
                    -- LOGIC: Masukkan ke kategori yang sesuai
                    
                    if itemType == "Fishing Rods" then
                        -- Rods (Walaupun nama filenya "!!! Rod", d.Name isinya bersih "Rod")
                        ShopData.Rods[name] = id
                        table.insert(ShopData.RodNames, name)
                        
                    elseif itemType == "Baits" or itemType == "Consumable" then
                        -- Baits
                        ShopData.Baits[name] = id
                        table.insert(ShopData.BaitNames, name)
                    end
                end
            end
        end
    end
    
    -- Urutkan nama biar rapi A-Z di Dropdown
    table.sort(ShopData.RodNames)
    table.sort(ShopData.BaitNames)
    
    print("✅ Scan Complete!")
    print("🎣 Rods Found: " .. #ShopData.RodNames)
    print("🪱 Baits Found: " .. #ShopData.BaitNames)
    
    -- Notifikasi Debug
    if #ShopData.RodNames == 0 and #ShopData.BaitNames == 0 then
        warn("❌ Scanner found nothing! Check filtering logic.")
    end
end

-- Jalankan Scanner (Pakai task.spawn biar ga freeze game pas scanning)
task.spawn(ScanShopItems)

local MerchantCache = {
    Items = {},      -- List Item ID untuk dikirim ke Remote
    DisplayNames = {} -- List Nama untuk Dropdown UI
}

local function RefreshMerchantItems()
    MerchantCache.Items = {}
    MerchantCache.DisplayNames = {}
    
    -- Load Replion
    local success, ReplionModule = pcall(function() return require(Services.ReplicatedStorage.Packages.Replion) end)
    local ItemUtility = require(Services.ReplicatedStorage.Shared.ItemUtility)
    local MarketData = require(Services.ReplicatedStorage.Shared.MarketItemData)
    
    if success and ReplionModule then
        -- Ambil Replion "Merchant"
        local successWait, merchRep = pcall(function() return ReplionModule.Client:GetReplion("Merchant") end)
        
        if successWait and merchRep then
            -- "Items" adalah list ID barang yang sedang dijual
            local currentItems = merchRep:GetExpect("Items") or {}
            
            for _, marketID in ipairs(currentItems) do
                -- Cari Data Market berdasarkan ID (untuk tau ini item apa)
                local marketItem = nil
                for _, v in pairs(MarketData) do
                    if v.Id == marketID then marketItem = v break end
                end
                
                if marketItem then
                    -- Ambil Nama Asli Item dari ItemUtility
                    local itemData = ItemUtility.GetItemDataFromItemType(marketItem.Type, marketItem.Identifier)
                    if itemData and itemData.Data then
                        local itemName = itemData.Data.Name
                        local price = marketItem.Price or "???"
                        
                        -- Format Nama: "Rare Key (500)"
                        local displayName = itemName .. " (" .. price .. ")"
                        
                        table.insert(MerchantCache.DisplayNames, displayName)
                        MerchantCache.Items[displayName] = marketID -- Simpan ID aslinya untuk pembelian
                    end
                end
            end
            
            table.sort(MerchantCache.DisplayNames)
            print("✅ Merchant Items Refreshed: " .. #MerchantCache.DisplayNames .. " items found.")
        end
    end
    return MerchantCache.DisplayNames
end

-- Anti AFK
LocalPlayer.Idled:Connect(function()
    Services.VirtualUser:CaptureController()
    Services.VirtualUser:ClickButton2(Vector2.new())
end)

-- Fishing Logic Variables
local fishingActive = false
local isFishing = false

-- Locations
local LOCATIONS = {
    ["Fisherman Island"] = CFrame.new(35, 17, 2851),
    ["Ancient Jungle"] = CFrame.new(1489, 7, -425),
    ["Sacred Temple"] = CFrame.new(1478, -22, -611),
    ["Ancuent Ruins"] = CFrame.new(6097, -586, 4665),
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

-- ====================================================================
--                  EVENT DATA & LOGIC (SMART VERSION)
-- ====================================================================

-- Database: Koordinat DAN Nama Model untuk Auto-Detect
local EVENT_DATABASE = {
    ["Ghost Shark Hunt"] = {
        TargetNames = {"Ghost Shark", "GhostShark"}, -- Nama model yang dicari di Workspace
        Coords = {
            Vector3.new(489.558, -1.35, 25.406), 
            Vector3.new(-1358.2, -1.35, 4100.55), 
            Vector3.new(627.859, -1.35, 3798.08)
        }
    },
    ["Megalodon Hunt"] = {
        TargetNames = {"Megalodon"},
        Coords = {
            Vector3.new(-1076.3, -1.4, 1676.19), 
            Vector3.new(-1191.8, -1.4, 3597.30), 
            Vector3.new(412.7, -1.4, 4134.39)
        }
    },
    ["Shark Hunt"] = {
        TargetNames = {"Great White Shark", "Shark"}, 
        Coords = {
            Vector3.new(1.65, -1.35, 2095.72), 
            Vector3.new(1369.94, -1.35, 930.125), 
            Vector3.new(-1585.5, -1.35, 1242.87), 
            Vector3.new(-1896.8, -1.35, 2634.37)
        }
    },
    ["Worm Hunt"] = {
        TargetNames = {"Worm"}, -- Sesuaikan jika nama modelnya beda (cek pake Dex)
        Coords = {
            Vector3.new(2190.85, -1.4, 97.57), 
            Vector3.new(-2450.6, -1.4, 139.73), 
            Vector3.new(-267.47, -1.4, 5188.53)
        }
    },
    ["Admin - Ghost Worm"] = {
        TargetNames = {"Ghost Worm"},
        Coords = { Vector3.new(-327, -1.4, 2422) }
    },
    ["Treasure Hunt"] = {
        TargetNames = {"Shipwreck", "Treasure", "Chest"},
        Coords = {} -- Tidak ada koordinat statis, full scan
    }
}

local FloatBody = nil
local FloatConnection = nil

-- Fungsi Float/Hover (DIPERBAIKI: Lebih Kuat)
local function ToggleFloat(bool)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    if bool then
        -- 1. Buat BodyVelocity jika belum ada
        if not hrp:FindFirstChild("CatrazFloat") then
            FloatBody = Instance.new("BodyVelocity")
            FloatBody.Name = "CatrazFloat"
            FloatBody.Parent = hrp
            FloatBody.MaxForce = Vector3.new(0, math.huge, 0) -- Tahan Y Axis (Gravitasi)
            FloatBody.Velocity = Vector3.new(0, 0, 0)
        end
        
        -- 2. Matikan State Humanoid (Biar ga animasi renang/jatuh)
        hum.PlatformStand = true
    else
        -- Matikan Float
        if hrp:FindFirstChild("CatrazFloat") then
            hrp.CatrazFloat:Destroy()
        end
        if hum then
            hum.PlatformStand = false
        end
        FloatBody = nil
    end
end

-- Fungsi Pintar: Cari Model dulu, kalau ga ketemu baru ke Koordinat
local function SmartTeleportToEvent(eventName)
    local data = EVENT_DATABASE[eventName]
    if not data then return end

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    -- TAHAP 1: SCANNING (Cari Model Boss di Workspace)
    print("🔍 Scanning for models: ", table.concat(data.TargetNames, ", "))
    local foundModel = nil
    
    for _, targetName in ipairs(data.TargetNames) do
        -- Cari di workspace
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == targetName and (obj:IsA("Model") or obj:IsA("BasePart")) then
                foundModel = obj
                break
            end
        end
        if foundModel then break end
    end

    -- JIKA KETEMU MODELNYA (Active Location Found!)
    if foundModel then
        local targetCFrame = foundModel:GetPivot()
        char.HumanoidRootPart.CFrame = targetCFrame + Vector3.new(0, 35, 0) -- Teleport di atas boss
        WindUI:Notify({ Title = "Smart Detect", Content = "Found Active " .. foundModel.Name .. "!", Duration = 3 })
        
        -- Paksa Nyalakan Fitur Pendukung
        ToggleFloat(true) 
        return true -- Sukses
    end

    -- TAHAP 2: JIKA TIDAK KETEMU, CEK KOORDINAT (Auto-Cycle)
    -- Script akan teleport ke lokasi satu per satu untuk mengecek
    if #data.Coords > 0 then
        WindUI:Notify({ Title = "Searching...", Content = "Model not found via Scan. Checking Spawns...", Duration = 2 })
        
        -- Teleport ke lokasi pertama (atau acak, tapi mending urut)
        -- Kita pakai sistem Loop sederhana
        task.spawn(function()
            for i, vec in ipairs(data.Coords) do
                char.HumanoidRootPart.CFrame = CFrame.new(vec) + Vector3.new(0, 35, 0)
                ToggleFloat(true) -- Aktifkan float biar ga jatuh pas teleport
                WindUI:Notify({ Title = "Checking Loc " .. i, Content = "Searching area...", Duration = 1 })
                
                task.wait(1.5) -- Tunggu sebentar loading chunk
                
                -- Cek lagi apakah ada model di dekat sini?
                -- (Biasanya kalau kita deketin, modelnya baru spawn/render)
                local nearby = false
                for _, targetName in ipairs(data.TargetNames) do
                    if workspace:FindFirstChild(targetName) then
                        nearby = true
                        break
                    end
                end
                
                if nearby then
                    WindUI:Notify({ Title = "Found!", Content = "Event is here!", Duration = 3 })
                    return -- Stop loop, kita sudah sampai
                end
            end
            WindUI:Notify({ Title = "Not Found", Content = "Event might not be spawned yet.", Duration = 3 })
        end)
    else
        WindUI:Notify({ Title = "Failed", Content = "No active model & no coordinates found.", Duration = 2 })
    end
end

-- Fungsi CastRod tetap sama
local function CastRod()
    pcall(function()
        Events.equip:FireServer(1)
        task.wait(0.05)
        Events.charge:InvokeServer(1755848498.4834)
        task.wait(0.02)
        Events.minigame:InvokeServer(1.2854545116425, 1)
    end)
end

-- 1. Mode Instant (Dulu NormalLoop) - Skip Minigame
local function InstantLoop()
    while fishingActive and not Config.BlatantMode and Config.FishingMode == "Instant" do
        if not isFishing then
            isFishing = true
            CastRod()
            task.wait(Config.FishDelay) -- Tunggu digigit
            pcall(function() Events.fishing:FireServer() end) -- Langsung selesai
            task.wait(Config.CatchDelay)
            isFishing = false
        else
            task.wait(0.1)
        end
    end
end

-- 2. Mode Legit - Tap Tap Kenceng
local function LegitLoop()
    while fishingActive and not Config.BlatantMode and Config.FishingMode == "Legit" do
        if not isFishing then
            isFishing = true
            CastRod()
            task.wait(Config.FishDelay) -- Tunggu digigit
            
            -- Simulasi Tap Tap Kenceng (Minigame)
            -- Kita spam klik kiri mouse selama 2 detik (bisa diatur)
            local tapDuration = 0.1
            local startTime = tick()
            
            while tick() - startTime < tapDuration do
                Services.VirtualUser:ClickButton1(Vector2.new(999, 999))
                task.wait(0.08) -- Kecepatan tap (semakin kecil semakin ngebut)
            end
            
            -- Akhiri dengan FireServer untuk memastikan ikan dapet
            pcall(function() Events.fishing:FireServer() end)
            
            task.wait(Config.CatchDelay)
            isFishing = false
        else
            task.wait(0.1)
        end
    end
end

-- 3. Blatant Loop (Tetap sama, logic ugal-ugalan)
local function BlatantLoop()
    while fishingActive and Config.BlatantMode do
        if not isFishing then
            isFishing = true
            -- Double Cast Trick
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
            
            -- Spam Catch
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

-- Main Loop Starter
local function ToggleFishing(bool)
    fishingActive = bool
    if bool then
        task.spawn(function()
            while fishingActive do
                if Config.BlatantMode then
                    -- Prioritas 1: Blatant
                    BlatantLoop() 
                elseif Config.FishingMode == "Legit" then
                    -- Prioritas 2: Legit (Tap Tap)
                    LegitLoop()
                else
                    -- Prioritas 3: Instant (Default/Normal)
                    InstantLoop()
                end
                task.wait(0.1)
            end
        end)
        
        -- Auto Catch Helper (Hanya jalan kalau BUKAN Legit mode, biar ga ganggu tap-tap)
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

-- Auto Sell
task.spawn(function()
    while true do
        task.wait(Config.SellDelay)
        if Config.AutoSell then pcall(function() Events.sell:InvokeServer() end) end
    end
end)

-- ====================================================================
--                  WEATHER LOGIC
-- ====================================================================

-- Daftar Cuaca & Harga (Untuk Info Visual)
local WeatherList = {
    "Cloudy",       -- 20k
    "Radiant",      -- 50k
    "Snow",         -- 15k
    "Storm",        -- 35k
    "Wind",         -- 10k
    "Shark Hunt"    -- 300k
}

local SelectedWeathers = {} -- Menyimpan pilihan dari Dropdown
local AutoWeatherActive = false

-- Fungsi Loop Auto Buy
task.spawn(function()
    while true do
        if AutoWeatherActive and #SelectedWeathers > 0 then
            for _, weatherName in ipairs(SelectedWeathers) do
                if not AutoWeatherActive then break end -- Stop jika dimatikan di tengah jalan
                
                -- Beli Cuaca
                pcall(function()
                    Events.buyWeather:InvokeServer(weatherName)
                    -- Notif kecil biar tau lagi beli
                    -- print("Buying Weather: " .. weatherName) 
                end)
                
                -- Delay antar pembelian (Supaya uang ga habis instan/spamming)
                -- Weather biasanya durasinya lama (900 detik), jadi delay agak lama aman.
                -- Tapi kalau mau 'antri' cuaca, 5 detik cukup.
                task.wait(5) 
            end
        end
        task.wait(1) -- Cek status setiap detik
    end
end)

-- ====================================================================
--                  AUTO FAVORITE CONFIG & LOGIC (REPLION VERSION)
-- ====================================================================

-- Mapping Rarity ke Angka
local RarityMap = {
    ["Common"] = 1, ["Uncommon"] = 2, ["Rare"] = 3, ["Epic"] = 4, 
    ["Legendary"] = 5, ["Mythic"] = 6, ["Secret"] = 7
}

Config.FavInterval = 3
Config.MinRarityNum = 6 -- Default Mythic

-- ====================================================================
--            AUTO FAVORITE LOGIC (ADVANCED FILTER + UNFAV)
-- ====================================================================

local ItemInfoCache = {} 
local ReplionData = nil
local ItemsFolder = Services.ReplicatedStorage:WaitForChild("Items", 10)
local DatabaseIndexed = false

-- 1. FUNGSI SCANNER DATABASE (UPDATE: AMBIL NAMA)
local function IndexItemDatabase()
    if DatabaseIndexed then return end
    
    print("📚 Indexing Database Item... (Mohon Tunggu)")
    GlobalFishNames = {} -- Reset list
    local count = 0
    
    for _, module in pairs(ItemsFolder:GetDescendants()) do
        if module:IsA("ModuleScript") then
            local success, result = pcall(require, module)
            if success and result and result.Data then
                local id = result.Data.Id
                local name = result.Data.Name
                
                if id then
                    -- Simpan ke Cache
                    ItemInfoCache[id] = {
                        Tier = result.Data.Tier or 0,
                        Type = result.Data.Type or "Fish",
                        Name = name or "Unknown"
                    }
                    
                    -- Masukkan nama ikan ke list global (untuk Dropdown UI)
                    if name and result.Data.Type == "Fish" then
                        table.insert(GlobalFishNames, name)
                    end
                    count = count + 1
                end
            end
        end
    end
    
    table.sort(GlobalFishNames) -- Urutkan Abjad
    DatabaseIndexed = true
    print("✅ Database Selesai: " .. count .. " item terdaftar.")
end

-- 2. FUNGSI INTIP DATA
local function GetItemInfo(itemId)
    if not DatabaseIndexed then IndexItemDatabase() end
    local sId = tostring(itemId)
    if ItemInfoCache[sId] then return ItemInfoCache[sId] end
    return {Tier = 0, Type = "Fish", Name = "Unknown"}
end

-- 3. FUNGSI AMBIL INVENTORY
local function GetReplionInventory()
    if not ReplionData then
        local success, ReplionModule = pcall(function() return require(Services.ReplicatedStorage.Packages.Replion) end)
        if success and ReplionModule then pcall(function() ReplionData = ReplionModule.Client:GetReplion("Data") end) end
    end
    if ReplionData and ReplionData.Data and ReplionData.Data.Inventory then
        if ReplionData.Data.Inventory.Items then return ReplionData.Data.Inventory.Items else return ReplionData.Data.Inventory end
    end
    return {}
end

-- 4. LOGIKA UTAMA (LOCK & UNLOCK)
local function RunAutoFavorite()
    local inventory = GetReplionInventory()
    local actionCount = 0

    if not inventory then return end

    for _, itemData in pairs(inventory) do
        if type(itemData) == "table" and itemData.Id and itemData.UUID then
            
            local isFav = itemData.Favorited or false
            local info = GetItemInfo(itemData.Id)
            local variant = itemData.VariantId -- Bisa nil atau string "Shiny"
            
            -- === CEK APAKAH ITEM INI HARUS DISIMPAN? ===
            local shouldKeep = false
            
            -- Cek 1: Rarity (Whitelist Mode)
            if Config.WhitelistRarities[info.Tier] then
                shouldKeep = true
            end
            
            -- Cek 2: Nama Ikan (Whitelist Mode)
            if info.Name and Config.WhitelistNames[info.Name] then
                shouldKeep = true
            end
            
            -- Cek 3: Variant (Whitelist Mode)
            if variant and Config.WhitelistVariants[variant] then
                shouldKeep = true
            end
            
            -- === EKSEKUSI ===
            
            -- KASUS A: Barang Bagus tapi BELUM di-Fav -> LOCK
            if shouldKeep and not isFav and Config.AutoFavorite then
                pcall(function()
                    if Events and Events.favorite then
                        local args = { itemData.UUID, info.Type }
                        Events.favorite:FireServer(unpack(args)) -- Toggle ON
                        print("🔒 Locked: " .. info.Name .. " (Tier " .. info.Tier .. ")")
                    end
                end)
                actionCount = actionCount + 1
                task.wait(0.2)
                
            -- KASUS B: Barang Sampah tapi SUDAH di-Fav -> UNLOCK (Auto Unfavorite)
            elseif not shouldKeep and isFav and Config.AutoUnfavorite then
                pcall(function()
                    if Events and Events.favorite then
                        local args = { itemData.UUID, info.Type }
                        Events.favorite:FireServer(unpack(args)) -- Toggle OFF
                        print("🔓 Unlocked: " .. info.Name .. " (Trash)")
                    end
                end)
                actionCount = actionCount + 1
                task.wait(0.2)
            end
        end
        
        if actionCount > 5 then break end -- Limit per loop biar ga disconnect
    end
    
    if actionCount > 0 then
        -- WindUI:Notify({ Title = "Manager", Content = "Updated " .. actionCount .. " items.", Duration = 2 })
    end
end

-- Loop di Background
task.spawn(function()
    task.wait(2)
    IndexItemDatabase() -- Index di awal
    while true do
        task.wait(Config.FavInterval)
        if Config.AutoFavorite or Config.AutoUnfavorite then
            RunAutoFavorite()
        end
    end
end)

-- ====================================================================
--                  TELEPORT LEGIC
-- ====================================================================

-- Fungsi untuk mengambil nama semua player (kecuali diri sendiri)
local function GetPlayerNames()
    local names = {}
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(names, player.Name)
        end
    end
    table.sort(names) -- Urutkan abjad biar gampang cari
    return names
end

-- GPU Saver
local BlackScreen = nil
local function ToggleGPU(bool)
    if bool then
        pcall(function() setfpscap(8) end)
        BlackScreen = Instance.new("ScreenGui", game.CoreGui)
        local f = Instance.new("Frame", BlackScreen)
        f.Size, f.BackgroundColor3 = UDim2.new(1,0,1,0), Color3.new(0,0,0)
        local t = Instance.new("TextLabel", f)
        t.Text, t.Size, t.TextColor3, t.BackgroundTransparency = "GPU SAVER ON", UDim2.new(1,0,1,0), Color3.new(0,1,0), 1
    else
        pcall(function() setfpscap(0) end)
        if BlackScreen then BlackScreen:Destroy() end
    end
end

-- ====================================================================
--                  3. WIND UI IMPLEMENTATION
-- ====================================================================

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

function createPopup()
    return WindUI:Popup({
        Title = "Welcome to Catraz Hub!",
        Icon = "snail",
        Content = "do by your own risk!",
        Buttons = {
            {
                Title = "Click Here !",
                Icon = "bird",
            }
        }
    })
end


-- */  Window  /* --
local Window = WindUI:CreateWindow({
    Title = "Catraz Hub |  Fish It",
    Author = "by alcatraz • team",
    Folder = "chub",
    Icon = "snail",
    IconSize = 22*2,
    NewElements = true,
    --Size = UDim2.fromOffset(700,700),
    
    HideSearchBar = false,
    
    OpenButton = {
        Title = "Open Catraz Hub", -- can be changed
        CornerRadius = UDim.new(1,0), -- fully rounded
        StrokeThickness = 3, -- removing outline
        Enabled = true, -- enable or disable openbutton
        Draggable = true,
        OnlyMobile = false,
        
        Color = ColorSequence.new( -- gradient
            Color3.fromHex("#fc03f8"), 
            Color3.fromHex("#db03fc")
        )
    },
    
    KeySystem = {
        Title = "Key System Example  |  WindUI Example",
        Note = "Key System. Key: 1234",
        KeyValidator = function(EnteredKey)
            if EnteredKey == "1234" then
                createPopup()
                return true
            end
            return false
            -- return EnteredKey == "1234" -- if key == "1234" then return true else return false end
        end
    }
})

-- TABS
local MainTab = Window:Tab({ Title = "Main", Icon = "house" })
local ShopTab = Window:Tab({ Title = "Shop", Icon = "store" })
local TeleportTab = Window:Tab({ Title = "Teleport", Icon = "navigation" })
local MiscTab = Window:Tab({ Title = "Misc", Icon = "settings" })
local ConfigTab = Window:Tab({ Title = "Configs", Icon = "save" })

-- >> MAIN SECTION (AUTO FARM)
local MainSection = MainTab:Section({ Title = "Auto Farm", Icon = "fish-symbol", Opened = true })

-- Toggle Utama
MainSection:Toggle({
    Title = "Auto Fish",
    Default = Config.AutoFish,
    Callback = function(value)
        Config.AutoFish = value
        ToggleFishing(value)
    end
})

-- Dropdown Mode (Instant vs Legit)
MainSection:Dropdown({
    Title = "Fishing Mode",
    Multi = false,
    AllowNone = true,
    Values = { "Instant", "Legit" }, -- Pilihan Mode
    Callback = function(value)
        Config.FishingMode = value
    end
})

-- Blatant Mode (Checkbox / Toggle Override)
MainSection:Toggle({
    Title = "⚡ Blatant Mode (Override All)",
    Desc = "(3x Faster)",
    Type = "Checkbox",
    Default = Config.BlatantMode,
    Callback = function(value)
        Config.BlatantMode = value
    end
})

MainSection:Input({
    Title = "Fish Delay (Wait for bite)",
    Default = tostring(Config.FishDelay),
    Placeholder = "Example: 0.9",
    Numeric = true, -- Hanya izinkan angka
    Finished = true, -- Callback jalan setelah tekan enter/keluar kolom
    Callback = function(value)
        local num = tonumber(value)
        if num then
            Config.FishDelay = num
        end
    end
})

MainSection:Input({
    Title = "Catch Delay (Cooldown)",
    Default = tostring(Config.CatchDelay),
    Placeholder = "Example: 0.2",
    Numeric = true, -- Hanya izinkan angka
    Finished = true, -- Callback jalan setelah tekan enter/keluar kolom
    Callback = function(value)
        local num = tonumber(value)
        if num then
            Config.CatchDelay = num
        end
    end
})

-- ====================================================================
--                  EVENT FARMING UI (SMART & FIXED)
-- ====================================================================

local EventSection = MainTab:Section({ Title = "Event Farming", Icon = "globe" })

local selectedEventKey = nil
local ManualFloatToggleUI = nil
local AutoFishToggleUI = nil 

-- Dropdown Event
EventSection:Dropdown({
    Title = "Select Event",
    Desc = "Choose active event",
    Value = nil,
    Values = (function()
        local keys = {}
        for k, v in pairs(EVENT_DATABASE) do table.insert(keys, k) end
        table.sort(keys)
        return keys
    end)(),
    Multi = false,
    Callback = function(value)
        selectedEventKey = value
    end
})

-- Tombol Teleport PINTAR
EventSection:Button({
    Title = "🚀 Smart Teleport & Farm",
    Desc = "Auto-Find Active Boss -> Float -> Auto Fish",
    Callback = function()
        if not selectedEventKey then
            WindUI:Notify({ Title = "Error", Content = "Please select an event first!", Duration = 2 })
            return
        end

        -- 1. Jalankan Smart Teleport
        -- Fungsi ini akan mencari model Boss. Kalau ketemu -> Teleport.
        -- Kalau ga ketemu -> Teleport ke koordinat 1, 2, 3...
        SmartTeleportToEvent(selectedEventKey)

        -- 2. FORCE ENABLE FEATURES (Perbaikan Bug Float)
        -- Jangan cuma andalkan UI Callback, panggil fungsi langsung!
        
        -- A. Float
        ToggleFloat(true) 
        if ManualFloatToggleUI then 
            ManualFloatToggleUI:SetValue(true) -- Update visual UI biar sinkron
        end

        -- B. Auto Fish
        if not Config.AutoFish then
            Config.AutoFish = true
            ToggleFishing(true) -- Paksa nyala script mancing
            
            -- Update visual UI di Main Tab (kalau variabelnya ketemu)
            if AutoFishToggleUI then
                AutoFishToggleUI:SetValue(true)
            end
            WindUI:Notify({ Title = "System", Content = "Auto Fish & Float Enabled!", Duration = 2 })
        end
    end
})

-- Toggle Float Manual
ManualFloatToggleUI = EventSection:Toggle({
    Title = "Manual Float",
    Desc = "Keep character in the air",
    Value = false,
    Callback = function(state)
        ToggleFloat(state)
    end
})

-- Tombol Scan Manual (Backup kalau Smart Teleport gagal)
EventSection:Button({
    Title = "🔍 Force Scan Workspace",
    Desc = "Try to find ANY event model",
    Callback = function()
        -- Scan generic event keywords
        local keywords = {"Boss", "Shark", "Megalodon", "Meteor", "Chest", "Shipwreck"}
        local found = false
        
        for _, word in ipairs(keywords) do
            for _, obj in pairs(workspace:GetDescendants()) do
                if string.find(obj.Name, word) and (obj:IsA("Model") or obj:IsA("BasePart")) then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = obj:GetPivot() * CFrame.new(0, 35, 0)
                    ToggleFloat(true)
                    WindUI:Notify({ Title = "Found", Content = obj.Name, Duration = 2 })
                    found = true
                    break
                end
            end
            if found then break end
        end
        
        if not found then
            WindUI:Notify({ Title = "Failed", Content = "No event models found in range.", Duration = 2 })
        end
    end
})

-- >> SHOP SECTION
local ShopSection = ShopTab:Section({ Title = "Shop Center", Icon = "store", Opened = true })

local selectedRodName = nil
local selectedBaitName = nil

-- === 1. FISHING RODS ===
ShopSection:Dropdown({
    Title = "🎣 Select Rod",
    Multi = false,
    AllowNone = true,
    Values = ShopData.RodNames, 
    Callback = function(value)
        selectedRodName = value
    end
})

ShopSection:Button({
    Title = "Purchase Rod",
    Desc = "Buy selected rod",
    Callback = function()
        if selectedRodName and ShopData.Rods[selectedRodName] then
            local rodID = ShopData.Rods[selectedRodName]
            
            print("🛒 Buying Rod:", selectedRodName, "| ID:", rodID, "| Type:", type(rodID))
            
            -- COBA CARA 1 (Sesuai RemoteSpy): Kirim ID langsung
            local success, err = pcall(function() 
                -- RemoteSpy bilang: InvokeServer(unpack({76})) -> Artinya InvokeServer(76)
                Events.buyRod:InvokeServer(rodID) 
            end)
            
            if success then
                WindUI:Notify({ Title = "Shop", Content = "Bought " .. selectedRodName, Duration = 2 })
            else
                warn("❌ Buy Rod Failed:", err)
                WindUI:Notify({ Title = "Error", Content = "Failed (Check Console F9)", Duration = 2 })
            end
        else
            WindUI:Notify({ Title = "Error", Content = "Select a rod first!", Duration = 2 })
        end
    end
})

-- === 2. BAITS ===
ShopSection:Dropdown({
    Title = "🪱 Select Bait",
    Multi = false,
    AllowNone = true,
    Values = ShopData.BaitNames, 
    Callback = function(value)
        selectedBaitName = value
    end
})

ShopSection:Button({
    Title = "Purchase Bait",
    Desc = "Buy selected bait",
    Callback = function()
        if selectedBaitName and ShopData.Baits[selectedBaitName] then
            local baitID = ShopData.Baits[selectedBaitName]
            
            print("🛒 Buying Bait:", selectedBaitName, "| ID:", baitID, "| Type:", type(baitID))
            
            local success, err = pcall(function() 
                -- RemoteSpy bilang: InvokeServer(unpack({2})) -> Artinya InvokeServer(2)
                Events.buyBait:InvokeServer(baitID) 
            end)
            
            if success then
                WindUI:Notify({ Title = "Shop", Content = "Bought " .. selectedBaitName, Duration = 2 })
            else
                warn("❌ Buy Bait Failed:", err)
                WindUI:Notify({ Title = "Error", Content = "Failed (Check Console F9)", Duration = 2 })
            end
        else
            WindUI:Notify({ Title = "Error", Content = "Select a bait first!", Duration = 2 })
        end
    end
})

-- === TRAVELING MERCHANT (DYNAMIC) ===
local MerchantDropdown = nil
local selectedMerchantItemName = nil

ShopSection:Button({
    Title = "Teleport to Merchant",
    Desc = "Go to merchant location",
    Callback = function()
        local merchant = workspace:FindFirstChild("TravelingMerchant") or workspace:FindFirstChild("Merchant")
        if merchant and merchant:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = merchant.HumanoidRootPart.CFrame
            WindUI:Notify({ Title = "Teleport", Content = "Warped to Merchant!", Duration = 2 })
        else
            WindUI:Notify({ Title = "Error", Content = "Merchant not spawned!", Duration = 2 })
        end
    end
})

MerchantDropdown = ShopSection:Dropdown({
    Title = "Merchant Stock (Live)",
    Multi = false,
    AllowNone = true,
    Values = RefreshMerchantItems(), -- Scan saat script pertama jalan
    Callback = function(value)
        selectedMerchantItemName = value
    end
})

ShopSection:Button({
    Title = "🔄 Refresh Stock",
    Desc = "Check what merchant is selling now",
    Callback = function()
        if MerchantDropdown then
            MerchantDropdown:Refresh(RefreshMerchantItems())
            WindUI:Notify({ Title = "System", Content = "Merchant stock updated!", Duration = 1 })
        end
    end
})

ShopSection:Button({
    Title = "Buy Merchant Item",
    Callback = function()
        if selectedMerchantItemName and MerchantCache.Items[selectedMerchantItemName] then
            local marketID = MerchantCache.Items[selectedMerchantItemName]
            
            -- Eksekusi Remote: RF/PurchaseMarketItem(marketID)
            local success, result = pcall(function() 
                return Events.buyMerchant:InvokeServer(marketID) 
            end)
            
            if success then
                WindUI:Notify({ Title = "Shop", Content = "Purchase Request Sent!", Duration = 2 })
            else
                WindUI:Notify({ Title = "Error", Content = "Purchase Failed!", Duration = 2 })
            end
        else
            WindUI:Notify({ Title = "Error", Content = "Select an item first!", Duration = 2 })
        end
    end
})

-- === 4. AUTO SELL ===
ShopSection:Toggle({
    Title = "Auto Sell All",
    Default = Config.AutoSell,
    Callback = function(value)
        Config.AutoSell = value
    end
})

-- ====================================================================
--                  WEATHER MACHINE UI (MULTI SELECT)
-- ====================================================================

local ShopSection = ShopTab:Section({ Title = "Weather Buy", Icon = "cloud-lightning", Opened = true })

-- 1. Dropdown Multi Select (Sesuai Docs: Multi=true, Value={})
ShopSection:Dropdown({
    Title = "Select Weather(s)",
    Desc = "Multi-select allowed. Can deselect.",
    Multi = true, -- BISA PILIH LEBIH DARI 1
    Value = {},   -- Default kosong (table)
    Values = WeatherList,
    Callback = function(values)
        -- 'values' akan mengembalikan table berisi string, contoh: {"Snow", "Wind"}
        SelectedWeathers = values
        
        -- Debug print untuk memastikan isi table
        -- print("Selected Weathers:", table.concat(SelectedWeathers, ", "))
    end
})

-- 2. Toggle Auto Buy
ShopSection:Toggle({
    Title = "Auto Buy Selected Weather",
    Desc = "Cycles through selection and buys them",
    Value = false, -- Sesuai Docs WindUI
    Callback = function(state)
        AutoWeatherActive = state
        
        if state then
            if #SelectedWeathers == 0 then
                WindUI:Notify({ Title = "Warning", Content = "Select a weather first!", Duration = 3 })
            else
                WindUI:Notify({ Title = "System", Content = "Auto Buying Weather Started...", Duration = 2 })
            end
        else
            WindUI:Notify({ Title = "System", Content = "Auto Buy Stopped.", Duration = 2 })
        end
    end
})

-- 3. Tombol Manual (Buy Once) - Opsional tapi berguna
ShopSection:Button({
    Title = "Buy Selected Once",
    Desc = "Buy all selected weathers one time immediately",
    Callback = function()
        if #SelectedWeathers == 0 then
            WindUI:Notify({ Title = "Error", Content = "Select a weather first!", Duration = 2 })
            return
        end

        local boughtCount = 0
        for _, wName in ipairs(SelectedWeathers) do
            local success = pcall(function() Events.buyWeather:InvokeServer(wName) end)
            if success then boughtCount = boughtCount + 1 end
            task.wait(0.5) -- Delay dikit biar server ga nolak request
        end
        
        WindUI:Notify({ Title = "Shop", Content = "Attempted to buy " .. boughtCount .. " weathers.", Duration = 2 })
    end
})

-- >> TELEPORT SECTION

local TeleportSection = TeleportTab:Section({ Title = "Teleport To Islands", Icon = "navigation", Opened = true })

-- 1. Siapkan List Nama Lokasi (Diurutkan Abjad)
local sortedLocs = {}
for name, _ in pairs(LOCATIONS) do 
    table.insert(sortedLocs, name) 
end
table.sort(sortedLocs) -- Biar rapi A-Z

-- 2. Buat Dropdown Teleport
TeleportSection:Dropdown({
    Title = "Select Destination",
    Multi = false,
    AllowNone = true, -- Bisa dikosongkan
    Values = sortedLocs, -- Masukkan list nama lokasi tadi
    Callback = function(value)
        -- Cek apakah value ada (takutnya user unselect/pilih kosong)
        if value and LOCATIONS[value] then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                -- Eksekusi Teleport
                char.HumanoidRootPart.CFrame = LOCATIONS[value]
                
                -- Notifikasi
                WindUI:Notify({ 
                    Title = "Teleport", 
                    Content = "Warped to " .. value, 
                    Duration = 2 
                })
            end
        end
    end
})

-- ... (Kode tombol lokasi kamu yang lama di sini) ...

-- Pemisah biar rapi (Opsional, WindUI kadang otomatis kasih jarak)
-- TeleportSection:Div({ Content = "Player Teleport" }) -- Kalau support Div

local selectedPlayer = nil
local PlayerDropdown = nil

-- Dropdown Pilih Player
PlayerDropdown = TeleportSection:Dropdown({
    Title = "Select Player",
    Multi = false,
    AllowNone = true,
    Values = GetPlayerNames(), -- Ambil list player saat script jalan
    Callback = function(value)
        selectedPlayer = value
    end
})

-- Tombol Refresh List (Penting! Kalau ada orang baru join/leave)
TeleportSection:Button({
    Title = "🔄 Refresh Player List",
    Desc = "Update the player dropdown",
    Callback = function()
        if PlayerDropdown then
            -- Syntax refresh WindUI: Object:Refresh(NewValues, DefaultValue)
            PlayerDropdown:Refresh(GetPlayerNames())
            WindUI:Notify({ Title = "System", Content = "Player list updated!", Duration = 1 })
        end
    end
})

-- Tombol Eksekusi Teleport
TeleportSection:Button({
    Title = "🚀 Teleport to Player",
    Callback = function()
        if not selectedPlayer then
            WindUI:Notify({ Title = "Error", Content = "Select a player first!", Duration = 2 })
            return
        end

        local target = Services.Players:FindFirstChild(selectedPlayer)
        
        -- Cek apakah player valid dan punya karakter
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local targetHRP = target.Character.HumanoidRootPart
            local myChar = LocalPlayer.Character
            
            if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                -- Teleport sedikit di belakang/samping player (biar ga nyangkut)
                myChar.HumanoidRootPart.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
                WindUI:Notify({ Title = "Teleport", Content = "Warped to " .. selectedPlayer, Duration = 2 })
            else
                WindUI:Notify({ Title = "Error", Content = "Wait for your character to spawn!", Duration = 2 })
            end
        else
            WindUI:Notify({ Title = "Error", Content = "Target player not found/spawned!", Duration = 2 })
        end
    end
})

-- Definisikan List Rarity untuk Dropdown (Urut dari terendah ke tertinggi)
local RarityList = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret"}

-- >> MISC SECTION
local MiscSection = MiscTab:Section({ Title = "Advanced Manager", Icon = "settings", Opened = true })

-- Toggle Fitur Utama
MiscSection:Toggle({
    Title = "Enable Auto Lock",
    Desc = "Lock items matching filters below",
    Default = Config.AutoFavorite,
    Callback = function(v) Config.AutoFavorite = v end
})

MiscSection:Toggle({
    Title = "Enable Auto Unlock",
    Desc = "Unlock items NOT matching filters",
    Default = Config.AutoUnfavorite,
    Callback = function(v) Config.AutoUnfavorite = v end
})

-- 1. Dropdown Rarity (Multi Select)
MiscSection:Dropdown({
    Title = "Select Rarities to Keep",
    Desc = "Specific Rarity Only",
    Multi = true,
    Values = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" },
    Default = {}, -- Kosongkan default biar user pilih sendiri
    Callback = function(values)
        Config.WhitelistRarities = {} -- Reset
        for _, rName in ipairs(values) do
            if RarityMap[rName] then
                Config.WhitelistRarities[RarityMap[rName]] = true
            end
        end
    end
})

-- 2. Dropdown Nama Ikan (Multi Select + Search)
local FishDropdown = MiscSection:Dropdown({
    Title = "Select Specific Fish",
    Desc = "Search & Select (Overrides Rarity)",
    Multi = true,
    SearchBarEnabled = true,
    Values = GlobalFishNames, 
    Callback = function(values)
        Config.WhitelistNames = {} 
        for _, name in ipairs(values) do
            Config.WhitelistNames[name] = true 
        end
    end
})

-- 3. Dropdown Variant (Multi Select)
MiscSection:Dropdown({
    Title = "Select Variants",
    Desc = "Keep special mutations (e.g. Shiny)",
    Multi = true,
    Values = GlobalVariants,
    Callback = function(values)
        Config.WhitelistVariants = {}
        for _, vName in ipairs(values) do
            Config.WhitelistVariants[vName] = true
        end
    end
})

MiscSection:Div({ Content = "Tools" })

-- Tombol Refresh List
MiscSection:Button({
    Title = "🔄 Refresh Fish List",
    Desc = "Click if dropdown is empty",
    Callback = function()
        DatabaseIndexed = false
        IndexItemDatabase()
        FishDropdown:Refresh(GlobalFishNames)
        WindUI:Notify({ Title = "System", Content = "Fish list refreshed!", Duration = 1 })
    end
})

-- Tombol Force Unfavorite
MiscSection:Button({
    Title = "⚠️ Force Unlock All Trash",
    Desc = "Unlock EVERYTHING not in whitelist immediately",
    Callback = function()
        -- Kita paksa nyalakan AutoUnfavorite sebentar, jalankan loop, lalu kembalikan
        local oldState = Config.AutoUnfavorite
        Config.AutoUnfavorite = true
        Config.AutoFavorite = false -- Matikan lock dulu biar fokus unlock
        
        RunAutoFavorite() -- Jalankan sekali
        RunAutoFavorite() -- Jalankan lagi jaga-jaga
        
        -- Kembalikan settingan
        Config.AutoUnfavorite = oldState
        Config.AutoFavorite = true
        WindUI:Notify({ Title = "System", Content = "Force Unlock Cycle Done.", Duration = 2 })
    end
})

-- (Tombol GPU Saver biarkan di bawah sini)
MiscSection:Toggle({
    Title = "🖥️ GPU Saver (Black Screen)",
    Default = Config.GPUSaver,
    Callback = function(value)
        Config.GPUSaver = value
        ToggleGPU(value)
    end
})

Window:SetToggleKey(Enum.KeyCode.RightControl)

-- Notification
WindUI:Notify({
    Title = "Success",
    Content = "Catraz Hub Loaded Successfully!",
    Duration = 5,
    Icon = "check"
})
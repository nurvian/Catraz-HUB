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
    FavoriteRarity = "Mythic"
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
            buyMerchant = net:WaitForChild("RF/PurchaseMarketItem")
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
--                  AUTO FAVORITE CONFIG & LOGIC (REPLION VERSION)
-- ====================================================================

-- Mapping Rarity ke Angka
local RarityMap = {
    ["Common"] = 1, ["Uncommon"] = 2, ["Rare"] = 3, ["Epic"] = 4, 
    ["Legendary"] = 5, ["Mythic"] = 6, ["Secret"] = 7
}

Config.FavInterval = 3
Config.MinRarityNum = 6 -- Default Mythic

-- Cache Variables
local ItemDatabaseCache = {} 
local ReplionData = nil

-- 1. FUNGSI MENCARI DATABASE ITEM (Untuk Cek Tier/Rarity)
local function GetItemTier(itemId)
    if ItemDatabaseCache[itemId] then return ItemDatabaseCache[itemId] end

    -- Path Database Item (Berdasarkan hasil analisa sebelumnya)
    -- Biasanya ada di ReplicatedStorage.Database.Items atau Shared.ItemUtility
    local potentialPaths = {
        Services.ReplicatedStorage:FindFirstChild("Database") and Services.ReplicatedStorage.Database:FindFirstChild("Items"),
        Services.ReplicatedStorage:FindFirstChild("Shared") and Services.ReplicatedStorage.Shared:FindFirstChild("ItemData"),
    }

    local targetFolder = nil
    for _, folder in pairs(potentialPaths) do
        if folder then targetFolder = folder break end
    end

    if targetFolder then
        -- Cek apakah ada module dengan nama ID tersebut
        local module = targetFolder:FindFirstChild(tostring(itemId))
        if module then
            local success, data = pcall(require, module)
            if success and data and data.Data then
                ItemDatabaseCache[itemId] = data.Data.Tier or 0
                return data.Data.Tier or 0
            end
        end
    end
    
    return 0
end

-- 2. FUNGSI AKSES REPLION (Cara Paling Akurat Ambil Inventory)
local function GetReplionInventory()
    -- Jika kita sudah punya objek Replion Data, langsung return isinya
    if ReplionData then
        -- Replion biasanya nyimpen data di tabel internal, kita coba akses aman
        -- Berdasarkan script Backpack tadi, dia pakai method :GetExpect("Key")
        local success, inv = pcall(function() 
            return ReplionData:GetExpect("Inventory") 
        end)
        if success and inv then return inv end
    end

    -- Jika belum ada, kita coba ambil
    local success, ReplionModule = pcall(function()
        return require(Services.ReplicatedStorage.Packages.Replion)
    end)

    if success and ReplionModule then
        -- Kita coba tunggu Replion "Data" muncul (seperti di script Backpack baris 333)
        local successWait, data = pcall(function()
            return ReplionModule.Client:GetReplion("Data") -- Pakai GetReplion biar ga yield lama
        end)
        
        if successWait and data then
            ReplionData = data
            return ReplionData:GetExpect("Inventory")
        end
    end

    return {}
end

-- 3. LOGIKA UTAMA AUTO FAVORITE
local function RunAutoFavorite()
    local inventory = GetReplionInventory()
    local favCount = 0

    if not inventory or next(inventory) == nil then
        -- Inventory kosong atau gagal diambil
        return
    end

    for _, itemData in pairs(inventory) do
        -- Validasi Item
        if itemData.Id and itemData.UUID then
            -- Cek apakah item sudah dilock/favorit
            local isLocked = itemData.Favorited or itemData.Locked or false

            if not isLocked then
                -- Cek Tier Item
                local tier = GetItemTier(itemData.Id)
                
                -- Jika Tier Ikan >= Tier Pilihan User
                if tier >= Config.MinRarityNum then
                    pcall(function()
                        -- Fire Remote Favorite
                        -- Argumen biasanya UUID string
                        local args = { itemData.UUID }
                        Events.favorite:FireServer(unpack(args))
                    end)
                    
                    favCount = favCount + 1
                    task.wait(0.05) -- Delay aman
                end
            end
        end
    end

    if favCount > 0 then
        WindUI:Notify({ Title = "Auto Favorite", Content = "Locked " .. favCount .. " items!", Duration = 3 })
    end
end

-- Loop Otomatis
task.spawn(function()
    while true do
        task.wait(Config.FavInterval)
        if Config.AutoFavorite then
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
local MiscSection = MiscTab:Section({ Title = "Miscellaneous", Icon = "settings", Opened = true })

-- 1. Toggle Auto Favorite
MiscSection:Toggle({
    Title = "⭐ Auto Favorite",
    Desc = "Automatically lock items based on rarity",
    Callback = function(value)
        Config.AutoFavorite = value
    end
})

-- 2. Dropdown Rarity (WindUI Standard)
MiscSection:Dropdown({
    Title = "Select Minimum Rarity",
    Multi = false,        -- Hanya boleh pilih 1
    AllowNone = true,      -- Tidak boleh kosong
    Values = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" },   -- List nama-nama rarity
    Callback = function(value)
        Config.FavoriteRarity = value
        
        -- Update angka Tier untuk logic (PENTING!)
        -- Pastikan variable RarityMap sudah ada di bagian Logic script kamu
        if RarityMap and RarityMap[value] then
            Config.MinRarityNum = RarityMap[value]
        end
    end
})

-- 3. Tombol Manual (Opsional, sangat berguna)
MiscSection:Button({
    Title = "Force Favorite Now",
    Desc = "Click to scan inventory immediately",
    Callback = function()
        -- Memanggil fungsi logika (pastikan fungsi ini ada di scriptmu)
        if RunAutoFavorite then
            RunAutoFavorite()
        end
    end
})

-- 4. GPU Saver
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
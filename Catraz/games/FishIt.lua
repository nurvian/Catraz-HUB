local SugarLibrary = loadstring(game:HttpGetAsync(
    'https://raw.githubusercontent.com/Yomkav2/Sugar-UI/refs/heads/main/Source'
))();
local Notification = SugarLibrary.Notification();

Notification.new({
    Title = "Fish It game detected",
    Description = "Loading Fish It script",
    Duration = 5,
    Icon = "bell-ring"
})

-- ====== CORE SERVICES & DEPENDENCIES ======
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local isFishing = false
local fishingActive = false -- Status utama AutoFish

-- Memuat Modul eksternal untuk Auto Favorite/Sell
local ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
local Replion = require(ReplicatedStorage.Packages.Replion)
local PlayerData = Replion.Client:WaitReplion("Data")

-- ====== CONFIGURATION (Diambil dari V4.0) ======
local CONFIG_FOLDER = "OptimizedAutoFish"
local CONFIG_FILE = CONFIG_FOLDER .. "/config_" .. LocalPlayer.UserId .. ".json"

local DefaultConfig = {
    AutoFish = false,
    AutoSell = false,
    AutoCatch = false,
    GPUSaver = false,
    BlatantMode = false,
    FishDelay = 0.6, -- Diubah ke rekomendasi optimal
    CatchDelay = 0.2, -- Pertahankan 0.2 (jadi 0.1 di Blatant)
    SellDelay = 30,
    TeleportLocation = "Sisyphus Statue",
    AutoFavorite = true,
    FavoriteRarity = "Mythic"
}

local Config = {}
for k, v in pairs(DefaultConfig) do Config[k] = v end

-- Load Config V4.0 (Tetap dibutuhkan untuk menyimpan nilai delay)
local function ensureFolder()
    if not isfolder or not makefolder then return false end
    if not isfolder(CONFIG_FOLDER) then
        pcall(function() makefolder(CONFIG_FOLDER) end)
    end
    return isfolder(CONFIG_FOLDER)
end

local function saveConfig()
    if not writefile or not ensureFolder() then return end
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
        -- print("[Config] Settings saved!")
    end)
end

local function loadConfig()
    if not readfile or not isfile or not isfile(CONFIG_FILE) then return end
    pcall(function()
        local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
        for k, v in pairs(data) do
            if DefaultConfig[k] ~= nil then Config[k] = v end
        end
        -- print("[Config] Settings loaded!")
    end)
end

loadConfig()


-- ====== NETWORK EVENTS (Diambil dari V4.0) ======
local function getNetworkEvents()
    local net = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
    return {
        fishing = net:WaitForChild("RE/FishingCompleted"),
        sell = net:WaitForChild("RF/SellAllItems"),
        charge = net:WaitForChild("RF/ChargeFishingRod"),
        minigame = net:WaitForChild("RF/RequestFishingMinigameStarted"),
        cancel = net:WaitForChild("RF/CancelFishingInputs"),
        equip = net:WaitForChild("RE/EquipToolFromHotbar"),
        unequip = net:WaitForChild("RE/UnequipToolFromHotbar"),
        favorite = net:WaitForChild("RE/FavoriteItem")
    }
end

local Events = getNetworkEvents()

-- ====== ANTI-AFK (Diambil dari V4.0) ======
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ====== Rarity Tiers (Diambil dari V4.0) ======
local RarityTiers = {
    Common = 1, Uncommon = 2, Rare = 3, Epic = 4,
    Legendary = 5, Mythic = 6, Secret = 7
}
local function getRarityValue(rarity) return RarityTiers[rarity] or 0 end
local function getFishRarity(itemData)
    if not itemData or not itemData.Data then return "Common" end
    return itemData.Data.Rarity or "Common"
end

-- ====================================================================
--                      FISHING LOGIC (FROM V4.0)
-- ====================================================================

-- Helper functions
local function castRod()
    pcall(function()
        Events.equip:FireServer(1)
        task.wait(0.05)
        -- Nilai Charge yang sangat tinggi untuk lemparan jauh/sempurna
        Events.charge:InvokeServer(1755848498.4834) 
        task.wait(0.02)
        -- Meminta Minigame (Auto Catch mengabaikannya)
        Events.minigame:InvokeServer(1.2854545116425, 1) 
        -- print("[Fishing] 🎣 Cast")
    end)
end

local function reelIn()
    pcall(function()
        Events.fishing:FireServer()
        -- print("[Fishing] ✅ Reel")
    end)
end

local function blatantFishingLoop()
    while fishingActive and Config.BlatantMode do
        if not isFishing then
            isFishing = true
            
            pcall(function()
                Events.equip:FireServer(1)
                task.wait(0.01)
                
                -- Cast 1
                task.spawn(function()
                    Events.charge:InvokeServer(1755848498.4834)
                    task.wait(0.01)
                    Events.minigame:InvokeServer(1.2854545116425, 1)
                end)
                
                task.wait(0.05)
                
                -- Cast 2 (overlapping)
                task.spawn(function()
                    Events.charge:InvokeServer(1755848498.4834)
                    task.wait(0.01)
                    Events.minigame:InvokeServer(1.2854545116425, 1)
                end)
            end)
            
            task.wait(Config.FishDelay)
            
            -- Spam reel 5x to instant catch
            for i = 1, 5 do
                pcall(function() Events.fishing:FireServer() end)
                task.wait(0.01)
            end
            
            -- Short cooldown
            task.wait(Config.CatchDelay * 0.5)
            
            isFishing = false
            print("[Blatant] ⚡ Fast cycle complete. FishDelay: " .. Config.FishDelay)
        else
            task.wait(0.01)
        end
    end
end

local function normalFishingLoop()
    while fishingActive and not Config.BlatantMode do
        if not isFishing then
            isFishing = true
            
            castRod()
            task.wait(Config.FishDelay)
            reelIn()
            task.wait(Config.CatchDelay)
            
            isFishing = false
        else
            task.wait(0.1)
        end
    end
end

-- Main fishing controller
local function fishingLoop()
    while fishingActive do
        if Config.BlatantMode then
            blatantFishingLoop()
        else
            normalFishingLoop()
        end
        task.wait(0.1)
    end
end

local function startFishing()
    if fishingActive then return end
    fishingActive = true
    task.spawn(fishingLoop)
    print("[Auto Fish] 🟢 Started " .. (Config.BlatantMode and "(BLATANT MODE)" or "(Normal)"))
end

local function stopFishing()
    fishingActive = false
    isFishing = false
    pcall(function() Events.unequip:FireServer() end)
    print("[Auto Fish] 🔴 Stopped")
end

-- AUTO CATCH (Spam System)
task.spawn(function()
    while true do
        if Config.AutoCatch and not isFishing then
            pcall(function() Events.fishing:FireServer() end)
        end
        task.wait(Config.CatchDelay)
    end
end)

-- ====================================================================
--                      AUTO FAVORITE LOGIC (FROM V4.0)
-- ====================================================================
local favoritedItems = {}

local function isItemFavorited(uuid)
    local items = PlayerData:GetExpect("Inventory").Items
    for _, item in ipairs(items) do
        if item.UUID == uuid then
            return item.Favorited == true
        end
    end
    return false
end

local function autoFavoriteByRarity()
    if not Config.AutoFavorite then return end
    
    local targetRarity = Config.FavoriteRarity
    local targetValue = getRarityValue(targetRarity)
    
    -- Memastikan minimal Mythic
    if targetValue < 6 then targetValue = 6 end 
    
    local favorited = 0
    
    pcall(function()
        local items = PlayerData:GetExpect("Inventory").Items
        if not items or #items == 0 then return end
        
        for _, item in ipairs(items) do
            local data = ItemUtility:GetItemData(item.Id)
            if data and data.Data then
                local rarity = getFishRarity(data)
                local rarityValue = getRarityValue(rarity)
                
                if rarityValue >= targetValue and rarityValue >= 6 then
                    if not isItemFavorited(item.UUID) and not favoritedItems[item.UUID] then
                        Events.favorite:FireServer(item.UUID)
                        favoritedItems[item.UUID] = true
                        favorited = favorited + 1
                        task.wait(0.3)
                    end
                end
            end
        end
    end)
    
    if favorited > 0 then
        print("[Auto Favorite] ✅ Favorited: " .. favorited .. " items.")
    end
end

task.spawn(function()
    while true do
        task.wait(10)
        if Config.AutoFavorite then
            autoFavoriteByRarity()
        end
    end
end)


-- ====================================================================
--                      AUTO SELL LOGIC (FROM V4.0)
-- ====================================================================
local function simpleSell()
    print("[Auto Sell] 💰 Selling all non-favorited items...")
    
    local sellSuccess = pcall(function()
        return Events.sell:InvokeServer()
    end)
    
    if sellSuccess then
        print("[Auto Sell] ✅ SOLD! (Favorited fish kept safe)")
    else
        warn("[Auto Sell] ❌ Sell failed")
    end
end

task.spawn(function()
    while true do
        task.wait(Config.SellDelay)
        if Config.AutoSell then
            simpleSell()
        end
    end
end)

-- ====================================================================
--                    MAIN WINDOW (Original Code)
-- ====================================================================

local Windows = SugarLibrary.new({
    Title = "Catraz Hub",
    Description = "by alcatraz",
    Keybind = Enum.KeyCode.LeftControl,
    Logo = "http://www.roblox.com/asset/?id=79862153675550",
    ConfigFolder = "catrazhub"
})

--========================================================--
--                        TABS (Original Code)
--========================================================--

local MainFrame = Windows:NewTab({
    Title = "Main",
    Description = "Main Features",
    Icon = "house"
})

local ShopTab = Windows:NewTab({ Title = "Shop", Description = "Shop Features", Icon = "store" })
local PlayerTab = Windows:NewTab({ Title = "Players", Description = "Player Tools", Icon = "users" })
local TeleportTab = Windows:NewTab({ Title = "Teleport", Description = "Teleport Tools", Icon = "navigation" })
local EventTab = Windows:NewTab({ Title = "Event", Description = "Event Features", Icon = "star" })
local QuestTab = Windows:NewTab({ Title = "Quest", Description = "Quest Tools", Icon = "flag" })
local MiscTab = Windows:NewTab({ Title = "Misc", Description = "Miscellaneous", Icon = "settings" })
local ConfigTab = Windows:NewTab({ Title = "Configs", Description = "Config Management", Icon = "save" })

--========================================================--
--                        SECTIONS (Original Code)
--========================================================--

local Section = MainFrame:NewSection({ Title = "Main Functions", Icon = "list", Position = "Left" })
local InfoSection = MainFrame:NewSection({ Title = "Information", Icon = "info", Position = "Right" })
local AutoFishingSection = MainFrame:NewSection({ Title = "Auto Fishing", Icon = "fish", Position = "Left" })
local AutoSellSection = MainFrame:NewSection({ Title = "Auto Sell", Icon = "shopping-bag", Position = "Left" })
local ConfigSection = ConfigTab:NewSection({ Title = "Config Tools", Icon = "file-cog", Position = "Left" })
local TeleportSection = TeleportTab:NewSection({ Title = "Teleport", Icon = "map-pin", Position = "Left" })


--========================================================--
--                     AUTO FISHING SECTION (INTEGRASI V4.0)
--========================================================--

AutoFishingSection:NewToggle({
    Title = "🤖 Auto Fish",
    Name = "AutoFishToggle",
    Default = Config.AutoFish,
    Callback = function(value)
        Config.AutoFish = value
        if value then
            startFishing()
        else
            stopFishing()
        end
        saveConfig()
    end
})

AutoFishingSection:NewToggle({
    Title = "⚡ BLATANT MODE (Fastest Catch)",
    Name = "BlatantModeToggle",
    Default = Config.BlatantMode,
    Callback = function(value)
        Config.BlatantMode = value
        print("[Blatant Mode] " .. (value and "⚡ ENABLED" or "🔴 Disabled"))
        -- Jika AutoFish aktif, restart loop agar mode baru terdeteksi
        if fishingActive then
            stopFishing()
            startFishing()
        end
        saveConfig()
    end
})

AutoFishingSection:NewToggle({
    Title = "🎯 Auto Catch (Spam Reel)",
    Name = "AutoCatchToggle",
    Default = Config.AutoCatch,
    Callback = function(value)
        Config.AutoCatch = value
        print("[Auto Catch] " .. (value and "🟢 Enabled" or "🔴 Disabled"))
        saveConfig()
    end
})

-- GANTI: Fish Delay dari Slider menjadi Textbox
AutoFishingSection:NewTextbox({
    Title = "🐟 Fish Delay (s) (Input)",
    Name = "FishDelayTextbox",
    Default = tostring(Config.FishDelay), -- Ubah angka menjadi string untuk Textbox
    FileType = "number", -- Minta input angka saja
    Callback = function(inputString)
        local value = tonumber(inputString)
 
        if value and value >= 0.1 and value <= 10 then -- Validasi nilai (Min 0.1, Max 10)
            Config.FishDelay = value
            print("[Config] ✅ Fish delay set to " .. value .. "s")
        else
            print("[Config] ⚠️ Input Fish Delay tidak valid. Menggunakan nilai lama: " .. Config.FishDelay .. "s")
-- Opsional: Atur ulang Textbox ke nilai Config.FishDelay jika input tidak valid
        end
        saveConfig()
    end
})

-- GANTI: Catch Delay dari Slider menjadi Textbox
AutoFishingSection:NewTextbox({
    Title = "🎣 Catch Delay (s) (Input)",
    Name = "CatchDelayTextbox",
    Default = tostring(Config.CatchDelay), -- Ubah angka menjadi string untuk Textbox
    FileType = "number", -- Minta input angka saja
    Callback = function(inputString)
        local value = tonumber(inputString)

        if value and value >= 0.1 and value <= 10 then -- Validasi nilai (Min 0.1, Max 10)
            Config.CatchDelay = value
            print("[Config] ✅ Catch delay set to " .. value .. "s")
        else
            print("[Config] ⚠️ Input Catch Delay tidak valid. Menggunakan nilai lama: " .. Config.CatchDelay .. "s")
-- Opsional: Atur ulang Textbox ke nilai Config.CatchDelay jika input tidak valid
        end
        saveConfig()
    end
})

--========================================================--
--               AUTO SELL SECTION (INTEGRASI V4.0)
--========================================================--

AutoSellSection:NewToggle({
    Title = "💰 Auto Sell Items",
    Name = "AutoSellToggle",
    Default = Config.AutoSell,
    Callback = function(value)
        Config.AutoSell = value
        print("[Auto Sell] " .. (value and "🟢 Enabled" or "🔴 Disabled"))
        saveConfig()
    end
})

AutoSellSection:NewSlider({
    Title = "Sell Delay (s)",
    Name = "SellDelaySlider",
    Default = Config.SellDelay,
    Min = 10, Max = 300, Step = 1,
    Callback = function(value)
        Config.SellDelay = value
        print("[Config] ✅ Sell delay set to " .. value .. "s")
        saveConfig()
    end
})

AutoSellSection:NewButton({
    Title = "💰 Sell All Now",
    Callback = function()
        simpleSell()
    end
})

AutoSellSection:NewToggle({
    Title = "⭐ Auto Favorite Mythic+",
    Name = "AutoFavoriteToggle",
    Default = Config.AutoFavorite,
    Callback = function(value)
        Config.AutoFavorite = value
        print("[Auto Favorite] " .. (value and "🟢 Enabled" or "🔴 Disabled"))
        saveConfig()
    end
})

AutoSellSection:NewDropdown({
    Title = "Min Rarity to Favorite",
    Name = "FavoriteRarityDropdown",
    Data = {"Mythic", "Secret"},
    Default = Config.FavoriteRarity,
    Callback = function(option)
        Config.FavoriteRarity = option
        print("[Config] Favorite rarity set to: " .. option .. "+")
        saveConfig()
    end
})

AutoSellSection:NewButton({
    Title = "⭐ Favorite Now",
    Callback = function()
        autoFavoriteByRarity()
    end
})


--========================================================--
--                    TELEPORT FEATURES (Original Code)
--========================================================--

-- Definisikan Lokasi (Mengambil CFrame dari V4.0 yang lebih akurat, tetapi menggunakan format Vector3)
-- Catatan: Teleport V4.0 menggunakan CFrame, Teleport Sugar UI Anda menggunakan Vector3. Kita gunakan CFrame dari V4.0 dan konversi.
local V4_LOCATIONS = {
    -- Format: "Nama Tempat" = CFrame.new(X, Y, Z)
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

-- Ambil nama-nama tempat untuk menu dropdown
local DropdownData = {}
for name, _ in pairs(V4_LOCATIONS) do
    table.insert(DropdownData, name)
end

-- Fungsi untuk Melakukan Teleport (Ditingkatkan dengan CFrame V4.0)
local function TeleportToLocation(locationName)
    local destinationCFrame = V4_LOCATIONS[locationName]
    
    if destinationCFrame then
        local HRP = Character:FindFirstChild("HumanoidRootPart")
        if HRP then
            HRP.CFrame = destinationCFrame
            print("Berhasil Teleport ke: " .. locationName)
        else
            print("Error: HumanoidRootPart tidak ditemukan.")
        end
    else
        print("Error: Lokasi " .. locationName .. " tidak ditemukan dalam list.")
    end
end

TeleportSection:NewDropdown({
    Title = "Teleport Destinations",
    Name = "Teleport",
    Data = DropdownData,
    Default = DropdownData[1], 
    Callback = function(selectedName)
        print("Memilih lokasi: " .. selectedName)
        TeleportToLocation(selectedName)
    end,
})

--========================================================--
--                    GPU SAVER (INTEGRASI V4.0)
--========================================================--

local gpuActive = false
local whiteScreen = nil

local function enableGPU()
    if gpuActive then return end
    gpuActive = true
    
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        game.Lighting.GlobalShadows = false
        game.Lighting.FogEnd = 1
        setfpscap(8)
    end)
    
    whiteScreen = Instance.new("ScreenGui")
    whiteScreen.ResetOnSpawn = false
    whiteScreen.DisplayOrder = 999999
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    frame.Parent = whiteScreen
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 400, 0, 100)
    label.Position = UDim2.new(0.5, -200, 0.5, -50)
    label.BackgroundTransparency = 1
    label.Text = "🟢 GPU SAVER ACTIVE\n\nAuto Fish Running..."
    label.TextColor3 = Color3.new(0, 1, 0)
    label.TextSize = 28
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Parent = frame
    
    whiteScreen.Parent = game.CoreGui
    print("[GPU] GPU Saver enabled")
end

local function disableGPU()
    if not gpuActive then return end
    gpuActive = false
    
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        game.Lighting.GlobalShadows = true
        game.Lighting.FogEnd = 100000
        setfpscap(0)
    end)
    
    if whiteScreen then
        whiteScreen:Destroy()
        whiteScreen = nil
    end
    print("[GPU] GPU Saver disabled")
end

local GpuSection = MiscTab:NewSection({
    Title = "Performance",
    Icon = "computer-speaker",
    Position = "Left"
})

GpuSection:NewToggle({
    Title = "🖥️ GPU Saver Mode",
    Name = "GPUSaverToggle",
    Default = Config.GPUSaver,
    Callback = function(value)
        Config.GPUSaver = value
        if value then
            enableGPU()
        else
            disableGPU()
        end
        saveConfig()
    end
})

--========================================================--
--                    CONFIG MANAGEMENT (Original Code)
--========================================================--

local configNames = Windows.ListConfigs()

local configDropdown = ConfigSection:NewDropdown({
    Title = "Configs",
    Data = configNames,
    Default = configNames[1] or "None",
    Callback = function(selected)
        print("Selected config:", selected)
    end,
})

local configNameTextbox = ConfigSection:NewTextbox({
    Title = "Config Name",
    Default = "",
    FileType = "",
    Callback = function(name)
        print("Entered:", name)
    end,
})

ConfigSection:NewButton({
    Title = "Create Config",
    Callback = function()
        local name = configNameTextbox.Get()
        if name ~= "" then
            Windows.SaveConfig(name)
            configDropdown.Refresh(Windows.ListConfigs())
            print("Created config:", name)
        end
    end,
})

ConfigSection:NewButton({
    Title = "Load Config",
    Callback = function()
        local selected = configDropdown.Get()
        if selected then
            Windows.LoadConfig(selected)
            print("Loaded config:", selected)
        end
    end,
})

ConfigSection:NewButton({
    Title = "Delete Config",
    Callback = function()
        local selected = configDropdown.Get()
        if selected then
            delfile(Windows.ConfigFolder .. "/" .. selected .. ".json")
            configDropdown.Refresh(Windows.ListConfigs())
            print("Deleted config:", selected)
        end
    end,
})

ConfigSection:NewButton({
    Title = "Refresh Configs",
    Callback = function()
        configDropdown.Refresh(Windows.ListConfigs())
        print("Configs refreshed")
    end,
})

--========================================================--
--                    UI CONTROL (Original Code)
--========================================================--

local UIControl = MiscTab:NewSection({
    Title = "UI Control",
    Icon = "monitor",
    Position = "Left"
})

UIControl:NewButton({
    Title = "Minimize UI",
    Callback = function()
        local success, err = pcall(function()
            Windows:Toggle() 
        end)
        if success then
            print("Action: Minimize/Toggle UI berhasil.")
        else
            print("ERROR MINIMIZE UI:", err)
        end
    end,
})

UIControl:NewButton({
    Title = "Close UI (Destroy)",
    Callback = function()
        local success, err = pcall(function()
            Windows:Destroy() 
        end)
        if success then
            print("Action: Destroy UI berhasil.")
        else
            print("ERROR DESTROY UI:", err)
        end
    end,
})
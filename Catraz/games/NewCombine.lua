--[[
    CATRAZ HUB | FISH IT - INTEGRATED VERSION (V2)
    UI Library: WindUI
    Logic: Auto Fish V4.0 + ZiaanHub Smart Logic
]]

-- ====================================================================
--                  1. CORE SERVICES & VARIABLES
-- ====================================================================
local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    VirtualUser = game:GetService("VirtualUser"),
    RunService = game:GetService("RunService"),
    HttpService = game:GetService("HttpService"),
    Lighting = game:GetService("Lighting")
}

local LocalPlayer = Services.Players.LocalPlayer
local Events = nil

local Config = {
    AutoFish = false,
    BlatantMode = false,
    FishingMode = "Smart V2", -- Default ke mode baru yang lebih pintar
    AutoCatch = false,
    AutoSell = false,
    GPUSaver = false,
    AutoFavorite = true,
    FishDelay = 0.9,
    CatchDelay = 0.2,
    SellDelay = 30,
    FavoriteRarity = "Mythic",
    PerfectCast = true -- [NEW]
}

-- [NEW] Data Delay Rod dari ZiaanHub
local RodDelaysV2 = {
    ["Ares Rod"] = {custom = 1.12, bypass = 1.45},
    ["Angler Rod"] = {custom = 1.12, bypass = 1.45},
    ["Ghostfinn Rod"] = {custom = 1.12, bypass = 1.45},
    ["Astral Rod"] = {custom = 1.9, bypass = 1.45},
    ["Chrome Rod"] = {custom = 2.3, bypass = 2},
    ["Steampunk Rod"] = {custom = 2.5, bypass = 2.3},
    ["Lucky Rod"] = {custom = 3.5, bypass = 3.6},
    ["Midnight Rod"] = {custom = 3.3, bypass = 3.4},
    ["Demascus Rod"] = {custom = 3.9, bypass = 3.8},
    ["Grass Rod"] = {custom = 3.8, bypass = 3.9},
    ["Luck Rod"] = {custom = 4.2, bypass = 4.1},
    ["Carbon Rod"] = {custom = 4, bypass = 3.8},
    ["Lava Rod"] = {custom = 4.2, bypass = 4.1},
    ["Starter Rod"] = {custom = 4.3, bypass = 4.2},
}

-- ====================================================================
--                  2. NETWORK & LOGIC FUNCTIONS
-- ====================================================================

-- Get Events Safely
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
            
            -- SHOP EVENTS
            buyBait = net:WaitForChild("RF/PurchaseBait"),
            buyRod = net:WaitForChild("RF/PurchaseFishingRod"),
            buyMerchant = net:WaitForChild("RF/PurchaseMarketItem"),
            
            -- [NEW] Enchant Events
            activateEnchant = net:WaitForChild("RE/ActivateEnchantingAltar")
        }
        print("✅ Events Loaded Successfully!")
    else
        warn("❌ Critical Error: Net Package not found in ReplicatedStorage!")
    end
end
SetupEvents()

-- [FIXED V3] Setup Animations (Manual ID Injection)
local AnimTracks = {}

local function SetupAnimations()
    task.spawn(function()
        local success, err = pcall(function()
            -- Kita tunggu karakter load dulu
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local humanoid = char:WaitForChild("Humanoid", 10)
            if not humanoid then return end
            
            local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

            -- FUNGSI PEMBUAT ANIMASI MANUAL
            -- Ini bypass folder game. Kita bikin file animasi sendiri via kodingan.
            local function CreateAnim(id)
                local anim = Instance.new("Animation")
                anim.AnimationId = id
                return anim
            end

            -- === MEMASUKKAN ID DARI DATA YANG KAMU KIRIM ===
            
            -- 1. Animasi Shake/Charge (StartRodCharge)
            -- ID dari data: rbxassetid://139622307103608
            local animShake = CreateAnim("rbxassetid://139622307103608")
            
            -- 2. Animasi Idle/Diam (ReelingIdle)
            -- ID dari data: rbxassetid://134965425664034
            local animIdle = CreateAnim("rbxassetid://134965425664034")

            -- Load ke karakter
            AnimTracks.Shake = animator:LoadAnimation(animShake)
            AnimTracks.Idle = animator:LoadAnimation(animIdle)
            
            print("✅ Animations Loaded via Hardcoded IDs (Anti-Error)")
        end)

        if not success then 
            warn("⚠️ Animation Setup Failed:", err) 
        end
    end)
end
SetupAnimations() -- Run once

-- ====================================================================
--                  SHOP LOGIC & CONTENT SCANNER
-- ====================================================================

local ShopData = { Rods = {}, Baits = {}, RodNames = {}, BaitNames = {} }

local function ScanShopItems()
    ShopData.Rods = {}
    ShopData.Baits = {}
    ShopData.RodNames = {}
    ShopData.BaitNames = {}
    
    local descendants = Services.ReplicatedStorage:GetDescendants()
    
    for _, obj in pairs(descendants) do
        if obj:IsA("ModuleScript") and not obj:FindFirstAncestor("Packages") then
            local success, result = pcall(require, obj)
            if success and result and type(result) == "table" and result.Data then
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

-- Merchant Logic (Same as before)
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
                        local displayName = itemData.Data.Name .. " (" .. (marketItem.Price or "???") .. ")"
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
    -- [NEW] Added from ZiaanHub
    ["Stingray Shores"] = Vector3.new(-32, 4, 2773),
    ["Winter Fest"] = Vector3.new(1611, 4, 3280),
    ["Lost Shore"] = Vector3.new(-3663, 38, -989 ),
}

-- [NEW] Helper Function for Smart V2: Get Rod Name
local function getEquippedRodName()
    local display = LocalPlayer.PlayerGui:FindFirstChild("Backpack") and LocalPlayer.PlayerGui.Backpack:FindFirstChild("Display")
    if not display then return "Starter Rod" end
    
    for _, tile in ipairs(display:GetChildren()) do
        if tile:FindFirstChild("Inner") and tile.Inner:FindFirstChild("Tags") and tile.Inner.Tags:FindFirstChild("ItemName") then
            local name = tile.Inner.Tags.ItemName.Text
            if RodDelaysV2[name] then return name end
        end
    end
    return "Starter Rod" -- Default fallback
end

-- Fungsi CastRod
local function CastRod()
    pcall(function()
        Events.equip:FireServer(1)
        task.wait(0.05)
        Events.charge:InvokeServer(1755848498.4834)
        task.wait(0.02)
        
        -- [NEW] Perfect Cast Logic Integration
        local x, y
        if Config.PerfectCast then
             x = -0.7499996423721313 + (math.random(-500, 500) / 10000000)
             y = 1 + (math.random(-500, 500) / 10000000)
        else
             x = 1.2854545116425
             y = 1
        end
        
        Events.minigame:InvokeServer(x, y)
    end)
end

-- [NEW] SMART LOOP V2 (ZiaanHub Logic)
local function SmartLoopV2()
    while fishingActive and Config.FishingMode == "Smart V2" do
        pcall(function()
            if not isFishing then
                isFishing = true
                
                -- 1. Deteksi Rod & Delay
                local rodName = getEquippedRodName()
                local rodData = RodDelaysV2[rodName] or {custom = 4.3, bypass = 4.2} -- Default
                local delayTime = rodData.custom
                
                -- 2. Equip & Charge
                Events.equip:FireServer(1)
                task.wait(0.1)
                Events.charge:InvokeServer(workspace:GetServerTimeNow())
                task.wait(0.5)
                
                -- 3. Animasi & Cast
                if AnimTracks.Shake then AnimTracks.Shake:Play() end
                
                -- Perfect Cast Coordinate
                local x = -0.7499996423721313 + (math.random(-500, 500) / 10000000)
                local y = 1 + (math.random(-500, 500) / 10000000)
                
                if AnimTracks.Idle then AnimTracks.Idle:Play() end
                Events.minigame:InvokeServer(x, y)
                
                -- 4. Smart Wait (Sesuai statistik Rod)
                task.wait(delayTime)
                
                -- 5. Finish
                Events.fishing:FireServer()
                isFishing = false
            end
        end)
        task.wait(0.1)
    end
end

-- 1. Mode Instant
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

-- 2. Mode Legit
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

-- 3. Blatant Loop
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

-- Main Loop Starter
local function ToggleFishing(bool)
    fishingActive = bool
    if bool then
        -- Stop animations if any
        if AnimTracks.Shake then AnimTracks.Shake:Stop() end
        
        task.spawn(function()
            while fishingActive do
                if Config.BlatantMode then
                    BlatantLoop() 
                elseif Config.FishingMode == "Smart V2" then
                    -- [NEW] Jalankan Smart Logic
                    SmartLoopV2()
                elseif Config.FishingMode == "Legit" then
                    LegitLoop()
                else
                    InstantLoop()
                end
                task.wait(0.1)
            end
        end)
        
        -- Auto Catch Helper (Hanya untuk Instant Mode)
        task.spawn(function()
            while fishingActive do
                if Config.AutoCatch and not isFishing and Config.FishingMode == "Instant" then
                    pcall(function() Events.fishing:FireServer() end)
                end
                task.wait(Config.CatchDelay)
            end
        end)
    else
        pcall(function() Events.unequip:FireServer() end)
        if AnimTracks.Shake then AnimTracks.Shake:Stop() end
        if AnimTracks.Idle then AnimTracks.Idle:Stop() end
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
--                  AUTO FAVORITE (REPLION)
-- ====================================================================
local RarityMap = { ["Common"] = 1, ["Uncommon"] = 2, ["Rare"] = 3, ["Epic"] = 4, ["Legendary"] = 5, ["Mythic"] = 6, ["Secret"] = 7 }
Config.FavInterval = 3
Config.MinRarityNum = 6
local ItemDatabaseCache = {} 
local ReplionData = nil

local function GetItemTier(itemId)
    if ItemDatabaseCache[itemId] then return ItemDatabaseCache[itemId] end
    local potentialPaths = {
        Services.ReplicatedStorage:FindFirstChild("Database") and Services.ReplicatedStorage.Database:FindFirstChild("Items"),
        Services.ReplicatedStorage:FindFirstChild("Shared") and Services.ReplicatedStorage.Shared:FindFirstChild("ItemData"),
    }
    local targetFolder = nil
    for _, folder in pairs(potentialPaths) do if folder then targetFolder = folder break end end

    if targetFolder then
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

local function GetReplionInventory()
    if ReplionData then
        local success, inv = pcall(function() return ReplionData:GetExpect("Inventory") end)
        if success and inv then return inv end
    end
    local success, ReplionModule = pcall(function() return require(Services.ReplicatedStorage.Packages.Replion) end)
    if success and ReplionModule then
        local successWait, data = pcall(function() return ReplionModule.Client:GetReplion("Data") end)
        if successWait and data then
            ReplionData = data
            return ReplionData:GetExpect("Inventory")
        end
    end
    return {}
end

local function RunAutoFavorite()
    local inventory = GetReplionInventory()
    local favCount = 0
    if not inventory or next(inventory) == nil then return end

    for _, itemData in pairs(inventory) do
        if itemData.Id and itemData.UUID then
            local isLocked = itemData.Favorited or itemData.Locked or false
            if not isLocked then
                local tier = GetItemTier(itemData.Id)
                if tier >= Config.MinRarityNum then
                    pcall(function() Events.favorite:FireServer(unpack({ itemData.UUID })) end)
                    favCount = favCount + 1
                    task.wait(0.05)
                end
            end
        end
    end
    if favCount > 0 then WindUI:Notify({ Title = "Auto Favorite", Content = "Locked " .. favCount .. " items!", Duration = 3 }) end
end

task.spawn(function()
    while true do
        task.wait(Config.FavInterval)
        if Config.AutoFavorite then RunAutoFavorite() end
    end
end)

-- ====================================================================
--                  UTILITIES & HELPERS
-- ====================================================================

-- [NEW] Auto Enchant Logic
local function AutoEnchantRod()
    local ENCHANT_POS = Vector3.new(3231, -1303, 1402)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local originalCF = char.HumanoidRootPart.CFrame
    
    WindUI:Notify({ Title = "Enchant", Content = "Teleporting to Altar...", Duration = 2 })
    
    char.HumanoidRootPart.CFrame = CFrame.new(ENCHANT_POS + Vector3.new(0,5,0))
    task.wait(1)
    
    -- Harus equip slot 5 (Enchant Stone)
    pcall(function()
        Events.equip:FireServer(5)
        task.wait(0.5)
        Events.activateEnchant:FireServer()
    end)
    
    WindUI:Notify({ Title = "Enchant", Content = "Enchanting... Wait 5s", Duration = 2 })
    task.wait(5)
    char.HumanoidRootPart.CFrame = originalCF
end

-- [NEW] FPS Boost
local function BoostFPS()
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        end
    end
    Services.Lighting.GlobalShadows = false
    Services.Lighting.FogEnd = 1e10
end

local function GetPlayerNames()
    local names = {}
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= LocalPlayer then table.insert(names, player.Name) end
    end
    table.sort(names)
    return names
end

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
        Content = "Integrated Version (V2). Use Smart V2 Mode for best results.",
        Buttons = { { Title = "Let's Fish!", Icon = "bird" } }
    })
end

local Window = WindUI:CreateWindow({
    Title = "Catraz Hub |  Fish It (Integrated V2)",
    Author = "by alcatraz • team",
    Folder = "chub",
    Icon = "snail",
    IconSize = 22*2,
    NewElements = true,
    OpenButton = {
        Title = "Open Catraz Hub", 
        CornerRadius = UDim.new(1,0), 
        StrokeThickness = 3, 
        Enabled = true, 
        Draggable = true,
        Color = ColorSequence.new(Color3.fromHex("#fc03f8"), Color3.fromHex("#db03fc"))
    },
    KeySystem = {
        Title = "Key System",
        Note = "Key System. Key: 1234",
        KeyValidator = function(EnteredKey)
            if EnteredKey == "1234" then createPopup() return true end
            return false
        end
    }
})

-- TABS
local MainTab = Window:Tab({ Title = "Main", Icon = "house" })
local ShopTab = Window:Tab({ Title = "Shop", Icon = "store" })
local TeleportTab = Window:Tab({ Title = "Teleport", Icon = "navigation" })
local MiscTab = Window:Tab({ Title = "Misc", Icon = "settings" })

-- >> MAIN SECTION (AUTO FARM)
local MainSection = MainTab:Section({ Title = "Auto Farm", Icon = "fish-symbol", Opened = true })

MainSection:Toggle({
    Title = "Auto Fish",
    Default = Config.AutoFish,
    Callback = function(value)
        Config.AutoFish = value
        ToggleFishing(value)
    end
})

MainSection:Dropdown({
    Title = "Fishing Mode",
    Multi = false,
    AllowNone = true,
    Values = { "Smart V2", "Instant", "Legit" }, -- [NEW] Added Smart V2
    Default = "Smart V2",
    Callback = function(value)
        Config.FishingMode = value
    end
})

MainSection:Toggle({
    Title = "⚡ Blatant Mode (Override All)",
    Desc = "(3x Faster - Risky)",
    Type = "Checkbox",
    Default = Config.BlatantMode,
    Callback = function(value)
        Config.BlatantMode = value
    end
})

MainSection:Toggle({
    Title = "🎯 Auto Perfect Cast", -- [NEW]
    Desc = "Always hit perfect throw (Smart V2 Only)",
    Default = Config.PerfectCast,
    Callback = function(value)
        Config.PerfectCast = value
    end
})

MainSection:Input({
    Title = "Fish Delay (Wait for bite)",
    Default = tostring(Config.FishDelay),
    Placeholder = "0.9",
    Numeric = true, 
    Finished = true, 
    Callback = function(value)
        local num = tonumber(value)
        if num then Config.FishDelay = num end
    end
})

-- >> SHOP SECTION (Same as before)
local ShopSection = ShopTab:Section({ Title = "Shop Center", Icon = "store", Opened = true })

local selectedRodName = nil
local selectedBaitName = nil

ShopSection:Dropdown({
    Title = "🎣 Select Rod",
    Multi = false, AllowNone = true, Values = ShopData.RodNames, 
    Callback = function(value) selectedRodName = value end
})

ShopSection:Button({
    Title = "Purchase Rod",
    Callback = function()
        if selectedRodName and ShopData.Rods[selectedRodName] then
            local rodID = ShopData.Rods[selectedRodName]
            local success, err = pcall(function() Events.buyRod:InvokeServer(rodID) end)
            if success then WindUI:Notify({ Title = "Shop", Content = "Bought " .. selectedRodName, Duration = 2 })
            else WindUI:Notify({ Title = "Error", Content = "Failed", Duration = 2 }) end
        end
    end
})

ShopSection:Dropdown({
    Title = "🪱 Select Bait",
    Multi = false, AllowNone = true, Values = ShopData.BaitNames, 
    Callback = function(value) selectedBaitName = value end
})

ShopSection:Button({
    Title = "Purchase Bait",
    Callback = function()
        if selectedBaitName and ShopData.Baits[selectedBaitName] then
            local baitID = ShopData.Baits[selectedBaitName]
            local success, err = pcall(function() Events.buyBait:InvokeServer(baitID) end)
            if success then WindUI:Notify({ Title = "Shop", Content = "Bought " .. selectedBaitName, Duration = 2 })
            else WindUI:Notify({ Title = "Error", Content = "Failed", Duration = 2 }) end
        end
    end
})

local MerchantDropdown = nil
local selectedMerchantItemName = nil

ShopSection:Button({
    Title = "Teleport to Merchant",
    Callback = function()
        local merchant = workspace:FindFirstChild("TravelingMerchant") or workspace:FindFirstChild("Merchant")
        if merchant and merchant:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = merchant.HumanoidRootPart.CFrame
        end
    end
})

MerchantDropdown = ShopSection:Dropdown({
    Title = "Merchant Stock (Live)",
    Multi = false, AllowNone = true, Values = RefreshMerchantItems(),
    Callback = function(value) selectedMerchantItemName = value end
})

ShopSection:Button({
    Title = "🔄 Refresh Stock",
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
            local success = pcall(function() return Events.buyMerchant:InvokeServer(marketID) end)
            if success then WindUI:Notify({ Title = "Shop", Content = "Request Sent!", Duration = 2 }) end
        end
    end
})

ShopSection:Toggle({
    Title = "Auto Sell All",
    Default = Config.AutoSell,
    Callback = function(value) Config.AutoSell = value end
})

-- >> TELEPORT SECTION
local TeleportSection = TeleportTab:Section({ Title = "Islands", Icon = "navigation", Opened = true })

local sortedLocs = {}
for name, _ in pairs(LOCATIONS) do table.insert(sortedLocs, name) end
table.sort(sortedLocs)

TeleportSection:Dropdown({
    Title = "Select Destination",
    Multi = false, AllowNone = true, Values = sortedLocs,
    Callback = function(value)
        if value and LOCATIONS[value] then
            local target = LOCATIONS[value]
            local cf = (typeof(target) == "Vector3") and CFrame.new(target) or target
            LocalPlayer.Character.HumanoidRootPart.CFrame = cf
        end
    end
})

-- [NEW] Event Teleport Dropdown
local eventsList = { "Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", "Black Hole", "Shocked", "Ghost Worm", "Meteor Rain" }
TeleportSection:Dropdown({
    Title = "Event Teleport",
    Values = eventsList,
    Callback = function(option)
        local props = workspace:FindFirstChild("Props")
        if props and props:FindFirstChild(option) and props[option]:FindFirstChild("Fishing Boat") then
            local boatCFrame = props[option]["Fishing Boat"]:GetPivot()
            LocalPlayer.Character.HumanoidRootPart.CFrame = boatCFrame + Vector3.new(0, 15, 0)
            WindUI:Notify({ Title = "Event", Content = "Warped to " .. option, Duration = 2 })
        else
            WindUI:Notify({ Title = "Event", Content = option .. " Not Found!", Duration = 2 })
        end
    end
})

local selectedPlayer = nil
local PlayerDropdown = TeleportSection:Dropdown({
    Title = "Select Player", Multi = false, AllowNone = true, Values = GetPlayerNames(),
    Callback = function(value) selectedPlayer = value end
})

TeleportSection:Button({
    Title = "🔄 Refresh Player List",
    Callback = function() if PlayerDropdown then PlayerDropdown:Refresh(GetPlayerNames()) end end
})

TeleportSection:Button({
    Title = "🚀 Teleport to Player",
    Callback = function()
        if not selectedPlayer then return end
        local target = Services.Players:FindFirstChild(selectedPlayer)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
        end
    end
})

-- >> MISC SECTION
local MiscSection = MiscTab:Section({ Title = "Miscellaneous", Icon = "settings", Opened = true })

MiscSection:Button({
    Title = "🪄 Auto Enchant Rod",
    Desc = "Place Enchant Stone in Slot 5 first!",
    Callback = function()
        AutoEnchantRod()
    end
})

MiscSection:Button({
    Title = "🥔 FPS Boost",
    Desc = "Make graphics ugly to save FPS",
    Callback = function()
        BoostFPS()
        WindUI:Notify({ Title = "FPS Boost", Content = "Applied!", Duration = 1 })
    end
})

MiscSection:Toggle({
    Title = "⭐ Auto Favorite",
    Desc = "Automatically lock items based on rarity",
    Callback = function(value) Config.AutoFavorite = value end
})

MiscSection:Dropdown({
    Title = "Select Minimum Rarity",
    Multi = false, AllowNone = true, Values = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" },
    Default = "Mythic",
    Callback = function(value)
        Config.FavoriteRarity = value
        if RarityMap and RarityMap[value] then Config.MinRarityNum = RarityMap[value] end
    end
})

MiscSection:Toggle({
    Title = "🖥️ GPU Saver (Black Screen)",
    Default = Config.GPUSaver,
    Callback = function(value)
        Config.GPUSaver = value
        ToggleGPU(value)
    end
})

Window:SetToggleKey(Enum.KeyCode.RightControl)
WindUI:Notify({ Title = "Success", Content = "Catraz Hub (V2 Integrated) Loaded!", Duration = 5, Icon = "check" })
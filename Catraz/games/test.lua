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
    FishingMode = "Instant"
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

-- Get Events Safely
local function SetupEvents()
    local net = Services.ReplicatedStorage.Packages._Index:FindFirstChild("sleitnick_net@0.2.0")
    if net then
        net = net.net
        Events = {
            fishing = net:WaitForChild("RE/FishingCompleted"),
            sell = net:WaitForChild("RF/SellAllItems"),
            charge = net:WaitForChild("RF/ChargeFishingRod"),
            minigame = net:WaitForChild("RF/RequestFishingMinigameStarted"),
            equip = net:WaitForChild("RE/EquipToolFromHotbar"),
            unequip = net:WaitForChild("RE/UnequipToolFromHotbar"),
            favorite = net:WaitForChild("RE/FavoriteItem")
        }
    end
end
SetupEvents()

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
            local tapDuration = 0.5 
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
                    Events.charge:InvokeServer(1755848498.4834)
                    Events.minigame:InvokeServer(1.2854545116425, 1)
                end)
                task.wait(0.05)
                task.spawn(function()
                    Events.charge:InvokeServer(1755848498.4834)
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

-- Auto Favorite Logic (Simplifed)
local function AutoFav()
    -- Requires accessing ItemUtility, omitted for brevity but logic is same as V4
    -- This placeholder ensures UI works without crashing on dependency
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
    Description = "Abaikan mode diatas, pakai cara kasar (3x Faster)",
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

-- >> SHOP SECTION (SELLING)
local ShopSection = ShopTab:Section({ Title = "Shop Section", Icon = "store", Opened = true })

ShopSection:Toggle({
    Title = "Auto Sell All",
    Default = Config.AutoSell,
    Callback = function(value)
        Config.AutoSell = value
    end
})

ShopSection:Slider({
    Title = "Sell Interval (Seconds)",
    Min = 5, Max = 120, Default = Config.SellDelay, Precise = false,
    Callback = function(value)
        Config.SellDelay = value
    end
})

ShopSection:Button({
    Title = "💰 Sell Everything Now",
    Callback = function()
        pcall(function() Events.sell:InvokeServer() end)
        WindUI:Notify({ Title = "Action", Content = "Sell Request Sent!", Duration = 2 })
    end
})

-- >> TELEPORT SECTION
local TeleportSection = TeleportTab:Section({ Title = "Teleport To Islands", Icon = "navigation", Opened = true })

-- Sorting locations alphabetically
local sortedLocs = {}
for name, _ in pairs(LOCATIONS) do table.insert(sortedLocs, name) end
table.sort(sortedLocs)

for _, name in ipairs(sortedLocs) do
    TeleportSection:Button({
        Title = name,
        Callback = function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = LOCATIONS[name]
                WindUI:Notify({ Title = "Teleport", Content = "Warped to " .. name, Duration = 2 })
            end
        end
    })
end

-- >> MISC SECTION
local MiscSection = MiscTab:Section({ Title = "Miscellaneous", Icon = "settings", Opened = true })

MiscSection:Toggle({
    Title = "🖥️ GPU Saver (Black Screen)",
    Default = Config.GPUSaver,
    Callback = function(value)
        Config.GPUSaver = value
        ToggleGPU(value)
    end
})

MiscSection:Toggle({
    Title = "⭐ Auto Favorite (Mythic+)",
    Default = Config.AutoFavorite,
    Callback = function(value)
        Config.AutoFavorite = value
    end
})

MiscSection:Dropdown({
    Title = "Favorite Rarity",
    Multi = false,
    Required = true,
    Items = {"Mythic", "Secret"},
    Default = Config.FavoriteRarity,
    Callback = function(value)
        Config.FavoriteRarity = value
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
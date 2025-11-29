--[[
    WindUI Base Template
    Cleaned & Structured for Production
]]

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- 1. Membuat Window
local Window = WindUI:CreateWindow({
    Title = "Catraz Hub | FISH IT", -- Ganti judul scriptmu
    Author = "By AlCatraz", -- Ganti nama pembuat
    Folder = "Catraz", -- Folder untuk config save
    Icon = "snail", -- Bisa pakai "sfsymbols:..." atau rbxassetid
    Size = UDim2.fromOffset(580, 460),
    Transparent = true, -- Ganti ke true jika ingin transparan
    Theme = "Dark", -- Tema default
    
    -- Tombol buka/tutup UI (Mobile/PC)

    OpenButton = {
        Title = "Catraz HUB", -- can be changed
        CornerRadius = UDim.new(1,0), -- fully rounded
        StrokeThickness = 3, -- removing outline
        Enabled = true, -- enable or disable openbutton
        Draggable = true,
        OnlyMobile = false,
        
        Color = ColorSequence.new( -- gradient
            Color3.fromHex("#c403ff"), 
            Color3.fromHex("#8302ab")
        )
    },
})

-- 2. Membuat Tab

local MainTab = Window:Tab({
    Title = "Main",
    Icon = "house",
    Locked = false,
})

local ShopTab = Window:Tab({
    Title = "Shop",
    Icon = "store",
    Locked = false,
})

local PlayerTab = Window:Tab({
    Title = "Players",
    Icon = "users",
    Locked = false,
})

local TeleportTab = Window:Tab({
    Title = "Teleport",
    Icon = "navigation",
    Locked = false,
})

local EventTab = Window:Tab({
    Title = "Event",
    Icon = "star",
    Locked = false,
})

local QuestTab = Window:Tab({
    Title = "Quest",
    Icon = "flag",
    Locked = false,
})

local MiscTab = Window:Tab({
    Title = "Misc",
    Icon = "settings",
    Locked = false,
})

local ConfigTab = Window:Tab({
    Title = "Configs",
    Icon = "save",
    Locked = false,
})


-- 3. Membuat Section di dalam Tab

local MainSection = MainTab:Section({
    Title = "Auto Farm",
    Icon = "fish-symbol",
    Opened = true,
})


local ShopSection = ShopTab:Section({
    Title = "Shop Section",
    Icon = "store",
    Opened = true,
})

local PlayerSection = PlayerTab:Section({
    Title = "Player Tools",
    Icon = "users",
    Opened = true,
})

local TeleportSection = TeleportTab:Section({
    Title = "Teleport To Islands",
    Icon = "navigation",
    Opened = true,
})

local EventSection = EventTab:Section({
    Title = "Event Features",
    Icon = "star",
    Opened = true,
})

local QuestSection = QuestTab:Section({
    Title = "Quest Tools",
    Icon = "flag",
    Opened = true,
})

local MiscSection = MiscTab:Section({
    Title = "Miscellaneous",
    Icon = "settings",
    Opened = true,
})

local ConfigSection = ConfigTab:Section({
    Title = "Config Management",
    Icon = "save",
    Opened = true,
})


-- 4. auto fishing script

-- 5. auto selling script

-- 6. teleport script
-------------------------------------------------------
-- 🔥 7. SISTEM TELEPORT V4 (AUTO INTEGRATED)
-------------------------------------------------------

local V4_LOCATIONS = {
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

-- 🔽 Ambil list nama tempat
local DropdownData = {}
for name,_ in pairs(V4_LOCATIONS) do
    table.insert(DropdownData, name)
end

-- 📌 Ambil player dan character
local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

-- 🚀 Fungsi Teleport
local function TeleportToLocation(locationName)
    local destinationCFrame = V4_LOCATIONS[locationName]

    if destinationCFrame then
        local HRP = Character:FindFirstChild("HumanoidRootPart")
        if HRP then
            HRP.CFrame = destinationCFrame
            print("Teleport → " .. locationName)
        else
            print("❌ HumanoidRootPart tidak ditemukan.")
        end
    else
        print("❌ Lokasi tidak ditemukan.")
    end
end

local SelectedLocation = nil

TeleportSection:Dropdown({
    Title = "Pilih Lokasi Teleport",
    Description = "Pilih tujuan teleport",
    Values = DropdownData,
    Multi = false,
    Default = nil,
    Callback = function(v)
        SelectedLocation = v
    end
})

TeleportSection:Button({
    Title = "Teleport!",
    Description = "Klik untuk teleport ke lokasi terpilih",
    Icon = "navigation",
    Callback = function()
        if SelectedLocation then
            TeleportToLocation(SelectedLocation)
        else
            print("❌ Pilih lokasi terlebih dahulu!")
        end
    end
})

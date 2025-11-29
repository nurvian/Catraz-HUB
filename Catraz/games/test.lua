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
    Title = "Teleport Tools",
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
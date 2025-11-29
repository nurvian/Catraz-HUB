--[[
    WindUI Base Template
    Cleaned & Structured for Production
]]

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- 1. Membuat Window
local Window = WindUI:CreateWindow({
    Title = "Nama Script Hub | Game Name", -- Ganti judul scriptmu
    Author = ".ftgs", -- Ganti nama pembuat
    Folder = "MyScriptHub", -- Folder untuk config save
    Icon = "rbxassetid://12345678", -- Bisa pakai "sfsymbols:..." atau rbxassetid
    Size = UDim2.fromOffset(580, 460),
    Transparent = false, -- Ganti ke true jika ingin transparan
    Theme = "Dark", -- Tema default
    
    -- Tombol buka/tutup UI (Mobile/PC)
    OpenButton = {
        Title = "Open UI",
        Icon = "rbxassetid://12345678",
        Enabled = true,
        Key = Enum.KeyCode.RightControl -- Default keybind buka tutup
    }
})

-- 2. Tab Utama (Main Tab)
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "home", -- Icon dari Lucide Icons (bisa cari di google lucide icons)
})

-- Section di dalam Main Tab
local MainSection = MainTab:Section({ 
    Title = "Fitur Utama",
    TextSize = 16 
})

-- [CONTOH ELEMEN]
MainSection:Button({
    Title = "Button Contoh",
    Desc = "Deskripsi tombol ini",
    Callback = function()
        print("Button ditekan!")
        
        -- Contoh Notifikasi
        WindUI:Notify({
            Title = "Informasi",
            Content = "Button berhasil ditekan.",
            Duration = 3,
            Icon = "info"
        })
    end
})

MainSection:Toggle({
    Title = "Auto Farm",
    Desc = "Mengaktifkan fitur farming otomatis",
    Default = false,
    Callback = function(state)
        print("Auto Farm status:", state)
        -- Masukkan logika loop _G.AutoFarm di sini
    end
})

MainSection:Slider({
    Title = "WalkSpeed",
    Default = 16,
    Min = 16,
    Max = 100,
    Callback = function(value)
        pcall(function()
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
        end)
    end
})

MainSection:Dropdown({
    Title = "Pilih Senjata",
    Multi = false,
    Values = {"Sword", "Gun", "Bow"},
    Value = "Sword",
    Callback = function(selected)
        print("Senjata dipilih:", selected)
    end
})


-- 3. Tab Pengaturan (Settings Tab)
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings",
})

local SettingsSection = SettingsTab:Section({ Title = "UI Settings" })

SettingsSection:Button({
    Title = "Unload UI",
    Desc = "Menutup dan menghapus UI",
    Callback = function()
        Window:Destroy()
    end
})

-- Theme Switcher sederhana (Optional)
SettingsSection:Dropdown({
    Title = "Pilih Tema",
    Values = {"Dark", "Light"},
    Value = "Dark",
    Callback = function(theme)
        -- Logika ganti tema jika library mendukung penggantian runtime
        -- WindUI biasanya butuh set di awal, tapi ini placeholder
        print("Tema dipilih:", theme)
    end
})

-- Pemberitahuan script sudah dimuat
WindUI:Notify({
    Title = "Script Loaded",
    Content = "Selamat datang di Script Hub!",
    Duration = 5,
    Icon = "check"
})
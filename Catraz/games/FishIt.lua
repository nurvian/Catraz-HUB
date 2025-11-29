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

--========================================================--
--                    MAIN WINDOW
--========================================================--

local Windows = SugarLibrary.new({
	Title = "Catraz Hub",
	Description = "by alcatraz",
	Keybind = Enum.KeyCode.LeftControl,
	Logo = "http://www.roblox.com/asset/?id=79862153675550",
	ConfigFolder = "catrazhub"
})

--========================================================--
--                        TABS
--========================================================--

local MainFrame = Windows:NewTab({
	Title = "Main",
	Description = "Main Features",
	Icon = "house"
})

local ShopTab = Windows:NewTab({
	Title = "Shop",
	Description = "Shop Features",
	Icon = "store"
})

local PlayerTab = Windows:NewTab({
	Title = "Players",
	Description = "Player Tools",
	Icon = "users"
})

local TeleportTab = Windows:NewTab({
	Title = "Teleport",
	Description = "Teleport Tools",
	Icon = "navigation"
})

local EventTab = Windows:NewTab({
	Title = "Event",
	Description = "Event Features",
	Icon = "star"
})

local QuestTab = Windows:NewTab({
	Title = "Quest",
	Description = "Quest Tools",
	Icon = "flag"
})

local MiscTab = Windows:NewTab({
	Title = "Misc",
	Description = "Miscellaneous",
	Icon = "settings"
})

local ConfigTab = Windows:NewTab({
	Title = "Configs",
	Description = "Config Management",
	Icon = "save"
})

--========================================================--
--                        SECTIONS
--========================================================--

local Section = MainFrame:NewSection({
	Title = "Main Functions",
	Icon = "list",
	Position = "Left"
})

local InfoSection = MainFrame:NewSection({
	Title = "Information",
	Icon = "info",
	Position = "Right"
})

-- *** SECTION BARU ***
local AutoFishingSection = MainFrame:NewSection({
	Title = "Auto Fishing",
	Icon = "fish",
	Position = "Left"
})

local AutoSellSection = MainFrame:NewSection({
	Title = "Auto Sell",
	Icon = "shopping-bag",
	Position = "Left"
})

local ConfigSection = ConfigTab:NewSection({
	Title = "Config Tools",
	Icon = "file-cog",
	Position = "Left"
})

--========================================================--
--                     MAIN FEATURES
--========================================================--

Section:NewToggle({
	Title = "Toggle",
	Name = "Toggle1",
	Default = false,
	Callback = function(v)
		print("Toggle1:", v)
	end,
})

-- Definisikan layanan yang diperlukan
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- ## 1. Definisikan Data Lokasi (Nama dan Koordinat)
local TeleportLocations = {
    -- Format: "Nama Tempat" = Vector3.new(X, Y, Z)
    ["Fisherman Island"] = Vector3.new(35, 17, 2851),
    ["Mining Area 1"] = Vector3.new(500, 50, 800),
    ["Safe Zone"] = Vector3.new(-200, 15, -100),
    ["Testing Spot"] = Vector3.new(0, 50, 0),
}

-- Ambil nama-nama tempat untuk menu dropdown
local DropdownData = {}
for name, _ in pairs(TeleportLocations) do
    table.insert(DropdownData, name)
end

-- ## 2. Fungsi untuk Melakukan Teleport
local function TeleportToLocation(locationName)
    local destination = TeleportLocations[locationName]
    
    if destination then
        -- Pastikan karakter dan HumanoidRootPart ada sebelum teleport
        local HRP = Character:FindFirstChild("HumanoidRootPart")
        if HRP then
            HRP.CFrame = CFrame.new(destination)
            print("Berhasil Teleport ke: " .. locationName)
        else
            print("Error: HumanoidRootPart tidak ditemukan.")
        end
    else
        print("Error: Lokasi " .. locationName .. " tidak ditemukan dalam list.")
    end
end

-- ## 3. Implementasi Dropdown Menu
Section:NewDropdown({
	Title = "Teleport Destinations",
	Name = "Teleport",
	-- Gunakan nama-nama tempat yang sudah diekstrak
	Data = DropdownData,
	-- Set default ke tempat pertama dalam daftar, atau tempat yang spesifik
	Default = DropdownData[1], 
	Callback = function(selectedName)
		print("Memilih lokasi: " .. selectedName)
		-- Panggil fungsi teleport saat nilai dropdown berubah
		TeleportToLocation(selectedName)
	end,
})
--========================================================--
--           AUTO FISHING SECTION (BARU, KOSONG)
--========================================================--

AutoFishingSection:NewToggle({
	Title = "Auto Cast",
	Default = false,
	Callback = function(v)
		print("Auto Cast:", v)
	end
})

AutoFishingSection:NewToggle({
	Title = "Auto Reel",
	Default = false,
	Callback = function(v)
		print("Auto Reel:", v)
	end
})

--========================================================--
--               AUTO SELL SECTION (BARU, KOSONG)
--========================================================--

AutoSellSection:NewToggle({
	Title = "Auto Sell All Fish",
	Default = false,
	Callback = function(v)
		print("Auto Sell Fish:", v)
	end
})

AutoSellSection:NewToggle({
	Title = "Auto Sell Trash",
	Default = false,
	Callback = function(v)
		print("Auto Sell Trash:", v)
	end
})

--========================================================--
--                    UI CONTROL
--========================================================--

local UIControl = MiscTab:NewSection({
	Title = "UI Control",
	Icon = "monitor",
	Position = "Left"
})

UIControl:NewButton({
	Title = "Minimize UI",
	Callback = function()
		Windows:Toggle()
	end,
})

UIControl:NewButton({
	Title = "Close UI",
	Callback = function()
		Windows:Destroy()
	end,
})

--========================================================--
--                    CONFIG MANAGEMENT
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
--                       DROPDOWN
--========================================================--


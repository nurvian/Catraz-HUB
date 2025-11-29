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

Section:NewToggle({
	Title = "Skip Minigame Fishing",
	Name = "ToggleSkipFish",
	Default = false,
	Callback = function(tr)
		-- Variabel dan Fungsi Skip yang sudah kita buat sebelumnya
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		
		-- Dapatkan Referensi Remote (sebaiknya diletakkan di luar callback untuk efisiensi)
		local RF_Start = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net"):WaitForChild("RF/RequestFishingMinigameStarted")
		local RE_Complete = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net"):WaitForChild("RE/FishingCompleted")

		if tr == true then
			-- ✅ Logic dijalankan saat Toggle diaktifkan (ON)

			local args = {
				-- Masukkan argumen posisi dan timestamp yang sesuai
				-1.233184814453125,
				0.8114499069302521,
				os.time() 
			}

			print("Toggle ON: Mencoba melakukan skip memancing...")

			-- Tahap 1: Memulai minigame (InvokeServer)
			local startResult = RF_Start:InvokeServer(unpack(args))
			
			-- Tahap 2: Waktu tunggu minimal
			wait(0.1) 
			
			-- Tahap 3: Menyelesaikan/Menarik Kail (FireServer)
			RE_Complete:FireServer()
            
            print("Fishing sequence completed/skipped. Result from start:", startResult)

		else
			-- ❌ Logic dijalankan saat Toggle dinonaktifkan (OFF)
			print("Toggle OFF: Skip memancing dinonaktifkan.")
            
            -- Untuk fungsi yang hanya dijalankan sekali (seperti ini),
            -- biasanya tidak ada aksi yang perlu dilakukan saat dinonaktifkan.
		end
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


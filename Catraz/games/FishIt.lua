local SugarLibrary = loadstring(game:HttpGetAsync(
    'https://raw.githubusercontent.com/Yomkav2/Sugar-UI/refs/heads/main/Source'
))();
local Notification = SugarLibrary.Notification();
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")
local SellAllItems = Net:WaitForChild("RF/SellAllItems")

-- Variabel untuk menyimpan koneksi loop agar bisa dihentikan
local autoSellConnection = nil

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
	Title = "Auto Sell Items",
	Name = "AutoSellToggle",
	Default = false,
	Callback = function(isEnabled)
		if isEnabled then
			-- Jika toggle dihidupkan
			print("Auto Sell Dihidupkan")
			
			-- Buat loop baru
			autoSellConnection = task.spawn(function()
				while true do
					-- Periksa apakah toggle masih aktif. 
					-- Sebenarnya tidak perlu di while true, tapi ini menjaga agar loop berhenti 
					-- jika ada cara lain mematikan toggle (misalnya, jika game dihentikan).
					if autoSellConnection == nil then break end 

					-- Panggil fungsi InvokeServer
					local success, result = pcall(function()
						return SellAllItems:InvokeServer()
					end)

					if success then
						-- print("Jual berhasil:", result)
					else
						print("Error saat menjual:", result)
					end
					
					-- Tunggu sebentar sebelum menjual lagi (misalnya 1 detik)
					task.wait(1) 
				end
			end)
		else
			-- Jika toggle dimatikan
			print("Auto Sell Dimatikan")
			
			-- Hentikan loop yang sedang berjalan
			if autoSellConnection then
				task.cancel(autoSellConnection)
				autoSellConnection = nil
			end
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


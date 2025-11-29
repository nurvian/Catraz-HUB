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
	Title = "Auto Farm",
	Name = "AutoFarm",
	Default = false,
	Callback = function(v)
		print("AutoFarm:", v)
	end,
})

Section:NewButton({
	Title = "Kill All",
	Callback = function()
		Notification.new({
			Title = "Killed",
			Description = "10",
			Duration = 5,
			Icon = "sword"
		})
		print("Killed All")
	end,
})

Section:NewButton({
	Title = "Teleport",
	Callback = function()
		print("Teleport used")
	end,
})

-- SLIDERS

Section:NewSlider({
	Title = "Slider",
	Name = "Slider1",
	Min = 10,
	Max = 50,
	Default = 25,
	Callback = function(v)
		print("Slider:", v)
	end,
})

Section:NewSlider({
	Title = "WalkSpeed",
	Name = "WalkSpeed",
	Min = 15,
	Max = 50,
	Default = 16,
	Callback = function(v)
		print("WalkSpeed:", v)
	end,
})

-- KEYBINDS

Section:NewKeybind({
	Title = "Keybind",
	Name = "Keybind1",
	Default = Enum.KeyCode.RightAlt,
	Callback = function(key)
		print("Pressed:", key)
	end,
})

Section:NewKeybind({
	Title = "Auto Combo",
	Name = "AutoCombo",
	Default = Enum.KeyCode.T,
	Callback = function(key)
		print("Auto Combo:", key)
	end,
})

--========================================================--
--                    UI CONTROL (ADDED)
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

Section:NewDropdown({
	Title = "Method",
	Name = "Method",
	Data = {"Teleport", "Locker", "Auto"},
	Default = "Auto",
	Callback = function(method)
		print("Method:", method)
	end,
})
--========================================================--
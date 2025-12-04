-------- Window / UI Library --------
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
------- window / UI Library end --------
------- Tabs --------
local MainTab = Window:Tab({ Title = "Main", Icon = "house" })
local ShopTab = Window:Tab({ Title = "Shop", Icon = "store" })
local TeleportTab = Window:Tab({ Title = "Teleport", Icon = "navigation" })
local MiscTab = Window:Tab({ Title = "Misc", Icon = "settings" })
local ConfigTab = Window:Tab({ Title = "Configs", Icon = "save" })
------- Tabs end --------
-------sections --------
local MainSection = MainTab:Section({ Title = "Main Cheats" })
local ShopSection = ShopTab:Section({ Title = "Shop Cheats" })
local TeleportSection = TeleportTab:Section({ Title = "Teleport Cheats" })
local MiscSection = MiscTab:Section({ Title = "Misc Cheats" })
local ConfigSection = ConfigTab:Section({ Title = "Config Options" })
-------sections end --------
------- core dan vardiabels --------
local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    VirtualUser = game:GetService("VirtualUser"),
    RunService = game:GetService("RunService"),
    HttpService = game:GetService("HttpService")
}
------- core dan vardiabels end --------
------- Main Tab and section logic  --------

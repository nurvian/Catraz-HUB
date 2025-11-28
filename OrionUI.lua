if game.PlaceId == 121864768012064 then
    local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()
    local Window = OrionLib:MakeWindow({Name = "Catraz Hub", HidePremium = false, SaveConfig = true, ConfigFolder = "Catraz"})

    -- Tab Didefinisikan sebagai 'Main'
    local Main = Window:MakeTab({
        Name = "Main",
        Icon = "house",
        PremiumOnly = false
    })

    -- Gunakan 'Main' (Tab yang sudah dibuat) untuk menambahkan Section
    local Section = Main:AddSection({
        Name = "Main Options" -- Saya tambahkan " Options" agar lebih jelas
    })

    -- Gunakan 'Main' (Tab yang sudah dibuat) untuk menambahkan Slider
    Main:AddSlider({
        Name = "Change walks speed",
        Min = 0,
        Max = 500,
        Default = 16,
        Color = Color3.fromRGB(255,255,255),
        Increment = 1,
        ValueName = "Speed",
        Callback = function(Value)
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end    
    })

end
OrionLib:Init()
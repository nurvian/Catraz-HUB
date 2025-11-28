local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()

function Script()
    local Window = Library.CreateLib("Catraz Hub", "Ocean")
    local Main = Window:NewTab("Main")
    local MainSection = Main:NewSection("Main")

    -- Script

    MainSection:NewSlider("WalkSpeed", "Change walks speed", 500, 16, function(s) -- 500 (MaxValue) | 0 (MinValue)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = s
    end)

    MainSection:NewSlider("JumpPower", "Change jump power", 500, 50, function(s) -- 500 (MaxValue) | 0 (MinValue)
        game.Players.LocalPlayer.Character.Humanoid.JumpPower = s
    end)

end

if game.PlaceId == 6701277882 then
    Script()
end

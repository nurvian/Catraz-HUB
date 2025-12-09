local games = {
    [121864768012064] = "https://raw.githubusercontent.com/nurvian/Catraz-HUB/refs/heads/main/Catraz/games/FishIt.lua"
    [76558904092080] = "https://raw.githubusercontent.com/nurvian/Catraz-HUB/refs/heads/main/Catraz/games/TheForge.lua?token=GHSAT0AAAAAADQHKTHGQA4LM7BZ3BTJNJE62JYJH3Q"
    [129009554587176] = "https://raw.githubusercontent.com/nurvian/Catraz-HUB/refs/heads/main/Catraz/games/TheForge.lua?token=GHSAT0AAAAAADQHKTHGQA4LM7BZ3BTJNJE62JYJH3Q"
}

local currentID = game.PlaceId
local scriptURL = games[currentID]

if scriptURL then
    loadstring(game:HttpGet(scriptURL))()
else
    game.Players.LocalPlayer:Kick("Yo! This game ain't on the list.\nCheck the Discord for whitelisted games, homie.")
end
local games = {
    [121864768012064] = "https://raw.githubusercontent.com/nurvian/Catraz-HUB/refs/heads/main/Catraz/games/FishIt.lua", -- Tambah koma
    [76558904092080]  = "https://raw.githubusercontent.com/nurvian/Catraz-HUB/refs/heads/main/Catraz/games/TheForge.lua", -- Tambah koma
    [129009554587176] = "https://raw.githubusercontent.com/nurvian/Catraz-HUB/refs/heads/main/Catraz/games/TheForge.lua"
}

local currentID = game.PlaceId
local scriptURL = games[currentID]

-- Debugging (Supaya kamu tau ID game yang kamu mainkan sekarang berapa)
print("Current Game ID:", currentID) 

if scriptURL then
    -- Perbaikan: Hapus tanda kutip (' ') di dalam kurung HttpGet
    loadstring(game:HttpGet(scriptURL))() 
else
    game.Players.LocalPlayer:Kick("Yo! This game ain't on the list.\nCheck the Discord for whitelisted games, homie.")
end
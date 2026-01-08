local games = {
    [76558904092080]  = "https://api.junkie-development.de/api/v1/luascripts/public/ea8ae5d36a20a896bb7f85ea42d1378ea6925566a1ddfb715928d016ad3fe70e/download", 
    [129009554587176] = "https://api.junkie-development.de/api/v1/luascripts/public/ea8ae5d36a20a896bb7f85ea42d1378ea6925566a1ddfb715928d016ad3fe70e/download",
    [131884594917121] = "https://api.junkie-development.de/api/v1/luascripts/public/ea8ae5d36a20a896bb7f85ea42d1378ea6925566a1ddfb715928d016ad3fe70e/download",
}

local currentID = game.PlaceId
local scriptURL = games[currentID]

-- Debugging 
print("[Catraz Hub] Current Game ID:", currentID) 

if scriptURL then

    getgenv().SCRIPT_KEY = "KEYLESS" 
    
    loadstring(game:HttpGet(scriptURL))() 
else
    game.Players.LocalPlayer:Kick("Yo! This game ain't on the list.\nCheck the Discord for whitelisted games, homie.")
end
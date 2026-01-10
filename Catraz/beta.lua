local games = { 
    [76558904092080]  = "https://api.junkie-development.de/api/v1/luascripts/public/471c571966bd317794998d4e6ae402400079e796c61a2be95eb01b46c6ff01c1/download", 
    [129009554587176] = "https://api.junkie-development.de/api/v1/luascripts/public/471c571966bd317794998d4e6ae402400079e796c61a2be95eb01b46c6ff01c1/download",
    [131884594917121] = "https://api.junkie-development.de/api/v1/luascripts/public/471c571966bd317794998d4e6ae402400079e796c61a2be95eb01b46c6ff01c1/download",
}

local currentID = game.PlaceId
local scriptURL = games[currentID]

-- Debugging 
print("Current Game ID:", currentID) 

if scriptURL then
    loadstring(game:HttpGet(scriptURL))() 
else
    game.Players.LocalPlayer:Kick("Yo! This game ain't on the list.\nCheck the Discord for whitelisted games, homie.")
end
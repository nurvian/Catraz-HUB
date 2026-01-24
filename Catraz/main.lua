local games = {
    [121864768012064] = "https://api.jnkie.com/api/v1/luascripts/public/97afe9c02a8026a11c091fedb8e687bd4c866ee7ac2a7a292bb9513ad65b5c5a/download", 
    [76558904092080]  = "https://api.jnkie.com/api/v1/luascripts/public/ea8ae5d36a20a896bb7f85ea42d1378ea6925566a1ddfb715928d016ad3fe70e/download", 
    [129009554587176] = "https://api.jnkie.com/api/v1/luascripts/public/ea8ae5d36a20a896bb7f85ea42d1378ea6925566a1ddfb715928d016ad3fe70e/download",
    [131884594917121] = "https://api.jnkie.com/api/v1/luascripts/public/ea8ae5d36a20a896bb7f85ea42d1378ea6925566a1ddfb715928d016ad3fe70e/download",
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
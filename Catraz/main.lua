local games = {
    [121864768012064] = "https://api.jnkie.com/api/v1/luascripts/public/97afe9c02a8026a11c091fedb8e687bd4c866ee7ac2a7a292bb9513ad65b5c5a/download", 
    [76558904092080]  = "https://api.jnkie.com/api/v1/luascripts/public/ea8ae5d36a20a896bb7f85ea42d1378ea6925566a1ddfb715928d016ad3fe70e/download", 
    [129009554587176] = "https://api.jnkie.com/api/v1/luascripts/public/ea8ae5d36a20a896bb7f85ea42d1378ea6925566a1ddfb715928d016ad3fe70e/download",
    [131884594917121] = "https://api.jnkie.com/api/v1/luascripts/public/ea8ae5d36a20a896bb7f85ea42d1378ea6925566a1ddfb715928d016ad3fe70e/download",
    [1537690962] = "https://api.jnkie.com/api/v1/luascripts/public/356b91d2f130f0d93b4bf50e5d3c9f611a6b210ce97f97317a2c7213c1a25431/download",
    [127794225497302] = "https://api.jnkie.com/api/v1/luascripts/public/16c8fd26bd86602187a839bb4c4f521723686c5fc3aa5dc91ecf9f6e7608318e/download",
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
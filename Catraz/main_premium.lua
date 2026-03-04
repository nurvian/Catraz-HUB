-- main_premium.lua
local games = {
    [121864768012064] = { url = "https://api.jnkie.com/api/v1/luascripts/public/97afe9c02a8026a11c091fedb8e687bd4c866ee7ac2a7a292bb9513ad65b5c5a/download", key_required = true }, -- Fish It
    [1537690962]      = { url = "https://api.jnkie.com/api/v1/luascripts/public/9aef5af13fe03c69370830bb9db781d35039ed439aa40dce9cd05410777e9e78/download", key_required = true }, -- Bee Swarm
    [130594398886540] = { url = "https://api.jnkie.com/api/v1/luascripts/public/137af69c239c8c71d27ab032c56b4096d762602207c63b096101e516f52aa305/download", key_required = true }, -- Garden Horizons
    [91833329899022] = { url = "https://api.jnkie.com/api/v1/luascripts/public/08a963600bde56e77609be5c8a35839682d14cf9a8fe98342719d4401288a3ed/download", key_required = true }, -- Create a World
    [96645548064314] = { url = "https://api.jnkie.com/api/v1/luascripts/public/6be28e98454a5d62eadf95db42a48065922a3c1c4374f44191cb382262e11985/download", key_required = true }, -- Catch and Tame

    -- Game Pakai Key (Akan memanggil Key System)
    [76558904092080]  = { url = "https://api.jnkie.com/api/v1/luascripts/public/ea7397c2c8068ab97ccf6e5883ae89b7030c71fc022997d3a777d371d3efc904/download", key_required = true },  -- The Forge 1
    [129009554587176] = { url = "https://api.jnkie.com/api/v1/luascripts/public/ea7397c2c8068ab97ccf6e5883ae89b7030c71fc022997d3a777d371d3efc904/download", key_required = true }, -- The Forge 2
    [131884594917121] = { url = "https://api.jnkie.com/api/v1/luascripts/public/ea7397c2c8068ab97ccf6e5883ae89b7030c71fc022997d3a777d371d3efc904/download", key_required = true }, -- The Forge 3
    [74414241680540] = { url = "https://api.jnkie.com/api/v1/luascripts/public/ea7397c2c8068ab97ccf6e5883ae89b7030c71fc022997d3a777d371d3efc904/download", key_required = true }, -- The Forge 4
    [127794225497302] = { url = "https://api.jnkie.com/api/v1/luascripts/public/df8df848fbfbd8bf211a96537ea75ffc51195f895eb28e369a56f5845fecbbff/download", key_required = true },  -- Abyss
    [131623223084840] = { url = "https://api.jnkie.com/api/v1/luascripts/public/4e724e2ae3f026d58d1e495342d6d2b3862b4013cb9c9fcbb95befe3e5110bf3/download", key_required = true }, -- Escape Tsunami For Brainrots
    [137629155365661] = { url = "https://api.jnkie.com/api/v1/luascripts/public/4e724e2ae3f026d58d1e495342d6d2b3862b4013cb9c9fcbb95befe3e5110bf3/download", key_required = true }, -- Escape Tsunami For brainrots
    [86362492050446] = { url = "https://api.jnkie.com/api/v1/luascripts/public/4e724e2ae3f026d58d1e495342d6d2b3862b4013cb9c9fcbb95befe3e5110bf3/download", key_required = true }, -- Escape Tsunami For Brainrots
}

local currentID = game.PlaceId
local gameData = games[currentID]

if gameData then
    getgenv().CatrazTargetScript = gameData.url
    -- Panggil file Key System khusus Premium
    loadstring(game:HttpGet("https://raw.githubusercontent.com/nurvian/Catraz-HUB/refs/heads/main/Catraz/keysystem_premiumobf.lua"))()
else
    game.Players.LocalPlayer:Kick("Not supported or not a Premium User.")
end
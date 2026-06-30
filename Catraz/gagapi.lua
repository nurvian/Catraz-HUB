-- StockReader_Realtime.lua (+ Weather + Phase + Dumper + GUI + Anti-AFK)
-- Script otomatis jalan, ramal 10 hari, lalu loop kirim data realtime!

local Players     = game:GetService("Players")
local lp          = Players.LocalPlayer
local PlayerGui   = lp:WaitForChild("PlayerGui")
local HttpService = game:GetService("HttpService")
local Workspace   = game:GetService("Workspace")
local RS          = game:GetService("ReplicatedStorage")
local TS          = game:GetService("TweenService")
local CoreGui     = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or PlayerGui

local req = (syn and syn.request) or request or http_request or (http and http.request)

local CONFIG = {
    API_URL_UPDATE  = "http://194.233.73.70:5050/api/gag2/main/update",
    API_URL_SCHED   = "http://194.233.73.70:5050/api/gag2/main/schedule",
    API_KEY         = "3ISQ6vScn3dczkNY",
    CHECK_INTERVAL  = 3,
    PREDICT_DAYS    = 10, -- Cuma 10 hari biar gak freeze pas inject
}

-- ============================================================
-- GUI SIMPLE & KEREN
-- ============================================================
local uiStatus, uiInfo

local function createUI()
    local sg = Instance.new("ScreenGui")
    sg.Name = "GraywolfTrackerUI"
    if CoreGui:FindFirstChild(sg.Name) then CoreGui[sg.Name]:Destroy() end
    sg.Parent = CoreGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 90)
    frame.Position = UDim2.new(0.5, -140, 0, -100)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    frame.BorderSizePixel = 0
    frame.Parent = sg
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 10)
    uiCorner.Parent = frame
    
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = Color3.fromRGB(138, 43, 226)
    uiStroke.Thickness = 2
    uiStroke.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundTransparency = 1
    title.Text = "🐺 GRAYWOLF TRACKER"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = frame
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 20)
    status.Position = UDim2.new(0, 0, 0, 35)
    status.BackgroundTransparency = 1
    status.Text = "Status: Booting..."
    status.TextColor3 = Color3.fromRGB(0, 255, 127)
    status.Font = Enum.Font.Gotham
    status.TextSize = 14
    status.Parent = frame
    
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, 0, 0, 20)
    info.Position = UDim2.new(0, 0, 0, 55)
    info.BackgroundTransparency = 1
    info.Text = "Initializing modules..."
    info.TextColor3 = Color3.fromRGB(170, 170, 170)
    info.Font = Enum.Font.Gotham
    info.TextSize = 12
    info.Parent = frame
    
    -- Animasi turun dari atas
    TS:Create(frame, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -140, 0, 20)}):Play()
    
    uiStatus = status
    uiInfo = info
end

local function updateUI(st, inf, color)
    if uiStatus and st then
        uiStatus.Text = "Status: " .. st
        if color then uiStatus.TextColor3 = color end
    end
    if uiInfo and inf then
        uiInfo.Text = inf
    end
end

-- ============================================================
-- GENERATE SCHEDULE (DUMPER)
-- ============================================================
local function generateAndSendSchedule()
    updateUI("Predicting...", "Scanning modules for schedule...", Color3.fromRGB(255, 165, 0))
    local shopArrays = {}
    local seenArrays = {}

    local function findArraysWithRestockChance(t, path)
        if type(t) ~= "table" then return end
        if seenArrays[t] then return end
        seenArrays[t] = true
        
        local isItemArray = false
        local hasRestockChance = false
        
        if t[1] and type(t[1]) == "table" then
            for _, item in ipairs(t) do
                if type(item) == "table" and item.RestockChance then
                    hasRestockChance = true
                    break
                end
            end
            if hasRestockChance then
                isItemArray = true
                table.insert(shopArrays, { Path = path, Items = t })
            end
        end
        
        if not isItemArray then
            for k, v in pairs(t) do
                if type(v) == "table" then
                    findArraysWithRestockChance(v, path .. "." .. tostring(k))
                end
            end
        end
    end

    -- Scan semua modul kecuali ExclusiveShopData
    for _, module in ipairs(RS:WaitForChild("SharedModules"):GetChildren()) do
        if module:IsA("ModuleScript") and module.Name ~= "ExclusiveShopData" then
            local success, res = pcall(function() return require(module) end)
            if success and type(res) == "table" then
                findArraysWithRestockChance(res, module.Name)
            end
        end
    end

    local OFFSET = -4996
    local TOTAL_CYCLES = math.floor(CONFIG.PREDICT_DAYS * 24 * 12)
    local currentTime = os.time()
    local currentCycle = math.floor(currentTime / 300)
    local scheduleMap = {}

    for i = 0, TOTAL_CYCLES do
        local cycleId = currentCycle + i
        local timestamp = cycleId * 300
        local shopItems = {}
        
        for _, shop in ipairs(shopArrays) do
            local seed = cycleId + OFFSET
            local rng = Random.new(seed)
            for _, item in ipairs(shop.Items) do
                if type(item) == "table" and item.RestockChance then
                    local chance = item.RestockChance
                    local roll = rng:NextInteger(1, 100)
                    if roll <= chance then
                        local itemName = item.ItemName or item.Name or item.PackName or item.ID or item.SeedName
                        if itemName then
                            table.insert(shopItems, itemName)
                        end
                    end
                end
            end
        end
        
        if #shopItems > 0 then
            scheduleMap[tostring(timestamp)] = shopItems
        end
    end

    local finalPayload = {
        ["generatedAt"] = currentTime,
        ["type"] = "AllShops",
        ["schedule"] = scheduleMap
    }

    local jsonOutput = HttpService:JSONEncode(finalPayload)
    updateUI("Uploading...", "Sending " .. CONFIG.PREDICT_DAYS .. " days schedule...", Color3.fromRGB(0, 200, 255))
    
    if req then
        local res = req({
            Url = CONFIG.API_URL_SCHED,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json", ["x-api-key"] = CONFIG.API_KEY },
            Body = jsonOutput
        })
        if res and res.StatusCode == 200 then
            updateUI("Active", "Schedule updated! Listening...", Color3.fromRGB(0, 255, 127))
        else
            updateUI("Active", "Schedule upload failed", Color3.fromRGB(255, 50, 50))
        end
    end
end

-- ============================================================
-- LIVE TRACKER MODULES
-- ============================================================

local SHOPS = {
    { name = "SeedShop_Normal",    path = {"SeedShop", "Frame", "NormalShop"}      },
    -- { name = "SeedShop_Exclusive", path = {"SeedShop", "Frame", "ExclusiveShop"}   }, -- DIHAPUS (Request User)
    { name = "GearShop",           path = {"GearShop",  "Frame", "ScrollingFrame"} },
    { name = "CrateShop",          path = {"CrateShop", "Frame", "ScrollingFrame"} },
}

local WeatherValues = RS:WaitForChild("WeatherValues", 10)
local WEATHER_NAMES = {"Rain", "Lightning", "Rainbow", "Snowfall", "Starfall"}

local function getWeatherData()
    local now = DateTime.now().UnixTimestamp
    local activeWeather = "None"
    local weatherEnd = 0
    local weatherEventName = "None"

    if WeatherValues then
        for _, name in ipairs(WEATHER_NAMES) do
            if WeatherValues:GetAttribute(name .. "_Playing") == true then
                weatherEventName = name
                weatherEnd = WeatherValues:GetAttribute(name .. "_EndTime") or 0
                break
            end
        end
        if weatherEventName == "None" then
            for _, folder in ipairs(WeatherValues:GetChildren()) do
                local bv = folder:FindFirstChild("Playing")
                local nv = folder:FindFirstChild("EndTime")
                if bv and bv:IsA("BoolValue") and bv.Value == true then
                    weatherEventName = folder.Name
                    weatherEnd = nv and nv.Value or 0
                    break
                end
            end
        end
    end

    local wsWeather = Workspace:GetAttribute("ActiveWeather")
    if wsWeather and wsWeather:find("Moon") then
        activeWeather = wsWeather
    elseif weatherEventName ~= "None" then
        activeWeather = weatherEventName
    end

    local phase = Workspace:GetAttribute("ActivePhase") or "Unknown"
    local phaseDuration = Workspace:GetAttribute("PhaseDuration") or 0
    local phaseRemaining = math.max(0, math.floor(phaseDuration - now))

    return {
        ActiveWeather    = activeWeather,
        ActivePhase      = phase,
        WeatherEndTime   = weatherEnd,
        WeatherRemaining = math.max(0, weatherEnd - now),
        PhaseEndTime     = math.floor(phaseDuration),
        PhaseRemaining   = phaseRemaining,
        WeatherEvent     = (weatherEventName ~= "None") and weatherEventName or nil,
    }
end

local lastWeather = getWeatherData()

local function checkWeatherChanged()
    local w = getWeatherData()
    if w.ActiveWeather ~= lastWeather.ActiveWeather
    or w.ActivePhase   ~= lastWeather.ActivePhase
    or (w.WeatherEvent or "None") ~= (lastWeather.WeatherEvent or "None") then
        lastWeather = w
        return true
    end
    return false
end

local function parseStock(t)
    if not t then return 0 end
    t = t:lower()
    if t:find("not owned")  then return "not_owned"  end
    if t:find("^owned")     then return "owned"       end
    if t:find("unequipped") then return "unequipped"  end
    if t:find("equipped")   then return "equipped"    end
    if t:find("no stock")   then return 0             end
    local n = t:match("x(%d+)")
    return n and tonumber(n) or 0
end

local function parseCost(t)
    if not t or t == "N/A" or t == "NO STOCK" then return nil end
    local clean = t:gsub("%¢",""):gsub(",",""):gsub("%s","")
    local num, suffix = clean:match("^([%d%.]+)([KkMmBb]?)$")
    if not num then return nil end
    num = tonumber(num)
    if suffix == "K" or suffix == "k" then num = num * 1000
    elseif suffix == "M" or suffix == "m" then num = num * 1000000
    elseif suffix == "B" or suffix == "b" then num = num * 1000000000
    end
    return num
end

local function readScrollingFrame(sf)
    local items = {}
    for _, item in ipairs(sf:GetChildren()) do
        if (item:IsA("Frame") or item:IsA("ImageButton") or item:IsA("TextButton")) and item.Visible then
            local seedText  = item:FindFirstChild("Seed_Text",  true)
            local costText  = item:FindFirstChild("Cost_Text",  true)
            local stockText = item:FindFirstChild("Stock_Text", true)
            if seedText or costText then
                local name = seedText and seedText.Text or item.Name
                local costRaw = costText and costText.Text or "N/A"
                local stockRaw = stockText and stockText.Text or "N/A"
                if name ~= "" and name ~= "Seed_Text" then
                    local stockVal = parseStock(stockRaw)
                    table.insert(items, {
                        name     = name,
                        cost_raw = costRaw,
                        cost     = parseCost(costRaw),
                        stock    = stockVal,
                        in_stock = stockVal ~= 0 and stockVal ~= "not_owned",
                    })
                end
            end
        end
    end
    return items
end

local function readAllShops()
    local allShops = {}
    for _, shopDef in ipairs(SHOPS) do
        local current = PlayerGui
        local ok = true
        for _, step in ipairs(shopDef.path) do
            local found = current:FindFirstChild(step) or current:FindFirstChild(step, true)
            if not found then ok = false break end
            current = found
        end
        if ok and (current:IsA("ScrollingFrame") or current:IsA("Frame")) then
            allShops[shopDef.name] = readScrollingFrame(current)
        else
            allShops[shopDef.name] = {}
        end
    end
    return allShops
end

local function buildSnapshotMap(allShops)
    local map = {}
    for sn, items in pairs(allShops) do
        for _, item in ipairs(items) do
            map[sn .. "|" .. tostring(item.name)] = {
                stock = tostring(item.stock),
                cost_raw = item.cost_raw
            }
        end
    end
    return map
end

local function hasChanged(oldMap, newMap)
    for k, nv in pairs(newMap) do
        local ov = oldMap[k]
        if not ov or ov.stock ~= nv.stock or ov.cost_raw ~= nv.cost_raw then return true end
    end
    for k in pairs(oldMap) do
        if not newMap[k] then return true end
    end
    return false
end

local function sendLiveUpdate(allShops, weather)
    local payload = HttpService:JSONEncode({
        timestamp = os.time(),
        player    = lp.Name,
        weather   = weather,
        shops     = allShops,
    })
    
    if req then
        req({
            Url = CONFIG.API_URL_UPDATE,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json", ["x-api-key"] = CONFIG.API_KEY },
            Body = payload,
        })
    end
end

-- ============================================================
-- STARTUP
-- ============================================================
createUI()

-- Anti-AFK agar tidak ditendang setelah 20 menit diam
local VirtualUser = game:GetService("VirtualUser")
lp.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    updateUI(nil, "Anti-AFK trigered, keeping connection alive.", Color3.fromRGB(0, 200, 255))
end)

-- Jalankan dumper jadwal (10 hari) secara terpisah agar tidak freeze main thread
task.spawn(generateAndSendSchedule)

local lastSnapshotMap = buildSnapshotMap(readAllShops())
local sentCount = 0

-- Main Loop (Live Tracker)
while true do
    task.wait(CONFIG.CHECK_INTERVAL)
    local currentShops = readAllShops()
    local currentMap = buildSnapshotMap(currentShops)
    local cw = getWeatherData()
    
    local stockChange = hasChanged(lastSnapshotMap, currentMap)
    local wChange = checkWeatherChanged()
    
    if stockChange or wChange then
        sendLiveUpdate(currentShops, cw)
        lastSnapshotMap = currentMap
        sentCount = sentCount + 1
        updateUI("Active", "Sent live updates: " .. sentCount, Color3.fromRGB(0, 255, 127))
    end
end

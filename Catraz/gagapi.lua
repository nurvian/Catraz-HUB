-- StockReader_Realtime.lua (+ Weather Detector + Phase Countdown)
-- Loop terus, kirim ke backend HANYA kalau ada perubahan stock ATAU weather
-- Jalankan via Delta / Solara / Executor lainnya

local Players     = game:GetService("Players")
local lp          = Players.LocalPlayer
local PlayerGui   = lp:WaitForChild("PlayerGui")
local HttpService = game:GetService("HttpService")
local Workspace   = game:GetService("Workspace")
local RS          = game:GetService("ReplicatedStorage")

-- ============================================================
-- CONFIG
-- ============================================================

local CONFIG = {
    API_URL         = "http://194.233.73.70:5050/api/stock",
    API_KEY         = "3ISQ6vScn3dczkNY",
    SEND_TO_BACKEND = true,
    CHECK_INTERVAL  = 3,
    DEBUG_LOG       = false,  -- true = spam console tiap cycle, false = hanya perubahan
}

-- ============================================================
-- DEFINISI SHOP
-- ============================================================

local SHOPS = {
    { name = "SeedShop_Normal",    path = {"SeedShop", "Frame", "NormalShop"}      },
    { name = "SeedShop_Exclusive", path = {"SeedShop", "Frame", "ExclusiveShop"}   },
    { name = "GearShop",           path = {"GearShop",  "Frame", "ScrollingFrame"} },
    { name = "CrateShop",          path = {"CrateShop", "Frame", "ScrollingFrame"} },
}

-- ============================================================
-- WEATHER: Baca dari ReplicatedStorage.WeatherValues
-- PhaseDuration = Unix timestamp kapan phase berikutnya mulai
-- ============================================================

local WeatherValues = RS:WaitForChild("WeatherValues", 10)
local WEATHER_NAMES = {"Rain", "Lightning", "Rainbow", "Snowfall", "Starfall"}

local function getWeatherData()
    local now         = DateTime.now().UnixTimestamp
    local activeWeather = "None"
    local weatherEnd  = 0

    -- Cek WeatherValues attributes (Rain/Lightning tidak punya folder, pakai attribute)
    if WeatherValues then
        for _, name in ipairs(WEATHER_NAMES) do
            local playing = WeatherValues:GetAttribute(name .. "_Playing")
            if playing == true then
                activeWeather = name
                weatherEnd    = WeatherValues:GetAttribute(name .. "_EndTime") or 0
                break
            end
        end

        -- Fallback: cek folder children (Rainbow/Snowfall/Starfall pakai BoolValue)
        if activeWeather == "None" then
            for _, folder in ipairs(WeatherValues:GetChildren()) do
                local bv = folder:FindFirstChild("Playing")
                local nv = folder:FindFirstChild("EndTime")
                if bv and bv:IsA("BoolValue") and bv.Value == true then
                    activeWeather = folder.Name
                    weatherEnd    = nv and nv.Value or 0
                    break
                end
            end
        end
    end

    -- Phase & next phase countdown dari Workspace
    local phase         = Workspace:GetAttribute("ActivePhase")    or "Unknown"
    local phaseDuration = Workspace:GetAttribute("PhaseDuration")  or 0
    -- PhaseDuration adalah Unix timestamp kapan phase berikutnya mulai
    local phaseRemaining = math.max(0, math.floor(phaseDuration - now))

    return {
        ActiveWeather    = activeWeather,
        ActivePhase      = phase,
        WeatherEndTime   = weatherEnd,
        WeatherRemaining = math.max(0, weatherEnd - now),
        PhaseEndTime     = math.floor(phaseDuration),
        PhaseRemaining   = phaseRemaining,
    }
end

local lastWeather = getWeatherData()

local function checkWeatherChanged()
    local w = getWeatherData()
    -- Trigger jika weather ATAU phase berubah
    if w.ActiveWeather ~= lastWeather.ActiveWeather
    or w.ActivePhase   ~= lastWeather.ActivePhase then
        local reason = ("Weather: %s→%s | Phase: %s→%s"):format(
            tostring(lastWeather.ActiveWeather), tostring(w.ActiveWeather),
            tostring(lastWeather.ActivePhase),   tostring(w.ActivePhase)
        )
        lastWeather = w
        return true, reason
    end
    return false, nil
end

-- ============================================================
-- HELPER: Parse stock & cost
-- ============================================================

local function parseStock(stockText)
    if stockText == nil then return 0 end
    local t = stockText:lower()
    if t:find("not owned")  then return "not_owned"  end
    if t:find("^owned")     then return "owned"       end
    if t:find("unequipped") then return "unequipped"  end
    if t:find("equipped")   then return "equipped"    end
    if t:find("no stock")   then return 0             end
    local n = stockText:match("x(%d+)")
    if n then return tonumber(n) end
    return 0
end

local function parseCost(costText)
    if costText == nil or costText == "N/A" or costText == "NO STOCK" then return nil end
    local clean = costText:gsub("%¢",""):gsub(",",""):gsub("%s","")
    local num, suffix = clean:match("^([%d%.]+)([KkMmBb]?)$")
    if not num then return nil end
    num = tonumber(num)
    if suffix == "K" or suffix == "k" then num = num * 1000
    elseif suffix == "M" or suffix == "m" then num = num * 1000000
    elseif suffix == "B" or suffix == "b" then num = num * 1000000000
    end
    return num
end

-- ============================================================
-- BACA SATU SCROLLINGFRAME
-- BUG FIX: stockVal → stockVal didefinisikan dari parseStock()
-- ============================================================

local function readScrollingFrame(sf)
    local items = {}
    for _, item in ipairs(sf:GetChildren()) do
        if (item:IsA("Frame") or item:IsA("ImageButton") or item:IsA("TextButton")) and item.Visible then
            local seedText  = item:FindFirstChild("Seed_Text",  true)
            local costText  = item:FindFirstChild("Cost_Text",  true)
            local stockText = item:FindFirstChild("Stock_Text", true)

            if seedText or costText then
                local name     = seedText and seedText.Text or item.Name
                local costRaw  = costText  and costText.Text  or "N/A"
                local stockRaw = stockText and stockText.Text or "N/A"

                if name ~= "" and name ~= "Seed_Text" then
                    local stockVal = parseStock(stockRaw)  -- FIX: dulu stockVal tidak didefinisikan
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

-- ============================================================
-- BACA SEMUA SHOP
-- ============================================================

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

-- ============================================================
-- DIFF: Cek perubahan stock
-- ============================================================

local function snapshotKey(shopName, item)
    return shopName .. "|" .. tostring(item.name)
end

local function buildSnapshotMap(allShops)
    local map = {}
    for shopName, items in pairs(allShops) do
        for _, item in ipairs(items) do
            local key = snapshotKey(shopName, item)
            map[key] = {
                stock    = tostring(item.stock),
                cost_raw = item.cost_raw,
                in_stock = item.in_stock,
            }
        end
    end
    return map
end

local function hasChanged(oldMap, newMap)
    for key, newVal in pairs(newMap) do
        local oldVal = oldMap[key]
        if not oldVal then
            return true, ("Item baru: %s"):format(key)
        end
        if oldVal.stock ~= newVal.stock then
            return true, ("Stock berubah [%s]: %s → %s"):format(key, oldVal.stock, newVal.stock)
        end
        if oldVal.cost_raw ~= newVal.cost_raw then
            return true, ("Harga berubah [%s]: %s → %s"):format(key, oldVal.cost_raw, newVal.cost_raw)
        end
    end
    for key in pairs(oldMap) do
        if not newMap[key] then
            return true, ("Item hilang: %s"):format(key)
        end
    end
    return false, nil
end

-- ============================================================
-- KIRIM KE BACKEND
-- ============================================================

local function sendToBackend(allShops, weather)
    local payload = {
        timestamp = os.time(),
        player    = lp.Name,
        weather   = weather,
        shops     = allShops,
    }

    local ok, jsonStr = pcall(function()
        return HttpService:JSONEncode(payload)
    end)
    if not ok then
        print("❌ Gagal encode JSON:", jsonStr)
        return false
    end

    -- Primary: request()
    local sendOk, result = pcall(function()
        return request({
            Url     = CONFIG.API_URL,
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json", ["x-api-key"] = CONFIG.API_KEY },
            Body    = jsonStr,
        })
    end)
    if sendOk and result then
        if result.StatusCode == 200 then
            print(("✅ Dikirim! %s"):format(tostring(result.Body):sub(1, 80)))
            return true
        else
            print(("⚠️ Server error %d: %s"):format(result.StatusCode, tostring(result.Body):sub(1, 80)))
            return false
        end
    end

    -- Fallback: syn.request
    local fallOk, fallResult = pcall(function()
        return syn.request({
            Url     = CONFIG.API_URL,
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json", ["x-api-key"] = CONFIG.API_KEY },
            Body    = jsonStr,
        })
    end)
    if fallOk and fallResult and fallResult.StatusCode == 200 then
        print("✅ Dikirim (fallback)!")
        return true
    end

    print("❌ Gagal kirim. Check koneksi / URL backend.")
    return false
end

-- ============================================================
-- MAIN LOOP
-- ============================================================

print("\n" .. string.rep("=", 50))
print("  STOCK + WEATHER TRACKER REAL-TIME")
print("  Interval cek: " .. CONFIG.CHECK_INTERVAL .. " detik")
print(string.rep("=", 50) .. "\n")

local lastSnapshotMap = {}
local cycleCount = 0
local sentCount  = 0

do
    print("[Init] Baca data pertama kali...")
    local initialShops   = readAllShops()
    local initialWeather = getWeatherData()
    lastSnapshotMap = buildSnapshotMap(initialShops)
    lastWeather     = initialWeather

    local totalItems = 0
    for _, items in pairs(initialShops) do totalItems = totalItems + #items end

    local now = DateTime.now().UnixTimestamp
    print(("[Init] %d item | Weather: %s | Phase: %s | Phase ganti dalam: %ds"):format(
        totalItems,
        initialWeather.ActiveWeather,
        initialWeather.ActivePhase,
        initialWeather.PhaseRemaining
    ))
    if initialWeather.ActiveWeather ~= "None" then
        print(("[Init] %s berakhir dalam: %ds"):format(
            initialWeather.ActiveWeather, initialWeather.WeatherRemaining))
    end

    if CONFIG.SEND_TO_BACKEND then
        sendToBackend(initialShops, initialWeather)
        sentCount = sentCount + 1
    end
end

while true do
    task.wait(CONFIG.CHECK_INTERVAL)
    cycleCount = cycleCount + 1

    local currentShops   = readAllShops()
    local currentMap     = buildSnapshotMap(currentShops)
    local currentWeather = getWeatherData()

    local stockChange, sreason = hasChanged(lastSnapshotMap, currentMap)
    local wChange,     wreason = checkWeatherChanged()

    if stockChange or wChange then
        local t = os.date("%H:%M:%S")
        if stockChange then print(("[%s] 🔄 %s"):format(t, sreason)) end
        if wChange     then
            print(("[%s] 🌤️  %s"):format(t, wreason))
            -- Tampilkan countdown weather baru jika aktif
            if currentWeather.ActiveWeather ~= "None" then
                print(("        ⏱️ Berakhir dalam: %ds (EndTime: %d)"):format(
                    currentWeather.WeatherRemaining, currentWeather.WeatherEndTime))
            end
            print(("        🌅 Phase ganti dalam: %ds"):format(currentWeather.PhaseRemaining))
        end

        if CONFIG.SEND_TO_BACKEND then
            local ok = sendToBackend(currentShops, currentWeather)
            if ok then
                sentCount = sentCount + 1
                lastSnapshotMap = currentMap
            end
        else
            lastSnapshotMap = currentMap
            local _, jsonStr = pcall(function()
                return HttpService:JSONEncode({
                    timestamp = os.time(),
                    player    = lp.Name,
                    weather   = currentWeather,
                    shops     = currentShops,
                })
            end)
            print("JSON:", jsonStr)
        end
    else
        if CONFIG.DEBUG_LOG then
            local w = currentWeather
            print(("[Cycle %d] Tidak ada perubahan | Weather: %s | Phase selesai: %ds"):format(
                cycleCount, w.ActiveWeather, w.PhaseRemaining))
        end
    end
end

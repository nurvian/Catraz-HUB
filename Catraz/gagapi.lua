-- StockReader_Realtime.lua
-- Loop terus, kirim ke backend HANYA kalau ada perubahan stock
-- Jalankan via Delta / Solara / Executor lainnya

local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local PlayerGui = lp:WaitForChild("PlayerGui")
local HttpService = game:GetService("HttpService")

-- ============================================================
-- CONFIG
-- ============================================================

local CONFIG = {
    API_URL          = "http://194.233.73.70:5050/api/stock",
    API_KEY          = "3ISQ6vScn3dczkNY",
    SEND_TO_BACKEND  = true,

    -- Interval cek perubahan (detik)
    -- 3 detik = cukup responsif tanpa spam request
    CHECK_INTERVAL   = 3,

    -- Kalau mau debug: print setiap loop walau tidak ada perubahan
    DEBUG_LOG        = false,
}

-- ============================================================
-- DEFINISI SHOP
-- ============================================================

local SHOPS = {
    { name = "SeedShop_Normal",    path = {"SeedShop", "Frame", "NormalShop"}    },
    { name = "SeedShop_Exclusive", path = {"SeedShop", "Frame", "ExclusiveShop"} },
    { name = "GearShop",           path = {"GearShop",  "Frame", "ScrollingFrame"} },
    { name = "CrateShop",          path = {"CrateShop", "Frame", "ScrollingFrame"} },
}

-- ============================================================
-- HELPER: Parse stock & cost
-- ============================================================

local function parseStock(stockText)
    if stockText == nil then return 0 end
    local t = stockText:lower()
    if t:find("not owned") then return "not_owned" end
    if t:find("^owned")    then return "owned" end
    if t:find("equipped")  then return t:find("unequipped") and "unequipped" or "equipped" end
    if t:find("no stock")  then return 0 end
    local n = stockText:match("x(%d+)")
    if n then return tonumber(n) end
    return 0
end

local function parseCost(costText)
    if costText == nil or costText == "N/A" or costText == "NO STOCK" then return nil end
    local clean = costText:gsub("¢",""):gsub(",",""):gsub("%s","")
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
                    table.insert(items, {
                        name     = name,
                        cost_raw = costRaw,
                        cost     = parseCost(costRaw),
                        stock    = parseStock(stockRaw),
                        in_stock = parseStock(stockRaw) ~= 0,
                    })
                end
            end
        end
    end
    return items
end

-- ============================================================
-- BACA SEMUA SHOP → return table allShops
-- ============================================================

local function readAllShops()
    local allShops = {}
    for _, shopDef in ipairs(SHOPS) do
        local current = PlayerGui
        local ok = true
        for _, step in ipairs(shopDef.path) do
            local next = current:FindFirstChild(step) or current:FindFirstChild(step, true)
            if not next then ok = false break end
            current = next
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
-- DIFF: Bandingkan dua snapshot
-- Kembalikan true kalau ada yang berubah
-- ============================================================

local function snapshotKey(shopName, item)
    -- Key unik per item: "ShopName|ItemName"
    return shopName .. "|" .. tostring(item.name)
end

local function buildSnapshotMap(allShops)
    -- Flatten semua item jadi map: key → {stock, cost}
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
    -- Cek item baru / berubah
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
    -- Cek item yang hilang
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

local function sendToBackend(allShops)
    local payload = {
        timestamp = os.time(),
        player    = lp.Name,
        shops     = allShops,
    }

    local ok, jsonStr = pcall(function()
        return HttpService:JSONEncode(payload)
    end)

    if not ok then
        print("❌ Gagal encode JSON:", jsonStr)
        return false
    end

    -- Coba pakai request() bawaan executor
    local sendOk, result = pcall(function()
        return request({
            Url     = CONFIG.API_URL,
            Method  = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["x-api-key"]    = CONFIG.API_KEY,
            },
            Body = jsonStr,
        })
    end)

    if sendOk and result then
        if result.StatusCode == 200 then
            print(("✅ Dikirim! %d shop, response: %s"):format(
                #SHOPS, tostring(result.Body):sub(1, 80)
            ))
            return true
        else
            print(("⚠️ Server error %d: %s"):format(result.StatusCode, tostring(result.Body):sub(1, 80)))
            return false
        end
    end

    -- Fallback: syn.request (executor lama)
    local fallOk, fallResult = pcall(function()
        return syn.request({
            Url     = CONFIG.API_URL,
            Method  = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["x-api-key"]    = CONFIG.API_KEY,
            },
            Body = jsonStr,
        })
    end)

    if fallOk and fallResult then
        if fallResult.StatusCode == 200 then
            print("✅ Dikirim (fallback)!")
            return true
        end
    end

    print("❌ Gagal kirim. Check koneksi / URL backend.")
    return false
end

-- ============================================================
-- MAIN LOOP
-- ============================================================

print("\n" .. string.rep("=", 50))
print("  STOCK TRACKER REAL-TIME")
print("  Interval cek: " .. CONFIG.CHECK_INTERVAL .. " detik")
print(string.rep("=", 50) .. "\n")

-- Snapshot pertama (belum ada data lama)
local lastSnapshotMap = {}
local cycleCount = 0
local sentCount   = 0

-- Kirim sekali di awal supaya backend langsung punya data
do
    print("[Init] Baca stock pertama kali...")
    local initialShops = readAllShops()
    lastSnapshotMap = buildSnapshotMap(initialShops)

    local totalItems = 0
    for _, items in pairs(initialShops) do totalItems = totalItems + #items end
    print(("[Init] Ditemukan %d item. Kirim data awal..."):format(totalItems))

    if CONFIG.SEND_TO_BACKEND then
        sendToBackend(initialShops)
        sentCount = sentCount + 1
    end
end

-- Loop utama
while true do
    task.wait(CONFIG.CHECK_INTERVAL)
    cycleCount = cycleCount + 1

    local currentShops = readAllShops()
    local currentMap   = buildSnapshotMap(currentShops)

    local changed, reason = hasChanged(lastSnapshotMap, currentMap)

    if changed then
        -- Hitung total item
        local totalItems = 0
        for _, items in pairs(currentShops) do totalItems = totalItems + #items end

        local time = os.date("%H:%M:%S")
        print(("\n[%s] 🔄 Perubahan terdeteksi: %s"):format(time, reason))
        print(("[%s] Total item: %d — mengirim ke backend..."):format(time, totalItems))

        if CONFIG.SEND_TO_BACKEND then
            local ok = sendToBackend(currentShops)
            if ok then
                sentCount = sentCount + 1
                lastSnapshotMap = currentMap  -- update snapshot hanya kalau berhasil kirim
            end
        else
            -- Kalau SEND_TO_BACKEND false, tetap update snapshot + print JSON
            lastSnapshotMap = currentMap
            local _, jsonStr = pcall(function() return HttpService:JSONEncode({
                timestamp = os.time(), player = lp.Name, shops = currentShops
            }) end)
            print("JSON:", jsonStr)
        end
    else
        if CONFIG.DEBUG_LOG then
            print(("[Cycle %d] Tidak ada perubahan"):format(cycleCount))
        end
    end
end

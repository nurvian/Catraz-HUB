local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = gethui and gethui() or game:GetService("CoreGui") or game.Players.LocalPlayer.PlayerGui

-- ==========================================
-- KONFIGURASI API CATRAZ HUB
-- ==========================================
local API_URL = "http://bot-service-asia-se-02.cybrancee.com:5023/gag/update"
local CHECK_INTERVAL = 5 -- Cek data setiap 5 detik (API cuma dipanggil kalau data beda)

local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request
if not httpRequest then
    warn("[Catraz Hub] Eksekutor kamu tidak mendukung fungsi HTTP Request!")
    return
end

local success, DataService = pcall(function()
    return require(ReplicatedStorage.Modules.DataService)
end)

if not success then
    warn("[Catraz Hub] Gagal memanggil DataService.")
    return
end

-- ==========================================
-- MEMBUAT UI (MINI DASHBOARD)
-- ==========================================
-- Hapus UI lama kalau ada (biar nggak numpuk kalau di-execute berkali-kali)
if CoreGui:FindFirstChild("CatrazStockSyncUI") then
    CoreGui.CatrazStockSyncUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CatrazStockSyncUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 110)
MainFrame.Position = UDim2.new(1, -270, 1, -130) -- Pojok Kanan Bawah
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🐱 Catraz Hub - Stock Sync"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 14
TitleLabel.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 20)
StatusLabel.Position = UDim2.new(0, 10, 0, 35)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Waiting for data..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

local RuntimeLabel = Instance.new("TextLabel")
RuntimeLabel.Size = UDim2.new(1, -20, 0, 20)
RuntimeLabel.Position = UDim2.new(0, 10, 0, 55)
RuntimeLabel.BackgroundTransparency = 1
RuntimeLabel.Text = "Runtime: 00:00:00"
RuntimeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
RuntimeLabel.Font = Enum.Font.Gotham
RuntimeLabel.TextSize = 12
RuntimeLabel.TextXAlignment = Enum.TextXAlignment.Left
RuntimeLabel.Parent = MainFrame

local LastSyncLabel = Instance.new("TextLabel")
LastSyncLabel.Size = UDim2.new(1, -20, 0, 20)
LastSyncLabel.Position = UDim2.new(0, 10, 0, 75)
LastSyncLabel.BackgroundTransparency = 1
LastSyncLabel.Text = "Last Sync: Never"
LastSyncLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
LastSyncLabel.Font = Enum.Font.Gotham
LastSyncLabel.TextSize = 12
LastSyncLabel.TextXAlignment = Enum.TextXAlignment.Left
LastSyncLabel.Parent = MainFrame

-- ==========================================
-- LOGIC & UPDATE DATA
-- ==========================================
local startTime = os.time()
local lastSentStock = nil

-- Fungsi untuk update Runtime UI
task.spawn(function()
    while task.wait(1) do
        local diff = os.difftime(os.time(), startTime)
        local h = math.floor(diff / 3600)
        local m = math.floor((diff % 3600) / 60)
        local s = diff % 60
        RuntimeLabel.Text = string.format("Runtime: %02d:%02d:%02d", h, m, s)
    end
end)

-- Fungsi untuk ngecek apakah ada perubahan data (Deep Compare)
local function isDataChanged(t1, t2)
    if t1 == t2 then return false end
    if type(t1) ~= "table" or type(t2) ~= "table" then return true end
    
    for k, v in pairs(t1) do
        if isDataChanged(v, t2[k]) then return true end
    end
    for k, v in pairs(t2) do
        if t1[k] == nil then return true end
    end
    return false
end

-- Fungsi utama untuk ngambil & ngirim stock
local function processStockSync()
    local playerData = DataService:GetData()
    if not playerData then return end

    local currentStock = {
        ["Shop"] = {},
        ["Daily_Deals"] = {},
        ["Gears"] = {},
        ["Eggs"] = {},
        ["Garden_Coins"] = {}
    }

    -- 1. Shop
    if playerData.SeedStocks and playerData.SeedStocks.Shop and playerData.SeedStocks.Shop.Stocks then
        for k, v in pairs(playerData.SeedStocks.Shop.Stocks) do currentStock["Shop"][k] = v.Stock end
    end
    -- 2. Daily Deals
    if playerData.SeedStocks and playerData.SeedStocks["Daily Deals"] and playerData.SeedStocks["Daily Deals"].Stocks then
        for k, v in pairs(playerData.SeedStocks["Daily Deals"].Stocks) do currentStock["Daily_Deals"][k] = v.Stock end
    end
    -- 3. Event Shop (Dinamis)
    if playerData.EventShopStock then
        for shopName, shopData in pairs(playerData.EventShopStock) do
            if type(shopData) == "table" and shopData.Stocks then
                local safeShopName = string.gsub(shopName, " ", "_")
                if safeShopName ~= "" then
                    currentStock[safeShopName] = {}
                    for k, v in pairs(shopData.Stocks) do currentStock[safeShopName][k] = v.Stock end
                end
            end
        end
    end
    -- 4. Gears
    if playerData.GearStock and playerData.GearStock.Stocks then
        for k, v in pairs(playerData.GearStock.Stocks) do currentStock["Gears"][k] = v.Stock end
    end
    -- 5. Eggs
    if playerData.PetEggStock and playerData.PetEggStock.Stocks then
        for _, v in pairs(playerData.PetEggStock.Stocks) do
            if v.EggName and v.Stock then currentStock["Eggs"][v.EggName] = v.Stock end
        end
    end
    -- 6. Garden Coins
    if playerData.GardenCoinShopStock and playerData.GardenCoinShopStock.Stocks then
        for k, v in pairs(playerData.GardenCoinShopStock.Stocks) do currentStock["Garden_Coins"][k] = v.Stock end
    end

    -- Cek apakah ada perubahan dari pengiriman sebelumnya
    if lastSentStock and not isDataChanged(currentStock, lastSentStock) then
        StatusLabel.Text = "Status: Idle (No stock changes)"
        StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        return -- STOP DI SINI, JANGAN KIRIM KE API
    end

    -- Kalau data beda (ada update baru), siapkan pengiriman
    StatusLabel.Text = "Status: Syncing to API..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    
    local jsonPayload = HttpService:JSONEncode(currentStock)

    local response = httpRequest({
        Url = API_URL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = jsonPayload
    })

    if response.StatusCode == 200 then
        -- Simpan data ini sebagai acuan perbandingan berikutnya
        lastSentStock = currentStock
        
        LastSyncLabel.Text = "Last Sync: " .. os.date("%X")
        StatusLabel.Text = "Status: Active & Synced"
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        StatusLabel.Text = "Status: API Error (" .. tostring(response.StatusCode) .. ")"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    end
end

-- ==========================================
-- JALANKAN SCRIPT (LOOP)
-- ==========================================
task.spawn(function()
    while true do
        processStockSync()
        task.wait(CHECK_INTERVAL)
    end
end)
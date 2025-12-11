-------- WindUI Loadstring --------
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-------- [[ CORE VARIABLES & SERVICES ]] --------
local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    RunService = game:GetService("RunService"),
    TweenService = game:GetService("TweenService"),
    VirtualInputManager = game:GetService("VirtualInputManager")
}

-- [[ KNIT HOOK ]] --
local Knit = require(Services.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Knit"))
local PlayerController = Knit.GetController("PlayerController")

local LocalPlayer = Services.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local RocksFolder = Services.Workspace:WaitForChild("Rocks")

-- [[ ADVANCED AUTO GENERATOR (FIXED SOURCE) ]] --
local RockNames = {"All"} -- List Nama Batu (Targeting)
local OreNames = {"All"}  -- List Nama Hasil/Ore (Filtering)
local RarityDatabase = {} 
local TempBlacklist = {} -- List batu yang harus dihindari sementara (Anti-Stuck)
-- [[ SHOP GENERATOR ]] --
local ShopPickaxes = {}
local ShopPotions = {}
local PotionDatabase = {}

local RawPotionData = {
    MinerPotion1 = "Miner Potion I",
    HealthPotion1 = "Health Potion I",
    HealthPotion2 = "Health Potion II",
    AttackDamagePotion1 = "Damage Potion I",
    MovementSpeedPotion1 = "Speed Potion I",
    LuckPotion1 = "Luck Potion I"
}

local function RefreshShopLists()
    -- 1. Scan Pickaxes (Dari Folder Assets)
    table.clear(ShopPickaxes)
    pcall(function()
        local PickaxeFolder = Services.ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Equipments"):WaitForChild("Pickaxes")
        for _, tool in pairs(PickaxeFolder:GetChildren()) do
            table.insert(ShopPickaxes, tool.Name)
        end
    end)
    table.sort(ShopPickaxes)

    -- 2. Scan Potions (Dari Data Manual)
    table.clear(ShopPotions)
    for key, realName in pairs(RawPotionData) do
        table.insert(ShopPotions, realName)
        PotionDatabase[realName] = key -- Simpan mapping jika butuh key nanti
    end
    table.sort(ShopPotions)
end

RefreshShopLists()

local function RunAutoGenerator()
    print("[System] Starting Generator...")
    local TempRocks = {}
    local TempOres = {}
    
    -- 1. SCAN ORE (Isi/Drop) dari Data Game
    local Shared = Services.ReplicatedStorage:WaitForChild("Shared", 5)
    local Data = Shared and Shared:WaitForChild("Data", 5)
    local OreFolder = Data and Data:FindFirstChild("Ore")
    
    if OreFolder then
        for _, categoryFolder in pairs(OreFolder:GetChildren()) do
            if categoryFolder:IsA("Folder") then
                for _, itemModule in pairs(categoryFolder:GetChildren()) do
                    if itemModule:IsA("ModuleScript") then
                        TempOres[itemModule.Name] = true
                        local success, data = pcall(require, itemModule)
                        if success and data then
                            local realName = data.Name or itemModule.Name
                            TempOres[realName] = true
                            RarityDatabase[realName] = data.Rarity or "Common"
                        end
                    end
                end
            end
        end
    end
    
    -- 2. SCAN ROCK (Nama Model Batu) dari Assets
    local Assets = Services.ReplicatedStorage:WaitForChild("Assets", 5)
    local RocksAssets = Assets and Assets:FindFirstChild("Rocks")
    
    if RocksAssets then
        for _, rock in pairs(RocksAssets:GetChildren()) do
            TempRocks[rock.Name] = true
        end
    end
    
    for name, _ in pairs(TempRocks) do table.insert(RockNames, name) end
    for name, _ in pairs(TempOres) do table.insert(OreNames, name) end
    
    table.sort(RockNames)
    table.sort(OreNames)
end

RunAutoGenerator()

-- [[ MOB NAMES GENERATOR ]] --
local MobNames = {"All"}
pcall(function()
    local MobAssets = Services.ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Mobs")
    for _, mob in pairs(MobAssets:GetChildren()) do table.insert(MobNames, mob.Name) end
    table.sort(MobNames)
end)

-- [[ FLAGS (SETTINGS) ]] --
local _G_Flags = {
    AutoFarm = false,
    AutoEquip = true,
    
    -- Targeting (ROCKS)
    PriorityRocks = {"Iron", "Gold", "Lucky Block"}, 
    BackupRocks = {"All"}, 
    
    -- Filtering (ORES)
    KeepOres = {"Iron", "Gold", "Mithril", "Adurite", "Adamantite", "Runite", "Lucky Block", "Cobalt"}, 
    OreSkipEnabled = true,
    
    AutoFarmMobs = false,
    SelectedMob = {"All"},
    TweenSpeed = 100, 
    FarmDepth = -8,
    MaxDistance = 300,
    AutoPlayLegit = false,
    AutoSell = false,
    SellRarities = {}, 
    SellThreshold = 40,
    AutoHeal = false,
    HealPercentage = 40,
    IsSellingAction = false,
    AntiLava = false,
}

-------- [[ CATRAZ THEME SETUP ]] --------
WindUI:AddTheme({
    Name = "Native Red",
    Accent = Color3.fromHex("#ff5e5e"), 
    Background = Color3.fromHex("#1a0b0b"), 
    BackgroundTransparency = 0.8, 
    Outline = Color3.fromHex("#451a1a"), 
    Text = Color3.fromHex("#fcfcfc"), 
    Placeholder = Color3.fromHex("#8a4b4b"),
    Button = Color3.fromHex("#2b1212"), 
    Icon = Color3.fromHex("#ffcccc"),
    Hover = Color3.fromHex("#3d1a1a"), 
    WindowBackground = Color3.fromHex("#140808"), 
    WindowShadow = Color3.fromHex("#000000"),
    WindowTopbarButtonIcon = Color3.fromHex("#ffcccc"),
    WindowTopbarTitle = Color3.fromHex("#fcfcfc"), 
    WindowTopbarAuthor = Color3.fromHex("#aa5555"),
    WindowTopbarIcon = Color3.fromHex("#ff5e5e"),
    TabBackground = Color3.fromHex("#0f0505"), 
    TabTitle = Color3.fromHex("#fcfcfc"),
    TabIcon = Color3.fromHex("#cc8888"),
    ElementBackground = Color3.fromHex("#260f0f"), 
    ElementTitle = Color3.fromHex("#fcfcfc"),
    ElementDesc = Color3.fromHex("#b36b6b"),
    ElementIcon = Color3.fromHex("#ffcccc"),
    Toggle = Color3.fromHex("#fcfcfc"), 
    ToggleBar = Color3.fromHex("#3d1a1a"),
    Checkbox = Color3.fromHex("#fcfcfc"),
    CheckboxIcon = Color3.fromHex("#1a0b0b"), 
    Slider = Color3.fromHex("#fcfcfc"),
    SliderThumb = Color3.fromHex("#ff5e5e"), 
})

WindUI:SetTheme("Native Red")

local Window = WindUI:CreateWindow({
    Title = "Catraz Hub | The Forge",
    Folder = "CatrazHub",
    Icon = "rbxassetid://124162045221605", 
    NewElements = true,
    Transparent = true,
    Theme = "Native Red",
    HideSearchBar = true,
    BackgroundImageTransparency = 1,
    OpenButton = { Title = "Open Hub", Enabled = false },
    KeySystem = {                                                   
        Note = "Catraz Hub Key System",              
        API = {                                                     
            { 
                Title = "Platoboost",
                Desc = "Click to copy.", 
                Icon = "rbxassetid://124162045221605", 
                Type = "platoboost",                                
                ServiceId = 15690, 
                Secret = "6b58c208-1a3e-4085-81f8-44a0ed290b88", 
            },                                                      
        },                                                          
    },                                                              
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function() end,
    },
})

-- [[ 1. VERSION TAG (BETA) ]] --
Window:Tag({
    Title = "v4.0-BETA",
    Icon = "github", -- Ikon Github
    Color = Color3.fromHex("#0a0a0a"), -- Warna Hijau Stabilo
})

Window:DisableTopbarButtons({
    "Close", 
    "Minimize", 
    "Fullscreen",
})

WindUI:Notify({
    Title = "Catraz Hub Loaded",
    Content = "Success load Catraz Hub v3.7 (Fix)",
    Duration = 5,
    Icon = "badge-check", 
})



-- [[ CUSTOM TOGGLE UI SYSTEM & MINI DASHBOARD ]] --
task.spawn(function()
    local CoreGui = game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    local Stats = game:GetService("Stats")
    
    local NameUI = "CatrazHubSystem"
    if CoreGui:FindFirstChild(NameUI) then CoreGui[NameUI]:Destroy() end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = NameUI
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false
    
    -- Variables State
    local IsMenuOpen = true -- Asumsi awal menu terbuka
    
    -- 1. TOGGLE BUTTON
    local ToggleBtn = Instance.new("ImageButton")
    ToggleBtn.Name = "MainButton"
    ToggleBtn.Parent = ScreenGui
    ToggleBtn.Position = UDim2.new(0.05, 0, 0.45, 0) -- Posisi Default (Kiri Tengah)
    ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
    ToggleBtn.BackgroundColor3 = Color3.fromHex("#140808")
    ToggleBtn.BackgroundTransparency = 0.2
    ToggleBtn.Draggable = true
    ToggleBtn.AutoButtonColor = false -- Matikan default biar kita custom animasinya

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0.3, 0)
    BtnCorner.Parent = ToggleBtn

    local BtnStroke = Instance.new("UIStroke")
    BtnStroke.Parent = ToggleBtn
    BtnStroke.Color = Color3.fromHex("#ff5e5e")
    BtnStroke.Thickness = 2.5
    BtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local IconImage = Instance.new("ImageLabel")
    IconImage.Parent = ToggleBtn
    IconImage.BackgroundTransparency = 1 
    IconImage.AnchorPoint = Vector2.new(0.5, 0.5)
    IconImage.Position = UDim2.new(0.5, 0, 0.5, 0)
    IconImage.Size = UDim2.new(0.7, 0, 0.7, 0)
    IconImage.Image = "rbxassetid://124162045221605" -- Logo Catraz
    IconImage.ScaleType = Enum.ScaleType.Fit
    
    -- 2. MINI DASHBOARD (Status Box)
    local StatusFrame = Instance.new("Frame")
    StatusFrame.Name = "StatusDashboard"
    StatusFrame.Parent = ScreenGui
    StatusFrame.Position = UDim2.new(0.5, 0, 0.05, 0) -- Posisi Atas Tengah
    StatusFrame.AnchorPoint = Vector2.new(0.5, 0)
    StatusFrame.Size = UDim2.new(0, 300, 0, 65)
    StatusFrame.BackgroundColor3 = Color3.fromHex("#0f0505")
    StatusFrame.BackgroundTransparency = 0.1
    StatusFrame.Visible = false -- Default mati (karena menu buka)

    local StatusCorner = Instance.new("UICorner")
    StatusCorner.CornerRadius = UDim.new(0, 8)
    StatusCorner.Parent = StatusFrame
    
    local StatusStroke = Instance.new("UIStroke")
    StatusStroke.Parent = StatusFrame
    StatusStroke.Color = Color3.fromHex("#451a1a")
    StatusStroke.Thickness = 2
    
    -- Hiasan Garis Merah di Kiri
    local AccentBar = Instance.new("Frame")
    AccentBar.Parent = StatusFrame
    AccentBar.BackgroundColor3 = Color3.fromHex("#ff5e5e")
    AccentBar.Size = UDim2.new(0, 4, 1, 0)
    AccentBar.BorderSizePixel = 0
    local BarCorner = Instance.new("UICorner"); BarCorner.Parent = AccentBar

    -- Isi Teks Dashboard
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Parent = StatusFrame
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position = UDim2.new(0, 15, 0, 5)
    TitleLabel.Size = UDim2.new(1, -20, 0, 20)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = "CATRAZ HUB | <font color='#ff5e5e'>THE FORGE</font>"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 14
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.RichText = true

    local StatsLabel = Instance.new("TextLabel")
    StatsLabel.Parent = StatusFrame
    StatsLabel.BackgroundTransparency = 1
    StatsLabel.Position = UDim2.new(0, 15, 0, 28)
    StatsLabel.Size = UDim2.new(1, -20, 0, 30)
    StatsLabel.Font = Enum.Font.GothamMedium
    StatsLabel.Text = "Loading Stats..."
    StatsLabel.TextColor3 = Color3.fromHex("#cccccc")
    StatsLabel.TextSize = 12
    StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- 3. ANIMATION & LOGIC
    local function PlayClickAnim()
        -- Efek mengecil (Press)
        TweenService:Create(ToggleBtn, TweenInfo.new(0.1), {Size = UDim2.new(0, 40, 0, 40)}):Play()
        task.wait(0.1)
        -- Efek membal balik (Bounce)
        TweenService:Create(ToggleBtn, TweenInfo.new(0.3, Enum.EasingStyle.Elastic), {Size = UDim2.new(0, 50, 0, 50)}):Play()
    end

    local function FormatTime(seconds)
        local h = math.floor(seconds / 3600)
        local m = math.floor((seconds % 3600) / 60)
        local s = math.floor(seconds % 60)
        return string.format("%02d:%02d:%02d", h, m, s)
    end

    ToggleBtn.MouseButton1Click:Connect(function()
        PlayClickAnim()
        Window:Toggle() -- Toggle Menu Utama
        
        IsMenuOpen = not IsMenuOpen
        
        -- Logic: Kalau Menu Buka -> Dashboard Mati. Kalau Menu Tutup -> Dashboard Nyala.
        StatusFrame.Visible = not IsMenuOpen 
        
        if not IsMenuOpen then
            -- Efek Fade In Dashboard
            StatusFrame.BackgroundTransparency = 1
            TitleLabel.TextTransparency = 1
            StatsLabel.TextTransparency = 1
            
            TweenService:Create(StatusFrame, TweenInfo.new(0.3), {BackgroundTransparency = 0.1}):Play()
            TweenService:Create(TitleLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
            TweenService:Create(StatsLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
        end
    end)

    -- 4. LIVE STATS LOOP
    RunService.RenderStepped:Connect(function(deltaTime)
        if StatusFrame.Visible then
            local fps = math.floor(1 / deltaTime)
            local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            local runtime = FormatTime(workspace.DistributedGameTime)
            local realTime = os.date("%H:%M:%S")
            
            StatsLabel.Text = string.format("FPS: %d  |  Ping: %d ms\nTime: %s  |  Runtime: %s", fps, ping, realTime, runtime)
        end
    end)
end)

------- [[ LOGIC FUNCTIONS ]] -------

local function IsTargetValid(targetName, selectionList)
    if selectionList == "All" then return true end
    if type(selectionList) == "table" then
        for _, selected in pairs(selectionList) do
            if selected == "All" then return true end
            if targetName == selected then return true end
            if string.find(targetName, selected) then return true end
        end
        return false
    end
    if type(selectionList) == "string" and string.find(targetName, selectionList) then return true end
    return false
end

local function ResetPhysics()
    local Char = LocalPlayer.Character
    if not Char then return end
    local Root = Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char:FindFirstChild("Humanoid")
    if Root then
        Root.Anchored = false
        Root.Velocity = Vector3.zero
        Root.AssemblyLinearVelocity = Vector3.zero
        for _, obj in pairs(Root:GetChildren()) do
            if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") or obj.Name == "FlyFloat" then obj:Destroy() end
        end
    end
    if Hum then Hum.PlatformStand = false end
end

-- [[ ANTI LAVA LOGIC (FIXED NAME) ]] --
local function ToggleAntiLava(state)
    _G_Flags.AntiLava = state
    
    if state then
        print("[Catraz] Anti-Lava Enabled for: lavadamagezone")
        
        -- 1. Hapus yang sudah ada sekarang
        for _, obj in pairs(Services.Workspace:GetDescendants()) do
            if obj.Name == "lavadamagezone" then
                obj:Destroy()
            end
        end
        
        -- 2. Pantau jika map reload atau kita teleport ke Volcano
        local LavaConnection
        LavaConnection = Services.Workspace.DescendantAdded:Connect(function(obj)
            if not _G_Flags.AntiLava then 
                LavaConnection:Disconnect() -- Stop memantau kalau dimatikan
                return 
            end
            
            if obj.Name == "lavadamagezone" then
                task.wait() -- Tunggu sebentar biar ke-load property-nya
                obj:Destroy()
            end
        end)
    end
end

local function ToggleFloat(state)
    local Char = LocalPlayer.Character
    if not Char or not Char:FindFirstChild("HumanoidRootPart") then return end
    local Root = Char.HumanoidRootPart
    if state then
        if not Root:FindFirstChild("FlyFloat") then
            local BV = Instance.new("BodyVelocity")
            BV.Name = "FlyFloat"
            BV.Parent = Root
            BV.MaxForce = Vector3.new(100000, 100000, 100000) 
            BV.Velocity = Vector3.new(0, 0, 0) 
        end
        if Char:FindFirstChild("Humanoid") then Char.Humanoid.PlatformStand = true end
    else
        ResetPhysics()
    end
end

local function GetTool(keyword)
    if not LocalPlayer.Backpack then return nil end
    for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do
        if item:IsA("Tool") and string.find(item.Name, keyword) then return item end
    end
    if LocalPlayer.Character then
        for _, item in pairs(LocalPlayer.Character:GetChildren()) do
            if item:IsA("Tool") and string.find(item.Name, keyword) then return item end
        end
    end
    return nil
end

local function ActivateTool(toolNameArg)
    local Char = LocalPlayer.Character
    if not Char then return end
    local tool = Char:FindFirstChildWhichIsA("Tool")
    if tool then
        tool:Activate() 
        local Remote = Services.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("ToolService"):WaitForChild("RF"):WaitForChild("ToolActivated")
        if Remote then pcall(function() Remote:InvokeServer(unpack({toolNameArg})) end) end
    end
end

local function TweenToPosition(targetPosition)
    local Char = LocalPlayer.Character
    if not Char or not Char:FindFirstChild("HumanoidRootPart") then return end
    local Root = Char.HumanoidRootPart
    local Distance = (Root.Position - targetPosition).Magnitude
    local Time = Distance / _G_Flags.TweenSpeed 
    if Distance < 10 then Time = 0 end 
    ToggleFloat(true) 
    local TweenInfo = TweenInfo.new(Time, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local Tween = Services.TweenService:Create(Root, TweenInfo, {CFrame = CFrame.new(targetPosition)})
    Tween:Play()
    if Time > 0 then
        local elapsed = 0
        while elapsed < Time do
            if not _G_Flags.AutoFarm and not _G_Flags.AutoFarmMobs and not _G_Flags.AutoSell and not _G_Flags.IsSellingAction then 
                Tween:Cancel() ResetPhysics() return false 
            end
            if not Char or not Root or (Char.Humanoid and Char.Humanoid.Health <= 0) then Tween:Cancel() ResetPhysics() return false end
            task.wait(0.1) elapsed = elapsed + 0.1
        end
    end
    return true 
end

-- [[ PRIORITY MINING SYSTEM (WITH BLACKLIST) ]] --
local function GetActiveRock()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    
    -- Clear Blacklist (Hapus yang sudah > 5 detik)
    for model, timeAdded in pairs(TempBlacklist) do
        if tick() - timeAdded > 5 then TempBlacklist[model] = nil end
    end
    
    local function FindRockInList(targetList)
        local bestRock, bestDist = nil, math.huge
        
        for _, obj in pairs(RocksFolder:GetDescendants()) do
            if obj.Name == "Hitbox" and obj.Parent then
                local rockModel, orePos = obj.Parent, obj:FindFirstChild("OrePosition")
                
                -- CEK BLACKLIST
                if not TempBlacklist[rockModel] then 
                    if orePos and rockModel:IsA("Model") then
                        if IsTargetValid(rockModel.Name, targetList) then
                            local targetPos = (orePos:IsA("BasePart") and orePos.Position) or (orePos:IsA("Attachment") and orePos.WorldPosition)
                            if targetPos then
                                local dist = (myRoot.Position - targetPos).Magnitude
                                if dist < _G_Flags.MaxDistance and dist < bestDist then
                                    bestRock = { Model = rockModel, Position = targetPos }
                                    bestDist = dist
                                end
                            end
                        end
                    end
                end
            end
        end
        return bestRock
    end

    local PriorityTarget = FindRockInList(_G_Flags.PriorityRocks)
    if PriorityTarget then return PriorityTarget end
    
    local BackupTarget = FindRockInList(_G_Flags.BackupRocks)
    return BackupTarget
end

local function GetActiveMob()
    local closestMob, shortestDistance = nil, math.huge
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    for _, obj in pairs(Services.Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            local hum = obj.Humanoid
            if hum.Health > 0 and not Services.Players:GetPlayerFromCharacter(obj) then
                if IsTargetValid(obj.Name, _G_Flags.SelectedMob) then
                    local dist = (myRoot.Position - obj.HumanoidRootPart.Position).Magnitude
                    if dist < _G_Flags.MaxDistance and dist < shortestDistance then
                        closestMob = obj
                        shortestDistance = dist
                    end
                end
            end
        end
    end
    return closestMob
end

-- [[ ORE REVEAL DETECTION (FIXED ATTRIBUTES) ]] --
local function CheckRevealedOre(RockModel)
    if not RockModel then return nil end
    
    local OreModel = RockModel:FindFirstChild("Ore")
    if OreModel then
        -- FIX UTAMA: Baca Attribute "Ore" (Contoh: "Gold")
        local oreType = OreModel:GetAttribute("Ore")
        if oreType then
            return oreType -- Mengembalikan "Gold", "Iron", dll
        end
    end
    return nil
end

-- [[ IS ROCK CLAIMED CHECKER ]] --
local function IsRockClaimed(RockModel)
    if not RockModel then return false end
    
    -- Cek BillboardGui bernama "infoFrame"
    local infoFrame = RockModel:FindFirstChild("infoFrame")
    if infoFrame then
        for _, gui in pairs(infoFrame:GetDescendants()) do
            if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                local text = string.lower(gui.Text)
                if string.find(text, "someone else") or string.find(text, "already mining") then
                    return true
                end
            end
        end
    end
    return false
end

-- [[ AUTO SELL FUNCTIONS ]]
local function GetTotalItems()
    local count = 0
    if PlayerController and PlayerController.Replica and PlayerController.Replica.Data then
        for name, q in pairs(PlayerController.Replica.Data.Inventory) do
            if not string.find(name, "Pickaxe") and not string.find(name, "Sword") then
                if type(q) == "number" then count = count + q
                elseif type(q) == "table" then count = count + (q.Value or q.Amount or 0) end
            end
        end
    end
    return count
end

local function ProcessAutoSell()
    local Inventory = nil
    if PlayerController and PlayerController.Replica and PlayerController.Replica.Data then
        Inventory = PlayerController.Replica.Data.Inventory
    end
    if not Inventory then return end

    local BasketToSell = {}
    local hasItem = false
    local totalQty = 0

    for itemName, quantity in pairs(Inventory) do
        local qty = 0
        if type(quantity) == "number" then qty = quantity
        elseif type(quantity) == "table" then qty = quantity.Value or quantity.Amount or 0 end
        
        if qty > 0 and not string.find(itemName, "Pickaxe") and not string.find(itemName, "Sword") then
            local itemRarity = RarityDatabase[itemName] or "Common"
            if IsTargetValid(itemRarity, _G_Flags.SellRarities) then
                BasketToSell[itemName] = qty
                hasItem = true
                totalQty = totalQty + 1
            end
        end
    end

    if hasItem then
        local NPC = Services.Workspace:FindFirstChild("Greedy Cey", true)
        local Prompt = NPC and NPC:FindFirstChildWhichIsA("ProximityPrompt", true)
        
        if NPC and Prompt then
            local TargetPos = nil
            local ParentObj = Prompt.Parent 
            if ParentObj:IsA("BasePart") then TargetPos = ParentObj.Position
            elseif ParentObj:IsA("Model") then TargetPos = ParentObj:GetPivot().Position end
            if not TargetPos then return end

            game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Auto Sell", Text = "Selling " .. totalQty .. " items...", Duration = 2 })
            
            local Char = LocalPlayer.Character
            local Root = Char and Char:FindFirstChild("HumanoidRootPart")
            if not Root then return end
            
            local OldPos = Root.Position
            local wasFarming = _G_Flags.AutoFarm
            local wasMobbing = _G_Flags.AutoFarmMobs

            _G_Flags.IsSellingAction = true
            _G_Flags.AutoFarm = false
            _G_Flags.AutoFarmMobs = false
            
            local arrived = TweenToPosition(TargetPos + Vector3.new(0, 0, 5))
            
            if arrived then
                fireproximityprompt(Prompt)
                task.wait(0.8) 
                local DialogueService = Services.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("DialogueService")
                local RunCommand = DialogueService:WaitForChild("RF"):WaitForChild("RunCommand")
                
                if RunCommand then
                    pcall(function()
                        local args = { "SellConfirm", { Basket = BasketToSell } }
                        RunCommand:InvokeServer(unpack(args))
                        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Auto Sell", Text = "Sold Successfully!", Duration = 3 })
                    end)
                end
                task.wait(0.5)
                TweenToPosition(OldPos) 
            end
            
            _G_Flags.IsSellingAction = false
            if wasFarming then _G_Flags.AutoFarm = true end
            if wasMobbing then _G_Flags.AutoFarmMobs = true end
        end
    end
end

-------- [[ SHOP LOGIC: HYBRID SYSTEM ]] --------

local function FindShopItemPosition(ItemName)
    print("[Shop] Mencari lokasi untuk: " .. ItemName)
    local searchKey = string.lower(ItemName)

    -- [[ LOGIC 1: KHUSUS PICKAXE (Cari Model Fisik) ]]
    if string.find(ItemName, "Pickaxe") then
        for _, obj in pairs(Services.Workspace:GetDescendants()) do
            if obj.Name == ItemName and obj:IsA("Model") and not obj:IsDescendantOf(Services.Players) then
                if obj.PrimaryPart then return obj.PrimaryPart.Position end
                if obj:FindFirstChild("Handle") then return obj.Handle.Position end
                if obj:FindFirstChild("Head") then return obj.Head.Position end
                local anyPart = obj:FindFirstChildWhichIsA("BasePart", true)
                if anyPart then return anyPart.Position end
            end
        end
        
    -- [[ LOGIC 2: KHUSUS POTION (Cari di Folder Proximity) ]]
    else
        -- Target Path: Workspace -> Proximity -> [Model] -> Handle -> Attachment -> BillboardGui -> Name -> TextLabel
        local ProximityFolder = Services.Workspace:WaitForChild("Proximity", 2)
        
        if ProximityFolder then
            -- Kita scan semua TextLabel yang ada di dalam folder Proximity biar akurat
            for _, label in pairs(ProximityFolder:GetDescendants()) do
                if label:IsA("TextLabel") then
                    -- Cek apakah tulisan di label mengandung nama Potion (contoh: "miner potion i")
                    if string.find(string.lower(label.Text), searchKey) then
                        
                        -- Kalau ketemu Text-nya, kita cari Part fisik (Handle) di atasnya buat dituju
                        local HandlePart = label:FindFirstAncestor("Handle") or label:FindFirstAncestorWhichIsA("BasePart")
                        
                        if HandlePart then
                            print("[Shop] Potion ketemu di: " .. HandlePart:GetFullName())
                            return HandlePart.Position
                        end
                    end
                end
            end
        end
    end

    return nil
end

local function BuyShopItem(ItemName, Quantity)
    local TargetPos = FindShopItemPosition(ItemName)
    
    if not TargetPos then
        WindUI:Notify({
            Title = "Lokasi Tidak Ketemu",
            Content = "Gagal cari lokasi '"..ItemName.."'. Pastikan item ada di map/Proximity.",
            Duration = 4,
            Icon = "alert-circle"
        })
        return
    end

    -- Simpan Posisi Awal
    local Char = LocalPlayer.Character
    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
    if not Root then return end

    local OldPos = Root.Position
    local wasFarming = _G_Flags.AutoFarm
    local wasMobbing = _G_Flags.AutoFarmMobs
    
    -- [[ PENTING: MATIKAN FARM & NYALAKAN STATUS BELANJA ]]
    _G_Flags.AutoFarm = false
    _G_Flags.AutoFarmMobs = false
    _G_Flags.IsSellingAction = true -- Flag ini mencegah karakter stuck diam!
    
    WindUI:Notify({ Title = "Otw Shop", Content = "Membeli " .. Quantity .. "x " .. ItemName, Duration = 2 })

    -- 1. Jalan ke Toko
    local arrived = TweenToPosition(TargetPos)
    
    if arrived then
        task.wait(0.5)
        -- 2. Eksekusi Remote Beli
        local PurchaseRemote = Services.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("ProximityService"):WaitForChild("RF"):WaitForChild("Purchase")
        
        if PurchaseRemote then
            local success, err = pcall(function()
                local args = { ItemName, Quantity }
                return PurchaseRemote:InvokeServer(unpack(args))
            end)
            
            if success then
                WindUI:Notify({ Title = "Success", Content = "Berhasil membeli!", Icon = "check", Duration = 3 })
            else
                WindUI:Notify({ Title = "Gagal", Content = "Uang kurang / Error.", Icon = "x-circle", Duration = 3 })
            end
        end
        
        task.wait(0.5)
        -- 3. Pulang
        TweenToPosition(OldPos)
    end

    -- Resume
    _G_Flags.IsSellingAction = false
    if wasFarming then _G_Flags.AutoFarm = true end
    if wasMobbing then _G_Flags.AutoFarmMobs = true end
end

------- [[ UI CONSTRUCTION ]] -------

-------- [[ TAB: HOME / INFO (DEFAULT OPEN) ]] --------
local HomeTab = Window:Tab({ Title = "Home", Icon = "tv-minimal" })

-- Section 1: Community & Info
local InfoSec = HomeTab:Section({ 
    Title = "Community & Support",
    Opened = true,
    Box = true,
})

InfoSec:Section({
    Title = "Welcome to Catraz Hub!",
    TextSize = 24,
})

InfoSec:Section({
    Title = "The best Script Hub for The Forge & Fish It. Join our Discord for the latest updates, giveaways, and support.",
    TextSize = 18,
    TextTransparency = .35,
})

InfoSec:Button({
    Title = "Copy Discord Link",
    Desc = "Click to copy the invite link",
    Callback = function()
        setclipboard("https://discord.gg/XVcWDFCYSu") -- GANTI LINK DISINI
        WindUI:Notify({
            Title = "Copied!",
            Content = "Discord link successfully copied to clipboard.",
            Icon = "copy",
            Duration = 2
        })
    end
})

-- Section 2: Changelog (Update Terbaru)
local ChangeSec = HomeTab:Section({ 
    Title = "Changelog v0.7" ,
    Opened = true,
    Box = true,
})

ChangeSec:Section({
    Title = "What's New?",
    TextSize = 24,
})
ChangeSec:Section({
    Title = "[+] UI Overhaul: New, cleaner & more modern look. \n[+] Performance: Much lighter & faster. \n[+] Added: Mini Dashboard (Status Box) when the menu is minimized. \n[+] Added: Bouncy Toggle Button Animation. \n[+] Fixed: Auto Shop & Selling Logic (Anti-Stuck). \n[+] Fixed: Mining Ore Skip Detection (More accurate).",
    TextSize = 18,
    TextTransparency = .35,
})

-- Section 3: Feature Overview
local FiturSec = HomeTab:Section({ 
    Title = "Feature Overview",
    Opened = true, 
    Box = true,
})

FiturSec:Section({
    Title = "Available Features",
    TextSize = 24,
})

FiturSec:Section({
    Title = "• Auto Farm: Automatic mining with smart filters. \n• Auto Shop: Buy Pickaxe & Potion automatically runs itself. \n• Teleport: Move to any NPC instantly. \n• Minigame: Auto resolver for Forge (Melt, Pour, Hammer). (Buggy) \n• FPS Boost: Potato mode to reduce lag.",
    TextSize = 18,
    TextTransparency = .35,
})

-- 1. Tab Auto
local AutoTab = Window:Tab({ Title = "Auto", Icon = "workflow" })

-- Section 1.1: Mining
local MiningSection = AutoTab:Section({ Title = "Mining Automation" })

MiningSection:Toggle({ 
    Title = "Auto Farm Rocks", 
    Desc = "Start mining nearby rocks", 
    Value = false, 
    Callback = function(Value) 
        _G_Flags.AutoFarm = Value 
        if Value then _G_Flags.AutoFarmMobs = false end 
        if not Value then ResetPhysics() end 
    end 
})

MiningSection:Dropdown({ 
    Title = "Priority Rocks", 
    Desc = "Target MODEL name (Container)", 
    SearchBarEnabled = true,
    Multi = true, 
    AllowNone = true,
    Values = RockNames, 
    Callback = function(Value) _G_Flags.PriorityRocks = Value end 
})

MiningSection:Dropdown({ 
    Title = "Backup Rocks", 
    Desc = "Target if Priority not found", 
    SearchBarEnabled = true,
    Multi = true, 
    AllowNone = true,
    Values = RockNames, 
    Callback = function(Value) _G_Flags.BackupRocks = Value end 
})

MiningSection:Toggle({ 
    Title = "Smart Ore Skip", 
    Desc = "Skip if revealed ORE is bad", 
    Value = true, 
    Callback = function(Value) _G_Flags.OreSkipEnabled = Value end 
})

MiningSection:Dropdown({ 
    Title = "Keep Ores", 
    Desc = "Select Ore/Drop name to KEEP", 
    SearchBarEnabled = true,
    Multi = true, 
    AllowNone = true,
    Values = OreNames, 
    Callback = function(Value) _G_Flags.KeepOres = Value end 
})

MiningSection:Slider({ 
    Title = "Stealth Depth", 
    Desc = "Player Y Offset (Negative = Underground)", 
    Step = 1, 
    Value = { Min = -15, Max = 5, Default = -5 }, 
    Callback = function(Value) _G_Flags.FarmDepth = Value end 
})

-- Section 1.2: Mobs
local MobSection = AutoTab:Section({ Title = "Mob Farming" })
MobSection:Toggle({ 
    Title = "Auto Farm Mobs", 
    Desc = "Start attacking mobs", 
    Value = false, 
    Callback = function(Value) 
        _G_Flags.AutoFarmMobs = Value 
        if Value then _G_Flags.AutoFarm = false end 
        if not Value then ResetPhysics() end 
    end 
})
MobSection:Dropdown({ 
    Title = "Select Mobs", 
    Desc = "Target mobs to attack", 
    SearchBarEnabled = true,
    Multi = true, 
    AllowNone = true,
    Values = MobNames, 
    Callback = function(Value) _G_Flags.SelectedMob = Value end 
})

-- Section 1.3: Sell
local SellSection = AutoTab:Section({ Title = "Auto Sell" })
SellSection:Toggle({
    Title = "Auto Sell Inventory",
    Desc = "Sell when capacity reached",
    Value = false,
    Callback = function(Value) _G_Flags.AutoSell = Value end
})
SellSection:Dropdown({
    Title = "Sell Rarity",
    Desc = "Select rarities to sell",
    SearchBarEnabled = true,
    Multi = true, 
    AllowNone = true,
    Value = {"Common", "Uncommon"},
    Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"},
    Callback = function(Value) _G_Flags.SellRarities = Value end
})
SellSection:Slider({
    Title = "Capacity Trigger",
    Desc = "Trigger sell at X items",
    Step = 1,
    Value = { Min = 10, Max = 500, Default = 45 },
    Callback = function(Value) _G_Flags.SellThreshold = Value end
})
SellSection:Button({ 
    Title = "Sell Now", 
    Callback = function() ProcessAutoSell() end 
})

-- Section 1.4: Forge Minigame
local ForgeSection = AutoTab:Section({ Title = "Forge Minigame" })
ForgeSection:Toggle({ 
    Title = "Legit Auto Minigame", 
    Desc = "Visual helper for Melt/Pour/Hammer", 
    Value = false, 
    Callback = function(Value) _G_Flags.AutoPlayLegit = Value end 
})

-- Section 1.5: Potion
local PotionSection = AutoTab:Section({ Title = "Auto Potion" })
PotionSection:Toggle({ 
    Title = "Auto Heal", 
    Desc = "Use potion when low HP", 
    Value = false, 
    Callback = function(Value) _G_Flags.AutoHeal = Value end 
})
PotionSection:Slider({ 
    Title = "HP Trigger %", 
    Desc = "HP threshold to use potion", 
    Step = 5, 
    Value = { Min = 10, Max = 90, Default = 40 }, 
    Callback = function(Value) _G_Flags.HealPercentage = Value end 
})

-- Section 1.6: Safety Movement
local SafetySection = AutoTab:Section({ Title = "Movement Settings" })
SafetySection:Slider({ 
    Title = "Max Distance", 
    Desc = "Max scanning distance",
    Step = 1, 
    Value = { Min = 50, Max = 2000, Default = 300 }, 
    Callback = function(Value) _G_Flags.MaxDistance = Value end 
})
SafetySection:Slider({ 
    Title = "Tween Speed", 
    Desc = "Flying speed",
    Step = 1, 
    Value = { Min = 50, Max = 500, Default = 100 }, 
    Callback = function(Value) _G_Flags.TweenSpeed = Value end 
})
SafetySection:Button({ 
    Title = "Unstuck / Reset", 
    Desc = "Click if character gets stuck",
    Callback = function() ResetPhysics() end 
})
SafetySection:Toggle({ 
    Title = "Anti Lava (Volcano)", 
    Desc = "Remove 'lavadamagezone' parts", 
    Value = false, 
    Callback = function(Value) 
        ToggleAntiLava(Value)
    end 
})

-- [[ SHOP TAB ]] --
local ShopTab = Window:Tab({ Title = "Shop", Icon = "shopping-cart" })

-- Variable Lokal untuk Dropdown
local SelectedPickaxeShop = nil
local SelectedPotionShop = nil
local PotionBuyQty = 1

-- Section Pickaxes
local PickaxeShopSection = ShopTab:Section({ Title = "Pickaxe Shop" })

PickaxeShopSection:Dropdown({
    Title = "Select Pickaxe",
    Desc = "Pilih Pickaxe yang mau dibeli",
    SearchBarEnabled = true,
    Multi = false,
    Value = nil,
    AllowNone = true,
    Values = ShopPickaxes, -- Mengambil dari list generator tadi
    Callback = function(Value)
        SelectedPickaxeShop = Value
    end
})

PickaxeShopSection:Button({
    Title = "Buy Pickaxe",
    Desc = "Pergi ke lokasi & Beli (Qty: 1)",
    Callback = function()
        if SelectedPickaxeShop then
            BuyShopItem(SelectedPickaxeShop, 1)
        else
            WindUI:Notify({ Title = "Select Item", Content = "Pilih Pickaxe dulu!", Duration = 2 })
        end
    end
})

-- Section Potions
local PotionShopSection = ShopTab:Section({ Title = "Potion Shop" })

PotionShopSection:Dropdown({
    Title = "Select Potion",
    Desc = "Pilih Potion/Extra yang mau dibeli",
    SearchBarEnabled = true,
    Multi = true,
    Value = nil,
    AllowNone = true,
    Values = ShopPotions,
    Callback = function(Value)
        SelectedPotionShop = Value
    end
})

PotionShopSection:Slider({
    Title = "Quantity",
    Desc = "Jumlah yang mau dibeli",
    Step = 1,
    Value = { Min = 1, Max = 100, Default = 1 },
    Callback = function(Value)
        PotionBuyQty = Value
    end
})

PotionShopSection:Button({
    Title = "Buy Potion",
    Desc = "Pergi ke lokasi & Beli",
    Callback = function()
        if SelectedPotionShop then
            BuyShopItem(SelectedPotionShop, PotionBuyQty)
        else
            WindUI:Notify({ Title = "Select Item", Content = "Pilih Potion dulu!", Duration = 2 })
        end
    end
})

-------- [[ PLAYER TAB: FORCE READER ]] --------
local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })

-- 1. DATA STORAGE
local RaceDataMap = {} 
local RaceListClean = {"Loading..."} 

-- 2. FUNGSI PARSER (YANG DIPERBAIKI)
local function ParseRaceData(data, raceName)
    local fullText = ""
    
    -- A. Header Rarity
    if data.Rarity then
        fullText = fullText .. "[ Rarity: " .. tostring(data.Rarity) .. " ]\n\n"
    end
    
    -- B. Coba BACA STATS (Versi Maksa)
    if data.Stats and type(data.Stats) == "table" then
        for i, statInfo in pairs(data.Stats) do
            -- Coba segala kemungkinan nama Key
            local sName = statInfo.Name or statInfo.name or statInfo.Title or ("Stat " .. i)
            local sDesc = statInfo.Description or statInfo.description or statInfo.Desc or statInfo.Info or "..."
            
            fullText = fullText .. "• " .. tostring(sName) .. ": " .. tostring(sDesc) .. "\n"
        end
    end

    -- C. Coba BACA TRAITS (Cadangan kalau Stats kosong/gagal)
    -- Karena di data yang kamu kirim ada table "Traits" juga
    if data.Traits and type(data.Traits) == "table" then
        local traitText = ""
        for _, t in pairs(data.Traits) do
            -- Ambil Id atau Name dari Traits
            local tName = t.Id or t.Name
            if tName then
                -- Coba cari value angkanya (misal: DamageBoost = 10)
                local tVal = ""
                for k,v in pairs(t) do
                    if k ~= "Id" and k ~= "Name" and type(v) == "number" then
                        tVal = tVal .. " (+" .. tostring(v) .. " " .. tostring(k) .. ")"
                    end
                end
                traitText = traitText .. "  > " .. tostring(tName) .. tVal .. "\n"
            end
        end
        
        if traitText ~= "" then
            fullText = fullText .. "\n[ Passive Traits ]:\n" .. traitText
        end
    end

    -- D. Final Check (Kalau kosong melompong)
    if fullText == "" then fullText = "No stats/description data found." end
    
    return fullText
end

-- 3. SCANNER DATA (SAFE MODE)
local function LoadRaceData()
    local TempMap = {}
    local TempList = {}
    
    -- Pakai pcall biar Tab bawah ga ilang kalau error
    pcall(function()
        local RacesFolder = Services.ReplicatedStorage:WaitForChild("Shared", 3):WaitForChild("Data", 3):WaitForChild("Races", 3)
        
        if RacesFolder then
            for _, module in pairs(RacesFolder:GetChildren()) do
                if module:IsA("ModuleScript") then
                    local CleanName = string.gsub(module.Name, "^%d+%s*-%s*", "")
                    
                    local success, mData = pcall(require, module)
                    if success and mData then
                        local desc = ParseRaceData(mData, CleanName)
                        TempMap[CleanName] = desc
                        table.insert(TempList, CleanName)
                    end
                end
            end
        end
    end)

    if #TempList > 0 then
        table.sort(TempList)
        RaceListClean = TempList
        RaceDataMap = TempMap
    else
        RaceListClean = {"Data Error / Kosong"}
    end
end

LoadRaceData()

-- 4. FUNGSI MY RACE
local function GetMyRaceName()
    if PlayerController and PlayerController.Replica and PlayerController.Replica.Data then
        local rawRace = PlayerController.Replica.Data.Race or "Human"
        return string.gsub(rawRace, "^%d+%s*-%s*", "") 
    end
    return "Unknown"
end

-- [[ UI DISPLAY ]] --
local MyStatsSection = PlayerTab:Section({ Title = "My Stats" })
local MyRaceTitle = MyStatsSection:Paragraph({ Title = "Current Race", Content = "Loading..." })

local function RefreshMyStats()
    local myRace = GetMyRaceName()
    MyRaceTitle:SetTitle("Current Race: " .. myRace)
    
    if RaceDataMap[myRace] then
        MyRaceTitle:SetContent(RaceDataMap[myRace])
    else
        MyRaceTitle:SetContent("Stats info tidak tersedia.")
    end
end

MyStatsSection:Button({ Title = "Refresh Info", Callback = RefreshMyStats })
task.delay(1.5, RefreshMyStats)

local LibrarySection = PlayerTab:Section({ Title = "Race Encyclopedia" })
local SelectedInfo = LibrarySection:Paragraph({ Title = "Race Info", Content = "Pilih race untuk melihat detail." })

LibrarySection:Dropdown({
    Title = "Select Race",
    Desc = "Database Stats & Traits",
    Values = RaceListClean,
    Multi = false,
    Default = nil,
    Callback = function(Value)
        if RaceDataMap[Value] then
            SelectedInfo:SetTitle(Value)
            SelectedInfo:SetContent(RaceDataMap[Value])
        end
    end
})

-------- [[ TELEPORT TAB: NPC LIST ]] --------
local TeleportTab = Window:Tab({ Title = "Teleport", Icon = "map" })

-- 1. DATA VARIABLES
local NPCList = {} 

-- 2. FUNGSI SCANNER NPC (Dari Dialogues)
local function RefreshNPCList()
    table.clear(NPCList)
    local DialoguesFolder = Services.ReplicatedStorage:WaitForChild("Dialogues", 5)
    
    if DialoguesFolder then
        for _, folder in pairs(DialoguesFolder:GetChildren()) do
            -- Kita ambil nama foldernya sebagai nama NPC
            table.insert(NPCList, folder.Name)
        end
        table.sort(NPCList)
    else
        table.insert(NPCList, "Error: Folder not found")
    end
end

RefreshNPCList()

-- 3. FUNGSI TELEPORT LOGIC
local function TeleportToNPC(npcName)
    -- Cari NPC di Workspace (Bisa model bernama "npcName" atau folder NPC)
    local TargetParams = {npcName, "Alchemist", "Blacksmith", "Merchant"} -- Tambahan nama umum jika beda
    local TargetPos = nil
    
    -- Cara 1: Cari Nama Persis
    local found = Services.Workspace:FindFirstChild(npcName, true)
    if found then
        TargetPos = found:GetPivot().Position
    else
        -- Cara 2: Cari ProximityPrompt yang parent-nya mirip
        for _, prompt in pairs(Services.Workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                local parent = prompt.Parent
                -- Cek apakah nama NPC ada di dalam nama Parent prompt
                if parent and string.find(string.lower(parent.Name), string.lower(npcName)) then
                     TargetPos = parent.Position
                     break
                end
                
                -- Cek ActionText (Misal: "Talk to Maria")
                if string.find(string.lower(prompt.ActionText), string.lower(npcName)) then
                    TargetPos = parent.Position
                    break
                end
            end
        end
    end

    -- Eksekusi Teleport
    if TargetPos then
        WindUI:Notify({ Title = "Teleport", Content = "Otw ke " .. npcName .. "...", Duration = 3 })
        
        -- Matikan farm sebentar biar ga conflict
        local wasFarming = _G_Flags.AutoFarm
        local wasMobbing = _G_Flags.AutoFarmMobs
        _G_Flags.AutoFarm = false
        _G_Flags.AutoFarmMobs = false
        _G_Flags.IsSellingAction = true -- Pakai flag ini biar loop bawah gak reset physics
        
        local arrived = TweenToPosition(TargetPos)
        
        if arrived then
            WindUI:Notify({ Title = "Arrived", Content = "Sampai di tujuan!", Icon = "check", Duration = 2 })
        end
        
        -- Kembalikan state (tapi user harus nyalain farm lagi manual kalau mau farm)
        _G_Flags.IsSellingAction = false
        -- _G_Flags.AutoFarm = wasFarming (Opsional: Kalau mau otomatis lanjut farm, uncomment ini)
    else
        WindUI:Notify({ Title = "Gagal", Content = "NPC tidak ditemukan di Map!", Icon = "alert-circle", Duration = 3 })
    end
end

-- [[ UI CONSTRUCTION ]] --
local TeleportSection = TeleportTab:Section({ Title = "NPC Teleport" })

local SelectedNPC = nil

TeleportSection:Dropdown({
    Title = "Select NPC",
    Desc = "Daftar NPC dari Dialogues",
    Values = NPCList,
    Multi = false,
    Default = nil,
    Callback = function(Value)
        SelectedNPC = Value
    end
})

TeleportSection:Button({
    Title = "Teleport Now",
    Desc = "Pergi ke lokasi NPC terpilih",
    Callback = function()
        if SelectedNPC then
            TeleportToNPC(SelectedNPC)
        else
            WindUI:Notify({ Title = "Select NPC", Content = "Pilih NPC dulu di dropdown!", Duration = 2 })
        end
    end
})

TeleportSection:Button({
    Title = "Refresh List",
    Desc = "Scan ulang folder Dialogues",
    Callback = function()
        RefreshNPCList()
        WindUI:Notify({ Title = "Refreshed", Content = "List NPC diperbarui.", Duration = 2 })
    end
})

-------- [[ SETTINGS TAB: ESSENTIALS + FPS BOOST ]] --------
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

-- VARIABLES
local _G_Settings = {
    Fullbright = false,
    NoFog = false,
    WalkSpeed = 16,
    JumpPower = 50,
    InfJump = false
}

-- [[ 1. VISUAL ESSENTIALS ]] --
local VisualSection = SettingsTab:Section({ Title = "Visuals & Performance" })

VisualSection:Button({
    Title = "FPS Boost (Potato Mode)",
    Desc = "Hapus tekstur & efek biar ringan (Anti-Lag)",
    Callback = function()
        -- Konfirmasi visual
        WindUI:Notify({ Title = "FPS Boost", Content = "Mengoptimalkan grafis...", Duration = 2 })
        
        -- 1. Optimasi Global Lighting
        local Terrain = workspace:FindFirstChildOfClass("Terrain")
        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 0
        end
        
        local Lighting = game:GetService("Lighting")
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        settings().Rendering.QualityLevel = 1 -- Set quality level ke terendah secara internal
        
        -- Hapus efek post-processing (Bloom, Blur, SunRays)
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Cloud") then
                v:Destroy()
            end
        end

        -- 2. Optimasi Part & Material (Looping Workspace)
        for _, v in pairs(game:GetService("Workspace"):GetDescendants()) do
            -- Ubah Part jadi plastik
            if v:IsA("BasePart") and not v:IsA("Terrain") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
                v.CastShadow = false
                v.TopSurface = Enum.SurfaceType.Smooth
            end
            
            -- Hapus Texture & Decal pada object
            if v:IsA("Decal") or v:IsA("Texture") then
                v:Destroy()
            end
            
            -- Matikan Partikel (Asap, Api, Sparkle)
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                v.Enabled = false
            end
        end
        
        WindUI:Notify({ Title = "Success", Content = "FPS Boost Aktif! Grafik jadi kentang.", Icon = "check", Duration = 3 })
    end
})

VisualSection:Toggle({
    Title = "Fullbright",
    Desc = "Bikin map jadi terang (Anti-Gelap)",
    Value = false,
    Callback = function(Value)
        _G_Settings.Fullbright = Value
        if Value then
            task.spawn(function()
                while _G_Settings.Fullbright do
                    game:GetService("Lighting").Brightness = 2
                    game:GetService("Lighting").ClockTime = 14
                    game:GetService("Lighting").GlobalShadows = false
                    game:GetService("Lighting").Ambient = Color3.fromRGB(255, 255, 255)
                    game:GetService("Lighting").OutdoorAmbient = Color3.fromRGB(255, 255, 255)
                    task.wait(1)
                end
            end)
        end
    end
})

VisualSection:Toggle({
    Title = "No Fog",
    Desc = "Hapus kabut biar pandangan jauh",
    Value = false,
    Callback = function(Value)
        _G_Settings.NoFog = Value
        if Value then
            game:GetService("Lighting").FogEnd = 100000
            for _, v in pairs(game:GetService("Lighting"):GetDescendants()) do
                if v:IsA("Atmosphere") then v:Destroy() end
            end
        else
            game:GetService("Lighting").FogEnd = 500
        end
    end
})

-- [[ 2. CHARACTER MODIFIERS ]] --
local CharSection = SettingsTab:Section({ Title = "Character" })

CharSection:Slider({
    Title = "Walk Speed",
    Desc = "Kecepatan jalan manual",
    Step = 1,
    Value = { Min = 16, Max = 200, Default = 16 },
    Callback = function(Value)
        _G_Settings.WalkSpeed = Value
        local Char = LocalPlayer.Character
        if Char and Char:FindFirstChild("Humanoid") then
            Char.Humanoid.WalkSpeed = Value
        end
    end
})

CharSection:Slider({
    Title = "Jump Power",
    Desc = "Kekuatan lompat",
    Step = 1,
    Value = { Min = 50, Max = 300, Default = 50 },
    Callback = function(Value)
        _G_Settings.JumpPower = Value
        local Char = LocalPlayer.Character
        if Char and Char:FindFirstChild("Humanoid") then
            Char.Humanoid.UseJumpPower = true
            Char.Humanoid.JumpPower = Value
        end
    end
})

CharSection:Toggle({
    Title = "Infinite Jump",
    Desc = "Lompat di udara berkali-kali",
    Value = false,
    Callback = function(Value)
        _G_Settings.InfJump = Value
    end
})

-- Logic Loop Character (Biar permanen walau mati)
task.spawn(function()
    Services.UserInputService.JumpRequest:Connect(function()
        if _G_Settings.InfJump then
            local Char = LocalPlayer.Character
            if Char and Char:FindFirstChild("Humanoid") then
                Char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)

    while true do
        task.wait(1)
        local Char = LocalPlayer.Character
        if Char and Char:FindFirstChild("Humanoid") then
            if Char.Humanoid.WalkSpeed ~= _G_Settings.WalkSpeed and _G_Settings.WalkSpeed > 16 then
                Char.Humanoid.WalkSpeed = _G_Settings.WalkSpeed
            end
            if Char.Humanoid.JumpPower ~= _G_Settings.JumpPower and _G_Settings.JumpPower > 50 then
                Char.Humanoid.UseJumpPower = true
                Char.Humanoid.JumpPower = _G_Settings.JumpPower
            end
        end
    end
end)

-- [[ 3. SYSTEM / GAME ]] --
local SystemSection = SettingsTab:Section({ Title = "System" })

SystemSection:Button({
    Title = "Rejoin Server",
    Desc = "Masuk ulang ke server yang sama",
    Callback = function()
        local ts = game:GetService("TeleportService")
        local p = game:GetService("Players").LocalPlayer
        ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, p)
    end
})

SystemSection:Button({
    Title = "Server Hop",
    Desc = "Pindah ke server lain (Cari server baru)",
    Callback = function()
        WindUI:Notify({ Title = "Server Hop", Content = "Mencari server kosong...", Duration = 3 })
        local Http = game:GetService("HttpService")
        local TPS = game:GetService("TeleportService")
        local Api = "https://games.roblox.com/v1/games/"
        local PlaceId = game.PlaceId
        local _servers = Api..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
        
        local function ListServers(cursor)
            local Raw = game:HttpGet(_servers .. ((cursor and "&cursor="..cursor) or ""))
            return Http:JSONDecode(Raw)
        end
        
        local Server, Next; repeat
            local Servers = ListServers(Next)
            Server = Servers.data[1]
            Next = Servers.nextPageCursor
        until Server
        
        TPS:TeleportToPlaceInstance(PlaceId, Server.id, game.Players.LocalPlayer)
    end
})

SettingsTab:Button({
    Title = "Unload UI (Clean)",
    Desc = "Remove Menu, Dashboard, & Buttons",
    Callback = function()
        -- 1. Matikan Semua Fitur
        _G_Flags.AutoFarm = false
        _G_Flags.AutoFarmMobs = false
        _G_Flags.IsSellingAction = false
        
        local CoreGui = game:GetService("CoreGui")
        
        -- 2. HAPUS CUSTOM UI KITA (Dashboard & Tombol)
        if CoreGui:FindFirstChild("CatrazHubSystem") then
            CoreGui["CatrazHubSystem"]:Destroy()
        end
        
        -- 3. HAPUS WIND UI (Cara Correct)
        -- Kita coba panggil fungsi destroy bawaan librarynya.
        -- Biasanya WindUI punya fungsi ini untuk membersihkan dirinya sendiri.
        if Window and Window.Destroy then
            Window:Destroy()
        elseif WindUI and WindUI.Destroy then
            WindUI:Destroy()
        end

        -- Notifikasi Terakhir
        Services.StarterGui:SetCore("SendNotification", {
            Title = "Catraz Hub",
            Text = "Unloaded Successfully!",
            Duration = 2
        })
    end
})

-- [[ 4. ANTI AFK ]] --
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

------- [[ LOGIC LOOPS (WORKERS) ]] -------

------- SUPER NOCLIP SYSTEM --------
Services.RunService.Stepped:Connect(function()
    if (_G_Flags.AutoFarm or _G_Flags.AutoFarmMobs or _G_Flags.IsSellingAction) and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- LOOP 1: Auto Sell Check
task.spawn(function()
    while true do
        task.wait(1)
        if _G_Flags.AutoSell then
            local currentItems = GetTotalItems()
            if currentItems >= _G_Flags.SellThreshold then
                ProcessAutoSell()
                task.wait(3) 
            end
        end
    end
end)

-- LOOP 2: Auto Heal
task.spawn(function() 
    while true do 
        task.wait(0.5) 
        if _G_Flags.AutoHeal then 
            local Char = LocalPlayer.Character
            if Char then
                local Hum = Char:FindFirstChild("Humanoid")
                if Hum and Hum.Health > 0 and (Hum.Health/Hum.MaxHealth)*100 <= _G_Flags.HealPercentage then
                   local P = GetTool("HealthPotion2") or GetTool("HealthPotion1")
                   if P then Hum:EquipTool(P) task.wait(0.5) ActivateTool(P.Name) task.wait(1.5) end
                end
            end
        end 
    end 
end)

-- LOOP 3: Legit Forge Minigame Solvers
local isPumpingMelt, isHoldingPour = false, false
local function SolveMelt()
    local MeltUI = PlayerGui:FindFirstChild("Forge") and PlayerGui.Forge:FindFirstChild("MeltMinigame")
    if MeltUI and MeltUI.Visible and not isPumpingMelt then
        isPumpingMelt = true
        task.spawn(function()
            local Heater = MeltUI:WaitForChild("Heater", 1)
            if Heater and Heater:FindFirstChild("Top") then
                local Top = Heater.Top
                while MeltUI.Visible and _G_Flags.AutoPlayLegit do
                    local absPos, absSize = Top.AbsolutePosition, Top.AbsoluteSize
                    local centerX, centerY = absPos.X + absSize.X/2, absPos.Y + absSize.Y + 30
                    Services.VirtualInputManager:SendMouseMoveEvent(centerX, centerY, game) task.wait(0.1)
                    Services.VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1) task.wait(0.1)
                    for i = 1, 5 do if not MeltUI.Visible then break end
                        Services.VirtualInputManager:SendMouseMoveEvent(centerX, centerY + (250 * (i/5)), game) task.wait(0.01)
                    end
                    Services.VirtualInputManager:SendMouseButtonEvent(centerX, centerY + 250, 0, false, game, 1) task.wait(0.15)
                end
            end
            isPumpingMelt = false
        end)
    elseif not MeltUI or not MeltUI.Visible then isPumpingMelt = false end
end

local function SolvePour()
    local PourUI = PlayerGui:FindFirstChild("Forge") and PlayerGui.Forge:FindFirstChild("PourMinigame")
    if PourUI and PourUI.Visible and PourUI:FindFirstChild("Frame") then
        local Line, Area = PourUI.Frame:FindFirstChild("Line"), PourUI.Frame:FindFirstChild("Area")
        if Line and Area then
            local lineY, targetY = Line.AbsolutePosition.Y, Area.AbsolutePosition.Y + (Area.AbsoluteSize.Y/2)
            if lineY > targetY + 10 then if not isHoldingPour then Services.VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1) isHoldingPour = true end
            elseif lineY < targetY - 10 then if isHoldingPour then Services.VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1) isHoldingPour = false end end
        end
    elseif isHoldingPour then Services.VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1) isHoldingPour = false end
end

local function SolveHammer()
    local HammerUI = PlayerGui:FindFirstChild("Forge") and PlayerGui.Forge:FindFirstChild("HammerMinigame")
    if HammerUI and HammerUI.Visible then
        for _, child in pairs(HammerUI:GetChildren()) do
            if child:IsA("TextButton") and child:FindFirstChild("Frame") and child.Frame:FindFirstChild("Border") then
                if child.Frame.Border.ImageColor3.G > 0.9 then
                    local p, s = child.AbsolutePosition, child.AbsoluteSize
                    local cx, cy = p.X + s.X/2, p.Y + s.Y/2
                    Services.VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
                    Services.VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 1) task.wait(0.2)
                end
            end
        end
    end
end
Services.RunService.RenderStepped:Connect(function() if _G_Flags.AutoPlayLegit then SolveMelt() SolvePour() SolveHammer() end end)

-- [[ AUTO RESUME LISTENER ]] --
local function OnCharacterAdded(newChar)
    task.wait(1) -- Tunggu loading character
    if _G_Flags.AutoFarm or _G_Flags.AutoFarmMobs then
        -- Opsional: Teleport balik ke spot terakhir mining jika kamu simpan posisinya
        print("[Catraz] Character Respawned, resuming farm...")
    end
end

Services.Players.LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

-- LOOP 4: Main Farming Loop (FINAL FIX)
task.spawn(function()
    while true do
        task.wait() 
        local Char = LocalPlayer.Character
        if not Char or not Char:FindFirstChild("HumanoidRootPart") or not Char:FindFirstChild("Humanoid") then
            task.wait(1) -- Tunggu spawn
            continue -- Skip loop ini dan ulang cek
        end
        local Root = Char and Char:FindFirstChild("HumanoidRootPart")
        local Hum = Char and Char:FindFirstChild("Humanoid")

        if Root and Hum and Hum.Health > 0 then
            -- AUTO MINING
            if _G_Flags.AutoFarm then
                if _G_Flags.AutoEquip and not Char:FindFirstChild("Pickaxe") then
                    local tool = GetTool("Pickaxe")
                    if tool then Hum:EquipTool(tool) end
                end
                
                local Target = GetActiveRock()
                
                if Target then
                    local stealthPos = Target.Position + Vector3.new(0, _G_Flags.FarmDepth, 0)
                    local arrived = TweenToPosition(stealthPos)
                    if arrived then
                        ToggleFloat(true) 
                        local lastHit = 0
                        
                        while _G_Flags.AutoFarm and Target.Model.Parent ~= nil and Target.Model:FindFirstChild("Hitbox") do
                            if not Char or not Root or Hum.Health <= 0 then break end
                            if (Root.Position - Target.Position).Magnitude > 30 then break end 
                            
                            -- [[ SKIP ORE LOGIC (FIXED) ]] --
                            if _G_Flags.OreSkipEnabled then
                                -- 1. Ambil HP dari Attributes
                                local currentHP = Target.Model:GetAttribute("Health") or 100
                                local maxHP = Target.Model:GetAttribute("MaxHealth") or 100
                                local hpPercent = currentHP / maxHP
                                
                                -- 2. Cek jika HP < 55% (Ore Reveal Phase)
                                if hpPercent <= 0.55 then
                                    local revealedOreName = CheckRevealedOre(Target.Model)
                                    if revealedOreName then
                                        -- Cek apakah nama ore ada di list "Keep Ores"
                                        if not IsTargetValid(revealedOreName, _G_Flags.KeepOres) then
                                            print("[Catraz] Skipping Bad Ore: " .. revealedOreName)
                                            -- Masukkan ke blacklist agar pindah batu
                                            TempBlacklist[Target.Model] = tick()
                                            break 
                                        end
                                    end
                                end
                            end

                            -- [[ ANTI-CLAIM LOGIC (FIXED) ]] --
                            if IsRockClaimed(Target.Model) then
                                print("[Catraz] Skipping Claimed Rock")
                                TempBlacklist[Target.Model] = tick()
                                break 
                            end
                            ----------------------------

                            Root.CFrame = CFrame.lookAt(stealthPos, Target.Position)
                            if tick() - lastHit > 0.25 then ActivateTool("Pickaxe") lastHit = tick() end
                            task.wait()
                        end
                    end
                else ToggleFloat(false) task.wait(1) end
            
            -- AUTO MOB FARMING
            elseif _G_Flags.AutoFarmMobs then
                if _G_Flags.AutoEquip then
                    local tool = GetTool("Sword") or GetTool("Blade") or GetTool("Weapon")
                    if not tool then for _, t in pairs(LocalPlayer.Backpack:GetChildren()) do if t:IsA("Tool") and not string.find(t.Name, "Pickaxe") then tool = t break end end end
                    if tool and tool.Parent ~= Char then Hum:EquipTool(tool) end
                end
                local Mob = GetActiveMob()
                if Mob and Mob:FindFirstChild("HumanoidRootPart") then
                    local MobRoot = Mob.HumanoidRootPart
                    local targetPos = MobRoot.Position + Vector3.new(0, _G_Flags.FarmDepth, 0)
                    local dist = (Root.Position - MobRoot.Position).Magnitude
                    if dist > 10 then TweenToPosition(targetPos)
                    else
                        ToggleFloat(true)
                        local lastHit = 0
                        while _G_Flags.AutoFarmMobs and Mob.Parent and Mob.Humanoid.Health > 0 do
                            if not Char or not Root or Hum.Health <= 0 then break end
                            local currentMobPos = MobRoot.Position
                            local myStealthPos = currentMobPos + Vector3.new(0, _G_Flags.FarmDepth, 0)
                            Root.CFrame = CFrame.lookAt(myStealthPos, currentMobPos)
                            if tick() - lastHit > 0.25 then ActivateTool("Weapon") lastHit = tick() end
                            if (Root.Position - MobRoot.Position).Magnitude > 20 then break end
                            Services.RunService.Heartbeat:Wait()
                        end
                    end
                else ToggleFloat(false) task.wait(1) end
            
            -----------------------------------------------------------
            -- SISIPKAN INI DI SINI (JANGAN DIHAPUS, INI PENYELAMATNYA)
            -----------------------------------------------------------
            elseif _G_Flags.IsSellingAction then
                 -- Diamkan logic ini. Biarkan fungsi Shop yang mengontrol karakter.
                 task.wait(0.1) 
            -----------------------------------------------------------

            else 
                ResetPhysics() -- Bagian ini bikin stuck kalau "SellingAction" tidak ditambahkan di atasnya
                task.wait(1) 
            end
        end
    end
end)
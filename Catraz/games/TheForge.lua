-------- WindUI Loadstring --------
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-------- [[ CORE VARIABLES & SERVICES ]] --------
-- Kita load variable dulu sebelum UI biar Dropdown ada isinya
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

-- [[ SETUP DATA ]] --
local RockNames = {
    "All", "Pebble", "Rock", "Boulder", "Basalt Rock", 
    "Basalt Core", "Basalt Vein", "Volcanic Rock", 
    "Lucky Block", "Iron", "Gold"
}

local MobNames = {"All"}
pcall(function()
    local MobAssets = Services.ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Mobs")
    for _, mob in pairs(MobAssets:GetChildren()) do table.insert(MobNames, mob.Name) end
end)

-- [[ FLAGS (SETTINGS) ]] --
local _G_Flags = {
    AutoFarm = false,
    AutoEquip = true,
    SelectedRock = {"All"}, 
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
    IsSellingAction = false 
}

-- [[ RARITY DATABASE FIX ]] --
local RarityDatabase = {
    ["Stone"] = "Common", ["Pebble"] = "Common", ["Rock"] = "Common", ["Coal"] = "Common", ["Copper"] = "Common",
    ["Iron"] = "Uncommon", ["Tin"] = "Uncommon", ["Gold"] = "Rare", ["Mithril"] = "Rare", ["Cobalt"] = "Rare",
    ["Adurite"] = "Epic", ["Obsidian"] = "Epic", ["Adamantite"] = "Legendary", ["Runite"] = "Legendary"
} 

task.spawn(function()
    local Shared = Services.ReplicatedStorage:WaitForChild("Shared", 5)
    local Data = Shared and Shared:WaitForChild("Data", 5)
    local OreFolder = Data and Data:FindFirstChild("Ore")
    if OreFolder then
        for _, categoryFolder in pairs(OreFolder:GetChildren()) do
            if categoryFolder:IsA("Folder") then
                for _, itemModule in pairs(categoryFolder:GetChildren()) do
                    if itemModule:IsA("ModuleScript") then
                        local success, data = pcall(require, itemModule)
                        if success and data then
                            RarityDatabase[data.Name or itemModule.Name] = data.Rarity or "Common"
                        end
                    end
                end
            end
        end
    end
end)

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
    PopupBackground = Color3.fromHex("#1a0b0b"),
    PopupTitle = Color3.fromHex("#fcfcfc"),
    PopupContent = Color3.fromHex("#ffe5e5"),
    PopupIcon = Color3.fromHex("#ff5e5e"),
    DialogBackground = Color3.fromHex("#1a0b0b"),
    DialogTitle = Color3.fromHex("#fcfcfc"),
    DialogContent = Color3.fromHex("#ffe5e5"),
    DialogIcon = Color3.fromHex("#ff5e5e"),
    Toggle = Color3.fromHex("#fcfcfc"), 
    ToggleBar = Color3.fromHex("#3d1a1a"),
    Checkbox = Color3.fromHex("#fcfcfc"),
    CheckboxIcon = Color3.fromHex("#1a0b0b"), 
    Slider = Color3.fromHex("#fcfcfc"),
    SliderThumb = Color3.fromHex("#ff5e5e"), 
})

WindUI:Gradient({
    ["0"]   = { Color = Color3.fromHex("#2e1212"), Transparency = 0.8 }, 
    ["100"] = { Color = Color3.fromHex("#0f0505"), Transparency = 0.8 }, 
}, { Rotation = 45 })

WindUI:SetTheme("Native Red")

local Window = WindUI:CreateWindow({
    Title = "Catraz Hub | The Forge",
    Folder = "chub",
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
            { -- PlatoBoost
                Type = "platoboost",                                
                ServiceId = 15690, -- service id
                Secret = "6b58c208-1a3e-4085-81f8-44a0ed290b88", -- platoboost secret
            },                                                      
        },                                                          
    },                                                              
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
            print("clicked")
        end,
    },
})

WindUI:Notify({
    Title = "Catraz Hub Loaded",
    Content = "Success load Catraz Hub, detected game The Forge",
    Duration = 5,
    Icon = "badge-check", -- Ikon centang
})

-- [[ CUSTOM TOGGLE UI SYSTEM V3 ]] --
task.spawn(function()
    local CoreGui = game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")
    local NameUI = "CatrazHubButton"
    if CoreGui:FindFirstChild(NameUI) then CoreGui[NameUI]:Destroy() end
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = NameUI
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false
    
    local ToggleBtn = Instance.new("ImageButton")
    ToggleBtn.Name = "MainButton"
    ToggleBtn.Parent = ScreenGui
    ToggleBtn.Position = UDim2.new(0.1, 0, 0.2, 0)
    ToggleBtn.Size = UDim2.new(0, 60, 0, 60)
    ToggleBtn.BackgroundColor3 = Color3.new(0, 0, 0)
    ToggleBtn.BackgroundTransparency = 0 
    ToggleBtn.Draggable = true
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(1, 0)
    BtnCorner.Parent = ToggleBtn

    local IconImage = Instance.new("ImageLabel")
    IconImage.Parent = ToggleBtn
    IconImage.BackgroundTransparency = 1 
    IconImage.AnchorPoint = Vector2.new(0.5, 0.5)
    IconImage.Position = UDim2.new(0.5, 0, 0.5, 0)
    IconImage.Size = UDim2.new(1, 0, 1, 0)
    IconImage.Image = "rbxassetid://124162045221605"
    IconImage.ScaleType = Enum.ScaleType.Crop
    
    local ImageCorner = Instance.new("UICorner")
    ImageCorner.CornerRadius = UDim.new(1, 0)
    ImageCorner.Parent = IconImage

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Parent = ToggleBtn
    UIStroke.Color = Color3.fromHex("#ff5e5e")
    UIStroke.Thickness = 3
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    ToggleBtn.MouseButton1Click:Connect(function()
        Window:Toggle()
        ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
        TweenService:Create(ToggleBtn, TweenInfo.new(0.15, Enum.EasingStyle.Back), {Size = UDim2.new(0, 60, 0, 60)}):Play()
    end)
end)

------- [[ LOGIC FUNCTIONS ]] -------
-- Didefinisikan di sini agar bisa dipanggil oleh UI
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

local function GetActiveRock()
    local closestRock, shortestDistance = nil, math.huge
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    for _, obj in pairs(RocksFolder:GetDescendants()) do
        if obj.Name == "Hitbox" and obj.Parent then
            local rockModel, orePos = obj.Parent, obj:FindFirstChild("OrePosition")
            if orePos and rockModel:IsA("Model") then
                if IsTargetValid(rockModel.Name, _G_Flags.SelectedRock) then
                    local targetPos = (orePos:IsA("BasePart") and orePos.Position) or (orePos:IsA("Attachment") and orePos.WorldPosition)
                    if targetPos then
                        local dist = (myRoot.Position - targetPos).Magnitude
                        if dist < _G_Flags.MaxDistance and dist < shortestDistance then
                            closestRock = { Model = rockModel, Position = targetPos }
                            shortestDistance = dist
                        end
                    end
                end
            end
        end
    end
    return closestRock
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
    if not Inventory then 
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Auto Sell", Text = "Inventory belum ter-load!", Duration = 3 })
        return 
    end

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

            game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Auto Sell", Text = "OTW Jual " .. totalQty .. " items...", Duration = 2 })
            
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
                        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Auto Sell", Text = "Terjual!", Duration = 3 })
                    end)
                end
                task.wait(0.5)
                TweenToPosition(OldPos) 
            end
            
            _G_Flags.IsSellingAction = false
            if wasFarming then _G_Flags.AutoFarm = true end
            if wasMobbing then _G_Flags.AutoFarmMobs = true end
        else
            game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Auto Sell", Text = "NPC Greedy Cey tidak ketemu!", Duration = 3 })
        end
    else
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Auto Sell", Text = "Tidak ada item untuk dijual (Cek Filter).", Duration = 3 })
    end
end

------- [[ UI CONSTRUCTION ]] -------

-- 1. Tab Auto
local AutoTab = Window:Tab({ Title = "Auto", Icon = "workflow" })

-- Section 1.1: Mining
local MiningSection = AutoTab:Section({ Title = "Automation Mining Ore" })
MiningSection:Toggle({ 
    Title = "Toggle Auto Farm", 
    Desc = "Otomatis menambang batu di sekitar", 
    Value = false, 
    Callback = function(Value) 
        _G_Flags.AutoFarm = Value 
        if Value then _G_Flags.AutoFarmMobs = false end 
        if not Value then ResetPhysics() end 
    end 
})
MiningSection:Dropdown({ 
    Title = "Pilih Batu", 
    Desc = "Target batu yang ingin ditambang", 
    Multi = true, 
    Default = {"All"}, 
    Values = RockNames, 
    Callback = function(Value) _G_Flags.SelectedRock = Value end 
})
MiningSection:Slider({ 
    Title = "Stealth Depth", 
    Desc = "Posisi player (Minus = Bawah Tanah)", 
    Step = 1, 
    Value = { Min = -15, Max = 5, Default = -8 }, 
    Callback = function(Value) _G_Flags.FarmDepth = Value end 
})

-- Section 1.2: Mobs
local MobSection = AutoTab:Section({ Title = "Automation Mobs Farming" })
MobSection:Toggle({ 
    Title = "Toggle Auto Farm Mobs", 
    Desc = "Otomatis menyerang monster", 
    Value = false, 
    Callback = function(Value) 
        _G_Flags.AutoFarmMobs = Value 
        if Value then _G_Flags.AutoFarm = false end 
        if not Value then ResetPhysics() end 
    end 
})
MobSection:Dropdown({ 
    Title = "Pilih Mob", 
    Desc = "Target monster yang ingin dilawan", 
    Multi = true, 
    Default = {"All"}, 
    Values = MobNames, 
    Callback = function(Value) _G_Flags.SelectedMob = Value end 
})

-- Section 1.3: Sell
local SellSection = AutoTab:Section({ Title = "Automation Sell" })
SellSection:Toggle({
    Title = "Toggle Auto Sell Inventory",
    Desc = "Jual item saat tas penuh",
    Value = false,
    Callback = function(Value) _G_Flags.AutoSell = Value end
})
SellSection:Dropdown({
    Title = "Pilih Rarity",
    Desc = "Kualitas item yang akan dijual",
    Multi = true, 
    Default = {"Common", "Uncommon"},
    Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"},
    Callback = function(Value) _G_Flags.SellRarities = Value end
})
SellSection:Slider({
    Title = "Trigger Jumlah Item",
    Desc = "Jual jika item mencapai jumlah ini",
    Step = 1,
    Value = { Min = 10, Max = 500, Default = 45 },
    Callback = function(Value) _G_Flags.SellThreshold = Value end
})
SellSection:Button({ 
    Title = "Jual Sekarang", 
    Callback = function() ProcessAutoSell() end 
})

-- Section 1.4: Forge Minigame
local ForgeSection = AutoTab:Section({ Title = "Automation Forge Minigame" })
ForgeSection:Toggle({ 
    Title = "Legit Auto Minigame", 
    Desc = "Bantuan visual otomatis untuk minigame forging", 
    Value = false, 
    Callback = function(Value) _G_Flags.AutoPlayLegit = Value end 
})

-- Section 1.5: Potion
local PotionSection = AutoTab:Section({ Title = "Automation Potion" })
PotionSection:Toggle({ 
    Title = "Autoheal Potion", 
    Desc = "Otomatis minum potion", 
    Value = false, 
    Callback = function(Value) _G_Flags.AutoHeal = Value end 
})
PotionSection:Slider({ 
    Title = "Trigger HP%", 
    Desc = "Batas HP untuk menggunakan potion", 
    Step = 5, 
    Value = { Min = 10, Max = 90, Default = 40 }, 
    Callback = function(Value) _G_Flags.HealPercentage = Value end 
})

-- Section 1.6: Safety Movement
local SafetySection = AutoTab:Section({ Title = "Safety Movement" })
SafetySection:Slider({ 
    Title = "Max Distance", 
    Desc = "Jarak maksimal deteksi target",
    Step = 1, 
    Value = { Min = 50, Max = 2000, Default = 300 }, 
    Callback = function(Value) _G_Flags.MaxDistance = Value end 
})
SafetySection:Slider({ 
    Title = "Kecepatan Tween", 
    Desc = "Kecepatan terbang ke target",
    Step = 1, 
    Value = { Min = 50, Max = 500, Default = 100 }, 
    Callback = function(Value) _G_Flags.TweenSpeed = Value end 
})
SafetySection:Button({ 
    Title = "Emergency Stuck", 
    Desc = "Reset karakter jika nyangkut",
    Callback = function() ResetPhysics() end 
})

-- 2. Tab Misc
local MiscTab = Window:Tab({ Title = "Misc", Icon = "backpack" })
MiscTab:Keybind({ 
    Title = "Hide Menu", 
    Desc = "Tombol sembunyi UI (Default: Right Ctrl)", 
    Default = Enum.KeyCode.RightControl, 
    Callback = function() Window:Toggle() end 
})

-- 3. Tab Shop (Empty)
local ShopTab = Window:Tab({ Title = "Shop", Icon = "shopping-cart" })
-- ShopTab:Section({ Title = "Coming Soon" }) -- Optional: Biar ga kosong melompong

-- 4. Tab Player (Empty)
local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })

-- 5. Tab Teleport (Empty)
local TeleportTab = Window:Tab({ Title = "Teleport", Icon = "map" })

-- 6. Tab Settings (Empty)
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })


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

-- LOOP 4: Main Farming Loop
task.spawn(function()
    while true do
        task.wait() 
        local Char = LocalPlayer.Character
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
            end
        else ResetPhysics() task.wait(1) end
    end
end)
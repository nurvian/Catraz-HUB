-------- Window / UI Library --------
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Catraz Hub | The Forge",
    Author = "by Graywolf",
    Folder = "chub",
    Icon = "swords", 
    IconSize = 22*2,
    NewElements = true,
    HideSearchBar = false,
    OpenButton = {
        Title = "Open Hub", 
        CornerRadius = UDim.new(1,0), 
        StrokeThickness = 3, 
        Enabled = false, 
        Draggable = true,
        OnlyMobile = false,
        Color = ColorSequence.new(Color3.fromHex("#fc03f8"), Color3.fromHex("#db03fc"))
    },
    KeySystem = {
        Title = "Key System",
        Note = "Key: 1234",
        KeyValidator = function(EnteredKey) return EnteredKey == "1234" end
    }
})

-- [[ CUSTOM TOGGLE UI SYSTEM ]] --
task.spawn(function()
    -- 1. Siapkan Variable
    local CoreGui = game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")
    
    -- Hapus UI lama jika ada (biar gak numpuk pas execute ulang)
    if CoreGui:FindFirstChild("GraywolfCustomUI") then
        CoreGui.GraywolfCustomUI:Destroy()
    end

    -- 2. Buat ScreenGui Utama
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "GraywolfCustomUI"
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- 3. Buat Tombol (ImageButton)
    local ToggleBtn = Instance.new("ImageButton")
    ToggleBtn.Name = "ToggleBtn"
    ToggleBtn.Parent = ScreenGui
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- Warna Background Gelap
    ToggleBtn.Position = UDim2.new(0.1, 0, 0.1, 0) -- Posisi Awal (Kiri Atas)
    ToggleBtn.Size = UDim2.new(0, 50, 0, 50) -- Ukuran 50x50 Pixel
    ToggleBtn.Image = "rbxassetid://124162045221605" -- [[ GANTI ID GAMBAR DISINI ]]
    ToggleBtn.Active = true
    ToggleBtn.Draggable = true -- Fitur bawaan biar bisa digeser user
    ToggleBtn.BorderSizePixel = 0

    -- 4. Hiasan (Biar Bulat & Ada Garis Pinggir)
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(1, 0) -- 1 = Bulat Sempurna
    UICorner.Parent = ToggleBtn

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromHex("#fc03f8") -- Warna Pink (Sesuai tema scriptmu)
    UIStroke.Thickness = 2
    UIStroke.Parent = ToggleBtn
    
    -- Efek Glow/Shadow (Optional)
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.Parent = ToggleBtn
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    Shadow.Size = UDim2.new(1, 15, 1, 15)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://6015897843"
    Shadow.ImageColor3 = Color3.fromHex("#fc03f8")
    Shadow.ImageTransparency = 0.6
    Shadow.ZIndex = 0

    -- 5. Fungsi Klik (Logika Utama)
    local isOpen = true -- Status awal Window
    
    ToggleBtn.MouseButton1Click:Connect(function()
        -- Panggil fungsi Toggle bawaan WindUI
        Window:Toggle()
        
        -- Animasi Tombol saat diklik (Efek membal)
        ToggleBtn.Size = UDim2.new(0, 40, 0, 40)
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Size = UDim2.new(0, 50, 0, 50)}):Play()
    end)
    
    -- (Optional) Sembunyikan tombol saat Key System muncul
    -- Karena WindUI KeySystem nge-block layar, tombol ini aman tetap ada.
end)

------- Tabs --------
local MainTab = Window:Tab({ Title = "Main", Icon = "home" })
local MobTab = Window:Tab({ Title = "Mobs", Icon = "skull" }) 
local ForgeTab = Window:Tab({ Title = "Forging", Icon = "flame" })
local SellTab = Window:Tab({ Title = "Selling", Icon = "circle-dollar-sign" }) 
local MiscTab = Window:Tab({ Title = "Misc", Icon = "settings" })

-- Sections
local FarmSection = MainTab:Section({ Title = "Auto Mining" })
local FilterSection = MainTab:Section({ Title = "Rock Settings" })
local StealthSection = MainTab:Section({ Title = "Stealth Mode" }) 
local MobSection = MobTab:Section({ Title = "Auto Mob Farming" }) 
local MobFilterSection = MobTab:Section({ Title = "Mob Settings" })
local ForgeSection = ForgeTab:Section({ Title = "Legit Auto Minigame", Opened = true })
local SellSection = SellTab:Section({ Title = "Auto Sell Settings" }) 
local SurvivalSection = MiscTab:Section({ Title = "Survival (Auto Heal)" })
local SpeedSection = MiscTab:Section({ Title = "Movement / Safety" })
local UnstuckSection = MiscTab:Section({ Title = "Emergency" }) 

------- Core Variables --------
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

-- [[ RARITY DATABASE FIX (DEEP SCAN) ]] --
local RarityDatabase = {
    -- Hardcode Backup (Jaga-jaga kalau scan telat)
    ["Stone"] = "Common", ["Pebble"] = "Common", ["Rock"] = "Common", ["Coal"] = "Common", ["Copper"] = "Common",
    ["Iron"] = "Uncommon", ["Tin"] = "Uncommon", ["Gold"] = "Rare", ["Mithril"] = "Rare", ["Cobalt"] = "Rare",
    ["Adurite"] = "Epic", ["Obsidian"] = "Epic", ["Adamantite"] = "Legendary", ["Runite"] = "Legendary"
} 

task.spawn(function()
    -- Path: ReplicatedStorage > Shared > Data > Ore
    local Shared = Services.ReplicatedStorage:WaitForChild("Shared", 5)
    local Data = Shared and Shared:WaitForChild("Data", 5)
    local OreFolder = Data and Data:FindFirstChild("Ore")
    
    if OreFolder then
        print("[System] Scanning Ore Data Folders...")
        
        -- Loop Folder Kategori (Crystals, General, Island 1, dll)
        for _, categoryFolder in pairs(OreFolder:GetChildren()) do
            if categoryFolder:IsA("Folder") then
                
                -- Loop Item di dalam Kategori
                for _, itemModule in pairs(categoryFolder:GetChildren()) do
                    if itemModule:IsA("ModuleScript") then
                        local success, data = pcall(require, itemModule)
                        if success and data then
                            -- Ambil Nama & Rarity
                            local name = data.Name or itemModule.Name
                            local rarity = data.Rarity or "Common"
                            
                            -- Masukkan ke Database
                            RarityDatabase[name] = rarity
                        end
                    end
                end
            end
        end
        print("[System] Rarity Database Updated! Total items loaded.")
    else
        warn("[System] Folder 'Ore' tidak ditemukan di Shared.Data!")
    end
end)

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

------- SUPER NOCLIP SYSTEM --------
Services.RunService.Stepped:Connect(function()
    if (_G_Flags.AutoFarm or _G_Flags.AutoFarmMobs or _G_Flags.IsSellingAction) and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

------- HELPER FUNCTIONS --------

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

------- MINING & MOB LOGIC --------

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

------- LEGIT FORGE LOGIC --------
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

-- [[ SELLING LOGIC ]] --

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
            -- AMBIL RARITY YANG SUDAH DI-SCAN
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

            -- AKTIFKAN MODE JUAL MANUAL
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
            
            -- RESET MODE JUAL & FARMING
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

-- [[ LOOPS ]] --
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

task.spawn(function() while true do task.wait(0.5) if _G_Flags.AutoHeal then 
    local Char = LocalPlayer.Character
    if Char then
        local Hum = Char:FindFirstChild("Humanoid")
        if Hum and Hum.Health > 0 and (Hum.Health/Hum.MaxHealth)*100 <= _G_Flags.HealPercentage then
           local P = GetTool("HealthPotion2") or GetTool("HealthPotion1")
           if P then Hum:EquipTool(P) task.wait(0.5) ActivateTool(P.Name) task.wait(1.5) end
        end
    end
end end end)

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

------- UI SETUP --------

FarmSection:Toggle({ Title = "Auto Farm Rocks", Desc = "Mulai Mining", Value = false, Callback = function(Value) _G_Flags.AutoFarm = Value if Value then _G_Flags.AutoFarmMobs = false end if not Value then ResetPhysics() end end })
StealthSection:Slider({ Title = "Stealth Depth (Y)", Desc = "Posisi sembunyi (Minus = Bawah Tanah)", Step = 1, Value = { Min = -15, Max = 5, Default = -8 }, Callback = function(Value) _G_Flags.FarmDepth = Value end })
FilterSection:Dropdown({ Title = "Pilih Batu", Desc = "Multi Select Aktif", Multi = true, Default = {"All"}, Values = RockNames, Callback = function(Value) _G_Flags.SelectedRock = Value end })

MobSection:Toggle({ Title = "Auto Farm Mobs", Desc = "Mulai Mob Farming", Value = false, Callback = function(Value) _G_Flags.AutoFarmMobs = Value if Value then _G_Flags.AutoFarm = false end if not Value then ResetPhysics() end end })
MobFilterSection:Dropdown({ Title = "Pilih Mob", Desc = "Multi Select Aktif", Multi = true, Default = {"All"}, Values = MobNames, Callback = function(Value) _G_Flags.SelectedMob = Value end })

ForgeSection:Toggle({ Title = "Legit Auto Minigame", Desc = "Membantu menyelesaikan minigame secara visual (Input Based)", Value = false, Callback = function(Value) _G_Flags.AutoPlayLegit = Value end })

-- [[ SELLING UI ]]
SellSection:Toggle({
    Title = "Auto Sell Inventory",
    Desc = "Jual otomatis saat tas penuh (mencapai batas)",
    Value = false,
    Callback = function(Value) _G_Flags.AutoSell = Value end
})

SellSection:Dropdown({
    Title = "Pilih Rarity Jual",
    Desc = "Pilih tipe item yang mau DIJUAL",
    Multi = true,
    Default = {"Common", "Uncommon"},
    Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"},
    Callback = function(Value) _G_Flags.SellRarities = Value end
})

SellSection:Slider({
    Title = "Trigger Jumlah Item (Full)",
    Desc = "Set sesuai kapasitas tasmu! (Misal tas 50, set 48)",
    Step = 1,
    Value = { Min = 10, Max = 500, Default = 45 },
    Callback = function(Value) _G_Flags.SellThreshold = Value end
})

SellSection:Button({ Title = "JUAL SEKARANG", Callback = function() ProcessAutoSell() end })

-- [[ SURVIVAL UI ]] --
SurvivalSection:Toggle({ Title = "Auto Heal Potion", Desc = "Minum Potion saat sekarat (Butuh Item)", Value = false, Callback = function(Value) _G_Flags.AutoHeal = Value end })
SurvivalSection:Slider({ Title = "Trigger HP %", Desc = "Batas HP untuk heal", Step = 5, Value = { Min = 10, Max = 90, Default = 40 }, Callback = function(Value) _G_Flags.HealPercentage = Value end })

SpeedSection:Slider({ Title = "Max Distance", Step = 1, Value = { Min = 50, Max = 2000, Default = 300 }, Callback = function(Value) _G_Flags.MaxDistance = Value end })
SpeedSection:Slider({ Title = "Kecepatan Tween", Step = 1, Value = { Min = 50, Max = 500, Default = 100 }, Callback = function(Value) _G_Flags.TweenSpeed = Value end })
UnstuckSection:Button({ Title = "UNSTUCK / RESET PHYSICS", Callback = function() ResetPhysics() end })
MiscTab:Keybind({ Title = "Hide Menu", Desc = "Right Ctrl", Default = Enum.KeyCode.RightControl, Callback = function() Window:Toggle() end })
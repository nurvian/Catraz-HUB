-------- Window / UI Library --------
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

function createPopup(text)
    return WindUI:Popup({
        Title = "System",
        Icon = "info",
        Content = text,
        Buttons = { { Title = "Oke", Icon = "check" } }
    })
end

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
        Enabled = true, 
        Draggable = true,
        OnlyMobile = false,
        Color = ColorSequence.new(Color3.fromHex("#fc03f8"), Color3.fromHex("#db03fc"))
    },
    KeySystem = {
        Title = "Key System",
        Note = "Key: 1234",
        KeyValidator = function(EnteredKey)
            return EnteredKey == "1234"
        end
    }
})

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

local ForgeSection = ForgeTab:Section({ Title = "Legit Auto Minigame" })

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

-- Generate Mob Names
local MobNames = {"All"}
pcall(function()
    local MobAssets = Services.ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Mobs")
    for _, mob in pairs(MobAssets:GetChildren()) do
        table.insert(MobNames, mob.Name)
    end
end)

-- [[ RARITY DATABASE ]] --
local RarityDatabase = {} 
task.spawn(function()
    local OreDataFolder = Services.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Data"):WaitForChild("Ore")
    local function ScanFolder(folder)
        for _, item in pairs(folder:GetChildren()) do
            if item:IsA("Folder") then ScanFolder(item)
            elseif item:IsA("ModuleScript") then
                local success, data = pcall(require, item)
                if success and data.Name and data.Rarity then
                    RarityDatabase[data.Name] = data.Rarity
                end
            end
        end
    end
    ScanFolder(OreDataFolder)
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
    -- Forge Config
    AutoPlayLegit = false,
    
    AutoSell = false,
    SellRarities = {}, 
    SellInterval = 10,
    AutoHeal = false,
    HealPercentage = 40 
}

------- SUPER NOCLIP SYSTEM --------
Services.RunService.Stepped:Connect(function()
    if (_G_Flags.AutoFarm or _G_Flags.AutoFarmMobs) and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false 
            end
        end
    end
end)

------- HELPER FUNCTIONS --------

local function IsTargetValid(targetName, selectionList)
    if selectionList == "All" then return true end
    if type(selectionList) == "table" then
        for _, selected in pairs(selectionList) do
            if selected == "All" then return true end
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
            if not _G_Flags.AutoFarm and not _G_Flags.AutoFarmMobs then Tween:Cancel() ResetPhysics() return false end
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

------- LEGIT FORGE LOGIC (FIXED COLOR & GRIP) --------

local isPumpingMelt = false
local isHoldingPour = false

-- [[ MELT FIX: GRIP +30 PIXEL ]] --
local function SolveMelt()
    local MeltUI = PlayerGui:FindFirstChild("Forge") and PlayerGui.Forge:FindFirstChild("MeltMinigame")
    
    if MeltUI and MeltUI.Visible and not isPumpingMelt then
        isPumpingMelt = true
        task.spawn(function()
            local Heater = MeltUI:WaitForChild("Heater", 1)
            if Heater then
                local Top = Heater:FindFirstChild("Top")
                if Top then
                    while MeltUI.Visible and _G_Flags.AutoPlayLegit do
                        local absPos = Top.AbsolutePosition
                        local absSize = Top.AbsoluteSize
                        local centerX = absPos.X + absSize.X/2
                        
                        -- [[ FIX: Posisi Mouse LEBIH BAWAH LAGI (+30px) ]]
                        local centerY = absPos.Y + absSize.Y + 30
                        
                        Services.VirtualInputManager:SendMouseMoveEvent(centerX, centerY, game)
                        task.wait(0.1) 
                        Services.VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
                        task.wait(0.1)
                        
                        -- Tarik
                        local dragDistance = 250 
                        local steps = 5 
                        for i = 1, steps do
                            if not MeltUI.Visible then break end
                            local lerpY = centerY + (dragDistance * (i/steps))
                            Services.VirtualInputManager:SendMouseMoveEvent(centerX, lerpY, game)
                            task.wait(0.01)
                        end
                        
                        -- Lepas
                        Services.VirtualInputManager:SendMouseButtonEvent(centerX, centerY + dragDistance, 0, false, game, 1)
                        task.wait(0.15)
                    end
                end
            end
            isPumpingMelt = false
        end)
    elseif not MeltUI or not MeltUI.Visible then
        isPumpingMelt = false
    end
end

-- [[ POUR: FLAPPY BIRD LOGIC ]] --
local function SolvePour()
    local PourUI = PlayerGui:FindFirstChild("Forge") and PlayerGui.Forge:FindFirstChild("PourMinigame")
    
    if PourUI and PourUI.Visible then
        local Frame = PourUI:FindFirstChild("Frame")
        if Frame then
            local Line = Frame:FindFirstChild("Line")
            local Area = Frame:FindFirstChild("Area")
            
            if Line and Area then
                local lineY = Line.AbsolutePosition.Y
                local areaY = Area.AbsolutePosition.Y
                local areaH = Area.AbsoluteSize.Y
                local targetY = areaY + (areaH / 2)
                
                if lineY > targetY + 10 then 
                    if not isHoldingPour then
                        Services.VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                        isHoldingPour = true
                    end
                elseif lineY < targetY - 10 then
                    if isHoldingPour then
                        Services.VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                        isHoldingPour = false
                    end
                end
            end
        end
    else
        if isHoldingPour then
            Services.VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            isHoldingPour = false
        end
    end
end

-- [[ HAMMER FIX: COLOR ONLY (G > 250) ]] --
local function SolveHammer()
    local HammerUI = PlayerGui:FindFirstChild("Forge") and PlayerGui.Forge:FindFirstChild("HammerMinigame")
    if HammerUI and HammerUI.Visible then
        for _, child in pairs(HammerUI:GetChildren()) do
            if child:IsA("TextButton") and child:FindFirstChild("Frame") then
                local InnerFrame = child.Frame
                local Border = InnerFrame:FindFirstChild("Border")
                
                if Border and Border:IsA("ImageLabel") then
                    local color = Border.ImageColor3
                    
                    -- [[ FIX LOGIKA HIT: HANYA WARNA ]]
                    -- Debugger kamu bilang: R1 G254 (Hijau Murni)
                    -- Jadi: G > 0.9 (230+)
                    
                    if color.G > 0.9 then
                        local absPos = child.AbsolutePosition
                        local absSize = child.AbsoluteSize
                        local centerX = absPos.X + absSize.X/2
                        local centerY = absPos.Y + absSize.Y/2
                        
                        Services.VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
                        Services.VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
                        
                        task.wait(0.2)
                    end
                end
            end
        end
    end
end

-- [[ GLOBAL LOOP ]] --
Services.RunService.RenderStepped:Connect(function()
    if _G_Flags.AutoPlayLegit then
        SolveMelt()
        SolvePour()
        SolveHammer()
    end
end)


-- [[ SELLING LOGIC ]] --
local function GetRealInventory()
    if PlayerController and PlayerController.Replica and PlayerController.Replica.Data then
        return PlayerController.Replica.Data.Inventory
    end
    return nil
end

local function ProcessAutoSell()
    local Inventory = GetRealInventory()
    if not Inventory then warn("[AutoSell] Gagal akses Data Knit!") return end

    local BasketToSell = {}
    local hasItem = false

    for itemName, quantity in pairs(Inventory) do
        if type(quantity) == "number" and quantity > 0 then
            local itemRarity = RarityDatabase[itemName]
            if itemRarity and IsTargetValid(itemRarity, _G_Flags.SellRarities) then
                BasketToSell[itemName] = quantity
                hasItem = true
            end
        end
    end

    if hasItem then
        local Remote = Services.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("DialogueService"):WaitForChild("RF"):WaitForChild("RunCommand")
        if Remote then
            pcall(function()
                Remote:InvokeServer("SellConfirm", { Basket = BasketToSell })
                print("[AutoSell] Success! Basket:", BasketToSell)
                game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Auto Sell", Text = "Barang terjual!", Duration = 3 })
            end)
        end
    end
end

task.spawn(function()
    while true do
        task.wait(1)
        if _G_Flags.AutoSell then ProcessAutoSell() task.wait(_G_Flags.SellInterval) end
    end
end)

-- [[ AUTO HEAL LOGIC ]] --
local lastHealTime = 0
local healCooldown = 3 

local function CheckAndHeal()
    local Char = LocalPlayer.Character
    if not Char then return end
    local Hum = Char:FindFirstChild("Humanoid")
    if not Hum or Hum.Health <= 0 then return end

    local pct = (Hum.Health / Hum.MaxHealth) * 100
    
    if pct <= _G_Flags.HealPercentage and (tick() - lastHealTime > healCooldown) then
        local Potion = GetTool("HealthPotion2") or GetTool("HealthPotion1")
        if Potion then
            print("[Auto Heal] Using " .. Potion.Name)
            Hum:EquipTool(Potion) 
            task.wait(0.5) 
            ActivateTool(Potion.Name) 
            task.wait(1.5) 
            lastHealTime = tick()
        end
    end
end

task.spawn(function()
    while true do
        task.wait(0.5) 
        if _G_Flags.AutoHeal then CheckAndHeal() end
    end
end)


------- MAIN LOOP --------
task.spawn(function()
    while true do
        task.wait() 
        local Char = LocalPlayer.Character
        local Root = Char and Char:FindFirstChild("HumanoidRootPart")
        local Hum = Char and Char:FindFirstChild("Humanoid")

        if Root and Hum and Hum.Health > 0 then
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

-- [[ LEGIT FORGE UI ]]
ForgeSection:Toggle({
    Title = "Legit Auto Minigame",
    Desc = "Membantu menyelesaikan minigame secara visual (Input Based)",
    Value = false,
    Callback = function(Value)
        _G_Flags.AutoPlayLegit = Value
    end
})

SellSection:Toggle({ Title = "Auto Sell Inventory", Desc = "Jual item otomatis berdasarkan Rarity", Value = false, Callback = function(Value) _G_Flags.AutoSell = Value end })
SellSection:Dropdown({ Title = "Pilih Rarity Jual", Desc = "Pilih tipe item yang mau DIJUAL", Multi = true, Default = {"Common", "Uncommon"}, Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}, Callback = function(Value) _G_Flags.SellRarities = Value end })
SellSection:Slider({ Title = "Interval Jual (Detik)", Step = 1, Value = { Min = 5, Max = 120, Default = 30 }, Callback = function(Value) _G_Flags.SellInterval = Value end })
SellSection:Button({ Title = "JUAL SEKARANG", Callback = function() ProcessAutoSell() end })

-- [[ SURVIVAL UI ]] --
SurvivalSection:Toggle({ Title = "Auto Heal Potion", Desc = "Minum Potion saat sekarat (Butuh Item)", Value = false, Callback = function(Value) _G_Flags.AutoHeal = Value end })
SurvivalSection:Slider({ Title = "Trigger HP %", Desc = "Batas HP untuk heal", Step = 5, Value = { Min = 10, Max = 90, Default = 40 }, Callback = function(Value) _G_Flags.HealPercentage = Value end })

SpeedSection:Slider({ Title = "Max Distance", Step = 1, Value = { Min = 50, Max = 2000, Default = 300 }, Callback = function(Value) _G_Flags.MaxDistance = Value end })
SpeedSection:Slider({ Title = "Kecepatan Tween", Step = 1, Value = { Min = 50, Max = 500, Default = 100 }, Callback = function(Value) _G_Flags.TweenSpeed = Value end })
UnstuckSection:Button({ Title = "UNSTUCK / RESET PHYSICS", Callback = function() ResetPhysics() end })
MiscTab:Keybind({ Title = "Hide Menu", Desc = "Right Ctrl", Default = Enum.KeyCode.RightControl, Callback = function() Window:Toggle() end })
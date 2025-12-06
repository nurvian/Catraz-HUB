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
    Icon = "pickaxe",
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
local MiscTab = Window:Tab({ Title = "Misc", Icon = "settings" })

local FarmSection = MainTab:Section({ Title = "Auto Farming" })
local FilterSection = MainTab:Section({ Title = "Filter Settings" })
local SpeedSection = MiscTab:Section({ Title = "Movement Settings" }) -- Tab Baru buat Speed

------- Core Variables --------
local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    RunService = game:GetService("RunService"),
    TweenService = game:GetService("TweenService") -- Service Wajib buat Tween
}

local LocalPlayer = Services.Players.LocalPlayer
local RocksFolder = Services.Workspace:WaitForChild("Rocks")

local RockNames = {
    "All", "Pebble", "Rock", "Boulder", "Basalt Rock", 
    "Basalt Core", "Basalt Vein", "Volcanic Rock", 
    "Lucky Block", "Iron", "Gold"
}

local _G_Flags = {
    AutoFarm = false,
    AutoEquip = true,
    SelectedRock = "All",
    TweenSpeed = 300 -- Kecepatan Default (Bisa diatur di UI)
}

------- NOCLIP SYSTEM --------
-- Ini wajib biar pas nge-Tween ga nabrak tembok/tanah
Services.RunService.Stepped:Connect(function()
    if _G_Flags.AutoFarm and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide == true then
                part.CanCollide = false
            end
        end
    end
end)

------- LOGIC FUNCTIONS --------

local function GetPickaxe()
    if not LocalPlayer.Backpack then return nil end
    local tool = LocalPlayer.Backpack:FindFirstChild("Pickaxe") 
    if not tool then
        for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do
            if item:IsA("Tool") and string.find(item.Name, "Pickaxe") then
                tool = item
                break
            end
        end
    end
    return tool
end

local function AttackRock(tool)
    if tool and tool.Parent == LocalPlayer.Character then
        tool:Activate()
    end
    
    local Remote = Services.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("ToolService"):WaitForChild("RF"):WaitForChild("ToolActivated")
    if Remote then
        pcall(function()
            Remote:InvokeServer(unpack({"Pickaxe"}))
        end)
    end
end

-- FUNGSI TWEEN (PENGGANTI TELEPORT KASAR)
local function TweenToTarget(targetCFrame)
    local Char = LocalPlayer.Character
    if not Char or not Char:FindFirstChild("HumanoidRootPart") then return end

    local Root = Char.HumanoidRootPart
    local Distance = (Root.Position - targetCFrame.Position).Magnitude
    
    -- Hitung waktu berdasarkan Jarak / Kecepatan
    local Time = Distance / _G_Flags.TweenSpeed 
    
    -- Kalau deket banget, dianggap 0 detik (instan)
    if Distance < 5 then Time = 0 end 

    -- Buat Tween
    local TweenInfo = TweenInfo.new(Time, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local Tween = Services.TweenService:Create(Root, TweenInfo, {CFrame = targetCFrame})
    
    Tween:Play()
    
    -- Tunggu sampe sampe (Looping wait biar bisa dicancel kalo autofarm dimatiin)
    if Time > 0 then
        local elapsed = 0
        while elapsed < Time do
            if not _G_Flags.AutoFarm then 
                Tween:Cancel() 
                return false 
            end
            -- Cek kalau mati pas lagi terbang
            if not Char or not Char:FindFirstChild("HumanoidRootPart") or Char.Humanoid.Health <= 0 then
                Tween:Cancel()
                return false
            end
            
            task.wait(0.1)
            elapsed = elapsed + 0.1
        end
    end
    return true -- Berhasil sampai
end

local function GetActiveRock()
    local closestRock = nil
    local shortestDistance = math.huge
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not myRoot then return nil end

    local descendants = RocksFolder:GetDescendants()
    
    for _, obj in pairs(descendants) do
        if obj.Name == "Hitbox" and obj.Parent then
            local rockModel = obj.Parent
            local orePos = obj:FindFirstChild("OrePosition")
            
            if orePos and rockModel:IsA("Model") then
                local checkName = true
                if _G_Flags.SelectedRock ~= "All" then
                    if not string.find(rockModel.Name, _G_Flags.SelectedRock) then
                        checkName = false
                    end
                end

                if checkName then
                    local targetPos = nil
                    if orePos:IsA("BasePart") then
                        targetPos = orePos.Position
                    elseif orePos:IsA("Attachment") then
                        targetPos = orePos.WorldPosition
                    end

                    if targetPos then
                        local dist = (myRoot.Position - targetPos).Magnitude
                        if dist < shortestDistance then
                            closestRock = {
                                Model = rockModel,
                                Position = targetPos
                            }
                            shortestDistance = dist
                        end
                    end
                end
            end
        end
    end
    return closestRock
end

-- LOOP UTAMA (SUDAH SUPPORT TWEEN & DEATH CHECK)
task.spawn(function()
    while true do
        task.wait() -- Loop cepat
        
        -- Cek Validasi Karakter (Death Check ada disini)
        local Char = LocalPlayer.Character
        local Root = Char and Char:FindFirstChild("HumanoidRootPart")
        local Hum = Char and Char:FindFirstChild("Humanoid")

        -- Kalau karakter ada, hidup, dan autofarm nyala
        if _G_Flags.AutoFarm and Root and Hum and Hum.Health > 0 then
            
            -- 1. Auto Equip
            if _G_Flags.AutoEquip then
                local tool = GetPickaxe()
                if tool then Char.Humanoid:EquipTool(tool) end
            end
            
            -- 2. Cari Batu
            local Target = GetActiveRock()
            
            if Target then
                local rockModel = Target.Model
                local farmPos = Target.Position
                
                -- Posisi berdiri: 3.5 stud dari batu, menghadap batu
                local standPos = farmPos + Vector3.new(3.5, 0, 0)
                local targetCFrame = CFrame.lookAt(standPos, farmPos)
                
                -- 3. JALAN MENUJU BATU (TWEEN)
                local arrived = TweenToTarget(targetCFrame)
                
                -- 4. KALO UDAH SAMPE, MULAI MUKUL
                if arrived then
                    -- Reset velocity biar ga mental pas sampe
                    Root.Velocity = Vector3.zero 
                    Root.AssemblyLinearVelocity = Vector3.zero
                    
                    -- Kunci posisi (Anchor) biar ga geser2 pas mukul
                    Root.Anchored = true 
                    
                    local lastHit = 0
                    local hitCooldown = 0.25 
                    
                    -- Loop Mukul (Selama batu masih ada & player masih hidup)
                    while _G_Flags.AutoFarm and rockModel.Parent ~= nil and rockModel:FindFirstChild("Hitbox") do
                        -- Cek lagi kalau tiba-tiba mati pas lagi mukul
                        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character.Humanoid.Health <= 0 then
                            break -- Keluar loop, nanti loop utama nunggu respawn
                        end
                        
                        -- Cek jarak (safety)
                        if (LocalPlayer.Character.HumanoidRootPart.Position - farmPos).Magnitude > 8 then
                            break -- Kejauhan, cari posisi lagi
                        end
                        
                        -- Pastikan menghadap batu
                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.lookAt(standPos, farmPos)

                        -- Equip ulang kalau lepas
                        if _G_Flags.AutoEquip and not LocalPlayer.Character:FindFirstChildWhichIsA("Tool") then
                            local tool = GetPickaxe()
                            if tool then LocalPlayer.Character.Humanoid:EquipTool(tool) end
                        end
                        
                        -- Pukul
                        if tick() - lastHit > hitCooldown then
                            local currentTool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
                            if currentTool then
                                AttackRock(currentTool)
                            end
                            lastHit = tick()
                        end
                        task.wait() 
                    end
                    
                    -- Selesai mukul/batu hancur: Lepas Anchor
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                         LocalPlayer.Character.HumanoidRootPart.Anchored = false
                    end
                end
            else
                -- Kalau ga nemu batu, tunggu bentar
                task.wait(1)
            end
        else
            -- Kalau mati atau autofarm mati, pastikan anchor lepas biar bisa jalan pas respawn
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.Anchored = false
            end
            task.wait(1) -- Idle wait saat mati/off
        end
    end
end)

------- UI SETUP --------

FarmSection:Toggle({
    Title = "Auto Farm Rocks",
    Desc = "Mulai Mining (Tween Mode)",
    Value = false,
    Callback = function(Value)
        _G_Flags.AutoFarm = Value
        -- Safety unlock
        if not Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.Anchored = false
        end
    end
})

FarmSection:Dropdown({
    Title = "Pilih Jenis Batu",
    Desc = "Filter Target",
    Multi = false,
    Default = "All",
    Values = RockNames,
    Callback = function(Value)
        _G_Flags.SelectedRock = Value
    end
})

-- Bagian Slider Speed Baru
FarmSection:Slider({
    Title = "Kecepatan Tween",
    Desc = "Makin kecil makin pelan (Aman). Default: 300",
    Step = 1,
    Value = {
        Min = 50,
        Max = 500,
        Default = 300,
    },
    Callback = function(Value)
        _G_Flags.TweenSpeed = Value
    end
})

FarmSection:Toggle({
    Title = "Auto Equip",
    Desc = "Otomatis pegang Pickaxe",
    Value = true,
    Callback = function(Value)
        _G_Flags.AutoEquip = Value
    end
})

MiscTab:Keybind({
    Title = "Sembunyikan Menu",
    Desc = "Tekan Right Ctrl",
    Default = Enum.KeyCode.RightControl,
    Callback = function()
        Window:Toggle()
    end
})
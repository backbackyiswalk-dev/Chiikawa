-- ===================================================================
-- SKY TOWER SURVIVAL EXECUTOR SCRIPT (TELEPORT TO FLOOR 1 CENTER)
-- ===================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")
local Camera = Workspace.CurrentCamera

-- Workspace Cleaning & Setup
local ExistingMap = Workspace:FindFirstChild("SurvivalMap")
if ExistingMap then ExistingMap:Destroy() end

local MapFolder = Instance.new("Folder")
MapFolder.Name = "SurvivalMap"
MapFolder.Parent = Workspace

local DisappearingPlatforms = {}
local ZombieFolder = Instance.new("Folder", MapFolder)
ZombieFolder.Name = "Zombies"

local ItemFolder = Instance.new("Folder", MapFolder)
ItemFolder.Name = "Items"

-- Configuration (하늘 위 높은 곳)
local SkyHeightOffset = 500
local FloorConfigs = {
    { Floor = 1, Count = 500, Height = SkyHeightOffset + 10, Size = Vector3.new(12, 2, 12), Grid = 23 },
    { Floor = 2, Count = 350, Height = SkyHeightOffset + 70, Size = Vector3.new(12, 2, 12), Grid = 19 },
    { Floor = 3, Count = 200, Height = SkyHeightOffset + 130, Size = Vector3.new(12, 2, 12), Grid = 15 },
    { Floor = 4, Count = 100, Height = SkyHeightOffset + 190, Size = Vector3.new(12, 2, 12), Grid = 10 }
}

-- -------------------------------------------------------------------
-- 1. MAP GENERATION & TELEPORT TO FLOOR 1 CENTER
-- -------------------------------------------------------------------
local function BuildMap()
    for _, config in ipairs(FloorConfigs) do
        local count = 0
        local gridWidth = config.Grid
        local spacing = 14
        local startX = -((gridWidth * spacing) / 2)
        local startZ = -((gridWidth * spacing) / 2)

        for x = 0, gridWidth - 1 do
            for z = 0, gridWidth - 1 do
                if count >= config.Count then break end

                local part = Instance.new("Part")
                part.Name = "Floor_" .. config.Floor .. "_" .. count
                part.Size = config.Size
                part.Position = Vector3.new(startX + (x * spacing), config.Height, startZ + (z * spacing))
                part.Anchored = true
                part.Material = Enum.Material.Neon
                
                if config.Floor == 1 then part.Color = Color3.fromRGB(0, 170, 255)
                elseif config.Floor == 2 then part.Color = Color3.fromRGB(85, 255, 127)
                elseif config.Floor == 3 then part.Color = Color3.fromRGB(255, 170, 0)
                elseif config.Floor == 4 then part.Color = Color3.fromRGB(255, 50, 50) end

                part.Parent = MapFolder
                table.insert(DisappearingPlatforms, part)

                -- 1층의 정확한 정중앙 발판 위치로 강제 텔레포트
                if config.Floor == 1 and math.floor(gridWidth / 2) == x and math.floor(gridWidth / 2) == z then
                    task.defer(function()
                        if Character and HumanoidRootPart then
                            HumanoidRootPart.CFrame = part.CFrame + Vector3.new(0, 5, 0)
                        end
                    end)
                end

                -- 발판 터치 시 사라지는 로직
                local isFading = false
                part.Touched:Connect(function(hit)
                    if hit.Parent == Character and not isFading then
                        isFading = true
                        local flashTween = TweenService:Create(part, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 3, true), {Transparency = 0.6})
                        flashTween:Play()
                        task.wait(0.6)
                        
                        local fadeTween = TweenService:Create(part, TweenInfo.new(0.3), {Transparency = 1})
                        fadeTween:Play()
                        part.CanCollide = false
                        
                        task.wait(5)
                        part.CanCollide = true
                        TweenService:Create(part, TweenInfo.new(0.3), {Transparency = 0}):Play()
                        isFading = false
                    end
                end)

                count = count + 1
            end
            if count >= config.Count then break end
        end
    end
end

BuildMap()

-- -------------------------------------------------------------------
-- 2. HIGH-QUALITY SNIPER SYSTEM (ZOOM, NO RECOIL WHEN ZOOMED)
-- -------------------------------------------------------------------
local function GiveSniper()
    local tool = Instance.new("Tool")
    tool.Name = "HQ Sniper Rifle"
    tool.RequiresHandle = true
    tool.CanBeDropped = false

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.6, 0.8, 4.5)
    handle.Color = Color3.fromRGB(20, 20, 20)
    handle.Material = Enum.Material.Metal
    handle.Parent = tool

    local scope = Instance.new("Part", tool)
    scope.Size = Vector3.new(0.4, 0.6, 1.2)
    scope.Color = Color3.fromRGB(10, 10, 10)
    local weld1 = Instance.new("WeldConstraint", tool)
    weld1.Part0 = handle
    weld1.Part1 = scope
    scope.CFrame = handle.CFrame * CFrame.new(0, 0.6, 0)

    local barrel = Instance.new("Part", tool)
    barrel.Size = Vector3.new(0.25, 0.25, 3)
    barrel.Color = Color3.fromRGB(15, 15, 15)
    local weld2 = Instance.new("WeldConstraint", tool)
    weld2.Part0 = handle
    weld2.Part1 = barrel
    barrel.CFrame = handle.CFrame * CFrame.new(0, 0.2, -3.5)

    local shootSound = Instance.new("Sound", handle)
    shootSound.SoundId = "rbxassetid://131070686" 
    shootSound.Volume = 2
    shootSound.Pitch = 0.8

    local isZoomed = false
    local defaultFOV = 70
    local zoomFOV = 15
    local lastShot = 0
    local fireRate = 0.85

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if tool.Parent == Character and input.UserInputType == Enum.UserInputType.MouseButton2 then
            isZoomed = true
            TweenService:Create(Camera, TweenInfo.new(0.2), {FieldOfView = zoomFOV}):Play()
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            isZoomed = false
            TweenService:Create(Camera, TweenInfo.new(0.2), {FieldOfView = defaultFOV}):Play()
        end
    end)

    tool.Activated:Connect(function()
        if tick() - lastShot < fireRate then return end
        lastShot = tick()

        shootSound:Play()

        local recoilPitch = isZoomed and 0.2 or 4
        local recoilYaw = isZoomed and 0.1 or 2
        Camera.CFrame = Camera.CFrame * CFrame.Angles(math.rad(recoilPitch), math.rad(math.random(-recoilYaw, recoilYaw)), 0)

        local mouse = LocalPlayer:GetMouse()
        local ray = Ray.new(handle.Position, (mouse.Hit.p - handle.Position).Unit * 1000)
        local hitPart, hitPos = Workspace:FindPartOnRayWithIgnoreList(ray, {Character, MapFolder})

        local tracer = Instance.new("Part", Workspace)
        tracer.Anchored = true
        tracer.CanCollide = false
        tracer.Material = Enum.Material.Neon
        tracer.Color = Color3.fromRGB(255, 100, 100)
        tracer.Size = Vector3.new(0.08, 0.08, (handle.Position - hitPos).Magnitude)
        tracer.CFrame = CFrame.new(handle.Position, hitPos) * CFrame.new(0, 0, -tracer.Size.Z / 2)
        TweenService:Create(tracer, TweenInfo.new(0.1), {Transparency = 1}):Play()
        game:GetService("Debris"):AddItem(tracer, 0.1)

        if hitPart and hitPart.Parent and hitPart.Parent:FindFirstChild("ZombieHumanoid") then
            local zombieModel = hitPart.Parent
            local zHum = zombieModel:FindFirstChild("ZombieHumanoid")
            local damage = 20

            if hitPart.Name == "Head" then
                damage = 100
            elseif hitPart.Name == "Torso" then
                damage = 45
            elseif hitPart.Name == "LeftLeg" or hitPart.Name == "RightLeg" then
                damage = 20
            end

            zHum:TakeDamage(damage)

            local hitMarker = Instance.new("BillboardGui", hitPart)
            hitMarker.Size = UDim2.new(0, 60, 0, 60)
            hitMarker.AlwaysOnTop = true
            local text = Instance.new("TextLabel", hitMarker)
            text.Size = UDim2.new(1, 0, 1, 0)
            text.BackgroundTransparency = 1
            text.Text = "-" .. damage
            text.TextColor3 = (damage == 100 and Color3.fromRGB(255, 215, 0)) or Color3.fromRGB(255, 50, 50)
            text.TextScaled = true
            text.Font = Enum.Font.FredokaOne
            game:GetService("Debris"):AddItem(hitMarker, 0.5)
        end
    end)

    tool.Unequipped:Connect(function()
        isZoomed = false
        Camera.FieldOfView = defaultFOV
    end)

    tool.Parent = LocalPlayer.Backpack
end

GiveSniper()

-- -------------------------------------------------------------------
-- 3. ZOMBIE SPAWNER (HP 100)
-- -------------------------------------------------------------------
local function SpawnZombie()
    if #DisappearingPlatforms == 0 then return end
    local randomPlatform = DisappearingPlatforms[math.random(1, #DisappearingPlatforms)]
    if not randomPlatform or not randomPlatform.Parent then return end

    local zombie = Instance.new("Model", ZombieFolder)
    zombie.Name = "Zombie"

    local torso = Instance.new("Part", zombie)
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 2, 1)
    torso.Position = randomPlatform.Position + Vector3.new(0, 3, 0)
    torso.Color = Color3.fromRGB(40, 100, 40)
    torso.Material = Enum.Material.Fabric

    local head = Instance.new("Part", zombie)
    head.Name = "Head"
    head.Size = Vector3.new(1.2, 1.2, 1.2)
    head.Position = torso.Position + Vector3.new(0, 1.5, 0)
    head.Color = Color3.fromRGB(50, 120, 50)

    local lLeg = Instance.new("Part", zombie)
    lLeg.Name = "LeftLeg"
    lLeg.Size = Vector3.new(0.8, 2, 1)
    lLeg.Position = torso.Position + Vector3.new(-0.5, -2, 0)

    local rLeg = Instance.new("Part", zombie)
    rLeg.Name = "RightLeg"
    rLeg.Size = Vector3.new(0.8, 2, 1)
    rLeg.Position = torso.Position + Vector3.new(0.5, -2, 0)

    for _, part in ipairs({head, lLeg, rLeg}) do
        local w = Instance.new("WeldConstraint", zombie)
        w.Part0 = torso
        w.Part1 = part
    end

    local zHum = Instance.new("Humanoid", zombie)
    zHum.Name = "ZombieHumanoid"
    zHum.MaxHealth = 100
    zHum.Health = 100
    zHum.WalkSpeed = 10

    task.spawn(function()
        while zHum and zHum.Health > 0 and zombie.Parent do
            if Character and Character:FindFirstChild("HumanoidRootPart") then
                zHum:MoveTo(Character.HumanoidRootPart.Position)
            end
            task.wait(0.5)
        end
    end)

    zHum.Died:Connect(function()
        zombie:Destroy()
    end)
end

-- -------------------------------------------------------------------
-- 4. ITEM SPAWNER (GOLDEN APPLE & JUMP POTION)
-- -------------------------------------------------------------------
local function SpawnItems()
    if #DisappearingPlatforms == 0 then return end
    for i = 1, 15 do
        local platform = DisappearingPlatforms[math.random(1, #DisappearingPlatforms)]
        local isApple = math.random(1, 2) == 1

        local item = Instance.new("Part", ItemFolder)
        item.Size = Vector3.new(1.5, 1.5, 1.5)
        item.Position = platform.Position + Vector3.new(0, 2.5, 0)
        item.Anchored = true
        item.CanCollide = false
        item.Material = Enum.Material.Neon

        task.spawn(function()
            while item.Parent do
                item.CFrame = item.CFrame * CFrame.Angles(0, math.rad(3), 0)
                task.wait(0.02)
            end
        end)

        if isApple then
            item.Name = "GoldenApple"
            item.Color = Color3.fromRGB(255, 215, 0)
            item.Shape = Enum.PartType.Ball
        else
            item.Name = "JumpPotion"
            item.Color = Color3.fromRGB(170, 0, 255)
            item.Shape = Enum.PartType.Cylinder
        end

        item.Touched:Connect(function(hit)
            if hit.Parent == Character then
                item:Destroy()
                if isApple then
                    Humanoid.WalkSpeed = 32
                    task.wait(8)
                    Humanoid.WalkSpeed = 16
                else
                    Humanoid.JumpPower = 100
                    task.wait(8)
                    Humanoid.JumpPower = 50
                end
            end
        end)
    end
end

-- -------------------------------------------------------------------
-- 5. GUI INTERFACE
-- -------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "TowerSurvivalGui"
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 220, 0, 100)
MainFrame.Position = UDim2.new(0.02, 0, 0.4, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true

local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0.4, 0)
Title.BackgroundTransparency = 1
Title.Text = "SKY TOWER SURVIVAL"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold

local StartBtn = Instance.new("TextButton", MainFrame)
StartBtn.Size = UDim2.new(0.85, 0, 0.4, 0)
StartBtn.Position = UDim2.new(0.075, 0, 0.5, 0)
StartBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
StartBtn.Text = "START GAME"
StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StartBtn.TextScaled = true
StartBtn.Font = Enum.Font.GothamBold

local BtnCorner = Instance.new("UICorner", StartBtn)
BtnCorner.CornerRadius = UDim.new(0, 8)

local isRunning = false
StartBtn.MouseButton1Click:Connect(function()
    if isRunning then return end
    isRunning = true
    StartBtn.Text = "RUNNING..."
    StartBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)

    SpawnItems()

    task.spawn(function()
        while isRunning do
            if #ZombieFolder:GetChildren() < 25 then
                SpawnZombie()
            end
            task.wait(1.5)
        end
    end)
end)

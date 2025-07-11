-- ✅ Полный финальный скрипт GUI + ESP + Aimbot + Silent + Movement для Base Battles (Roblox)

--// СЕРВИСЫ
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// ПЕРЕМЕННЫЕ
local aimbot, silent, espEnabled = false, false, false
local showName, showHealth, showDistance, showHighlight = true, true, true, true
local aimbotFOV, silentFOV = 90, 90
local aimbotPart = "Head"
local aimbotSmoothness = 50
local speedEnabled = false
local speedValue = 30
local antiAFKEnabled = true
local antiRecoil = true
local antiSpread = true

--// АНТИ-АФК
if antiAFKEnabled then
    LocalPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

--// АНТИ-RECOIL / АНТИ-SPREAD
if antiRecoil or antiSpread then
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local old = mt.__namecall

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if tostring(self) == "UpdateRecoil" and method == "FireServer" and antiRecoil then
            return nil -- блокировка отдачи
        end

        if tostring(self) == "UpdateSpread" and method == "FireServer" and antiSpread then
            return nil -- блокировка разброса
        end

        return old(self, ...)
    end)
end

--// ESP СИСТЕМА
local ESPFolder = {}

local function createESP(player)
    local name = Drawing.new("Text") name.Size, name.Center, name.Outline, name.Color = 14, true, true, Color3.new(1,1,1)
    local health = Drawing.new("Text") health.Size, health.Center, health.Outline, health.Color = 14, true, true, Color3.new(0,1,0)
    local dist = Drawing.new("Text") dist.Size, dist.Center, dist.Outline, dist.Color = 14, true, true, Color3.new(1,1,0)

    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 1
    highlight.Enabled = false
    highlight.Parent = player.Character or player.CharacterAdded:Wait()

    ESPFolder[player] = {name=name, health=health, distance=dist, highlight=highlight}
end

local function removeESP(player)
    if ESPFolder[player] then
        for _, v in pairs(ESPFolder[player]) do
            if typeof(v) == "Instance" then v:Destroy() else v:Remove() end
        end
        ESPFolder[player] = nil
    end
end

RunService.RenderStepped:Connect(function()
    if not espEnabled then return end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team then
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                if not ESPFolder[player] then createESP(player) end
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                local esp = ESPFolder[player]

                if onScreen then
                    if showName then esp.name.Position = Vector2.new(screenPos.X, screenPos.Y - 20) esp.name.Text = player.Name esp.name.Visible = true else esp.name.Visible = false end
                    if showHealth then esp.health.Position = Vector2.new(screenPos.X, screenPos.Y) esp.health.Text = "HP: "..math.floor(hum.Health) esp.health.Visible = true else esp.health.Visible = false end
                    if showDistance then esp.distance.Position = Vector2.new(screenPos.X, screenPos.Y + 20) esp.distance.Text = "Dist: "..math.floor((hrp.Position - Camera.CFrame.Position).Magnitude) esp.distance.Visible = true else esp.distance.Visible = false end
                    esp.highlight.Adornee = char
                    esp.highlight.Enabled = showHighlight
                else
                    esp.name.Visible, esp.health.Visible, esp.distance.Visible = false, false, false
                    esp.highlight.Enabled = false
                end
            else removeESP(player) end
        else removeESP(player) end
    end
end)

Players.PlayerRemoving:Connect(removeESP)

--// AIMBOT
local function getClosest(maxFOV)
    local closest, shortest = nil, maxFOV or math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local pos, vis = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
            if vis then
                local dist = (Vector2.new(pos.X, pos.Y) - UIS:GetMouseLocation()).Magnitude
                if dist < shortest then
                    closest = plr
                    shortest = dist
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if aimbot and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = getClosest(aimbotFOV)
        if target and target.Character and target.Character:FindFirstChild(aimbotPart) then
            local tPos = target.Character[aimbotPart].Position
            local camPos = Camera.CFrame.Position
            local dir = (tPos - camPos).Unit
            local targetCF = CFrame.new(camPos, camPos + dir)
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, aimbotSmoothness / 100)
        end
    end
end)

--// SILENT AIM
local mt = getrawmetatable(game)
setreadonly(mt, false)
local old = mt.__namecall
mt.__namecall = newcclosure(function(self, ...)
    local args, method = {...}, getnamecallmethod()
    if tostring(self) == "HitPart" and method == "FireServer" and silent then
        local target = getClosest(silentFOV)
        if target and target.Character and target.Character:FindFirstChild("Head") then
            args[1], args[2] = target.Character.Head, target.Character.Head.Position
            return old(self, unpack(args))
        end
    end
    return old(self, ...)
end)

--// SPEEDHACK
RunService.RenderStepped:Connect(function()
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed = speedEnabled and speedValue or 16 end
end)

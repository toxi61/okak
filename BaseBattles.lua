-- 📦 Base Battles Final Script (All-in-One, встроенное GUI)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- 🧠 Настройки (переменные)
local settings = {
    aimbot = false,
    silent = false,
    esp = false,
    showName = true,
    showHealth = true,
    showDistance = true,
    showHighlight = true,
    aimbotFOV = 90,
    silentFOV = 90,
    aimbotPart = "Head",
    aimbotSmoothness = 50,
    speedEnabled = false,
    speedValue = 30,
    antiAFKEnabled = true,
    antiRecoil = false,
    antiSpread = false
}

-- 💤 Anti-AFK
if settings.antiAFKEnabled then
    LocalPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), Camera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), Camera.CFrame)
    end)
end

-- 🎯 Recoil/Spread Block
local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldNamecall = mt.__namecall
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if settings.antiRecoil and tostring(self) == "UpdateRecoil" and method == "FireServer" then return nil end
    if settings.antiSpread and tostring(self) == "UpdateSpread" and method == "FireServer" then return nil end
    return oldNamecall(self, ...)
end)

-- 🔎 ESP
local ESP = {}
local function createESP(p)
    local n = Drawing.new("Text") n.Center=true n.Outline=true n.Size=14 n.Color=Color3.new(1,1,1)
    local h = Drawing.new("Text") h.Center=true h.Outline=true h.Size=14 h.Color=Color3.new(0,1,0)
    local d = Drawing.new("Text") d.Center=true d.Outline=true d.Size=14 d.Color=Color3.new(1,1,0)
    local hl = Instance.new("Highlight") hl.FillColor=Color3.new(1,0,0) hl.FillTransparency=0.5 hl.Enabled=false
    hl.Parent = p.Character or p.CharacterAdded:Wait()
    ESP[p] = {n, h, d, hl}
end
local function removeESP(p)
    if ESP[p] then
        for _, v in ipairs(ESP[p]) do if typeof(v)=="Instance" then v:Destroy() else v:Remove() end end
        ESP[p] = nil
    end
end
RunService.RenderStepped:Connect(function()
    if not settings.esp then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Team~=LocalPlayer.Team then
            local c = p.Character; local hrp = c and c:FindFirstChild("HumanoidRootPart")
            local hum = c and c:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health>0 then
                if not ESP[p] then createESP(p) end
                local pos, vis = Camera:WorldToViewportPoint(hrp.Position)
                local e = ESP[p]
                if vis then
                    if settings.showName then e[1].Text, e[1].Position, e[1].Visible = p.Name, Vector2.new(pos.X,pos.Y-20), true else e[1].Visible = false end
                    if settings.showHealth then e[2].Text, e[2].Position, e[2].Visible = "HP:"..math.floor(hum.Health), Vector2.new(pos.X,pos.Y), true else e[2].Visible = false end
                    if settings.showDistance then e[3].Text, e[3].Position, e[3].Visible = "Dist:"..math.floor((hrp.Position-Camera.CFrame.Position).Magnitude), Vector2.new(pos.X,pos.Y+20), true else e[3].Visible = false end
                    e[4].Adornee = c; e[4].Enabled = settings.showHighlight
                else
                    e[1].Visible = false; e[2].Visible = false; e[3].Visible = false; e[4].Enabled = false
                end
            else removeESP(p) end
        else removeESP(p) end
    end
end)
Players.PlayerRemoving:Connect(removeESP)

-- 🎯 Aimbot
local function getClosest(fov)
    local best, dist = nil, fov or math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team then
            local part = p.Character and p.Character:FindFirstChild(settings.aimbotPart)
            if part then
                local pos, vis = Camera:WorldToViewportPoint(part.Position)
                local d = (Vector2.new(pos.X,pos.Y)-UIS:GetMouseLocation()).Magnitude
                if vis and d < dist then best, dist = p, d end
            end
        end
    end
    return best
end
RunService.RenderStepped:Connect(function()
    if settings.aimbot and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local p = getClosest(settings.aimbotFOV)
        if p and p.Character and p.Character:FindFirstChild(settings.aimbotPart) then
            local t = p.Character[settings.aimbotPart].Position
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, t), settings.aimbotSmoothness/100)
        end
    end
end)

-- 🔇 Silent Aim
mt.__namecall = newcclosure(function(self,...)
    if settings.silent and tostring(self)=="HitPart" and getnamecallmethod()=="FireServer" then
        local p = getClosest(settings.silentFOV)
        if p and p.Character and p.Character:FindFirstChild("Head") then
            local args={...}; args[1]=p.Character.Head; args[2]=p.Character.Head.Position
            return oldNamecall(self, unpack(args))
        end
    end
    return oldNamecall(self, ...)
end)

-- 🏃 SpeedHack
RunService.RenderStepped:Connect(function()
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed = settings.speedEnabled and settings.speedValue or 16 end
end)

-- 📂 GUI с кнопкой и меню
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.ResetOnSpawn = false

local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.new(0, 40, 0, 40)
OpenButton.Position = UDim2.new(0, 10, 0, 100)
OpenButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
OpenButton.Text = "📂"
OpenButton.TextSize = 24
OpenButton.TextColor3 = Color3.new(1, 1, 1)
OpenButton.Parent = ScreenGui
OpenButton.Active = true
OpenButton.Draggable = true

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 400)
Frame.Position = UDim2.new(0, 60, 0, 60)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.Visible = false
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local function createToggle(name, default, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 30)
    button.Position = UDim2.new(0, 5, 0, #Frame:GetChildren()*35)
    button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    button.TextColor3 = Color3.new(1,1,1)
    button.TextSize = 14
    button.Text = name .. ": " .. (default and "ON" or "OFF")
    button.Parent = Frame

    local state = default
    button.MouseButton1Click:Connect(function()
        state = not state
        button.Text = name .. ": " .. (state and "ON" or "OFF")
        callback(state)
    end)
end

local function createSlider(name, min, max, default, callback)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 30)
    label.Position = UDim2.new(0, 5, 0, #Frame:GetChildren()*35)
    label.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    label.TextColor3 = Color3.new(1,1,1)
    label.TextSize = 14
    label.Text = name .. ": " .. default
    label.Parent = Frame

    local slider = Instance.new("TextBox")
    slider.Size = UDim2.new(1, -10, 0, 30)
    slider.Position = UDim2.new(0, 5, 0, #Frame:GetChildren()*35)
    slider.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    slider.TextColor3 = Color3.new(1,1,1)
    slider.Text = tostring(default)
    slider.Parent = Frame

    slider.FocusLost:Connect(function()
        local val = tonumber(slider.Text)
        if val then
            val = math.clamp(val, min, max)
            slider.Text = tostring(val)
            label.Text = name .. ": " .. val
            callback(val)
        end
    end)
end

-- 🎛️ Заполнение GUI функциями
createToggle("ESP", settings.esp, function(v) settings.esp = v end)
createToggle("Aimbot", settings.aimbot, function(v) settings.aimbot = v end)
createToggle("Silent Aim", settings.silent, function(v) settings.silent = v end)
createToggle("Anti-AFK", settings.antiAFKEnabled, function(v) settings.antiAFKEnabled = v end)
createToggle("Anti-Recoil", settings.antiRecoil, function(v) settings.antiRecoil = v end)
createToggle("Anti-Spread", settings.antiSpread, function(v) settings.antiSpread = v end)
createToggle("SpeedHack", settings.speedEnabled, function(v) settings.speedEnabled = v end)
createSlider("Speed", 16, 100, settings.speedValue, function(v) settings.speedValue = v end)
createSlider("Aimbot FOV", 1, 180, settings.aimbotFOV, function(v) settings.aimbotFOV = v end)
createSlider("Silent FOV", 1, 180, settings.silentFOV, function(v) settings.silentFOV = v end)
createSlider("Smoothness", 1, 100, settings.aimbotSmoothness, function(v) settings.aimbotSmoothness = v end)

-- 🔘 Открытие GUI
OpenButton.MouseButton1Click:Connect(function()
    Frame.Visible = not Frame.Visible
end)

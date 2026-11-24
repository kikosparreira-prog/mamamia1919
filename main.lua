-- SmokeBlox v1.0 | Aimbot + ESP
-- Universal Roblox PVP | by Tren
-- Hold Q = Aimbot | Always On = ESP

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

local Config = {
    -- AIMBOT
    AimbotEnabled   = true,
    AimbotKey       = Enum.KeyCode.Q,
    AimbotFOV       = 150,
    AimbotSmoothing = 0.18,
    AimbotBone      = "Head",
    TeamCheck       = true,
    -- ESP
    ESPEnabled      = true,
    ESPMaxDist      = 1000,
    BoxColor        = Color3.fromRGB(255, 255, 255),
    EnemyColor      = Color3.fromRGB(255, 50, 50),
    FriendColor     = Color3.fromRGB(0, 162, 255),
    HealthColor     = Color3.fromRGB(50, 255, 50),
}

-- ============================================================
-- UTILITY
-- ============================================================

local function isEnemy(player)
    if not Config.TeamCheck then return true end
    return player.Team ~= LP.Team
end

local function getClosest()
    local best, bestDist = nil, Config.AimbotFOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP or not isEnemy(p) then continue end
        local char = p.Character
        if not char then continue end
        local bone = char:FindFirstChild(Config.AimbotBone) or char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if not bone or not hum or hum.Health <= 0 then continue end
        local sp, vis = Camera:WorldToViewportPoint(bone.Position)
        if not vis then continue end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d < bestDist then bestDist = d; best = bone end
    end
    return best
end

-- ============================================================
-- FOV CIRCLE
-- ============================================================

local fovCircle = Drawing.new("Circle")
fovCircle.Visible   = true
fovCircle.Radius    = Config.AimbotFOV
fovCircle.Color     = Color3.fromRGB(255,255,255)
fovCircle.Thickness = 1
fovCircle.Filled    = false
fovCircle.Position  = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

-- ============================================================
-- ESP STORAGE
-- ============================================================

local ESPCache = {}

local function newLine(color, thickness)
    local l = Drawing.new("Line")
    l.Color = color; l.Thickness = thickness; l.Visible = false
    return l
end

local function newText(size)
    local t = Drawing.new("Text")
    t.Size = size; t.Center = true; t.Outline = true; t.Visible = false
    return t
end

local function buildESP(p)
    ESPCache[p] = {
        b1 = newLine(Config.BoxColor, 1.2),
        b2 = newLine(Config.BoxColor, 1.2),
        b3 = newLine(Config.BoxColor, 1.2),
        b4 = newLine(Config.BoxColor, 1.2),
        hpBg  = newLine(Color3.fromRGB(20,20,20), 3),
        hpBar = newLine(Config.HealthColor, 3),
        name  = newText(13),
        dist  = newText(11),
    }
end

local function hideESP(d)
    for _, v in pairs(d) do v.Visible = false end
end

local function drawBox(d, tl, tr, bl, br, color)
    d.b1.From=tl; d.b1.To=tr; d.b1.Color=color; d.b1.Visible=true
    d.b2.From=bl; d.b2.To=br; d.b2.Color=color; d.b2.Visible=true
    d.b3.From=tl; d.b3.To=bl; d.b3.Color=color; d.b3.Visible=true
    d.b4.From=tr; d.b4.To=br; d.b4.Color=color; d.b4.Visible=true
end

-- ============================================================
-- MAIN LOOP
-- ============================================================

RunService.RenderStepped:Connect(function()
    -- FOV circle follow center
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        if not ESPCache[p] then buildESP(p) end
        local d    = ESPCache[p]
        local char = p.Character
        if not char or not Config.ESPEnabled then hideESP(d); continue end

        local hrp  = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then hideESP(d); continue end

        local dist3D = (hrp.Position - Camera.CFrame.Position).Magnitude
        if dist3D > Config.ESPMaxDist then hideESP(d); continue end

        local topV, onTop = Camera:WorldToViewportPoint((head or hrp).Position + Vector3.new(0,0.7,0))
        local botV, onBot = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0,2.5,0))
        if not onTop or not onBot then hideESP(d); continue end

        local top2  = Vector2.new(topV.X, topV.Y)
        local bot2  = Vector2.new(botV.X, botV.Y)
        local h     = bot2.Y - top2.Y
        local w     = math.abs(h) * 0.45
        local cx    = (top2.X + bot2.X) / 2
        local color = isEnemy(p) and Config.EnemyColor or Config.FriendColor

        -- Box
        drawBox(d,
            Vector2.new(cx-w, top2.Y), Vector2.new(cx+w, top2.Y),
            Vector2.new(cx-w, bot2.Y), Vector2.new(cx+w, bot2.Y),
            color
        )

        -- Name
        d.name.Text     = p.Name
        d.name.Color    = color
        d.name.Position = Vector2.new(cx, top2.Y - 15)
        d.name.Visible  = true

        -- Distance
        d.dist.Text     = string.format("[%d]", math.floor(dist3D))
        d.dist.Color    = Color3.fromRGB(200,200,200)
        d.dist.Position = Vector2.new(cx, bot2.Y + 2)
        d.dist.Visible  = true

        -- Health bar (left side)
        local hpPct  = hum.Health / hum.MaxHealth
        local barH   = math.abs(h)
        local barX   = cx - w - 5
        d.hpBg.From  = Vector2.new(barX, top2.Y)
        d.hpBg.To    = Vector2.new(barX, bot2.Y)
        d.hpBg.Visible = true
        d.hpBar.From = Vector2.new(barX, bot2.Y)
        d.hpBar.To   = Vector2.new(barX, bot2.Y - (barH * hpPct))
        d.hpBar.Color = Color3.fromRGB(
            math.floor(255*(1-hpPct)),
            math.floor(255*hpPct),
            0
        )
        d.hpBar.Visible = true
    end

    -- AIMBOT
    if Config.AimbotEnabled and UserInputService:IsKeyDown(Config.AimbotKey) then
        local target = getClosest()
        if target then
            local sp = Camera:WorldToViewportPoint(target.Position)
            local targetPos = Vector3.new(sp.X, sp.Y, 0)
            -- smooth lerp toward target
            local curCF = Camera.CFrame
            local dir   = (target.Position - curCF.Position).Unit
            local newCF = CFrame.new(curCF.Position, curCF.Position + dir)
            Camera.CFrame = curCF:Lerp(newCF, Config.AimbotSmoothing)
        end
    end
end)

-- Cleanup on player leave
Players.PlayerRemoving:Connect(function(p)
    if ESPCache[p] then
        hideESP(ESPCache[p])
        ESPCache[p] = nil
    end
end)
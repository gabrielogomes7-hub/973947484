-- ═══════════════════════════════════════════════════════════
--  MIRAGE HUB - 9 NIGHTS IN THE FOREST EDITION (RECONSTRUÍDO)
--  Objetivo: Garantir que o GUI apareça ao executar e corrigir erros
--  Version: 2.1.1 (REBUILT - LOADSTRING COMPATIBLE)
-- ═══════════════════════════════════════════════════════════

-- Proteção para múltiplas execuções (NÃO indexar nil)
do
    local coreGui = game:GetService("CoreGui")
    local playersService = game:GetService("Players")
    local alreadyRunning = false

    if pcall(function() return coreGui:FindFirstChild("MirageHubPro") end) and coreGui:FindFirstChild("MirageHubPro") then
        alreadyRunning = true
    else
        local lp = playersService.LocalPlayer
        if lp then
            local pgui = lp:FindFirstChild("PlayerGui")
            if pgui and pgui:FindFirstChild("MirageHubPro") then
                alreadyRunning = true
            end
        end
    end

    if alreadyRunning then
        warn("[Mirage Hub] Script já está rodando!")
        return
    end
end

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Aguarda LocalPlayer estar disponível
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat 
        LocalPlayer = Players.LocalPlayer
        task.wait(0.1)
    until LocalPlayer
end

local DEBUG = true

-- CONFIG
local CONFIG = {
    Colors = {
        Background = Color3.fromRGB(18, 18, 22),
        Surface = Color3.fromRGB(25, 25, 30),
        SurfaceLight = Color3.fromRGB(32, 32, 37),
        Primary = Color3.fromRGB(88, 101, 242),
        Accent = Color3.fromRGB(114, 137, 218),
        TextPrimary = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(142, 146, 151),
        Border = Color3.fromRGB(40, 40, 45),
        Success = Color3.fromRGB(67, 181, 129),
        Warning = Color3.fromRGB(250, 166, 26),
        Danger = Color3.fromRGB(237, 66, 69),
        MacRed = Color3.fromRGB(255, 95, 86),
        MacYellow = Color3.fromRGB(255, 189, 46),
        MacGreen = Color3.fromRGB(40, 201, 64)
    },
    Sizes = {
        Normal = UDim2.new(0, 380, 0, 440),
        Floating = UDim2.new(0, 180, 0, 34),
        Fullscreen = UDim2.new(1, 0, 1, 0)
    },
    Positions = {
        Normal = UDim2.new(0.5, -190, 0.5, -220),
        Floating = UDim2.new(1, -210, 1, -90),
        Fullscreen = UDim2.new(0, 0, 0, 0)
    },
    Animation = {
        Fast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Normal = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Smooth = TweenInfo.new(0.30, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    }
}

local function debugPrint(...)
    if DEBUG then
        pcall(function() print("[Mirage]", ...) end)
    end
end

-- UTILITIES
local function createInstance(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties) do
        instance[property] = value
    end
    return instance
end

local function applyCorner(parent, radius)
    return createInstance("UICorner", {
        CornerRadius = UDim.new(0, radius),
        Parent = parent
    })
end

local function applyStroke(parent, color, thickness)
    return createInstance("UIStroke", {
        Color = color,
        Thickness = thickness,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent
    })
end

local function tween(object, properties, tweenInfo)
    TweenService:Create(object, tweenInfo or CONFIG.Animation.Normal, properties):Play()
end

-- SCREENGUI CREATION
local ScreenGui = createInstance("ScreenGui", {
    Name = "MirageHubPro",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true
})

-- Tentativa robusta de parentar o ScreenGui:
-- estratégias:
-- 1) gethui() / get_hidden_gui() (muitos executores mobile/Delta aceitam)
-- 2) syn.protect_gui + CoreGui
-- 3) CoreGui (fallback)
-- 4) PlayerGui (último recurso)
local function tryGetHiddenGui()
    if type(gethui) == "function" then
        return gethui()
    end
    if type(get_hidden_gui) == "function" then
        return get_hidden_gui()
    end
    if syn and type(syn.get_hidden_gui) == "function" then
        return syn.get_hidden_gui()
    end
    return nil
end

local function parentScreenGui(gui)
    local ok = false

    -- 1) try hidden gui (gethui/get_hidden_gui) - common for mobile executors like Delta
    local hidden = tryGetHiddenGui()
    if hidden then
        pcall(function()
            -- try to protect first if available
            if syn and syn.protect_gui then
                pcall(function() syn.protect_gui(gui) end)
            elseif protect_gui then
                pcall(function() protect_gui(gui) end)
            end
            gui.Parent = hidden
            ok = (gui.Parent == hidden)
        end)
        if ok then
            debugPrint("ScreenGui parent definido em: hidden gui (gethui/get_hidden_gui)")
            return
        end
    end

    -- 2) try CoreGui with protection (many exploits require syn.protect_gui before parenting)
    pcall(function()
        if syn and syn.protect_gui then
            pcall(function() syn.protect_gui(gui) end)
        elseif protect_gui then
            pcall(function() protect_gui(gui) end)
        end
        gui.Parent = game:GetService("CoreGui")
        ok = (gui.Parent == game:GetService("CoreGui"))
    end)
    if ok then
        debugPrint("ScreenGui parent definido em: CoreGui")
        return
    end

    -- 3) fallback to PlayerGui
    pcall(function()
        local pg = LocalPlayer:WaitForChild("PlayerGui", 2)
        if pg then
            gui.Parent = pg
            ok = (gui.Parent == pg)
        end
    end)
    if ok then
        debugPrint("ScreenGui parent definido em: PlayerGui")
        return
    end

    -- 4) last attempt: set to CoreGui without protection (some environments)
    pcall(function()
        gui.Parent = game:GetService("CoreGui")
    end)
    debugPrint("ScreenGui parent final:", gui.Parent and gui.Parent:GetFullName() or "nil")
end

parentScreenGui(ScreenGui)

-- Nota: debugPrint será silencioso se DEBUG = false
debugPrint("ScreenGui parent definido em:", ScreenGui.Parent and ScreenGui.Parent:GetFullName() or "nil")

-- NOTIFICATION SYSTEM
local NotificationContainer = createInstance("Frame", {
    Name = "NotificationContainer",
    Size = UDim2.new(0, 220, 1, -20),
    Position = UDim2.new(1, -230, 0, 12),
    BackgroundTransparency = 1,
    Parent = ScreenGui
})

createInstance("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Parent = NotificationContainer
})

local function createNotification(title, message, duration, notifType)
    local notif = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = CONFIG.Colors.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = NotificationContainer
    })
    
    applyCorner(notif, 8)
    applyStroke(notif, CONFIG.Colors.Border, 1)
    
    createInstance("Frame", {
        Size = UDim2.new(0, 6, 1, 0),
        BackgroundColor3 = notifType == "success" and CONFIG.Colors.Success or 
                           notifType == "warning" and CONFIG.Colors.Warning or
                           notifType == "error" and CONFIG.Colors.Danger or CONFIG.Colors.Primary,
        BorderSizePixel = 0,
        Parent = notif
    })
    
    createInstance("TextLabel", {
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 10, 0, 12),
        BackgroundTransparency = 1,
        Text = notifType == "success" and "✓" or notifType == "warning" and "⚠" or notifType == "error" and "✕" or "ℹ",
        TextColor3 = notifType == "success" and CONFIG.Colors.Success or 
                     notifType == "warning" and CONFIG.Colors.Warning or
                     notifType == "error" and CONFIG.Colors.Danger or CONFIG.Colors.Primary,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        Parent = notif
    })
    
    createInstance("TextLabel", {
        Size = UDim2.new(1, -52, 0, 14),
        Position = UDim2.new(0, 46, 0, 8),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = CONFIG.Colors.TextPrimary,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif
    })
    
    createInstance("TextLabel", {
        Size = UDim2.new(1, -52, 0, 34),
        Position = UDim2.new(0, 46, 0, 22),
        BackgroundTransparency = 1,
        Text = message,
        TextColor3 = CONFIG.Colors.TextSecondary,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = notif
    })
    
    notif.Size = UDim2.new(1, 0, 0, 0)
    tween(notif, {Size = UDim2.new(1, 0, 0, 56)}, CONFIG.Animation.Normal)
    
    task.delay(duration or 3, function()
        if notif and notif.Parent then
            tween(notif, {Size = UDim2.new(1, 0, 0, 0)}, CONFIG.Animation.Normal)
            task.wait(0.26)
            if notif and notif.Parent then
                notif:Destroy()
            end
        end
    end)
end

-- MAIN FRAME
local MainFrame = createInstance("Frame", {
    Name = "MainFrame",
    Size = CONFIG.Sizes.Normal,
    Position = CONFIG.Positions.Normal,
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = CONFIG.Colors.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Parent = ScreenGui
})

applyCorner(MainFrame, 8)
applyStroke(MainFrame, CONFIG.Colors.Border, 1)

local Shadow = createInstance("ImageLabel", {
    Name = "Shadow",
    BackgroundTransparency = 1,
    Position = UDim2.new(0, -8, 0, -8),
    Size = UDim2.new(1, 16, 1, 16),
    ZIndex = 0,
    Image = "rbxassetid://6014261993",
    ImageColor3 = Color3.fromRGB(0, 0, 0),
    ImageTransparency = 0.55,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(100, 100, 100, 100),
    Parent = MainFrame
})

MainFrame.Active = true
MainFrame.Visible = true -- garante visibilidade

-- TITLE BAR
local TitleBar = createInstance("Frame", {
    Name = "TitleBar",
    Size = UDim2.new(1, 0, 0, 26),
    BackgroundColor3 = CONFIG.Colors.Surface,
    BorderSizePixel = 0,
    Parent = MainFrame
})

applyCorner(TitleBar, 8)
TitleBar.Active = true

createInstance("Frame", {
    Size = UDim2.new(1, 0, 0, 5),
    Position = UDim2.new(0, 0, 1, -5),
    BackgroundColor3 = CONFIG.Colors.Surface,
    BorderSizePixel = 0,
    Parent = TitleBar
})

local function createMacCircle(color, position)
    local circle = createInstance("Frame", {
        Size = UDim2.new(0, 6, 0, 6),
        Position = position,
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Parent = TitleBar
    })
    applyCorner(circle, 4)
    return circle
end

createMacCircle(CONFIG.Colors.MacRed, UDim2.new(0, 8, 0, 10))
createMacCircle(CONFIG.Colors.MacYellow, UDim2.new(0, 20, 0, 10))
createMacCircle(CONFIG.Colors.MacGreen, UDim2.new(0, 32, 0, 10))

createInstance("TextLabel", {
    Name = "Title",
    Size = UDim2.new(1, -120, 0, 14),
    Position = UDim2.new(0, 44, 0, 6),
    BackgroundTransparency = 1,
    Text = "Mirage Hub",
    TextColor3 = CONFIG.Colors.TextPrimary,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = TitleBar
})

createInstance("TextLabel", {
    Name = "Subtitle",
    Size = UDim2.new(1, -120, 0, 10),
    Position = UDim2.new(0, 44, 0, 18),
    BackgroundTransparency = 1,
    Text = "9 Nights in the Forest",
    TextColor3 = CONFIG.Colors.TextSecondary,
    Font = Enum.Font.Gotham,
    TextSize = 8,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = TitleBar
})

local StatusIndicator = createInstance("Frame", {
    Name = "StatusIndicator",
    Size = UDim2.new(0, 8, 0, 8),
    Position = UDim2.new(1, -84, 0, 9),
    BackgroundColor3 = CONFIG.Colors.Success,
    BorderSizePixel = 0,
    Parent = TitleBar
})

applyCorner(StatusIndicator, 4)

local pulseConnection = RunService.RenderStepped:Connect(function()
    local time = tick()
    StatusIndicator.BackgroundColor3 = Color3.fromRGB(
        math.floor(67 + math.sin(time * 2) * 12),
        math.floor(181 + math.sin(time * 2) * 12),
        math.floor(129 + math.sin(time * 2) * 12)
    )
end)

local function createControlButton(iconText, name, position, hoverColor)
    local button = createInstance("TextButton", {
        Name = name,
        Size = UDim2.new(0, 18, 0, 18),
        Position = position,
        BackgroundColor3 = CONFIG.Colors.SurfaceLight,
        BorderSizePixel = 0,
        Text = iconText,
        TextColor3 = CONFIG.Colors.TextSecondary,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = TitleBar
    })
    
    applyCorner(button, 6)
    
    button.MouseEnter:Connect(function()
        tween(button, {
            BackgroundColor3 = hoverColor or CONFIG.Colors.Border,
            TextColor3 = CONFIG.Colors.TextPrimary
        }, CONFIG.Animation.Fast)
    end)
    
    button.MouseLeave:Connect(function()
        tween(button, {
            BackgroundColor3 = CONFIG.Colors.SurfaceLight,
            TextColor3 = CONFIG.Colors.TextSecondary
        }, CONFIG.Animation.Fast)
    end)
    
    return button
end

local MinimizeBtn = createControlButton("—", "Minimize", UDim2.new(1, -84, 0, 4), CONFIG.Colors.Border)
local MaximizeBtn = createControlButton("□", "Maximize", UDim2.new(1, -56, 0, 4), CONFIG.Colors.Border)
local CloseBtn = createControlButton("✕", "Close", UDim2.new(1, -28, 0, 4), CONFIG.Colors.Danger)

-- CONTENT CONTAINER
local ContentContainer = createInstance("Frame", {
    Name = "Content",
    Size = UDim2.new(1, 0, 1, -56),
    Position = UDim2.new(0, 0, 0, 26),
    BackgroundTransparency = 1,
    Parent = MainFrame
})

-- MAIN CONTENT (sem sidebar para mais espaço)
local MainContent = createInstance("Frame", {
    Name = "MainContent",
    Size = UDim2.new(1, 0, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    Parent = ContentContainer
})

local ScrollFrame = createInstance("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 6,
    ScrollBarImageColor3 = CONFIG.Colors.Border,
    CanvasSize = UDim2.new(0, 0, 0, 900),
    Parent = MainContent
})

local PageTitle = createInstance("TextLabel", {
    Size = UDim2.new(1, -20, 0, 20),
    Position = UDim2.new(0, 12, 0, 8),
    BackgroundTransparency = 1,
    Text = "9 Nights in the Forest - Features",
    TextColor3 = CONFIG.Colors.TextPrimary,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = ScrollFrame
})

local PageDescription = createInstance("TextLabel", {
    Size = UDim2.new(1, -20, 0, 14),
    Position = UDim2.new(0, 12, 0, 30),
    BackgroundTransparency = 1,
    Text = "Automated farming and utility tools",
    TextColor3 = CONFIG.Colors.TextSecondary,
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = ScrollFrame
})

-- SECTION BUILDER
local function createSection(title, description, position, width)
    local section = createInstance("Frame", {
        Name = title,
        Size = UDim2.new(width, -8, 0, 0),
        Position = position,
        BackgroundColor3 = CONFIG.Colors.Surface,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = ScrollFrame
    })
    
    applyCorner(section, 6)
    applyStroke(section, CONFIG.Colors.Border, 1)
    
    createInstance("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = section
    })
    
    createInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = CONFIG.Colors.TextPrimary,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = section
    })
    
    if description then
        createInstance("TextLabel", {
            Size = UDim2.new(1, 0, 0, 12),
            Position = UDim2.new(0, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = description,
            TextColor3 = CONFIG.Colors.TextSecondary,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = section
        })
    end
    
    local container = createInstance("Frame", {
        Name = "Container",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, description and 36 or 28),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = section
    })
    
    createInstance("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = container
    })
    
    return container
end

-- === 9 NIGHTS IN THE FOREST - AURA KILL SYSTEM ===

-- Estado global
local mobAuraEnabled = false
local mobAuraRange = 100
local mobAuraDamage = 100 -- Dano em porcentagem (100 = mata instantâneo)
local treeAuraEnabled = false
local treeAuraRange = 100
local treeAuraDamage = 100 -- Dano em porcentagem (100 = destrói instantâneo)

-- Cooldowns para evitar spam
local lastDamageTimes = setmetatable({}, {__mode = "k"}) -- weak keys para não prender referências

-- Nomes dos mobs no jogo (case-insensitive matching)
local mobNames = {
    "wolf", "alfa wolf", "alpha wolf", "bear", "cultist", "alien",
    "arctic fox", "polar bear", "mammoth", "deer", "monster"
}

-- Nomes de árvores (case-insensitive matching)
local treeNames = {
    "tree", "trunk", "wood", "oak", "pine", "birch"
}

-- Função para verificar se um nome contém um dos tokens
local function nameMatches(name, tokens)
    if not name then return false end
    local lowerName = string.lower(name)
    for _, token in ipairs(tokens) do
        if string.find(lowerName, token, 1, true) then
            return true
        end
    end
    return false
end

-- Função para encontrar o Humanoid em um Model
local function findHumanoid(model)
    if not model or not model:IsA("Model") then return nil end
    
    -- Procura direto
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then return humanoid end
    
    -- Procura em descendants
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("Humanoid") then
            return desc
        end
    end
    
    return nil
end

-- Função para encontrar a parte principal (HumanoidRootPart ou PrimaryPart)
local function findRootPart(model)
    if not model or not model:IsA("Model") then return nil end
    
    -- Tenta HumanoidRootPart primeiro
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then return hrp end
    
    -- Tenta RootPart
    local root = model:FindFirstChild("RootPart")
    if root and root:IsA("BasePart") then return root end
    
    -- Tenta PrimaryPart
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
        return model.PrimaryPart
    end
    
    -- Procura qualquer BasePart
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("BasePart") then
            return child
        end
    end
    
    return nil
end

-- Função ROBUSTA para aplicar dano COM PORCENTAGEM
local function applyDamage(model, damagePercent)
    if not model or not model.Parent then return false end
    
    local success = false
    
    -- Método 1: Usar Humanoid (com cálculo de porcentagem)
    local humanoid = findHumanoid(model)
    if humanoid then
        pcall(function()
            if humanoid.Health > 0 then
                local maxHealth = humanoid.MaxHealth or 100
                local damageAmount = (maxHealth * damagePercent) / 100
                
                -- Se for 100%, garantir morte instantânea
                if damagePercent >= 100 then
                    humanoid.Health = 0
                else
                    humanoid.Health = math.max(0, humanoid.Health - damageAmount)
                end
                
                success = true
                debugPrint("Dano aplicado:", model.Name, "| HP restante:", humanoid.Health, "| Dano%:", damagePercent)
            end
        end)
    end
    
    -- Método 2: Modificar Health diretamente (fallback)
    if humanoid and not success then
        pcall(function()
            if humanoid.Health > 0 then
                if damagePercent >= 100 then
                    humanoid.Health = 0
                else
                    local maxHealth = humanoid.MaxHealth or 100
                    local damageAmount = (maxHealth * damagePercent) / 100
                    humanoid.Health = math.max(0, humanoid.Health - damageAmount)
                end
                success = true
                debugPrint("Dano direto aplicado:", model.Name)
            end
        end)
    end
    
    -- Método 3: Procurar NumberValue "Health" no Model
    if not success then
        local healthValue = model:FindFirstChild("Health")
        if healthValue and healthValue:IsA("NumberValue") then
            pcall(function()
                if healthValue.Value > 0 then
                    if damagePercent >= 100 then
                        healthValue.Value = 0
                    else
                        local maxHealth = model:FindFirstChild("MaxHealth")
                        local max = (maxHealth and maxHealth:IsA("NumberValue")) and maxHealth.Value or 100
                        local damageAmount = (max * damagePercent) / 100
                        healthValue.Value = math.max(0, healthValue.Value - damageAmount)
                    end
                    success = true
                    debugPrint("Dano aplicado via NumberValue:", model.Name)
                end
            end)
        end
    end
    
    -- Método 4: FireServer para jogos que usam RemoteEvents
    if not success then
        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Events")
            if remotes then
                local damageRemote = remotes:FindFirstChild("Damage") or remotes:FindFirstChild("DealDamage") or remotes:FindFirstChild("Hit")
                if damageRemote and (damageRemote:IsA("RemoteEvent") or damageRemote:IsA("RemoteFunction")) then
                    -- Calcula dano real baseado na porcentagem (se possível)
                    local damageAmount = 999999
                    if damagePercent < 100 and humanoid then
                        damageAmount = (humanoid.MaxHealth * damagePercent) / 100
                    end
                    if damageRemote:IsA("RemoteEvent") then
                        damageRemote:FireServer(model, damageAmount)
                        success = true
                    elseif damageRemote:IsA("RemoteFunction") then
                        pcall(function() damageRemote:InvokeServer(model, damageAmount) end)
                        success = true
                    end
                    debugPrint("Dano aplicado via Remote:", model.Name)
                end
            end
        end)
    end
    
    -- Método 5: Destruir partes (último recurso - APENAS se for 100%)
    if not success and damagePercent >= 100 then
        local rootPart = findRootPart(model)
        if rootPart then
            pcall(function()
                rootPart:BreakJoints()
                success = true
                debugPrint("Partes quebradas (100% damage):", model.Name)
            end)
        end
    end
    
    return success
end

-- Loop principal do Mob Aura
local function mobAuraLoop()
    if not mobAuraEnabled then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local playerPos = hrp.Position
    local currentTime = tick()
    
    -- Procura por mobs no workspace
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and nameMatches(obj.Name, mobNames) then
            local mobHumanoid = findHumanoid(obj)
            local mobRoot = findRootPart(obj)
            
            if mobHumanoid and mobRoot and mobHumanoid.Health > 0 then
                local distance = (mobRoot.Position - playerPos).Magnitude
                
                if distance <= mobAuraRange then
                    -- Cooldown de 0.5 segundos por mob
                    local lastTime = lastDamageTimes[obj] or 0
                    if currentTime - lastTime >= 0.5 then
                        local success = applyDamage(obj, mobAuraDamage)
                        if success then
                            lastDamageTimes[obj] = currentTime
                        end
                    end
                end
            end
        end
    end
end

-- Loop principal do Tree Aura
local function treeAuraLoop()
    if not treeAuraEnabled then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local playerPos = hrp.Position
    local currentTime = tick()
    
    -- Procura por árvores no workspace
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and nameMatches(obj.Name, treeNames) then
            local treeHumanoid = findHumanoid(obj)
            local treeRoot = findRootPart(obj)
            
            -- Árvores podem não ter Humanoid
            if treeRoot then
                local distance = (treeRoot.Position - playerPos).Magnitude
                
                if distance <= treeAuraRange then
                    local lastTime = lastDamageTimes[obj] or 0
                    if currentTime - lastTime >= 0.5 then
                        local success = applyDamage(obj, treeAuraDamage)
                        if success then
                            lastDamageTimes[obj] = currentTime
                        end
                    end
                end
            end
        end
    end
end

-- Conexão do RunService
local auraConnection = RunService.Heartbeat:Connect(function()
    pcall(mobAuraLoop)
    pcall(treeAuraLoop)
end)

-- === UI COMPONENTS ===

local function createToggle(text, parent, initial)
    local frame = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Parent = parent
    })
    local label = createInstance("TextLabel", {
        Size = UDim2.new(0.6, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = CONFIG.Colors.TextPrimary,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })
    local btn = createInstance("TextButton", {
        Size = UDim2.new(0, 56, 0, 20),
        Position = UDim2.new(1, -60, 0.5, -10),
        BackgroundColor3 = initial and CONFIG.Colors.Primary or CONFIG.Colors.SurfaceLight,
        BorderSizePixel = 0,
        Text = initial and "ON" or "OFF",
        TextColor3 = initial and CONFIG.Colors.TextPrimary or CONFIG.Colors.TextSecondary,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        AutoButtonColor = false,
        Parent = frame
    })
    applyCorner(btn, 6)
    applyStroke(btn, CONFIG.Colors.Border, 1)
    return frame, btn
end

local function createSlider(labelText, min, max, step, parent, initialValue, onChange)
    local frame = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
        Parent = parent
    })
    createInstance("TextLabel", {
        Size = UDim2.new(0.6, 0, 0, 18),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Text = labelText,
        TextColor3 = CONFIG.Colors.TextPrimary,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })
    local valueLabel = createInstance("TextLabel", {
        Size = UDim2.new(0.35, 0, 0, 18),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.65, 0, 0, 0),
        Text = tostring(initialValue),
        TextColor3 = CONFIG.Colors.Primary,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = frame
    })
    local bar = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 0, 24),
        BackgroundColor3 = CONFIG.Colors.SurfaceLight,
        BorderSizePixel = 0,
        Parent = frame
    })
    applyCorner(bar, 6)
    applyStroke(bar, CONFIG.Colors.Border, 1)
    local fill = createInstance("Frame", {
        Size = UDim2.new((initialValue - min) / math.max(1, (max - min)), 0, 1, 0),
        BackgroundColor3 = CONFIG.Colors.Primary,
        BorderSizePixel = 0,
        Parent = bar
    })
    applyCorner(fill, 6)
    local handle = createInstance("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0),
        BackgroundColor3 = CONFIG.Colors.Surface,
        BorderSizePixel = 0,
        Parent = bar
    })
    applyCorner(handle, 8)
    applyStroke(handle, CONFIG.Colors.Primary, 2)

    local dragging = false

    local function updateValue(input)
        local relativeX = math.clamp((input.Position.X - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
        local rawValue = min + (relativeX * (max - min))
        local value = math.floor(rawValue / step + 0.5) * step
        value = math.clamp(value, min, max)
        
        valueLabel.Text = tostring(value)
        fill.Size = UDim2.new((value - min) / math.max(1, (max - min)), 0, 1, 0)
        handle.Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0)
        
        if onChange then
            onChange(value)
        end
        
        return value
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateValue(input)
        end
    end)

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateValue(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return frame, valueLabel
end

-- SECTIONS
local MobSection = createSection("Mob Aura Kill", "Automatically kill mobs within range", UDim2.new(0, 12, 0, 52), 1)
local TreeSection = createSection("Tree Aura", "Automatically destroy trees within range", UDim2.new(0, 12, 0, 280), 1)
local InfoSection = createSection("Info", "Current status and statistics", UDim2.new(0, 12, 0, 510), 1)

-- MOB AURA CONTROLS
local mobToggleFrame, mobToggleBtn = createToggle("Enable Mob Aura", MobSection, false)
local mobRangeSliderFrame, mobRangeSliderLabel = createSlider("Range (studs)", 0, 2000, 10, MobSection, mobAuraRange, function(value)
    mobAuraRange = value
    debugPrint("Mob Aura Range:", value)
end)
local mobDamageSliderFrame, mobDamageSliderLabel = createSlider("Damage (%)", 1, 100, 1, MobSection, mobAuraDamage, function(value)
    mobAuraDamage = value
    debugPrint("Mob Aura Damage:", value, "%")
end)

mobToggleBtn.MouseButton1Click:Connect(function()
    mobAuraEnabled = not mobAuraEnabled
    if mobAuraEnabled then
        mobToggleBtn.BackgroundColor3 = CONFIG.Colors.Primary
        mobToggleBtn.Text = "ON"
        mobToggleBtn.TextColor3 = CONFIG.Colors.TextPrimary
        createNotification("Mob Aura", "Ativado! Range: " .. mobAuraRange .. " | Dano: " .. mobAuraDamage .. "%", 3, "success")
        debugPrint("Mob Aura: ATIVADO - Range:", mobAuraRange, "- Dano:", mobAuraDamage, "%")
    else
        mobToggleBtn.BackgroundColor3 = CONFIG.Colors.SurfaceLight
        mobToggleBtn.Text = "OFF"
        mobToggleBtn.TextColor3 = CONFIG.Colors.TextSecondary
        createNotification("Mob Aura", "Desativado", 2, "warning")
        debugPrint("Mob Aura: DESATIVADO")
    end
end)

-- TREE AURA CONTROLS
local treeToggleFrame, treeToggleBtn = createToggle("Enable Tree Aura", TreeSection, false)
local treeRangeSliderFrame, treeRangeSliderLabel = createSlider("Range (studs)", 0, 2000, 10, TreeSection, treeAuraRange, function(value)
    treeAuraRange = value
    debugPrint("Tree Aura Range:", value)
end)
local treeDamageSliderFrame, treeDamageSliderLabel = createSlider("Damage (%)", 1, 100, 1, TreeSection, treeAuraDamage, function(value)
    treeAuraDamage = value
    debugPrint("Tree Aura Damage:", value, "%")
end)

treeToggleBtn.MouseButton1Click:Connect(function()
    treeAuraEnabled = not treeAuraEnabled
    if treeAuraEnabled then
        treeToggleBtn.BackgroundColor3 = CONFIG.Colors.Primary
        treeToggleBtn.Text = "ON"
        treeToggleBtn.TextColor3 = CONFIG.Colors.TextPrimary
        createNotification("Tree Aura", "Ativado! Range: " .. treeAuraRange .. " | Dano: " .. treeAuraDamage .. "%", 3, "success")
        debugPrint("Tree Aura: ATIVADO - Range:", treeAuraRange, "- Dano:", treeAuraDamage, "%")
    else
        treeToggleBtn.BackgroundColor3 = CONFIG.Colors.SurfaceLight
        treeToggleBtn.Text = "OFF"
        treeToggleBtn.TextColor3 = CONFIG.Colors.TextSecondary
        createNotification("Tree Aura", "Desativado", 2, "warning")
        debugPrint("Tree Aura: DESATIVADO")
    end
end)

-- INFO DISPLAY (corrigido para evitar erro de sintaxe)
local infoText = createInstance("TextLabel", {
    Size = UDim2.new(1, 0, 0, 140),
    BackgroundTransparency = 1,
    Text = "• Mob Aura: Mata mobs automaticamente (wolves, bears, cultists...)\n• Tree Aura: Destrói árvores para farm de madeira\n• Damage: 100% = morte/destruição instantânea\n• Range: Ajustável pelo slider",
    TextColor3 = CONFIG.Colors.TextSecondary,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true,
    Parent = InfoSection
})

-- FOOTER
local Footer = createInstance("Frame", {
    Name = "Footer",
    Size = UDim2.new(1, 0, 0, 20),
    Position = UDim2.new(0, 0, 1, -20),
    BackgroundColor3 = CONFIG.Colors.Surface,
    BorderSizePixel = 0,
    Parent = MainFrame
})

createInstance("Frame", {
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = CONFIG.Colors.Border,
    BorderSizePixel = 0,
    Parent = Footer
})

createInstance("TextLabel", {
    Size = UDim2.new(0, 180, 1, 0),
    Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text = "v2.1.1 • 9 Nights Edition",
    TextColor3 = CONFIG.Colors.TextSecondary,
    Font = Enum.Font.Gotham,
    TextSize = 8,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = Footer
})

createInstance("TextLabel", {
    Size = UDim2.new(0, 140, 1, 0),
    Position = UDim2.new(1, -148, 0, 0),
    BackgroundTransparency = 1,
    Text = "● Connected",
    TextColor3 = CONFIG.Colors.Success,
    Font = Enum.Font.GothamMedium,
    TextSize = 8,
    TextXAlignment = Enum.TextXAlignment.Right,
    Parent = Footer
})

-- WINDOW CONTROLS
local currentState = "Normal"
local previousState = "Normal"

local function applyState(state)
    if state == "Floating" then
        tween(MainFrame, {Size = CONFIG.Sizes.Floating, Position = CONFIG.Positions.Floating}, CONFIG.Animation.Fast)
        ContentContainer.Visible = false
        Footer.Visible = false
    elseif state == "Fullscreen" then
        tween(MainFrame, {Size = CONFIG.Sizes.Fullscreen, Position = CONFIG.Positions.Fullscreen}, CONFIG.Animation.Smooth)
        ContentContainer.Visible = true
        Footer.Visible = true
    else
        tween(MainFrame, {Size = CONFIG.Sizes.Normal, Position = CONFIG.Positions.Normal}, CONFIG.Animation.Normal)
        ContentContainer.Visible = true
        Footer.Visible = true
    end
    currentState = state
end

CloseBtn.MouseButton1Click:Connect(function()
    tween(MainFrame, {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In))
    task.wait(0.25)
    if ScreenGui and ScreenGui.Parent then
        ScreenGui:Destroy()
    end
end)

MinimizeBtn.MouseButton1Click:Connect(function()
    if currentState ~= "Floating" then
        previousState = currentState
        applyState("Floating")
    else
        applyState(previousState == "Floating" and "Normal" or previousState)
    end
end)

MaximizeBtn.MouseButton1Click:Connect(function()
    if currentState ~= "Fullscreen" then
        previousState = currentState
        applyState("Fullscreen")
    else
        applyState("Normal")
    end
end)

-- DRAG SYSTEM
local dragStartPos, dragStartFramePos
local isDragging = false

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
        dragStartPos = input.Position
        dragStartFramePos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStartPos
        MainFrame.Position = UDim2.new(
            dragStartFramePos.X.Scale,
            dragStartFramePos.X.Offset + delta.X,
            dragStartFramePos.Y.Scale,
            dragStartFramePos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
    end
end)

-- KEYBIND TOGGLE (RightShift)
local isGuiVisible = true
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        isGuiVisible = not isGuiVisible
        MainFrame.Visible = isGuiVisible
        if isGuiVisible then
            createNotification("GUI", "GUI mostrado", 1.5, "success")
        else
            createNotification("GUI", "GUI ocultado", 1.5, "warning")
        end
    end
end)

-- CLEANUP ON DESTROY
ScreenGui.Destroying:Connect(function()
    if pulseConnection then pcall(function() pulseConnection:Disconnect() end) end
    if auraConnection then pcall(function() auraConnection:Disconnect() end) end
    debugPrint("Mirage Hub: Descarregado")
end)

-- INITIALIZATION
task.wait(0.5)
createNotification(
    "Mirage Hub Loaded",
    "9 Nights Edition v2.1.1 • RightShift para toggle",
    4,
    "success"
)

debugPrint("=== MIRAGE HUB CARREGADO ===")
debugPrint("Mob Aura: Pronto")
debugPrint("Tree Aura: Pronto")
debugPrint("GUI: Funcionando")
debugPrint("============================")

-- END OF SCRIPT
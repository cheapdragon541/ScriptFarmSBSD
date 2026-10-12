--[[ Auto-Farm v3.1 - Key Presser + Enemy Attraction (Only Enemies folder) ]]
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local VIM = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- ==== ЗАЩИЩЁННЫЙ РОДИТЕЛЬ ====
local function getSafeParent()
    local ok, hui = pcall(function() return gethui() end)
    if ok and hui then return hui end
    local ok2, cg = pcall(function() return CoreGui end)
    if ok2 and cg then return cg end
    return player:WaitForChild("PlayerGui")
end

-- ==== СОСТОЯНИЕ ====
if _G.AutoFarmState == nil then
    _G.AutoFarmState = {
        running = false,
        lmbOn = false,
        keys = "E",
        interval = 0.1,
        hold = 0.05,
        attract = false,
        attractRange = 200,
        attractThread = nil,
        loopThread = nil,
        gui = nil,
    }
end
local S = _G.AutoFarmState

-- ==== ПОИСК ВРАГОВ (ТОЛЬКО ИЗ ПАПКИ ENEMIES) ====
local function getEnemies()
    local enemies = {}
    local myChar = player.Character
    if not myChar then return enemies end

    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return enemies end

    for _, obj in ipairs(enemiesFolder:GetChildren()) do
        if obj:IsA("Model") 
            and obj:FindFirstChildOfClass("Humanoid") 
            and obj:FindFirstChild("HumanoidRootPart") 
        then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(enemies, obj)
            end
        end
    end
    return enemies
end

-- ==== ПРИТЯЖЕНИЕ ====
local function attractEnemies()
    local myChar = player.Character
    if not myChar then return 0 end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return 0 end

    local enemies = getEnemies()
    local count = 0
    for _, enemy in ipairs(enemies) do
        local eRoot = enemy:FindFirstChild("HumanoidRootPart")
        if eRoot then
            local dist = (eRoot.Position - myRoot.Position).Magnitude
            if dist <= S.attractRange then
                pcall(function()
                    eRoot.CFrame = myRoot.CFrame * CFrame.new(math.random(-6, 6), 0, math.random(-6, 6))
                    eRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    eRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end)
                count = count + 1
            end
        end
    end
    return count
end

-- ==== GUI ====
local function buildGUI()
    if S.gui and S.gui.Parent then return S.gui end

    local parent = getSafeParent()
    local old = parent:FindFirstChild("AutoFarmGUI")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "AutoFarmGUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999
    gui.Parent = parent

    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(gui)
        elseif protect_gui then protect_gui(gui) end
    end)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 320, 0, 470)
    frame.Position = UDim2.new(0, 20, 0, 60)
    frame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    title.Text = "⚙️ Auto-Farm v3.1"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = frame

    -- Секция 1: Автокликер
    local sec1 = Instance.new("TextLabel")
    sec1.Size = UDim2.new(1, -20, 0, 22)
    sec1.Position = UDim2.new(0, 10, 0, 42)
    sec1.BackgroundTransparency = 1
    sec1.Text = "— АВТОКЛИКЕР —"
    sec1.TextColor3 = Color3.fromRGB(120, 180, 255)
    sec1.Font = Enum.Font.GothamBold
    sec1.TextSize = 12
    sec1.TextXAlignment = Enum.TextXAlignment.Left
    sec1.Parent = frame

    local keyBox = Instance.new("TextBox")
    keyBox.Size = UDim2.new(1, -20, 0, 28)
    keyBox.Position = UDim2.new(0, 10, 0, 68)
    keyBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    keyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyBox.PlaceholderText = "E,Q,R,One,Two"
    keyBox.Text = S.keys
    keyBox.Font = Enum.Font.Gotham
    keyBox.TextSize = 13
    keyBox.Parent = frame
    keyBox:GetPropertyChangedSignal("Text"):Connect(function() S.keys = keyBox.Text end)

    local intBox = Instance.new("TextBox")
    intBox.Size = UDim2.new(0.5, -15, 0, 28)
    intBox.Position = UDim2.new(0, 10, 0, 102)
    intBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    intBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    intBox.Text = tostring(S.interval)
    intBox.Font = Enum.Font.Gotham
    intBox.TextSize = 13
    intBox.PlaceholderText = "Интервал"
    intBox.Parent = frame
    intBox:GetPropertyChangedSignal("Text"):Connect(function() S.interval = tonumber(intBox.Text) or 0.1 end)

    local holdBox = Instance.new("TextBox")
    holdBox.Size = UDim2.new(0.5, -15, 0, 28)
    holdBox.Position = UDim2.new(0.5, 5, 0, 102)
    holdBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    holdBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    holdBox.Text = tostring(S.hold)
    holdBox.Font = Enum.Font.Gotham
    holdBox.TextSize = 13
    holdBox.PlaceholderText = "Удержание"
    holdBox.Parent = frame
    holdBox:GetPropertyChangedSignal("Text"):Connect(function() S.hold = tonumber(holdBox.Text) or 0.05 end)

    local lmbBtn = Instance.new("TextButton")
    lmbBtn.Size = UDim2.new(1, -20, 0, 30)
    lmbBtn.Position = UDim2.new(0, 10, 0, 136)
    lmbBtn.BackgroundColor3 = S.lmbOn and Color3.fromRGB(60, 140, 60) or Color3.fromRGB(45, 45, 55)
    lmbBtn.Text = S.lmbOn and "🖱 ЛКМ: ВКЛ" or "🖱 ЛКМ: ВЫКЛ"
    lmbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    lmbBtn.Font = Enum.Font.Gotham
    lmbBtn.TextSize = 13
    lmbBtn.Parent = frame

    -- Секция 2: Притяжение
    local sec2 = Instance.new("TextLabel")
    sec2.Size = UDim2.new(1, -20, 0, 22)
    sec2.Position = UDim2.new(0, 10, 0, 178)
    sec2.BackgroundTransparency = 1
    sec2.Text = "— ПРИТЯЖЕНИЕ ВРАГОВ —"
    sec2.TextColor3 = Color3.fromRGB(255, 180, 120)
    sec2.Font = Enum.Font.GothamBold
    sec2.TextSize = 12
    sec2.TextXAlignment = Enum.TextXAlignment.Left
    sec2.Parent = frame

    local rangeBox = Instance.new("TextBox")
    rangeBox.Size = UDim2.new(1, -20, 0, 28)
    rangeBox.Position = UDim2.new(0, 10, 0, 204)
    rangeBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    rangeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    rangeBox.Text = tostring(S.attractRange)
    rangeBox.Font = Enum.Font.Gotham
    rangeBox.TextSize = 13
    rangeBox.PlaceholderText = "Радиус притяжения (студы)"
    rangeBox.Parent = frame
    rangeBox:GetPropertyChangedSignal("Text"):Connect(function() S.attractRange = tonumber(rangeBox.Text) or 200 end)

    local attractBtn = Instance.new("TextButton")
    attractBtn.Size = UDim2.new(1, -20, 0, 34)
    attractBtn.Position = UDim2.new(0, 10, 0, 238)
    attractBtn.BackgroundColor3 = S.attract and Color3.fromRGB(80, 60, 140) or Color3.fromRGB(45, 45, 55)
    attractBtn.Text = S.attract and "🧲 Притяжение: ВКЛ" or "🧲 Притяжение: ВЫКЛ"
    attractBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    attractBtn.Font = Enum.Font.GothamBold
    attractBtn.TextSize = 13
    attractBtn.Parent = frame

    local attractStatus = Instance.new("TextLabel")
    attractStatus.Size = UDim2.new(1, -20, 0, 18)
    attractStatus.Position = UDim2.new(0, 10, 0, 276)
    attractStatus.BackgroundTransparency = 1
    attractStatus.Text = "Врагов найдено: 0"
    attractStatus.TextColor3 = Color3.fromRGB(160, 160, 160)
    attractStatus.Font = Enum.Font.Gotham
    attractStatus.TextSize = 11
    attractStatus.TextXAlignment = Enum.TextXAlignment.Left
    attractStatus.Parent = frame

    -- Секция 3: Управление
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, -20, 0, 42)
    toggleBtn.Position = UDim2.new(0, 10, 0, 306)
    toggleBtn.BackgroundColor3 = S.running and Color3.fromRGB(140, 60, 60) or Color3.fromRGB(60, 140, 60)
    toggleBtn.Text = S.running and "⏹ СТОП" or "▶️ СТАРТ"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 15
    toggleBtn.Parent = frame

    local log = Instance.new("TextLabel")
    log.Size = UDim2.new(1, -20, 0, 110)
    log.Position = UDim2.new(0, 10, 0, 356)
    log.BackgroundTransparency = 1
    log.Text = "Лог:"
    log.TextColor3 = Color3.fromRGB(180, 180, 180)
    log.Font = Enum.Font.Code
    log.TextSize = 11
    log.TextWrapped = true
    log.TextXAlignment = Enum.TextXAlignment.Left
    log.TextYAlignment = Enum.TextYAlignment.Top
    log.Parent = frame

    S.gui = gui
    S.frame = frame
    S.keyBox = keyBox
    S.intBox = intBox
    S.holdBox = holdBox
    S.lmbBtn = lmbBtn
    S.rangeBox = rangeBox
    S.attractBtn = attractBtn
    S.attractStatus = attractStatus
    S.toggleBtn = toggleBtn
    S.log = log

    -- ЛОГИКА
    local function pressKey(code)
        pcall(function()
            VIM:SendKeyEvent(true, code, false, game)
            task.wait(S.hold)
            VIM:SendKeyEvent(false, code, false, game)
        end)
    end

    local function clickMouse()
        pcall(function()
            local x, y = mouse.X, mouse.Y
            VIM:SendMouseButtonEvent(x, y, 0, true, game, 1)
            task.wait(S.hold)
            VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
        end)
    end

    local function parseKeys(str)
        local keys = {}
        for k in string.gmatch(str, "([^,]+)") do
            local t = k:gsub("^%s+", ""):gsub("%s+$", "")
            if t ~= "" then table.insert(keys, t) end
        end
        return keys
    end

    local function startLoop()
        if S.loopThread then pcall(task.cancel, S.loopThread) S.loopThread = nil end
        S.loopThread = task.spawn(function()
            while S.running do
                pcall(function()
                    local keys = parseKeys(S.keys)
                    for _, k in ipairs(keys) do
                        if not S.running then break end
                        local code = Enum.KeyCode[k]
                        if not code then code = Enum.KeyCode[k:sub(1,1):upper() .. k:sub(2):lower()] end
                        if code then pressKey(code) end
                        task.wait(S.interval)
                    end
                    if S.lmbOn and S.running then clickMouse() end
                end)
                task.wait(S.interval)
            end
        end)
    end

    local function startAttract()
        if S.attractThread then pcall(task.cancel, S.attractThread) S.attractThread = nil end
        S.attractThread = task.spawn(function()
            while S.attract do
                local ok, count = pcall(attractEnemies)
                if ok and S.attractStatus then
                    S.attractStatus.Text = "Врагов найдено: " .. tostring(count)
                end
                task.wait(0.15)
            end
        end)
    end

    lmbBtn.MouseButton1Click:Connect(function()
        S.lmbOn = not S.lmbOn
        lmbBtn.Text = S.lmbOn and "🖱 ЛКМ: ВКЛ" or "🖱 ЛКМ: ВЫКЛ"
        lmbBtn.BackgroundColor3 = S.lmbOn and Color3.fromRGB(60, 140, 60) or Color3.fromRGB(45, 45, 55)
    end)

    attractBtn.MouseButton1Click:Connect(function()
        S.attract = not S.attract
        attractBtn.Text = S.attract and "🧲 Притяжение: ВКЛ" or "🧲 Притяжение: ВЫКЛ"
        attractBtn.BackgroundColor3 = S.attract and Color3.fromRGB(80, 60, 140) or Color3.fromRGB(45, 45, 55)
        if S.attract then
            startAttract()
            log.Text = "Лог:\nПритяжение включено (радиус " .. S.attractRange .. ")"
        else
            if S.attractThread then pcall(task.cancel, S.attractThread) S.attractThread = nil end
            log.Text = "Лог:\nПритяжение выключено"
        end
    end)

    toggleBtn.MouseButton1Click:Connect(function()
        S.running = not S.running
        if S.running then
            toggleBtn.Text = "⏹ СТОП"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(140, 60, 60)
            startLoop()
            log.Text = "Лог:\nАвтокликер запущен"
        else
            toggleBtn.Text = "▶️ СТАРТ"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 60)
            if S.loopThread then pcall(task.cancel, S.loopThread) S.loopThread = nil end
            log.Text = "Лог:\nАвтокликер остановлен"
        end
    end)

    if S.running then startLoop() end
    if S.attract then startAttract() end

    return gui
end

buildGUI()

-- ==== АВТО-ВОССТАНОВЛЕНИЕ ====
task.spawn(function()
    while true do
        task.wait(2)
        local parent = getSafeParent()
        local existing = parent:FindFirstChild("AutoFarmGUI")
        if not existing or not S.gui or not S.gui.Parent then
            buildGUI()
        end
    end
end)

player.CharacterAdded:Connect(function()
    task.wait(1)
    if not S.gui or not S.gui.Parent then buildGUI() end
end)

print("✅ Auto-Farm v3.1 загружен (кликер + притяжение только врагов)")

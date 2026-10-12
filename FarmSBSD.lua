--[[ Auto-Farm Hub v4 - Tabbed UI ]]
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local VIM = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Safe parent
local function getSafeParent()
    local ok, hui = pcall(function() return gethui() end)
    if ok and hui then return hui end
    local ok2, cg = pcall(function() return CoreGui end)
    if ok2 and cg then return cg end
    return player:WaitForChild("PlayerGui")
end

-- State
if _G.AutoFarmState == nil then
    _G.AutoFarmState = {
        running = false, lmbOn = false, keys = "E",
        interval = 0.1, hold = 0.05,
        attract = false, attractRange = 200,
        loopThread = nil, attractThread = nil,
        gui = nil, activeTab = "Farm",
    }
end
local S = _G.AutoFarmState

-- Enemies
local function getEnemies()
    local enemies = {}
    local folder = Workspace:FindFirstChild("Enemies")
    if not folder then return enemies end
    for _, obj in ipairs(folder:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then table.insert(enemies, obj) end
        end
    end
    return enemies
end

local function countEnemiesInRange()
    local myChar = player.Character
    if not myChar then return 0 end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return 0 end
    local enemies = getEnemies()
    local count = 0
    for _, e in ipairs(enemies) do
        local er = e:FindFirstChild("HumanoidRootPart")
        if er and (er.Position - myRoot.Position).Magnitude <= S.attractRange then
            count = count + 1
        end
    end
    return count
end

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
                    eRoot.CFrame = myRoot.CFrame * CFrame.new(math.random(-6,6), 0, math.random(-6,6))
                    eRoot.AssemblyLinearVelocity = Vector3.new(0,0,0)
                    eRoot.AssemblyAngularVelocity = Vector3.new(0,0,0)
                end)
                count = count + 1
            end
        end
    end
    return count
end

-- Actions
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
                    if not code then code = Enum.KeyCode[k:sub(1,1):upper()..k:sub(2):lower()] end
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
            pcall(attractEnemies)
            task.wait(0.15)
        end
    end)
end

-- ==== BUILD ====
local function buildGUI()
    if S.gui and S.gui.Parent then return S.gui end
    local parent = getSafeParent()
    local old = parent:FindFirstChild("AutoFarmGUI")
    if old then old:Destroy() end

    local C = {
        bg = Color3.fromRGB(18, 18, 22),
        sidebar = Color3.fromRGB(24, 24, 30),
        panel = Color3.fromRGB(28, 28, 34),
        item = Color3.fromRGB(34, 34, 42),
        itemHover = Color3.fromRGB(44, 44, 54),
        accent = Color3.fromRGB(88, 101, 242),
        green = Color3.fromRGB(60, 165, 90),
        red = Color3.fromRGB(200, 65, 65),
        text = Color3.fromRGB(240, 240, 245),
        textDim = Color3.fromRGB(150, 150, 160),
        border = Color3.fromRGB(50, 50, 60),
    }

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

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 640, 0, 420)
    main.Position = UDim2.new(0.5, -320, 0.5, -210)
    main.BackgroundColor3 = C.bg
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
    local ms = Instance.new("UIStroke", main) ms.Color = C.border ms.Thickness = 1

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 38)
    titleBar.BackgroundColor3 = C.sidebar
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)
    local tbMask = Instance.new("Frame")
    tbMask.Size = UDim2.new(1, 0, 0, 12)
    tbMask.Position = UDim2.new(0, 0, 1, -12)
    tbMask.BackgroundColor3 = C.sidebar
    tbMask.BorderSizePixel = 0
    tbMask.Parent = titleBar

    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(0, 24, 0, 24)
    logo.Position = UDim2.new(0, 12, 0.5, -12)
    logo.BackgroundTransparency = 1
    logo.Text = "⚡"
    logo.TextColor3 = C.accent
    logo.Font = Enum.Font.GothamBold
    logo.TextSize = 18
    logo.Parent = titleBar

    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -100, 1, 0)
    titleText.Position = UDim2.new(0, 42, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "Auto-Farm Hub"
    titleText.TextColor3 = C.text
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 15
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 26, 0, 26)
    closeBtn.Position = UDim2.new(1, -34, 0, 6)
    closeBtn.BackgroundColor3 = C.item
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = C.text
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.Parent = titleBar
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    closeBtn.MouseButton1Click:Connect(function() gui.Enabled = false end)

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 26, 0, 26)
    minBtn.Position = UDim2.new(1, -66, 0, 6)
    minBtn.BackgroundColor3 = C.item
    minBtn.Text = "—"
    minBtn.TextColor3 = C.text
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 14
    minBtn.Parent = titleBar
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)
    minBtn.MouseButton1Click:Connect(function() gui.Enabled = false end)

    -- Sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 150, 1, -38)
    sidebar.Position = UDim2.new(0, 0, 0, 38)
    sidebar.BackgroundColor3 = C.sidebar
    sidebar.BorderSizePixel = 0
    sidebar.Parent = main
    Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 10)

    -- Content
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -150, 1, -38)
    content.Position = UDim2.new(0, 150, 0, 38)
    content.BackgroundColor3 = C.panel
    content.BorderSizePixel = 0
    content.Parent = main
    Instance.new("UICorner", content).CornerRadius = UDim.new(0, 10)

    local pages = Instance.new("Folder", content)
    pages.Name = "Pages"

    -- Helper: Page
    local function makePage(name)
        local page = Instance.new("ScrollingFrame")
        page.Name = name
        page.Size = UDim2.new(1, -16, 1, -16)
        page.Position = UDim2.new(0, 8, 0, 8)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 4
        page.ScrollBarImageColor3 = C.accent
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Parent = pages
        local l = Instance.new("UIListLayout", page)
        l.Padding = UDim.new(0, 8) l.SortOrder = Enum.SortOrder.LayoutOrder
        local p = Instance.new("UIPadding", page)
        p.PaddingTop = UDim.new(0, 4) p.PaddingBottom = UDim.new(0, 8)
        return page
    end

    -- Helper: Section
    local function makeSection(parent, text)
        local sec = Instance.new("Frame")
        sec.Size = UDim2.new(1, 0, 0, 24)
        sec.BackgroundTransparency = 1
        sec.Parent = parent
        local lbl = Instance.new("TextLabel", sec)
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text:upper()
        lbl.TextColor3 = C.accent
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        return sec
    end

    -- Helper: Toggle
    local function makeToggle(parent, label, default, callback)
        local item = Instance.new("Frame")
        item.Size = UDim2.new(1, 0, 0, 38)
        item.BackgroundColor3 = C.item
        item.BorderSizePixel = 0
        item.Parent = parent
        Instance.new("UICorner", item).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel", item)
        lbl.Size = UDim2.new(1, -80, 1, 0)
        lbl.Position = UDim2.new(0, 14, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = C.text
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local track = Instance.new("Frame", item)
        track.Size = UDim2.new(0, 42, 0, 22)
        track.Position = UDim2.new(1, -54, 0.5, -11)
        track.BackgroundColor3 = default and C.green or Color3.fromRGB(60, 60, 70)
        track.BorderSizePixel = 0
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame", track)
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local btn = Instance.new("TextButton", item)
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""

        local state = default
        local function update()
            local target = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            TweenService:Create(knob, TweenInfo.new(0.15), {Position = target}):Play()
            track.BackgroundColor3 = state and C.green or Color3.fromRGB(60, 60, 70)
        end
        btn.MouseButton1Click:Connect(function()
            state = not state update()
            if callback then callback(state) end
        end)
        item.MouseEnter:Connect(function() item.BackgroundColor3 = C.itemHover end)
        item.MouseLeave:Connect(function() item.BackgroundColor3 = C.item end)
        return item
    end

    -- Helper: Input
    local function makeInput(parent, label, default, callback)
        local item = Instance.new("Frame")
        item.Size = UDim2.new(1, 0, 0, 38)
        item.BackgroundColor3 = C.item
        item.BorderSizePixel = 0
        item.Parent = parent
        Instance.new("UICorner", item).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel", item)
        lbl.Size = UDim2.new(0.5, -12, 1, 0)
        lbl.Position = UDim2.new(0, 14, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = C.text
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local box = Instance.new("TextBox", item)
        box.Size = UDim2.new(0.5, -26, 0, 26)
        box.Position = UDim2.new(0.5, 12, 0.5, -13)
        box.BackgroundColor3 = C.bg
        box.Text = default
        box.TextColor3 = C.text
        box.Font = Enum.Font.Gotham
        box.TextSize = 13
        box.ClearTextOnFocus = false
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

        box:GetPropertyChangedSignal("Text"):Connect(function()
            if callback then callback(box.Text) end
        end)
        item.MouseEnter:Connect(function() item.BackgroundColor3 = C.itemHover end)
        item.MouseLeave:Connect(function() item.BackgroundColor3 = C.item end)
        return item
    end

    -- Helper: Slider
    local function makeSlider(parent, label, min, max, default, callback)
        local item = Instance.new("Frame")
        item.Size = UDim2.new(1, 0, 0, 52)
        item.BackgroundColor3 = C.item
        item.BorderSizePixel = 0
        item.Parent = parent
        Instance.new("UICorner", item).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel", item)
        lbl.Size = UDim2.new(1, -24, 0, 20)
        lbl.Position = UDim2.new(0, 14, 0, 5)
        lbl.BackgroundTransparency = 1
        lbl.Text = label .. ":  " .. tostring(default)
        lbl.TextColor3 = C.text
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local barBg = Instance.new("Frame", item)
        barBg.Size = UDim2.new(1, -28, 0, 6)
        barBg.Position = UDim2.new(0, 14, 0, 34)
        barBg.BackgroundColor3 = C.bg
        barBg.BorderSizePixel = 0
        Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame", barBg)
        local initFrac = (default - min) / (max - min)
        fill.Size = UDim2.new(initFrac, 0, 1, 0)
        fill.BackgroundColor3 = C.accent
        fill.BorderSizePixel = 0
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local dragging = false
        local function update(x)
            local rel = math.clamp((x - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * rel)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            lbl.Text = label .. ":  " .. tostring(val)
            if callback then callback(val) end
        end

        local btn = Instance.new("TextButton", item)
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.Position = UDim2.new(0, 0, 0, 20)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.MouseButton1Down:Connect(function() dragging = true update(mouse.X) end)
        mouse.Move:Connect(function()
            if dragging then
                if not barBg.Parent then dragging = false return end
                update(mouse.X)
            end
        end)
        mouse.Button1Up:Connect(function() dragging = false end)
        item.MouseEnter:Connect(function() item.BackgroundColor3 = C.itemHover end)
        item.MouseLeave:Connect(function() item.BackgroundColor3 = C.item end)
        return item
    end

    -- Helper: Button
    local function makeButton(parent, label, color, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 38)
        btn.BackgroundColor3 = color or C.item
        btn.Text = label
        btn.TextColor3 = C.text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.Parent = parent
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.MouseButton1Click:Connect(callback)
        btn.MouseEnter:Connect(function() btn.BackgroundColor3 = (color or C.item):Lerp(Color3.new(1,1,1), 0.1) end)
        btn.MouseLeave:Connect(function() btn.BackgroundColor3 = color or C.item end)
        return btn
    end

    -- ==== PAGES ====
    local pageFarm = makePage("Farm")
    local pageCombat = makePage("Combat")
    local pageMisc = makePage("Misc")
    local pageSettings = makePage("Settings")

    -- FARM
    makeSection(pageFarm, "Auto Key Presser")
    makeToggle(pageFarm, "Enable Auto Presser", S.running, function(v)
        S.running = v
        if v then startLoop()
        else if S.loopThread then pcall(task.cancel, S.loopThread) S.loopThread = nil end end
    end)
    makeInput(pageFarm, "Keys (comma-separated)", S.keys, function(t) S.keys = t end)
    makeInput(pageFarm, "Interval (sec)", tostring(S.interval), function(t) S.interval = tonumber(t) or 0.1 end)
    makeInput(pageFarm, "Hold Duration (sec)", tostring(S.hold), function(t) S.hold = tonumber(t) or 0.05 end)
    makeToggle(pageFarm, "Auto Left Click", S.lmbOn, function(v) S.lmbOn = v end)

    makeSection(pageFarm, "Enemy Attraction")
    makeToggle(pageFarm, "Enable Attraction", S.attract, function(v)
        S.attract = v
        if v then startAttract()
        else if S.attractThread then pcall(task.cancel, S.attractThread) S.attractThread = nil end end
    end)
    makeSlider(pageFarm, "Attract Range", 50, 1000, S.attractRange, function(v) S.attractRange = v end)

    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(1, 0, 0, 28)
    statusLbl.BackgroundColor3 = C.item
    statusLbl.Text = "Enemies in range: 0"
    statusLbl.TextColor3 = C.textDim
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 12
    statusLbl.Parent = pageFarm
    Instance.new("UICorner", statusLbl).CornerRadius = UDim.new(0, 6)

    task.spawn(function()
        while true do
            task.wait(0.3)
            if S.gui and S.gui.Parent then
                local ok, n = pcall(countEnemiesInRange)
                if ok then statusLbl.Text = "Enemies in range: " .. tostring(n) end
            end
        end
    end)

    -- COMBAT (placeholder)
    makeSection(pageCombat, "Teleportation")
    makeButton(pageCombat, "📍 Teleport to Nearest Enemy", C.accent, function()
        local myChar = player.Character
        if not myChar then return end
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        local enemies = getEnemies()
        if #enemies == 0 then return end
        local closest, bestDist = nil, math.huge
        for _, e in ipairs(enemies) do
            local er = e:FindFirstChild("HumanoidRootPart")
            if er then
                local d = (er.Position - myRoot.Position).Magnitude
                if d < bestDist then bestDist = d closest = e end
            end
        end
        if closest and closest:FindFirstChild("HumanoidRootPart") then
            myRoot.CFrame = closest.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
        end
    end)

    makeSection(pageCombat, "Auto Abilities")
    local abilPlaceholder = Instance.new("TextLabel")
    abilPlaceholder.Size = UDim2.new(1, 0, 0, 50)
    abilPlaceholder.BackgroundColor3 = C.item
    abilPlaceholder.Text = "🚧 Coming soon — auto-cast abilities"
    abilPlaceholder.TextColor3 = C.textDim
    abilPlaceholder.Font = Enum.Font.Gotham
    abilPlaceholder.TextSize = 12
    abilPlaceholder.Parent = pageCombat
    Instance.new("UICorner", abilPlaceholder).CornerRadius = UDim.new(0, 6)

    -- MISC
    makeSection(pageMisc, "Information")
    local infoLbl = Instance.new("TextLabel")
    infoLbl.Size = UDim2.new(1, 0, 0, 80)
    infoLbl.BackgroundColor3 = C.item
    infoLbl.Text = "Auto-Farm Hub v4\nPress F4 to toggle interface\nEnemies are pulled from Workspace.Enemies"
    infoLbl.TextColor3 = C.textDim
    infoLbl.Font = Enum.Font.Gotham
    infoLbl.TextSize = 12
    infoLbl.TextWrapped = true
    infoLbl.TextYAlignment = Enum.TextYAlignment.Top
    infoLbl.Parent = pageMisc
    Instance.new("UICorner", infoLbl).CornerRadius = UDim.new(0, 6)

    -- SETTINGS
    makeSection(pageSettings, "Interface")
    makeButton(pageSettings, "↺ Reset Position", C.item, function()
        main.Position = UDim2.new(0.5, -320, 0.5, -210)
    end)
    makeButton(pageSettings, "⏻ Unload Script", C.red, function()
        S.running = false S.attract = false
        if S.loopThread then pcall(task.cancel, S.loopThread) end
        if S.attractThread then pcall(task.cancel, S.attractThread) end
        S.loopThread = nil S.attractThread = nil
        gui:Destroy() S.gui = nil
    end)

    -- SIDEBAR TABS
    local tabLayout = Instance.new("UIListLayout", sidebar)
    tabLayout.Padding = UDim.new(0, 4)
    local tabPad = Instance.new("UIPadding", sidebar)
    tabPad.PaddingTop = UDim.new(0, 10)
    tabPad.PaddingLeft = UDim.new(0, 8)
    tabPad.PaddingRight = UDim.new(0, 8)

    local pagesMap = {Farm = pageFarm, Combat = pageCombat, Misc = pageMisc, Settings = pageSettings}
    local tabButtons = {}
    local tabs = {
        {name = "Farm", icon = "🌾"},
        {name = "Combat", icon = "⚔️"},
        {name = "Misc", icon = "🎯"},
        {name = "Settings", icon = "⚙️"},
    }

    local function switchTab(name)
        for _, p in pairs(pagesMap) do p.Visible = false end
        if pagesMap[name] then pagesMap[name].Visible = true end
        for n, btn in pairs(tabButtons) do
            if n == name then
                btn.BackgroundColor3 = C.accent
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                btn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
                btn.TextColor3 = C.textDim
            end
        end
        S.activeTab = name
    end

    for _, tab in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 36)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        btn.Text = "  " .. tab.icon .. "   " .. tab.name
        btn.TextColor3 = C.textDim
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = sidebar
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.MouseButton1Click:Connect(function() switchTab(tab.name) end)
        btn.MouseEnter:Connect(function()
            if S.activeTab ~= tab.name then btn.BackgroundColor3 = C.itemHover end
        end)
        btn.MouseLeave:Connect(function()
            if S.activeTab ~= tab.name then btn.BackgroundColor3 = Color3.fromRGB(30, 30, 38) end
        end)
        tabButtons[tab.name] = btn
    end

    switchTab(S.activeTab or "Farm")
    S.gui = gui

    if S.running then startLoop() end
    if S.attract then startAttract() end

    return gui
end

buildGUI()

-- Auto-restore
task.spawn(function()
    while true do
        task.wait(2)
        local parent = getSafeParent()
        local existing = parent:FindFirstChild("AutoFarmGUI")
        if not existing or not S.gui or not S.gui.Parent then buildGUI() end
    end
end)

player.CharacterAdded:Connect(function()
    task.wait(1)
    if not S.gui or not S.gui.Parent then buildGUI() end
end)

-- F4 toggle
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F4 then
        if S.gui then S.gui.Enabled = not S.gui.Enabled
        else buildGUI() end
    end
end)

print("✅ Auto-Farm Hub v4 loaded — press F4 to toggle")

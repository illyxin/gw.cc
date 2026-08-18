--[[
    gw.cc | UI Shell v2.0
    Written by ENI for LO
    Cross-platform. Pure UI. No game logic.
--]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- COLORS
local C = {
    Panel   = Color3.fromRGB(13, 13, 18),
    PanelLt = Color3.fromRGB(17, 17, 24),
    HdrTop  = Color3.fromRGB(19, 19, 26),
    NavCol  = Color3.fromRGB(15, 15, 20),
    NavAct  = Color3.fromRGB(26, 26, 36),
    NavIna  = Color3.fromRGB(20, 20, 26),
    NavHov  = Color3.fromRGB(22, 22, 30),
    TxtPri  = Color3.fromRGB(228, 228, 232),
    TxtMut  = Color3.fromRGB(106, 106, 120),
    TxtBrt  = Color3.fromRGB(145, 145, 160),
    TxtHint = Color3.fromRGB(74, 74, 85),
    Accent  = Color3.fromRGB(90, 90, 122),
    BarBg   = Color3.fromRGB(24, 24, 32),
    BarA    = Color3.fromRGB(74, 74, 106),
    BarB    = Color3.fromRGB(106, 106, 138),
    ScrClr  = Color3.fromRGB(42, 42, 53),
    MinA    = Color3.fromRGB(26, 26, 36),
    MinB    = Color3.fromRGB(20, 20, 26),
    MinP    = Color3.fromRGB(30, 30, 40),
    StrkClr = Color3.fromRGB(26, 26, 34),
    HLne    = Color3.fromRGB(23, 23, 31),
    MinStrk = Color3.fromRGB(34, 34, 44),
}

-- HELPERS
local function new(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

local function corner(parent, r)
    new("UICorner", { CornerRadius = UDim.new(0, r) }, parent)
end

local function dropShadow(parent, spread, alpha)
    new("ImageLabel", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = alpha or 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, spread or 60, 1, spread or 60),
        ZIndex = 0,
    }, parent)
end

local function borderStroke(parent, color, thick, transp)
    new("UIStroke", {
        Color = color or C.StrkClr,
        Thickness = thick or 1,
        Transparency = transp or 0.3,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

-- SIZING
local cam = workspace.CurrentCamera
local viewport = cam and cam.ViewportSize or Vector2.new(1280, 720)
local screenW, screenH = viewport.X, viewport.Y
local small = screenW < 500

local PW   = small and math.clamp(math.floor(screenW * 0.80), 260, 420) or 460
local PH   = small and math.clamp(math.floor(screenH * 0.55), 260, 380) or 400
local NW   = small and 48 or 50
local NB   = small and 48 or 50
local HH   = small and 42 or 42
local NF   = small and 17 or 16
local WW   = small and math.clamp(math.floor(screenW * 0.82), 260, 340) or 340

-- ROOT
local gui = new("ScreenGui", {
    Name = "gwcc_UI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 9999,
}, PlayerGui)

--============================================================
-- WELCOME WINDOW (small, centered, NOT full screen)
--============================================================
local welcome = new("Frame", {
    Name = "Welcome",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(WW, 170),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
    ZIndex = 50,
}, gui)
corner(welcome, 10)
dropShadow(welcome, 50, 0.5)
borderStroke(welcome, C.StrkClr, 1, 0.3)

local wTitle = new("TextLabel", {
    Name = "Title",
    BackgroundTransparency = 1,
    Text = "Welcome to gw.cc",
    TextColor3 = C.TxtPri,
    TextTransparency = 0,
    TextXAlignment = Enum.TextXAlignment.Center,
    Font = Enum.Font.Code,
    TextSize = 18,
    Size = UDim2.new(1, 0, 0, 24),
    Position = UDim2.new(0, 0, 0, 24),
    ZIndex = 51,
}, welcome)

local wCredit = new("TextLabel", {
    Name = "Credit",
    BackgroundTransparency = 1,
    Text = "by illyxin",
    TextColor3 = C.TxtMut,
    TextTransparency = 0,
    TextXAlignment = Enum.TextXAlignment.Center,
    Font = Enum.Font.Code,
    TextSize = 12,
    Size = UDim2.new(1, 0, 0, 16),
    Position = UDim2.new(0, 0, 0, 52),
    ZIndex = 51,
}, welcome)

local barBack = new("Frame", {
    Name = "BarBack",
    BackgroundColor3 = C.BarBg,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 84),
    Size = UDim2.new(0, WW - 60, 0, 6),
    ClipsDescendants = true,
    ZIndex = 51,
}, welcome)
corner(barBack, 3)

local barFill = new("Frame", {
    Name = "BarFill",
    BackgroundColor3 = C.BarA,
    BorderSizePixel = 0,
    Size = UDim2.new(0, 0, 1, 0),
    ZIndex = 52,
}, barBack)
corner(barFill, 3)
new("UIGradient", {
    Color = ColorSequence.new(C.BarA, C.BarB),
    Rotation = 0,
}, barFill)

local wPct = new("TextLabel", {
    Name = "Percent",
    BackgroundTransparency = 1,
    Text = "Loading... 0%",
    TextColor3 = C.TxtBrt,
    TextTransparency = 0,
    TextXAlignment = Enum.TextXAlignment.Center,
    Font = Enum.Font.Code,
    TextSize = 11,
    Size = UDim2.new(1, 0, 0, 14),
    Position = UDim2.new(0, 0, 0, 100),
    ZIndex = 51,
}, welcome)

--============================================================
-- MAIN MENU PANEL (CENTERED)
--============================================================
local panel = new("Frame", {
    Name = "MainMenu",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(PW, PH),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 10,
}, gui)
corner(panel, 10)
dropShadow(panel, 70, 0.5)
borderStroke(panel, C.StrkClr, 1, 0.3)

-- HEADER
local header = new("Frame", {
    Name = "Header",
    BackgroundColor3 = C.PanelLt,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, HH),
    ZIndex = 3,
}, panel)
corner(header, 10)
new("UIGradient", {
    Color = ColorSequence.new(C.HdrTop, C.Panel),
    Rotation = 90,
}, header)

new("Frame", {
    Name = "HFoot",
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 0, 1, 0),
    Size = UDim2.new(1, 0, 0, 8),
    ZIndex = 2,
}, header)

new("Frame", {
    Name = "HLine",
    BackgroundColor3 = C.HLne,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 0, 1, 0),
    Size = UDim2.new(1, 0, 0, 1),
    ZIndex = 4,
}, header)

new("TextLabel", {
    Name = "Brand",
    BackgroundTransparency = 1,
    Text = "gw.cc",
    TextColor3 = C.TxtPri,
    TextTransparency = 0,
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.Code,
    TextSize = 15,
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 14, 0.5, 0),
    Size = UDim2.new(0, 100, 1, 0),
    ZIndex = 5,
}, header)

new("TextLabel", {
    Name = "Hint",
    BackgroundTransparency = 1,
    Text = "RightShift to toggle",
    TextColor3 = C.TxtHint,
    TextTransparency = 0,
    TextXAlignment = Enum.TextXAlignment.Right,
    Font = Enum.Font.Code,
    TextSize = 10,
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -14, 0.5, 0),
    Size = UDim2.new(0, 160, 1, 0),
    ZIndex = 5,
}, header)

-- BODY
local body = new("Frame", {
    Name = "Body",
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, HH),
    Size = UDim2.new(1, 0, 1, -HH),
    ZIndex = 3,
}, panel)

-- NAV COLUMN
local nav = new("Frame", {
    Name = "Nav",
    BackgroundColor3 = C.NavCol,
    BorderSizePixel = 0,
    Size = UDim2.new(0, NW, 1, 0),
    ZIndex = 4,
}, body)
corner(nav, 10)

new("Frame", {
    Name = "NavTopFill",
    BackgroundColor3 = C.NavCol,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 8),
    ZIndex = 4,
}, nav)

local TABS = { "M", "V", "C" }
local TAB_NAMES = { M = "Main", V = "Visual", C = "Config/Settings" }
local navBtns = {}
local navAccs = {}

for i, id in ipairs(TABS) do
    local btn = new("TextButton", {
        Name = "Nav_" .. id,
        AutoButtonColor = false,
        BackgroundColor3 = C.NavIna,
        BorderSizePixel = 0,
        Text = id,
        TextColor3 = C.TxtMut,
        TextTransparency = 0,
        Font = Enum.Font.Code,
        TextSize = NF,
        Position = UDim2.new(0, 0, 0, 8 + (i - 1) * NB),
        Size = UDim2.new(1, 0, 0, NB),
        ZIndex = 5,
    }, nav)
    corner(btn, 6)

    local acc = new("Frame", {
        Name = "Accent",
        BackgroundColor3 = C.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, -16),
        Position = UDim2.new(0, 0, 0, 8),
        ZIndex = 6,
    }, btn)
    corner(acc, 2)

    navBtns[id] = btn
    navAccs[id] = acc
end

-- Nav separator line (between nav and content)
new("Frame", {
    Name = "NavSep",
    BackgroundColor3 = C.HLne,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    Size = UDim2.new(0, 1, 1, 0),
    ZIndex = 5,
}, nav)

local function styleNav(id, active)
    local btn = navBtns[id]
    local acc = navAccs[id]
    if not btn then return end
    local info = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    TweenService:Create(btn, info, {
        BackgroundColor3 = active and C.NavAct or C.NavIna,
        TextColor3 = active and C.TxtPri or C.TxtMut,
    }):Play()
    TweenService:Create(acc, info, { BackgroundTransparency = active and 0 or 1 }):Play()
end

-- CONTENT AREA
local content = new("ScrollingFrame", {
    Name = "Content",
    BackgroundColor3 = C.Panel,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    Position = UDim2.new(0, NW, 0, 0),
    Size = UDim2.new(1, -NW, 1, 0),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.ScrClr,
    ScrollBarImageTransparency = 0.15,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    ClipsDescendants = true,
    ZIndex = 4,
}, body)
corner(content, 10)

-- PAGES
local pages = {}

local function makePage(name, text)
    local page = new("Frame", {
        Name = "Page_" .. name,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        ZIndex = 5,
    }, content)

    local label = new("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.TxtPri,
        TextTransparency = 0,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Font = Enum.Font.Code,
        TextSize = 15,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -20, 0, 24),
        ZIndex = 6,
    }, page)

    pages[name] = { frame = page, label = label }
    return pages[name]
end

local rawName = LocalPlayer.DisplayName
if not rawName or rawName == "" then rawName = LocalPlayer.Name end
rawName = tostring(rawName):gsub("[^%w%s_%.%-]", "")
local typedText = "Welcome, " .. rawName .. "!"

local intro = makePage("Intro", "")
makePage("M", TAB_NAMES.M)
makePage("V", TAB_NAMES.V)
makePage("C", TAB_NAMES.C)

local currentPage = intro
local activeTab = "M"
local firstLoad = true

local function showPage(target)
    if currentPage == target then return end
    currentPage.frame.Visible = false
    currentPage = target
    currentPage.frame.Visible = true
end

-- NAV EVENTS
for _, id in ipairs(TABS) do
    local btn = navBtns[id]

    btn.MouseEnter:Connect(function()
        if activeTab ~= id then
            TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = C.NavHov }):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if activeTab ~= id then
            TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = C.NavIna }):Play()
        end
    end)

    btn.Activated:Connect(function()
        if activeTab == id and not firstLoad then return end
        local prev = activeTab
        activeTab = id
        firstLoad = false
        if prev ~= id then styleNav(prev, false) end
        styleNav(id, true)
        showPage(pages[id])
    end)
end

styleNav("M", true)

--============================================================
-- MINIMIZE BUTTON (floating, LEFT-CENTER, DRAGGABLE)
--============================================================
local minBtn = new("ImageButton", {
    Name = "Minimize",
    AutoButtonColor = false,
    BackgroundColor3 = C.MinA,
    BorderSizePixel = 0,
    Image = "",
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 20, 0.5, 0),
    Size = UDim2.fromOffset(44, 44),
    ZIndex = 30,
}, gui)
corner(minBtn, 12)
dropShadow(minBtn, 34, 0.6)
new("UIGradient", {
    Color = ColorSequence.new(C.MinA, C.MinB),
    Rotation = 90,
}, minBtn)
borderStroke(minBtn, C.MinStrk, 1, 0.4)

local icon1 = new("Frame", {
    Name = "Icon1",
    BackgroundColor3 = C.TxtMut,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, -4),
    Size = UDim2.fromOffset(18, 2),
    ZIndex = 31,
}, minBtn)
corner(icon1, 1)

local icon2 = new("Frame", {
    Name = "Icon2",
    BackgroundColor3 = C.TxtMut,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 4),
    Size = UDim2.fromOffset(12, 2),
    ZIndex = 31,
}, minBtn)
corner(icon2, 1)

--============================================================
-- MENU VISIBILITY
--============================================================
local menuVisible = false

local function toggleMenu()
    menuVisible = not menuVisible
    panel.Visible = menuVisible
end

--============================================================
-- DRAGGING SYSTEM (panel + minimize button)
--============================================================
local dragging = false
local dragStart = nil
local startPos = nil

local minDragging = false
local minDragStart = nil
local minStartPos = nil
local minDragMoved = false

-- Panel drag — from ANY non-button part
local function startDrag(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
    end
end

panel.InputBegan:Connect(startDrag)
header.InputBegan:Connect(startDrag)
body.InputBegan:Connect(startDrag)
nav.InputBegan:Connect(startDrag)
content.InputBegan:Connect(startDrag)

-- Minimize button drag + tap detection
minBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        minDragging = true
        minDragMoved = false
        minDragStart = input.Position
        minStartPos = minBtn.Position
        TweenService:Create(minBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = C.MinP }):Play()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then return end

    -- Panel drag end
    dragging = false

    -- Minimize button release
    if minDragging then
        TweenService:Create(minBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = C.MinA }):Play()
        if not minDragMoved then
            toggleMenu()
        end
        minDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
    and input.UserInputType ~= Enum.UserInputType.Touch then return end

    -- Panel drag
    if dragging then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end

    -- Minimize button drag
    if minDragging then
        local delta = input.Position - minDragStart
        if delta.Magnitude > 5 then
            minDragMoved = true
        end
        minBtn.Position = UDim2.new(
            minStartPos.X.Scale, minStartPos.X.Offset + delta.X,
            minStartPos.Y.Scale, minStartPos.Y.Offset + delta.Y
        )
    end
end)

-- RightShift keybind
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        toggleMenu()
    end
end)

--============================================================
-- FADE OUT HELPER
--============================================================
local function fadeOut(root, duration)
    local info = TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    local all = root:GetDescendants()
    table.insert(all, 1, root)
    for _, obj in ipairs(all) do
        if obj:IsA("Frame") then
            TweenService:Create(obj, info, { BackgroundTransparency = 1 }):Play()
        elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
            TweenService:Create(obj, info, { TextTransparency = 1 }):Play()
        elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
            TweenService:Create(obj, info, { ImageTransparency = 1 }):Play()
        elseif obj:IsA("UIStroke") then
            TweenService:Create(obj, info, { Transparency = 1 }):Play()
        end
    end
end

--============================================================
-- TYPING ANIMATION
--============================================================
local function typeIntro()
    intro.frame.Visible = true
    intro.label.Text = ""
    intro.label.TextTransparency = 0
    local built = ""
    for i = 1, #typedText do
        built = built .. typedText:sub(i, i)
        intro.label.Text = built
        task.wait(0.06)
    end
    intro.label.Text = typedText
end

--============================================================
-- BOOT SEQUENCE (stepped loading with pauses)
--============================================================
local function tweenBar(target, dur)
    TweenService:Create(barFill, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(target, 0, 1, 0) }):Play()
    task.wait(dur)
end

task.spawn(function()
    local conn

    local ok, err = pcall(function()
        -- Heartbeat updates percentage from bar fill size
        conn = RunService.Heartbeat:Connect(function()
            local pct = barFill.Size.X.Scale
            wPct.Text = string.format("Loading... %d%%", math.floor(pct * 100 + 0.5))
            if pct >= 1 then
                conn:Disconnect()
                conn = nil
            end
        end)

        -- Stepped loading with pauses (~7 seconds total)
        tweenBar(0.15, 0.8)
        task.wait(0.4)

        tweenBar(0.35, 0.7)
        task.wait(0.5)

        tweenBar(0.55, 0.8)
        task.wait(0.4)

        tweenBar(0.75, 0.6)
        task.wait(0.5)

        tweenBar(0.90, 0.5)
        task.wait(0.4)

        tweenBar(1.00, 0.4)
        task.wait(0.3)

        if conn then conn:Disconnect() conn = nil end

        -- Prepare panel content BEFORE showing
        intro.frame.Visible = true
        intro.label.Text = ""
        intro.label.TextTransparency = 0

        -- Show panel (centered)
        panel.Visible = true
        menuVisible = true

        -- Fade out welcome window
        fadeOut(welcome, 0.4)

        -- Destroy welcome after fade
        task.delay(0.5, function()
            welcome:Destroy()
        end)

        -- Start typing animation
        typeIntro()
    end)

    if not ok then
        if conn then conn:Disconnect() end
        warn("[gw.cc] Boot error: " .. tostring(err))
    end
end)

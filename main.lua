--[[
    gw.cc  |  UI SHELL v1.0
    Pure interface framework. No game logic, no functional features.
--]]

--// SERVICES
local Players               = game:GetService("Players")
local TweenService          = game:GetService("TweenService")
local UserInputService      = game:GetService("UserInputService")
local ContextActionService  = game:GetService("ContextActionService")
local RunService            = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

--// THEME
local T = {
    Panel        = Color3.fromHex("0D0D12"),
    Header       = Color3.fromHex("111118"),
    HeaderTop    = Color3.fromHex("13131A"),
    NavColumn    = Color3.fromHex("0F0F14"),
    NavActive    = Color3.fromHex("1A1A24"),
    NavInactive  = Color3.fromHex("14141A"),
    NavHover     = Color3.fromHex("16161E"),
    TextPrimary  = Color3.fromHex("E4E4E8"),
    TextMuted    = Color3.fromHex("6A6A78"),
    TextHint     = Color3.fromHex("4A4A55"),
    Accent       = Color3.fromHex("5A5A7A"),
    BarBack      = Color3.fromHex("181820"),
    BarFillA     = Color3.fromHex("4A4A6A"),
    BarFillB     = Color3.fromHex("6A6A8A"),
    ScrollBar    = Color3.fromHex("2A2A35"),
    MinA         = Color3.fromHex("1A1A24"),
    MinB         = Color3.fromHex("14141A"),
    MinPressed   = Color3.fromHex("1E1E28"),
}

--// PLATFORM
local IS_TOUCH  = UserInputService.TouchEnabled
local IS_MOUSE  = UserInputService.MouseEnabled
local IS_MOBILE = IS_TOUCH and not IS_MOUSE
local IS_PC     = IS_MOUSE

--// EASING
local function TI(t, style, dir)
    return TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
end
local EASE_IN  = Enum.EasingDirection.In
local QUINT    = Enum.EasingStyle.Quint
local QUAD     = Enum.EasingStyle.Quad
local LINEAR   = Enum.EasingStyle.Linear

--// HELPERS
local function new(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    if parent then inst.Parent = parent end
    return inst
end

local function font(label, size, weight)
    label.TextSize = size
    local ok = pcall(function()
        label.FontFace = Font.new("rbxasset://fonts/families/JetBrainsMono.json", weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    end)
    if not ok then
        label.Font = Enum.Font.Code
    end
    return label
end

local function corner(parent, r)
    return new("UICorner", { CornerRadius = UDim.new(0, r or 6) }, parent)
end

local function shadow(parent, spread, alpha)
    return new("ImageLabel", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = alpha or 0.55,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, spread or 60, 1, spread or 60),
        ZIndex = 0,
    }, parent)
end

-- transparency snapshot / fade system
local function snapshot(root)
    local snap = {}
    local list = root:GetDescendants()
    table.insert(list, 1, root)
    for _, o in ipairs(list) do
        if o:IsA("GuiObject") then
            table.insert(snap, { o, "BackgroundTransparency", o.BackgroundTransparency })
        end
        if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
            table.insert(snap, { o, "TextTransparency", o.TextTransparency })
        end
        if o:IsA("ImageLabel") or o:IsA("ImageButton") then
            table.insert(snap, { o, "ImageTransparency", o.ImageTransparency })
        end
        if o:IsA("UIStroke") then
            table.insert(snap, { o, "Transparency", o.Transparency })
        end
    end
    return snap
end

local function applySnap(snap, value)
    for _, e in ipairs(snap) do
        e[1][e[2]] = value or e[3]
    end
end

local function tweenSnap(snap, info, toHidden)
    for _, e in ipairs(snap) do
        TweenService:Create(e[1], info, { [e[2]] = toHidden and 1 or e[3] }):Play()
    end
end

--// SIZING
local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
local PANEL_W, PANEL_H, NAV_W, HEADER_H

if IS_MOBILE then
    PANEL_W  = math.clamp(math.floor(viewport.X * 0.86), 300, 460)
    PANEL_H  = math.clamp(math.floor(viewport.Y * 0.60), 280, 400)
    NAV_W    = 50
    HEADER_H = 44
else
    PANEL_W, PANEL_H, NAV_W, HEADER_H = 460, 400, 46, 42
end

--// ROOT SCREENGUI
local gui = new("ScreenGui", {
    Name = "gwcc_UI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 9999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)

--============================================================
-- COMPONENT 1: WELCOME / LOADING SCREEN
--============================================================
local welcome = new("Frame", {
    Name = "Welcome",
    BackgroundColor3 = T.Panel,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    Size = UDim2.fromScale(1, 1),
    ZIndex = 50,
}, gui)

local wCenter = new("Frame", {
    Name = "Center",
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(0, 360, 0, 130),
}, welcome)

local wTitle = font(new("TextLabel", {
    Name = "Title",
    BackgroundTransparency = 1,
    Text = "Welcome to gw.cc",
    TextColor3 = T.TextPrimary,
    TextXAlignment = Enum.TextXAlignment.Center,
    Size = UDim2.new(1, 0, 0, 26),
    Position = UDim2.new(0, 0, 0, 0),
}, wCenter), 20, Enum.FontWeight.Medium)

local wCredit = font(new("TextLabel", {
    Name = "Credit",
    BackgroundTransparency = 1,
    Text = "by illyxin",
    TextColor3 = T.TextMuted,
    TextXAlignment = Enum.TextXAlignment.Center,
    Size = UDim2.new(1, 0, 0, 16),
    Position = UDim2.new(0, 0, 0, 34),
}, wCenter), 13)

local barBack = new("Frame", {
    Name = "BarBack",
    BackgroundColor3 = T.BarBack,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 74),
    Size = UDim2.new(0, 320, 0, 7),
    ClipsDescendants = true,
}, wCenter)
corner(barBack, 4)

local barFill = new("Frame", {
    Name = "BarFill",
    BackgroundColor3 = T.BarFillA,
    BorderSizePixel = 0,
    Size = UDim2.new(0, 0, 1, 0),
}, barBack)
corner(barFill, 4)
new("UIGradient", {
    Color = ColorSequence.new(T.BarFillA, T.BarFillB),
    Rotation = 0,
}, barFill)

local wPercent = font(new("TextLabel", {
    Name = "Percent",
    BackgroundTransparency = 1,
    Text = "Loading... 0%",
    TextColor3 = T.TextMuted,
    TextXAlignment = Enum.TextXAlignment.Center,
    Size = UDim2.new(1, 0, 0, 14),
    Position = UDim2.new(0, 0, 0, 90),
}, wCenter), 11)

--============================================================
-- COMPONENT 2: MAIN MENU
--============================================================
local panel = new("Frame", {
    Name = "MainMenu",
    BackgroundColor3 = T.Panel,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.70, 0, 0.5, 0),
    Size = UDim2.fromOffset(PANEL_W, PANEL_H),
    ClipsDescendants = false,
    Visible = false,
    ZIndex = 10,
}, gui)
corner(panel, 6)
shadow(panel, 70, 0.5)
new("UIStroke", {
    Color = Color3.fromHex("1A1A22"),
    Thickness = 1,
    Transparency = 0.35,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, panel)

--// A) HEADER (drag handle)
local header = new("Frame", {
    Name = "Header",
    BackgroundColor3 = T.Header,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, HEADER_H),
    ZIndex = 3,
}, panel)
corner(header, 6)
new("UIGradient", {
    Color = ColorSequence.new(T.HeaderTop, T.Panel),
    Rotation = 90,
}, header)
new("Frame", {
    Name = "HeaderFoot",
    BackgroundColor3 = T.Panel,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 0, 1, 0),
    Size = UDim2.new(1, 0, 0, 6),
    ZIndex = 2,
}, header)
new("Frame", {
    Name = "HeaderLine",
    BackgroundColor3 = Color3.fromHex("17171F"),
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 0, 1, 0),
    Size = UDim2.new(1, 0, 0, 1),
    ZIndex = 4,
}, header)

local brand = font(new("TextLabel", {
    Name = "Brand",
    BackgroundTransparency = 1,
    Text = "gw.cc",
    TextColor3 = T.TextPrimary,
    TextXAlignment = Enum.TextXAlignment.Left,
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 12, 0.5, 0),
    Size = UDim2.new(0, 120, 1, 0),
    ZIndex = 5,
}, header), 18, Enum.FontWeight.Medium)

local hint = font(new("TextLabel", {
    Name = "Hint",
    BackgroundTransparency = 1,
    Text = "RightShift to toggle",
    TextColor3 = T.TextHint,
    TextXAlignment = Enum.TextXAlignment.Right,
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -12, 0.5, 0),
    Size = UDim2.new(0, 180, 1, 0),
    ZIndex = 5,
    Visible = IS_PC,
}, header), 11)

--// B) BODY
local body = new("Frame", {
    Name = "Body",
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, HEADER_H),
    Size = UDim2.new(1, 0, 1, -HEADER_H),
}, panel)

--// LEFT COLUMN: SIDE NAV
local navColumn = new("Frame", {
    Name = "Nav",
    BackgroundColor3 = T.NavColumn,
    BorderSizePixel = 0,
    Size = UDim2.new(0, NAV_W, 1, 0),
}, body)
corner(navColumn, 6)
new("Frame", {
    Name = "NavTopFill",
    BackgroundColor3 = T.NavColumn,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 8),
}, navColumn)

local NAV_BTN = math.max(44, NAV_W)
local tabs = { "M", "V", "C" }
local tabTitles = { M = "Main", V = "Visual", C = "Config/Settings" }
local navButtons, navAccents = {}, {}
local activeTab = "M"
local firstLoad = true

for i, id in ipairs(tabs) do
    local btn = font(new("TextButton", {
        Name = "Nav_" .. id,
        AutoButtonColor = false,
        BackgroundColor3 = T.NavInactive,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Text = id,
        TextColor3 = T.TextMuted,
        Position = UDim2.new(0, 0, 0, (i - 1) * NAV_BTN),
        Size = UDim2.new(1, 0, 0, NAV_BTN),
    }, navColumn), IS_MOBILE and 18 or 16, Enum.FontWeight.Medium)
    corner(btn, 4)

    local accent = new("Frame", {
        Name = "Accent",
        BackgroundColor3 = T.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, -10),
        Position = UDim2.new(0, 0, 0, 5),
        ZIndex = 2,
    }, btn)
    corner(accent, 2)

    navButtons[id] = btn
    navAccents[id] = accent
end

local function styleNav(id, active)
    local btn, accent = navButtons[id], navAccents[id]
    local info = TI(0.25, QUINT, Enum.EasingDirection.Out)
    TweenService:Create(btn, info, {
        BackgroundColor3 = active and T.NavActive or T.NavInactive,
        TextColor3 = active and T.TextPrimary or T.TextMuted,
    }):Play()
    TweenService:Create(accent, info, { BackgroundTransparency = active and 0 or 1 }):Play()
end

--// RIGHT COLUMN: CONTENT
local content = new("ScrollingFrame", {
    Name = "Content",
    BackgroundColor3 = T.Panel,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    Position = UDim2.new(0, NAV_W, 0, 0),
    Size = UDim2.new(1, -NAV_W, 1, 0),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = T.ScrollBar,
    ScrollBarImageTransparency = 0.15,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
    ClipsDescendants = true,
}, body)
corner(content, 6)
new("Frame", {
    Name = "EdgeFill",
    BackgroundColor3 = T.Panel,
    BorderSizePixel = 0,
    Size = UDim2.new(0, 8, 1, 0),
    ZIndex = 0,
}, content)

local pages = {}
local function makePage(name, text)
    local page = new("Frame", {
        Name = "Page_" .. name,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
    }, content)

    local label = font(new("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = T.TextPrimary,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -20, 0, 24),
    }, page), 15)

    pages[name] = { frame = page, label = label }
    return pages[name]
end

local rawName = LocalPlayer.DisplayName
if rawName == nil or rawName == "" then rawName = LocalPlayer.Name end
rawName = tostring(rawName):gsub("[^%w%s_%.%-]", "")
local typedText = "Welcome, " .. rawName .. "!"

local intro = makePage("Intro", "")
makePage("M", tabTitles.M)
makePage("V", tabTitles.V)
makePage("C", tabTitles.C)

local currentPage = intro
local FADE_OUT = TI(0.2, QUINT, EASE_IN)
local FADE_IN  = TI(0.2, QUINT, Enum.EasingDirection.Out)

local function showPage(target)
    if currentPage == target then return end
    local old = currentPage
    currentPage = target

    TweenService:Create(old.label, FADE_OUT, { TextTransparency = 1 }):Play()
    task.delay(0.2, function()
        if currentPage ~= target then return end
        old.frame.Visible = false
    end)

    target.label.TextTransparency = 1
    target.frame.Visible = true
    TweenService:Create(target.label, FADE_IN, { TextTransparency = 0 }):Play()
end

--// NAV INTERACTION
for _, id in ipairs(tabs) do
    local btn = navButtons[id]

    if IS_PC then
        btn.MouseEnter:Connect(function()
            if activeTab ~= id then
                TweenService:Create(btn, TI(0.2, QUAD, Enum.EasingDirection.Out), { BackgroundColor3 = T.NavHover }):Play()
            end
        end)
        btn.MouseLeave:Connect(function()
            if activeTab ~= id then
                TweenService:Create(btn, TI(0.2, QUAD, Enum.EasingDirection.Out), { BackgroundColor3 = T.NavInactive }):Play()
            end
        end)
    end

    btn.Activated:Connect(function()
        if activeTab == id and not firstLoad then return end
        local previous = activeTab
        activeTab = id
        firstLoad = false
        if previous ~= id then styleNav(previous, false) end
        styleNav(id, true)
        showPage(pages[id])
    end)
end

styleNav("M", true)

--============================================================
-- DRAGGING
--============================================================
local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
local panelBasePos = panel.Position

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragInput = input
        dragStart = input.Position
        startPos = panel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                panelBasePos = panel.Position
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging or not dragInput then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local delta = input.Position - dragStart
    panel.Position = UDim2.new(
        startPos.X.Scale, startPos.X.Offset + delta.X,
        startPos.Y.Scale, startPos.Y.Offset + delta.Y
    )
    panelBasePos = panel.Position
end)

--============================================================
-- SHOW / HIDE
--============================================================
local panelSnap = snapshot(panel)
applySnap(panelSnap, 1)

local menuVisible = false
local animating = false
local minimizeBtn

local function setMinimizeIconState(open)
    if not minimizeBtn then return end
    local icon = minimizeBtn:FindFirstChild("Icon")
    if not icon then return end
    TweenService:Create(icon, TI(0.2, QUAD, Enum.EasingDirection.Out), {
        BackgroundTransparency = open and 0.35 or 0,
    }):Play()
end

local function showMenu(duration)
    if menuVisible or animating then return end
    animating = true
    menuVisible = true
    panel.Visible = true
    applySnap(panelSnap, 1)
    panel.Position = panelBasePos + UDim2.fromOffset(0, 24)
    local info = TI(duration or 0.3, QUINT, Enum.EasingDirection.Out)
    tweenSnap(panelSnap, info, false)
    TweenService:Create(panel, info, { Position = panelBasePos }):Play()
    setMinimizeIconState(true)
    task.delay(duration or 0.3, function() animating = false end)
end

local function hideMenu(duration)
    if not menuVisible or animating then return end
    animating = true
    menuVisible = false
    panelSnap = snapshot(panel)
    local info = TI(duration or 0.3, QUINT, EASE_IN)
    tweenSnap(panelSnap, info, true)
    TweenService:Create(panel, info, { Position = panelBasePos + UDim2.fromOffset(0, 24) }):Play()
    setMinimizeIconState(false)
    task.delay(duration or 0.3, function()
        panel.Visible = false
        panel.Position = panelBasePos
        animating = false
    end)
end

local function toggleMenu()
    if menuVisible then hideMenu() else showMenu() end
end

--// PC KEYBIND
if IS_PC then
    ContextActionService:BindAction("gwcc_toggle", function(_, state)
        if state == Enum.UserInputState.Begin then
            toggleMenu()
        end
        return Enum.ContextActionResult.Sink
    end, false, Enum.KeyCode.RightShift)
end

--============================================================
-- COMPONENT 3: MOBILE FLOATING TOGGLE
--============================================================
if IS_MOBILE then
    minimizeBtn = new("ImageButton", {
        Name = "Minimize",
        AutoButtonColor = false,
        BackgroundColor3 = T.MinA,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Image = "",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -20, 1, -20),
        Size = UDim2.fromOffset(44, 44),
        ZIndex = 30,
    }, gui)
    corner(minimizeBtn, 10)
    shadow(minimizeBtn, 34, 0.6)
    new("UIGradient", {
        Color = ColorSequence.new(T.MinA, T.MinB),
        Rotation = 90,
    }, minimizeBtn)
    new("UIStroke", {
        Color = Color3.fromHex("22222C"),
        Thickness = 1,
        Transparency = 0.4,
    }, minimizeBtn)
    local scale = new("UIScale", { Scale = 1 }, minimizeBtn)

    local icon = new("Frame", {
        Name = "Icon",
        BackgroundColor3 = T.TextMuted,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, -4),
        Size = UDim2.fromOffset(18, 2),
    }, minimizeBtn)
    corner(icon, 1)
    local icon2 = new("Frame", {
        Name = "Icon2",
        BackgroundColor3 = T.TextMuted,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 4),
        Size = UDim2.fromOffset(12, 2),
    }, minimizeBtn)
    corner(icon2, 1)

    local qOut = TI(0.2, QUAD, Enum.EasingDirection.Out)
    minimizeBtn.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch then return end
        TweenService:Create(scale, TI(0.1, QUAD, Enum.EasingDirection.Out), { Scale = 1.05 }):Play()
        TweenService:Create(minimizeBtn, qOut, { BackgroundColor3 = T.MinPressed }):Play()
    end)
    minimizeBtn.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch then return end
        TweenService:Create(scale, qOut, { Scale = 1 }):Play()
        TweenService:Create(minimizeBtn, qOut, { BackgroundColor3 = T.MinA }):Play()
    end)
    minimizeBtn.Activated:Connect(toggleMenu)
end

--============================================================
-- BOOT SEQUENCE
--============================================================
local function typeIntro()
    intro.frame.Visible = true
    intro.label.Text = ""
    intro.label.TextTransparency = 0
    local built = ""
    -- FIX: correct grapheme iteration
    for pos1, pos2 in utf8.graphemes(typedText) do
        built = built .. typedText:sub(pos1, pos2 - 1)
        intro.label.Text = built
        task.wait(0.06)
    end
    intro.label.Text = typedText
end

task.spawn(function()

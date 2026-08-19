--[[
    gw.cc | UI Shell v6.1 — Optimized Motion (Module)
    Written by ENI for LO
--]]

local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local Lighting           = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local IS_TOUCH    = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local uiParent
pcall(function() uiParent = gethui() end)
uiParent = uiParent or LocalPlayer:WaitForChild("PlayerGui")

--============================================================
-- MOTION CONFIG
--============================================================
local MOTION = {
    speed      = 1.0,
    reduce     = false,
    blur       = true,
    dim        = true,
    shimmer    = true,
    idleFloat  = true,
    edgeSnap   = true,
}

--============================================================
-- COLORS
--============================================================
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
    AccentH = Color3.fromRGB(140, 140, 190),
    BarBg   = Color3.fromRGB(24, 24, 32),
    BarA    = Color3.fromRGB(74, 74, 106),
    BarB    = Color3.fromRGB(106, 106, 138),
    BarDone = Color3.fromRGB(130, 130, 175),
    ScrClr  = Color3.fromRGB(42, 42, 53),
    MinA    = Color3.fromRGB(26, 26, 36),
    MinB    = Color3.fromRGB(20, 20, 26),
    MinP    = Color3.fromRGB(30, 30, 40),
    StrkClr = Color3.fromRGB(26, 26, 34),
    StrkAct = Color3.fromRGB(58, 58, 82),
    HLne    = Color3.fromRGB(23, 23, 31),
    MinStrk = Color3.fromRGB(34, 34, 44),
}

--============================================================
-- MOTION CORE
--============================================================
local ES, ED = Enum.EasingStyle, Enum.EasingDirection

local function ti(dur, style, dir)
    return TweenInfo.new(
        math.max(dur * MOTION.speed * (MOTION.reduce and 0.55 or 1), 0.01),
        style or ES.Quint,
        dir or ED.Out
    )
end

local E = {
    micro  = function() return ti(0.14, ES.Quad,  ED.Out)   end,
    snap   = function() return ti(0.22, ES.Quint, ED.Out)   end,
    smooth = function() return ti(0.34, ES.Quint, ED.Out)   end,
    slow   = function() return ti(0.52, ES.Quint, ED.Out)   end,
    exit   = function() return ti(0.20, ES.Quint, ED.In)    end,
    soft   = function() return ti(0.40, ES.Sine,  ED.InOut) end,
}

local Motion = {}
Motion._reg = setmetatable({}, { __mode = "k" })

function Motion.to(obj, group, info, props)
    if not obj then return end
    local reg = Motion._reg[obj]
    if not reg then reg = {}; Motion._reg[obj] = reg end
    local prev = reg[group]
    if prev then prev:Cancel() end
    local t = TweenService:Create(obj, info, props)
    reg[group] = t
    t:Play()
    return t
end

function Motion.kill(obj, group)
    local reg = Motion._reg[obj]
    if reg and reg[group] then reg[group]:Cancel(); reg[group] = nil end
end

local springPool = {}
local springConn

function Motion.spring(scaleObj, target, opts)
    if not scaleObj then return end
    opts = opts or {}
    if MOTION.reduce then
        Motion.to(scaleObj, "scale", E.snap(), { Scale = target })
        return
    end
    local st = springPool[scaleObj]
    if st then
        st.target = target
        if opts.stiffness then st.stiffness = opts.stiffness end
        if opts.damping then st.damping = opts.damping end
        if opts.impulse then st.vel = st.vel + opts.impulse end
    else
        springPool[scaleObj] = {
            target = target,
            vel = opts.impulse or 0,
            stiffness = opts.stiffness or 260,
            damping = opts.damping or 22,
        }
    end
    if not springConn then
        springConn = RunService.RenderStepped:Connect(function(dt)
            dt = math.min(dt, 1 / 30)
            local alive = 0
            for obj, st in pairs(springPool) do
                if not obj.Parent then
                    springPool[obj] = nil
                else
                    local x = obj.Scale
                    local a = (st.target - x) * st.stiffness - st.vel * st.damping
                    st.vel = st.vel + a * dt
                    obj.Scale = x + st.vel * dt
                    if math.abs(st.target - obj.Scale) < 0.0015 and math.abs(st.vel) < 0.02 then
                        obj.Scale = st.target
                        springPool[obj] = nil
                    else
                        alive = alive + 1
                    end
                end
            end
            if alive == 0 then
                springConn:Disconnect()
                springConn = nil
            end
        end)
    end
end

function Motion.press(scaleObj, depth)
    if not scaleObj then return end
    scaleObj.Scale = 1 - (depth or 0.16)
    Motion.spring(scaleObj, 1, { stiffness = 320, damping = 18 })
end

function Motion.stagger(list, step, startAt, fn)
    if MOTION.reduce then
        for i, v in ipairs(list) do fn(v, i) end
        return
    end
    for i, v in ipairs(list) do
        task.delay((startAt or 0) + (i - 1) * step, function() fn(v, i) end)
    end
end

--============================================================
-- HELPERS
--============================================================
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
    return new("ImageLabel", {
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
    return new("UIStroke", {
        Color = color or C.StrkClr,
        Thickness = thick or 1,
        Transparency = transp or 0.3,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function addScale(parent, v)
    return new("UIScale", { Scale = v or 1 }, parent)
end

local function snapshot(root)
    local snap = {}
    local all = root:GetDescendants()
    table.insert(all, 1, root)
    for _, o in ipairs(all) do
        if o:IsA("GuiObject") then
            snap[#snap + 1] = { o, "BackgroundTransparency", o.BackgroundTransparency }
        end
        if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
            snap[#snap + 1] = { o, "TextTransparency", o.TextTransparency }
        elseif o:IsA("ImageLabel") or o:IsA("ImageButton") then
            snap[#snap + 1] = { o, "ImageTransparency", o.ImageTransparency }
        elseif o:IsA("UIStroke") then
            snap[#snap + 1] = { o, "Transparency", o.Transparency }
        end
    end
    return snap
end

local function fadeSnapshot(snap, info, toHidden)
    for _, e in ipairs(snap) do
        local obj, prop, orig = e[1], e[2], e[3]
        if obj and obj.Parent then
            Motion.to(obj, "fade_" .. prop, info, { [prop] = toHidden and 1 or orig })
        end
    end
end

--============================================================
-- SIZING
--============================================================
local cam = workspace.CurrentCamera
local function vpSize()
    return (cam and cam.ViewportSize) or Vector2.new(1280, 720)
end
local viewport = vpSize()
local screenW, screenH = viewport.X, viewport.Y
local small = screenW < 500

local PW = small and math.clamp(math.floor(screenW * 0.80), 260, 420) or 460
local PH = small and math.clamp(math.floor(screenH * 0.55), 260, 380) or 400
local NW, NB, HH = small and 48 or 50, small and 48 or 50, 42
local NF = small and 17 or 16
local WW = small and math.clamp(math.floor(screenW * 0.82), 260, 340) or 340

--============================================================
-- ROOT
--============================================================
local gui = new("ScreenGui", {
    Name = "gwcc_UI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 9999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, uiParent)

task.spawn(function()
    while task.wait(1) do
        if not gui.Parent then gui.Parent = uiParent end
        if not gui.Enabled then gui.Enabled = true end
    end
end)

local dim = new("Frame", {
    Name = "Dim",
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Active = false,
    Size = UDim2.fromScale(1, 1),
    ZIndex = 5,
}, gui)

local blur
if MOTION.blur then
    pcall(function()
        blur = new("BlurEffect", { Name = "gwcc_Blur", Size = 0, Enabled = true }, Lighting)
    end)
end

local function setBackdrop(on)
    if MOTION.dim then
        Motion.to(dim, "bg", E.smooth(), { BackgroundTransparency = on and 0.45 or 1 })
    end
    if blur then
        Motion.to(blur, "blur", E.smooth(), { Size = on and 14 or 0 })
    end
end

--============================================================
-- WELCOME WINDOW
--============================================================
local welcomeTargetPos = UDim2.fromScale(0.5, 0.5)

local welcome = new("Frame", {
    Name = "Welcome",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = welcomeTargetPos + UDim2.fromOffset(0, 34),
    Size = UDim2.fromOffset(WW, 170),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
    Rotation = 1.5,
    ZIndex = 50,
}, gui)
corner(welcome, 10)
local wShadow = dropShadow(welcome, 50, 0.85)
borderStroke(welcome, C.StrkClr, 1, 0.3)
local welcomeScale = addScale(welcome, 0.82)

local wTitle = new("TextLabel", {
    Name = "Title", BackgroundTransparency = 1,
    Text = "Welcome to gw.cc", TextColor3 = C.TxtPri, TextTransparency = 1,
    TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.Code, TextSize = 18,
    Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 0, 28), ZIndex = 1,
}, welcome)

local wCredit = new("TextLabel", {
    Name = "Credit", BackgroundTransparency = 1,
    Text = "by illyxin", TextColor3 = C.TxtMut, TextTransparency = 1,
    TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.Code, TextSize = 12,
    Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 0, 56), ZIndex = 1,
}, welcome)

local barBack = new("Frame", {
    Name = "BarBack", BackgroundColor3 = C.BarBg, BackgroundTransparency = 1,
    BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 84), Size = UDim2.new(0, WW - 60, 0, 6),
    ClipsDescendants = true, ZIndex = 1,
}, welcome)
corner(barBack, 3)

local barFill = new("Frame", {
    Name = "BarFill", BackgroundColor3 = C.BarA, BorderSizePixel = 0,
    Size = UDim2.new(0, 0, 1, 0), ZIndex = 2,
}, barBack)
corner(barFill, 3)
new("UIGradient", { Color = ColorSequence.new(C.BarA, C.BarB), Rotation = 0 }, barFill)

local shimmer = new("Frame", {
    Name = "Shimmer", BackgroundColor3 = Color3.fromRGB(200, 200, 235),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    Size = UDim2.new(0, 70, 1, 0), Position = UDim2.new(0, -70, 0, 0), ZIndex = 3,
}, barBack)
new("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.55),
        NumberSequenceKeypoint.new(1, 1),
    }),
}, shimmer)

local wPct = new("TextLabel", {
    Name = "Percent", BackgroundTransparency = 1,
    Text = "Loading... 0%", TextColor3 = C.TxtBrt, TextTransparency = 1,
    TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.Code, TextSize = 11,
    Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 0, 102), ZIndex = 1,
}, welcome)
local pctScale = addScale(wPct, 1)

--============================================================
-- MAIN MENU PANEL
--============================================================
local panelTargetPos = UDim2.fromScale(0.5, 0.5)

local panel = new("Frame", {
    Name = "MainMenu", AnchorPoint = Vector2.new(0.5, 0.5),
    Position = panelTargetPos + UDim2.fromOffset(0, 44),
    Size = UDim2.fromOffset(PW, PH), BackgroundColor3 = C.Panel,
    BorderSizePixel = 0, Visible = false, Rotation = 1.5, ZIndex = 10,
}, gui)
corner(panel, 10)
local pShadow = dropShadow(panel, 70, 0.85)
local pStroke = borderStroke(panel, C.StrkClr, 1, 0.3)
local panelScale = addScale(panel, 0.84)

local header = new("Frame", {
    Name = "Header", BackgroundColor3 = C.PanelLt, BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, HH), ZIndex = 1,
}, panel)
corner(header, 10)
new("UIGradient", { Color = ColorSequence.new(C.HdrTop, C.Panel), Rotation = 90 }, header)

new("Frame", {
    Name = "HFoot", BackgroundColor3 = C.Panel, BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0),
    Size = UDim2.new(1, 0, 0, 8), ZIndex = 1,
}, header)

new("Frame", {
    Name = "HLine", BackgroundColor3 = C.HLne, BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0),
    Size = UDim2.new(1, 0, 0, 1), ZIndex = 2,
}, header)

local brand = new("TextLabel", {
    Name = "Brand", BackgroundTransparency = 1, Text = "gw.cc",
    TextColor3 = C.TxtPri, TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.Code, TextSize = 15, AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.new(0, 100, 1, 0), ZIndex = 3,
}, header)

local hint = new("TextLabel", {
    Name = "Hint", BackgroundTransparency = 1,
    Text = IS_TOUCH and "tap the tab to toggle" or "RightShift to toggle",
    TextColor3 = C.TxtHint, TextXAlignment = Enum.TextXAlignment.Right,
    Font = Enum.Font.Code, TextSize = 10, AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.new(0, 160, 1, 0), ZIndex = 3,
}, header)

local body = new("Frame", {
    Name = "Body", BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, HH), Size = UDim2.new(1, 0, 1, -HH), ZIndex = 1,
}, panel)

local nav = new("Frame", {
    Name = "Nav", BackgroundColor3 = C.NavCol, BorderSizePixel = 0,
    Size = UDim2.new(0, NW, 1, 0), ZIndex = 1,
}, body)
corner(nav, 10)

new("Frame", {
    Name = "NavTopFill", BackgroundColor3 = C.NavCol, BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 8), ZIndex = 1,
}, nav)

local TABS = { "M", "V", "C" }
local TAB_NAMES = { M = "Main", V = "", C = "Config/Settings" }
local navBtns, navAccs, navScales, navGlow = {}, {}, {}, {}

for i, id in ipairs(TABS) do
    local btn = new("TextButton", {
        Name = "Nav_" .. id, AutoButtonColor = false, BackgroundColor3 = C.NavIna,
        BorderSizePixel = 0, Text = id, TextColor3 = C.TxtMut, Font = Enum.Font.Code,
        TextSize = NF, Position = UDim2.new(0, 0, 0, 8 + (i - 1) * NB),
        Size = UDim2.new(1, 0, 0, NB), ZIndex = 2,
    }, nav)
    corner(btn, 6)

    local acc = new("Frame", {
        Name = "Accent", BackgroundColor3 = C.Accent, BackgroundTransparency = 1,
        BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 3, 0, 0), ZIndex = 3,
    }, btn)
    corner(acc, 2)

    navBtns[id], navAccs[id], navScales[id] = btn, acc, addScale(btn, 1)
end

new("Frame", {
    Name = "NavSep", BackgroundColor3 = C.HLne, BorderSizePixel = 0,
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
    Size = UDim2.new(0, 1, 1, 0), ZIndex = 2,
}, nav)

local function startGlow(id)
    if navGlow[id] then return end
    local acc = navAccs[id]
    if not acc or MOTION.reduce then return end
    navGlow[id] = TweenService:Create(
        acc, TweenInfo.new(1.7, ES.Sine, ED.InOut, -1, true),
        { BackgroundColor3 = C.AccentH }
    )
    navGlow[id]:Play()
end

local function stopGlow(id)
    if navGlow[id] then
        navGlow[id]:Cancel()
        navGlow[id] = nil
        if navAccs[id] then navAccs[id].BackgroundColor3 = C.Accent end
    end
end

local function styleNav(id, active)
    local btn, acc, scl = navBtns[id], navAccs[id], navScales[id]
    if not btn then return end

    Motion.to(btn, "color", E.snap(), {
        BackgroundColor3 = active and C.NavAct or C.NavIna,
        TextColor3       = active and C.TxtPri or C.TxtMut,
    })

    stopGlow(id)

    if active then
        Motion.kill(acc, "glow")
        local grow = Motion.to(acc, "acc", ti(0.3, ES.Quint, ED.Out), {
            BackgroundTransparency = 0,
            Size = UDim2.new(0, 3, 1, -16),
        })
        Motion.spring(scl, 1, { impulse = 0.85, stiffness = 300, damping = 17 })
        if grow and not MOTION.reduce then
            grow.Completed:Once(function()
                startGlow(id)
            end)
        end
    else
        Motion.to(acc, "acc", E.exit(), {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 3, 0, 0),
        })
        Motion.spring(scl, 1)
    end
end

local content = new("Frame", {
    Name = "Content", BackgroundColor3 = C.Panel, BorderSizePixel = 0,
    Position = UDim2.new(0, NW, 0, 0), Size = UDim2.new(1, -NW, 1, 0),
    ClipsDescendants = true, ZIndex = 1,
}, body)
corner(content, 10)

local function mkContentLabel()
    return new("TextLabel", {
        BackgroundTransparency = 1, Text = "", TextColor3 = C.TxtPri, TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center,
        Font = Enum.Font.Code, TextSize = 18, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -20, 0, 30), ZIndex = 2,
    }, content)
end
local labelA, labelB = mkContentLabel(), mkContentLabel()
local frontLabel, backLabel = labelA, labelB

local function crossfadeContent(text, size)
    local outgoing, incoming = frontLabel, backLabel
    frontLabel, backLabel = incoming, outgoing

    incoming.Text = text
    incoming.TextSize = size or 15
    incoming.TextTransparency = 1
    incoming.Position = UDim2.new(0.5, 0, 0.5, 14)
    incoming.ZIndex = 3
    outgoing.ZIndex = 2

    Motion.to(outgoing, "fade", ti(0.2, ES.Quint, ED.In), {
        TextTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, -14),
    })
    Motion.to(incoming, "fade", ti(0.3, ES.Back, ED.Out), {
        TextTransparency = 0, Position = UDim2.fromScale(0.5, 0.5),
    })
end

--============================================================
-- STATE
--============================================================
local activeTab   = "M"
local firstLoad   = true
local firstShow   = true
local typing      = false
local menuVisible = false
local typeIntro

--============================================================
-- FLOATING TOGGLE (FAB)
--============================================================
local FAB = 44
local fabPos = Vector2.new(20 + FAB / 2, screenH * 0.5)

local minBtn = new("ImageButton", {
    Name = "Minimize", AutoButtonColor = false, BackgroundColor3 = C.MinA,
    BorderSizePixel = 0, Image = "", AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromOffset(fabPos.X, fabPos.Y), Size = UDim2.fromOffset(FAB, FAB),
    ZIndex = 30,
}, gui)
corner(minBtn, 12)
dropShadow(minBtn, 34, 0.6)
new("UIGradient", { Color = ColorSequence.new(C.MinA, C.MinB), Rotation = 90 }, minBtn)
borderStroke(minBtn, C.MinStrk, 1, 0.4)
local minScale = addScale(minBtn, 0)

local icon1 = new("Frame", {
    Name = "Icon1", BackgroundColor3 = C.TxtMut, BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -4),
    Size = UDim2.fromOffset(18, 2), ZIndex = 1,
}, minBtn)
corner(icon1, 1)

local icon2 = new("Frame", {
    Name = "Icon2", BackgroundColor3 = C.TxtMut, BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 4),
    Size = UDim2.fromOffset(12, 2), ZIndex = 1,
}, minBtn)
corner(icon2, 1)

local function morphIcon(open)
    local info = ti(0.34, ES.Back, ED.Out)
    if open then
        Motion.to(icon1, "morph", info, {
            Rotation = 45, Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.fromOffset(17, 2), BackgroundColor3 = C.AccentH,
        })
        Motion.to(icon2, "morph", info, {
            Rotation = -45, Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.fromOffset(17, 2), BackgroundColor3 = C.AccentH,
        })
    else
        Motion.to(icon1, "morph", info, {
            Rotation = 0, Position = UDim2.new(0.5, 0, 0.5, -4),
            Size = UDim2.fromOffset(18, 2), BackgroundColor3 = C.TxtMut,
        })
        Motion.to(icon2, "morph", info, {
            Rotation = 0, Position = UDim2.new(0.5, 0, 0.5, 4),
            Size = UDim2.fromOffset(12, 2), BackgroundColor3 = C.TxtMut,
        })
    end
end

local idleFloat
local function startIdle()
    if not MOTION.idleFloat or MOTION.reduce or idleFloat then return end
    idleFloat = TweenService:Create(
        minBtn, TweenInfo.new(2.4, ES.Sine, ED.InOut, -1, true),
        { Rotation = 2.5 }
    )
    idleFloat:Play()
end
local function stopIdle()
    if idleFloat then idleFloat:Cancel(); idleFloat = nil end
    Motion.to(minBtn, "rot", E.snap(), { Rotation = 0 })
end

--============================================================
-- PANEL SHOW / HIDE
--============================================================
local function showPanelAnimated()
    panel.Visible = true
    menuVisible = true
    setBackdrop(true)
    morphIcon(true)

    Motion.to(pShadow, "fade", E.slow(), { ImageTransparency = 0.5 })
    Motion.to(pStroke, "stroke", E.smooth(), { Color = C.StrkAct, Transparency = 0.15 })

    if firstShow then
        firstShow = false
        panelScale.Scale = 0.84
        panel.Position = panelTargetPos + UDim2.fromOffset(0, 44)
        panel.Rotation = 1.5

        Motion.spring(panelScale, 1, { stiffness = 190, damping = 17 })
        Motion.to(panel, "pos", ti(0.5, ES.Quint, ED.Out), { Position = panelTargetPos })
        Motion.to(panel, "rot", ti(0.6, ES.Quint, ED.Out), { Rotation = 0 })

        header.Position = UDim2.new(0, 0, 0, -HH)
        Motion.to(header, "pos", ti(0.45, ES.Quint, ED.Out), { Position = UDim2.new(0, 0, 0, 0) })
        brand.TextTransparency, hint.TextTransparency = 1, 1
        task.delay(0.18, function()
            Motion.to(brand, "fade", E.smooth(), { TextTransparency = 0 })
            Motion.to(hint,  "fade", E.smooth(), { TextTransparency = 0 })
        end)

        for _, id in ipairs(TABS) do
            navScales[id].Scale = 0
            navBtns[id].TextTransparency = 1
        end
        Motion.stagger(TABS, 0.075, 0.16, function(id)
            Motion.spring(navScales[id], 1, { stiffness = 240, damping = 15 })
            Motion.to(navBtns[id], "fade", ti(0.26, ES.Quint, ED.Out), { TextTransparency = 0 })
        end)

        task.delay(MOTION.reduce and 0.15 or 0.42, function() styleNav("M", true) end)
        task.delay(MOTION.reduce and 0.25 or 0.6, function()
            if firstLoad then typeIntro() end
        end)
    else
        panelScale.Scale = 0.9
        panel.Position = panelTargetPos + UDim2.fromOffset(0, 26)
        Motion.spring(panelScale, 1, { stiffness = 260, damping = 18 })
        Motion.to(panel, "pos", E.smooth(), { Position = panelTargetPos })
        Motion.to(panel, "rot", E.smooth(), { Rotation = 0 })
        Motion.spring(navScales[activeTab], 1, { impulse = 0.5 })
        task.delay(0.15, function()
            if menuVisible then startGlow(activeTab) end
        end)
    end
end

local function hidePanelAnimated()
    menuVisible = false
    setBackdrop(false)
    morphIcon(false)

    for id, _ in pairs(navGlow) do
        stopGlow(id)
    end

    Motion.to(pShadow, "fade", E.exit(), { ImageTransparency = 0.9 })
    Motion.to(pStroke, "stroke", E.exit(), { Color = C.StrkClr, Transparency = 0.3 })
    Motion.to(panelScale, "scale", ti(0.22, ES.Quint, ED.In), { Scale = 0.9 })
    Motion.to(panel, "pos", ti(0.22, ES.Quint, ED.In), {
        Position = panelTargetPos + UDim2.fromOffset(0, 22),
    })
    Motion.to(panel, "rot", ti(0.22, ES.Quint, ED.In), { Rotation = -1 })

    task.delay(0.22 * MOTION.speed, function()
        if not menuVisible then panel.Visible = false end
    end)
end

local function toggleMenu()
    if menuVisible then hidePanelAnimated() else showPanelAnimated() end
end

--============================================================
-- NAV EVENTS
--============================================================
for _, id in ipairs(TABS) do
    local btn, scl = navBtns[id], navScales[id]

    if not IS_TOUCH then
        btn.MouseEnter:Connect(function()
            if activeTab ~= id then
                Motion.to(btn, "color", E.micro(), { BackgroundColor3 = C.NavHov })
                Motion.spring(scl, 1.05, { stiffness = 300, damping = 24 })
            end
        end)
        btn.MouseLeave:Connect(function()
            if activeTab ~= id then
                Motion.to(btn, "color", E.micro(), { BackgroundColor3 = C.NavIna })
                Motion.spring(scl, 1, { stiffness = 300, damping = 24 })
            end
        end)
    end

    btn.MouseButton1Click:Connect(function()
        Motion.press(scl, 0.18)
        if activeTab == id and not firstLoad then return end

        local prev = activeTab
        activeTab = id
        firstLoad = false
        typing = false

        if prev ~= id then styleNav(prev, false) end
        styleNav(id, true)
        crossfadeContent(TAB_NAMES[id], 15)
    end)
end

--============================================================
-- DRAGGING
--============================================================
local dragging, dragStart, startPos = false, nil, nil
local minDragging, minDragStart, minStartPos, minMoved = false, nil, nil, false
local minVel, lastMinPos, lastMinT = Vector2.zero, Vector2.zero, 0

local function startDrag(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
        Motion.spring(panelScale, 1.015, { stiffness = 260, damping = 26 })
        Motion.to(pShadow, "drag", E.smooth(), { ImageTransparency = 0.35 })
    end
end

panel.InputBegan:Connect(startDrag)
header.InputBegan:Connect(startDrag)
body.InputBegan:Connect(startDrag)
nav.InputBegan:Connect(startDrag)
content.InputBegan:Connect(startDrag)

minBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        minDragging = true
        minMoved = false
        minDragStart = input.Position
        minStartPos = fabPos
        minVel = Vector2.zero
        lastMinPos = Vector2.new(input.Position.X, input.Position.Y)
        lastMinT = os.clock()
        stopIdle()
        Motion.press(minScale, 0.16)
        Motion.to(minBtn, "color", E.micro(), { BackgroundColor3 = C.MinP })
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then return end

    if dragging then
        dragging = false
        Motion.spring(panelScale, 1, { stiffness = 240, damping = 20 })
        Motion.to(pShadow, "drag", E.smooth(), {
            ImageTransparency = menuVisible and 0.5 or 0.9,
        })
    end

    if minDragging then
        minDragging = false
        Motion.to(minBtn, "color", E.micro(), { BackgroundColor3 = C.MinA })

        if not minMoved then
            toggleMenu()
            Motion.spring(minScale, 1, { impulse = 1.1 })
        else
            local vp = vpSize()
            local pad = FAB / 2 + 14
            local projected = fabPos + minVel * 0.12
            local targetX = projected.X
            if MOTION.edgeSnap then
                targetX = (projected.X < vp.X * 0.5) and pad or (vp.X - pad)
            end
            local targetY = math.clamp(projected.Y, pad, vp.Y - pad)
            fabPos = Vector2.new(targetX, targetY)
            Motion.to(minBtn, "pos", ti(0.45, ES.Back, ED.Out), {
                Position = UDim2.fromOffset(fabPos.X, fabPos.Y),
            })
        end
        startIdle()
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
    and input.UserInputType ~= Enum.UserInputType.Touch then return end

    if dragging and dragStart then
        local d = input.Position - dragStart
        panel.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
        panelTargetPos = panel.Position
    end

    if minDragging and minDragStart then
        local d = input.Position - minDragStart
        if d.Magnitude > 6 then minMoved = true end

        local now = os.clock()
        local dt = math.max(now - lastMinT, 1 / 240)
        local cur = Vector2.new(input.Position.X, input.Position.Y)
        minVel = (cur - lastMinPos) / dt
        lastMinPos, lastMinT = cur, now

        local vp = vpSize()
        local pad = FAB / 2 + 4
        fabPos = Vector2.new(
            math.clamp(minStartPos.X + d.X, pad, vp.X - pad),
            math.clamp(minStartPos.Y + d.Y, pad, vp.Y - pad)
        )
        Motion.kill(minBtn, "pos")
        minBtn.Position = UDim2.fromOffset(fabPos.X, fabPos.Y)
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        toggleMenu()
    end
end)

--============================================================
-- TYPING
--============================================================
function typeIntro()
    typing = true
    frontLabel.Text = ""
    frontLabel.TextSize = 18
    frontLabel.TextTransparency = 0
    frontLabel.Position = UDim2.fromScale(0.5, 0.5)
    backLabel.TextTransparency = 1

    local raw = LocalPlayer.DisplayName
    if not raw or raw == "" then raw = LocalPlayer.Name end
    raw = tostring(raw):gsub("[^%w%s_%.%-]", "")

    local full, built = "Welcome, " .. raw .. "!", ""
    for i = 1, #full do
        if not typing then return end
        local ch = full:sub(i, i)
        built = built .. ch
        frontLabel.Text = built .. "_"

        local w = 0.055
        if ch == " " then w = 0.028
        elseif ch == "," then w = 0.16
        elseif ch == "!" then w = 0.2
        end
        task.wait(w * MOTION.speed)
    end

    for _ = 1, 3 do
        if not typing then frontLabel.Text = full; return end
        frontLabel.Text = full .. "_"; task.wait(0.2)
        frontLabel.Text = full;         task.wait(0.2)
    end
    frontLabel.Text = full
    typing = false
end

--============================================================
-- BOOT SEQUENCE
--============================================================
local loadTarget = 0

local function tweenBar(target, dur)
    loadTarget = target
    Motion.to(barFill, "size", ti(dur, ES.Quint, ED.Out), {
        Size = UDim2.new(target, 0, 1, 0),
    })
    task.wait(dur * MOTION.speed)
end

task.spawn(function()
    local conns = {}
    local ok, err = pcall(function()
        Motion.spring(welcomeScale, 1, { stiffness = 190, damping = 17 })
        Motion.to(welcome, "pos", ti(0.5, ES.Quint, ED.Out), { Position = welcomeTargetPos })
        Motion.to(welcome, "rot", ti(0.6, ES.Quint, ED.Out), { Rotation = 0 })
        Motion.to(wShadow, "fade", E.slow(), { ImageTransparency = 0.5 })

        Motion.stagger({ wTitle, wCredit, barBack, wPct }, 0.08, 0.12, function(obj)
            if obj == barBack then
                Motion.to(obj, "fade", E.smooth(), { BackgroundTransparency = 0 })
            else
                Motion.to(obj, "fade", E.smooth(), { TextTransparency = 0 })
            end
            if obj.Parent and obj:IsA("TextLabel") then
                obj.Position = obj.Position + UDim2.fromOffset(0, 6)
                Motion.to(obj, "pos", E.smooth(), {
                    Position = obj.Position - UDim2.fromOffset(0, 6),
                })
            end
        end)

        task.delay(0.34, function()
            Motion.spring(minScale, 1, { stiffness = 240, damping = 15 })
            task.delay(0.45, startIdle)
        end)

        local shown = 0
        conns[#conns + 1] = RunService.RenderStepped:Connect(function(dt)
            local actual = barFill.Size.X.Scale
            shown = shown + (actual - shown) * math.min(dt * 9, 1)
            wPct.Text = string.format("Loading... %d%%", math.floor(shown * 100 + 0.5))
            wPct.TextColor3 = C.TxtBrt:Lerp(C.BarDone, shown)

            if MOTION.shimmer and not MOTION.reduce then
                shimmer.BackgroundTransparency = (actual > 0.02) and 0 or 1
            end
        end)

        if MOTION.shimmer and not MOTION.reduce then
            task.spawn(function()
                while shimmer.Parent do
                    local w = barBack.AbsoluteSize.X
                    shimmer.Position = UDim2.new(0, -70, 0, 0)
                    Motion.to(shimmer, "sweep", TweenInfo.new(1.1, ES.Sine, ED.InOut), {
                        Position = UDim2.new(0, (w > 0 and w or WW - 60) + 10, 0, 0),
                    })
                    task.wait(1.5)
                end
            end)
        end

        tweenBar(0.15, 0.8); task.wait(0.4 * MOTION.speed)
        tweenBar(0.35, 0.7); task.wait(0.5 * MOTION.speed)
        tweenBar(0.55, 0.8); task.wait(0.4 * MOTION.speed)
        tweenBar(0.75, 0.6); task.wait(0.5 * MOTION.speed)
        tweenBar(0.90, 0.5); task.wait(0.4 * MOTION.speed)
        tweenBar(1.00, 0.4)

        Motion.to(barFill, "color", E.snap(), { BackgroundColor3 = C.BarDone })
        Motion.press(pctScale, -0.12)
        task.wait(0.3 * MOTION.speed)

        for _, c in ipairs(conns) do c:Disconnect() end
        conns = {}

        local snap = snapshot(welcome)
        fadeSnapshot(snap, ti(0.35, ES.Quint, ED.In), true)
        Motion.to(welcomeScale, "scale", ti(0.35, ES.Quint, ED.In), { Scale = 0.88 })
        Motion.to(welcome, "rot", ti(0.35, ES.Quint, ED.In), { Rotation = -1.5 })

        task.delay(0.14, showPanelAnimated)
        task.delay(0.5, function() if welcome then welcome:Destroy() end end)
    end)

    if not ok then
        for _, c in ipairs(conns) do c:Disconnect() end
        warn("[gw.cc] Boot error: " .. tostring(err))
    end
end)

--============================================================
-- CLEANUP
--============================================================
gui.Destroying:Connect(function()
    stopIdle()
    for id, _ in pairs(navGlow) do stopGlow(id) end
    if springConn then springConn:Disconnect() end
    if blur then pcall(function() blur:Destroy() end) end
end)

--============================================================
-- MODULE EXPORTS
--============================================================
return {
    gui         = gui,
    panel       = panel,
    body        = body,
    nav         = nav,
    content     = content,
    header      = header,
    Motion      = Motion,
    C           = C,
    E           = E,
    ES          = ES,
    ED          = ED,
    ti          = ti,
    new         = new,
    corner      = corner,
    dropShadow  = dropShadow,
    borderStroke = borderStroke,
    addScale    = addScale,
    TABS        = TABS,
    TAB_NAMES   = TAB_NAMES,
    navBtns     = navBtns,
    navScales   = navScales,
    styleNav    = styleNav,
    startGlow   = startGlow,
    stopGlow    = stopGlow,
    crossfadeContent = crossfadeContent,
    frontLabel  = frontLabel,
    backLabel   = backLabel,
    toggleMenu  = toggleMenu,
    small       = small,
    PW          = PW,
    PH          = PH,
    NW          = NW,
    NB          = NB,
    HH          = HH,
    NF          = NF,
    vpSize      = vpSize,
    LocalPlayer = LocalPlayer,
}

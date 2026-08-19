--!nocheck
--[[ settings_components.luau
     usage:  local Comp = loadstring(source)(UI)
     returns { createToggle, createAccordion, createColorSetting, createSlider, buildVisualTab, Settings }
]]

local UI = ...
if type(UI) ~= "table" then
    local ok, g = pcall(function() return getgenv() end)
    if ok and type(g) == "table" then UI = g.UI end
end
assert(type(UI) == "table", "[components] pass the host UI table: loadstring(src)(UI)")

local C      = UI.C
local E      = UI.E
local Motion = UI.Motion
local UIS    = game:GetService("UserInputService")
local GuiSvc = game:GetService("GuiService")
local TS     = game:GetService("TweenService")

local TOUCH  = UIS.TouchEnabled and not UIS.MouseEnabled
local FONT   = Enum.Font.Code

----------------------------------------------------------------------
-- palette constants (spec-locked)
----------------------------------------------------------------------
local TRK_OFF  = Color3.fromRGB(28, 28, 38)
local TRK_ON   = Color3.fromRGB(60, 60, 90)
local TRK_EDGE = Color3.fromRGB(34, 34, 44)
local KNB_OFF  = Color3.fromRGB(180, 180, 195)
local KNB_ON   = Color3.fromRGB(228, 228, 232)
local KNOB_L, KNOB_R = 11, 29
local SQ_EDGE  = Color3.fromRGB(40, 40, 50)
local TRACK_BG = Color3.fromRGB(24, 24, 32)

-- NEW: Default ESP colors per type
local DEFAULT_COLORS = {
    killer    = Color3.fromRGB(255, 0, 0),
    survivor  = Color3.fromRGB(0, 100, 255),
    pallet    = Color3.fromRGB(255, 165, 0),
    window    = Color3.fromRGB(255, 255, 255),
    generator = Color3.fromRGB(255, 255, 0),
    hook      = Color3.fromRGB(139, 69, 19),
    zombie    = Color3.fromRGB(128, 0, 128),
}

-- NEW: Global settings table — the ESP module reads from this
local Settings = {
    esp = {
        killer = {
            enabled = false, name = false, distance = false,
            outline = { enabled = true, color = DEFAULT_COLORS.killer },
            fill    = { enabled = false, color = DEFAULT_COLORS.killer },
        },
        survivor = {
            enabled = false, name = false, distance = false, healthStatus = false,
            outline = { enabled = true, color = DEFAULT_COLORS.survivor },
            fill    = { enabled = false, color = DEFAULT_COLORS.survivor },
        },
        pallet = {
            enabled = false, name = false, distance = false,
            outline = { enabled = true, color = DEFAULT_COLORS.pallet },
            fill    = { enabled = false, color = DEFAULT_COLORS.pallet },
        },
        window = {
            enabled = false, name = false, distance = false,
            outline = { enabled = true, color = DEFAULT_COLORS.window },
            fill    = { enabled = false, color = DEFAULT_COLORS.window },
        },
        generator = {
            enabled = false, name = false, distance = false, progress = false,
            outline = { enabled = true, color = DEFAULT_COLORS.generator },
            fill    = { enabled = false, color = DEFAULT_COLORS.generator },
        },
        hook = {
            enabled = false, name = false, distance = false,
            outline = { enabled = true, color = DEFAULT_COLORS.hook },
            fill    = { enabled = false, color = DEFAULT_COLORS.hook },
        },
        zombie = {
            enabled = false, name = false, distance = false,
            outline = { enabled = true, color = DEFAULT_COLORS.zombie },
            fill    = { enabled = false, color = DEFAULT_COLORS.zombie },
        },
    },
    render = {
        fov = 70,
        brightness = 50,
        noFog = false,
    },
}

----------------------------------------------------------------------
-- thin wrappers over the host API (with safe fallbacks)
----------------------------------------------------------------------
local new = UI.new or function(class, props, parent)
    local i = Instance.new(class)
    for k, v in pairs(props or {}) do i[k] = v end
    i.Parent = parent
    return i
end

local function ti(d, style, dir)
    local st = (UI.ES and UI.ES[style]) or Enum.EasingStyle[style]
    local dr = (UI.ED and UI.ED[dir]) or Enum.EasingDirection[dir]
    if UI.ti then return UI.ti(d, st, dr) end
    return TweenInfo.new(d, st, dr)
end

local function micro() return (E and E.micro and E.micro()) or ti(0.12, "Quad", "Out") end

local function mto(obj, group, info, props)
    if Motion and Motion.to then return Motion.to(obj, group, info, props) end
    local t = TS:Create(obj, info, props); t:Play(); return t
end

local function mkill(obj, group)
    if Motion and Motion.kill then Motion.kill(obj, group) end
end

local function mspring(scaleObj, target, opts)
    if Motion and Motion.spring then return Motion.spring(scaleObj, target, opts) end
    return mto(scaleObj, "spring", ti(0.28, "Back", "Out"), { Scale = target })
end

local function mpress(scaleObj, depth)
    if Motion and Motion.press then return Motion.press(scaleObj, depth) end
    mto(scaleObj, "press", ti(0.08, "Quad", "Out"), { Scale = 1 - (depth or 0.1) })
    task.delay(0.09, function() mspring(scaleObj, 1) end)
end

local function mstagger(list, step, startAt, fn)
    if Motion and Motion.stagger then return Motion.stagger(list, step, startAt, fn) end
    task.spawn(function()
        task.wait(startAt or 0)
        for i, item in ipairs(list) do fn(item, i); task.wait(step or 0.03) end
    end)
end

----------------------------------------------------------------------
-- primitives
----------------------------------------------------------------------
local function round(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = (typeof(r) == "UDim") and r or UDim.new(0, r or 6)
    c.Parent = inst
    return c
end

local function edge(inst, color, thick, transp)
    local s = Instance.new("UIStroke")
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Color = color
    s.Thickness = thick or 1
    s.Transparency = transp or 0
    s.Parent = inst
    return s
end

local function scaleOf(inst, v)
    local s = inst:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
    s.Scale = v or 1
    s.Parent = inst
    return s
end

local function lighten(c, a) return c:Lerp(Color3.new(1, 1, 1), a) end

-- OPTIMIZATION: cache screen offset per picker open instead of per drag move
local function screenOffset()
    local gui = UI.gui
    if gui and gui.IgnoreGuiInset then return Vector2.new(0, 0) end
    local ins = GuiSvc:GetGuiInset()
    return Vector2.new(ins.X, ins.Y)
end

local function isPointer(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

----------------------------------------------------------------------
-- SHARED: switch (used by Component 1, accordions and the picker)
----------------------------------------------------------------------
local function makeSwitch(parent, opts)
    opts = opts or {}
    local z    = opts.zIndex or 2
    local pad  = opts.rightPad or 14
    local onToggle = opts.onToggle

    local track = new("TextButton", {
        Name = "SwitchTrack",
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = TRK_OFF,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -pad, 0.5, 0),
        Size = UDim2.fromOffset(40, 22),
        ZIndex = z,
    }, parent)
    round(track, UDim.new(1, 0))
    edge(track, TRK_EDGE, 1, 0.4)
    local tsc = scaleOf(track, 1)

    local knob = new("Frame", {
        Name = "Knob",
        BackgroundColor3 = KNB_OFF,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(16, 16),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, KNOB_L, 0.5, 0),
        ZIndex = z + 1,
    }, track)
    round(knob, UDim.new(1, 0))

    local api = { track = track, knob = knob, scale = tsc }
    local state, hovering = false, false

    local function paint(animate)
        local bg = state and TRK_ON or TRK_OFF
        if hovering then bg = lighten(bg, 0.08) end
        local kx  = state and KNOB_R or KNOB_L
        local kcl = state and KNB_ON or KNB_OFF
        if animate then
            mto(knob,  "knobX",  ti(0.30, "Back",  "Out"), { Position = UDim2.new(0, kx, 0.5, 0) })
            mto(knob,  "knobCol", ti(0.25, "Quint", "Out"), { BackgroundColor3 = kcl })
            mto(track, "trackBg", ti(0.25, "Quint", "Out"), { BackgroundColor3 = bg })
        else
            mkill(knob, "knobX"); mkill(knob, "knobCol"); mkill(track, "trackBg")
            knob.Position = UDim2.new(0, kx, 0.5, 0)
            knob.BackgroundColor3 = kcl
            track.BackgroundColor3 = bg
        end
    end

    function api.getState() return state end

    function api.setState(on, animate, silent)
        on = on and true or false
        local changed = (on ~= state)
        state = on
        paint(animate ~= false)
        if changed and not silent then
            if onToggle then task.spawn(onToggle, state) end
            if api.onToggle then task.spawn(api.onToggle, state) end
        end
        return state
    end

    track.MouseButton1Click:Connect(function()
        mpress(tsc, 0.12)
        api.setState(not state, true)
    end)

    if not TOUCH then
        track.MouseEnter:Connect(function()
            hovering = true
            mto(track, "trackBg", micro(), { BackgroundColor3 = lighten(state and TRK_ON or TRK_OFF, 0.08) })
        end)
        track.MouseLeave:Connect(function()
            hovering = false
            mto(track, "trackBg", micro(), { BackgroundColor3 = state and TRK_ON or TRK_OFF })
        end)
    end

    api.setState(opts.default, false, true)
    return api
end

----------------------------------------------------------------------
-- COMPONENT 1: TOGGLE
----------------------------------------------------------------------
local function createToggle(parent, name, defaultState, onToggle, textSize)
    local row = new("Frame", {
        Name = "ToggleRow_" .. tostring(name),
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
    }, parent)

    new("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Text = tostring(name),
        TextColor3 = C.TxtPri,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = FONT,
        TextSize = textSize or 13,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -80, 1, 0),
        ZIndex = 2,
    }, row)

    local sw = makeSwitch(row, { default = defaultState, onToggle = onToggle, rightPad = 14, zIndex = 2 })

    return {
        frame    = row,
        switch   = sw,
        setState = function(on, animate) return sw.setState(on, animate ~= false) end,
        getState = sw.getState,
    }
end

----------------------------------------------------------------------
-- COMPONENT 2: ACCORDION
----------------------------------------------------------------------
local function createAccordion(parent, name, hasToggle, defaultExpanded, textSize)
    local onToggle = (type(hasToggle) == "function") and hasToggle or nil
    local withToggle = onToggle ~= nil or hasToggle == true

    local container = new("Frame", {
        Name = "Accordion_" .. tostring(name),
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    }, parent)

    local header = new("TextButton", {
        Name = "Header",
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 36),
        ZIndex = 2,
    }, container)
    local hsc = scaleOf(header, 1)

    local expanded = defaultExpanded and true or false

    local arrow = new("TextLabel", {
        Name = "Arrow",
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = C.TxtMut,
        Font = FONT,
        TextSize = 10,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.fromOffset(20, 36),
        Rotation = expanded and 0 or -90,
        ZIndex = 3,
    }, header)

    local title = new("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Text = tostring(name),
        TextColor3 = C.TxtPri,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = FONT,
        TextSize = textSize or 13,
        Position = UDim2.new(0, 30, 0, 0),
        Size = UDim2.new(1, -80, 1, 0),
        ZIndex = 3,
    }, header)

    local sw
    if withToggle then
        sw = makeSwitch(header, { default = false, onToggle = onToggle, rightPad = 54, zIndex = 4 })
    end

    local content = new("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 36),
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        ZIndex = 2,
    }, container)

    local layout = new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        FillDirection = Enum.FillDirection.Vertical,
    }, content)

    local order = 0
    content.ChildAdded:Connect(function(ch)
        if ch:IsA("GuiObject") and ch.LayoutOrder == 0 then
            order += 1
            ch.LayoutOrder = order
        end
    end)

    local function measured()
        return math.max(0, layout.AbsoluteContentSize.Y + 6)
    end

    local function apply(animate)
        local h = expanded and measured() or 0
        if animate then
            local info = expanded and ti(0.30, "Back", "Out") or ti(0.25, "Quint", "In")
            mto(content,   "accH", info, { Size = UDim2.new(1, 0, 0, h) })
            mto(container, "accH", info, { Size = UDim2.new(1, 0, 0, 36 + h) })
        else
            mkill(content, "accH"); mkill(container, "accH")
            content.Size   = UDim2.new(1, 0, 0, h)
            container.Size = UDim2.new(1, 0, 0, 36 + h)
        end
    end

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if expanded then apply(true) end
    end)

    local acc = { frame = container, content = content, header = header, toggle = sw }

    function acc.isExpanded() return expanded end

    function acc.setExpanded(on, animate)
        on = on and true or false
        expanded = on
        animate = animate ~= false
        if animate then
            mto(arrow, "arrowRot", ti(0.28, "Back", "Out"), { Rotation = on and 0 or -90 })
        else
            mkill(arrow, "arrowRot")
            arrow.Rotation = on and 0 or -90
        end
        apply(animate)

        if on and animate then
            local kids = {}
            for _, ch in ipairs(content:GetChildren()) do
                if ch:IsA("GuiObject") then table.insert(kids, ch) end
            end
            table.sort(kids, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
            for _, kid in ipairs(kids) do scaleOf(kid, 0.94) end
            mstagger(kids, 0.03, 0.02, function(kid)
                local s = kid:FindFirstChildOfClass("UIScale")
                if s then mspring(s, 1) end
            end)
        end
        return expanded
    end

    function acc.addRow(inst)
        order += 1
        inst.LayoutOrder = order
        inst.Parent = content
        return inst
    end

    function acc.refresh() apply(true) end

    header.MouseButton1Click:Connect(function()
        mpress(hsc, 0.08)
        acc.setExpanded(not expanded, true)
    end)

    if not TOUCH then
        header.MouseEnter:Connect(function()
            mto(title, "hdrTxt", micro(), { TextColor3 = C.AccentH })
            mto(arrow, "hdrArw", micro(), { TextColor3 = C.TxtPri })
        end)
        header.MouseLeave:Connect(function()
            mto(title, "hdrTxt", micro(), { TextColor3 = C.TxtPri })
            mto(arrow, "hdrArw", micro(), { TextColor3 = C.TxtMut })
        end)
    end

    apply(false)
    return acc
end

----------------------------------------------------------------------
-- COMPONENT 3: COLOR SQUARE + HSV PICKER
----------------------------------------------------------------------
local activePicker = nil

local function openPicker(cfg)
    if activePicker then activePicker.close() end

    local gui   = UI.gui
    local small = UI.small
    local h, s, v = cfg.color:ToHSV()
    local enabled = cfg.enabled and true or false

    local svH = small and 140 or 160
    local pw  = small and 210 or 240
    local yHue  = 12 + svH + 12
    local yPrev = yHue + 16 + 12
    local yEn   = yPrev + 28 + 10
    local ph    = yEn + 30 + 12

    local backdrop = new("Frame", {
        Name = "ColorPickerOverlay",
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Active = true,
        ZIndex = 100,
    }, gui)

    local dismiss = new("TextButton", {
        Name = "Dismiss",
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 100,
    }, backdrop)

    local panel = new("Frame", {
        Name = "PickerPanel",
        BackgroundColor3 = C.Panel,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(pw, ph),
        Active = true,
        ZIndex = 101,
    }, backdrop)
    round(panel, 8)
    edge(panel, C.StrkClr, 1, 0.15)
    if UI.dropShadow then pcall(UI.dropShadow, panel, 30, 0.55) end
    local psc = scaleOf(panel, 0.85)

    -- SV square ------------------------------------------------------
    local sv = new("Frame", {
        Name = "SV",
        BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 0, 12),
        Size = UDim2.new(1, -24, 0, svH),
        ClipsDescendants = true,
        ZIndex = 102,
    }, panel)
    round(sv, 6)

    local white = new("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 103,
    }, sv)
    round(white, 6)
    new("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, white)

    local black = new("Frame", {
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 104,
    }, sv)
    round(black, 6)
    new("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        }),
    }, black)

    local cursor = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(12, 12),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(s, 1 - v),
        ZIndex = 105,
    }, sv)
    round(cursor, UDim.new(1, 0))
    edge(cursor, Color3.new(1, 1, 1), 2, 0.05)

    local svHit = new("TextButton", {
        Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1), ZIndex = 106,
    }, sv)

    -- hue slider -----------------------------------------------------
    local hueKeys = {}
    for i = 0, 6 do
        table.insert(hueKeys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
    end

    local hue = new("Frame", {
        Name = "Hue",
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 0, yHue),
        Size = UDim2.new(1, -24, 0, 16),
        ZIndex = 102,
    }, panel)
    round(hue, 4)
    new("UIGradient", { Color = ColorSequence.new(hueKeys) }, hue)

    local hueInd = new("Frame", {
        BackgroundColor3 = Color3.fromRGB(240, 240, 245),
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(6, 22),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(h, 0.5),
        ZIndex = 104,
    }, hue)
    round(hueInd, 3)
    edge(hueInd, Color3.fromRGB(20, 20, 26), 1, 0.3)

    local hueHit = new("TextButton", {
        Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 12), Position = UDim2.new(0, 0, 0, -6), ZIndex = 105,
    }, hue)

    -- preview + rgb --------------------------------------------------
    local preview = new("Frame", {
        BackgroundColor3 = cfg.color,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 0, yPrev),
        Size = UDim2.fromOffset(28, 28),
        ZIndex = 102,
    }, panel)
    round(preview, 6)
    edge(preview, SQ_EDGE, 1, 0)

    local rgbText = new("TextLabel", {
        BackgroundTransparency = 1,
        Font = FONT,
        TextSize = 12,
        TextColor3 = C.TxtMut,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 48, 0, yPrev),
        Size = UDim2.new(1, -60, 0, 28),
        Text = "",
        ZIndex = 102,
    }, panel)

    -- enable row -----------------------------------------------------
    local enRow = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, yEn),
        Size = UDim2.new(1, -24, 0, 30),
        ZIndex = 102,
    }, panel)

    new("TextLabel", {
        BackgroundTransparency = 1,
        Font = FONT,
        TextSize = 12,
        TextColor3 = C.TxtPri,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Enabled",
        Size = UDim2.new(1, -50, 1, 0),
        ZIndex = 103,
    }, enRow)

    local conns = {}
    local dragging = nil
    local closing = false

    -- OPTIMIZATION: cache screen offset once per picker open
    local cachedOffset = screenOffset()

    local function push(smooth)
        local col = Color3.fromHSV(h, s, v)
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        preview.BackgroundColor3 = col
        rgbText.Text = string.format("R:%d G:%d B:%d",
            math.floor(col.R * 255 + 0.5),
            math.floor(col.G * 255 + 0.5),
            math.floor(col.B * 255 + 0.5))
        if smooth then
            mto(cursor, "svCur",  ti(0.06, "Quad", "Out"), { Position = UDim2.fromScale(s, 1 - v) })
            mto(hueInd, "hueInd", ti(0.08, "Quad", "Out"), { Position = UDim2.fromScale(h, 0.5) })
        else
            mkill(cursor, "svCur"); mkill(hueInd, "hueInd")
            cursor.Position = UDim2.fromScale(s, 1 - v)
            hueInd.Position = UDim2.fromScale(h, 0.5)
        end
        if cfg.apply then cfg.apply(col, enabled) end
    end

    local enSwitch = makeSwitch(enRow, {
        default = enabled, rightPad = 0, zIndex = 103,
        onToggle = function(on) enabled = on; push(true) end,
    })

    local function fromSV(p)
        local ap, as = sv.AbsolutePosition + cachedOffset, sv.AbsoluteSize
        s = math.clamp((p.X - ap.X) / math.max(as.X, 1), 0, 1)
        v = 1 - math.clamp((p.Y - ap.Y) / math.max(as.Y, 1), 0, 1)
        push(true)
    end

    local function fromHue(p)
        local ap, as = hue.AbsolutePosition + cachedOffset, hue.AbsoluteSize
        h = math.clamp((p.X - ap.X) / math.max(as.X, 1), 0, 1)
        push(true)
    end

    table.insert(conns, svHit.InputBegan:Connect(function(i)
        if isPointer(i) then dragging = "sv"; fromSV(i.Position) end
    end))
    table.insert(conns, hueHit.InputBegan:Connect(function(i)
        if isPointer(i) then dragging = "hue"; fromHue(i.Position) end
    end))
    table.insert(conns, UIS.InputChanged:Connect(function(i)
        if not dragging or not isMove(i) then return end
        if dragging == "sv" then fromSV(i.Position) else fromHue(i.Position) end
    end))
    table.insert(conns, UIS.InputEnded:Connect(function(i)
        if isPointer(i) then dragging = nil end
    end))

    local api = {}

    function api.close()
        if closing then return end
        closing = true
        if activePicker == api then activePicker = nil end
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        table.clear(conns)
        mto(backdrop, "fade", ti(0.18, "Quint", "In"), { BackgroundTransparency = 1 })
        mto(psc, "pop", ti(0.18, "Quint", "In"), { Scale = 0.9 })
        task.delay(0.2, function()
            if backdrop and backdrop.Parent then backdrop:Destroy() end
        end)
        if cfg.onClose then cfg.onClose() end
    end

    dismiss.MouseButton1Click:Connect(api.close)

    push(false)
    mto(backdrop, "fade", ti(0.20, "Quad", "Out"), { BackgroundTransparency = 0.5 })
    mspring(psc, 1)

    activePicker = api
    return api
end

local function createColorSetting(parent, name, defaultColor, defaultEnabled, onColorChange, textSize)
    local color   = defaultColor or Color3.fromRGB(255, 255, 255)
    local enabled = defaultEnabled and true or false

    local row = new("Frame", {
        Name = "ColorRow_" .. tostring(name),
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
    }, parent)

    new("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Text = tostring(name),
        TextColor3 = C.TxtPri,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = FONT,
        TextSize = textSize or 12,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -104, 1, 0),
        ZIndex = 2,
    }, row)

    local square = new("TextButton", {
        Name = "ColorSquare",
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(20, 20),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -64, 0.5, 0),
        ZIndex = 3,
    }, row)
    round(square, 4)
    edge(square, SQ_EDGE, 1, 0)
    local ssc = scaleOf(square, 1)

    local cross = new("TextLabel", {
        Name = "Off",
        BackgroundTransparency = 1,
        Text = "✕",
        Font = FONT,
        TextSize = 12,
        TextColor3 = C.TxtHint,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        ZIndex = 4,
    }, square)

    local api = { frame = row, square = square }

    local function paintSquare(animate)
        local target = enabled and 0 or 0.55
        cross.Visible = not enabled
        if animate then
            mto(square, "sqFade", micro(), { BackgroundTransparency = target, BackgroundColor3 = color })
        else
            mkill(square, "sqFade")
            square.BackgroundTransparency = target
            square.BackgroundColor3 = color
        end
    end

    local function fire()
        if onColorChange then task.spawn(onColorChange, color, enabled) end
    end

    local sw = makeSwitch(row, {
        default = enabled, rightPad = 14, zIndex = 2,
        onToggle = function(on) enabled = on; paintSquare(true); fire() end,
    })

    square.MouseButton1Click:Connect(function()
        mpress(ssc, 0.12)
        openPicker({
            color = color,
            enabled = enabled,
            apply = function(newColor, newEnabled)
                color, enabled = newColor, newEnabled
                paintSquare(true)
                if sw.getState() ~= enabled then sw.setState(enabled, true, true) end
                fire()
            end,
        })
    end)

    if not TOUCH then
        square.MouseEnter:Connect(function() mspring(ssc, 1.12) end)
        square.MouseLeave:Connect(function() mspring(ssc, 1) end)
    end

    api.getColor   = function() return color end
    api.getEnabled = function() return enabled end
    api.switch     = sw
    function api.setColor(newColor, newEnabled)
        color = newColor or color
        if newEnabled ~= nil then
            enabled = newEnabled and true or false
            sw.setState(enabled, true, true)
        end
        paintSquare(true)
        fire()
    end

    paintSquare(false)
    return api
end

----------------------------------------------------------------------
-- COMPONENT 4: SLIDER
----------------------------------------------------------------------
local function createSlider(parent, name, minV, maxV, default, suffix, onValueChange)
    minV = minV or 0
    maxV = maxV or 100
    suffix = suffix or ""

    local row = new("Frame", {
        Name = "SliderRow_" .. tostring(name),
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
    }, parent)

    new("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Text = tostring(name),
        TextColor3 = C.TxtPri,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = FONT,
        TextSize = 13,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0.5, 0, 0, 20),
        ZIndex = 2,
    }, row)

    local valueTxt = new("TextLabel", {
        Name = "Value",
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = C.TxtMut,
        TextXAlignment = Enum.TextXAlignment.Right,
        Font = FONT,
        TextSize = 12,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 0),
        Size = UDim2.new(0, 60, 0, 20),
        ZIndex = 2,
    }, row)

    local track = new("Frame", {
        Name = "Track",
        BackgroundColor3 = TRACK_BG,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 0, 26),
        Size = UDim2.new(1, -28, 0, 6),
        ZIndex = 2,
    }, row)
    round(track, 3)

    local fill = new("Frame", {
        Name = "Fill",
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
        ZIndex = 3,
    }, track)
    round(fill, 3)
    new("UIGradient", { Color = ColorSequence.new(C.BarA, C.BarB) }, fill)

    local handle = new("Frame", {
        Name = "Handle",
        BackgroundColor3 = C.TxtPri,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(14, 14),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        ZIndex = 4,
    }, track)
    round(handle, UDim.new(1, 0))
    local hsc = scaleOf(handle, 1)

    local hit = new("TextButton", {
        Name = "Hit",
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 18),
        Size = UDim2.new(1, -28, 0, 22),
        ZIndex = 5,
    }, row)

    local value = math.clamp(default or minV, minV, maxV)
    local dragging = false

    local function quantize(x)
        if (maxV - minV) >= 5 then return math.floor(x + 0.5) end
        return math.floor(x * 100 + 0.5) / 100
    end

    local function frac() return (value - minV) / math.max(maxV - minV, 1e-6) end

    local function paint(animate)
        local f = frac()
        if animate then
            mto(fill,   "sldFill", ti(0.25, "Quint", "Out"), { Size = UDim2.new(f, 0, 1, 0) })
            mto(handle, "sldPos",  ti(0.25, "Quint", "Out"), { Position = UDim2.new(f, 0, 0.5, 0) })
        else
            mkill(fill, "sldFill"); mkill(handle, "sldPos")
            fill.Size = UDim2.new(f, 0, 1, 0)
            handle.Position = UDim2.new(f, 0, 0.5, 0)
        end
        valueTxt.Text = tostring(value) .. suffix
    end

    local api = { frame = row, handle = handle, track = track }

    function api.setValue(newValue, animate, silent)
        local q = quantize(math.clamp(newValue or value, minV, maxV))
        local changed = q ~= value
        value = q
        paint(animate == true)
        if changed and not silent and onValueChange then task.spawn(onValueChange, value) end
        return value
    end

    function api.getValue() return value end

    function api.setRange(newMin, newMax)
        minV, maxV = newMin or minV, newMax or maxV
        api.setValue(value, true, true)
    end

    local function fromX(px)
        local off = screenOffset()
        local ap, as = track.AbsolutePosition + off, track.AbsoluteSize
        local f = math.clamp((px - ap.X) / math.max(as.X, 1), 0, 1)
        api.setValue(minV + f * (maxV - minV), false)
    end

    hit.InputBegan:Connect(function(i)
        if not isPointer(i) then return end
        dragging = true
        mpress(hsc, 0.15)
        fromX(i.Position.X)
    end)

    local moveConn = UIS.InputChanged:Connect(function(i)
        if dragging and isMove(i) then fromX(i.Position.X) end
    end)
    local endConn = UIS.InputEnded:Connect(function(i)
        if dragging and isPointer(i) then
            dragging = false
            mspring(hsc, (not TOUCH and api.hovering) and 1.15 or 1)
        end
    end)
    row.Destroying:Connect(function()
        moveConn:Disconnect()
        endConn:Disconnect()
    end)

    if not TOUCH then
        hit.MouseEnter:Connect(function() api.hovering = true;  mspring(hsc, 1.15) end)
        hit.MouseLeave:Connect(function() api.hovering = false; if not dragging then mspring(hsc, 1) end end)
    end

    paint(false)
    return api
end

-- NEW: ============================================================
-- HELPER: createESPSection
-- Creates a sub-accordion with standard ESP settings:
--   Name toggle, Distance toggle, (optional Health/Progress),
--   Outline Color setting, Fill Color setting
-- Wires all callbacks to the Settings table
-- ================================================================
local function createESPSection(parent, name, defaultColor, hasHealthStatus, hasProgress, settings_ref)
    local acc = createAccordion(parent, name, true, false, 13)

    -- Wire accordion toggle → section enabled state
    if acc.toggle then
        acc.toggle.onToggle = function(on)
            settings_ref.enabled = on
        end
    end

    -- Name
    createToggle(acc.content, "Name", false, function(on)
        settings_ref.name = on
    end, 12)

    -- Distance
    createToggle(acc.content, "Distance", false, function(on)
        settings_ref.distance = on
    end, 12)

    -- Health Status (survivor only)
    if hasHealthStatus then
        createToggle(acc.content, "Health Status", false, function(on)
            settings_ref.healthStatus = on
        end, 12)
    end

    -- Progress (generator only)
    if hasProgress then
        createToggle(acc.content, "Progress", false, function(on)
            settings_ref.progress = on
        end, 12)
    end

    -- Outline Color (enabled by default — outline is the primary visual)
    createColorSetting(acc.content, "Outline Color", defaultColor, true, function(color, enabled)
        settings_ref.outline.color = color
        settings_ref.outline.enabled = enabled
    end, 12)

    -- Fill Color (disabled by default — fill is optional, softer)
    createColorSetting(acc.content, "Fill Color", defaultColor, false, function(color, enabled)
        settings_ref.fill.color = color
        settings_ref.fill.enabled = enabled
    end, 12)

    return acc
end

-- NEW: ============================================================
-- buildVisualTab
-- Creates the complete Visual tab structure inside the content area:
--   ▼ Visuals
--     ▼ Killer Settings    [toggle]
--       Name, Distance, Outline Color, Fill Color
--     ▼ Survivor Settings  [toggle]
--       Name, Distance, Health Status, Outline Color, Fill Color
--     ▼ Pallet Settings    [toggle]
--     ▼ Window Settings    [toggle]
--     ▼ Generator Settings [toggle]
--       Name, Distance, Progress, Outline Color, Fill Color
--     ▼ Hook Settings      [toggle]
--     ▼ Zombie Settings    [toggle]
--   ▼ Render
--     FOV slider, Brightness slider, No-Fog toggle
-- ================================================================
local function buildVisualTab(parent, UI)
    -- Scrolling container for all settings
    local scroll = new("ScrollingFrame", {
        Name = "VisualContent",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = C.ScrClr or Color3.fromRGB(42, 42, 53),
        ScrollBarImageTransparency = 0.15,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ClipsDescendants = true,
        Visible = false,
    }, parent)

    local layout = new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    }, scroll)

    -- Auto-resize canvas when content changes
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)

    -- ====== VISUALS ACCORDION (top-level, no toggle) ======
    local visuals = createAccordion(scroll, "Visuals", false, false, 14)

    -- Killer Settings
    createESPSection(visuals.content, "Killer Settings",
        DEFAULT_COLORS.killer, false, false, Settings.esp.killer)

    -- Survivor Settings (has Health Status)
    createESPSection(visuals.content, "Survivor Settings",
        DEFAULT_COLORS.survivor, true, false, Settings.esp.survivor)

    -- Pallet Settings
    createESPSection(visuals.content, "Pallet Settings",
        DEFAULT_COLORS.pallet, false, false, Settings.esp.pallet)

    -- Window Settings
    createESPSection(visuals.content, "Window Settings",
        DEFAULT_COLORS.window, false, false, Settings.esp.window)

    -- Generator Settings (has Progress)
    createESPSection(visuals.content, "Generator Settings",
        DEFAULT_COLORS.generator, false, true, Settings.esp.generator)

    -- Hook Settings
    createESPSection(visuals.content, "Hook Settings",
        DEFAULT_COLORS.hook, false, false, Settings.esp.hook)

    -- Zombie Settings
    createESPSection(visuals.content, "Zombie Settings",
        DEFAULT_COLORS.zombie, false, false, Settings.esp.zombie)

    -- ====== RENDER ACCORDION (top-level, no toggle) ======
    local render = createAccordion(scroll, "Render", false, false, 14)

    -- FOV slider
    createSlider(render.content, "FOV", 70, 120, 70, "", function(v)
        Settings.render.fov = v
    end)

    -- Brightness slider
    createSlider(render.content, "Brightness", 0, 100, 50, "%", function(v)
        Settings.render.brightness = v
    end)

    -- No-Fog toggle
    createToggle(render.content, "No-Fog", false, function(on)
        Settings.render.noFog = on
    end, 13)

    -- Expand top-level accordions by default
    visuals.setExpanded(true, false)
    render.setExpanded(true, false)

    return {
        container = scroll,
        settings  = Settings,
        visuals  = visuals,
        render   = render,
    }
end

----------------------------------------------------------------------
return {
    createToggle       = createToggle,
    createAccordion    = createAccordion,
    createColorSetting = createColorSetting,
    createSlider       = createSlider,
    buildVisualTab     = buildVisualTab,
    Settings           = Settings,
}

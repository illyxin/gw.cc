--==============================================================
--  PANEL UI  •  single client script  (LocalScript / executor)
--==============================================================
local Players           = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

----------------------------------------------------------------
-- PALETTE
----------------------------------------------------------------
local C = {
	PanelBG      = Color3.fromRGB(13, 13, 18),
	HeaderTop    = Color3.fromRGB(19, 19, 26),
	HeaderBottom = Color3.fromRGB(13, 13, 18),
	NavActive    = Color3.fromRGB(26, 26, 36),
	NavInactive  = Color3.fromRGB(20, 20, 26),
	NavHover     = Color3.fromRGB(24, 24, 32),
	TextPrimary  = Color3.fromRGB(228, 228, 232),
	TextMuted    = Color3.fromRGB(106, 106, 120),
	Accent       = Color3.fromRGB(106, 106, 138),
	AccentDark   = Color3.fromRGB(74, 74, 106),
	Stroke       = Color3.fromRGB(38, 38, 48),
	Line         = Color3.fromRGB(30, 30, 40),
}
local SHADOW_ID = "rbxassetid://6014261993"
local SHADOW_SLICE = Rect.new(49, 49, 450, 450)

----------------------------------------------------------------
-- HELPER
----------------------------------------------------------------
local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do inst[k] = v end
	if parent then inst.Parent = parent end
	return inst
end

--==============================================================
-- 1. SCREENGUI
--==============================================================
local gui = new("ScreenGui", {
	Name = "PanelUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 100,
}, playerGui)

----------------------------------------------------------------
-- RESPONSIVE SIZING  (read viewport AFTER ScreenGui exists)
----------------------------------------------------------------
local cam = workspace.CurrentCamera
while not cam do task.wait() cam = workspace.CurrentCamera end
local viewport = cam.ViewportSize
local screenW, screenH = viewport.X, viewport.Y

local PANEL_W, PANEL_H, NAV_W, NAV_BTN_H, HEADER_H, NAV_TEXT

if screenW < 500 then                        -- likely a phone
	PANEL_W   = math.clamp(math.floor(screenW * 0.86), 280, 460)
	PANEL_H   = math.clamp(math.floor(screenH * 0.60), 280, 400)
	NAV_W     = 50
	NAV_BTN_H = 50
	HEADER_H  = 44
	NAV_TEXT  = 18
else                                         -- PC / desktop
	PANEL_W   = 460
	PANEL_H   = 400
	NAV_W     = 46
	NAV_BTN_H = 46
	HEADER_H  = 42
	NAV_TEXT  = 16
end

local BAR_W = math.clamp(math.floor(screenW * 0.55), 220, 420)

--==============================================================
-- 2. WELCOME SCREEN
--==============================================================
local welcome = new("Frame", {
	Name = "Welcome",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = C.PanelBG,
	BorderSizePixel = 0,
	ZIndex = 50,
}, gui)

local wCenter = new("Frame", {
	Name = "Center",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(BAR_W, 110),
	BackgroundTransparency = 1,
	ZIndex = 51,
}, welcome)

new("TextLabel", {
	Name = "Title",
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "WELCOME",
	TextSize = 22,
	TextColor3 = C.TextPrimary,
	TextTransparency = 0,
	ZIndex = 51,
}, wCenter)

new("TextLabel", {
	Name = "Credit",
	Position = UDim2.new(0, 0, 0, 32),
	Size = UDim2.new(1, 0, 0, 18),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	Text = "made by dev",
	TextSize = 13,
	TextColor3 = C.TextMuted,
	TextTransparency = 0,
	ZIndex = 51,
}, wCenter)

local barBack = new("Frame", {
	Name = "BarBack",
	Position = UDim2.new(0, 0, 0, 66),
	Size = UDim2.new(1, 0, 0, 6),
	BackgroundColor3 = C.NavActive,
	BorderSizePixel = 0,
	ZIndex = 51,
}, wCenter)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, barBack)

local barFill = new("Frame", {
	Name = "BarFill",
	Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = C.AccentDark,
	BorderSizePixel = 0,
	ZIndex = 52,
}, barBack)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, barFill)
new("UIGradient", {
	Color = ColorSequence.new(C.AccentDark, C.Accent),
	Rotation = 0,
}, barFill)

local pct = new("TextLabel", {
	Name = "Percent",
	Position = UDim2.new(0, 0, 0, 78),
	Size = UDim2.new(1, 0, 0, 16),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	Text = "0%",
	TextSize = 12,
	TextColor3 = C.TextMuted,
	TextTransparency = 0,
	ZIndex = 51,
}, wCenter)

--==============================================================
-- 3. MAIN PANEL
--==============================================================
local panel = new("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(PANEL_W, PANEL_H),
	BackgroundColor3 = C.PanelBG,
	BorderSizePixel = 0,
	Visible = false,
	Active = true,
	ZIndex = 2,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 10) }, panel)

new("ImageLabel", {
	Name = "Shadow",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(1, 60, 1, 60),
	BackgroundTransparency = 1,
	Image = SHADOW_ID,
	ImageColor3 = Color3.fromRGB(0, 0, 0),
	ImageTransparency = 0.45,
	ScaleType = Enum.ScaleType.Slice,
	SliceCenter = SHADOW_SLICE,
	ZIndex = 1,
}, panel)

new("UIStroke", {
	Color = C.Stroke,
	Thickness = 1,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	Transparency = 0.2,
}, panel)

--==============================================================
-- 4. HEADER
--==============================================================
local header = new("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, HEADER_H),
	BackgroundColor3 = C.HeaderTop,
	BorderSizePixel = 0,
	ZIndex = 3,
}, panel)
new("UICorner", { CornerRadius = UDim.new(0, 10) }, header)
new("UIGradient", {
	Color = ColorSequence.new(C.HeaderTop, C.HeaderBottom),
	Rotation = 90,
}, header)

new("Frame", { -- foot: squares off the bottom corners of the header
	Name = "Foot",
	Position = UDim2.new(0, 0, 1, -10),
	Size = UDim2.new(1, 0, 0, 10),
	BackgroundColor3 = C.HeaderBottom,
	BorderSizePixel = 0,
	ZIndex = 3,
}, header)

new("Frame", {
	Name = "Line",
	Position = UDim2.new(0, 0, 1, -1),
	Size = UDim2.new(1, 0, 0, 1),
	BackgroundColor3 = C.Line,
	BorderSizePixel = 0,
	ZIndex = 4,
}, header)

new("TextLabel", {
	Name = "Brand",
	Position = UDim2.new(0, 14, 0, 0),
	Size = UDim2.new(0.5, 0, 1, 0),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "PANEL",
	TextSize = 14,
	TextColor3 = C.TextPrimary,
	TextTransparency = 0,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 5,
}, header)

new("TextLabel", {
	Name = "Hint",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -48, 0, 0),
	Size = UDim2.new(0.5, -60, 1, 0),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	Text = "RightControl to toggle",
	TextSize = 11,
	TextColor3 = C.TextMuted,
	TextTransparency = 0,
	TextXAlignment = Enum.TextXAlignment.Right,
	ZIndex = 5,
}, header)

--==============================================================
-- 5. BODY
--==============================================================
local body = new("Frame", {
	Name = "Body",
	Position = UDim2.new(0, 0, 0, HEADER_H),
	Size = UDim2.new(1, 0, 1, -HEADER_H),
	BackgroundColor3 = C.PanelBG,
	BorderSizePixel = 0,
	ZIndex = 3,
}, panel)

--==============================================================
-- 6. NAV COLUMN
--==============================================================
local nav = new("Frame", {
	Name = "Nav",
	Size = UDim2.new(0, NAV_W, 1, 0),
	BackgroundColor3 = C.NavInactive,
	BorderSizePixel = 0,
	ZIndex = 4,
}, body)

new("Frame", {
	Name = "TopFill",
	Size = UDim2.new(1, 0, 0, 4),
	BackgroundColor3 = C.NavInactive,
	BorderSizePixel = 0,
	ZIndex = 4,
}, nav)

local TABS = { "M", "V", "C" }
local navButtons, navAccents = {}, {}

for i, id in ipairs(TABS) do
	local btn = new("TextButton", {
		Name = "Nav_" .. id,
		Position = UDim2.new(0, 0, 0, 4 + (i - 1) * NAV_BTN_H),
		Size = UDim2.new(1, 0, 0, NAV_BTN_H),
		BackgroundColor3 = C.NavInactive,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.GothamBold,
		Text = id,
		TextSize = NAV_TEXT,
		TextColor3 = C.TextMuted,
		TextTransparency = 0,
		ZIndex = 5,
	}, nav)

	local accent = new("Frame", {
		Name = "Accent",
		Size = UDim2.new(0, 3, 1, -14),
		Position = UDim2.new(0, 0, 0, 7),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 6,
	}, btn)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, accent)

	navButtons[id] = btn
	navAccents[id] = accent
end

--==============================================================
-- 7. CONTENT + PAGES
--==============================================================
local content = new("ScrollingFrame", {
	Name = "Content",
	Position = UDim2.new(0, NAV_W, 0, 0),
	Size = UDim2.new(1, -NAV_W, 1, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = C.Accent,
	ScrollBarImageTransparency = 0.4,
	ZIndex = 4,
}, body)

local pages = {}
local PAGE_TEXT = {
	Intro = "Ready.",
	M     = "Main",
	V     = "Visuals",
	C     = "Config",
}

for _, id in ipairs({ "Intro", "M", "V", "C" }) do
	local page = new("Frame", {
		Name = "Page_" .. id,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,                      -- ALL pages start hidden
		ZIndex = 5,
	}, content)

	new("TextLabel", {
		Name = "Label",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -24, 0, 26),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = PAGE_TEXT[id],
		TextSize = 15,
		TextColor3 = C.TextPrimary,
		TextTransparency = 0,                 -- never 1
		ZIndex = 6,
	}, page)

	pages[id] = page
end

--==============================================================
-- 8. MINIMIZE BUTTON
--==============================================================
local minBtn = new("TextButton", {
	Name = "Minimize",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -12, 0.5, 0),
	Size = UDim2.fromOffset(26, 26),
	BackgroundColor3 = C.NavActive,
	BorderSizePixel = 0,
	AutoButtonColor = false,
	Text = "",
	ZIndex = 6,
}, header)
new("UICorner", { CornerRadius = UDim.new(0, 6) }, minBtn)
new("UIGradient", {
	Color = ColorSequence.new(Color3.fromRGB(26, 26, 36), Color3.fromRGB(20, 20, 26)),
	Rotation = 90,
}, minBtn)
new("UIStroke", { Color = C.Stroke, Thickness = 1, Transparency = 0.3 }, minBtn)

local iconTop = new("Frame", {
	Name = "IconTop",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.fromOffset(12, 2),
	BackgroundColor3 = C.TextPrimary,
	BorderSizePixel = 0,
	ZIndex = 7,
}, minBtn)
local iconBottom = new("Frame", {
	Name = "IconBottom",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.62),
	Size = UDim2.fromOffset(12, 2),
	BackgroundColor3 = C.TextMuted,
	BorderSizePixel = 0,
	ZIndex = 7,
}, minBtn)

--==============================================================
-- 9. EVENTS
--==============================================================
local activeTab = "M"
local firstLoad = true

local function styleNav(id, active)
	local btn, accent = navButtons[id], navAccents[id]
	if not btn then return end
	btn.BackgroundColor3 = active and C.NavActive or C.NavInactive
	btn.TextColor3       = active and C.TextPrimary or C.TextMuted
	accent.BackgroundTransparency = active and 0 or 1
end

local function selectTab(id)
	if firstLoad then
		firstLoad = false
		pages.Intro.Visible = false
		pages[id].Visible = true
		activeTab = id
		for _, t in ipairs(TABS) do styleNav(t, t == id) end
		return
	end

	if id == activeTab then return end

	pages[activeTab].Visible = false
	pages[id].Visible = true
	styleNav(activeTab, false)
	styleNav(id, true)
	activeTab = id
end

for _, id in ipairs(TABS) do
	local btn = navButtons[id]
	btn.MouseButton1Click:Connect(function() selectTab(id) end)
	btn.TouchTap:Connect(function() selectTab(id) end)
	btn.MouseEnter:Connect(function()
		if id ~= activeTab then btn.BackgroundColor3 = C.NavHover end
	end)
	btn.MouseLeave:Connect(function()
		if id ~= activeTab then btn.BackgroundColor3 = C.NavInactive end
	end)
end

-- dragging (mouse + touch)
local dragging, dragStart, startPos = false, nil, nil

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		dragging  = true
		dragStart = input.Position
		startPos  = panel.Position
	end
end)

header.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement
	or input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - dragStart
		panel.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)

-- keybind (always connected, every platform)
local booted = false
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.RightControl and booted then
		panel.Visible = not panel.Visible
	end
end)

-- minimize
local minimized = false
local function toggleMinimize()
	minimized = not minimized
	body.Visible = not minimized
	iconBottom.BackgroundTransparency = minimized and 1 or 0
	panel:TweenSize(
		minimized and UDim2.fromOffset(PANEL_W, HEADER_H)
		           or UDim2.fromOffset(PANEL_W, PANEL_H),
		Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.18, true
	)
end
minBtn.MouseButton1Click:Connect(toggleMinimize)
minBtn.TouchTap:Connect(toggleMinimize)

--==============================================================
-- 10. STYLE "M" AS ACTIVE (before boot)
--==============================================================
styleNav("M", true)
styleNav("V", false)
styleNav("C", false)

--==============================================================
-- 11. BOOT SEQUENCE
--==============================================================
local function setProgress(target, duration)
	local from = barFill.Size.X.Scale
	local t = 0
	while t < duration do
		t += task.wait()
		local a = math.clamp(t / duration, 0, 1)
		local v = from + (target - from) * a
		barFill.Size = UDim2.new(v, 0, 1, 0)
		pct.Text = math.floor(v * 100 + 0.5) .. "%"
	end
	barFill.Size = UDim2.new(target, 0, 1, 0)
	pct.Text = math.floor(target * 100 + 0.5) .. "%"
end

task.spawn(function()
	-- STEP 1: welcome up, panel hidden
	welcome.Visible = true
	panel.Visible   = false
	task.wait(0.35)

	-- STEP 2-5: progress
	setProgress(0.25, 0.45)
	setProgress(0.55, 0.50)
	setProgress(0.82, 0.40)
	setProgress(1.00, 0.35)
	task.wait(0.25)

	-- STEP 6: Intro page visible, then reveal panel
	pages.Intro.Visible = true
	panel.Visible = true
	booted = true

	-- fade the welcome layer out
	TweenService:Create(welcome, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
	for _, d in ipairs(wCenter:GetDescendants()) do
		if d:IsA("TextLabel") then
			TweenService:Create(d, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
		elseif d:IsA("Frame") then
			TweenService:Create(d, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
		end
	end
	task.wait(0.35)
	welcome:Destroy()
end)

Create a custom Roblox Luau UI library — an in-game menu interface framework. This is a pure UI implementation with no game logic or functional features. The script should create a visually polished, professionally animated interface that works cross-platform (PC and Mobile). Below is the complete specification.

## TECHNICAL SETUP
- Language: Luau (Roblox Lua)
- ScreenGui properties: ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 9999
- All UI elements created programmatically via Instance.new()
- All animations via TweenService
- Input handling via UserInputService and ContextActionService
- Platform detection: UserInputService.TouchEnabled (mobile), UserInputService.MouseEnabled (PC)

## FONT
- JetBrains Mono throughout the entire interface
- Load via FontFace.new() with the appropriate asset ID, or set Font property on all TextLabels/TextButtons
- Font sizes:
  - Branding/title: 18-20px
  - Body text: 14-15px
  - Side navigation buttons: 16-18px
  - Subtitle/credits: 12-13px

## COLOR SCHEME
- Panel background: #0D0D12 (deep near-black charcoal) — SOLID, NOT transparent, NOT semi-transparent
- Header background: slightly differentiated, #111118 or subtle gradient from #13131A to #0D0D12
- Side navigation active button: #1A1A24 with accent border (left edge, 2-3px, color #4A4A5E or similar muted accent)
- Side navigation inactive button: transparent or #14141A
- Side navigation hover (PC): #16161E
- Text primary: #E4E4E8 (off-white)
- Text secondary/muted: #6A6A78 (gray)
- Accent: #5A5A7A (muted, not neon)
- Loading bar background: #181820
- Loading bar fill: gradient from #4A4A6A to #6A6A8A
- All colors should feel premium, muted, sophisticated — NOT bright, NOT neon, NOT flashy

## DESIGN REFERENCE
The interface aesthetic is inspired by a premium in-game utility panel with the following visual characteristics:
- A solid, opaque dark panel positioned in the game viewport (the game scene is visible AROUND the panel, NOT through it)
- Clean, minimal layout with sharp or very slightly rounded corners (CornerRadius 4-6px)
- Top of panel: branding text (single short label, monospace font)
- Left column below branding: three small vertical navigation buttons, each containing a single uppercase letter
- Right of navigation: main content area
- Overall feel: modern, sleek, professional, understated
- Subtle drop shadow behind the panel for depth (UIStroke or Image with shadow gradient)

## COMPONENT 1: WELCOME / LOADING SCREEN

This is a full-screen overlay shown when the script first runs. It is NOT draggable.

### Layout (all elements vertically centered on screen):
1. **"Welcome to gw.cc"** — large text, JetBrains Mono, color #E4E4E8, centered horizontally
2. **"by illyxin"** — smaller text below the title, color #6A6A78, centered, positioned ~8-10px below title
3. **Loading progress bar** — positioned ~20-25px below "by illyxin":
   - Container: rounded rectangle, ~320px wide, ~6-8px tall, background #181820, CornerRadius 4px
   - Fill: inner rectangle starting at width 0, height matching container, background gradient (#4A4A6A → #6A6A8A), CornerRadius 4px
   - The fill animates from 0% to 100% width over approximately 5-6 seconds using TweenService
   - Optional: small percentage text below the bar (e.g., "Loading... 42%"), JetBrains Mono 11px, color #6A6A78

### Transition to Main Menu:
- After the loading bar reaches 100%, wait ~0.3 seconds
- Fade out the entire welcome screen (TweenService, transparency 0 → 1, ~0.6-0.8 seconds, EasingStyle.Quint, EasingDirection.In)
- Simultaneously or immediately after, fade in the Main Menu (transparency 1 → 0, same duration)
- Destroy or set Visible = false on the welcome screen after transition completes

## COMPONENT 2: MAIN MENU

The main menu is the primary interface panel. It IS draggable.

### Panel Properties:
- Size: approximately 460px wide × 400px tall on PC; scale proportionally for mobile (use scale/offset mix or detect screen size)
- Position: initially center-right of screen
- Background: #0D0D12, solid (Transparency = 0), CornerRadius 6px
- UIStroke or shadow for depth: subtle dark drop shadow

### Panel Structure (top to bottom):

#### A) Header / Top Bar
- Height: ~40-45px
- Background: #111118 or subtle gradient
- Contains:
  1. **"gw.cc"** branding text — JetBrains Mono, 18px, color #E4E4E8, positioned left-aligned with ~12px left padding
  2. **Hint text**: "RightShift to toggle" — JetBrains Mono, 11px, color #4A4A55, positioned right-aligned or bottom-right of header. This is a small, subtle hint for PC users so they know the keybind.
- The header is the DRAG HANDLE — clicking and holding (mouse) or touching and holding (finger) on the header allows the user to drag the entire panel to any position on screen
- Dragging implementation: track InputBegan on header frame, update panel Position on InputChanged (mouse movement or touch movement), release on InputEnded

#### B) Body (below header)
Split into two columns:

**Left Column — Side Navigation:**
- Width: ~44-50px
- Background: same as panel or slightly different (#0F0F14)
- Three buttons stacked vertically, filling the column:
  1. **"M"** — represents Main
  2. **"V"** — represents Visual
  3. **"C"** — represents Config/Settings
- Each button: square or slightly rounded square, fills column width, ~44-50px tall
- Font: JetBrains Mono, 16px, uppercase
- Active state: background #1A1A24, text color #E4E4E8, left accent border (2-3px wide, #5A5A7A or accent color)
- Inactive state: background transparent or #14141A, text color #6A6A78
- Hover state (PC only): background #16161E, smooth transition (~0.2s)
- Click transition: smooth TweenService animation switching active/inactive styling on both the clicked button and the previously active button (~0.25s, EasingStyle.Quint)

**Right Column — Center Content Area:**
- Fills remaining width of the panel (panel width minus side nav width)
- Background: #0D0D12 (same as panel)
- Acts as a scrollable container (ScrollingFrame) for future content — set CanvasSize and ScrollBarThickness appropriately. For now, content is minimal so scrolling is not active, but the structure should support adding scrollable content later.
- Rounded right corners matching panel (6px)

### Center Content — Initial State:
When the main menu first appears (after welcome screen transition):
1. **Typing animation**: Text appears character by character, simulating live typing
   - Text content: "Welcome, " .. LocalPlayer.DisplayName .. "!" (or .Name if DisplayName is empty)
   - IMPORTANT: No question marks, no unexpected characters. Pure clean text typing.
   - Font: JetBrains Mono, 15px, color #E4E4E8
   - Position: centered in the content area (both horizontally and vertically)
   - Speed: approximately 50-80ms between each character (use task.wait())
   - Implementation: iterate through the string, appending one character at a time to a TextLabel's Text property

2. **After typing completes**: the text remains visible until the user clicks a side navigation button

### Center Content — Tab Selection:
When a side navigation button is clicked:
- The current center content fades out (TweenService, ~0.2s, transparency → 1)
- New content fades in (TweenService, ~0.2s, transparency 1 → 0)
- Content shown per tab (PLACEHOLDER for now — actual functions will be added in future versions):
  - **M (Main)**: centered text "Main", JetBrains Mono 15px, color #E4E4E8
  - **V (Visual)**: centered text "Visual", JetBrains Mono 15px, color #E4E4E8
  - **C (Config/Settings)**: centered text "Config/Settings", JetBrains Mono 15px, color #E4E4E8
- Each tab switch should use the same fade transition for consistency
- The typing animation only plays once (on initial load). Subsequent tab switches use the fade transition only.

## COMPONENT 3: MINIMIZE / TOGGLE BUTTON (MOBILE ONLY)

A small floating button visible on mobile devices when the main menu is hidden.

### Visibility Logic:
- Show this button ONLY on mobile (UserInputService.TouchEnabled == true and UserInputService.MouseEnabled == false)
- On PC, this button is NOT created — PC users toggle the menu via RightShift keybind
- The button appears when the main menu is hidden/minimized
- The button disappears when the main menu is shown

### Design — Premium, Non-Basic:
- Shape: small rounded rectangle (NOT a circle), approximately 40×40px, CornerRadius 8-10px
- Background: subtle gradient (e.g., #1A1A24 to #14141A), solid (not transparent)
- Subtle drop shadow for depth
- Inside: a minimal, elegant icon — NOT a letter. Suggestions:
  - Two horizontal lines (like a minimized-window icon), thin, 2px tall, #6A6A78, centered
  - Or a stylized chevron pointing upward
  - Or a minimal geometric mark (e.g., small square outline)
- On touch: subtle scale-up animation (1.0 → 1.05 → 1.0, ~0.2s) and background color shift to #1E1E28
- Position: bottom-right corner of screen, with ~20px margin from edges
- Tapping it shows the main menu (with fade/slide-in animation) and hides the button
- When menu is hidden again (via the same button or another mechanism), the button reappears

### Mobile Menu Toggle Flow:
1. Menu visible + button hidden
2. User taps the floating button → menu slides/fades out (~0.3s), button stays visible
3. User taps the button again → menu slides/fades back in (~0.3s)

Actually — alternative: the floating button should toggle the menu. When menu is visible, tapping the button hides it. When menu is hidden, tapping the button shows it. The button is ALWAYS visible on mobile.

## COMPONENT 4: PC KEYBIND — RIGHT SHIFT

### Behavior:
- Pressing RightShift toggles the main menu visibility (show/hide)
- When hidden: the panel fades/slides out (TweenService, ~0.3s, EasingStyle.Quint)
- When shown: the panel fades/slides back in (~0.3s)
- Implementation: UserInputService.InputBegan, check KeyCode.RightShift
- The hint text "RightShift to toggle" in the header ensures PC users discover this

## ANIMATION SPECIFICATIONS — COMPLETE LIST

All animations must use TweenService with appropriate easing. NO instant pop-ins, NO instant disappearances. Everything must feel smooth and premium.

| Animation | Duration | EasingStyle | EasingDirection |
|---|---|---|---|
| Loading bar fill (0→100%) | ~5-6 seconds | Linear | In |
| Welcome screen fade out | ~0.6-0.8s | Quint | In |
| Main menu fade in | ~0.6-0.8s | Quint | Out |
| Typing animation (per character) | 50-80ms per char | N/A (task.wait) | N/A |
| Tab content fade out | ~0.2s | Quint | In |
| Tab content fade in | ~0.2s | Quint | Out |
| Side button active/inactive transition | ~0.25s | Quint | Out |
| Side button hover (PC) | ~0.2s | Quad | Out |
| Panel show (RightShift / mobile button) | ~0.3s | Quint | Out |
| Panel hide (RightShift / mobile button) | ~0.3s | Quint | In |
| Minimize button touch scale | ~0.2s | Quad | Out |
| Minimize button color shift | ~0.2s | Quad | Out |

## CROSS-PLATFORM REQUIREMENTS

1. **Platform Detection**: Check UserInputService.TouchEnabled and UserInputService.MouseEnabled at script start
2. **Mobile Adjustments**:
   - Scale panel down if screen is small (use viewport size to calculate appropriate panel size)
   - Ensure side navigation buttons are large enough for touch (min 44×44px)
   - Show the floating minimize/toggle button
   - Larger touch targets generally
3. **PC Adjustments**:
   - Standard panel size
   - Hide the floating minimize button
   - Enable RightShift keybind
   - Enable hover effects on side buttons
4. **Dragging Support**:
   - PC: mouse-based drag (InputBegan with UserInputType.MouseButton1, InputChanged with MouseMovement)
   - Mobile: touch-based drag (InputBegan with Touch, InputChanged with Touch)
   - Handle both in the same drag logic by checking input type

## STRUCTURAL NOTES FOR FUTURE EXPANSION

The center content area (right column) should be designed as a flexible container that will later hold:
- Accordion/dropdown sections (expandable headers that reveal lists of items)
- Toggle switches (function name on left, switch on right)
- Color square indicators (small colored squares that open a full HSV color picker when clicked)
- Sliders (for value adjustment)
- Sub-settings panels (expandable under each item)

For now, none of these components need to be implemented. But the content area should use a ScrollingFrame structure so that when these are added later, they can be parented to it and scroll naturally. Set ScrollBarThickness to ~4px, scrollbar color #2A2A35, and scrollbar background transparent.

## WHAT NOT TO INCLUDE IN THIS VERSION
- No toggle switches
- No color picker component
- No slider component
- No accordion/dropdown component
- No settings save/load (no writefile/readfile)
- No game manipulation logic of any kind
- No RemoteEvent firing
- No Highlight objects
- No workspace scanning
- No character detection

This version is PURELY the UI shell: welcome screen, main menu panel, side navigation, center content area with placeholder text, all animations, cross-platform support, and platform detection. The functional UI components will be specified in subsequent iterations.

## OUTPUT FORMAT
Provide the complete Luau script as a single file. The script should be self-contained — it creates all GUI elements, sets up all animations, handles all input, and manages the welcome-to-menu transition. No external dependencies. No module imports beyond standard Roblox services (TweenService, UserInputService, Players, RunService, etc.).

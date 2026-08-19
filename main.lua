--[[
    gw.cc | Loader v2
    Run this in Delta. Downloads all modules from GitHub.
--]]

local BASE = "https://raw.githubusercontent.com/illyxin/gw.cc/main"

local function loadModule(path, ...)
    local url = BASE .. "/" .. path
    local ok, src = pcall(function() return game:HttpGet(url) end)
    if not ok or not src then
        warn("[gw.cc] Failed to download: " .. path)
        return nil
    end
    local fn, err = loadstring(src)
    if not fn then
        warn("[gw.cc] Parse error: " .. path .. " — " .. tostring(err))
        return nil
    end
    return fn(...)
end

-- Step 1: Load UI shell
local UI = loadModule("gwcc/ui_shell.lua")
if not UI then
    warn("[gw.cc] UI shell failed to load!")
    return
end

-- Make UI accessible globally for modules that use getgenv().UI
pcall(function() getgenv().UI = UI end)

-- Step 2: Load settings components (pass UI table as argument)
local Comp = loadModule("gwcc/settings_components.lua", UI)
if not Comp then
    warn("[gw.cc] Components failed to load!")
    return
end

-- Step 3: Build Visual tab content inside the panel's content area
local visual = Comp.buildVisualTab(UI.content, UI)
visual.container.ZIndex = 3  -- on top of text labels (ZIndex 2)

-- Step 4: Show Visual content when "V" tab is clicked, hide for others
UI.navBtns["V"].Activated:Connect(function()
    visual.container.Visible = true
end)

UI.navBtns["M"].Activated:Connect(function()
    visual.container.Visible = false
end)

UI.navBtns["C"].Activated:Connect(function()
    visual.container.Visible = false
end)

print("[gw.cc] Loaded! UI shell + Visual tab ready.")

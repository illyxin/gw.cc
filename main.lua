--[[
    gw.cc | Loader
    Run this in Delta. It downloads and loads all modules from GitHub.
--]]

local BASE = "https://raw.githubusercontent.com/illyxin/gw.cc/main"

local function loadModule(path)
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
    return fn()
end

-- Load UI shell
local UI = loadModule("gwcc/ui_shell.lua")
if not UI then
    warn("[gw.cc] UI shell failed to load!")
    return
end

-- Future modules (uncomment when ready):
-- local Toggle   = loadModule("gwcc/toggle.lua")
-- local Accordion = loadModule("gwcc/accordion.lua")
-- local Slider   = loadModule("gwcc/slider.lua")
-- local ColorPicker = loadModule("gwcc/colorpicker.lua")

print("[gw.cc] Loaded successfully!")

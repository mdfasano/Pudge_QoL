-- Slash commands, each with its own on/off checkbox on the Slash Commands subpanel.
local addonName, ns = ...
ns.RegisterGroup("slashcommands", "Slash Commands")
ns.RegisterFeature("slashCdm", "/cdm - open Cooldown Manager settings", "slashcommands")
ns.RegisterFeature("slashKb", "/kb - open the quick keybind window", "slashcommands")

local PREFIX = "|cffff8000Pudge QoL:|r "

-- Checks the toggle, combat lockdown, and that the frame exists before opening it
local function CanOpen(featureKey, frame, name)
    if not ns.IsEnabled(featureKey) then
        print(PREFIX .. "that command is turned off in the Pudge QoL options.")
        return false
    end
    if InCombatLockdown() then
        print(PREFIX .. "can't open " .. name .. " in combat.")
        return false
    end
    if not frame then
        print(PREFIX .. name .. " isn't available in this client.")
        return false
    end
    return true
end

-- /cdm, /cooldownmanagersettings
SLASH_COOLDOWNMANAGERSETTINGS1 = "/cooldownmanagersettings"
SLASH_COOLDOWNMANAGERSETTINGS2 = "/cdm"
SlashCmdList["COOLDOWNMANAGERSETTINGS"] = function()
    if CanOpen("slashCdm", _G.CooldownViewerSettings, "Cooldown Manager settings") then
        ShowUIPanel(CooldownViewerSettings)
    end
end

-- /kb
SLASH_KEYBINDINGSHORTCUT1 = "/kb"
SlashCmdList["KEYBINDINGSHORTCUT"] = function()
    if CanOpen("slashKb", _G.QuickKeybindFrame, "the keybind window") then
        ShowUIPanel(QuickKeybindFrame)
    end
end

-- /esctest: debug tool, print the Settings categories (not shown in the options panel)
SLASH_TESTSLASHCOMMANDS1 = "/esctest"
SlashCmdList["TESTSLASHCOMMANDS"] = function()
    if not SettingsPanel or not SettingsPanel.GetAllCategories then
        print(PREFIX .. "SettingsPanel isn't available in this client.")
        return
    end
    print("|cff00ff00--- Available Settings Categories ---|r")
    for _, cat in ipairs(SettingsPanel:GetAllCategories()) do
        local id = cat.GetID and cat:GetID() or "?"
        print(string.format("Name: %s | ID: %s", tostring(cat.name), tostring(id)))
    end
end

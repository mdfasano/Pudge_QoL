-- Shared namespace, saved settings, and the options panels.
-- Features register with ns.RegisterFeature(key, label, group):
--   group = nil     -> shown on the main Pudge QoL panel
--   group = "name"  -> shown on that section's subpanel (see ns.RegisterGroup)
local addonName, ns = ...

ns.features = {}    -- { key = ..., label = ..., group = ... }
ns.groups = {}      -- key -> { key, name, panel, category }
ns.groupOrder = {}  -- group keys in registration order
ns.db = {}          -- replaced with Pudge_QoLDB once saved variables load

function ns.RegisterFeature(key, label, group)
    table.insert(ns.features, { key = key, label = label, group = group })
end

function ns.IsEnabled(key)
    return ns.db[key] ~= false   -- features default to on
end

-- Load saved settings
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, name)
    if name ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")
    Pudge_QoLDB = Pudge_QoLDB or {}
    ns.db = Pudge_QoLDB
end)

-- Main panel (registered in the Blizzard "AddOns" category)
local rootPanel = CreateFrame("Frame", addonName .. "Panel", UIParent)
rootPanel.name = "Pudge QoL"

local rootTitle = rootPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
rootTitle:SetPoint("TOPLEFT", 16, -16)
rootTitle:SetText("Pudge QoL")

local rootBlurb = rootPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
rootBlurb:SetPoint("TOPLEFT", rootTitle, "BOTTOMLEFT", 0, -8)
rootBlurb:SetText("This is a lightweight QoL addon.")

local rootCategory = Settings.RegisterCanvasLayoutCategory(rootPanel, rootPanel.name)
Settings.RegisterAddOnCategory(rootCategory)

-- Creates a section under the main panel, e.g. ns.RegisterGroup("questing", "Questing")
function ns.RegisterGroup(key, name)
    local panel = CreateFrame("Frame", addonName .. key .. "Panel", UIParent)
    panel.name = name

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(name)

    local category = Settings.RegisterCanvasLayoutSubcategory(rootCategory, panel, name)
    ns.groups[key] = { key = key, name = name, panel = panel, category = category }
    table.insert(ns.groupOrder, key)
end

-- Adds a checkbox for each feature that belongs to this group (nil = main panel)
local function BuildCheckboxes(panel, group)
    local y = -80
    for _, feature in ipairs(ns.features) do
        if feature.group == group then
            local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
            cb:SetPoint("TOPLEFT", 16, y)
            local label = cb.Text or cb.text
            if label then label:SetText(feature.label) end
            cb:SetChecked(ns.IsEnabled(feature.key))
            cb:SetScript("OnClick", function(button)
                ns.db[feature.key] = button:GetChecked() and true or false
            end)
            y = y - 30
        end
    end
end

-- Checkboxes are built after every file has registered its features and groups
local builder = CreateFrame("Frame")
builder:RegisterEvent("PLAYER_LOGIN")
builder:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    BuildCheckboxes(rootPanel, nil)
    for _, key in ipairs(ns.groupOrder) do
        BuildCheckboxes(ns.groups[key].panel, key)
    end
end)

-- /pqol            -> main panel
-- /pqol questing   -> Questing section
SLASH_PUDGEQOL1 = "/pqol"
SlashCmdList["PUDGEQOL"] = function(msg)
    if not (Settings and Settings.OpenToCategory) then
        print("|cffff8000Pudge QoL:|r the options panel isn't available in this client.")
        return
    end
    local key = (msg or ""):match("^%s*(.-)%s*$"):lower()
    if key == "" then
        Settings.OpenToCategory(rootCategory:GetID())
    elseif ns.groups[key] then
        Settings.OpenToCategory(ns.groups[key].category:GetID())
    else
        print("|cffff8000Pudge QoL:|r unknown section '" .. key .. "'. Try /pqol or /pqol questing.")
    end
end

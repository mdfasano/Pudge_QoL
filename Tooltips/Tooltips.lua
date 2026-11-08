-- Game tooltips follow the mouse cursor instead of sitting in a fixed corner.
-- Options: out-of-combat only, and how long the tooltip lingers after the mouse leaves.
local addonName, ns = ...
ns.RegisterGroup("tooltips", "Tooltips")
ns.RegisterFeature("tooltipCursor", "Tooltips follow the cursor", "tooltips")
ns.RegisterFeature("tooltipOutOfCombatOnly", "    Only follow the cursor out of combat", "tooltips")

local OFFSET_X, OFFSET_Y = 16, -16   -- gap between cursor and tooltip

-- Whether the cursor-follow should run right now
local function FollowAllowed()
    if not ns.IsEnabled("tooltipCursor") then return false end
    if ns.IsEnabled("tooltipOutOfCombatOnly") and UnitAffectingCombat("player") then return false end
    return true
end

GameTooltip:HookScript("OnUpdate", function(self)
    if not FollowAllowed() then return end
    if not self:IsShown() then return end
    if self.pudgeLingering then return end   -- hold position while lingering

    local scale = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()
    x, y = x / scale, y / scale

    self:ClearAllPoints()
    -- Open to the left of the cursor if the tooltip would run off the right edge
    if x + self:GetWidth() + OFFSET_X > UIParent:GetWidth() then
        self:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", x - OFFSET_X, y - OFFSET_Y)
    else
        self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x + OFFSET_X, y + OFFSET_Y)
    end
end)

-- Linger: when the tooltip is asked to hide, keep it up for the chosen number of seconds.
-- It stays hidden early if the mouse comes back to the same item, or a different tooltip takes over.
local originalHide = GameTooltip.Hide
GameTooltip.Hide = function(self, ...)
    local delay = (ns.db and ns.db.tooltipLinger) or 0
    local owner = self:GetOwner()

    if delay <= 0 or not owner then
        self.pudgeLingering = false
        return originalHide(self, ...)
    end
    if self.pudgeLingering then return end   -- already waiting to hide

    self.pudgeLingering = true
    C_Timer.After(delay, function()
        if not self.pudgeLingering then return end
        self.pudgeLingering = false
        -- Only hide if this is still the same owner and the mouse is off it
        if self:GetOwner() == owner and not owner:IsMouseOver() then
            originalHide(self)
        end
    end)
end

-- A fresh show cancels any pending linger
GameTooltip:HookScript("OnShow", function(self)
    self.pudgeLingering = false
end)

-- Controls on the Tooltips subpanel (the checkboxes come from Core.lua)
local controls = CreateFrame("Frame")
controls:RegisterEvent("PLAYER_LOGIN")
controls:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local panel = ns.groups["tooltips"] and ns.groups["tooltips"].panel
    if not panel then return end

    local slider = CreateFrame("Slider", "PudgeQoLLingerSlider", panel, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 16, -170)
    slider:SetWidth(220)
    slider:SetMinMaxValues(0, 5)
    slider:SetValueStep(0.5)
    slider:SetObeyStepOnDrag(true)

    local function Label(v)
        return string.format("Linger after mouse leaves: %.1f s", v)
    end

    slider:SetValue(ns.db.tooltipLinger or 0)
    if slider.Text then slider.Text:SetText(Label(ns.db.tooltipLinger or 0)) end
    if slider.Low then slider.Low:SetText("0") end
    if slider.High then slider.High:SetText("5") end
    slider:SetScript("OnValueChanged", function(_, v)
        ns.db.tooltipLinger = v
        if slider.Text then slider.Text:SetText(Label(v)) end
    end)
end)

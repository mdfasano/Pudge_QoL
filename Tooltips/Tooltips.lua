-- Game tooltips follow the mouse cursor instead of sitting in a fixed corner.
-- Option: only follow the cursor out of combat.
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

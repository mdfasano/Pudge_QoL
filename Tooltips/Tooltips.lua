-- Game tooltips follow the mouse cursor instead of sitting in a fixed corner.
local addonName, ns = ...
ns.RegisterGroup("tooltips", "Tooltips")
ns.RegisterFeature("tooltipCursor", "Tooltips follow the cursor", "tooltips")

local OFFSET_X, OFFSET_Y = 16, -16   -- gap between cursor and tooltip

GameTooltip:HookScript("OnUpdate", function(self)
    if not ns.IsEnabled("tooltipCursor") then return end
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

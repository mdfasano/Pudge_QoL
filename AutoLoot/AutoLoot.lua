-- Auto loot: takes every item when the loot window opens.
-- Hold the auto-loot modifier key (default Shift) to loot manually.
local addonName, ns = ...
ns.RegisterGroup("autoloot", "Auto Loot")
ns.RegisterFeature("autoLoot", "Auto loot (hold Shift to loot manually)", "autoloot")

local frame = CreateFrame("Frame")
frame:RegisterEvent("LOOT_READY")
frame:SetScript("OnEvent", function()
    if not ns.IsEnabled("autoLoot") then return end
    if IsModifiedClick("AUTOLOOTTOGGLE") then return end
    for slot = GetNumLootItems(), 1, -1 do   -- reverse so slot indexes don't shift
        LootSlot(slot)
    end
end)

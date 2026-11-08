-- Quest auto-accept: accepts quests when an NPC offers them.
-- Hold Shift at the NPC to accept manually.
local addonName, ns = ...
ns.RegisterFeature("questAccept", "Quest auto-accept (hold Shift to accept manually)", "questing")

local frame = CreateFrame("Frame", "questing")
frame:RegisterEvent("QUEST_DETAIL", "questing")
frame:RegisterEvent("QUEST_ACCEPT_CONFIRM", "questing")

frame:SetScript("OnEvent", function(_, event)
    if not ns.IsEnabled("questAccept") then return end
    if IsShiftKeyDown() then return end

    if event == "QUEST_DETAIL" then
        AcceptQuest()
    elseif event == "QUEST_ACCEPT_CONFIRM" then
        -- Shown for escort-style quests that ask for confirmation
        if ConfirmAcceptQuest then ConfirmAcceptQuest() end
    end
end)

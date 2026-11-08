-- Quest auto turn-in: completes quests with the NPC automatically.
-- Quests with several reward choices are left for you to pick.
-- Hold Shift at the NPC to turn in manually.
local addonName, ns = ...
ns.RegisterFeature("questTurnIn", "Quest auto turn-in (hold Shift to do it manually)", "questing")

local frame = CreateFrame("Frame", "questing")
frame:RegisterEvent("QUEST_PROGRESS", "questing")
frame:RegisterEvent("QUEST_COMPLETE", "questing")

frame:SetScript("OnEvent", function(_, event)
    if not ns.IsEnabled("questTurnIn") then return end
    if IsShiftKeyDown() then return end

    if event == "QUEST_PROGRESS" then
        -- Only proceed if the quest's objectives are actually done
        if IsQuestCompletable() then
            CompleteQuest()
        end

    elseif event == "QUEST_COMPLETE" then
        local choices = GetNumQuestChoices()
        if choices == 0 then
            GetQuestReward(nil)          -- no item choice offered
        elseif choices == 1 then
            GetQuestReward(1)            -- only one option, take it
        end
        -- more than one choice: leave it for the player to pick
    end
end)

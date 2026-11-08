-- NPCs with several quests: works through the quest list one quest at a time.
-- Finished quests are turned in first, then new quests are accepted.
-- Each step uses the same turn-in and accept handlers as the single-quest case.
-- Hold Shift at the NPC to skip.
local addonName, ns = ...
ns.RegisterFeature("questGreeting", "NPCs with several quests: handle each one (hold Shift to skip)", "questing")

local MAX_STEPS = 40          -- safety limit per NPC visit
local steps = 0
local lastRun = 0

local function GreetingShown()
    return QuestFrameGreetingPanel and QuestFrameGreetingPanel:IsShown()
end

local function IsReadyToTurnIn(questID)
    return questID and C_QuestLog and C_QuestLog.IsComplete and C_QuestLog.IsComplete(questID)
end

-- Picks the next quest to act on. Returns true if it selected one.
local function HandleGreeting()
    if IsShiftKeyDown() then return false end
    if GetTime() - lastRun < 0.8 then return false end   -- ignore duplicate triggers
    lastRun = GetTime()
    if steps >= MAX_STEPS then return false end

    if ns.IsEnabled("questTurnIn") and GetActiveQuestID then
        for i = 1, GetNumActiveQuests() do
            if IsReadyToTurnIn(GetActiveQuestID(i)) then
                steps = steps + 1
                SelectActiveQuest(i)
                return true
            end
        end
    end

    if ns.IsEnabled("questAccept") and GetNumAvailableQuests() > 0 then
        steps = steps + 1
        SelectAvailableQuest(1)
        return true
    end

    return false
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("QUEST_GREETING")   -- fires when an NPC offers more than one quest
frame:RegisterEvent("QUEST_FINISHED")   -- fires as each quest screen closes
frame:SetScript("OnEvent", function(_, event)
    if event == "QUEST_GREETING" then
        C_Timer.After(0.1, HandleGreeting)
    elseif event == "QUEST_FINISHED" then
        -- If the quest list is back on screen, carry on with the next quest
        C_Timer.After(0.3, function()
            if GreetingShown() then
                HandleGreeting()
            elseif not (QuestFrame and QuestFrame:IsShown()) then
                steps = 0   -- the visit is over, so reset for the next NPC
            end
        end)
    end
end)

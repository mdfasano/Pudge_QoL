-- NPCs with several quests: works through the quest list one quest at a time.
-- Finished quests are turned in first, then new quests are accepted.
-- Covers both the quest greeting screen and the gossip menu that lists quests
-- (for example, trainers). Hold Shift at the NPC to skip.
local addonName, ns = ...
ns.RegisterFeature("questGreeting", "NPCs with several quests: handle each one (hold Shift to skip)", "questing")

local MAX_STEPS = 40          -- safety limit per NPC visit
local steps = 0
local lastRun = 0

local function GreetingShown()
    return QuestFrameGreetingPanel and QuestFrameGreetingPanel:IsShown()
end

local function GossipShown()
    return GossipFrame and GossipFrame:IsShown()
end

local function IsReadyToTurnIn(questID)
    return questID and C_QuestLog and C_QuestLog.IsComplete and C_QuestLog.IsComplete(questID)
end

-- Shared guard: skip while Shift is held, ignore duplicate triggers, cap the steps
local function CanAct()
    if IsShiftKeyDown() then return false end
    if GetTime() - lastRun < 0.8 then return false end
    if steps >= MAX_STEPS then return false end
    lastRun = GetTime()
    return true
end

-- Quest greeting screen (several quests from one NPC)
local function HandleGreeting()
    if not CanAct() then return false end

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

-- Gossip menu (quests listed alongside other options)
local function HandleGossip()
    if not CanAct() then return false end
    local gossip = C_GossipInfo
    if not gossip then return false end

    if ns.IsEnabled("questTurnIn") and gossip.GetActiveQuests then
        for _, q in ipairs(gossip.GetActiveQuests() or {}) do
            if q.isComplete then
                steps = steps + 1
                gossip.SelectActiveQuest(q.questID)
                return true
            end
        end
    end

    if ns.IsEnabled("questAccept") and gossip.GetAvailableQuests then
        local available = gossip.GetAvailableQuests() or {}
        if available[1] then
            steps = steps + 1
            gossip.SelectAvailableQuest(available[1].questID)
            return true
        end
    end

    return false
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("QUEST_GREETING")   -- several quests from one NPC
frame:RegisterEvent("GOSSIP_SHOW")      -- gossip menu, which can list quests
frame:RegisterEvent("GOSSIP_CLOSED")
frame:RegisterEvent("QUEST_FINISHED")   -- each quest screen closes
frame:SetScript("OnEvent", function(_, event)
    if event == "QUEST_GREETING" then
        C_Timer.After(0.1, HandleGreeting)
    elseif event == "GOSSIP_SHOW" then
        C_Timer.After(0.1, HandleGossip)
    elseif event == "GOSSIP_CLOSED" then
        steps = 0
    elseif event == "QUEST_FINISHED" then
        -- If the list is back on screen, carry on with the next quest
        C_Timer.After(0.3, function()
            if GreetingShown() then
                HandleGreeting()
            elseif GossipShown() then
                HandleGossip()
            elseif not (QuestFrame and QuestFrame:IsShown()) then
                steps = 0   -- the visit is over
            end
        end)
    end
end)

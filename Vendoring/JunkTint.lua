-- Greys out bag items that are on the junk list.
local addonName, ns = ...
ns.RegisterFeature("junkTint", "Grey out junk items in bags", "vendoring")

local TINT_COLOR = { 0.35, 0.35, 0.35, 0.6 }   -- grey, semi-transparent

local GetItemIDAt = (C_Container and C_Container.GetContainerItemID) or GetContainerItemID

local function IsJunk(itemID)
    local junk = ns.db and ns.db.junkItems
    return itemID ~= nil and junk ~= nil and junk[itemID] ~= nil
end

-- One overlay texture per bag button, created on first use
local function GetTint(button)
    if not button.pudgeJunkTint then
        local tex = button:CreateTexture(nil, "OVERLAY", nil, 7)
        tex:SetAllPoints(button)
        tex:SetColorTexture(unpack(TINT_COLOR))
        tex:Hide()
        button.pudgeJunkTint = tex
    end
    return button.pudgeJunkTint
end

-- Bag frames that hold item buttons
local function GetBagFrames()
    local frames = {}
    if ContainerFrameCombinedBags then table.insert(frames, ContainerFrameCombinedBags) end
    for i = 1, (NUM_CONTAINER_FRAMES or 13) do
        local f = _G["ContainerFrame" .. i]
        if f then table.insert(frames, f) end
    end
    return frames
end

-- Calls fn(button) for every bag item button we can find
local function ForEachBagButton(fn)
    for _, frame in ipairs(GetBagFrames()) do
        if frame.EnumerateValidItems then
            for _, button in frame:EnumerateValidItems() do fn(button) end
        else
            for _, child in ipairs({ frame:GetChildren() }) do
                if child.GetBagID and child.GetID then fn(child) end
            end
        end
    end
end

-- Shows or hides the tint on every bag button. Called by Vendoring.lua and the triggers below.
function PudgeQoL_RefreshJunkTint()
    local enabled = ns.IsEnabled("junkTint")
    ForEachBagButton(function(button)
        local tint = GetTint(button)
        local show = false
        if enabled and button.GetBagID and button.GetID then
            local bag, slot = button:GetBagID(), button:GetID()
            if bag ~= nil and slot ~= nil then
                show = IsJunk(GetItemIDAt(bag, slot))
            end
        end
        tint:SetShown(show)
    end)
end

local function RefreshSoon()
    C_Timer.After(0.1, PudgeQoL_RefreshJunkTint)
end

-- Refresh whenever a bag frame is shown, since its buttons may only exist from then on
local hooked = {}
local function HookBagFrames()
    for _, frame in ipairs(GetBagFrames()) do
        if not hooked[frame] then
            frame:HookScript("OnShow", RefreshSoon)
            hooked[frame] = true
        end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")          -- once per login or reload
frame:RegisterEvent("BAG_UPDATE_DELAYED")    -- when items move, are added, or are sold
frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        HookBagFrames()
        C_Timer.After(1, PudgeQoL_RefreshJunkTint)
    else
        PudgeQoL_RefreshJunkTint()
    end
end)

-- Bag frames can be created after login, so hook them when bags are toggled too
if ToggleAllBags then hooksecurefunc("ToggleAllBags", HookBagFrames) end
if OpenAllBags then hooksecurefunc("OpenAllBags", HookBagFrames) end

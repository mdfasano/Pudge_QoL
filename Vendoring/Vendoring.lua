-- Junk management: mark items as junk with Alt-click or a keybind, then they are
-- sold automatically the next time you open a vendor. Hold Shift at a vendor to skip.
local addonName, ns = ...
ns.RegisterGroup("vendoring", "Vendoring")
ns.RegisterFeature("autoVendorJunk", "Auto-sell junk at vendors (hold Shift to skip)", "vendoring")
ns.RegisterFeature("junkAltClick", "Alt-click a bag item to mark or unmark it as junk", "vendoring")

local PREFIX = "|cffff8000Pudge QoL:|r "
local SELL_DELAY = 0.15   -- seconds between sales, so the server keeps up

-- Compatibility wrappers (C_Container on current clients, globals on older ones)
local GetSlots     = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
local GetItemIDAt  = (C_Container and C_Container.GetContainerItemID) or GetContainerItemID
local UseItemAt    = (C_Container and C_Container.UseContainerItem) or UseContainerItem

-- Junk list lives in the saved variables: [itemID] = item name
local function JunkList()
    ns.db.junkItems = ns.db.junkItems or {}
    return ns.db.junkItems
end

local function ItemNameFor(itemID)
    local name = C_Item and C_Item.GetItemInfo and select(1, C_Item.GetItemInfo(itemID))
    return name or ("item " .. itemID)
end

-- Marks or unmarks the item in a bag slot
local function ToggleJunkAt(bag, slot)
    local itemID = GetItemIDAt(bag, slot)
    if not itemID then
        print(PREFIX .. "that slot is empty.")
        return
    end
    local name = ItemNameFor(itemID)
    local junk = JunkList()
    if junk[itemID] then
        junk[itemID] = nil
        print(PREFIX .. "unmarked " .. name .. " as junk.")
        PudgeQoL_RefreshJunkTint()
    else
        junk[itemID] = name
        print(PREFIX .. "marked " .. name .. " as junk. It will sell at your next vendor visit.")
    PudgeQoL_RefreshJunkTint()
    end
end

-- Bag and slot of the bag item under the mouse, if any
local function SlotUnderMouse()
    local focus = GetMouseFocus and GetMouseFocus()
    if not focus or not focus.GetBagID or not focus.GetID then return nil end
    local bag, slot = focus:GetBagID(), focus:GetID()
    if bag == nil or slot == nil then return nil end
    return bag, slot
end

-- Called by the keybind (see Bindings.xml)
function PudgeQoL_ToggleJunkUnderMouse()
    local bag, slot = SlotUnderMouse()
    if not bag then
        print(PREFIX .. "hover over an item in your bags, then press the key.")
        return
    end
    ToggleJunkAt(bag, slot)
end

-- Alt + left-click on a bag item toggles its junk mark.
-- HandleModifiedItemClick runs for every modified item click; we only act on
-- Alt + left-click on a bag slot.
if HandleModifiedItemClick then
    hooksecurefunc("HandleModifiedItemClick", function(_, itemLocation)
        if not ns.IsEnabled("junkAltClick") then return end
        if not IsAltKeyDown() then return end
        if GetMouseButtonClicked and GetMouseButtonClicked() ~= "LeftButton" then return end
        if not itemLocation or not itemLocation.IsBagAndSlot or not itemLocation:IsBagAndSlot() then return end
        local bag, slot = itemLocation:GetBagAndSlot()
        ToggleJunkAt(bag, slot)
    end)
end

-- Sells every junk item in the bags, one at a time
local function SellJunk()
    local junk = JunkList()
    local queue = {}
    for bag = 0, (NUM_BAG_SLOTS or 4) do
        for slot = 1, GetSlots(bag) do
            local id = GetItemIDAt(bag, slot)
            if id and junk[id] then
                table.insert(queue, { bag = bag, slot = slot, id = id })
            end
        end
    end
    if #queue == 0 then return end

    local sold = 0
    for i, entry in ipairs(queue) do
        C_Timer.After((i - 1) * SELL_DELAY, function()
            -- Never sell unless the vendor window is open, and the slot still holds the same item
            if not (MerchantFrame and MerchantFrame:IsShown()) then return end
            if GetItemIDAt(entry.bag, entry.slot) ~= entry.id then return end
            UseItemAt(entry.bag, entry.slot)
            sold = sold + 1
        end)
    end
    C_Timer.After(#queue * SELL_DELAY + 0.1, function()
        if sold > 0 then
            print(PREFIX .. "sold " .. sold .. " junk item(s).")
        end
    end)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("MERCHANT_SHOW")
frame:SetScript("OnEvent", function()
    if not ns.IsEnabled("autoVendorJunk") then return end
    if IsShiftKeyDown() then return end
    SellJunk()
end)

-- /pqjunk               -> list junk items
-- /pqjunk remove <id>   -> unmark one item
-- /pqjunk clear         -> unmark everything
SLASH_PQJUNK1 = "/pqjunk"
SlashCmdList["PQJUNK"] = function(msg)
    local cmd, arg = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    local junk = JunkList()
    if cmd == "remove" and tonumber(arg) then
        junk[tonumber(arg)] = nil
        print(PREFIX .. "removed item " .. arg .. " from junk.")
        PudgeQoL_RefreshJunkTint()
    elseif cmd == "clear" then
        ns.db.junkItems = {}
        print(PREFIX .. "junk list cleared.")
        PudgeQoL_RefreshJunkTint()
    else
        local count = 0
        print("|cff00ff00--- Junk items ---|r")
        for id, name in pairs(junk) do
            count = count + 1
            print(string.format("%s (ID %d)", tostring(name), id))
        end
        if count == 0 then print("(none)") end
    end
end

-- Names shown in the Keybindings menu
BINDING_HEADER_PUDGEQOL = "Pudge QoL"
BINDING_NAME_PUDGEQOL_TOGGLE_JUNK = "Mark / unmark junk under cursor"

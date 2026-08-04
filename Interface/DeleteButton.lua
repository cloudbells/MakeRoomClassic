local _, ns = ...

local CUI = LibStub("CloudUI-1.0")
local GetContainerNumSlots = C_Container.GetContainerNumSlots
local GetContainerItemInfo = C_Container.GetContainerItemInfo
local GetItemInfo = C_Item.GetItemInfo
local buttons = {}
local items = {}
local clickedButton = 0
local isAtMerchant = false

local hButtonMargin = 12
local vButtonMargin = 14

-- Called when the player speaks with a merchant.
function ns:OnMerchantShow()
    isAtMerchant = true
end

-- Called when the player leaves a merchant.
function ns.OnMerchantClosed()
    isAtMerchant = false
end

-- Called when the player enters or leaves combat.
function ns:OnPlayerInCombatChanged(isInCombat)
    ns:UpdateOpacity(isInCombat)
end

-- Scans the given bag for the cheapest item.
function ns:ScanBags()
    items = {[1] = {value = 999999999}, [2] = {value = 999999999}, [3] = {value = 999999999}}
    local itemCount = 0
    for i = 1, 3 do
        for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
            for slot = 1, GetContainerNumSlots(bag) do
                local itemInfo = GetContainerItemInfo(bag, slot)
                if itemInfo then
                    local texture, count, quality, itemLink, itemID = itemInfo.iconFileID, itemInfo.stackCount, itemInfo.quality, itemInfo.hyperlink,
                                                                      itemInfo.itemID
                    if MRCOptions and not MRCOptions.blacklist[itemID] then
                        local itemName, _, _, _, _, _, _, _, _, _, value = GetItemInfo(itemID)
                        if value and value > 0 then
                            itemCount = itemCount + 1
                            value = value * count
                            if value < items[1].value then
                                items[1] = {
                                    value = value,
                                    itemName = itemName,
                                    itemID = itemID,
                                    texture = texture,
                                    count = count,
                                    quality = quality,
                                    itemLink = itemLink,
                                    bag = bag,
                                    slot = slot
                                }
                            elseif value < items[2].value and not (items[1].bag == bag and items[1].slot == slot) and
                                not (items[3].bag == bag and items[3].slot == slot) then
                                items[2] = {
                                    value = value,
                                    itemName = itemName,
                                    itemID = itemID,
                                    texture = texture,
                                    count = count,
                                    quality = quality,
                                    itemLink = itemLink,
                                    bag = bag,
                                    slot = slot
                                }
                            elseif value < items[3].value and not (items[1].bag == bag and items[1].slot == slot) and
                                not (items[2].bag == bag and items[2].slot == slot) then
                                items[3] = {
                                    value = value,
                                    itemName = itemName,
                                    itemID = itemID,
                                    texture = texture,
                                    count = count,
                                    quality = quality,
                                    itemLink = itemLink,
                                    bag = bag,
                                    slot = slot
                                }
                            end
                        end
                    end
                end
            end
        end
    end
    for i = 1, 3 do
        if items[i].texture then
            local color = ITEM_QUALITY_COLORS[items[i].quality]
            buttons[i]:Show()
            buttons[i]:Enable()
            local valueStr = items[i].value < 100 and items[i].value .. "c" or
                                 (items[i].value >= 100 and items[i].value < 10000 and items[i].value / 100 .. "s") or items[i].value / 10000 .. "g"
            buttons[i].priceFontString:SetText(valueStr)
            buttons[i]:SetIcon(items[i].texture)
            buttons[i].countFontString:SetText(items[i].count > 1 and items[i].count or "")
            buttons[i]:SetBorderColor(color.r, color.g, color.b)
            buttons[i]:SetLink(items[i].itemLink)
            buttons[i]:SetItemLocation(items[i].bag, items[i].slot)
        else
            if i == 1 then
                buttons[i]:Disable()
            else
                buttons[i]:Hide()
            end
            buttons[i].priceFontString:SetText("")
            buttons[i]:SetIcon(nil)
            buttons[i].countFontString:SetText("")
            buttons[i]:SetLink(nil)
        end
    end

    if not MRCOptions then
        return
    end

    if itemCount == 0 then
        MRCOptions.isHidden = true
        return ns.deleteButtonParent:Hide()
    end

    if not MRCOptions.userHidden then
        MRCOptions.isHidden = false
        ns.deleteButtonParent:Show()
    end
end

-- Deletes or sells cheapest item.
function ns:DeleteOrSellCheapest()
    local bag, slot = buttons[1]:GetItemLocation()
    if bag and slot then
        local itemInfo = GetContainerItemInfo(bag, slot)
        if itemInfo then
            if MRCOptions and not MRCOptions.blacklist[itemInfo.itemID] then
                if isAtMerchant then
                    return C_Container.UseContainerItem(bag, slot)
                end

                C_Container.PickupContainerItem(bag, slot)
                DeleteCursorItem()
            end
        end
    end
end

-- Deletes or sells cheapest item.
function MRC_DeleteOrSellCheapest()
    ns:DeleteOrSellCheapest()
end

-- Called when the button is clicked.
local function DeleteButton_OnClick(self, button)
    if not MRCOptions.isLocked then
        return
    end
    if button == "RightButton" then
        if not MRCOptions.blacklist[items[self.id].itemID] then
            ns:AddToBlacklist(items[self.id].itemID)
        else
            ns:RemoveFromBlacklist(items[self.id].itemID)
        end
    elseif self:GetLink() then
        clickedButton = self.id
        if isAtMerchant then
            C_Container.UseContainerItem(self.bag, self.slot)
        else
            StaticPopupDialogs["MAKEROOMCLASSIC_CONFIRM_DELETE"].text = "Are you sure you want to delete " .. items[self.id].itemLink ..
                                                                            (items[self.id].count > 1 and "x" .. items[self.id].count or "") .. " (" ..
                                                                            GetCoinTextureString(items[self.id].value) .. ")?"
            StaticPopup_Show("MAKEROOMCLASSIC_CONFIRM_DELETE")
        end
    end
end

-- Sets the location of the item.
local function DeleteButton_SetItemLocation(self, bag, slot)
    self.bag = bag
    self.slot = slot
end

-- Gets the location of the item.
local function DeleteButton_GetItemLocation(self)
    return self.bag, self.slot
end

-- Called on BAG_UPDATE.
function ns:OnBagUpdate(bag)
    if bag >= 0 then
        ns:ScanBags()
    end
end

-- Updates the opacity of the buttons.
function ns:UpdateOpacity(isInCombat)
    local opacity = isInCombat and MRCOptionsGlobal.inCombatOpacity / 100 or MRCOptionsGlobal.outOfCombatOpacity / 100

    ns.deleteButtonParent:SetAlpha(opacity)
    for i = 1, 3 do
        buttons[i]:SetAlpha(opacity)
    end
end

-- Updates button grow direction.
function ns:UpdateGrowDirection()
    if not MRCOptions then
        return
    end

    buttons[2]:ClearAllPoints()
    buttons[3]:ClearAllPoints()
    if MRCOptions.growDirection == ns.GROW_DIRECTION.Up then
        buttons[2]:SetPoint("BOTTOM", buttons[1], "TOP", 0, vButtonMargin)
        buttons[3]:SetPoint("BOTTOM", buttons[2], "TOP", 0, vButtonMargin)
    elseif MRCOptions.growDirection == ns.GROW_DIRECTION.Down then
        buttons[2]:SetPoint("TOP", buttons[1], "BOTTOM", 0, -vButtonMargin)
        buttons[3]:SetPoint("TOP", buttons[2], "BOTTOM", 0, -vButtonMargin)
    elseif MRCOptions.growDirection == ns.GROW_DIRECTION.Left then
        buttons[2]:SetPoint("RIGHT", buttons[1], "LEFT", -hButtonMargin, 0)
        buttons[3]:SetPoint("RIGHT", buttons[2], "LEFT", -hButtonMargin, 0)
    elseif MRCOptions.growDirection == ns.GROW_DIRECTION.Right then
        buttons[2]:SetPoint("LEFT", buttons[1], "RIGHT", hButtonMargin, 0)
        buttons[3]:SetPoint("LEFT", buttons[2], "RIGHT", hButtonMargin, 0)
    end
end

-- Creates the delete button.
function ns:InitDeleteButton()
    -- Create the parent frame.
    ns.deleteButtonParent = CreateFrame("Frame", "MakeRoomClassicFrame", UIParent)
    ns.deleteButtonParent:SetSize(1, 1)
    ns.deleteButtonParent:SetPoint("CENTER")
    -- Create buttons.
    for i = 1, 3 do
        buttons[i] = CUI:CreateLinkButton(ns.deleteButtonParent, "MakeRoomClassicButton" .. i, nil, {DeleteButton_OnClick})
        buttons[i]:SetSize(32, 32)
        buttons[i]:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        buttons[i]:SetPoint("CENTER")
        buttons[i].priceFontString = buttons[i]:CreateFontString(nil, "OVERLAY", CUI:GetFontSmall():GetName())
        buttons[i].priceFontString:SetJustifyH("CENTER")
        buttons[i].priceFontString:SetPoint("TOP", buttons[i], "BOTTOM", 0, -2)
        buttons[i].countFontString = buttons[i]:CreateFontString(nil, "OVERLAY", CUI:GetFontSmall():GetName())
        buttons[i].countFontString:SetPoint("BOTTOMRIGHT")
        buttons[i].SetItemLocation = DeleteButton_SetItemLocation
        buttons[i].GetItemLocation = DeleteButton_GetItemLocation
        buttons[i].id = i
    end
    ns.deleteButtonParent:SetMovable(true)
    buttons[1]:HookScript("OnMouseDown", function()
        if not MRCOptions.isLocked then
            ns.deleteButtonParent:StartMoving()
        end
    end)
    buttons[1]:HookScript("OnMouseUp", function()
        if not MRCOptions.isLocked then
            ns.deleteButtonParent:StopMovingOrSizing()
        end
    end)
    buttons[1]:SetSize(40, 40)
    -- Init static popup.
    StaticPopupDialogs["MAKEROOMCLASSIC_CONFIRM_DELETE"] = {
        text = "Placeholder text",
        button1 = "Yes",
        button2 = "No",
        timeout = 0,
        OnAccept = function()
            C_Container.PickupContainerItem(buttons[clickedButton]:GetItemLocation())
            DeleteCursorItem()
        end
    }
end

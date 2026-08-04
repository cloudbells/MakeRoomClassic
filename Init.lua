local ADDON_NAME, ns = ...

-- TODO:
-- add a scroll? add a frame to the right of the highlighted frame and have the highlighted frame be the second most cheap item among the current 4

-- Variables.
local eventFrame
local minimapButton = LibStub("LibDBIcon-1.0")
ns.GROW_DIRECTION = ns:Enum({"Up", "Down", "Left", "Right"})

-- Adds the given item to the blacklist.
function ns:AddToBlacklist(itemID)
    MRCOptions.blacklist[itemID] = true
    local _, itemLink = GetItemInfo(itemID)
    print("|cFFFFFF00MakeRoomClassic|r: Added " .. itemLink .. " to the blacklist.")
    ns:ScanBags()
end

-- Removes the given item from the blacklist.
function ns:RemoveFromBlacklist(itemID)
    MRCOptions.blacklist[itemID] = nil
    local _, itemLink = GetItemInfo(itemID)
    print("|cFFFFFF00MakeRoomClassic|r: Removed " .. itemLink .. " from the blacklist.")
    ns:ScanBags()
end

-- Shows or hides the frame.
local function ToggleFrame()
    MRCOptions.isHidden = not MRCOptions.isHidden
    MRCOptions.userHidden = MRCOptions.isHidden
    if MRCOptions.isHidden then
        ns.deleteButtonParent:Hide()
        PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
    else
        ns.deleteButtonParent:Show()
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
    end
end

-- Shows or hides the minimap button.
local function ToggleMinimapButton()
    MRCOptions.minimapTable.hide = not MRCOptions.minimapTable.hide
    if MRCOptions.minimapTable.hide then
        minimapButton:Hide("MakeRoomClassic")
        print("|cFFFFFF00MakeRoomClassic|r: Minimap button hidden. Type /mrc minimap to show it again.")
    else
        minimapButton:Show("MakeRoomClassic")
    end
end

-- Toggles login messages.
local function ToggleLoginMessage()
    MRCOptionsGlobal.disableLoginMessage = not MRCOptionsGlobal.disableLoginMessage
    if MRCOptionsGlobal.disableLoginMessage then
        print("|cFFFFFF00MakeRoomClassic:|r Login message disabled. Type /mrc loginmessage to show it again.")
    else
        print("|cFFFFFF00MakeRoomClassic:|r Login message enabled.")
    end
end

-- Sets the in-combat and out-of-combat opacity levels.
local function SetOpacity(outOfCombatOpacity, inCombatOpacity)
    if not outOfCombatOpacity or not inCombatOpacity then
        print("|cFFFFFF00MakeRoomClassic|r: unable to set opacity as no opacity level was provided.")
        return
    end

    MRCOptionsGlobal.outOfCombatOpacity = outOfCombatOpacity
    MRCOptionsGlobal.inCombatOpacity = inCombatOpacity

    ns:UpdateOpacity(InCombatLockdown())

    print("|cFFFFFF00MakeRoomClassic|r: out-of-combat opacity set to " .. outOfCombatOpacity .. "%.")
    print("|cFFFFFF00MakeRoomClassic|r: in-combat opacity set to " .. inCombatOpacity .. "%.")
end

-- Sets frame positional lock status.
local function SetLocked(isLocked)
    if isLocked then
        print("|cFFFFFF00MakeRoomClassic|r: locked.")
    else
        print("|cFFFFFF00MakeRoomClassic|r: unlocked.")
    end
    MRCOptions.isLocked = isLocked
end

-- Sets button grow direction.
local function SetGrowDirection(growDirectionText)
    -- text is already lower case
    if growDirectionText == "up" then
        MRCOptions.growDirection = ns.GROW_DIRECTION.Up
        print("|cFFFFFF00MakeRoomClassic|r: set grow direction to 'up'.")
    elseif growDirectionText == "down" then
        MRCOptions.growDirection = ns.GROW_DIRECTION.Down
        print("|cFFFFFF00MakeRoomClassic|r: set grow direction to 'down'.")
    elseif growDirectionText == "left" then
        MRCOptions.growDirection = ns.GROW_DIRECTION.Left
        print("|cFFFFFF00MakeRoomClassic|r: set grow direction to 'left'.")
    elseif growDirectionText == "right" then
        MRCOptions.growDirection = ns.GROW_DIRECTION.Right
        print("|cFFFFFF00MakeRoomClassic|r: set grow direction to 'right'.")
    else
        print("|cFFFFFF00MakeRoomClassic|r: couldn't set grow direction to " .. growDirectionText .. ".")
    end

    ns:UpdateGrowDirection()
end

-- Initializes the minimap button.
local function InitMinimapButton()
    -- Register for eventual data brokers.
    local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("MakeRoomClassic", {
        type = "data source",
        text = "MakeRoomClassic",
        icon = "Interface/Addons/MakeRoomClassic/Media/FrostPresence",
        OnClick = function(self, button)
            if button == "LeftButton" then
                ToggleFrame()
            elseif button == "RightButton" then
                ToggleMinimapButton()
            end
        end,
        OnEnter = function(self)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:AddLine("|cFFFFFFFFMakeRoomClassic|r")
            GameTooltip:AddLine("Click to toggle the main frame. Right click to hide this minimap button.") -- temp
            GameTooltip:Show()
        end,
        OnLeave = function(self)
            GameTooltip:Hide()
        end
    })
    -- Create minimap icon.
    minimapButton:Register("MakeRoomClassic", LDB, MRCOptions.minimapTable)
end

-- Initializes slash commands.
local function InitSlash()
    SLASH_MRC1 = "/mrc"
    SLASH_MRC2 = "/makeroomclassic"
    function SlashCmdList.MRC(text)
        if text == "minimap" then
            ToggleMinimapButton()
        elseif text == "loginmessage" then
            ToggleLoginMessage()
        elseif text:find("opacity") then
            local outOfCombatOpacityText, inCombatOpacityText = text:match("opacity (%d+).* (%d+).*")
            local outOfCombatOpacity = tonumber(outOfCombatOpacityText)
            local inCombatOpacity = tonumber(inCombatOpacityText)
            if not outOfCombatOpacity or not inCombatOpacity then
                print("|cFFFFFF00MakeRoomClassic|r: opacity needs valid numbers")
                return
            end
            if outOfCombatOpacity < 0 or outOfCombatOpacity > 100 or inCombatOpacity < 0 or inCombatOpacity > 100 then
                print("|cFFFFFF00MakeRoomClassic|r: opacity cannot be lower than 0% or higher than 100%")
                return
            end
            SetOpacity(outOfCombatOpacity, inCombatOpacity)
        elseif text == "lock" then
            SetLocked(true)
        elseif text == "unlock" then
            SetLocked(false)
        elseif text:find("growdirection") then
            SetGrowDirection(text:match("growdirection (.*)"))
        elseif text == "delete" then
            ns:DeleteOrSellCheapest()
        elseif text:find("blacklist add") then
            ns:AddToBlacklist(ns:ParseIDFromLink(text:match("blacklist add (.+)")))
        elseif text:find("blacklist remove") then
            ns:RemoveFromBlacklist(ns:ParseIDFromLink(text:match("blacklist remove (.+)")))
        elseif text == "blacklist all" then
            local str = ""
            for itemID in pairs(MRCOptions.blacklist) do
                local _, itemLink = GetItemInfo(itemID)
                if itemLink then
                    print("* " .. itemLink)
                end
            end
            print("|cFFFFFF00MakeRoomClassic|r: all blacklist items:" .. str)
        elseif text == "blacklist purge" then
            MRCOptions.blacklist = {}
            ns:ScanBags()
            print("|cFFFFFF00MakeRoomClassic|r: removed all items from the blacklist")
        elseif text == "help" then
            -- LuaFormatter off
            print("|cFFFFFF00MakeRoomClassic|r help:\n" ..
                      "Right click an item to add it to the blacklist.\n" ..
                      "Left click an item to delete it.\n" ..
                      "/mrc minimap - shows or hides the minimap\n" ..
                      "/mrc loginmessage - shows or hides the login message\n" ..
                      "/mrc opacity outOfCombatOpacity inCombatOpacity - sets opacity, numbers must be between 0 and 100\n" ..
                      "/mrc lock and /mrc unlock - locks/unlocks the frame's position\n" ..
                      "/mrc growdirection up/down/left/right - sets grow direction of the buttons\n" ..
                      "/mrc blacklist add [itemlink] - adds the given itemlink to the blacklist\n" ..
                      "/mrc blacklist remove [itemlink] - removes the given item from the blacklist\n" ..
                      "/mrc blacklist all - lists all the blacklist items\n" ..
                      "/mrc blacklist purge - removes all items from the blacklist")
            -- LuaFormatter on
        else
            ToggleFrame()
        end
    end
end

-- Initializes keybinds.
local function InitKeybinds()
    BINDING_NAME_MRC_DELETE_CHEAPEST = "Delete or Sell Cheapest Item"
end

-- Registers for events.
local function Initialize()
    eventFrame = CreateFrame("Frame")
    ns:RegisterAllEvents(eventFrame)
    ns:InitDeleteButton()
end

-- Loads all saved variables.
local function LoadVariables()
    MRCOptions = MRCOptions or {}
    MRCOptionsGlobal = MRCOptionsGlobal or {}
    MRCOptions.isHidden = MRCOptions.isHidden or false
    MRCOptions.userHidden = MRCOptions.userHidden or false
    MRCOptions.minimapTable = MRCOptions.minimapTable or {}
    MRCOptions.blacklist = MRCOptions.blacklist or {}
    MRCOptions.isLocked = MRCOptions.isLocked or false
    MRCOptions.growDirection = MRCOptions.growDirection or ns.GROW_DIRECTION.Left
    MRCOptionsGlobal.disableLoginMessage = MRCOptionsGlobal.disableLoginMessage or false
    MRCOptionsGlobal.outOfCombatOpacity = MRCOptionsGlobal.outOfCombatOpacity or 100
    MRCOptionsGlobal.inCombatOpacity = MRCOptionsGlobal.inCombatOpacity or 100
end

-- Called when most game data is available.
function ns:OnPlayerEnteringWorld()
    eventFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
    ns:UpdateOpacity(InCombatLockdown())
    ns:UpdateGrowDirection()
    ns:ScanBags()
    if MRCOptions.isHidden then
        ns.deleteButtonParent:Hide()
    end
end

-- Called on ADDON_LOADED.
function ns:OnAddonLoaded(addonName)
    if addonName == ADDON_NAME then
        eventFrame:UnregisterEvent("ADDON_LOADED")
        LoadVariables()
        InitMinimapButton()
        InitSlash()
        InitKeybinds()
        if not MRCOptionsGlobal.disableLoginMessage then
            print("|cFFFFFF00MakeRoomClassic|r loaded! Type /mrc help for commands and controls. Remember to do /mrc lock so the addon works!")
        end
    end
end

Initialize()

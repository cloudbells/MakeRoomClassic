local ADDON_NAME, ns = ...

-- TODO:
    -- add a scroll? add a frame to the right of the highlighted frame and have the highlighted frame be the second most cheap item among the current 4

-- Variables.
local eventFrame
local minimapButton = LibStub("LibDBIcon-1.0")

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
        print("|cFFFFFF00MakeRoomClassic|r: Minimap button hidden. Type /MRC minimap to show it again.")
    else
        minimapButton:Show("MakeRoomClassic")
    end
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
    SLASH_MRC1 = "/MRC"
    SLASH_MRC2 = "/MakeRoomClassic"
    function SlashCmdList.MRC(text)
        if text == "help" then
            print("|cFFFFFF00MakeRoomClassic|r help: \nRight click an item to add it to the blacklist.\nLeft click an item to delete it.\n" ..
                    "/mrc minimap - shows or hides the minimap\n/mrc blacklist add [itemlink] - adds the given itemlink to the blacklist\n" ..
                    "/mrc blacklist remove [itemlink] - removes the given item from the blacklist\n/mrc blacklist all - lists all the blacklist items\n" ..
                    "/mrc blacklist purge - removes all items from the blacklist")
        elseif text == "delete" then
            ns:DeleteCheapest()
        elseif text == "minimap" then
            ToggleMinimapButton()
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
        else
            ToggleFrame()
        end
    end
end

-- Initializes keybinds.
local function InitKeybinds()
    BINDING_NAME_MRC_DELETE_CHEAPEST = "Delete Cheapest Item"
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
    MRCOptions.isHidden = MRCOptions.isHidden or false
    MRCOptions.minimapTable = MRCOptions.minimapTable or {}
    MRCOptions.blacklist = MRCOptions.blacklist or {}
end

-- Called when most game data is available.
function ns:OnPlayerEnteringWorld()
    eventFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
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
        print("|cFFFFFF00MakeRoomClassic|r loaded! Type /mrc help for commands and controls.")
    end
end

Initialize()

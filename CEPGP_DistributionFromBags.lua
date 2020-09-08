local L = LibStub("AceLocale-3.0"):GetLocale("CEPGP_DistributionFromBags")

--[[ Globals ]]--

CEPGP_DFB_Addon = "CEPGP_DistributionFromBags"
CEPGP_DFB_LoadedAddon = false
CEPGP_DFB_LastTime = 0
CEPGP_DFB_LastLink = nil
CEPGP_DFB_Distributing = false
CEPGP_DFB_DistPlayerBtn = nil
CEPGP_DFB_IsAnnounced = false

SLASH_CEPGPDFB1 = "/CEPDFB"
SLASH_CEPGPDFB2 = "/cepdfb"

--[[ SAVED VARIABLES ]]--

--[[ Code ]]--
local frame = CreateFrame("Frame")
frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("TRADE_ACCEPT_UPDATE")
frame:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")
frame:RegisterEvent("TRADE_REQUEST_CANCEL")

frame:SetScript("OnEvent", CEPGP_DFB_OnEvent)
local origCEPGP_ListButton_OnClick = CEPGP_ListButton_OnClick
local origCEPGP_distribute_popup_give = CEPGP_distribute_popup_give

function CEPGP_DFB_print(str, err)
	if not str then return; end;
	if err == nil then
		DEFAULT_CHAT_FRAME:AddMessage("|c00FFF569CEPGP_DFB: " .. tostring(str) .. "|r");
	else
		DEFAULT_CHAT_FRAME:AddMessage("|c00FFF569CEPGP_DFB:|r " .. "|c00FF0000Error|r|c00FFF569 - " .. tostring(str) .. "|r");
	end
end

local function GetBagPosition(itemLink)
    local bag,slot;--   These are nil to start with
	for i=0, NUM_BAG_SLOTS do
		for j=1,GetContainerNumSlots(i) do
			if GetContainerItemLink(i,j)==link then
				bag,slot=i,j;-- Set vars
				break;--    Breaks out of inner loop
			end
		end
	
		--  Break out of outer loop if vars have been set by inner loop
		if bag and slot then break; end
	end
	return bag, slot
end

-- [[ WOW API HOOK ]] --
-- Shift+Click item to trigger CEPGP_DFB_LootFrame_Update if DFB window is shown
hooksecurefunc("HandleModifiedItemClick", function(link)
	if CEPGP_DFB_LastLink == link then	-- duplicate calls 
		if time() - CEPGP_DFB_LastTime < 2 then	
			return
		end
	end

	if CEPGP_DFB_frame:IsShown() and not ChatEdit_GetActiveWindow() then
		local _, itemLink = GetItemInfo(link)
		if itemLink then
			CEPGP_DFB_LootFrame_Update(itemLink)
		end

		CEPGP_DFB_LastTime = time()
		CEPGP_DFB_LastLink = link
	end
end)

-- [[ CORE ]] --

local function CEPGP_DFB_SlashCmd(arg)
	if not CEPGP_DFB_frame:IsShown()then
		ShowUIPanel(CEPGP_DFB_frame)
		OpenAllBags()
	else
		HideUIPanel(CEPGP_DFB_frame)
	end
end

SlashCmdList["CEPGPDFB"] = CEPGP_DFB_SlashCmd

function CEPGP_DFB_init()
	if (_G.CEPGP) then
		_G.CEPGP_distribute_popup_give = CEPGP_distribute_popup_give_Hook
		_G.CEPGP_ListButton_OnClick = CEPGP_ListButton_OnClick_Hook
	end

	CEPGP_DFB_confirmation:Hide()
	_G["CEPGP_DFB_frame_text"]:SetText(L["Instruction"] )
	CEPGP_DFB_frame:HookScript("OnHide", function()
		CEPGP_DFB_LastTime = 0
		CEPGP_DFB_LastLink = nil
		CEPGP_DFB_Distributing = false
		CEPGP_DFB_DistPlayerBtn = nil
		CEPGP_distributing = false
		CEPGP_DFB_IsAnnounced = false
	end)
	CEPGP_distribute_popup:HookScript("OnHide", function()
		CEPGP_distribute_popup_pass:Show()
	end)
	CEPGP_distribute_popup_pass:HookScript("OnClick", function()
		CEPGP_DFB_DistPlayerBtn = nil
	end)
end

function CEPGP_DFB_OnEvent(self, event, arg1, arg2, arg3, arg4, arg5)

	if event == "ADDON_LOADED" and arg1 == CEPGP_DFB_Addon and CEPGP_DFB_LoadedAddon == false then
        self:UnregisterEvent("ADDON_LOADED")
        CEPGP_DFB_LoadedAddon = true
		CEPGP_DFB_init()

	elseif event == "TRADE_ACCEPT_UPDATE" then
		if CEPGP_DFB_Distributing and CEPGP_DFB_DistPlayerBtn and CEPGP_distItemLink then
			if arg1==1 then
				if CEPGP_distItemLink == GetTradePlayerItemLink(1) then
					CEPGP_distribute_popup_pass:Hide()
					CEPGP_ListButton_OnClick(CEPGP_DFB_DistPlayerBtn, "LeftButton")
				else
					CEPGP_DFB_print(CEPGP_distItemLink .. " is not in SLOT 1",true)
				end
			end
		end

	elseif event == "TRADE_PLAYER_ITEM_CHANGED" then
		if CEPGP_DFB_Distributing and CEPGP_DFB_DistPlayerBtn and CEPGP_distItemLink then
			if CEPGP_distItemLink ~= GetTradePlayerItemLink(1) then
				CEPGP_DFB_print(L["Wrong Item"], true)
				CancelTrade()
				CEPGP_DFB_confirmation:Show()
			end
		end

	elseif event == "TRADE_REQUEST_CANCEL" then
		if CEPGP_DFB_Distributing and CEPGP_DFB_DistPlayerBtn and CEPGP_distItemLink then
			CEPGP_distribute_popup:Hide()
			CEPGP_DFB_confirmation:Show()
		end
	end
end

function CEPGP_DFB_LootFrame_Update(itemLink)

	if GetLootMethod() ~= "master" then
		CEPGP_DFB_print(L["The loot method is not Master Looter"], 1);
		return
	elseif CEPGP_isML() ~= 0 then
		CEPGP_DFB_print(L["You are not the Loot Master"], 1);
		return
	end

	local items = {};
    
    itemName, _, itemRarity, _, _, _, _, _,_, itemIcon, _, _, _, _, _, _, _ = GetItemInfo(itemLink) 
	if itemName == nil then return; end

	items[1] = {};
	items[1][1] = itemIcon;
	items[1][2] = itemName;
	items[1][3] = itemRarity;
	items[1][4] = itemLink;
	local itemString = string.find(itemLink, "item[%-?%d:]+");
	itemString = strsub(itemLink, itemString, string.len(itemLink)-string.len(itemName)-6);
	items[1][5] = itemString;
	items[1][6] = 1;	-- slot
	items[1][7] = 1;	-- quantity	

	CEPGP_DFB_Distributing = true
	CEPGP_DFB_DistPlayerBtn = nil
	CEPGP_DFB_IsAnnounced = false

	CEPGP_frame:Show();
	CEPGP_mode = "loot";
	CEPGP_toggleFrame("CEPGP_loot");
	CEPGP_populateFrame(items);
	CEPGP_announce(itemLink, 1, 1, 1)
end

function CEPGP_DFB_ConfirmWinner(player)
	CEPGP_DFB_confirmation:SetAttribute("player", player)
	if player == UnitName("player") then
		_G["CEPGP_DFB_confirmation_desc"]:SetText(CEPGP_distItemLink .. "\n\nTo yourself")
	else
		_G["CEPGP_DFB_confirmation_desc"]:SetText(CEPGP_distItemLink .. "\n\n" .. player ..  L[" is the winner"])
	end
	CEPGP_DFB_confirmation:Show()
end


function CEPGP_DFB_AnnounceWinner(isWinner)
	if isWinner then
		local player = CEPGP_DFB_confirmation:GetAttribute("player")
		if player == UnitName("player") then
			CEPGP_DFB_confirmation:Hide();
			CEPGP_ListButton_OnClick(CEPGP_DFB_DistPlayerBtn, "LeftButton")
		else
			if not CEPGP_DFB_IsAnnounced then
				if CEPGP.Loot.RaidWarning then
					SendChatMessage(player .. L[" is the winner. Come to trade with me"] , "RAID_WARNING", CEPGP_LANGUAGE);
				else
					SendChatMessage(player .. L[" is the winner. Come to trade with me"] , "RAID", CEPGP_LANGUAGE);
				end
				CEPGP_DFB_IsAnnounced = true
			end
			if CheckInteractDistance(player, 2) then
				CEPGP_DFB_confirmation:Hide();
				InitiateTrade(player)
			else
				CEPGP_DFB_print(player.." is too far away", true)
			end
		end
	else
		CEPGP_DFB_DistPlayerBtn = nil
		CEPGP_DFB_confirmation:Hide();
	end
end

-- [[ CEPGP Hook ]] --
function CEPGP_ListButton_OnClick_Hook(obj, button)
	if CEPGP_DFB_Distributing and button == "LeftButton" then
		--[[ Distribution Menu ]]--
		if CEPGP_DFB_frame:IsShown() and strfind(obj, "LootDistButton") then --A player in the distribution menu is clicked
			if CEPGP_DFB_DistPlayerBtn then
				if CEPGP_DFB_confirmation:IsShown() then
					CEPGP_DFB_DistPlayerBtn = nil
					CEPGP_DFB_confirmation:Hide()
					return
				end
			else
				CEPGP_DFB_IsAnnounced = false
				local player = _G[_G[obj]:GetName() .. "Info"]:GetText()
				CEPGP_DFB_DistPlayerBtn = obj
				CEPGP_DFB_ConfirmWinner(player)
				return
			end
		end
	end
	origCEPGP_ListButton_OnClick(obj, button)
end

function CEPGP_distribute_popup_give_Hook()
	if CEPGP_DFB_frame:IsShown() then
		CEPGP_handleLoot("LOOT_SLOT_CLEARED", 1)
		CEPGP_DFB_Distributing = false
		CEPGP_DFB_DistPlayerBtn = nil
		CEPGP_DFB_IsAnnounced = false
	else
		origCEPGP_distribute_popup_give()
	end
end
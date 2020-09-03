--[[ Globals ]]--

CEPGP_AFB_Addon = "CEPGP_AnnounceFromBag"
CEPGP_AFB_LoadedAddon = false
CEPGP_AFB_LastTime = 0
CEPGP_AFB_LastLink = nil

SLASH_CEPGPAFB1 = "/CEPAFB"
SLASH_CEPGPAFB2 = "/cepafb"

--[[ SAVED VARIABLES ]]--

--[[ Code ]]--
local frame = CreateFrame("Frame")
frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("ADDON_LOADED")

hooksecurefunc("HandleModifiedItemClick", function(link)
	if CEPGP_AFB_LastLink == link then	-- too quickly
		if time() - CEPGP_AFB_LastTime < 2 then
			return
		end
	end

	if CEPGP_AFB_frame:IsShown() and not ChatEdit_GetActiveWindow() then
		local _, itemLink = GetItemInfo(link)
		if itemLink then
			CEPGP_AFB_LootFrame_Update(itemLink)
		end

		CEPGP_AFB_LastTime = time()
		CEPGP_AFB_LastLink = link
	end
end)


local function CEPGP_AFB_SlashCmd(arg)
	if arg ~= "" then
		local _, itemLink = GetItemInfo(arg)
        if itemLink then
			CEPGP_AFB_LootFrame_Update(arg)
		else
			CEPGP_print("|cFFFFFFFFType|r |cFF80FF80/cepafb [ItemLink]|r |cFFFFFFFFto announce the item from bag.|r");
		end
	else
		ShowUIPanel(CEPGP_AFB_frame)
		OpenAllBags()
	end
end

SlashCmdList["CEPGPAFB"] = CEPGP_AFB_SlashCmd

function CEPGP_AFB_init()
	if (_G.CEPGP) then
		_G.CEPGP_distribute_popup_give = CEPGP_distribute_popup_give_Hook
	end

	if (GetLocale() == "zhTW") then
		_G["CEPGP_AFB_frame_text"]:SetText("Shift+Click 點擊包包裡的物品來開始分配\n\n分配完後要自行手動拿裝給人")
	else
		_G["CEPGP_AFB_frame_text"]:SetText("Shift+Click a item in inventory to start the loot process.\n\nYou need to trade the item to people manually.")
	end
end

local function OnEvent(self, event, arg1, arg2)
    if arg1 ~= CEPGP_AFB_Addon then return end
	if event == "ADDON_LOADED" and CEPGP_AFB_LoadedAddon == false then
        self:UnregisterEvent("ADDON_LOADED")
        CEPGP_AFB_LoadedAddon = true
		CEPGP_AFB_init()
    end
end

frame:SetScript("OnEvent", OnEvent)

function CEPGP_AFB_LootFrame_Update(itemLink)
	if GetLootMethod() ~= "master" then
		if (GetLocale() == "zhTW") then
			CEPGP_print("不在隊長分配模式", 1);
		else
			CEPGP_print("The loot method is not Master Looter", 1);
		end
		return
	elseif CEPGP_isML() ~= 0 then
		if (GetLocale() == "zhTW") then
			CEPGP_print("你不是分裝者.", 1);
		else
			CEPGP_print("You are not the Loot Master.", 1);
		end
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

	CEPGP_frame:Show();
	CEPGP_mode = "loot";
	CEPGP_toggleFrame("CEPGP_loot");
	
	CEPGP_populateFrame(items);
	CEPGP_announce(itemLink, 1, 1, 1)
end

function CEPGP_distribute_popup_give_Hook()
	if not CEPGP_AFB_frame:IsShown() then
		for i = 1, 40 do
			if GetMasterLootCandidate(CEPGP_lootSlot, i) == CEPGP_distPlayer then
				GiveMasterLoot(CEPGP_lootSlot, i);
				return;
			end
		end
		CEPGP_print(CEPGP_distPlayer .. " is not on the candidate list for loot", true);
		CEPGP_distPlayer = "";
		
	else
		CEPGP_handleLoot("LOOT_SLOT_CLEARED", 1)	
	end
end
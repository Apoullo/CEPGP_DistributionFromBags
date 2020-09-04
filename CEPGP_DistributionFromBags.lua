--[[ Globals ]]--

CEPGP_DFB_Addon = "CEPGP_DistributionFromBags"
CEPGP_DFB_LoadedAddon = false
CEPGP_DFB_LastTime = 0
CEPGP_DFB_LastLink = nil

SLASH_CEPGPDFB1 = "/CEPDFB"
SLASH_CEPGPDFB2 = "/cepdfb"

--[[ SAVED VARIABLES ]]--

--[[ Code ]]--
local frame = CreateFrame("Frame")
frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("ADDON_LOADED")

function CEPGP_DFB_print(str, err)
	if not str then return; end;
	if err == nil then
		DEFAULT_CHAT_FRAME:AddMessage("|c00FFF569CEPGP_DFB: " .. tostring(str) .. "|r");
	else
		DEFAULT_CHAT_FRAME:AddMessage("|c00FFF569CEPGP_DFB:|r " .. "|c00FF0000Error|r|c00FFF569 - " .. tostring(str) .. "|r");
	end
end
-- [[ WOW API HOOK ]] --
hooksecurefunc("HandleModifiedItemClick", function(link)
	if CEPGP_DFB_LastLink == link then	-- too quickly
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
	end

	if (GetLocale() == "zhTW") then
		_G["CEPGP_DFB_frame_text"]:SetText("Shift+Click 點擊包包裡的物品來開始喊裝\n\n分配完後要自行手動拿裝給人")
	else
		_G["CEPGP_DFB_frame_text"]:SetText("Shift+Click an item in inventory to start loot distribution process.\n\nAt the end, you need to give the item to the winner MANUALLY.")
	end
end

local function OnEvent(self, event, arg1, arg2)
    if arg1 ~= CEPGP_DFB_Addon then return end
	if event == "ADDON_LOADED" and CEPGP_DFB_LoadedAddon == false then
        self:UnregisterEvent("ADDON_LOADED")
        CEPGP_DFB_LoadedAddon = true
		CEPGP_DFB_init()
    end
end

frame:SetScript("OnEvent", OnEvent)

function CEPGP_DFB_LootFrame_Update(itemLink)

	if GetLootMethod() ~= "master" then
		if (GetLocale() == "zhTW") then
			CEPGP_DFB_print("不在隊長分配模式", 1);
		else
			CEPGP_DFB_print("The loot method is not Master Looter", 1);
		end
		return
	elseif CEPGP_isML() ~= 0 then
		if (GetLocale() == "zhTW") then
			CEPGP_DFB_print("你不是分裝者.", 1);
		else
			CEPGP_DFB_print("You are not the Loot Master.", 1);
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

-- [[ CEPGP HOOK ]] --
function CEPGP_distribute_popup_give_Hook()
	if not CEPGP_DFB_frame:IsShown() then
		for i = 1, 40 do
			if GetMasterLootCandidate(CEPGP_lootSlot, i) == CEPGP_distPlayer then
				GiveMasterLoot(CEPGP_lootSlot, i);
				return;
			end
		end
		CEPGP_DFB_print(CEPGP_distPlayer .. " is not on the candidate list for loot", true);
		CEPGP_distPlayer = "";
		
	else
		-- local distPlayer = CEPGP_distPlayer
		CEPGP_handleLoot("LOOT_SLOT_CLEARED", 1)
		-- CEPGP_DFB_print("You need give " .. CEPGP_distItemLink .. "|c00FFF569 to |r" .. distPlayer .. "|c00FFF569 MANALLY.|r")
	end
end
local L = LibStub("AceLocale-3.0"):NewLocale("CEPGP_DistributionFromBags", "enUS", true)
if not L then return end

L["Instruction"] = "Shift-Drag an item in inventory to start loot distribution process.\n\nAt the end, you need to give the item to the winner MANUALLY."
L["The loot method is not Master Looter"] = true
L["You are not the Loot Master"] = true
L[" is the winner. Come to trade with me"] = true
L[" is the winner"] = " is the winner.\n\n.Press the [Trade] button near the winner."
L["Wrong Item"] = " can't loot this item."
L["Give GP without Trade confirm"] = "Give GP without Trade confirm\n(If checked, it may happen that GP is given to the person who can't loot)"

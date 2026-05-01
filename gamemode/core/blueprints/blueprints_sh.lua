local PLAYER = FindMetaTable("Player")

function PLAYER:HasBlueprint(item)
    if (gRust.GetConfigValue("crafting/blueprints.enable", true) == false) then return true end
    local register = gRust.GetItemRegister(item)
    if (not register or not register:GetResearchCost()) then return true end
    return self.Blueprints and self.Blueprints[item] or false
end
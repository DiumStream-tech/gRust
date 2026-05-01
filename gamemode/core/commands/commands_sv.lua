local function ItemAutoComplete(cmd, argStr, args)
    if (#args > 1) then return {} end
    local searchItem = string.lower(args[1] or "")

    local items = {}
    for k, v in ipairs(gRust.GetItems()) do
        local itemId = string.lower(v)
        if (string.StartWith(itemId, searchItem)) then
            local completion = string.format("%s %s", cmd, v)
            table.insert(items, completion)
        end
    end

    table.sort(items, function(a, b)
        return string.len(a) < string.len(b)
    end)

    return items
end

local function HasPermission(pl, key)
    if (not gRust.Permissions or not gRust.Permissions.CheckAndNotify) then 
        if (IsValid(pl)) then
            pl:ChatPrint("Error: Permissions system not initialized.")
        end
        return false 
    end
    return gRust.Permissions:CheckAndNotify(pl, key)
end

concommand.Add("grust_giveitem", function(pl, cmd, args)
    if (not HasPermission(pl, "give")) then
        return
    end

    local itemID = args[1]
    local amount = tonumber(args[2]) or 1
    
    if (not itemID) then
        if (IsValid(pl)) then
            pl:ChatPrint("Usage: grust_giveitem <item_id> [amount]")
        end
        return
    end
    
    pl:AddItem(gRust.CreateItem(itemID, amount), ITEM_PICKUP)
    gRust.Log(string.format("%s gave themselves %s x%d", pl:Name(), itemID, amount))
end, ItemAutoComplete, "Give yourself an item")

concommand.Add("grust_multiplier", function(pl, cmd, args)
    if (not HasPermission(pl, "multiplier")) then
        return
    end

    local action = string.lower(args[1] or "get")
    
    if (action == "get") then
        local gather = gRust.GetConfigValue("farming/gather.multiplier", 1)
        local resources = gRust.GetConfigValue("building/resources.multiplier", 1)
        local recycler = gRust.GetConfigValue("recycler/efficiency.multiplier", 1)
        local loot = gRust.GetConfigValue("loot/multiplier", 1)

        local messages = {
            "=== Current Multipliers ===",
            "Gather: " .. gather .. "x",
            "Resources: " .. resources .. "x",
            "Recycler: " .. recycler .. "x",
            "Loot: " .. loot .. "x"
        }
        
        for _, msg in ipairs(messages) do
            if (IsValid(pl)) then
                pl:ChatPrint(msg)
            else
                print("[gRust] " .. msg)
            end
        end
        
    elseif (action == "set") then
        local multiplierType = string.lower(args[2] or "")
        local value = tonumber(args[3])

        if (not multiplierType or not value) then
            local msg = "Usage: grust_multiplier set <type> <value>\nTypes: gather, resources, recycler, loot, all"
            if (IsValid(pl)) then
                pl:ChatPrint(msg)
            else
                print("[gRust] " .. msg)
            end
            return
        end

        if (multiplierType == "all") then
            gRust.SetConfigValue("farming/gather.multiplier", value)
            gRust.SetConfigValue("building/resources.multiplier", value)
            gRust.SetConfigValue("recycler/efficiency.multiplier", value)
            gRust.SetConfigValue("loot/multiplier", value)
            if (IsValid(pl)) then pl:ChatPrint("All multipliers set to " .. value) else print("[gRust] All multipliers set to " .. value) end
        elseif (multiplierType == "gather") then
            gRust.SetConfigValue("farming/gather.multiplier", value)
            if (IsValid(pl)) then pl:ChatPrint("Gather multiplier set to " .. value) else print("[gRust] Gather multiplier set to " .. value) end
        elseif (multiplierType == "resources") then
            gRust.SetConfigValue("building/resources.multiplier", value)
            if (IsValid(pl)) then pl:ChatPrint("Resources multiplier set to " .. value) else print("[gRust] Resources multiplier set to " .. value) end
        elseif (multiplierType == "recycler") then
            gRust.SetConfigValue("recycler/efficiency.multiplier", value)
            if (IsValid(pl)) then pl:ChatPrint("Recycler multiplier set to " .. value) else print("[gRust] Recycler multiplier set to " .. value) end
        elseif (multiplierType == "loot") then
            gRust.SetConfigValue("loot/multiplier", value)
            if (IsValid(pl)) then pl:ChatPrint("Loot multiplier set to " .. value) else print("[gRust] Loot multiplier set to " .. value) end
        else
            if (IsValid(pl)) then pl:ChatPrint("Unknown multiplier type: " .. multiplierType) else print("[gRust] Unknown multiplier type: " .. multiplierType) end
        end
    else
        if (IsValid(pl)) then pl:ChatPrint("Usage: grust_multiplier [get|set] [type] [value]") else print("[gRust] Usage: grust_multiplier [get|set] [type] [value]") end
    end
end)

concommand.Add("grust_reloadconfig", function(pl, cmd, args)
    if (IsValid(pl)) then
        return
    end

    gRust.LoadConfig()
    gRust.LogSuccess("Reloaded config")
end)

concommand.Add("grust_wipe", function(pl, cmd, args)
    if (not HasPermission(pl, "wipe")) then
        return
    end
    
    local bpWipe = args[1] == "1"
    local scheduled = args[2] == "1"

    gRust.Wipe(bpWipe, scheduled)
end)

concommand.Add("grust_save", function(pl, cmd, args)
    if (not HasPermission(pl, "save")) then
        return
    end
    
    gRust.Save(args[1] or "manualsave.dat")
end)

concommand.Add("grust_load", function(pl, cmd, args)
    if (not HasPermission(pl, "load")) then
        return
    end

    for _, ent in ents.Iterator() do
        if (ent.ShouldSave and not ent:CreatedByMap()) then
            ent:Remove()
        end
    end

    gRust.Load(args[1] or "manualsave.dat")
end)

concommand.Add("grust_setpermission", function(pl, cmd, args)
    if (IsValid(pl) and not pl:IsSuperAdmin()) then
        pl:ChatPrint("Only superadmins can change permissions.")
        return
    end

    local permissionKey = args[1]
    local level = args[2]

    if (not permissionKey or not level) then
        local msg = "Usage: grust_setpermission <key> <level>\nLevels: public, user, moderator, admin, superadmin"
        if (IsValid(pl)) then
            pl:ChatPrint(msg)
        else
            MsgC(Color(0, 255, 0), "[gRust] " .. msg .. "\n")
        end
        return
    end

    gRust.SetConfigValue("permissions/" .. permissionKey, level)
    local msg = "Permission '" .. permissionKey .. "' set to '" .. level .. "'"
    if (IsValid(pl)) then
        pl:ChatPrint(msg)
    else
        MsgC(Color(0, 255, 0), "[gRust] " .. msg .. "\n")
    end
end)

concommand.Add("grust_getpermissions", function(pl, cmd, args)
    if (IsValid(pl) and not pl:IsSuperAdmin()) then
        pl:ChatPrint("Only superadmins can view permissions.")
        return
    end

    local messages = {
        "=== Current Permissions ===",
        "give: " .. gRust.GetConfigValue("permissions/give", "admin"),
        "wipe: " .. gRust.GetConfigValue("permissions/wipe", "admin"),
        "save: " .. gRust.GetConfigValue("permissions/save", "admin"),
        "load: " .. gRust.GetConfigValue("permissions/load", "admin"),
        "multiplier: " .. gRust.GetConfigValue("permissions/multiplier", "admin"),
        "config: " .. gRust.GetConfigValue("permissions/config", "admin")
    }
    
    for _, msg in ipairs(messages) do
        if (IsValid(pl)) then
            pl:ChatPrint(msg)
        else
            MsgC(Color(0, 255, 0), "[gRust] " .. msg .. "\n")
        end
    end
end)

concommand.Add("grust_setmultiplier", function(pl, cmd, args)
    if (not HasPermission(pl, "multiplier")) then
        return
    end

    local multiplierType = args[1]
    local value = tonumber(args[2])

    if (not multiplierType or not value) then
        local msg = "Usage: grust_setmultiplier <type> <value>\nTypes: gather, resources, recycler, loot, all"
        if (IsValid(pl)) then
            pl:ChatPrint(msg)
        else
            print("[gRust] " .. msg)
        end
        return
    end

    multiplierType = string.lower(multiplierType)

    if (multiplierType == "all") then
        gRust.SetConfigValue("farming/gather.multiplier", value)
        gRust.SetConfigValue("building/resources.multiplier", value)
        gRust.SetConfigValue("recycler/efficiency.multiplier", value)
        gRust.SetConfigValue("loot/multiplier", value)
        if (IsValid(pl)) then pl:ChatPrint("All multipliers set to " .. value) else print("[gRust] All multipliers set to " .. value) end
    elseif (multiplierType == "gather") then
        gRust.SetConfigValue("farming/gather.multiplier", value)
        if (IsValid(pl)) then pl:ChatPrint("Gather multiplier set to " .. value) else print("[gRust] Gather multiplier set to " .. value) end
    elseif (multiplierType == "resources") then
        gRust.SetConfigValue("building/resources.multiplier", value)
        if (IsValid(pl)) then pl:ChatPrint("Resources multiplier set to " .. value) else print("[gRust] Resources multiplier set to " .. value) end
    elseif (multiplierType == "recycler") then
        gRust.SetConfigValue("recycler/efficiency.multiplier", value)
        if (IsValid(pl)) then pl:ChatPrint("Recycler multiplier set to " .. value) else print("[gRust] Recycler multiplier set to " .. value) end
    elseif (multiplierType == "loot") then
        gRust.SetConfigValue("loot/multiplier", value)
        if (IsValid(pl)) then pl:ChatPrint("Loot multiplier set to " .. value) else print("[gRust] Loot multiplier set to " .. value) end
    else
        if (IsValid(pl)) then pl:ChatPrint("Unknown multiplier type: " .. multiplierType) else print("[gRust] Unknown multiplier type: " .. multiplierType) end
    end
end)

concommand.Add("grust_getmultiplier", function(pl, cmd, args)
    if (not HasPermission(pl, "multiplier")) then
        return
    end

    local gather = gRust.GetConfigValue("farming/gather.multiplier", 1)
    local resources = gRust.GetConfigValue("building/resources.multiplier", 1)
    local recycler = gRust.GetConfigValue("recycler/efficiency.multiplier", 1)
    local loot = gRust.GetConfigValue("loot/multiplier", 1)

    local messages = {
        "=== Current Multipliers ===",
        "Gather: " .. gather .. "x",
        "Resources: " .. resources .. "x",
        "Recycler: " .. recycler .. "x",
        "Loot: " .. loot .. "x"
    }
    
    for _, msg in ipairs(messages) do
        if (IsValid(pl)) then
            pl:ChatPrint(msg)
        else
            print("[gRust] " .. msg)
        end
    end
end)

concommand.Add("grust_stacksize", function(pl, cmd, args)
    if (not HasPermission(pl, "config")) then
        return
    end

    local action = string.lower(args[1] or "")
    
    if (action == "get" or action == "") then
        local messages = {
            "=== Item Stack Sizes ===",
            "Resources:",
            "  wood: " .. gRust.GetConfigValue("items/stacksize/wood", 1000),
            "  stones: " .. gRust.GetConfigValue("items/stacksize/stones", 1000),
            "  metal_ore: " .. gRust.GetConfigValue("items/stacksize/metal_ore", 1000),
            "  hq_metal_ore: " .. gRust.GetConfigValue("items/stacksize/hq_metal_ore", 1000),
            "  sulfur_ore: " .. gRust.GetConfigValue("items/stacksize/sulfur_ore", 1000),
            "Components:",
            "  metal_fragments: " .. gRust.GetConfigValue("items/stacksize/metal_fragments", 1000),
            "  hq_metal: " .. gRust.GetConfigValue("items/stacksize/hq_metal", 500),
            "  sulfur_powder: " .. gRust.GetConfigValue("items/stacksize/sulfur_powder", 1000),
            "  gunpowder: " .. gRust.GetConfigValue("items/stacksize/gunpowder", 500),
            "  scrap: " .. gRust.GetConfigValue("items/stacksize/scrap", 500),
            "Medical:",
            "  bandage: " .. gRust.GetConfigValue("items/stacksize/bandage", 10),
            "Ammunition:",
            "  ammo_556: " .. gRust.GetConfigValue("items/stacksize/ammo_556", 128),
            "  ammo_9mm: " .. gRust.GetConfigValue("items/stacksize/ammo_9mm", 128),
            "  ammo_12gauge: " .. gRust.GetConfigValue("items/stacksize/ammo_12gauge", 64),
        }
        
        for _, msg in ipairs(messages) do
            if (IsValid(pl)) then
                pl:ChatPrint(msg)
            else
                print("[gRust] " .. msg)
            end
        end
        return
    end

    local itemID = action
    local newSize = tonumber(args[2])

    if (not newSize) then
        if (IsValid(pl)) then
            pl:ChatPrint("Usage: grust_stacksize <item_id|all> <size>")
            pl:ChatPrint("Example: grust_stacksize wood 500")
            pl:ChatPrint("Use 'grust_stacksize get' to list all stack sizes")
        end
        return
    end

    if (itemID == "all") then
        gRust.SetConfigValue("items/stacksize/wood", newSize)
        gRust.SetConfigValue("items/stacksize/stones", newSize)
        gRust.SetConfigValue("items/stacksize/metal_ore", newSize)
        gRust.SetConfigValue("items/stacksize/hq_metal_ore", newSize)
        gRust.SetConfigValue("items/stacksize/sulfur_ore", newSize)
        gRust.SetConfigValue("items/stacksize/cloth", newSize)
        gRust.SetConfigValue("items/stacksize/leather", newSize)
        gRust.SetConfigValue("items/stacksize/hemp", newSize)
        gRust.SetConfigValue("items/stacksize/metal_fragments", newSize)
        gRust.SetConfigValue("items/stacksize/hq_metal", newSize)
        gRust.SetConfigValue("items/stacksize/sulfur_powder", newSize)
        gRust.SetConfigValue("items/stacksize/gunpowder", newSize)
        gRust.SetConfigValue("items/stacksize/scrap", newSize)
        
        local msg = "All stack sizes set to " .. newSize
        if (IsValid(pl)) then pl:ChatPrint(msg) else print("[gRust] " .. msg) end
        return
    end

    local configKey = "items/stacksize/" .. itemID
    if (gRust.GetConfigValue(configKey, nil) == nil) then
        if (IsValid(pl)) then
            pl:ChatPrint("Unknown item: " .. itemID)
        end
        return
    end

    gRust.SetConfigValue(configKey, newSize)
    local msg = "Stack size for '" .. itemID .. "' set to " .. newSize
    if (IsValid(pl)) then pl:ChatPrint(msg) else print("[gRust] " .. msg) end
end, nil, "Manage item stack sizes")
-- Chat commands with ! prefix
-- Usage: !command arg1 arg2

local ChatCommands = {}

-- Register chat commands
local function RegisterChatCommand(name, func, permission)
    ChatCommands[string.lower(name)] = {
        func = func,
        permission = permission
    }
end

-- Check permission helper
local function HasPermission(ply, permission)
    if (not IsValid(ply)) then return false end
    if (not permission) then return true end
    if (not gRust.Permissions or not gRust.Permissions.HasPermission) then
        -- Fallback if permissions system not ready
        return ply:IsSuperAdmin() or ply:IsAdmin()
    end
    return gRust.Permissions:HasPermission(ply, permission)
end

-- Parse and execute chat commands
hook.Add("PlayerSay", "gRust.ChatCommands", function(ply, text)
    if (not IsValid(ply)) then return end
    if (string.sub(text, 1, 1) ~= "!") then return end
    
    local parts = string.Explode(" ", text)
    local cmd = string.lower(string.sub(parts[1], 2)) -- Remove ! and lowercase
    local args = {}
    for i = 2, #parts do
        table.insert(args, parts[i])
    end
    
    local chatCmd = ChatCommands[cmd]
    if (not chatCmd) then return end
    
    -- Check permission if required
    if (not HasPermission(ply, chatCmd.permission)) then
        ply:ChatPrint("You don't have permission to use this command")
        return false
    end
    
    chatCmd.func(ply, cmd, args)
    return false -- Don't broadcast the command
end)

-- Command: !multiplier or !mult
RegisterChatCommand("multiplier", function(ply, cmd, args)
    local action = string.lower(args[1] or "get")
    
    if (action == "get" or action == "") then
        local gather = gRust.GetConfigValue("farming/gather.multiplier", 1)
        local resources = gRust.GetConfigValue("building/resources.multiplier", 1)
        local recycler = gRust.GetConfigValue("recycler/efficiency.multiplier", 1)
        local loot = gRust.GetConfigValue("loot/multiplier", 1)

        ply:ChatPrint("=== Current Multipliers ===")
        ply:ChatPrint("Gather: " .. gather .. "x")
        ply:ChatPrint("Resources: " .. resources .. "x")
        ply:ChatPrint("Recycler: " .. recycler .. "x")
        ply:ChatPrint("Loot: " .. loot .. "x")
        return
    end

    local multiplierType = string.lower(action)
    local value = tonumber(args[2])

    if (not value) then
        ply:ChatPrint("Usage: !multiplier <type> <value>")
        ply:ChatPrint("Types: gather, resources, recycler, loot, all")
        return
    end

    if (multiplierType == "all") then
        gRust.SetConfigValue("farming/gather.multiplier", value)
        gRust.SetConfigValue("building/resources.multiplier", value)
        gRust.SetConfigValue("recycler/efficiency.multiplier", value)
        gRust.SetConfigValue("loot/multiplier", value)
        ply:ChatPrint("All multipliers set to " .. value)
    elseif (multiplierType == "gather") then
        gRust.SetConfigValue("farming/gather.multiplier", value)
        ply:ChatPrint("Gather multiplier set to " .. value)
    elseif (multiplierType == "resources") then
        gRust.SetConfigValue("building/resources.multiplier", value)
        ply:ChatPrint("Resources multiplier set to " .. value)
    elseif (multiplierType == "recycler") then
        gRust.SetConfigValue("recycler/efficiency.multiplier", value)
        ply:ChatPrint("Recycler multiplier set to " .. value)
    elseif (multiplierType == "loot") then
        gRust.SetConfigValue("loot/multiplier", value)
        ply:ChatPrint("Loot multiplier set to " .. value)
    else
        ply:ChatPrint("Unknown multiplier type: " .. multiplierType)
    end
end, "multiplier")

RegisterChatCommand("mult", function(ply, cmd, args)
    ChatCommands.multiplier.func(ply, cmd, args)
end, "multiplier")

-- Command: !giveitem or !give
RegisterChatCommand("giveitem", function(ply, cmd, args)
    local itemID = args[1]
    local amount = tonumber(args[2]) or 1
    
    if (not itemID) then
        ply:ChatPrint("Usage: !giveitem <item_id> [amount]")
        return
    end
    
    ply:AddItem(gRust.CreateItem(itemID, amount), ITEM_PICKUP)
    gRust.Log(string.format("%s gave themselves %s x%d via chat", ply:Name(), itemID, amount))
end, "give")

RegisterChatCommand("give", function(ply, cmd, args)
    ChatCommands.giveitem.func(ply, cmd, args)
end, "give")

-- Command: !wipe
RegisterChatCommand("wipe", function(ply, cmd, args)
    local wipeType = string.lower(args[1] or "all")
    
    if (wipeType == "all") then
        gRust.WipeAll()
        ply:ChatPrint("Wiping all gRust data...")
    elseif (wipeType == "config") then
        gRust.WipeConfig()
        ply:ChatPrint("Wiping config data...")
    else
        ply:ChatPrint("Usage: !wipe [all|config]")
    end
end, "config")

-- Command: !save
RegisterChatCommand("save", function(ply, cmd, args)
    gRust.SaveConfig()
    ply:ChatPrint("Config saved")
end, "config")

-- Command: !load
RegisterChatCommand("load", function(ply, cmd, args)
    gRust.LoadConfig()
    ply:ChatPrint("Config loaded")
end, "config")

-- Command: !perm
RegisterChatCommand("perm", function(ply, cmd, args)
    local action = string.lower(args[1] or "get")
    
    if (action == "get") then
        ply:ChatPrint("=== Current Permissions ===")
        ply:ChatPrint("give: " .. gRust.GetConfigValue("permissions/give", "admin"))
        ply:ChatPrint("wipe: " .. gRust.GetConfigValue("permissions/wipe", "admin"))
        ply:ChatPrint("save: " .. gRust.GetConfigValue("permissions/save", "admin"))
        ply:ChatPrint("load: " .. gRust.GetConfigValue("permissions/load", "admin"))
        ply:ChatPrint("multiplier: " .. gRust.GetConfigValue("permissions/multiplier", "admin"))
        ply:ChatPrint("config: " .. gRust.GetConfigValue("permissions/config", "admin"))
        return
    end

    local key = args[2]
    local level = args[3]

    if (not key or not level) then
        ply:ChatPrint("Usage: !perm set <key> <level>")
        ply:ChatPrint("Levels: public, user, moderator, admin, superadmin")
        return
    end

    if (action == "set") then
        gRust.SetConfigValue("permissions/" .. key, string.lower(level))
        ply:ChatPrint("Permission '" .. key .. "' set to " .. level)
    else
        ply:ChatPrint("Usage: !perm [get|set] [key] [level]")
    end
end, "config")

-- Command: !grust help
RegisterChatCommand("grust", function(ply, cmd, args)
    local action = string.lower(args[1] or "help")
    
    if (action == "help") then
        ply:ChatPrint("=== gRust Commands ===")
        ply:ChatPrint("")
        ply:ChatPrint("Multiplier Commands:")
        ply:ChatPrint("  !multiplier get - Show current multipliers")
        ply:ChatPrint("  !multiplier gather <value> - Set gather multiplier")
        ply:ChatPrint("  !multiplier resources <value> - Set resources multiplier")
        ply:ChatPrint("  !multiplier recycler <value> - Set recycler multiplier")
        ply:ChatPrint("  !multiplier loot <value> - Set loot multiplier")
        ply:ChatPrint("  !multiplier all <value> - Set all multipliers")
        ply:ChatPrint("  !mult <type> <value> - Shortcut for multiplier")
        ply:ChatPrint("")
        ply:ChatPrint("Item Commands:")
        ply:ChatPrint("  !giveitem <item_id> [amount] - Give yourself an item")
        ply:ChatPrint("  !give <item_id> [amount] - Shortcut for giveitem")
        ply:ChatPrint("")
        ply:ChatPrint("Config Commands:")
        ply:ChatPrint("  !save - Save current config")
        ply:ChatPrint("  !load - Load config from disk")
        ply:ChatPrint("  !wipe all - Wipe all data")
        ply:ChatPrint("  !wipe config - Wipe config only")
        ply:ChatPrint("  !perm get - Show all permissions")
        ply:ChatPrint("  !perm set <key> <level> - Set permission level")
        ply:ChatPrint("")
        ply:ChatPrint("Use !grust help for this message")
        return
    end
    
    ply:ChatPrint("Usage: !grust help")
end)

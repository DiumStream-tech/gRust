-- ============================================================
-- gRust - commands_sv.lua (PATCHÉ)
-- Corrections :
--   [CRITIQUE] Path traversal dans grust_save / grust_load
--   [CRITIQUE] Injection de clé config dans grust_setpermission
--   [BUG]      Commandes grust_setmultiplier et grust_multiplier dupliquées → fusionnées
--   [BUG]      grust_wipe : paramètres alignés avec la doc (bpWipe, scheduled)
-- ============================================================

-- ============================================================
-- Helpers internes
-- ============================================================

-- [PATCH CRITIQUE] Sanitise un nom de fichier de sauvegarde.
-- Autorise uniquement les caractères alphanumériques, tirets et underscores.
-- Empêche le path traversal (../, /, etc.)
local function SanitizeSaveFilename(raw)
    if (not raw or raw == "") then return "manualsave.dat" end
    local clean = string.match(raw, "^([%w_%-]+)$")
    if (not clean) then return nil end
    return clean .. ".dat"
end

-- [PATCH CRITIQUE] Whitelist des clés de permission valides.
-- Empêche l'injection de clés arbitraires via grust_setpermission.
local VALID_PERMISSION_KEYS = {
    ["give"]       = true,
    ["wipe"]       = true,
    ["save"]       = true,
    ["load"]       = true,
    ["multiplier"] = true,
    ["config"]     = true,
    ["devmenu"]    = true,
}

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

-- ============================================================
-- grust_giveitem
-- ============================================================

concommand.Add("grust_giveitem", function(pl, cmd, args)
    if (not IsValid(pl)) then return end

    if (not HasPermission(pl, "give")) then
        return
    end

    local itemID = args[1]
    local amount = tonumber(args[2]) or 1

    if (not itemID) then
        pl:ChatPrint("Usage: grust_giveitem <item_id> [amount]")
        return
    end

    -- [PATCH] Clamp du montant pour éviter les abus
    amount = math.Clamp(amount, 1, 10000)

    local item = gRust.CreateItem(itemID, amount)
    if (item) then
        pl:AddItem(item, ITEM_PICKUP)
        gRust.Log(string.format("%s gave themselves %s x%d", pl:Name(), itemID, amount))
    else
        pl:ChatPrint("Invalid Item ID: " .. itemID)
    end
end, ItemAutoComplete, "Give yourself an item")

-- ============================================================
-- grust_multiplier  (get | set <type> <valeur>)
-- [PATCH BUG] Fusion de grust_multiplier et grust_setmultiplier
--             en une seule implémentation interne pour éviter
--             la duplication de code.
-- ============================================================

local MULTIPLIER_CONFIG_KEYS = {
    ["gather"]    = "farming/gather.multiplier",
    ["resources"] = "building/resources.multiplier",
    ["recycler"]  = "recycler/efficiency.multiplier",
    ["loot"]      = "loot/multiplier",
}

local function GetMultipliers()
    return {
        gather    = gRust.GetConfigValue("farming/gather.multiplier", 1),
        resources = gRust.GetConfigValue("building/resources.multiplier", 1),
        recycler  = gRust.GetConfigValue("recycler/efficiency.multiplier", 1),
        loot      = gRust.GetConfigValue("loot/multiplier", 1),
    }
end

local function PrintMultipliers(pl)
    local m = GetMultipliers()
    local lines = {
        "=== Current Multipliers ===",
        "Gather: "    .. m.gather    .. "x",
        "Resources: " .. m.resources .. "x",
        "Recycler: "  .. m.recycler  .. "x",
        "Loot: "      .. m.loot      .. "x",
    }
    for _, msg in ipairs(lines) do
        if (IsValid(pl)) then pl:ChatPrint(msg) else print("[gRust] " .. msg) end
    end
end

local function SetMultiplier(pl, multiplierType, value)
    if (multiplierType == "all") then
        for _, configKey in pairs(MULTIPLIER_CONFIG_KEYS) do
            gRust.SetConfigValue(configKey, value)
        end
        local msg = "All multipliers set to " .. value
        if (IsValid(pl)) then pl:ChatPrint(msg) else print("[gRust] " .. msg) end
    elseif (MULTIPLIER_CONFIG_KEYS[multiplierType]) then
        gRust.SetConfigValue(MULTIPLIER_CONFIG_KEYS[multiplierType], value)
        local msg = multiplierType .. " multiplier set to " .. value
        if (IsValid(pl)) then pl:ChatPrint(msg) else print("[gRust] " .. msg) end
    else
        local msg = "Unknown multiplier type: " .. multiplierType
        if (IsValid(pl)) then pl:ChatPrint(msg) else print("[gRust] " .. msg) end
    end
end

concommand.Add("grust_multiplier", function(pl, cmd, args)
    if (not HasPermission(pl, "multiplier")) then return end

    local action = string.lower(args[1] or "get")

    if (action == "get") then
        PrintMultipliers(pl)
    elseif (action == "set") then
        local multiplierType = string.lower(args[2] or "")
        local value = tonumber(args[3])

        if (not multiplierType or multiplierType == "" or not value) then
            local msg = "Usage: grust_multiplier set <type> <value>\nTypes: gather, resources, recycler, loot, all"
            if (IsValid(pl)) then pl:ChatPrint(msg) else print("[gRust] " .. msg) end
            return
        end

        -- [PATCH] Clamp de la valeur pour éviter les multipliers absurdes
        value = math.Clamp(value, 0.01, 1000)
        SetMultiplier(pl, multiplierType, value)
    else
        local msg = "Usage: grust_multiplier [get|set] [type] [value]"
        if (IsValid(pl)) then pl:ChatPrint(msg) else print("[gRust] " .. msg) end
    end
end)

-- ============================================================
-- grust_setmultiplier  (conservé pour rétrocompatibilité,
--                       délègue maintenant à SetMultiplier)
-- ============================================================

concommand.Add("grust_setmultiplier", function(pl, cmd, args)
    if (not HasPermission(pl, "multiplier")) then return end

    local multiplierType = args[1]
    local value = tonumber(args[2])

    if (not multiplierType or not value) then
        local msg = "Usage: grust_setmultiplier <type> <value>\nTypes: gather, resources, recycler, loot, all"
        if (IsValid(pl)) then pl:ChatPrint(msg) else print("[gRust] " .. msg) end
        return
    end

    -- [PATCH] Clamp de la valeur
    value = math.Clamp(value, 0.01, 1000)
    SetMultiplier(pl, string.lower(multiplierType), value)
end)

-- ============================================================
-- grust_getmultiplier  (conservé pour rétrocompatibilité)
-- ============================================================

concommand.Add("grust_getmultiplier", function(pl, cmd, args)
    if (not HasPermission(pl, "multiplier")) then return end
    PrintMultipliers(pl)
end)

-- ============================================================
-- grust_reloadconfig  (console uniquement)
-- ============================================================

concommand.Add("grust_reloadconfig", function(pl, cmd, args)
    if (IsValid(pl)) then return end

    gRust.LoadConfig()
    gRust.LogSuccess("Reloaded config")
end)

-- ============================================================
-- grust_wipe
-- [PATCH BUG] Paramètres alignés avec la doc :
--             grust_wipe [bpWipe] [scheduled]
--             bpWipe    : 1 = wipe blueprints aussi, 0 = world seulement
--             scheduled : 1 = wipe programmé, 0 = manuel
-- ============================================================

concommand.Add("grust_wipe", function(pl, cmd, args)
    if (not HasPermission(pl, "wipe")) then return end

    local bpWipe   = (tonumber(args[1]) or 0) == 1
    local scheduled = (tonumber(args[2]) or 0) == 1

    local msg = string.format(
        "Wiping server (bpWipe=%s, scheduled=%s)...",
        tostring(bpWipe), tostring(scheduled)
    )
    if (IsValid(pl)) then pl:ChatPrint(msg) else print("[gRust] " .. msg) end

    gRust.Wipe(bpWipe, scheduled)
end)

-- ============================================================
-- grust_save
-- [PATCH CRITIQUE] Sanitisation du nom de fichier
-- ============================================================

concommand.Add("grust_save", function(pl, cmd, args)
    if (not HasPermission(pl, "save")) then return end

    local filename = SanitizeSaveFilename(args[1])
    if (not filename) then
        local msg = "Nom de fichier invalide. Utilisez uniquement des lettres, chiffres, - et _"
        if (IsValid(pl)) then pl:ChatPrint(msg) else print("[gRust] " .. msg) end
        return
    end

    gRust.Save(filename)
    local msg = "Sauvegarde effectuée : " .. filename
    if (IsValid(pl)) then pl:ChatPrint(msg) else print("[gRust] " .. msg) end
end)

-- ============================================================
-- grust_load
-- [PATCH CRITIQUE] Sanitisation du nom de fichier
-- ============================================================

concommand.Add("grust_load", function(pl, cmd, args)
    if (not HasPermission(pl, "load")) then return end

    local filename = SanitizeSaveFilename(args[1])
    if (not filename) then
        local msg = "Nom de fichier invalide. Utilisez uniquement des lettres, chiffres, - et _"
        if (IsValid(pl)) then pl:ChatPrint(msg) else print("[gRust] " .. msg) end
        return
    end

    for _, ent in ents.Iterator() do
        if (ent.ShouldSave and not ent:CreatedByMap()) then
            ent:Remove()
        end
    end

    gRust.Load(filename)
    local msg = "Chargement effectué : " .. filename
    if (IsValid(pl)) then pl:ChatPrint(msg) else print("[gRust] " .. msg) end
end)

-- ============================================================
-- grust_setpermission
-- [PATCH CRITIQUE] Whitelist des clés de permission valides
-- ============================================================

concommand.Add("grust_setpermission", function(pl, cmd, args)
    if (IsValid(pl) and not pl:IsSuperAdmin()) then
        pl:ChatPrint("Only superadmins can change permissions.")
        return
    end

    local permissionKey = args[1]
    local level = args[2]

    if (not permissionKey or not level) then
        local msg = "Usage: grust_setpermission <key> <level>\nLevels: public, user, moderator, admin, superadmin"
        if (IsValid(pl)) then pl:ChatPrint(msg) else MsgC(Color(0, 255, 0), "[gRust] " .. msg .. "\n") end
        return
    end

    -- [PATCH] Validation de la clé via whitelist
    if (not VALID_PERMISSION_KEYS[permissionKey]) then
        local validList = table.concat(table.GetKeys(VALID_PERMISSION_KEYS), ", ")
        local msg = "Clé invalide : '" .. permissionKey .. "'. Clés valides : " .. validList
        if (IsValid(pl)) then pl:ChatPrint(msg) else MsgC(Color(255, 100, 0), "[gRust] " .. msg .. "\n") end
        return
    end

    -- [PATCH] Validation du niveau
    local VALID_LEVELS = { public=true, user=true, moderator=true, admin=true, superadmin=true }
    if (not VALID_LEVELS[level]) then
        local msg = "Niveau invalide : '" .. level .. "'. Niveaux valides : public, user, moderator, admin, superadmin"
        if (IsValid(pl)) then pl:ChatPrint(msg) else MsgC(Color(255, 100, 0), "[gRust] " .. msg .. "\n") end
        return
    end

    gRust.SetConfigValue("permissions/" .. permissionKey, level)
    local msg = "Permission '" .. permissionKey .. "' set to '" .. level .. "'"
    if (IsValid(pl)) then pl:ChatPrint(msg) else MsgC(Color(0, 255, 0), "[gRust] " .. msg .. "\n") end
end)

-- ============================================================
-- grust_getpermissions
-- ============================================================

concommand.Add("grust_getpermissions", function(pl, cmd, args)
    if (IsValid(pl) and not pl:IsSuperAdmin()) then
        pl:ChatPrint("Only superadmins can view permissions.")
        return
    end

    local lines = { "=== Current Permissions ===" }
    for key, _ in pairs(VALID_PERMISSION_KEYS) do
        table.insert(lines, key .. ": " .. gRust.GetConfigValue("permissions/" .. key, "admin"))
    end

    for _, msg in ipairs(lines) do
        if (IsValid(pl)) then pl:ChatPrint(msg) else MsgC(Color(0, 255, 0), "[gRust] " .. msg .. "\n") end
    end
end)

-- ============================================================
-- grust_stacksize
-- [PATCH BUG] Vérification d'existence de clé corrigée
--             (utilise une whitelist explicite au lieu de tester nil)
-- ============================================================

local VALID_STACK_ITEMS = {
    "wood", "stones", "metal_ore", "hq_metal_ore", "sulfur_ore",
    "cloth", "leather", "hemp",
    "metal_fragments", "hq_metal", "sulfur_powder", "gunpowder", "scrap",
    "bandage",
    "ammo_556", "ammo_9mm", "ammo_12gauge",
}

-- Convertit la liste en set pour lookup O(1)
local VALID_STACK_SET = {}
for _, v in ipairs(VALID_STACK_ITEMS) do
    VALID_STACK_SET[v] = true
end

concommand.Add("grust_stacksize", function(pl, cmd, args)
    if (not HasPermission(pl, "config")) then return end

    local action = string.lower(args[1] or "")

    if (action == "get" or action == "") then
        local lines = { "=== Item Stack Sizes ===" }

        local categories = {
            { "Resources:", { "wood", "stones", "metal_ore", "hq_metal_ore", "sulfur_ore" } },
            { "Misc:",      { "cloth", "leather", "hemp" } },
            { "Components:", { "metal_fragments", "hq_metal", "sulfur_powder", "gunpowder", "scrap" } },
            { "Medical:",   { "bandage" } },
            { "Ammunition:", { "ammo_556", "ammo_9mm", "ammo_12gauge" } },
        }

        for _, cat in ipairs(categories) do
            table.insert(lines, cat[1])
            for _, itemID in ipairs(cat[2]) do
                table.insert(lines, "  " .. itemID .. ": " .. gRust.GetConfigValue("items/stacksize/" .. itemID, "?"))
            end
        end

        for _, msg in ipairs(lines) do
            if (IsValid(pl)) then pl:ChatPrint(msg) else print("[gRust] " .. msg) end
        end
        return
    end

    local itemID  = action
    local newSize = tonumber(args[2])

    if (not newSize) then
        if (IsValid(pl)) then
            pl:ChatPrint("Usage: grust_stacksize <item_id|all> <size>")
            pl:ChatPrint("Example: grust_stacksize wood 500")
            pl:ChatPrint("Use 'grust_stacksize get' to list all stack sizes")
        end
        return
    end

    -- [PATCH] Clamp de la taille de stack
    newSize = math.Clamp(math.floor(newSize), 1, 100000)

    if (itemID == "all") then
        for _, id in ipairs(VALID_STACK_ITEMS) do
            gRust.SetConfigValue("items/stacksize/" .. id, newSize)
        end
        local msg = "All stack sizes set to " .. newSize
        if (IsValid(pl)) then pl:ChatPrint(msg) else print("[gRust] " .. msg) end
        return
    end

    -- [PATCH BUG] Vérification via whitelist explicite (pas via GetConfigValue == nil)
    if (not VALID_STACK_SET[itemID]) then
        local msg = "Unknown item: '" .. itemID .. "'. Use 'grust_stacksize get' to see valid items."
        if (IsValid(pl)) then pl:ChatPrint(msg) else print("[gRust] " .. msg) end
        return
    end

    gRust.SetConfigValue("items/stacksize/" .. itemID, newSize)
    local msg = "Stack size for '" .. itemID .. "' set to " .. newSize
    if (IsValid(pl)) then pl:ChatPrint(msg) else print("[gRust] " .. msg) end
end, nil, "Manage item stack sizes")
gRust.Permissions = gRust.Permissions or {}

util.AddNetworkString("gRust.CheckPermission")
util.AddNetworkString("gRust.PermissionDenied")
util.AddNetworkString("gRust.RequestSpawnItem")


local PERMISSION_LEVELS = {
    ["public"]     = 0,
    ["user"]       = 1,
    ["moderator"]  = 2,
    ["admin"]      = 3,
    ["superadmin"] = 4,
}

local SAM_RANK_MAP = {
    ["superadmin"]    = 4,
    ["super admin"]   = 4,
    ["owner"]         = 4,
    ["co-owner"]      = 4,
    ["co owner"]      = 4,

    ["admin"]         = 3,
    ["administrator"] = 3,
    ["headadmin"]     = 3,
    ["head admin"]    = 3,

    ["moderator"]     = 2,
    ["mod"]           = 2,
    ["headmod"]       = 2,
    ["head mod"]      = 2,
    ["staff"]         = 2,
    ["helper"]        = 2,

    ["vip"]           = 1,
    ["member"]        = 1,
    ["user"]          = 1,
    ["player"]        = 1,

    ["guest"]         = 0,
    ["public"]        = 0,
    ["default"]       = 0,
}

function gRust.Permissions:GetPlayerLevel(ply)
    if (not IsValid(ply)) then return PERMISSION_LEVELS["public"] end

    if (ply.GetUserGroup) then
        local userGroup = string.lower(ply:GetUserGroup() or "")
        if (PERMISSION_LEVELS[userGroup] ~= nil) then
            return PERMISSION_LEVELS[userGroup]
        end

        local mappedLevel = SAM_RANK_MAP[userGroup]
        if (mappedLevel ~= nil) then
            return mappedLevel
        end
    end

    if (sam and sam.get_player_rank) then
        local ok, rank = pcall(sam.get_player_rank, ply)
        if (ok and rank and rank.name) then
            local rankName = string.lower(rank.name)
            local level = SAM_RANK_MAP[rankName]
            if (level ~= nil) then
                return level
            end

            gRust.Log(
                "[Permissions] Rang SAM inconnu : '" .. rank.name ..
                "' pour " .. ply:Name() ..
                " — ajoutez-le dans SAM_RANK_MAP dans permissions_sv.lua"
            )
        end
    end

    if (ply:IsSuperAdmin()) then
        return PERMISSION_LEVELS["superadmin"]
    elseif (ply:IsAdmin()) then
        return PERMISSION_LEVELS["admin"]
    end

    return PERMISSION_LEVELS["user"]
end


function gRust.Permissions:HasPermission(ply, permissionKey)
    local configValue = gRust.GetConfigValue("permissions/" .. permissionKey, "admin")
    local requiredLevel = PERMISSION_LEVELS[configValue] or 4
    local playerLevel = self:GetPlayerLevel(ply)
    return playerLevel >= requiredLevel
end

function gRust.Permissions:CheckAndNotify(ply, permissionKey)
    if (not self:HasPermission(ply, permissionKey)) then
        if (IsValid(ply)) then
            local required = gRust.GetConfigValue("permissions/" .. permissionKey, "admin")
            ply:ChatPrint(
                "Accès Refusé: Vous n'avez pas le grade requis (" .. required .. ")"
            )
        end
        return false
    end
    return true
end

net.Receive("gRust.CheckPermission", function(len, ply)
    local permissionKey = net.ReadString()
    if (not permissionKey or string.len(permissionKey) == 0 or string.len(permissionKey) > 64) then
        return
    end

    local hasPermission = gRust.Permissions:HasPermission(ply, permissionKey)

    net.Start("gRust.PermissionDenied")
        net.WriteBool(hasPermission)
        net.WriteString(permissionKey)
    net.Send(ply)
end)

local SPAWN_RATE_LIMIT = 0.5

net.Receive("gRust.RequestSpawnItem", function(len, ply)
    if (not IsValid(ply)) then return end

    if (ply._lastSpawnRequest and CurTime() - ply._lastSpawnRequest < SPAWN_RATE_LIMIT) then
        return
    end
    ply._lastSpawnRequest = CurTime()

    local itemId = net.ReadString()
    local amount = net.ReadUInt(16)

    if (not itemId or string.len(itemId) == 0 or string.len(itemId) > 64) then return end
    amount = math.Clamp(amount, 1, 10000)

    if (not gRust.Permissions:CheckAndNotify(ply, "give")) then return end

    local item = gRust.CreateItem(itemId, amount)
    if (item) then
        ply:AddItem(item, ITEM_PICKUP)
        gRust.Log(string.format(
            "[gRust] %s a spawné %s x%d via RequestSpawnItem",
            ply:Name(), itemId, amount
        ))
    else
        ply:ChatPrint("Invalid Item ID: " .. itemId)
    end
end)

hook.Add("gRust.Loaded", "gRust.InitPermissions", function()
    gRust.CreateConfigValue("permissions/give",       "admin")
    gRust.CreateConfigValue("permissions/wipe",       "admin")
    gRust.CreateConfigValue("permissions/save",       "admin")
    gRust.CreateConfigValue("permissions/load",       "admin")
    gRust.CreateConfigValue("permissions/multiplier", "admin")
    gRust.CreateConfigValue("permissions/config",     "admin")
    gRust.CreateConfigValue("permissions/devmenu",    "admin")
end)
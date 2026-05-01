gRust.Permissions = gRust.Permissions or {}

util.AddNetworkString("gRust.CheckPermission")
util.AddNetworkString("gRust.PermissionDenied")
util.AddNetworkString("gRust.RequestSpawnItem")

local PERMISSION_LEVELS = {
    ["public"] = 0,
    ["user"] = 1,
    ["moderator"] = 2,
    ["admin"] = 3,
    ["superadmin"] = 4
}

function gRust.Permissions:GetPlayerLevel(ply)
    if (not IsValid(ply)) then return PERMISSION_LEVELS["public"] end
    
    if (ulx and ply.GetUserGroup) then
        local userGroup = ply:GetUserGroup()
        if (PERMISSION_LEVELS[userGroup]) then
            return PERMISSION_LEVELS[userGroup]
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
    local requiredLevelNum = PERMISSION_LEVELS[configValue] or 4
    local playerLevel = self:GetPlayerLevel(ply)
    
    return playerLevel >= requiredLevelNum
end

function gRust.Permissions:CheckAndNotify(ply, permissionKey)
    if (not self:HasPermission(ply, permissionKey)) then
        if (IsValid(ply)) then
            ply:ChatPrint("Accès Refusé: Vous n'avez pas le grade requis (" .. gRust.GetConfigValue("permissions/" .. permissionKey, "admin") .. ")")
        end
        return false
    end
    return true
end

net.Receive("gRust.CheckPermission", function(len, ply)
    local permissionKey = net.ReadString()
    local hasPermission = gRust.Permissions:HasPermission(ply, permissionKey)
    
    net.Start("gRust.PermissionDenied")
        net.WriteBool(hasPermission)
        net.WriteString(permissionKey)
    net.Send(ply)
end)

net.Receive("gRust.RequestSpawnItem", function(len, ply)
    if (not IsValid(ply)) then return end
    
    local itemId = net.ReadString()
    local amount = net.ReadUInt(16)

    if (gRust.Permissions:CheckAndNotify(ply, "give")) then
        concommand.Run(ply, "grust_giveitem", {itemId, tostring(amount)})
    end
end)

hook.Add("gRust.Loaded", "gRust.InitPermissions", function()
    gRust.CreateConfigValue("permissions/give", "admin")
    gRust.CreateConfigValue("permissions/wipe", "admin")
    gRust.CreateConfigValue("permissions/save", "admin")
    gRust.CreateConfigValue("permissions/load", "admin")
    gRust.CreateConfigValue("permissions/multiplier", "admin")
    gRust.CreateConfigValue("permissions/config", "admin")
    gRust.CreateConfigValue("permissions/devmenu", "admin")
end)
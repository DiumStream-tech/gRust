gRust.Permissions = gRust.Permissions or {}

util.AddNetworkString("gRust.CheckPermission")
util.AddNetworkString("gRust.PermissionDenied")

local PERMISSION_LEVELS = {
    ["public"] = 0,
    ["user"] = 1,
    ["moderator"] = 2,
    ["admin"] = 3,
    ["superadmin"] = 4
}

function gRust.Permissions:GetPlayerLevel(ply)
    if (not IsValid(ply)) then return PERMISSION_LEVELS["superadmin"] end
    
    if (ulx and ply.GetUserGroup and ply.IsUserGroup) then
        local userGroup = ply:GetUserGroup()
        if (userGroup == "superadmin") then
            return PERMISSION_LEVELS["superadmin"]
        elseif (userGroup == "admin") then
            return PERMISSION_LEVELS["admin"]
        elseif (userGroup == "moderator") then
            return PERMISSION_LEVELS["moderator"]
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
    local requiredLevel = gRust.GetConfigValue("permissions/" .. permissionKey, "admin")
    local requiredLevelNum = PERMISSION_LEVELS[requiredLevel] or PERMISSION_LEVELS["admin"]
    local playerLevel = self:GetPlayerLevel(ply)
    
    return playerLevel >= requiredLevelNum
end

function gRust.Permissions:CheckAndNotify(ply, permissionKey)
    if (not self:HasPermission(ply, permissionKey)) then
        if (IsValid(ply)) then
            ply:ChatPrint("You do not have permission to use this command.")
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
    net.Send(ply)
end)

hook.Add("gRust.Loaded", "gRust.InitPermissions", function()
    gRust.CreateConfigValue("permissions/give", "admin")
    gRust.CreateConfigValue("permissions/wipe", "admin")
    gRust.CreateConfigValue("permissions/save", "admin")
    gRust.CreateConfigValue("permissions/load", "admin")
    gRust.CreateConfigValue("permissions/multiplier", "admin")
    gRust.CreateConfigValue("permissions/config", "admin")
end)
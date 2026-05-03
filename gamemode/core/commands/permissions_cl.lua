gRust.PermissionsClient = gRust.PermissionsClient or {}

local pendingCallbacks = {}

gRust.PermissionsClient.Handlers = gRust.PermissionsClient.Handlers or {}

net.Receive("gRust.PermissionDenied", function()
    local hasPermission = net.ReadBool()
    local permissionKey = net.ReadString()

    gRust.PermissionsClient.hasPermission = hasPermission

    if (pendingCallbacks[permissionKey]) then
        for _, cb in ipairs(pendingCallbacks[permissionKey]) do
            cb(hasPermission, permissionKey)
        end
        pendingCallbacks[permissionKey] = nil
    end

    for _, handler in ipairs(gRust.PermissionsClient.Handlers) do
        handler(hasPermission, permissionKey)
    end
end)

function gRust.PermissionsClient:AddHandler(fn)
    table.insert(self.Handlers, fn)
end

function gRust.PermissionsClient:CheckPermission(key, callback)
    if (not key or key == "") then
        if (callback) then callback(false, key) end
        return false
    end

    if (callback) then
        if (not pendingCallbacks[key]) then
            pendingCallbacks[key] = {}
        end
        table.insert(pendingCallbacks[key], callback)
    end

    net.Start("gRust.CheckPermission")
        net.WriteString(key)
    net.SendToServer()

    return self.hasPermission
end
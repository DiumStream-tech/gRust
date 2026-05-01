gRust.Config = gRust.Config or {}

net.Receive("gRust.SyncConfig", function(len)
    local strLen = net.ReadUInt(32)
    local data = net.ReadData(strLen)
    local decompressed = util.Decompress(data)

    if (not decompressed) then return end

    local tbl = util.JSONToTable(decompressed)
    if (tbl) then
        gRust.Config = tbl
        hook.Run("gRust.ConfigUpdated")
        hook.Run("gRust.ConfigInitialized")
    end
end)

function gRust.GetConfigValue(key, default)
    local value = gRust.Config[key]
    if (value == nil) then
        return default
    end

    return value
end

hook.Add("gRust.Loaded", "gRust.Config", function()
    if (IsValid(LocalPlayer()) and LocalPlayer().NetworkReady) then
        hook.Run("gRust.ConfigInitialized")
    end
end)
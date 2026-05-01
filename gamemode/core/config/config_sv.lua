local CONFIG_DIR = "grust/config/"

if (not file.Exists(CONFIG_DIR, "DATA")) then
    file.CreateDir(CONFIG_DIR)
end

gRust.Config = gRust.Config or {}
gRust.NetworkedConfig = gRust.NetworkedConfig or {}
gRust.ConfigLoaded = false

util.AddNetworkString("gRust.SyncConfig")

local function SyncToAll()
    local str = util.TableToJSON(gRust.NetworkedConfig)
    local compressed = util.Compress(str)
    local len = #compressed

    net.Start("gRust.SyncConfig")
        net.WriteUInt(len, 32)
        net.WriteData(compressed, len)
    net.Broadcast()
end

function gRust.GetConfigValue(key, default)
    local parts = string.Split(key, "/")
    local fileName = parts[1]
    local keyName = parts[2]

    if (not fileName or not keyName) then
        return default
    end

    if (not gRust.Config[fileName]) then
        gRust.Config[fileName] = {}
    end

    local value = gRust.Config[fileName][keyName]

    if (value ~= nil) then
        return value
    end

    local filePath = CONFIG_DIR .. fileName .. ".json"
    if (file.Exists(filePath, "DATA")) then
        local fileData = file.Read(filePath, "DATA")
        if (fileData and fileData ~= "") then
            local decoded = util.JSONToTable(fileData)
            if (decoded) then
                gRust.Config[fileName] = decoded
                if (gRust.Config[fileName][keyName] ~= nil) then
                    return gRust.Config[fileName][keyName]
                end
            end
        end
    end

    return default
end

function gRust.SetConfigValue(key, value)
    local parts = string.Split(key, "/")
    local fileName = parts[1]
    local keyName = parts[2]

    if (not fileName or not keyName) then
        return
    end

    if (not gRust.Config[fileName]) then
        gRust.Config[fileName] = {}
    end

    gRust.Config[fileName][keyName] = value

    local filePath = CONFIG_DIR .. fileName .. ".json"
    local fileContent = util.TableToJSON(gRust.Config[fileName], true)
    file.Write(filePath, fileContent)

    gRust.NetworkedConfig[key] = value

    local jsonStr = util.TableToJSON(gRust.NetworkedConfig)
    local compressed = util.Compress(jsonStr)
    
    net.Start("gRust.SyncConfig")
        net.WriteUInt(#compressed, 32)
        net.WriteData(compressed, #compressed)
    net.Broadcast()

    hook.Run("gRust.ConfigUpdated", key, value)
end

function gRust.CreateConfigValue(key, default, networked)
    local f = string.Split(key, "/")
    local fileName = f[1]
    local keyName = f[2]

    if (not fileName or not keyName) then
        return
    end

    if (not gRust.Config[fileName]) then
        local path = CONFIG_DIR .. fileName .. ".json"
        if (file.Exists(path, "DATA")) then
            local fileData = file.Read(path, "DATA")
            if (fileData and fileData ~= "") then
                gRust.Config[fileName] = util.JSONToTable(fileData) or {}
            else
                gRust.Config[fileName] = {}
            end
        else
            gRust.Config[fileName] = {}
        end
    end
    
    if (gRust.Config[fileName][keyName] == nil) then
        gRust.Config[fileName][keyName] = default
        local filePath = CONFIG_DIR .. fileName .. ".json"
        local fileData = util.TableToJSON(gRust.Config[fileName], true)
        file.Write(filePath, fileData)
    end

    if (networked) then
        gRust.NetworkedConfig[key] = gRust.Config[fileName][keyName]
    end
end

function gRust.LoadConfig()
    local files, _ = file.Find(CONFIG_DIR .. "*.json", "DATA")
    
    for _, v in ipairs(files) do
        local fileName = string.Replace(v, ".json", "")
        local fileData = file.Read(CONFIG_DIR .. v, "DATA")
        if (fileData) then
            local decoded = util.JSONToTable(fileData)
            if (decoded) then
                gRust.Config[fileName] = decoded
            end
        end
    end

    gRust.ConfigLoaded = true
end

hook.Add("PrePlayerNetworkReady", "gRust.SyncConfigOnJoin", function(pl)
    local str = util.TableToJSON(gRust.NetworkedConfig)
    local compressed = util.Compress(str)
    local len = #compressed

    net.Start("gRust.SyncConfig")
        net.WriteUInt(len, 32)
        net.WriteData(compressed, len)
    net.Send(pl)
end)

function gRust.WipeAll()
    local players = player.GetHumans()
    for k, v in ipairs(players) do
        v:Kick("Server is wiping, please rejoin in a few seconds.")
    end

    hook.Run("gRust.Wipe", false, false)
    
    file.Write("gRust/last_wipe.txt", os.time())
    
    timer.Simple(2, function()
        RunConsoleCommand("_restart")
    end)
end

function gRust.WipeConfig()
    local players = player.GetHumans()
    for k, v in ipairs(players) do
        v:Kick("Server config is being wiped, please rejoin in a few seconds.")
    end
    
    gRust.Config = {}
    gRust.NetworkedConfig = {}
    
    local files, _ = file.Find(CONFIG_DIR .. "*.json", "DATA")
    if (files) then
        for _, f in ipairs(files) do
            file.Delete(CONFIG_DIR .. f)
        end
    end
    
    timer.Simple(2, function()
        RunConsoleCommand("_restart")
    end)
end

gRust.LoadConfig()
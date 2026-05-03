-- ============================================================
-- gRust - saving_sv.lua (PATCHÉ)
-- Corrections :
--   [CRITIQUE] gRust.Load() crée des entités depuis le fichier
--              binaire sans whitelist → ajout d'une liste blanche
--              des classes sauvegardables.
--   [BUG]      Les intervalles SAVE/BACKUP/MAX_BACKUPS étaient
--              lus immédiatement après CreateConfigValue, avant
--              que LoadConfig() soit appelé (premier démarrage).
--              Ils sont maintenant lus via hook après le chargement.
-- ============================================================

local SAVE_DIR = "grust/saves/"

file.CreateDir(SAVE_DIR)
file.CreateDir(SAVE_DIR .. "backups")

gRust.CreateConfigValue("server/save.interval",    120)
gRust.CreateConfigValue("server/backup.max",        30)
gRust.CreateConfigValue("server/backup.interval", 1200)

local SAVE_INTERVAL    = 120
local MAX_BACKUPS      = 30
local BACKUP_INTERVAL  = 1200

hook.Add("gRust.Loaded", "gRust.LoadSaveIntervals", function()
    SAVE_INTERVAL   = gRust.GetConfigValue("server/save.interval",    120)
    MAX_BACKUPS     = gRust.GetConfigValue("server/backup.max",        30)
    BACKUP_INTERVAL = gRust.GetConfigValue("server/backup.interval", 1200)

    if (timer.Exists("gRust.Save")) then
        timer.Adjust("gRust.Save", SAVE_INTERVAL, 0)
    end
end)

-- ============================================================
-- [PATCH CRITIQUE] Whitelist des classes d'entités sauvegardables.
-- Seules ces classes peuvent être instanciées lors d'un Load.
-- Ajoutez ici toute nouvelle entité qui doit être sauvegardée.
-- ============================================================

local SAVEABLE_ENT_CLASSES = {
    ["rust_base"]             = true,
    ["rust_armoreddoor"]      = true,
    ["rust_armoreddoubledoor"]= true,
    ["rust_barrel"]           = true,
    ["rust_battery"]          = true,
    ["rust_bed"]              = true,
    ["rust_bomb"]             = true,
    ["rust_button"]           = true,
    ["rust_cardreader"]       = true,
    ["rust_casinobox"]        = true,
    ["rust_casinowheel"]      = true,
    ["rust_chair"]            = true,
    ["rust_codelock"]         = true,
    ["rust_container"]        = true,
    ["rust_crate"]            = true,
    ["rust_deathbag"]         = true,
    ["rust_door"]             = true,
    ["rust_doubledoor"]       = true,
    ["rust_elitecrate"]       = true,
    ["rust_embrasureh"]       = true,
    ["rust_embrasurev"]       = true,
    ["rust_furnace"]          = true,
    ["rust_fusebox"]          = true,
    ["rust_garagedoor"]       = true,
    ["rust_itembag"]          = true,
    ["rust_sleepingplayer"]   = true,
    ["rust_tc"]               = true,
}

-- ============================================================
-- gRust.Save
-- ============================================================

function gRust.Save(filename)
    local saveFile = SAVE_DIR .. filename
    if (not file.Exists(saveFile, "DATA")) then
        file.Write(saveFile, "")
    end

    local f = file.Open(saveFile, "wb", "DATA")
    if (not f) then
        gRust.LogError("Failed to open save file for writing: " .. saveFile)
        return
    end

    local entCount = 0

    for _, ent in ents.Iterator() do
        if (not ent.ShouldSave) then continue end
        if (not ent.Save)       then continue end
        if (ent:CreatedByMap()) then continue end

        if (not SAVEABLE_ENT_CLASSES[ent:GetClass()]) then
            gRust.Log("Save: skipping non-whitelisted class: " .. ent:GetClass())
            continue
        end

        f:WriteUShort(string.len(ent:GetClass()))
        f:Write(ent:GetClass())
        ent:Save(f)

        entCount = entCount + 1
    end

    f:Close()

    gRust.LogSuccess(string.format("Saved %i entities", entCount))
end

-- ============================================================
-- gRust.Load
-- [PATCH CRITIQUE] Validation de la classe avant ents.Create
-- ============================================================

function gRust.Load(filename)
    local saveFile = SAVE_DIR .. filename
    if (not file.Exists(saveFile, "DATA")) then return end

    local entCount  = 0
    local skipCount = 0

    local f = file.Open(saveFile, "rb", "DATA")
    if (not f) then
        gRust.LogError("Failed to open save file for reading: " .. saveFile)
        return
    end

    while (not f:EndOfFile()) do
        local class = f:ReadString()

        if (not class or class == "") then
            gRust.LogError("Load: empty class name in save file, stopping.")
            break
        end

        if (not SAVEABLE_ENT_CLASSES[class]) then
            gRust.LogError("Load: refused to create non-whitelisted entity class: " .. class)
            skipCount = skipCount + 1
            break
        end

        local ent = ents.Create(class)

        if (not IsValid(ent)) then
            gRust.LogError("Load: failed to create entity of class: " .. class)
            skipCount = skipCount + 1
            continue
        end

        ent:Spawn()
        ent:Load(f)

        entCount = entCount + 1
    end

    f:Close()

    gRust.LogSuccess(string.format("Loaded %i entities (%i skipped)", entCount, skipCount))
end

-- ============================================================
-- gRust.ClearSave
-- ============================================================

function gRust.ClearSave(filename)
    local saveFile = SAVE_DIR .. filename
    if (file.Exists(saveFile, "DATA")) then
        file.Delete(saveFile)
    end
end

-- ============================================================
-- gRust.AutoSave
-- ============================================================

function gRust.AutoSave()
    gRust.Save("autosave.dat")
end

-- ============================================================
-- Timer de sauvegarde automatique
-- ============================================================

timer.Create("gRust.Save", SAVE_INTERVAL, 0, function()
    if (gRust.Wiping) then return end

    gRust.Save("autosave.dat")

    gRust.LastBackup = gRust.LastBackup or CurTime()
    if (gRust.LastBackup + BACKUP_INTERVAL < CurTime()) then
        gRust.LastBackup = CurTime()

        local f = file.Read(SAVE_DIR .. "autosave.dat", "DATA")
        if (f and f ~= "") then
            local backupFile = SAVE_DIR .. "backups/autosave_" .. os.date("%Y-%m-%d_%H-%M-%S") .. ".dat"
            file.Write(backupFile, f)

            local files = file.Find(SAVE_DIR .. "backups/*.dat", "DATA")
            if (files and #files > MAX_BACKUPS) then
                table.sort(files, function(a, b)
                    return a < b
                end)

                file.Delete(SAVE_DIR .. "backups/" .. files[1])
            end
        end
    end
end)

-- ============================================================
-- Chargement au démarrage
-- ============================================================

hook.Add("InitPostEntity", "gRust.Load", function()
    gRust.Load("autosave.dat")
end)

hook.Add("gRust.Wipe", "gRust.ClearAutoSave", function()
    gRust.ClearSave("autosave.dat")
end)
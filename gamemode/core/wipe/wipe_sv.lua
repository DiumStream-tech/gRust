function gRust.Wipe(bpWipe, scheduled)
    gRust.Wiping = true

    local players = player.GetHumans()
    for k, v in ipairs(players) do
        v:Kick("Server is wiping, please rejoin in a few seconds.")
    end

    hook.Run("gRust.Wipe", bpWipe, scheduled)

    file.Write("gRust/last_wipe.txt", os.time())

    timer.Simple(5, function()
        RunConsoleCommand("_restart")
    end)
end

function gRust.GetLastWipe()
    return file.Read("gRust/last_wipe.txt", "DATA") or 0
end
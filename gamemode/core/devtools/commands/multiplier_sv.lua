gRust.CreateConfigValue("farming/gather.multiplier", 1, true)
gRust.CreateConfigValue("building/resources.multiplier", 1, true)
gRust.CreateConfigValue("recycler/efficiency.multiplier", 1, true)
gRust.CreateConfigValue("loot/multiplier", 1, true)

hook.Add("gRust.ConfigUpdated", "gRust.MultiplierNotify", function()
	if (GetConVar("developer"):GetInt() > 0) then
		print("[gRust] Multiplier config updated")
	end
end)

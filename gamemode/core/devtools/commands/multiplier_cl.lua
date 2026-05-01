net.Receive("gRust.MultiplierMessage", function()
	local msg = net.ReadString()
	chat.AddText(Color(100, 200, 255), "[gRust] " .. msg)
end)

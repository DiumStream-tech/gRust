gRust.PermissionsClient = gRust.PermissionsClient or {}

net.Receive("gRust.PermissionDenied", function()
	gRust.PermissionsClient.hasPermission = net.ReadBool()
end)

function gRust.PermissionsClient:CheckPermission(key)
	net.Start("gRust.CheckPermission")
		net.WriteString(key)
	net.SendToServer()
	
	return self.hasPermission
end

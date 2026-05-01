local F1Down = false
local IsAdminCached = false
local LastCheck = 0

net.Receive("gRust.PermissionDenied", function()
    local hasPermission = net.ReadBool()
    local permissionKey = net.ReadString()
    
    if (permissionKey == "devmenu") then
        IsAdminCached = hasPermission
    end
end)

hook.Add("Think", "gRust.DevTools", function()
    if (input.IsButtonDown(KEY_F1)) then
        if (!F1Down) then
            if (CurTime() > LastCheck) then
                net.Start("gRust.CheckPermission")
                    net.WriteString("devmenu")
                net.SendToServer()
                LastCheck = CurTime() + 10
            end

            if (IsValid(gRust.DevTools)) then
                gRust.DevTools:Remove()
            elseif (gRust.Hud.ShouldDraw and IsAdminCached) then
                gRust.DevTools = vgui.Create("gRust.DevTools")
                gRust.DevTools:SetPos(0, 0)
                gRust.DevTools:SetSize(ScrW(), ScrH() * 0.88)
                gRust.DevTools:MakePopup()
                gRust.DevTools:DockMargin(8, 8, 8, 8)
                
                gRust.DevTools:AddPage("ITEMS", "gRust.DevTools.Items")
            end

            F1Down = true
        end
    else
        F1Down = false
    end
end)
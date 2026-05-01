local PANEL = FindMetaTable("Panel")

local TooltipColor = Color(24, 102, 154)
local TooltipFont = "gRust.38px"
local TextColor = Color(108, 193, 253)

function PANEL:SetTooltip(text)
    if (self.Tooltip) then
        self.Tooltip = text
        return
    end
    
    local TooltipPaddingX = 20 * gRust.Hud.Scaling
    local TooltipPaddingY = 4 * gRust.Hud.Scaling
    local TooltipSpacing = 8 * gRust.Hud.Scaling
    self.Tooltip = text

    local paintOver = self.PaintOver
    self.TooltipMatrix = Matrix()
    self.PaintOver = function(me, w, h)
        draw.Overlay(function()
            local text = me.Tooltip
            if (vgui.GetHoveredPanel() == me and text and type(text) == "string" and string.len(text) > 0) then
                if (!me.TooltipHoverTime) then
                    me.TooltipHoverTime = CurTime() + 0.15
                end

                if (CurTime() < me.TooltipHoverTime) then
                    return
                end

                local sx, sy = me:LocalToScreen(0, 0)
                local clip = DisableClipping(true)

                surface.SetFont(TooltipFont)
                local tw, th = surface.GetTextSize(text)
                local x = (w * 0.5) - (tw * 0.5 + TooltipPaddingX)
                local y

                if (sy - h * 0.5 > 0) then
                    y = -TooltipSpacing - th - TooltipPaddingY * 2
                else
                    y = h + TooltipSpacing
                end
                
                local bw = tw + TooltipPaddingX * 2
                local bh = th + TooltipPaddingY * 2

                local animProgress = Lerp((CurTime() - me.TooltipHoverTime) / 0.125, 0, 1)

                surface.SetAlphaMultiplier(animProgress)

                local mx, my = me:LocalToScreen(x, y)
                mx = mx + bw * 0.5
                my = my + bh * 0.5

                local screenX, screenY = me:LocalToScreen(x, y)

                local scale = Vector(1, 1, 1) * math.ease.OutBack(animProgress)
                scale.z = 1
                
                me.TooltipMatrix:Identity()
                me.TooltipMatrix:Translate(Vector(mx, my))
                me.TooltipMatrix:SetScale(scale)
                me.TooltipMatrix:Translate(Vector(-mx, -my))
                
                cam.PushModelMatrix(me.TooltipMatrix)

                gRust.DrawPanelColored(screenX, screenY, bw, bh, TooltipColor)

                local lines = string.Explode("\n", text)
                for i = 1, #lines do
                    draw.SimpleText(lines[i], TooltipFont, screenX + bw * 0.5, screenY + TooltipPaddingY + (i - 1) * (th / #lines), TextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                end

                surface.SetAlphaMultiplier(1)
                cam.PopModelMatrix()
                DisableClipping(clip)
            else
                me.TooltipHoverTime = nil
            end
            
            if (paintOver) then
                paintOver(me, w, h)
            end
        end)
    end
end
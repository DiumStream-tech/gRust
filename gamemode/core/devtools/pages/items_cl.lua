local PANEL = {}

local OpenedTab = "Items"

local CATEGORY_FONT = "gRust.22px"
local CATEGORY_MARGIN = 5

local hasPermission = false

local function CheckPermission()
    net.Start("gRust.CheckPermission")
        net.WriteString("give")
    net.SendToServer()
end

net.Receive("gRust.PermissionDenied", function()
    hasPermission = net.ReadBool()
end)

function PANEL:Init()
    timer.Simple(0.1, function() CheckPermission() end)
    
    local CategoryContainer = self:Add("Panel")
    CategoryContainer:Dock(TOP)
    CategoryContainer:SetTall(40)

    self.Container = self:Add("Panel")
    self.Container:Dock(FILL)

    for k, v in ipairs(gRust.GetCategories()) do
        local Category = CategoryContainer:Add("gRust.Button")
        Category:SetText(v.Name .. " [" .. #v.Items .. "]")
        Category:SetFont(CATEGORY_FONT)
        Category:DockMargin(0, 0, CATEGORY_MARGIN, 0)
        if (#v.Items == 0) then
            Category:SetTextColor(Color(255, 255, 255, 25))
        end
        if (v.Name == OpenedTab) then
            self:FillCategory(v.Name)
        end
        Category.DoClick = function(pnl)
            self:FillCategory(v.Name)
            OpenedTab = v.Name
        end
    end

    CategoryContainer.PerformLayout = function(pnl, w, h)
        local x = CATEGORY_MARGIN
        local children = pnl:GetChildren()
        local count = #children
        for k, v in ipairs(children) do
            v:SetWide(w / count - CATEGORY_MARGIN)
            v:SetTall(h)
            v:SetPos(x, 0)
            x = x + v:GetWide() + CATEGORY_MARGIN
        end
    end

    local SearchContainer = self:Add("Panel")
    SearchContainer:Dock(BOTTOM)
    SearchContainer:SetTall(50)
    local padding = 8
    SearchContainer:DockMargin(padding, padding, padding, padding)

    local Search = SearchContainer:Add("DTextEntry")
    Search:SetTall(40)
    Search:SetWide(200)
    Search:SetPos(0, 0)
    Search:Dock(FILL)
    Search:SetFont("gRust.32px")
    Search:SetCursor("hand")
    Search.Paint = function(me, w, h)
        gRust.DrawPanelColored(0, 0, w, h, Color(200, 200, 200))
        me:DrawTextEntryText(Color(0, 0, 0), Color(0, 0, 0), Color(0, 0, 0))
    end
    Search.OnChange = function(me)
        self:FillItems(function(item)
            return string.find(string.lower(item:GetName()), string.lower(me:GetText()))
        end)
    end
    Search.OnEnter = function(me)
        local FirstItem = self.Container:GetChildren()[1]
        if (IsValid(FirstItem)) then
            FirstItem:DoClick()
        end
        me:RequestFocus()
    end
    Search:RequestFocus()

    self:MakePopup()
end

function PANEL:Paint(w, h)
end

local function SpawnItem(id, amount)
    if (not hasPermission) then
        LocalPlayer():ChatPrint("You do not have permission to spawn items")
        return
    end
    
    RunConsoleCommand("grust_giveitem", id, amount)
end

local ITEM_PADDING = 8
local BLUEPRINT_ICON = Material("items/misc/blueprint.png", "smooth")
local TEXT_COLOR = Color(131, 131, 131)

function PANEL:FillItems(condition)
    if (!IsValid(self.Container)) then return end
    self.Container:Clear()

    for k, v in ipairs(gRust.GetItems()) do
        local register = gRust.GetItemRegister(v)
        if (!condition(register)) then continue end

        local Item = self.Container:Add("gRust.Button")
        Item:SetDefaultColor(Color(200, 200, 200))
        Item:SetHoveredColor(Color(255, 255, 255))
        Item:SetSelectedColor(Color(180, 180, 180))
        Item.Paint = function(me, w, h)
            if (register:IsInCategory("Blueprints")) then
                surface.SetDrawColor(color_white)
                surface.SetMaterial(BLUEPRINT_ICON)
                surface.DrawTexturedRect(ITEM_PADDING, ITEM_PADDING, w - ITEM_PADDING * 2, h - ITEM_PADDING * 2)
            end

            surface.SetDrawColor(me:GetColor())
            surface.SetMaterial(register:GetIcon())
            surface.DrawTexturedRect(ITEM_PADDING, ITEM_PADDING, w - ITEM_PADDING * 2, h - ITEM_PADDING * 2)

            draw.SimpleText(register:GetName(), "gRust.16px", w / 2, h - 16, TEXT_COLOR, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        Item.DoClick = function(me)
            SpawnItem(v, 1)
        end

        local Hundred = Item:Add("gRust.Button")
        Hundred:SetText("100")
        Hundred:SetFont("gRust.16px")
        local OldOnCursorEntered = Hundred.OnCursorEntered
        Hundred.OnCursorEntered = function(me)
            if (OldOnCursorEntered) then OldOnCursorEntered(me) end
            Item:OnCursorEntered()
        end
        Hundred.DoClick = function(me)
            SpawnItem(v, 100)
        end
        
        local Thousand = Item:Add("gRust.Button")
        Thousand:SetText("1k")
        Thousand:SetFont("gRust.16px")
        local OldOnCursorEntered2 = Thousand.OnCursorEntered
        Thousand.OnCursorEntered = function(me)
            if (OldOnCursorEntered2) then OldOnCursorEntered2(me) end
            Item:OnCursorEntered()
        end
        Thousand.DoClick = function(me)
            SpawnItem(v, 1000)
        end

        Item.PerformLayout = function(me, w, h)
            Hundred:SetWide(40)
            Hundred:SetTall(20)
            Hundred:SetPos(w / 2 + ITEM_PADDING, ITEM_PADDING)

            Thousand:SetWide(40)
            Thousand:SetTall(20)
            Thousand:SetPos(w / 2 + ITEM_PADDING, ITEM_PADDING + Hundred:GetTall() + ITEM_PADDING)
        end

        local OldPaint1 = Hundred.Paint
        Hundred.Paint = function(me, w, h)
            if (Item:IsHovered() or me:IsHovered() or Thousand:IsHovered()) then
                OldPaint1(me, w, h)
            end
        end

        local OldPaint2 = Thousand.Paint
        Thousand.Paint = function(me, w, h)
            if (Item:IsHovered() or me:IsHovered() or Hundred:IsHovered()) then
                OldPaint2(me, w, h)
            end
        end
    end

    self:InvalidateLayout()
end

function PANEL:FillCategory(category)
    self:FillItems(function(item)
        return item:IsInCategory(category)
    end)
end

local ITEM_SIZE = 128
function PANEL:PerformLayout(w, h)
    if (!IsValid(self.Container)) then return end
    
    local children = self.Container:GetChildren()
    local cols = math.floor(w / ITEM_SIZE)
    if (cols < 1) then cols = 1 end

    for k, v in ipairs(children) do
        v:SetWide(ITEM_SIZE)
        v:SetTall(ITEM_SIZE)

        local x = (k - 1) % cols * ITEM_SIZE
        local y = math.floor((k - 1) / cols) * ITEM_SIZE
        v:SetPos(x, y)
    end
end

vgui.Register("gRust.DevTools.Items", PANEL, "EditablePanel")
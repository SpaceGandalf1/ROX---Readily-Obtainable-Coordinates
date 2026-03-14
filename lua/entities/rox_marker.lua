AddCSLuaFile()
DEFINE_BASECLASS("base_gmodentity")

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "ROX Marker"
ENT.Author = "SpaceGandalf"
ENT.Spawnable = true
ENT.Category = "#spawnmenu.category.editors"
ENT.Information = "Press E to name. Type 'rox_list' in console to print coordinates."

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "Nickname")
end

if SERVER then
    util.AddNetworkString("ROX_OpenMenu")
    util.AddNetworkString("ROX_SubmitName")

    ROX_MARKER_COUNT = ROX_MARKER_COUNT or 0

    function ENT:Initialize()
        self:SetModel("models/maxofs2d/cube_tool.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:Wake() end

        ROX_MARKER_COUNT = ROX_MARKER_COUNT + 1
        self:SetNickname("Rox " .. ROX_MARKER_COUNT)
    end

    function ENT:Use(activator)
        if IsValid(activator) and activator:IsPlayer() then
            net.Start("ROX_OpenMenu")
            net.WriteEntity(self) 
            net.Send(activator)
        end
    end

    net.Receive("ROX_SubmitName", function(len, ply)
        local ent = net.ReadEntity()
        local newName = net.ReadString()

        if IsValid(ent) and ent:GetClass() == "rox_marker" and IsValid(ply) then
            -- distance check to prevent remote renaming exploits
            if ply:GetPos():DistToSqr(ent:GetPos()) < 100000 then 
                ent:SetNickname(newName)
                ply:PrintMessage(HUD_PRINTCONSOLE, "ROX renamed to: " .. newName)
            end
        end
    end)

    concommand.Add("rox_list", function(ply)
        if not IsValid(ply) then return end

        local markers = ents.FindByClass("rox_marker")
        if #markers == 0 then
            ply:PrintMessage(HUD_PRINTCONSOLE, "No ROX markers found.")
            return
        end

        ply:PrintMessage(HUD_PRINTCONSOLE, "\n=== ROX Coordinates ===")
        for _, ent in ipairs(markers) do
            local pos = ent:GetPos()
            ply:PrintMessage(HUD_PRINTCONSOLE, string.format("%s | X: %d, Y: %d, Z: %d", ent:GetNickname(), pos.x, pos.y, pos.z))
        end
        ply:PrintMessage(HUD_PRINTCONSOLE, "=======================\n")
    end)
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()

        local pos = self:GetPos() + Vector(0, 0, 15)
        local ang = LocalPlayer():EyeAngles()
        
        ang:RotateAroundAxis(ang:Forward(), 90)
        ang:RotateAroundAxis(ang:Right(), 90)

        cam.Start3D2D(pos, ang, 0.1)
            draw.SimpleText(self:GetNickname(), "DermaDefault", 0, 0, color_green, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end

    net.Receive("ROX_OpenMenu", function()
        local ent = net.ReadEntity()
        if not IsValid(ent) then return end

        local frame = vgui.Create("DFrame")
        frame:SetSize(300, 110)
        frame:Center()
        frame:SetTitle("Rename Marker")
        frame:MakePopup() 

        local entry = vgui.Create("DTextEntry", frame)
        entry:Dock(TOP)
        entry:DockMargin(10, 10, 10, 0)
        entry:SetText(ent:GetNickname())
        entry:RequestFocus() 

        local btn = vgui.Create("DButton", frame)
        btn:Dock(BOTTOM)
        btn:DockMargin(10, 0, 10, 10)
        btn:SetText("Save")
        
        local function submit()
            net.Start("ROX_SubmitName")
            net.WriteEntity(ent)
            net.WriteString(entry:GetValue())
            net.SendToServer()
            frame:Close()
        end
        
        btn.DoClick = submit
        entry.OnEnter = submit 
    end)
end
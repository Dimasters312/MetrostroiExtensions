MEL.DefineRecipe("base_scroll_event", "gmod_subway_base")
local C_DrawDebug = GetConVar("metrostroi_drawdebug")
function RECIPE:Init()
    if SERVER then util.AddNetworkString("metrostroi-cabin-button-scroll") end
end

function RECIPE:Inject(ent, entclass)
    if CLIENT then
        local function LinePlaneIntersect(PlanePos, PlaneNormal, LinePos, LineDir)
            local dot = LineDir:Dot(PlaneNormal)
            local fac = LinePos - PlanePos
            local dis = -PlaneNormal:Dot(fac) / dot
            return LineDir * dis + LinePos
        end

        local function WorldToScreen(vWorldPos, vPos, vScale, aRot)
            vWorldPos = vWorldPos - vPos
            vWorldPos:Rotate(Angle(0, -aRot.y, 0))
            vWorldPos:Rotate(Angle(-aRot.p, 0, 0))
            vWorldPos:Rotate(Angle(0, 0, -aRot.r))
            return vWorldPos.x / vScale, -vWorldPos.y / vScale
        end

        local function isValidTrainDriver(ply)
            local train
            local seat = ply:GetVehicle()
            if IsValid(seat) then train = seat:GetNW2Entity("TrainEntity") end
            if IsValid(train) then return train end
            local weapon = IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon():GetClass()
            if weapon == "train_kv_wrench" or weapon == "train_kv_wrench_gold" then
                train = util.TraceLine({
                    start = LocalPlayer():GetPos(),
                    endpos = LocalPlayer():GetPos() - LocalPlayer():GetAngles():Up() * 100,
                    filter = function(ent) if ent.ButtonMap ~= nil then return true end end
                }).Entity

                if not IsValid(train) then
                    train = util.TraceLine({
                        start = LocalPlayer():EyePos(),
                        endpos = LocalPlayer():EyePos() + LocalPlayer():EyeAngles():Forward() * 300,
                        filter = function(ent) if ent.ButtonMap ~= nil then return true end end
                    }).Entity
                end
            end
            return train, true
        end

        local function findAimButton(ply, train)
            local panel, panelDist = nil, 1e9
            for kp, pan in pairs(train.ButtonMap) do
                if not train:ShouldDrawPanel(kp) then continue end
                --If player is looking at this panel
                if pan.aimedAt and (pan.buttons or pan.sensor or pan.mouse) and pan.aimedAt < panelDist then
                    panel = pan
                    panelDist = pan.aimedAt
                end
            end

            if not panel then return false end
            if panel.aimX and panel.aimY and (panel.sensor or panel.mouse) and math.InRangeXY(panel.aimX, panel.aimY, 0, 0, panel.width, panel.height) then return false, panel.aimX, panel.aimY, panel.system end
            if not panel.buttons then return false end
            local buttonTarget
            for _, button in pairs(panel.buttons) do
                if (train.Hidden[button.PropName] or train.Hidden.button[button.PropName]) and (not train.ClientProps[button.PropName] or not train.ClientProps[button.PropName].config or not train.ClientProps[button.PropName].config.staylabel) then continue end
                if (train.Hidden[button.ID] or train.Hidden.button[button.ID]) and (not train.ClientProps[button.ID] or not train.ClientProps[button.ID].config or not train.ClientProps[button.ID].config.staylabel) then continue end
                if button.w and button.h then
                    if panel.aimX >= button.x and panel.aimX <= button.x + button.w and panel.aimY >= button.y and panel.aimY <= button.y + button.h then
                        buttonTarget = button
                        --table.insert(foundbuttons,{button,panel.aimedAt})
                    end
                else
                    --If the aim location is withing button radis
                    local dist = math.Distance(button.x, button.y, panel.aimX, panel.aimY)
                    if dist < (button.radius or 10) then
                        buttonTarget = button
                        --table.insert(foundbuttons,{button,panel.aimedAt})
                    end
                end
            end

            if not buttonTarget then return false end
            return buttonTarget
        end

        hook.Remove("Think", "metrostroi-cabin-panel")
        hook.Add("Think", "metrostroi-cabin-panel", function()
            local ply = LocalPlayer()
            if not IsValid(ply) then return end
            toolTipText = nil
            drawCrosshair = false
            canDrawCrosshair = false
            currentAimedButton = nil
            local train, outside = isValidTrainDriver(ply)
            if not IsValid(train) then return end
            if gui.IsConsoleVisible() or gui.IsGameUIVisible() or IsValid(vgui.GetHoveredPanel()) and not vgui.IsHoveringWorld() and vgui.GetHoveredPanel():GetParent() ~= vgui.GetWorldPanel() then return end
            if train.ButtonMap ~= nil then
                canDrawCrosshair = true
                local plyaimvec
                if outside then
                    plyaimvec = ply:GetAimVector()
                else
                    local x, y = input.GetCursorPos()
                    --plyaimvec = util.AimVector( train.CamAngles, train.CamFOV,x,y,ScrW(),ScrH())
                    --plyaimvec = ply:GetAimVector()
                    plyaimvec = gui.ScreenToVector(x, y) -- ply:GetAimVector() is unreliable when in seats
                end

                -- Loop trough every panel
                for k2, panel in pairs(train.ButtonMap) do
                    if not train:ShouldDrawPanel(kp2) then continue end
                    local pang = train:LocalToWorldAngles(panel.ang)
                    if plyaimvec:Dot(pang:Up()) < 0 then
                        local campos = not outside and train.CamPos or ply:EyePos()
                        local ppos = train:LocalToWorld(panel.pos) -- - Vector(math.Round((not outside and train.HeadAcceleration or 0),2),0,0))
                        local isectPos = LinePlaneIntersect(ppos, pang:Up(), campos, plyaimvec)
                        local localx, localy = WorldToScreen(isectPos, ppos, panel.scale, pang)
                        panel.aimX = localx
                        panel.aimY = localy
                        if plyaimvec:Dot(isectPos - campos) / (isectPos - campos):Length() > 0 and localx > 0 and localx < panel.width and localy > 0 and localy < panel.height then
                            panel.aimedAt = isectPos:Distance(campos)
                            drawCrosshair = panel.aimedAt
                        else
                            panel.aimedAt = false
                        end

                        panel.outside = outside
                    else
                        panel.aimedAt = false
                    end
                end

                -- Tooltips
                local ttdelay = GetConVar("metrostroi_tooltip_delay"):GetFloat()
                if GetConVar("metrostroi_disablehovertext"):GetInt() == 0 and ttdelay and ttdelay >= 0 then
                    local button = findAimButton(ply, train)
                    --print(train.ClientProps[button.ID].button)
                    if button and ((train.Hidden[button.ID] or train.Hidden[button.PropName]) and (not train.ClientProps[button.ID].config or not train.ClientProps[button.ID].config.staylabel) or (train.Hidden.button[button.ID] or train.Hidden.button[button.PropName]) and (not train.ClientProps[button.PropName].config or not train.ClientProps[button.PropName].config.staylabel)) then return end
                    currentAimedButton = button
                    if button ~= lastAimButton then
                        lastAimButtonChange = CurTime()
                        lastAimButton = button
                    end

                    if button then
                        if ttdelay == 0 or CurTime() - lastAimButtonChange > ttdelay then
                            if C_DrawDebug:GetInt() > 0 then
                                toolTipText, toolTipColor = button.ID, Color(255, 0, 255)
                            elseif button.plombed then
                                toolTipText, _, toolTipColor = button.plombed(train)
                            else
                                toolTipText, toolTipColor = button.tooltip
                            end

                            --[[toolTipPosition = nil
                            if button.tooltipState then
                                local newTT,newTTpos = button.tooltipState(train)
                                toolTipText = toolTipText..newTT
                                toolTipPosition = Metrostroi.GetPhrase(newTTpos)
                            end]]
                            if GetConVar("metrostroi_disablehovertextpos"):GetInt() == 0 and button.tooltipState and button.tooltip then toolTipText = toolTipText .. button.tooltipState(train) end
                        end
                    end
                end
            end
        end)

        hook.Add("HUDShouldDraw", "HideHUD", function(name) if name == "CHudWeaponSelection" and currentAimedButton and currentAimedButton.potentiometer then return false end end)
        local function sendButtonScrollMessage(button, train, outside)
            local buttID = button.ID
            if not buttID then
                Error(Format("Can't send button scroll message! %s\n", button.ID))
                return
            end

            net.Start("metrostroi-cabin-button-scroll")
            net.WriteEntity(train)
            net.WriteString(buttID:gsub("^.+:", ""))
            net.WriteInt(button.delta, 6)
            net.WriteBool(outside)
            net.SendToServer()
            return buttID
        end

        local function handleScrollEvent(ply, cmd)
            if gui.IsConsoleVisible() or gui.IsGameUIVisible() then return end
            local train, outside = isValidTrainDriver(ply)
            if not IsValid(train) then return end
            if train.ButtonMap == nil then return end
            local button, _, _, _ = findAimButton(ply, train)
            if button and button.ID and button.ID[1] ~= "!" then
                button.delta = cmd:GetMouseWheel()
                local buttID = sendButtonScrollMessage(button, train, outside)
                lastButton = button
                lastButton.train = train
            end
        end

        hook.Add("InputMouseApply", "metrostroi-cabin-buttons_extscroll", function(cmd, x, y, ang) if cmd:GetMouseWheel() ~= 0 then handleScrollEvent(LocalPlayer(), cmd) end end)
    end

    if SERVER then
        net.Receive("metrostroi-cabin-button-scroll", function(len, ply)
            local train = net.ReadEntity()
            local button = net.ReadString()
            local event_delta = net.ReadInt(6)
            local seat = ply:GetVehicle()
            local outside = net.ReadBool()
            if outside then
                if not IsValid(train) then return end
                if outside and (train.CPPICanPickup and not train:CPPICanPickup(ply)) then return end
                if not outside and ply ~= train.DriverSeat.lastDriver then return end
                if not outside and train.DriverSeat.lastDriverTime and CurTime() - train.DriverSeat.lastDriverTime > 1 then return end
            else
                if not IsValid(train) then return end
                if seat ~= train.DriverSeat and seat ~= train.InstructorsSeat and (train.CPPICanPhysgun and not train:CPPICanPhysgun(ply)) and not button:find("Door") then return end
            end

            train:OnButtonScroll(button, event_delta, ply)
        end)
    end
end

local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Debris=game:GetService("Debris")
local Effects={}; Effects.__index=Effects
function Effects.new()
    local self=setmetatable({mode=nil,me=nil,lastPhase=nil},Effects)
    Players.LocalPlayer.CharacterAdded:Connect(function() self:reset() end)
    RunService:BindToRenderStep("ThriftFizz",Enum.RenderPriority.Camera.Value+1,function()
        local camera=workspace.CurrentCamera; local char=Players.LocalPlayer.Character; local hum=char and char:FindFirstChildOfClass("Humanoid")
        if self.mode then
            if self.untilTime and os.clock()>=self.untilTime then self:reset()
            else camera.CameraType=Enum.CameraType.Scriptable; camera.CFrame=self.mode; return end
        end
        local p=self.me
        if p and p.status=="Active" and p.fizz>0 and p.role=="Gran" and (self.phase=="Heist" or self.phase=="Escape") then
            local amount=p.fizz/100; local wave=math.sin(os.clock()*3.5)
            camera.CFrame*=CFrame.Angles(0,0,wave*0.035*amount)
            if hum then
                hum.CameraOffset=Vector3.new(wave*0.15*amount,math.sin(os.clock()*5)*0.08*amount,0)
                if hum.MoveDirection.Magnitude>0.1 then hum:Move(CFrame.Angles(0,wave*0.1*amount,0):VectorToWorldSpace(hum.MoveDirection),false) end
            end
        elseif hum then hum.CameraOffset=Vector3.zero end
    end)
    return self
end
function Effects:reset()
    self.mode=nil; self.untilTime=nil
    local camera=workspace.CurrentCamera; camera.CameraType=Enum.CameraType.Custom
    local char=Players.LocalPlayer.Character; local hum=char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.CameraOffset=Vector3.zero; camera.CameraSubject=hum end
end
function Effects:update(snapshot)
    self.me=nil; self.phase=snapshot.phase
    for _,p in snapshot.players do if p.id==Players.LocalPlayer.UserId and p.connected then self.me=p end end
    if snapshot.phase=="Payout" or snapshot.phase=="Intermission" or not self.me or self.me.status~="Active" then self:reset() end
    self.lastPhase=snapshot.phase
end
function Effects:event(data)
    if data.kind=="Intro" then self.mode=data.cf; self.untilTime=os.clock()+data.duration
    elseif data.kind=="Camera" then
        if data.index==0 then self:reset() else self.mode=data.cf; self.untilTime=nil end
    elseif data.kind=="Reveal" then
        for _,id in data.ids do
            local player=Players:GetPlayerByUserId(id)
            if player and player.Character then
                local highlight=Instance.new("Highlight"); highlight.FillColor=Color3.fromRGB(255,130,157); highlight.OutlineColor=Color3.fromRGB(255,239,191)
                highlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; highlight.Adornee=player.Character; highlight.Parent=player.Character; Debris:AddItem(highlight,4)
            end
        end
    end
end
return Effects

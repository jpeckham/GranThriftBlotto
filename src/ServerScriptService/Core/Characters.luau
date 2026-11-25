local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Rules=require(Shared.Rules)
local Catalog=require(Shared.Catalog)
local Characters={}
local function rgb(value,fallback)
    return if value then Color3.new(value[1],value[2],value[3]) else fallback
end
local function wearable(model,root,name,size,offset,color,shape)
    local p=Instance.new("Part"); p.Name=name; p.Size=size; p.Color=color
    p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Massless=true
    p.Material=Enum.Material.SmoothPlastic; p.TopSurface=Enum.SurfaceType.Smooth
    if shape then p.Shape=shape end
    p.CFrame=root.CFrame*offset; p.Parent=model
    local weld=Instance.new("Weld"); weld.Part0=root; weld.Part1=p; weld.C0=offset; weld.Parent=p
    return p
end
function Characters.apply(player,p,profile,now)
    local char=player.Character
    if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart"); local hum=char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    local equipped=(profile and profile.equipped) or {}
    local passes=(profile and profile.passes) or {}
    local signature=table.concat({p.role,p.class,tostring(p.segway),equipped.Dress or "",equipped.Wig or "",equipped.Walker or "",tostring(passes.VIP),tostring(passes.TacticalSegway)},":")
    local props=char:FindFirstChild("ThriftProps")
    if not props or props:GetAttribute("Signature")~=signature then
        if props then props:Destroy() end
        props=Instance.new("Model"); props.Name="ThriftProps"; props:SetAttribute("Signature",signature); props.Parent=char
        if p.role=="Gran" then
            local dress=rgb(Catalog.Cosmetics[equipped.Dress or ""] and Catalog.Cosmetics[equipped.Dress].color,Color3.fromRGB(151,93,159))
            wearable(props,root,"FloralMuumuu",Vector3.new(3.2,3.1,2.2),CFrame.new(0,-0.7,0),dress)
            for i=1,9 do
                local angle=i*2.4
                wearable(props,root,"Flower",Vector3.new(0.27,0.27,0.12),CFrame.new(math.sin(angle)*1.3,-1.7+(i%3)*0.7,-1.15),Color3.fromRGB(255,231,160),Enum.PartType.Ball)
            end
            local bloomColor=if passes.VIP then Color3.fromRGB(239,200,85) else Color3.fromRGB(248,224,214)
            wearable(props,root,"Bloomers",Vector3.new(3.5,1.7,2.7),CFrame.new(0,-1.4,0),bloomColor,Enum.PartType.Ball)
            for i=1,5 do wearable(props,root,"LootLump"..i,Vector3.new(0.7,0.7,0.7),CFrame.new((i-3)*0.6,-1.4,-1.2),bloomColor,Enum.PartType.Ball) end
            local head=char:FindFirstChild("Head")
            if head then
                local wig=rgb(Catalog.Cosmetics[equipped.Wig or ""] and Catalog.Cosmetics[equipped.Wig].color,Color3.fromRGB(217,214,218))
                wearable(props,head,"Perm",Vector3.new(2,1.1,1.8),CFrame.new(0,0.6,0.15),wig,Enum.PartType.Ball)
                for _,x in {-0.5,0.5} do wearable(props,head,"Spectacle",Vector3.new(0.7,0.5,0.12),CFrame.new(x,0,-0.6),Color3.fromRGB(111,71,48)) end
            end
            if p.class=="Turbo" then
                local ball=rgb(Catalog.Cosmetics[equipped.Walker or ""] and Catalog.Cosmetics[equipped.Walker].color,Color3.fromRGB(197,228,75))
                for _,x in {-1.8,1.8} do for _,z in {-2.5,-1} do
                    wearable(props,root,"WalkerLeg",Vector3.new(0.15,2.5,0.15),CFrame.new(x,-1,z),Color3.fromRGB(175,184,185))
                    wearable(props,root,"TennisBall",Vector3.new(0.5,0.5,0.5),CFrame.new(x,-2.3,z),ball,Enum.PartType.Ball)
                end; wearable(props,root,"WalkerRail",Vector3.new(0.18,0.18,1.7),CFrame.new(x,0.2,-1.7),Color3.fromRGB(175,184,185)) end
                wearable(props,root,"WalkerCrossbar",Vector3.new(3.6,0.18,0.18),CFrame.new(0,0.2,-2.5),Color3.fromRGB(175,184,185))
            elseif p.class=="Manager" then
                wearable(props,root,"Megaphone",Vector3.new(0.8,0.8,1.5),CFrame.new(1.8,0,-1),Color3.fromRGB(227,145,82),Enum.PartType.Cylinder)
            end
        elseif p.role=="Cop" then
            wearable(props,root,"Uniform",Vector3.new(2.2,2.1,1.2),CFrame.new(0,0,0),Color3.fromRGB(47,63,103))
            wearable(props,root,"Badge",Vector3.new(0.4,0.5,0.15),CFrame.new(-0.6,0.4,-0.7),Color3.fromRGB(242,205,91))
            wearable(props,root,"FoamBaton",Vector3.new(0.35,2.8,0.35),CFrame.new(1.8,-0.5,-0.6)*CFrame.Angles(0,0,-0.4),Color3.fromRGB(96,158,205))
            wearable(props,root,"TagWand",Vector3.new(0.35,1.2,0.35),CFrame.new(-1.6,0,-0.8),Color3.fromRGB(144,209,139))
            if p.segway then
                wearable(props,root,"SegwayDeck",Vector3.new(4,0.35,2),CFrame.new(0,-2.6,0),Color3.fromRGB(52,59,66))
                for _,x in {-2,2} do wearable(props,root,"SegwayWheel",Vector3.new(0.7,1.6,1.6),CFrame.new(x,-2.5,0),Color3.fromRGB(26,27,32),Enum.PartType.Cylinder) end
                wearable(props,root,"SegwayStem",Vector3.new(0.2,3.5,0.2),CFrame.new(0,-0.8,-1.1),Color3.fromRGB(166,171,175))
                wearable(props,root,"SegwayHandle",Vector3.new(3,0.2,0.2),CFrame.new(0,0.9,-1.1),Color3.fromRGB(45,47,50))
                if passes.TacticalSegway then
                    for _,x in {-1,1} do
                        local light=wearable(props,root,"Siren",Vector3.new(0.5,0.5,0.5),CFrame.new(x,-1.8,-0.9),if x<0 then Color3.new(1,0.1,0.1) else Color3.new(0.1,0.2,1))
                        light.Material=Enum.Material.Neon
                    end
                    wearable(props,root,"DonutCup",Vector3.new(0.5,0.7,0.5),CFrame.new(1.2,0.6,-1),Color3.fromRGB(238,168,109),Enum.PartType.Cylinder)
                end
            end
        end
    end
    local bloom=props:FindFirstChild("Bloomers")
    if bloom then
        local scale=1+math.min(p.bulk/10,1.8)*0.42
        bloom.Size=Vector3.new(3.5*scale,1.7,2.7*scale)
        for i=1,5 do local lump=props:FindFirstChild("LootLump"..i); lump.Transparency=if p.bulk>=i*2 then 0 else 1 end
    end
    local parking=root.Position.Z>0
    local speed=if p.role=="Gran" then Rules.speed(p.class,p.bulk,p.fizz,parking) else (if p.segway then 28 else 18)
    if p.role=="Cop" and p.segway then
        if root.Position.X < -46 and root.Position.Z < -25 then speed=14 end
        if (p.slipUntil or 0)>now then speed=10 end
    end
    if p.hits>0 and now-p.lastHit<8 then speed*=0.65 end
    if p.stunUntil>now or p.status~="Active" or p.car then speed=0 end
    hum.WalkSpeed=speed; hum.JumpPower=if speed==0 then 0 else 40
    hum.AutoRotate=speed~=0
end
return Characters

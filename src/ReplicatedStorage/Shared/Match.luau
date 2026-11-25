local Rules = if script then require(script.Parent.Rules) else require("./Rules")
local Config = if script then require(script.Parent.Config) else require("./Config")
local Match = {}
local function active(m, id, role)
    local p = m.players[id]
    return not m.result and p and p.connected and p.role == role and p.status == "Active" and p
end
local function unboard(m, p)
    if p.car then m.cars[p.car].riders[p.id] = nil end
    p.car, p.seat = nil, nil
end
local function drop(m, p)
    for _, id in p.bag do m.loot[id].owner = nil end
    p.bag, p.bulk = {}, 0
end
local function finish(m, result)
    if m.result then return end
    m.result, m.phase = result, "Payout"
    for _, p in m.players do
        p.reward = p.banked + (if p.status == "Escaped" then Config.EscapeBonus else 0)
            + (if p.role == "Cop" and result == "Cops" then Config.CopWinReward else 0)
    end
end
function Match.new(players, now, loot)
    local m = {players={}, cars={}, loot={}, started=now, updated=now, phase="Heist", extracted=0, practice=#players==1}
    for _, data in players do
        m.players[data.id] = {id=data.id,name=data.name or tostring(data.id),role=data.role,class=data.class or "Manager",
            connected=true,status="Active",bag={},bulk=0,fizz=0,banked=0,receipt={},hits=0,lastHit=-100,
            gates={},stunUntil=0,segway=false, reward=0,priority=data.priority or false}
    end
    for id, item in loot do m.loot[id] = table.clone(item) end
    for i=1,3 do m.cars[i]={id=i,riders={},cargo=0,departed=false} end
    return m
end
function Match.pickup(m,id,lootId)
    local p, item = active(m,id,"Gran"), m.loot[lootId]
    if not p or p.car or not item or item.owner or not Rules.canCarry(p.class,p.fizz,p.bulk,item.bulk) then return false end
    item.owner=id; table.insert(p.bag,lootId); p.bulk+=item.bulk
    return true
end
function Match.bank(m,id,carId)
    local p, car=active(m,id,"Gran"),m.cars[carId]
    if not p or not car or car.departed or #p.bag==0 then return false end
    for _, lootId in p.bag do
        local item=m.loot[lootId]
        item.owner="Banked"; car.cargo+=item.value; p.banked+=item.value
        table.insert(p.receipt,{name=item.name or item.kind,value=item.value})
    end
    p.bag,p.bulk={},0
    return true
end
function Match.board(m,id,carId,seat)
    local p,car=active(m,id,"Gran"),m.cars[carId]
    if not p or not car or car.departed or (seat~="Seat" and seat~="Hitch") then return false end
    unboard(m,p); p.car,p.seat=carId,seat; car.riders[id]=seat
    return true
end
function Match.leaveCar(m,id)
    local p=active(m,id,"Gran")
    if not p or not p.car then return false end
    unboard(m,p); return true
end
function Match.depart(m,id,carId,now)
    local p,car=active(m,id,"Gran"),m.cars[carId]
    if not p or not car or p.car~=carId or car.riders[id]~="Seat" or car.departed or car.leavesAt then return false end
    if car.driver and car.driver~=id then return false end
    car.driver=id; car.leavesAt=now+Config.DepartureDelay
    return true
end
function Match.capture(m,id)
    local p=active(m,id,"Gran")
    if not p then return false end
    unboard(m,p); drop(m,p)
    p.status,p.fizz,p.hits="Detained",0,0
    return true
end
function Match.tag(m,copId,granId,now)
    local cop,gran=active(m,copId,"Cop"),active(m,granId,"Gran")
    if not cop or not gran or cop.stunUntil>now or not Rules.allow(cop.gates,"tag",now,Config.HitCooldown) then return false end
    gran.hits=(if now-gran.lastHit<=Config.HitWindow then gran.hits else 0)+1
    gran.lastHit=now
    if gran.hits>=2 then Match.capture(m,granId) end
    return true
end
function Match.rescue(m,id,target)
    local p,gran=active(m,id,"Gran"),m.players[target]
    if not p or p.car or not gran or not gran.connected or gran.role~="Gran" or gran.status~="Detained" then return false end
    gran.status,gran.hits="Active",0
    return true
end
function Match.drink(m,id)
    local p=active(m,id,"Gran")
    if not p or p.car then return false end
    p.fizz=100; return true
end
function Match.ability(m,id,now)
    local p=active(m,id,"Gran")
    if not p or p.car or p.class=="Hoarder" then return false end
    return Rules.allow(p.gates,"ability",now,if p.class=="Manager" then Config.ManagerCooldown else Config.DashCooldown)
end
function Match.disconnect(m,id)
    local p=m.players[id]
    if not p or not p.connected then return end
    unboard(m,p); drop(m,p); p.connected=false
    Match.tick(m,m.updated)
end
function Match.tick(m,now)
    if m.result then return end
    local dt=math.max(0,now-m.updated); m.updated=now
    for _, p in m.players do p.fizz=math.max(0,p.fizz-dt*Config.FizzDecay) end
    for _, car in m.cars do
        if not car.departed and car.leavesAt and now>=car.leavesAt then
            local count=0
            for id in car.riders do
                local p=active(m,id,"Gran")
                if p then p.status="Escaped"; p.car=nil; p.seat=nil; count+=1 end
            end
            if count>0 then car.departed=true; m.extracted+=car.cargo
            else car.leavesAt=nil; car.driver=nil end
        end
    end
    local cops,grans,free=0,0,0
    for _,p in m.players do
        if p.connected then
            if p.role=="Cop" then cops+=1 else grans+=1; if p.status=="Active" then free+=1 end end
        end
    end
    if grans==0 then finish(m,"Cops")
    elseif cops==0 and not m.practice then finish(m,"Grans")
    elseif now-m.started>=Config.Heist or free==0 then finish(m,if m.extracted>=Config.Target then "Grans" else "Cops")
    elseif now-m.started>=Config.Heist-Config.EscapeWindow then m.phase="Escape" end
end
function Match.snapshot(m)
    local players,cars={},{}
    for _,p in m.players do
        table.insert(players,{id=p.id,name=p.name,role=p.role,class=p.class,status=p.status,connected=p.connected,
            bulk=p.bulk,capacity=Rules.capacity(p.class,p.fizz),fizz=p.fizz,banked=p.banked,hits=p.hits,
            car=p.car,seat=p.seat,segway=p.segway,stunUntil=p.stunUntil,abilityAt=p.gates.ability or 0,
            wandAt=p.gates.wand or 0,reward=p.reward,receipt=p.receipt})
    end
    for _,car in m.cars do table.insert(cars,{id=car.id,cargo=car.cargo,departed=car.departed,leavesAt=car.leavesAt,driver=car.driver}) end
    return {phase=m.phase,remaining=math.max(0,Config.Heist-(m.updated-m.started)),players=players,cars=cars,
        extracted=m.extracted,result=m.result}
end
return Match

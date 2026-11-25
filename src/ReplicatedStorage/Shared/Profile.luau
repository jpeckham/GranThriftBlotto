local Catalog=if script then require(script.Parent.Catalog) else require("./Catalog")
local Rules=if script then require(script.Parent.Rules) else require("./Rules")
local Profile={}
function Profile.new()
    return {version=1,bucks=0,owned={},equipped={},rounds={},receipts={}}
end
function Profile.normalize(raw)
    local p=Profile.new()
    if type(raw)~="table" then return p end
    if Rules.finite(raw.bucks) and raw.bucks>=0 then p.bucks=math.min(math.floor(raw.bucks),1e9) end
    if type(raw.owned)=="table" then for id in Catalog.Cosmetics do if raw.owned[id]==true then p.owned[id]=true end end end
    if type(raw.equipped)=="table" then for slot,id in raw.equipped do
        if type(id)=="string" and p.owned[id] and Catalog.Cosmetics[id].slot==slot then p.equipped[slot]=id end
    end end
    for _,field in {"rounds","receipts"} do
        if type(raw[field])=="table" then for id,value in raw[field] do if type(id)=="string" and value==true then p[field][id]=true end end end
    end
    return p
end
function Profile.purchase(p,id)
    local item=Catalog.Cosmetics[id]
    if not item or p.owned[id] or p.bucks<item.price then return false end
    p.bucks-=item.price; p.owned[id]=true; p.equipped[item.slot]=id; return true
end
function Profile.equip(p,id)
    local item=Catalog.Cosmetics[id]
    if not item or not p.owned[id] then return false end
    p.equipped[item.slot]=id; return true
end
function Profile.reward(p,roundId,amount)
    if type(roundId)~="string" or not Rules.finite(amount) or amount<0 or amount%1~=0 or p.rounds[roundId] then return false end
    p.rounds[roundId]=true; p.bucks=math.min(1e9,p.bucks+amount); return true
end
function Profile.receipt(p,purchaseId,productId,products)
    if type(purchaseId)~="string" then return false end
    if p.receipts[purchaseId] then return true end
    local product=products[productId]
    if not product or not Rules.finite(product.bucks) or product.bucks<=0 then return false end
    p.receipts[purchaseId]=true; p.bucks=math.min(1e9,p.bucks+math.floor(product.bucks)); return true
end
return Profile

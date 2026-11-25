local Profile=require("../src/ReplicatedStorage/Shared/Profile")
return {
    ["Purchases require funds and cannot charge twice"] = function()
        local p=Profile.new(); assert(not Profile.purchase(p,"PlumDress")); assert(p.bucks==0)
        p.bucks=200; assert(Profile.purchase(p,"PlumDress")); assert(p.bucks==50)
        assert(not Profile.purchase(p,"PlumDress")); assert(p.bucks==50)
    end,
    ["Only owned cosmetics can be equipped in their slot"] = function()
        local p=Profile.new(); assert(not Profile.equip(p,"PinkWig"))
        p.bucks=100; Profile.purchase(p,"PinkWig"); assert(Profile.equip(p,"PinkWig")); assert(p.equipped.Wig=="PinkWig")
    end,
    ["Rewards are idempotent and invalid currency rejected"] = function()
        local p=Profile.new(); assert(Profile.reward(p,"round1",375))
        assert(not Profile.reward(p,"round1",375)); assert(p.bucks==375)
        assert(not Profile.reward(p,"bad",-10)); assert(not Profile.reward(p,"nan",0/0))
    end,
    ["Durable product receipts grant exactly once"] = function()
        local p=Profile.new(); local products={[99]={bucks=50}}
        assert(Profile.receipt(p,"purchase-1",99,products)); assert(p.bucks==50)
        local loaded=Profile.normalize(p)
        assert(Profile.receipt(loaded,"purchase-1",99,products)); assert(loaded.bucks==50)
        assert(not Profile.receipt(loaded,"unknown",7,products))
    end,
    ["Normalization rejects invalid balances and unowned equips"] = function()
        local p=Profile.normalize({bucks=math.huge,owned={PlumDress=true,Injected=true},equipped={Dress="MintDress"}})
        assert(p.bucks==0 and p.owned.PlumDress and not p.owned.Injected and not p.equipped.Dress)
        assert(Profile.normalize("invalid").bucks==0)
    end,
}

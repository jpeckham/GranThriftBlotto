local Match = require("../src/ReplicatedStorage/Shared/Match")
local function game()
    return Match.new({{id=1,role="Gran",class="Manager"},{id=2,role="Gran",class="Hoarder"},{id=3,role="Cop"}},0,
        {a={kind="Painting",value=300,bulk=4}, b={kind="Shoes",value=250,bulk=3}})
end
return {
    ["Only active Grans can drink or activate class abilities"] = function()
        local m=game(); assert(Match.drink(m,1)); assert(m.players[1].fizz==100)
        assert(not Match.drink(m,3)); assert(Match.ability(m,1,0)); assert(not Match.ability(m,1,1))
        assert(Match.ability(m,1,22)); Match.capture(m,1); assert(not Match.ability(m,1,50)); assert(not Match.drink(m,1))
    end,
    ["Manager stun prevents cop attacks until exact expiry"] = function()
        local m=game(); m.players[3].stunUntil=3
        assert(not Match.tag(m,3,1,2.99)); assert(Match.tag(m,3,1,3))
    end,
    ["Atomic pickups cannot be claimed twice"] = function()
        local m=game(); assert(Match.pickup(m,1,"a")); assert(not Match.pickup(m,2,"a"))
        assert(m.players[1].bulk==4 and m.players[2].bulk==0)
    end,
    ["Two tags detain and return unbanked goods"] = function()
        local m=game(); Match.pickup(m,1,"a")
        assert(Match.tag(m,3,1,1)); assert(m.players[1].status=="Active")
        assert(not Match.tag(m,3,1,1.1))
        assert(Match.tag(m,3,1,2.3)); assert(m.players[1].status=="Detained")
        assert(m.loot.a.owner==nil and m.players[1].bulk==0)
        assert(Match.rescue(m,2,1)); assert(m.players[1].status=="Active")
    end,
    ["Banked goods follow their Buick and hitchers escape"] = function()
        local m=game(); Match.pickup(m,1,"a"); Match.bank(m,1,1)
        Match.pickup(m,2,"b"); Match.bank(m,2,1)
        assert(Match.board(m,1,1,"Seat")); assert(Match.board(m,2,1,"Hitch"))
        assert(Match.depart(m,1,1,10)); assert(not Match.depart(m,1,1,10))
        Match.tick(m,17)
        assert(m.cars[1].departed and m.extracted==550)
        assert(m.players[2].status=="Escaped")
        assert(m.result=="Grans")
        assert(m.players[1].reward==375 and m.players[2].reward==325)
    end,
    ["Unextracted deposits pay depositor but do not win"] = function()
        local m=game(); Match.pickup(m,1,"a"); Match.bank(m,1,1)
        Match.pickup(m,2,"b"); Match.bank(m,2,1); Match.tick(m,240)
        assert(m.result=="Cops" and m.extracted==0 and m.players[1].reward==300)
        Match.tick(m,500); assert(m.players[1].reward==300)
    end,
    ["Hit window expires"] = function()
        local m=game(); Match.tag(m,3,1,1); Match.tag(m,3,1,10)
        assert(m.players[1].status=="Active" and m.players[1].hits==1)
    end,
    ["Detained players cannot act or rescue"] = function()
        local m=game(); Match.capture(m,1)
        assert(not Match.pickup(m,1,"a")); assert(not Match.bank(m,1,1))
        assert(not Match.rescue(m,1,2)); assert(not Match.board(m,1,1,"Seat"))
    end,
    ["Fizz expiration keeps items and blocks further overcapacity loot"] = function()
        local m=game(); m.players[1].fizz=1; m.players[1].bulk=12
        Match.tick(m,1); assert(m.players[1].fizz==0 and m.players[1].bulk==12)
        assert(not Match.pickup(m,1,"a"))
    end,
    ["Disconnect returns carried loot and resolves empty teams"] = function()
        local m=game(); Match.pickup(m,1,"a"); Match.disconnect(m,1)
        assert(m.loot.a.owner==nil); Match.disconnect(m,2)
        assert(m.result=="Cops")
    end,
    ["All cops leaving resolves for remaining Grans"] = function()
        local m=game(); Match.disconnect(m,3); assert(m.result=="Grans")
    end,
    ["Empty cars cannot depart and car hopping clears old membership"] = function()
        local m=game(); assert(not Match.depart(m,1,1,0))
        Match.board(m,1,1,"Seat"); Match.board(m,1,2,"Hitch")
        assert(m.players[1].car==2 and not m.cars[1].riders[1])
    end,
}

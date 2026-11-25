local Rules = require("../src/ReplicatedStorage/Shared/Rules")
return {
    ["Hoarder holds 40 percent more"] = function()
        assert(Rules.capacity("Hoarder", 0) == 14)
        assert(Rules.capacity("Manager", 0) == 10)
    end,
    ["Fizz expands capacity without permitting overfill"] = function()
        assert(Rules.canCarry("Manager", 0, 8, 2))
        assert(not Rules.canCarry("Manager", 0, 8, 3))
        assert(Rules.canCarry("Manager", 50, 10, 2))
        assert(not Rules.canCarry("Manager", 0, 12, 1))
    end,
    ["Turbo asphalt bonus is twenty percent"] = function()
        assert(math.abs(Rules.speed("Turbo", 0, 0, true) - 19.2) < 0.001)
        assert(Rules.speed("Turbo", 0, 0, false) == 16)
        assert(Rules.speed("Manager", 8, 0, false) < 16)
        assert(Rules.speed("Manager", 8, 100, false) > 16)
    end,
    ["Role counts support small and full lobbies"] = function()
        for _, count in {2, 3, 4, 10} do
            local players = {}
            for id = 1, count do table.insert(players, {id=id, preference="Cop"}) end
            local roles = Rules.roles(players, function() return 0.5 end)
            local cops, grans = 0, 0
            for _, role in roles do if role == "Cop" then cops += 1 else grans += 1 end end
            assert(cops == (if count >= 4 then 2 else 1))
            assert(grans == count - cops)
        end
    end,
    ["Malformed numeric input is rejected"] = function()
        assert(not Rules.finite(0/0))
        assert(not Rules.finite(math.huge))
        assert(not Rules.finite("20"))
        assert(Rules.finite(0))
    end,
    ["Cooldown permits exact boundary but throttles spam"] = function()
        local gates = {}
        assert(Rules.allow(gates, "hit", 10, 1))
        assert(not Rules.allow(gates, "hit", 10.9, 1))
        assert(Rules.allow(gates, "hit", 11, 1))
    end,
}

local Rules = {}
function Rules.finite(n)
    return type(n) == "number" and n == n and math.abs(n) < math.huge
end
function Rules.capacity(class, fizz)
    return 10 * (if class == "Hoarder" then 1.4 else 1) + (if fizz > 0 then 4 else 0)
end
function Rules.canCarry(class, fizz, bulk, extra)
    return Rules.finite(extra) and extra > 0 and bulk + extra <= Rules.capacity(class, fizz)
end
function Rules.speed(class, bulk, fizz, parking)
    return math.max(9, 16 - bulk * 0.4) * (if class == "Turbo" and parking then 1.2 else 1)
        + (if fizz > 0 then 7 * fizz / 100 else 0)
end
function Rules.allow(gates, key, now, interval)
    if now < (gates[key] or -math.huge) then return false end
    gates[key] = now + interval
    return true
end
function Rules.roles(players, random)
    random = random or math.random
    local roles, pool = {}, table.clone(players)
    local count = if #players == 1 then 0 elseif #players >= 4 then 2 else 1
    for _ = 1, count do
        local total = 0
        for _, p in pool do total += (if p.preference == "Cop" then (if p.priority then 5 else 2) else 1) end
        local target, chosen = random() * total, #pool
        for i, p in pool do
            target -= (if p.preference == "Cop" then (if p.priority then 5 else 2) else 1)
            if target <= 0 then chosen = i; break end
        end
        roles[table.remove(pool, chosen).id] = "Cop"
    end
    for _, p in pool do roles[p.id] = "Gran" end
    return roles
end
return Rules

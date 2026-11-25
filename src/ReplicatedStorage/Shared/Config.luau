return table.freeze({
    MaxPlayers = 10, MinPlayers = 2, Practice = true,
    Intermission = 18, Intro = 6, Heist = 240, EscapeWindow = 30, Payout = 12,
    Target = 500, Capacity = 10, BaseSpeed = 16, FizzDecay = 2,
    HitCooldown = 1.2, HitWindow = 8, TagRange = 8, Stun = 3,
    ManagerCooldown = 22, DashCooldown = 12, WandCooldown = 15,
    DepartureDelay = 7, EscapeBonus = 75, CopWinReward = 125,
    -- Owner config: 0 means unavailable. Never use placeholder paid IDs.
    Passes = { GoldenBuick = 0, VIP = 0, TacticalSegway = 0, RolePriority = 0 },
    Products = {},
    DataStore = "GranThriftBlotto_v1", ProfileLease = 180,
})

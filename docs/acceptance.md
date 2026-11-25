# PRD acceptance and verification

Status: implemented source under review; **native Roblox acceptance is pending**.
This is a game implementation, not a published Roblox experience.

## Automated evidence

- 27 Lune tests execute production rules, match actions, profiles and map generation.
- Every Luau source compiles through `@lune/luau`.
- Rojo builds the DataModel. Lune bakes the map and deserializes the resulting
  binary place to confirm it contains map and server scripts.
- Selene static analysis and independent code review are recorded below after
  their final runs. Source tests do not execute Roblox engine physics or services.

## Requirement mapping

| PRD requirement | Implementation | Native check still required |
|---|---|---|
| 10 players, two cops/eight Grans, four-minute round | Config, Rules.roles, Match, Game | Full ten-client round and timer |
| Lobby → Buick intro → heist → extraction → payout | Game phases, Match.tick | Full cycle and reset |
| Dense one-store/four-zone map | Map.build | Walk all aisles, doors and shortcuts |
| Shoes, inserts, figurines, paintings, haunted phones | Catalog.Loot, generated props | Prompt usability and loot visuals |
| Expanding bloomers worn outside floral dresses | Characters.apply | R6/R15 appearance and collisions |
| Fizz speed/capacity/wobble/hiccup | Rules, Match.drink, Game sound, Effects | Steering/visual/audio comfort and reset |
| Manager cone/3-second stun/scanner shutdown | Match.ability, Game.ability | Cone/occlusion, timing, complaint cue |
| Hoarder 40% capacity, silent fragile pickup | Rules.capacity, Game loot handler | No crash alert from Hoarder |
| Turbo Walker 20% asphalt boost/dash ram | Rules.speed, Characters, Game.ability | Walker appearance, dash and dismount |
| Segway fast tile/reduced carpet and puddle traction | Characters, Game update | Actual physics/movement feel |
| Two tags, detention, loot confiscation/return | Match.tag/capture, Game | Wall blocking, hit timings, reset/death |
| Held detention rescue | Map rescue prompt, Match.rescue, Game | Hold duration and valid proximity |
| Security wand through racks, alarms and CCTV | Game actions/scanners, Effects | Visibility, all cameras and camera exit |
| Buick deposit/driver/departure/stragglers/hitch | Match, Map car prompts, Game animation | Rider seats, bumper and warning timing |
| Buick intro with bottle props | Game.beginRound | Camera, car movement and bottles |
| HUD capacity/Fizz/escape/alerts | UI | Desktop, narrow phone, gamepad |
| Receipt/payout/soft currency wardrobe | UI, Profile, Economy | Itemization, wallet updates and equip |
| Golden Buick, VIP, tactical Segway, role priority | Catalog, Config pass IDs, Game/Characters | Real pass ownership, visuals and pricing |
| Developer-product hook | Economy.ProcessReceipt, Profile.receipt | Real durable receipt retry/idempotence |
| Late join/death/respawn/disconnect | Game lifecycle, Match.disconnect | Multi-client join/reset/leave during every phase |
| Save safety/reward/receipt deduplication | Profile + Economy session lease/UpdateAsync | Failed load, competing server, failed save, reconnect |
| Moderation-oriented terminology | Fizz names, external costume props | Owner's final content/moderation review |

## Native acceptance procedure

1. Open `build/GranThriftBlotto.rbxl` in Studio. Play solo practice. Check
   Output for errors, walk all zones, pick up/bank/escape and see payout/reset.
2. Start Server & Clients with at least four clients. Verify two cops, two
   Grans, lobby choices, intro, 240-second clock, late-join spectator behavior.
3. Play each Gran class; verify Fizz expiry with an overcapacity bag keeps
   items; verify all effects clear on capture, escape, reset and respawn.
4. Tag twice, rescue, reset a character, disconnect/reconnect. Check shelves
   restore, banked rewards are not duplicated, and the round always resolves.
5. Trigger scanners, complaint shutdown, fragile crash, wand and each CCTV
   view. Verify attacks and rescues cannot cross walls or exceed range.
6. Bank $500+, board seats and hitchers, leave a rider behind, start departure,
   unboard during countdown, attempt duplicate departure. Verify actual cargo
   and individual receipt totals and post-round camera/movement state.
7. Use Studio Device Emulator on phone-sized screens and a gamepad. Check
   all actions, menu scrolling, modal focus, prompts and CCTV exit.
8. In an owned test experience, configure pass IDs and audio; test ownership,
   actual prices, cosmetic activation, persistence after rejoin, rejected
   writes after a failed load, and receipt retry after simulated store failure.

## Environment limitation

Roblox Studio was not found in installed locations or running processes, and
no Roblox runtime connector is available. Automatic approval review rejected
the download/launch installation command with “blocked by policy”. No native
playtest or live Marketplace/DataStore verification has been claimed.

# PRD acceptance and verification

Status: source reviewed and fixes verified; **native Roblox acceptance is pending**.
A private cloud playtest copy was saved on 2026-11-25 under JheredParnell:
universe `10779045356`, start place `71312709063689`. Public release is off.
Tester invitation completion and production-service verification remain open.

## Automated evidence

- 49 Lune tests execute production rules, match actions, profiles, map generation,
  real Economy service logic, real UI construction/actions and camera cleanup.
  Service-boundary tests replace external Roblox services and events; they
  are not a substitute for native engine acceptance.
- Every Luau source compiles through `@lune/luau`.
- Rojo builds the DataModel. Lune bakes the map and deserializes the resulting
  binary place to confirm it contains map and server scripts.
- Latest source run: 49/49 tests; 13 source files compile; Selene reports
  0 errors, 0 warnings and 0 parse errors; Rojo and binary map packaging pass.
  Source tests do not execute Roblox engine physics or live online services.

## Independent review and fix evidence

The reviewer inspected the full source branch at `9c917f0` and reported no
Critical findings, four Important findings, and three smaller gaps. All were
addressed in the same fix pass; fixes are verified by regression tests rather
than an additional reviewer pass.

| Finding | Fix and regression |
|---|---|
| UpdateAsync callback retry can lose lease but acknowledge an unpersisted receipt | Reset ownership flag on every transform; require persisted return value. Multi-callback lease-takeover test failed before fix and now passes. |
| Failed profile load cannot recover on same-server rejoin | Remove failed/unwritable sessions on departure without saving them. Same-server rejoin test failed before fix and now passes. |
| Touch/gamepad CCTV lacks exit/cycle controls | Visible HUD controls, LB/RB bindings and local camera release. Actual production UI callback test failed before fix and now passes. |
| Donation shortcut does not bypass scanners; unsupported exterior | Connect fitting-room vent to supported exterior side walkway. Map traversal endpoint/support test failed before fix and now passes. |
| Monitor wall lacks live aisle alerts | Motion sensing and timed alert/clear labels. Map monitor-state test failed before fix and now passes. |
| Stash/Fizz visuals persist on escape/payout | Clear unbanked bags/Fizz at those transitions, retain deposit receipt. Both match regression tests failed before fix and now pass. |
| HUD omits carried value and wand cooldown | Add both fields/displays. Actual UI render test failed before fix and now passes. |

Additional checks protect car color/scanner reset, animated escape-rider
retention, touch horn/unboarding and camera cleanup after detention,
character replacement and round transition. Departure prompts remain usable
inside car geometry while the server checks range and chosen driver.

## Native Studio startup evidence — 2026-11-25

Studio 0.748.0.7481526 is now installed and signed in. Native Play testing
exposed two issues that standalone service doubles did not reproduce:

- Opening DataStoreService before checking `IsStudio()` prevented an
  unpublished local place from starting. Studio startup now avoids opening a
  DataStore entirely and uses the intended temporary wallet. A regression
  test reproducing the native error failed before the fix and now passes.
- The client main script could execute before its sibling UI module had
  replicated. Client module dependencies now use `WaitForChild`.

After these fixes the native smoke runner returned `passed: true`, one player,
phase `Heist`, and no captured game-script errors. It verified native Studio
wallet initialization, client HUD initialization, costume construction and
solo round startup. The same packaged place was opened and played in the
visible Studio window; HUD, intro and Heist were visually observed without
game-script errors. Machine-readable evidence, including the tested place
hash, is in `verification/native-smoke-2026-11-25.json`.

Subsequent native suites now cover:

- **Heist, four clients, 41 checks:** first-join guide display/dismissal,
  lobby/intro/240-second clock, loot and
  Fizz prompts, Manager stun, capture/rescue, Segway slip, wand, CCTV exit
  through an actual button click, vent traversal, banking over $500, seating
  and hitching, departure/stragglers, payout receipt and camera reset.
- **Classes/lifecycle, six growing to eight clients, 38 checks:** Hoarder
  capacity and silent fragile loot, Fizz expiry with excess cargo, death and
  respawn detention, rescue, late joining, next-round selection/reset, Turbo
  movement/speed/ram/cooldown, carrying-player disconnect and timeout resolution.
- **Phone landscape, 567×319 viewport, 20 checks:** first-join guide persistence,
  actual dismissal button, Gran/Cop instruction text fitting, safe-area bounds,
  nonoverlapping stash/actions/car status, text fitting in the HUD/help/classes,
  and accessible Cop CCTV exit. Portrait was requested in an earlier test but
  the experience retained landscape; portrait support is not claimed.

Saved results and artifact hashes are in `verification/native-{heist,classes,
mobile-landscape}-2026-11-25.json`. These are native scripted scenarios: fixtures
position players, accelerate selected timers and inspect state. They do not
replace human assessment of controls, character appearance or camera comfort.

The tests exposed and verified fixes for a server-only dash velocity being
overwritten by native character physics and for the phone HUD overlapping its
action bar. Turbo now uses a short-lived replicated velocity actuator; the HUD
adapts its geometry and text sizes to smaller viewports. Modern TextChatService
is explicitly configured, and bundled fallback audio paths reference installed
Roblox content files. Native game-script error checks are green; platform
messages, when present, are recorded separately in the JSON.

Beginner guidance now uses numbered, role-specific instructions and the actual
prompt labels from the map. The Help panel stays open until explicitly dismissed;
role objectives and next-step hints remain on the HUD. Source regressions verify
collection/banking, driver/hitcher instructions (including a missing driver),
departure countdown, detention, late joins and guide dismissal. This addresses
the first private playtest feedback that the game did not explain how to play.

## Execution decisions

- Used native inline execution on `codex/full-game` in the requested checkout,
  leaving `main` unchanged. This avoids moving the workspace again; changes
  are visible to any other editor sharing this checkout.
- Built persistence before live server wiring, so the runtime uses the real
  Economy service instead of a temporary alternate implementation. No product
  scope changed.
- Resolved the reviewer's smaller gaps because they are explicit design/PRD
  requirements. No review findings were silently deferred as polish.
- The reviewer declined to judge native prompt visibility, rider collisions,
  R6/R15 visuals, camera comfort, dash/Segway feel and live online services
  without Studio. Those remain explicit acceptance gates below, not completed
  requirements. The cost of proceeding without them would be shipping
  unverified controls, physics and persistence; the goal stays unfinished.

## Requirement mapping

| PRD requirement | Implementation | Native check still required |
|---|---|---|
| 10 players, two cops/eight Grans, four-minute round | Config, Rules.roles, Match, Game; native 4/8 clients and 240-second clock | Published ten-player round (Studio limit is eight) |
| Lobby → Buick intro → heist → extraction → payout | Game phases, Match.tick; native full cycle and reset | Human pacing assessment |
| Dense one-store/four-zone map | Map.build | Walk all aisles, doors and shortcuts |
| Shoes, inserts, figurines, paintings, haunted phones | Catalog.Loot, generated props | Prompt usability and loot visuals |
| Expanding bloomers worn outside floral dresses | Characters.apply | R6/R15 appearance and collisions |
| Fizz speed/capacity/wobble/hiccup | Rules, Match.drink, Game sound, Effects | Steering/visual/audio comfort and reset |
| Manager cone/3-second stun/scanner shutdown | Match.ability, Game.ability | Cone/occlusion, timing, complaint cue |
| Hoarder 40% capacity, silent fragile pickup | Rules.capacity, Game loot handler; native capacity/silence pass | Human feedback assessment |
| Turbo Walker 20% asphalt boost/dash ram | Rules.speed, Characters, Game.ability; native movement/ram/dismount pass | Walker appearance and dash feel |
| Segway fast tile/reduced carpet and puddle traction | Characters, Game update | Actual physics/movement feel |
| Two tags, detention, loot confiscation/return | Match.tag/capture, Game | Wall blocking, hit timings, reset/death |
| Held detention rescue | Map rescue prompt, Match.rescue, Game; native held prompt pass | Human touch/gamepad usability |
| Security wand through racks, alarms and CCTV | Game actions/scanners, Effects | Visibility, all cameras and camera exit |
| Buick deposit/driver/departure/stragglers/hitch | Match, Map car prompts, Game animation | Rider seats, bumper and warning timing |
| Buick intro with bottle props | Game.beginRound | Camera, car movement and bottles |
| HUD capacity/Fizz/escape/alerts | UI; native HUD/menu checks at 567×319 | Human phone/gamepad interaction and rotation |
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

## Remaining environment gates

James installed Studio and signed in after the earlier installer command
was blocked by automatic approval review. Native local testing is now
available; live Marketplace and production DataStore checks still require
an owned published test experience and owner-specific IDs. Those external
configuration and publishing steps have not been performed.

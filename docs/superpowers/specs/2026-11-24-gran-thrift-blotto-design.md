# Gran Thrift Blotto — implementation design

Status: approved by James on 2026-11-25. Source of requirements:
`gran_thrift_blotto_roblox_prd.md`. This covers the full PRD.

## Intent and approach

Build a playable asymmetric Roblox party game for up to ten players in a
single thrift store and parking lot. Preserve the PRD's comedy, non-alcoholic
Fizz, and exaggerated bloomers worn over dresses.

Native Luau with Rojo is the proposed approach: it matches the specified
platform, supports multiplayer and Roblox purchases, and keeps source
reviewable. A browser recreation would change the requested platform.
Hand-authoring everything inside an opaque Studio place would make future
code review and changes harder. Generate the map and props from source and
produce a place through Rojo. Custom production art and recorded voice lines
can replace generated geometry and text effects later; the mechanics must
work with the supplied geometry.

The following unspecified rules are builder proposals, open to correction.
They are not recorded as prior user decisions.

## Architecture and authority

- `ReplicatedStorage/Shared`: configuration, class/loot/cosmetic catalogs,
  pure inventory, round, role-selection, scoring rules and shared types.
- `ServerScriptService/Core`: match orchestration, map generation, interaction
  validation, character state, inventory, abilities, vehicles, security,
  economy, persistence, purchase fulfillment, and remote-event setup.
- `StarterPlayer/StarterPlayerScripts`: input, camera/cutscene, Fizz effects,
  local visuals and responsive HUD/shop/receipt UI.
- `default.project.json`: complete Rojo DataModel mapping.

The server owns roles, round phase, inventory, timers, money, ownership,
captures, cooldowns and distance checks. Clients request actions; they cannot
provide authoritative rewards, damage, prices or capture targets without
server validation. Rate-limit requests, reject malformed payloads, and clear
round-specific state after every match.

## Round and multiplayer rules

Support 2–10 players; waiting players can select classes and a preferred role.
Normal games assign two cops with enough players (four or more); two/three
player games use one cop so there is always a Gran. A Studio practice setting
allows one-player testing without changing production minimums. Role priority
adds weight rather than guaranteeing a role.

Intermission → Buick Intro → Heist (240 seconds) → Escape → Payout.
The escape phase is a brief resolution window within the four-minute heist
clock: escaping is available during the heist and the final countdown makes
it urgent. The round closes when time expires or all Grans have escaped or
are detained with nobody able to rescue them. Grans win by extracting at
least $500 in banked goods; cops win otherwise. Each deposit belongs to
that Buick's cargo and retains its depositor for receipts and personal
currency. Banked currency survives capture. Cargo counts toward the team win
only when its Buick departs with at least one active Gran aboard or hitching;
the depositor need not be aboard. Cargo on a car that never departs does not
count toward the $500 objective. An escape bonus rewards individual survival.

Late joiners wait in the lobby until the next round. Death/reset returns
active Grans to detention and active cops to HQ, avoiding reset-based escapes.
Disconnects update terminal-state detection. Character respawns reapply state.
If all cops disconnect, resolve for remaining Grans; if all Grans disconnect,
resolve for cops. Cancel a lobby countdown if too few players remain.

## Map, loot and extraction

Generate Thrifty Acres with four connected zones: parking/lobby with 2–3
Buicks; thrift floor with shoes, figurines, paintings and phones; fitting
rooms/donation shortcuts; security office with CCTV and detention bench.
Use collision geometry, accessible doorways, clear labels and distinct colors.
All required interactions have keyboard/gamepad/mobile ProximityPrompts or
touch buttons as appropriate.

Each loot item has value, bulk and fragility. Pickup claims are atomic and
server-validated. Capacity follows class and Fizz modifiers. Loot visibly
expands an external bloomer accessory and slows the carrier. Capture restores
unbanked items to their spawn points. Round reset restores all loot.

Buick trunks bank carried items. A driver starts a warned departure countdown;
nearby Grans can board or hitch to the bumper. Only boarded/hitching Grans
escape with that car. Departed cars stop accepting interactions. The intro
animates cars and harmless Fizz bottle props; extraction animates departure.

## Gran gameplay

Fizz cooler refills a decaying meter that increases speed and capacity, with
client camera sway and bounded steering drift. When boosted capacity expires,
retain existing items but prohibit additional pickup until under capacity.
Stash and camera visuals reset on capture, escape, respawn and payout.

- Manager: server-checked forward cone, three-second cop stun and temporary
  scanner shutdown in range; readable complaint text effect and cooldown.
- Velvet Hoarder: 40% extra capacity and silent fragile pickups.
- Turbo Walker: walker prop, cooldown dash/ram that dismounts cops, plus 20%
  speed on parking asphalt.

Non-Hoarder fragile interactions produce crash alerts. Teammates can use a
held rescue prompt at detention; only free active Grans can rescue, and the
server checks distance and round state at completion.

## Cop gameplay and security

Segway mounting changes movement and adds a visible vehicle assembly. Smooth
tile supports fast patrol; carpet and Fizz puddles reduce traction. Movement
and stun/capture restrictions are applied on the server.

Foam baton/Velcro tagging requires two valid close-range hits with a cooldown
and hit window; the first slows, the second detains. Capture confiscates
unbanked loot and moves the Gran to the bench. No friendly fire or attacks
across walls. The tag wand temporarily reveals nearby Grans through racks.

Exit scanners alert cops when a loaded Gran crosses an enabled sensor.
Manager complaints temporarily disable nearby scanners. CCTV shows live
aisle alerts and selectable camera views; leaving the tablet, detention,
round transition and character replacement restore normal cameras.

## HUD, economy and cosmetics

Show phase/time, role, class and ability cooldown, capacity/value, Fizz,
banked loot, extraction availability, alarms and detention/rescue feedback.
Payout shows an itemized receipt, escape bonus, team outcome and Thrift Bucks.
Provide class selection, role preference, help, and cosmetic shop/equip flows.

Persist balances and cosmetic selections with versioned DataStore profiles.
Avoid overwriting profiles after failed loads; retry transient operations,
save periodically/on leave/on shutdown, and keep rewards server-owned.
Shop includes earnable dress/wig/walker colors and configured Roblox passes
for golden Buick, VIP bloomers/megaphone, tactical Segway, and role priority.
Expose real configured Marketplace prices. With product IDs unset, purchases
are visibly unavailable; never simulate a successful paid purchase.
Developer-product hooks must have durable idempotent receipt processing
before any repeatable paid reward is enabled. Prices and production IDs
require the owner's Creator Dashboard configuration.

## Verification and delivery

Deliver source, Rojo configuration, generated place/build command, setup and
controls README, and a PRD acceptance checklist. Automated Luau tests cover
capacity and speed modifiers, role assignment, phase transitions, capture,
banking/escaping payout, cooldowns, and receipt deduplication where enabled.
Build with Rojo and run available static analysis.

Roblox runtime verification must exercise a real Studio server with multiple
clients: full round, two-hit capture/rescue, each class, Fizz decay, scanners,
CCTV, car departure/stragglers, payout and reset, join/leave/reset handling,
and mobile UI. Record what was actually tested. A successful source build
alone does not prove multiplayer behavior. Any unavailable Studio or Roblox
credentials are explicit remaining gates, not grounds to claim completion.

Publishing the experience and creating paid products in the owner's account
are separate external steps; leave owner-specific IDs configurable. Avoid
new Beluga orchestration or dependencies: Codex owns further development.

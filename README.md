# Gran Thrift Blotto

A Roblox thrift-store heist: up to eight Grans stuff loot into Tactical
Bloomers while two Mall Cops try to detain them. Bank goods at a Buick,
rescue teammates, and extract at least $500 before the four-minute clock ends.

The implementation lives on `codex/full-game`. The Beluga transfer record is
in [docs/handoff/beluga-transfer.md](docs/handoff/beluga-transfer.md).

## Build and play

Rojo 7.7.1 and Lune 0.11.1 are pinned in `rokit.toml`. Use Rokit to install
these tools, or their official GitHub release binaries. On this workstation
the tools are already available in ignored `.tools/`.

```powershell
./scripts/test.ps1
./scripts/build.ps1
```

Open **`build/GranThriftBlotto.rbxl`** in Roblox Studio. This packaged place
includes the editor-visible map and all scripts. Press Play for solo practice;
use Studio's Server & Clients test with 2–10 players for multiplayer.
The map resets from source at game startup, so make map changes in
`src/ServerScriptService/Core/Map.luau` rather than the generated place.

For live source sync, run `rojo serve` (or `.tools/rojo.exe serve`) and connect
the Rojo Studio plugin. The `.rbxlx` build also contains the source scripts;
the map in that file is generated when Play begins.

Studio is not installed on the build workstation. Source checks and place
serialization have run; actual engine multiplayer and UI verification remain
open. See [docs/acceptance.md](docs/acceptance.md) for the evidence and exact
checks still needed. Do not treat a green rules suite as a live playtest.

## Controls

| Action | Keyboard | Other devices |
|---|---|---|
| Stash, drink, bank, board, depart, rescue | E near a prompt | Gamepad X / touch prompt |
| Gran ability / cop baton | Q; F or click also tags | Gamepad Y / R2; HUD action |
| Cop tag wand | R | Gamepad L2 / HUD |
| Mount/dismount Segway | G | Gamepad B / HUD |
| Leave a Buick | B | HUD |
| Cycle CCTV / return to character | C / X | Security monitor prompt |
| Buick horn (driver) | H | Keyboard |
| Menu, classes, preferences, wardrobe, receipt | M | Gamepad Select / HUD |

Grans choose Manager (complaint cone), Hoarder (40% more space and silent
fragile pickup), or Turbo Walker (dash ram and 20% parking-lot speed).
Fizz temporarily increases capacity and speed while wobbling the camera
and steering. If Fizz expires with a full bag, existing loot stays but
additional pickup is blocked until capacity is available.

Bank at a trunk **before** boarding. Seats and rear-bumper hitching both
count as riders. The chosen seated driver starts a seven-second departure;
unboarded players remain behind. Driver priority increases lottery weight.
Only cargo on a departed car counts toward the team's $500 objective.
Individual banked goods pay Thrift Bucks even if the depositor is later
detained; escaping adds $75. Two valid cop tags within eight seconds detain
a Gran and return unbanked loot to shelves. A free teammate can hold the
detention lock prompt to rescue everyone on the bench.

Production games wait for two players. At four or more players there are
two cops; two/three-player games use one. Studio solo practice is enabled
through `Config.Practice`. Late joiners enter the next round.

## Economy and owner configuration

`src/ReplicatedStorage/Shared/Config.luau` holds tuning, gamepass IDs, audio
asset paths, and the versioned DataStore name. All paid IDs default to `0`:
unconfigured passes display **Unavailable** and cannot be purchased.
Create the passes in the experience owner's Creator Dashboard, set the real
IDs, and set the PRD's intended prices there (199/149/129/79 Robux). The UI
loads actual Marketplace prices instead of trusting hard-coded amounts.

Soft currency buys dress, wig, and walker colors. Paid hooks cover golden
Buick/horn/bounce, VIP bloomers/complaint sound, tactical Segway, and weighted
role/driver priority. Replace the bundled fallback sound cues in `Config.Audio`
with approved, experience-authorized recordings for custom voice/audio polish.
No third-party art or audio uploads are required to build the place.

`Config.Products` is intentionally empty. If a repeatable Thrift Bucks product
is created, configure `[productId] = { bucks = amount }`; `ProcessReceipt`
persists each purchase ID atomically before granting. The current shop only
prompts gamepasses, so additional repeatable products are not sold by default.

Studio sessions use clearly labeled temporary wallets. Production uses
DataStore `UpdateAsync`, session leases, serialized mutations, retries,
autosave, leave/shutdown save, and duplicate round/receipt protection. A
failed load disables economy writes; it never saves a new empty profile over
the existing record. Test production persistence and purchases in an owned
test experience before publishing.

## Source layout

- `ReplicatedStorage/Shared`: catalogs, rule calculations, match model, profiles.
- `ServerScriptService/Core`: generated map, character visuals, live game, economy.
- `StarterPlayer/StarterPlayerScripts`: HUD/input, camera/Fizz effects.
- `tests`: production Luau rules and generated-instance tests, syntax compilation.
- `scripts`: deterministic source build and editor-visible map packaging.

Tool reference: [Rojo builds](https://rojo.space/docs/v7/getting-started/new-game/),
[Lune](https://lune-org.github.io/docs/getting-started/1-installation/),
[Studio setup](https://create.roblox.com/docs/studio/setup).

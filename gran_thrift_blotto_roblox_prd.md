# Product Requirements Document: *Gran Thrift Blotto* (Roblox Edition)

**Subtitle:** Asymmetric 1-Map Thrift-Store Heist & Escape Party Game (Grans vs. Mall Cops)

**Original Pitch By:** AtomDrake, Mike Dunham & James Peckham (November 2026)

**Target Build Environment:** Roblox Studio + Rojo File Sync via Beluga Multi-Agent Orchestrator (`beluga-labs/beluga`)

## 1. Executive Summary & Roblox Scope
*Gran Thrift Blotto* is a chaotic, asymmetrical round-based multiplayer party game on Roblox scoped similarly to *Rob Run*. Each 4-minute round takes place on **one dense, interactive thrift store & strip-mall parking lot map**. 

Up to **10 players** spawn into the lobby: **2 players** are randomly selected (or queue via priority pass) as **Mall Cops**, while the remaining **up to 8 players** spawn as **Grans** arriving in late-model Buicks. Grans waddle into the thrift store, load up on *"Sparkling Grape Fizz"* (Roblox TOS-compliant intoxication/dizzy mechanic), stuff high-value knick-knacks and used orthopedic shoes into their oversized *"Tactical Support Bloomers"* (comically expanding backpack/waistline physics), deploy class abilities like **"Get Me The Manager!"**, and sprint back to their Buick getaway car before time expires or the Mall Cops zip-tie them in the security backroom.

## 2. Roblox TOS & Compliance Guardrails (Critical)
To pass Roblox moderation cleanly while preserving 100% of the comedy:
* **Intoxication Reframing:** Wine coolers are themed as **"Sparkling Peach Fizz"**, **"Prune Juice Turbo"**, or **"Dizzy Juice"**. Drinking boosts movement speed and stash capacity while applying camera wobble, tilted ragdoll physics, and burp/hiccup sound effects—zero explicit alcohol references.
* **Undergarment Stash Reframing:** Styled visually as comically oversized, ruffled Victorian **"Tactical Bloomers" / "Mega-Girdle Satchels"** worn *over* floral dresses that visibly inflate and bulge with lumpy item silhouettes as Grans hoard loot.

## 3. Multi-Agent Worktree Architecture (Rojo + Beluga)
Structured for a weekend sprint using Rojo (`default.project.json`) so Beluga agents can write Luau scripts across isolated worktrees without `.rbxl` merge conflicts:

| Worktree / Directory | Agent Scope | Core Luau Responsibility |
| :--- | :--- | :--- |
| `wt/round-loop` (`src/ServerScriptService/Core`) | Match & Lobby Agent | 1-map round state machine (`Intermission` -> `Buick Intro` -> `Heist` -> `Escape/Extraction` -> `Payout`), asymmetric role assignment (2 Mall Cops vs. N Grans), and timer/scoring. |
| `wt/gran-mechanics` (`src/ReplicatedStorage/Grans`) | Gran Gameplay & Classes Agent | Bloomer inventory expansion scaling, Sparkling Fizz wobble/speed physics, Gran classes (*"Get Me The Manager"*, *Orthopedic Sprinter*, *Coupon Clipper*), and Buick trunk drop-off. |
| `wt/mall-cop-ai-pvp` (`src/ReplicatedStorage/Cops`) | Mall Cop & Security Agent | Mall Cop loadout (Segway scooter, foam baton, Velcro zip-ties, CCTV tablets), security gate alarms, and backroom Detention Cell rescue mechanics. |
| `wt/monetization-ui` (`src/StarterGui` & `Economy`) | UI, Cosmetics & Robux Agent | HUD (Bloomer Capacity Meter, Fizz Level, Buick Escape Indicator), post-round receipt summary, and Developer Product / Gamepass shop (custom Buicks, floral muumuus, golden walkers). |

## 4. Single-Map Layout: *Thrifty Acres & Strip-Mall Lot*
One compact, high-replayability map divided into 4 interconnected zones:
1. **The Parking Lot (Spawn & Extraction Zone):**
   * **Round Intro Cutscene:** Round opens with 2–3 beat-up late-model Buicks screeching into handicapped/curbside spots as empty *Sparkling Fizz* bottles clatter out onto the asphalt.
   * **Extraction:** Grans must return to their team's Buick trunk to bank stashed loot and escape. Driving away leaves stragglers behind unless they hitch onto the rear bumper.
2. **Main Thrift Floor (High-Density Loot):**
   * **Orthopedic Shoe Wall:** High-value, bulky beige Velcro sneakers and orthopedic inserts.
   * **Porcelain Knick-Knack Aisles:** Fragile Hummel-style figurines, velvet Elvis paintings, and haunted rotary phones (knocking over shelves creates loud crash alerts for Mall Cops).
   * **Fizz Cooler Display:** Restocks Gran speed/dizzy meter.
3. **Fitting Rooms & Donation Drop-Off (Stealth & Shortcuts):**
   * Vent shafts and donation chutes allowing Grans to bypass main aisle security scanners.
4. **Security Office & Detention Backroom (Mall Cop HQ):**
   * Live CCTV monitor wall showing which aisles have motion alerts, plus the **Detention Bench** where captured Grans sit until rescued by a teammate.

## 5. Asymmetric Roles & Classes

### 5.1 The Grans (Up to 8 Players)
* **Core Loop:**
  * Press `E` (ProximityPrompt) to stuff items into Tactical Bloomers. Each item visibly inflates the Gran's hip/waist mesh and slightly slows base walk speed—unless offset by drinking **Sparkling Fizz** (increases speed + stash limit, decreases steering stability).
  * **Rescue Mechanic:** Captured Grans sit on the Detention Bench; another Gran can pick the lock or distract the cop to free them.
* **Selectable Gran Classes:**
  1. **"Get Me The Manager!" (Mike's Class — Crowd Control / Tank):** Activates a loud megaphone shriek (`"EXCUSE ME, I KNOW THE OWNER!"`) that stuns nearby Mall Cops in a cone for 3 seconds as they are forced to politely listen to a complaint, disabling security scanners in the room.
  2. **The Velvet Hoarder (High Capacity):** +40% Bloomer storage capacity and silent knick-knack pickup (never knocks over fragile shelves).
  3. **Turbo Walker (Mobility / Escape):** Equips a tennis-ball-tipped aluminum walker that doubles as a dash ram (knocks Mall Cops off their Segways) and grants +20% speed on parking lot asphalt.

### 5.2 The Mall Cops (2 Players)
* **Objective:** Prevent Grans from escaping with $500+ worth of thrift goods before the 4-minute clock expires.
* **Equipment & Abilities:**
  * **Mall Segway:** High-speed patrol vehicle on smooth tile floors; loses traction on spilled Sparkling Fizz puddles or carpeted aisles.
  * **Velcro Zip-Ties & Foam Baton:** Tagging a Gran twice slows them down and teleports/escorts them to the Detention Bench, confiscating unbanked Bloomer loot back onto store shelves.
  * **Security Tag Wand:** Scans Grans through racks; triggers loud EAS door alarms if a Gran walks past exit sensors without disabling them.

## 6. Monetization & Robux Cosmetics (`wt/monetization-ui`)
* **Soft Currency (`Thrift Bucks`):** Earned from banked knick-knacks and successful Buick escapes; unlocks basic floral dresses, wig colors, and walker tennis-ball skins.
* **Robux Gamepasses & Cosmetics:**
  * **Golden Buick Skylark / Faux-Woodgrain Wagon (199 Robux):** Custom getaway car skin with hydraulic bounce and horn customization.
  * **VIP "Manager's Nightmare" Mega-Bloomers (149 Robux):** Cosmetic golden-trimmed bloomers + custom megaphone sound pack.
  * **Mall Cop "Paul Blart" Tactical Segway Skin (129 Robux):** Flashing red/blue sirens and donut cup holder.
  * **Role Priority Pass (79 Robux):** Increases weight for being selected as Mall Cop or Squad Leader driver.

## 7. Weekend Build Milestones (Beluga Execution Plan)
* **Hour 0–4 (Vertical Slice):** Rojo project scaffold, greybox *Thrifty Acres* 1-map layout, basic ProximityPrompt loot pickup, and Buick extraction zone.
* **Hour 4–10 (Asymmetric Loop & Physics):** 2 Mall Cops vs. Grans round manager, expanding Bloomer mesh scaling, Sparkling Fizz wobble controller, and Detention Bench rescue loop.
* **Hour 10–16 (Classes & Polish):** *"Get Me The Manager!"* stun ability, Mall Cop Segway physics, Buick intro cutscene with spilling fizz bottles, UI HUD, and Robux Gamepass hooks.
# Veil of Vera — Task 5.3 review

Existing enemy encounters are relocated to suitable candidate-island regions, candidate navigation is enabled, and the existing Demon Boar repeats its telegraphed charge/recovery cycle. Production still launches `res://scenes/main.tscn`. Task 5.4 has not started. Stop for owner review; no commercial-completion or Android-performance claim.

## Root cause and reproduced evidence

The original candidate boar performed **1 charge in approximately 80 simulated seconds**, then repeatedly oscillated between FACE and CHASE while visually idle. Target health remained valid, line-of-sight remained true, the attack cooldown reached zero, recovery completed and the idle animation continued advancing. This was not a disconnected animation/timer signal or a one-time attack flag.

The original clearance cast swept the long horizontal capsule almost at floor-contact height across a horizontal line. After charging into the uneven river-side depression, uphill terrain was treated as an immediate obstacle. The recorded forward clearance fraction fell to approximately 0.011. Steering consequently returned zero and WARNING rejected a lane shorter than 1.2 m, reset its 1 s cooldown and retried the same blocked position. A FACE state with lost line-of-sight also had no timeout/reposition transition. The old spawn was unsuitable for a charging encounter.

`baseline_boar_trace.json` and `logs/boar_baseline.stdout.log` contain actual values and transitions from the pre-change candidate. Exploratory failures, including a forced old-spawn stress test, are retained in raw logs. The old river-side position is retired; it is not certified as a safe charging arena. The final five-cycle gates use the actual new border clearing and a suitable hillside, not a forced invalid gully.

## Focused correction

- Keep the existing model, animations, manual animation clock and state machine. No replacement AI or creature asset.
- Make predictive clearance follow sampled ground beneath the centre and both ends of the existing long capsule, using short swept segments. Reject missing/steep support and real obstacles. Every physical move still uses the original full body with `move_and_slide`; charge wall collisions and travel/time limits still end the charge.
- Let FACE return to chase/reposition if line-of-sight is lost or facing exceeds 3 s. A rejected lane gets a bounded reposition interval, avoiding immediate FACE retry at the same spot.
- Use the existing sensing timer for near-target reposition checks; do not sweep the whole floor path every physics tick.
- Preserve the committed warning lane, **1.8s warning**, **1.4s recovery**, **0.4s post-recovery delay**, charge speed 3.12 m/s, maximum charge distance 6.24 m, boar HP 24, contact damage 18 and one-time reward 20 Tide Shards. `_hit_victim` resets on each new charge and damage remains CHARGE-only, once per charge contact.
- Keep existing detection/leash thresholds and death handling. Add a transition signal for deterministic test logging, with no per-frame file logging or telemetry in normal play.

Final cycle remains Idle/Patrol → Detect/Chase → Face → Warning → Charge → Recovery → Chase Again. Damage, stagger, dodge, loot and inventory systems are unchanged.

## Encounter placement and navigation

There is no separate Demon Fox enemy/model in this checkout. Existing identities are two Ember Wolves, two Ash Stalkers, one Dire Warg and one optional Demon Boar. Their identities and stable `CampDemon0..4` / `DemonBoar` save/reward connections are preserved. Retired ID 5 remains cleared and absent; no extra enemy or duplicate giant warg is restored.

| Stable ID | Existing identity | New XYZ position (metres) | HP |
|---|---|---|---:|
| CampDemon0 | EMBER WOLF | (-72.0, 1.774241, 4.0) | 18 |
| CampDemon1 | ASH STALKER | (-52.0, 1.417502, 4.0) | 17 |
| CampDemon2 | DIRE WARG | (-40.0, 1.770815, -28.0) | 21 |
| CampDemon3 | EMBER WOLF | (-64.0, 1.248644, -24.0) | 18 |
| CampDemon4 | ASH STALKER | (-68.0, 2.211786, 28.0) | 17 |
| DemonBoar | DEMON BOAR | (-36.0, 0.394178, 12.0) | 24 |

Wolves occupy woodland paths/interior; the faster stalkers use woodland edges; the existing warg uses open hillside; boar uses the western grassland/forest border. All exact actor shapes are clear of scenery at spawn. The boar clearing has **12/12 tested full-length charge directions** clear. Region geometry and quest/collectible/waystone positions are unchanged.

A shared 2 m static AStar3D graph covers x=-96..-12,z=-52..48, surrounding the relocated encounters and their existing leash ranges. It samples real ground normals, capsule headroom and clear connections. It contains **1900 nodes**. Actors share the graph; no individual navmesh, new collider or terrain rebuild is introduced. Direct shortcuts reject starting overlaps because Godot motion casts ignore them. The candidate waits for newly instanced trunk physics to synchronize before graph generation; the initial unsynchronized graph missed those obstacles and the real detour test exposed that problem.

Existing enemies accept an optional navigation reference. Without it their original movement behavior remains; it is assigned only in the candidate. Routes refresh on bounded intervals and static shortcut sensing is capped at five checks per second per actor. Actual physics remains authoritative. No teleportation, collision disabling or obstacle removal is used to pass navigation tests.

Vegetation is generated before encounter relocation, preserving the accepted grass/tree placement and original exclusion context. The live gameplay minimap already reads actual enemy positions, so its markers follow the moved actors without HUD edits. The older full-map schematic/legacy camp labels are unchanged and are not a new navigation overlay.

## Mandatory test evidence

**25/25 final regression suites passed with no script/shader/engine errors.** Relevant boar/navigation/campaign/combat suites were rerun after the final bounded-sensing change. Terrain/river/HUD and previous system checks were retained. An earlier native-renderer shutdown diagnostic was corrected by releasing test-local meshes before fixture shutdown; assertions and runtime visuals were not weakened. Existing harmless HUD draw-width warnings remain in raw logs.

- Five uninterrupted natural charge/recovery cycles at the actual border spawn: 5 warnings, 5 charges, 5 completed recoveries in 30.6 simulated seconds. Same result on a suitable hillside. No forced AI transitions or target/boar relocations during either sequence; a test-only high-health player survives.
- Three consecutive attacks avoided by the real player dodge/movement with normal 100 HP and no test invulnerability. No health lost. The fixture does not change normal health, damage, stamina or cooldown rules.
- Actual health loss occurs only during CHARGE, at the unchanged 18 damage. The existing boar regression also verifies one contact per charge while overlapping, no recovery damage, committed sidestep avoidance, invulnerability and obstacle/LOS gating.
- Moving target pursuit resumes: target separation drops 9.03 → 4.62 m over 4 simulated seconds in the controlled scenario.
- An obstacle inserted after commitment physically stops a charge, prevents damage, enters recovery and allows another charge when clear. Separate real wolf and real boar controller tests detour around a persistent existing mature trunk, proving pursuit around static obstructions.
- Escaping the leash produces RETURN → IDLE → PATROL naturally. Player death and boar death each produce zero additional charges. Boar defeat reward is 20 shards once.
- Five-region enemy-body support, player/enemy solid collision, 16 camera clearances, 26 river walking exits, ten regional approach/return legs, cave entry/relic/save reload, campaign/quest progression, persistent world, fast travel, HUD and combat regressions passed in their documented fixture contexts.

See `boar_cycle_results.json` for actual transition timestamps, damage events and warning durations; `navigation_results.json` for positions, graph cost, body clearance and real detour traces; `test_results.json` and `logs/` for raw runs. Tests are representative, not an exhaustive proof at every world coordinate.

## Actual screenshots and video

`screenshots/` contains six actual Godot encounter views plus warning/charge/recovery views. Original 1280×720 PNGs are retained. No AI concept renders are used.

`repeated_charges.mp4` is **30.6 seconds, 1280×720, H.264, 918 frames at 30 capture FPS**, showing five actual charge/recovery cycles in Godot. The real player is held stationary with test-only invulnerability for this recording; other enemies are held for isolation. This is a controlled AI demonstration, not an Android playtest or an FPS benchmark. Capture is silent. Detailed frame/state events are in `recording.json`.

## Local physics cost and mobile limitation

Windows headless observations, 60 Hz physics: 120 warmup ticks + 600 sampled ticks per scenario. No concurrent build/capture/regression workload ran during the final observation. Compare the end-to-end candidates; positions, terrain contacts and a previously broken versus working combat loop differ. These are not statistically isolated attributions or measured Android CPU/GPU/frame rates.

| Scenario | Physics median ms before → final | Physics p95 ms before → final | Engine static allocation MiB before → final |
|---|---:|---:|---:|
| far_patrol | 6.027 → 2.754 | 7.849 → 27.108 | 364.19 → 365.77 |
| boar_combat | 4.268 → 3.931 | 11.257 → 5.290 | 364.21 → 365.79 |

Final graph generation took **77.87ms** in the isolated Windows run, with 1900 nodes. Static allocation increased by approximately 1.6 MiB. These counters are not device PSS/RAM measurements. No art/texture/foliage draw geometry or shadow settings were added.

An intermediate unbounded close-range clearance pass had boar-combat p95≈20.70ms. Reusing the sensing cadence reduced the final observed combat p95, but **the final far-patrol p95 still worsened to27.11ms**. This tail-spike observation remains unresolved; a single Windows run does not identify its cause or prove Samsung smoothness. It must be checked with the existing on-device profiler. Do not claim stable Android FPS, thermals or battery life from these results.

No physical Android phone was connected. Task 5.3 Samsung A37 FPS/frame-time, memory, thermal and battery measurements remain **pending**. This task does not perform another rendering redesign.

## Review APK

`APK/Veil_of_Vera_Task53_720p_Candidate.apk` — 150,988,271 bytes; SHA-256 `e1033eede3defdaf4b26d8091b200f972383d51230c311435d5405b83a647c32`. Same separate package `com.hirukshanan.veilofveyra.islandtest` and signing identity as the accepted B APK. Install as an in-place update; do not uninstall or clear data if retaining test saves. Production map/save package is unchanged.

The accepted 720p bootstrap and profiler bytecode are identical. HUD native resolution/layout remains unchanged. Existing 30 FPS/shadows-off startup defaults remain; use Settings 60 FPS for the owner's accepted comparison. No INTERNET permission requested. Signature/package/CRC/config checks passed. Actual exported resources also passed local resize/HUD/profiling/bootstrap checks; desktop ETC2 fallback warnings are expected on this Intel GPU and are not phone-memory evidence.

## Changed files, sources and reproduction

`changed_files.json` lists exact files. Runtime changes are `scripts/demon_boar.gd`, `enemy.gd`, `island_candidate.gd` and new `island_enemy_navigation.gd`; builder changes label/enforce the separate Task 5.3/720p test build. Two new versioned regression fixtures and a forest-test comparison/teardown adjustment are included. Source and pre-change AI snapshots are in `art_source/island/task53`; this ZIP also contains the source patch and baseline snapshots. The patch requires the existing project; the APK is the complete runnable review candidate.

No external or AI-generated asset was added. Existing owner-created boar/island and licensed wolf/environment assets and their credits/licenses remain unchanged. No private files were uploaded to a third-party service.

Use Godot 4.7.2 with `VEYRA_TEST=1` and a separate APPDATA profile. Create the output folder, then:

```powershell
& $godot --headless --path . --script res://tests/boar_repeated_cycle_check.gd -- "$PWD/.validation/island_task53"
& $godot --headless --path . --script res://tests/island_enemy_navigation_check.gd -- "$PWD/.validation/island_task53"
```

The existing native forest fixture requires GL Compatibility, while the other listed physics/campaign fixtures run headless. Raw `.run.json` files preserve exact executed arguments. Build using `tools/build_island_android.py --task 5.3 --render-height 720` with the existing local Godot/SDK/Java/templates/staging/output arguments. For phone profiling reuse `tools/profile_island_android.py`; collect actual sustained region/combat measurements separately.

## Remaining limitations and approval boundary

- Samsung A37 sustained performance is unverified; the desktop patrol tail spike needs a phone retest. No Android benchmark success is claimed.
- Static navigation is intentionally confined to the encounter/leash area. It is not a whole-island navmesh or a dynamic obstacle rebaking system. Narrow passages rejected by the conservative enemy clearance remain walkable for the smaller player where existing geometry allows.
- The old river-side boar site is intentionally no longer used. Forced tests there remain unsuitable; no terrain/river redesign was introduced to turn that gully into an arena.
- Existing cave/waterfall seams, grass aliasing and the legacy full-map schematic limitations are unchanged. No new Demon Fox asset was invented to replace an existing creature.
- Collision and movement fixtures cover representative paths/solids; they do not certify every decorative prop or possible chase trajectory.

Task 5.3 implementation is ready for visual/phone review. **Do not activate production, start Task 5.4 or claim commercial completion.**

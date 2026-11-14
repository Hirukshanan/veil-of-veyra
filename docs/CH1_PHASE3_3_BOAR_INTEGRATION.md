# Phase 3.3 — Demon Boar integration review

Status: implemented and locally verified for user review. This completes the boar integration subphase, not the entire Phase 3 enemy/combat plan. Further subphases require direction/approval.

## Existing-system audit and scope

The campaign currently spawns five required wolf variants through `enemy.gd`. The retired sixth/giant-wolf spawn ID remains cleared and is never restored. The repository does not currently have a separate fox controller/model: the fast Ash Stalker is also a wolf variant. Those enemies, their HP/damage values, visuals and combat code remain unchanged in this subphase.

Player attacks already use delayed contacts, one body overlap per swing, heavy stagger, stamina, dodge invulnerability, guard/parry and Spirit Burst. The boar reuses those interfaces and the existing damage-number/currency/save systems. This is an extension of the existing game, not a replacement project.

## Implemented encounter

One optional Demon Boar spawns at `(26.5, 0.05, -19.5)` on the existing forest trail. No terrain, trees, routes, quest layout or original camp spawn is moved. It is outside the five required camp kills, so existing lantern/dragon progression and saved camp IDs stay intact. Normal unfinished encounters restart at full health on reload, consistent with existing enemies.

The behavior is **patrol → detect/approach → face/reposition → committed warning → linear charge → recovery**. Detection requires line of sight within 10 m. Close-range retreat is capped at 0.65 s before facing/warning, so a player cannot keep it retreating forever by maintaining melee pressure. The boar returns home when pulled beyond its 18 m leash or when its target is lost. Clearance casts provide small local avoidance for patrol/pursuit; no new navigation system or global pathfinder was introduced.

| Setting | Value |
|---|---:|
| Health | 24 |
| Charge damage | 18, once per charge |
| Patrol / pursuit | 0.65 / 2.6 m/s |
| Warning | 1.8 s |
| Charge | 3.12 m/s, up to 6.24 m |
| Recovery | 1.4 s; decelerates over 0.5 s |
| Reward | 20 Tide Shards once |

The red world-space lane shows the committed direction; it stops tracking the player when the warning starts. A body-clearance sweep shortens the route before static obstacles and reserves stopping space. Actual movement collides with terrain, trees, rocks and the shallow-water boundary. Contact requires the front tusk volume, a living player and an unobstructed line, and occurs only in the charge state. A late obstacle stops the charge; no attack damages through a wall.

The player can walk sideways or dodge out of the lane. Dodge invulnerability prevents both damage and knockback. A valid charge reuses the normal hurt/cancel-swing flow and adds a short collision-aware horizontal impulse (4 m/s, decaying at 10 m/s²). It does not teleport the player. A new dodge clears the impulse. Ordinary melee guard/parry remains unchanged; the boar's heavy body charge must be evaded and bypasses ordinary blocking. The enemy guide explains this.

Normal sword hits always damage it and provide a restrained hit flash. Light hits do not cancel warning/charge/recovery, preventing permanent normal-attack stun-lock. The existing heavy-attack `stagger` call interrupts it and plays the approved hit reaction. Idle/patrol/pursuit hits can also trigger that reaction; hits do not continually restart an ongoing stagger.

Death immediately disables offense/collision and emits one defeat event, then plays the approved death clip and holds the final pose. The corpse is removed after 14 seconds. Currency and the optional `boar_defeated` flag save together through the existing store; subsequent loads do not respawn the defeated boar or pay again. The additive optional boolean is backward compatible with old version-4/earlier worlds and requires no camp-ID migration.

## Model and animations

The runtime GLB is byte-identical to the approved Stage B export. All eight clips, original proportions, original 4K base color, 2K normal, corrected closed surface and skin weights are preserved. No model regeneration, geometry change or placeholder substitution was performed.

Animation selection follows actual AI state, with short crossfades, in-place movement and declared locomotion speeds. All clips retain the correct loop/one-shot settings. The collider base matches the model's foot plane. No target-lock interface, HUD customization button or new gameplay control is introduced.

Model-generation credit remains **Hirukshanan using Tripo3D**. See `assets/characters/demon_boar/README.md` and the unchanged Stage A/B asset credit for provenance and ownership-term limitations.

## Files changed

| Path | Purpose |
|---|---|
| `scripts/demon_boar.gd` + UID | Dedicated optional creature, state/animation controller, fair hit volume, wall checks, local avoidance, distant sleep and death lifecycle |
| `scripts/player.gd` | Small charge-damage/decaying-knockback compatibility hook; preserves existing inputs and ordinary combat |
| `scripts/campaign.gd` | One optional spawn, one-time shard/save callback, guide text; keeps required objective guidance on camp enemies |
| `scripts/campaign_store.gd` | Validate the optional backward-compatible boolean |
| `assets/characters/demon_boar/` | Approved runtime GLB, precise import metadata and credit/setup notes |
| `.gitattributes` | Track the new runtime GLB through existing Git LFS setup |
| `tests/boar_check.gd` | Physical attack/state/range/obstacle/lifecycle regressions |
| `tests/boar_campaign_check.gd` | Real player dodge/knockback, optional reward, saved flag, reload and legacy save compatibility |
| `tests/boar_gameplay_review.gd` | Controlled native gameplay replay using existing HUD action signals and isolated profiles |
| `tests/free_combat_check.gd` | Preserve the five required camp enemies while separately checking the new optional registry member |
| `tests/campaign_smoke.gd` | Clear required camps only, verifying the optional boar does not block lantern progression or alter the existing boss reward |
| `docs/phase3_3/` and this report | Actual gameplay evidence and machine-readable verification |

The pre-existing local changes in `export_presets.cfg`, `RELEASE_STATUS.md` and `VALIDATION.md` are preserved byte-for-byte. No edits were made to the approved HUD/editor, hero presentation, old enemy controller, environment, quests or dragon assets/code. The small campaign changes above are compatibility wiring rather than a quest redesign. Approved Stage A and B delivery manifests still match.

## Automated verification

14 isolated Godot regression scripts passed:

| Test | Result |
|---|---|
| boar_check | PASS |
| boar_campaign_check | PASS |
| enemy_check | PASS |
| combat_check | PASS |
| free_combat_check | PASS |
| campaign_smoke | PASS |
| chapter_route_check | PASS |
| fast_travel_check | PASS |
| autosave_check | PASS |
| persistent_world_check | PASS |
| heavy_attack_check | PASS |
| jump_check | PASS |
| hud_customization_check | PASS |
| quest_hud_check | PASS |

The boar-specific checks cover the full warning duration; committed direction and lateral escape; one valid contact; invulnerable misses; initial LOS and late wall collision; grounded collider; coherent close-range repositioning; normal-hit poise and heavy interruption; one defeat event; final death hold; one optional spawn; actual dodge/knockback hooks; legacy flag validation; one-time payment; save/reload persistence; five unchanged required camps and no restored giant wolf.

Two issues found during verification were corrected: an old shared-registry test assumed exactly five total actors, and close-range retreat applied opposing turn commands. The test now verifies five required enemies plus one optional boar; retreat turns toward its movement and has a time cap before facing the target for the warning.

## Actual gameplay evidence

These are native 1280×720, 30-frame-per-second offline captures of the actual campaign scene, original world, hero and HUD. They are scripted review playbacks using existing joystick/action signals, not claims of manual physical-touch or Android-device testing. The other camp enemies are paused only in the review fixture so the encounter can be inspected independently. The final game does not pause them.

- [Combined actual gameplay](phase3_3/boar_gameplay_showcase.mp4)
- [Warning, joystick/dodge and committed miss](phase3_3/boar_dodge.mp4): hero remains at 100 HP; the boar takes no damage.
- [Valid contact and knockback](phase3_3/boar_hit.mp4): hero goes from 100 to 82 HP; one charge contact.
- [Heavy interruption, approach, sword follow-up, death and saved reward](phase3_3/boar_defeat.mp4): original boar health stays 24; the fixture uses the existing maximum blade upgrade (damage 5), not reduced enemy health. Hero stays at 100 HP; the boar dies and pays/saves exactly 20 shards.
- [Warning screenshot](phase3_3/boar_warning.png), [dodge screenshot](phase3_3/boar_dodge.png), [valid hit screenshot](phase3_3/boar_valid_hit.png), [death/reward screenshot](phase3_3/boar_death_reward.png).

The JSON traces and `verification.json` distinguish observed gameplay outcomes from automated collision/save assertions. Screenshots alone do not prove combat correctness. The initial setup frame was omitted; otherwise the recordings are unchanged native gameplay. Audio, where present, is the existing game's sword/dodge/hurt output, not microphone or desktop audio.

## Reproduction

Use the installed Godot 4.7.2 executable in place of `godot`. Keep test/review saves separate from personal progress:

```powershell
$previousAppData = $env:APPDATA
try {
    $env:VEYRA_TEST = '1'
    $env:APPDATA = Join-Path (Get-Location) '.validation/phase3_3_manual_profile'
    New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
    godot --headless --editor --path . --import --quit
    godot --headless --path . --script res://tests/boar_check.gd
    godot --headless --path . --script res://tests/boar_campaign_check.gd
    godot --path . --script res://tests/boar_gameplay_review.gd --rendering-method gl_compatibility --fixed-fps 30 --write-movie .validation/boar_dodge.png -- --case=dodge
} finally {
    $env:APPDATA = $previousAppData
    Remove-Item Env:VEYRA_TEST -ErrorAction SilentlyContinue
}
```

For other review cases use `--case=hit` or `--case=defeat`. The replay explicitly refuses a non-validation profile before clearing its three test-save files. Regression logs and task-owned process records are in `.validation/phase3_3_2026-11-15/`.

## Performance and remaining limitations

- One boar is spawned. At distances beyond 36 m during patrol/idle, AI is checked twice per second and animation poses do not advance; its model is hidden beyond 45 m. Active collision and attack timing stay on the physics clock. Pursuit senses are checked every 0.2 s. No per-frame pathfinder, fur simulation, new particles or global enemy spawning system was added.
- The approved 120,000-triangle, 88,201-render-vertex, 30-joint, four-weight, one-material model is unchanged. Lower LODs and texture-memory tuning remain device-driven work. Offline Movie Maker timing includes capture/PNG overhead and is not a gameplay FPS benchmark.
- No real Android phone, thermal, memory or 30 FPS acceptance measurement was performed. No APK was requested or built.
- Collision-aware local steering is intentionally simple; this is not full navigation-mesh pathfinding. Complex future mazes/terrain may require a proper navigation layer.
- The authored death is for the current flat forest-trail area, not a terrain-aware ragdoll. Obstacle impact uses the available recovery animation, with movement stopped by collision; no dedicated wall-impact animation is invented.
- New bespoke boar growl/hoof/charge/death audio and broader sword/fox/wolf polish are not implemented in this subphase. Existing player cues remain functional. Fox/wolf audit findings and the rest of the Phase 3 plan remain separate work, not silently marked complete.
- The encounter is optional and does not change the lantern quest. Balance values above are initial explicit tuning for review, not player-tested commercial balance.

No branch, commit, push or external asset upload was performed. STOP for user review before another subphase or Phase 4.

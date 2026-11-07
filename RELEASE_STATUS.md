# Veil of Veyra — development status

## Implemented

- First expanded island layout: sloped sandy coastline, beach arrival, branching forest trail, ruins, three distributed wolf camps and current-hunt water-rescue waystones. Chapters share this layout; natural terrain polish and persistent checkpoints remain pending.

- First signed ARM64 Android debug APK exported and signature-verified. Owner reports smooth gameplay and persisted progress after reopening on Samsung A37; background/resume and measured performance remain pending.

- Third-person movement, curved blade attacks, dodge, touch controls.
- Tab/on-screen target lock selects the nearest living enemy within 14 metres, tracks facing/camera, marks the target, and releases on manual camera input, menus, death, removal or range exit.
- Collision-aware camera with terrain/tree-trunk obstruction handling and saved 4–9 metre camera distance.
- Three-hit sword combo, double-damage finisher, hit flashes, dodge cooldown display, and a 0.18-second input buffer near the end of attack recovery.
- Spirit Burst: successful sword swings build charge; L/on-screen BURST spends 100 charge on a 3-metre area attack for triple blade damage, with a pulse effect and camp guide.
- Licensed textured, skeletal Dire Wolf Lite model integrated as Ember Wolf, Ash Stalker and Dire Warg size/tint variants. Local-only source model installation is required; earlier procedural animals remain a missing-asset fallback.
- Enemy attack warnings with range escape and interruptible windups, plus quadruped gait, serpent sway, anticipation, bite/lunge and hit-recoil poses. Dragon wings and body react to windup, breath, charge and recovery.
- Textured wolf damage flash and pause-aware visual fall/fade on defeat, with immediate gameplay removal and a maximum of eight temporary remains.
- Floating damage numbers for enemy and boss hits, including finishing hits, with pause-aware expiry and a 24-label limit.
- Ember Wolf/Ash Stalker/Dire Warg enemy types with distinct stats, silhouettes, colors, health labels, and a camp enemy guide; stalkers appear in chapter one and wargs join later chapters.
- Camp/pause settings with saved camera sensitivity, camera distance, master volume, mute, sound preview, a Shadows on/off toggle, and a saved 30/60 FPS cap.
- Original synthesized placeholder sword, dodge, and player-damage audio cues.
- Three sequential hunts with increasing enemy counts and durability.
- Procedural chapter skies, colored sunlight, directional shadows, extended sea horizon, and outlined HUD text.
- First chapter environment pass: sandy shore with palms, green grove with trees/fungi, and dark stone ruins; distinct ground/sea palettes with perimeter camera blockers.
- Chapter lantern objectives: clear enemies, approach and light the lantern with E or the on-screen button, then defeat the dragon.
- Optional Keeper relic hunt: three chapter-specific pickup locations, distance/progress HUD, camp instructions, and 20 bonus shards for collecting all three before victory.
- Dragon boss with warning, charge, breath, and health display.
- Dragon Enraged phase at half health: explicit HUD/action labels, faster pursuit/charge, and shorter future windups/recovery while preserving attacks already in progress.
- Camp, chapter introductions, pause, healing, defeat/retry, and ending.
- Quest Journal (Q or Pause menu) shows chapter instructions, demon/lantern/dragon stages and optional relic progress, with paused combat while reading.
- Escape pause/resume, automatic pause on application focus loss/backgrounding, and joystick reset on menus.
- Mobile safe-area insets for HUD/actions and menu contents, with scaled display-coordinate mapping; actual cutout-device acceptance remains pending.
- Anchored landscape controls and scrollable camp/settings menus with keyboard focus following.
- Shard rewards, blade/armor upgrades, and local campaign persistence.
- Campaign saves use a validated temporary file and previous-save backup; invalid primary files recover from backup, with explicit protection when both snapshots are unreadable and retry options on failed victory/reset saves.
- Headless campaign flow regression check using isolated save storage.

## Required before public release

- Replace primitive characters with rigged original models and animations.
- Create distinct explorable chapter maps, NPC dialogue, and environmental quests. Planned later: larger land areas ending in natural beaches and surrounding sea, inland water where suitable, and more world characters.
- Add original or licensed music, combat sound, and accessibility settings.
- Visually review touch layouts across phone aspect ratios and safe areas.
- Playtest combat balance, camera collision, enemy navigation, and performance.
- Validate real device storage/power interruption and Android background/resume behavior (simulated save failures have regression coverage).
- Replace the debug app icon, finalize the production package identifier, and configure Gradle/AAB export and release signing.
- Produce and test a signed Android App Bundle on physical devices.
- Complete privacy/Data Safety, age rating, store assets, and required closed testing.
- Select and validate monetization only after the game experience is ready.

This is an evolving playable prototype, not a finished commercial release.

## Version control

The assistant edits and verifies changes, then suggests a commit message. The project owner creates commits and controls branches, pushes, and merges.
Code, game text, documentation, and commit messages are written in English.

## Island exploration update (0.3.1-dev)
- Expanded island with three hunting camps, rescue waystones, camera-relative objective guidance, pause map, and stamina-based sprint.
- Wolves patrol locally and approach faster after detection while retaining attack warnings.
- CC0 scanned foliage and ground textures, lightweight reduced vegetation meshes, and animated coastal water.
- Irregular coastline with matching beach collision and curved trails shared with the pause map. Combat ground remains level.
- Device acceptance for these additions is pending. Earlier Samsung A37 feedback covers the initial build, not this version.

## Blended terrain update (0.4.0-dev)
- Unified opaque sand/grass/soil terrain replaces separate interior and path meshes.
- Feathered path edges, varied beach/grass transition, wet shoreline sand, and animated coastal foam.
- Existing flat combat plateau, collision, rescue threshold, and map navigation remain intact.
- Native desktop captures checked; performance and visuals on Android remain pending.

## Shore Keeper and Western Watch (0.5.0-dev)
- In-world Shore Keeper beside the beach waystone, using the existing CC0 humanoid rig with an original blue spirit material and marker ring. This is reused art, not a new bespoke character model.
- E / TALK within three metres opens paused dialogue with accept, report, relic information and return choices.
- Optional Western Watch bounty: accept, clear the western camp, return to report, then defeat the dragon for 15 additional shards.
- Bounty tracking uses enemy home camps, including wolves pursuing elsewhere. It can be accepted after clearing the camp.
- Journal, HUD guidance and a blue Keeper marker on the island map support the quest.
- Accepted/reported state resets with each hunt. Bounty currency saves only with chapter victory, using existing save/retry handling. Existing relic bonus remains separate.

## Heavy sword attack (0.6.0-dev)
- H / HEAVY spends 40 stamina for a 0.6-second windup and four-times-blade-damage strike in a 2.6 m, 120-degree forward arc.
- Uses the existing sword clip at a slower speed, an orange ground arc, blade glow, and a mobile cooldown display.
- Total commitment is 1.1 seconds; movement is reduced to 35% and stamina regeneration stops during it.
- Ordinary wolves stagger for 0.65 seconds. Boss attacks retain their existing resistance to interruption.
- Dodge, incoming damage, death, and menus cancel pending contact without refunding stamina. Misses still cost stamina; one connected swing grants 25 spirit.
- Camp guide and journal describe the controls and tradeoffs. Device combat balance and performance remain pending.

## Mountain rim and imposing demons (0.7.0-dev)
- Seven irregular multi-peak formations and six connecting rocky ridges frame the north/east/west shore. Southern beach and existing routes remain open.
- Mountain meshes have physical and camera collision; grey triangles mark the main peaks on the island map.
- Wolf model scales increased from 0.78/0.66/1.05 to 1.25/1.05/1.7, with larger collision capsules and raised labels.
- Detection triggers a brief sampled snarl and a distance-attenuated original synthesized growl; bite anticipation, forward lunge and hit recoil are stronger.
- Existing pursuit speeds, warning durations, damage and attack ranges are retained. Larger bodies still need physical-device playtesting.
- Mountains use procedural rock geometry; this is not a new traversable mountain quest or a finished photorealistic landscape.

## Waystone fast travel (0.8.0-dev)
- Beach is known initially; visit Forest and Ruins waystones to discover them for the current hunt.
- Pause > Island Map provides destination buttons with explicit blocked reasons and discovered/undiscovered marker colors.
- Travel is blocked by living enemies within 14 metres of departure or destination, active dragon encounters, or unfinished player combat actions.
- Travel clears motion and queued attacks, updates camera and rescue binding, and resumes gameplay. No health, stamina or potion refill.
- Discovery resets on hunt restart/chapter reload; campaign save format is unchanged.

## Quest scroll and circular controls (0.9.0-dev)
- Dedicated HUD scroll icon opens full objectives, rewards, progress and Western Watch acceptance/completion from anywhere. NPC dialogue is no longer required; the Keeper remains scenery.
- Circular HUD buttons with circular hit areas; transparent corners allow touches through. Sprint joins attack/dodge on the right. Menus use rounded pill buttons for longer text.
- Campaign wolf base health increased from 3/5/7 to 5/8/11; scout (-1) and brute (+3) modifiers remain. Damage and attack timing are unchanged.
- This stage retains three sequential hunts and the existing island size/water rescue behavior.

## Requested next stages
- Replace sequential hunts with a continuous, quest-driven island progression model.
- Expand the island substantially, with visible ground grass and additional exploration quests.
- Add collectible medicinal plants and a healing-resource system.
- Allow limited shallow-water movement and enforce a movement boundary instead of the current sea damage/respawn rule.
These are planned changes, not features of the current build.

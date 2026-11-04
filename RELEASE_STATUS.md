# Veil of Veyra — development status

## Implemented

- Third-person movement, curved blade attacks, dodge, touch controls.
- Tab/on-screen target lock selects the nearest living enemy within 14 metres, tracks facing/camera, marks the target, and releases on manual camera input, menus, death, removal or range exit.
- Collision-aware camera with terrain/tree-trunk obstruction handling and saved 4–9 metre camera distance.
- Three-hit sword combo, double-damage finisher, hit flashes, dodge cooldown display, and a 0.18-second input buffer near the end of attack recovery.
- Spirit Burst: successful sword swings build charge; L/on-screen BURST spends 100 charge on a 3-metre area attack for triple blade damage, with a pulse effect and camp guide.
- Enemy attack warnings with range escape and interruptible windups.
- Shore/Scout/Brute enemy types with distinct stats, silhouettes, colors, health labels, and a camp enemy guide; Scouts appear in chapter one and Brutes join later chapters.
- Camp/pause settings with saved camera sensitivity and master volume, mute, and sound preview.
- Original synthesized placeholder sword, dodge, and player-damage audio cues.
- Three sequential hunts with increasing enemy counts and durability.
- First chapter environment pass: sandy shore with palms, green grove with trees/fungi, and dark stone ruins; distinct ground/sea palettes with perimeter camera blockers.
- Chapter lantern objectives: clear enemies, approach and light the lantern with E or the on-screen button, then defeat the dragon.
- Optional Keeper relic hunt: three chapter-specific pickup locations, distance/progress HUD, camp instructions, and 20 bonus shards for collecting all three before victory.
- Dragon boss with warning, charge, breath, and health display.
- Dragon Enraged phase at half health: explicit HUD/action labels, faster pursuit/charge, and shorter future windups/recovery while preserving attacks already in progress.
- Camp, chapter introductions, pause, healing, defeat/retry, and ending.
- Escape pause/resume, automatic pause on application focus loss/backgrounding, and joystick reset on menus.
- Anchored landscape controls and scrollable camp/settings menus with keyboard focus following.
- Shard rewards, blade/armor upgrades, and local campaign persistence.
- Campaign saves use a validated temporary file and previous-save backup; invalid primary files recover from backup, with explicit protection when both snapshots are unreadable and retry options on failed victory/reset saves.
- Headless campaign flow regression check using isolated save storage.

## Required before public release

- Replace primitive characters with rigged original models and animations.
- Create distinct explorable chapter maps, NPC dialogue, and environmental quests.
- Add original or licensed music, combat sound, and accessibility settings.
- Visually review touch layouts across phone aspect ratios and safe areas.
- Playtest combat balance, camera collision, enemy navigation, and performance.
- Validate real device storage/power interruption and Android background/resume behavior (simulated save failures have regression coverage).
- Configure Android export templates, SDK, app icon, package identifier, and release signing.
- Produce and test a signed Android App Bundle on physical devices.
- Complete privacy/Data Safety, age rating, store assets, and required closed testing.
- Select and validate monetization only after the game experience is ready.

This is an evolving playable prototype, not a finished commercial release.

## Version control

The assistant edits and verifies changes, then suggests a commit message. The project owner creates commits and controls branches, pushes, and merges.
Code, game text, documentation, and commit messages are written in English.

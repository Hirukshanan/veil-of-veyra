# Veil of Veyra

An original third-person action RPG set on a demon-haunted island. Play as Aru, reclaim the lanterns, and confront the Tidewraith Dragon.

Built with **Godot 4.7.2** and **GDScript**, with landscape touch controls for Android and keyboard/mouse controls for desktop development.

> **In development:** a playable prototype with one persistent island. Art, audio, combat balance, performance testing, and release preparation are still evolving.

## Explore, fight, reclaim

- **Island exploration:** forest trails, beaches, coastal water, mountain formations, ruins, and hunting camps.
- **Sword combat:** three-hit combos, dodge, target lock, stamina-powered heavy attacks, and Spirit Burst.
- **Demon encounters:** three wolf variants and a dragon boss with an enraged phase.
- **Lantern seal quest:** follow the south-west trail from the Beach waystone, recover three seal fragments using the hand icon/E, then light the northern lantern once the camps are clear. A cyan diamond on MAP marks Tideseal Ruins.
- **Optional quests:** gather three grove flowers in Moonleaf Grove for a one-time 25-shard reward, recover Keeper relics, and complete the Western Watch bounty through the quest scroll.
- **Waystones:** discover rescue points and fast-travel between safe destinations through the island map.
- **Progression:** earn shards, upgrade blade and armor, and save island progress throughout exploration.
- **Camp menu:** dragon-and-lantern artwork, prominent Continue action, shard/equipment cards, upgrades, and quick access to quests, guides, settings and New journey.
- **Mobile controls:** circular action buttons and right-side sprint; **settings:** camera adjustments, safe-area layouts, shadows, and a 30/60 FPS option.

## Run locally

1. Install the standard **Godot 4.7.2** editor; .NET is not required.
2. Clone or download this repository.
3. Import `project.godot` and allow asset imports to finish.
4. Install the separately distributed wolf model for the intended visuals; see [asset setup](#assets-and-credits).
5. Press **F5** and select **Continue exploring Veyra** in the camp menu.

The project uses Godot's **GL Compatibility** renderer. Command examples assume the executable is available as `godot` on your `PATH`; substitute your executable name or local path if needed.

```sh
godot --editor --path .
```

## Controls

| Action | Keyboard / mouse | Touch |
| --- | --- | --- |
| Move | WASD / arrow keys | Left joystick |
| Camera | Hold right mouse button and drag | Drag open screen space |
| Sprint | Shift | Running figure icon |
| Sword combo | J | Tap the sword icon |
| Heavy attack | H | Hold the sword icon for 0.4 seconds |
| Dodge | K / Space | Evasion/boot icon |
| Target lock | Tab | Keyboard only; no HUD button |
| Spirit Burst | L | Starburst icon |
| Collect herb / light lantern | E | Contextual hand / lantern icon |
| Quest journal | Q | Scroll icon / Pause → Quest Journal |
| Map / fast travel | Pause → Island Map | Pause → Island Map |
| Pause / resume | Escape | Pause icon / Resume |
| Heal | On-screen button | Potion icon |

Gameplay action buttons use icons without text labels. Tap/release the sword for a normal attack; hold for 0.4 seconds for one heavy attack. Moving the finger off the button or opening a menu cancels a pending hold. Collection responds on touch-down or the E key event. Heavy attacks cost **40 stamina**. Spirit Burst requires a full spirit meter. In-game guides explain combat timing and optional rewards.

## Progress and travel

One continuous island replaces the three sequential hunts. Recover the three lantern-seal fragments from Tideseal Ruins on the south-west coast, clear five demons across three camps, restore the lantern, and defeat the Tidewraith; then continue exploring without advancing a level or reloading the map.

Cleared enemies, seal fragments, collected Moonleaf herbs and relics, Western Watch status, discovered/bound waystones, location, health, potions, shards and upgrades are saved on quest actions, menu opening, every five seconds of exploration, and on normal exit. Periodic autosaves write an independent snapshot in the background so storage I/O does not block movement. Quest, menu and normal-exit saves finish pending writes before saving the newest state; reset and scene exit also wait for the writer. A forced termination may lose the last few seconds. Surviving enemies and an unfinished dragon encounter restart at full health after reloading; spirit and stamina are session resources.

Death returns Aru to the bound waystone at full health while preserving world progress and potion stock. Dragon rewards and optional relic/bounty rewards are paid once; optional quests can finish after victory. Moonleaf plants are finite pickups in this prototype and do not respawn. The original eight pickups retain their IDs; five more grow in Moonleaf Grove, reached by the eastern trail from the Beach waystone. A green leaf on the island map marks the grove. Only grove flowers count toward its three-flower quest; each flower also provides one potion.

Older chapter and persistent-island saves migrate automatically, retaining shards, upgrades and final completion. Old saves did not store current-hunt pickups or camp clears, so an unfinished legacy journey starts with fresh island objectives. Final completion prevents the dragon from spawning again. Earlier saves with an already-lit lantern automatically receive completed seal-fragment progress, keeping the lantern and dragon encounter state intact. New journey explicitly resets the world; save failures keep the existing journey intact.

Aru can wade a short distance into shallow coastal water. An invisible boundary follows the irregular coastline and blocks deeper water while allowing movement along the shore and back to land; ordinary water entry does not cost health or teleport Aru. Genuine falls below the terrain still trigger emergency rescue and its existing health penalty. Older saved positions outside the boundary are moved just inside it without changing health or progress.

Approach a waystone to discover it and bind a rescue point. Beach is known initially. Fast travel requires a discovered destination, no nearby enemies at either end, and no active dragon encounter. Travel does not refill health, stamina, or potions.

## Android builds

The `Android Debug` preset produces an ARM64 development APK. Configure the Android SDK, Java, and matching Godot export templates first. Create `builds/android`, then run:

```sh
godot --headless --path . --export-debug "Android Debug" builds/android/veyra-debug.apk
```

See [Android setup](ANDROID_SETUP.md) for portable setup instructions, verification, and device checks. Build outputs and signing keys are excluded from Git. Production signing, AAB delivery, and store preparation remain unfinished.

## Assets and credits

| Asset | Source and setup |
| --- | --- |
| Hero base and animations | [Quaternius asset notes](assets/characters/quaternius/README.md) |
| Dire Wolf Lite | [Literock asset notes and installation](assets/characters/literock/README.md) |
| Ground textures and scanned foliage | [Environment credits](assets/environment/README.md) |

**The wolf source model is not included in Git.** Obtain it from the creator and follow the installation notes. Without it, the game uses procedural fallback creatures. Install the model before evaluating the intended visuals or exporting them.

The three wolf variants share one model with different sizes and colors. Hero costume is provisional; terrain and mountains are procedural. The dragon uses an optimized, rigged [Charcoal Black Dark Dragon by Pigcraft](assets/characters/pigcraft/README.md), included under CC BY 4.0. Its hovering combat motions are custom and remain subject to device playtesting.

Third-party assets retain their respective licenses. Repository access does not grant redistribution rights to those assets. Consult the linked notes before reuse.

## Project structure

| Directory | Purpose |
| --- | --- |
| `scenes/` | Game scene entry points |
| `scripts/` | Combat, campaign, exploration, UI, and persistence |
| `assets/` | Art, shaders, and attribution |
| `tests/` | Godot regression checks |
| `tools/` | Development and asset-preparation utilities |
| `builds/` | Local export output; ignored by Git |

## Development checks

Run tests with isolated save storage to protect personal playthroughs. From the repository root, this PowerShell example restores the environment afterward:

```powershell
$previousAppData = $env:APPDATA
$previousTestMode = $env:VEYRA_TEST
try {
    $env:APPDATA = Join-Path (Get-Location) '.validation'
    $env:VEYRA_TEST = '1'
    godot --headless --path . --script res://tests/gameplay_check.gd
} finally {
    $env:APPDATA = $previousAppData
    $env:VEYRA_TEST = $previousTestMode
}
```

Additional targeted checks cover combat, quests, saves, terrain, UI, and travel. See [validation notes](VALIDATION.md) for recorded results and limitations.

## Current priorities

- Improve character presentation, environmental detail, and audio.
- Playtest combat, navigation, and touch controls on physical Android devices.
- Measure sustained performance and investigate shutdown resource warnings.
- Finish release artwork, signing, packaging, and store requirements.

See [release status](RELEASE_STATUS.md) for implemented systems and remaining work.

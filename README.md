# Veil of Veyra

An original third-person action RPG set on a demon-haunted island. Play as Aru, reclaim the lanterns, and confront the Tidewraith Dragon.

Built with **Godot 4.7.2** and **GDScript**, with landscape touch controls for Android and keyboard/mouse controls for desktop development.

> **In development:** a playable prototype with three sequential hunts. Art, audio, combat balance, performance testing, and release preparation are still evolving.

## Explore, fight, reclaim

- **Island exploration:** forest trails, beaches, coastal water, mountain formations, ruins, and hunting camps.
- **Sword combat:** three-hit combos, dodge, target lock, stamina-powered heavy attacks, and Spirit Burst.
- **Demon encounters:** three wolf variants and a dragon boss with an enraged phase.
- **Optional quests:** recover Keeper relics and accept and complete the Western Watch bounty directly from the on-screen quest scroll.
- **Waystones:** discover rescue points and fast-travel between safe destinations through the island map.
- **Progression:** earn shards, upgrade blade and armor, and save campaign progress between chapters.
- **Mobile controls:** circular action buttons and right-side sprint; **settings:** camera adjustments, safe-area layouts, shadows, and a 30/60 FPS option.

## Run locally

1. Install the standard **Godot 4.7.2** editor; .NET is not required.
2. Clone or download this repository.
3. Import `project.godot` and allow asset imports to finish.
4. Install the separately distributed wolf model for the intended visuals; see [asset setup](#assets-and-credits).
5. Press **F5** and select **Begin** in the camp menu.

The project uses Godot's **GL Compatibility** renderer. Command examples assume the executable is available as `godot` on your `PATH`; substitute your executable name or local path if needed.

```sh
godot --editor --path .
```

## Controls

| Action | Keyboard / mouse | Touch |
| --- | --- | --- |
| Move | WASD / arrow keys | Left joystick |
| Camera | Hold right mouse button and drag | Drag open screen space |
| Sprint | Shift | SPRINT |
| Sword combo | J | ATTACK |
| Heavy attack | H | HEAVY |
| Dodge | K / Space | DODGE |
| Target lock | Tab | LOCK |
| Spirit Burst | L | BURST |
| Talk / light lantern | E | TALK / LIGHT |
| Quest journal | Q | Scroll icon / Pause → Quest Journal |
| Map / fast travel | Pause → Island Map | Pause → Island Map |
| Pause / resume | Escape | PAUSE / Resume |
| Heal | On-screen button | HEAL |

Heavy attacks cost **40 stamina**. Spirit Burst requires a full spirit meter. In-game guides explain combat timing and optional rewards.

## Progress and travel

Campaign progress, shards, and upgrades save between chapters. Enemies, relic collection, bounty acceptance/reporting, and waystone discovery reset when a hunt restarts.

Approach a waystone to discover it and bind a water-rescue point. Beach is known initially. Fast travel requires a discovered destination, no nearby enemies at either end, and no active dragon encounter. Travel does not refill health, stamina, or potions.

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

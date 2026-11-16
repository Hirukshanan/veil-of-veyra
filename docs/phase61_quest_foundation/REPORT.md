# Phase 6.1 — Chapter I quest progression and story foundation

The candidate island now presents the existing Chapter I content as a connected journey, with a current objective, regional guidance, prerequisite status, visible rewards, next objective and collection/completion feedback. The approved parchment scroll, gameplay HUD layout and all progression/reward mechanisms remain in use. **The production map is not activated.**

## Implemented improvements

- Added a read-only quest projection over existing counters and saved flags. The main chain reads: recover the shore seal and clear the forest camps in either order, manually restore the northern lantern, then resolve the existing Tidewraith encounter. Optional relics, herbs, grove and Western Watch fit around that journey.
- Put current guidance, reward and next step before background lore in the parchment. Optional entries distinguish AVAILABLE, ACTIVE, READY, SECURED, deferred rewards and paid rewards. Existing acceptance/reporting buttons remain the interaction, with no mandatory NPC.
- Added five-second feedback for fragment/relic collection, camp progress, bounty acceptance/reporting, healing herbs and the existing one-time bonuses. Grove/cave/bounty context uses the current panel, without moving any approved control.
- Fixed a real candidate-specific Western Watch defect: its old fixed-radius coordinate search no longer matched relocated enemies. Explicit membership now tracks the original western pair, without moving or changing an enemy. An incomplete bounty cannot report; already-reported older saves retain credit.
- Established future story prerequisites by deriving chapter victory, complete seal and cave relic discovery. Documented the later lantern exploration, ancient discoveries and Dragon awakening as future dependencies only. No new cave access gate, lighting, awakening or final encounter was implemented.

## Existing economy and persistence

Values are unchanged: victory **80**, all relics plus victory **20**, reported Western Watch plus victory **15**, three grove flowers **25**, optional Demon Boar **20** Tide Shards; each herb grants one potion. Existing one-time flags and campaign reward functions still award them. No inventory replacement, new saved quest-state object or schema migration was introduced; version remains **4**.

The focused candidate test exercises a fresh journey, acceptance, unrelated/correct wolf kills, actual fragment and cave relic collection, ordinary/grove herbs, several save/reloads, manual lantern gating, existing boss victory, optional completion after victory and repeated award attempts. Final controlled balance is 140 shards (25 + 80 + 15 + 20), with zero duplicate payments.

A synthetic pre-Phase-6.1 version-4 save verifies blade/armor levels, health, potions, waystones, partial IDs, cave position and previously reported bounty. All relics collected before victory correctly defer their bonus; 73 starting shards become 188 (73 + 80 + 20 + 15), then remain 188 after reload. Existing version-1/2/3 migration, corrupt-save protection, backup recovery and failed-write tests also pass. Real owner saves were not copied or used.

## Verification

**38/38 regression programs pass** with exit code 0 and no recorded script, shader or engine errors. This includes new quest progression/save tests; seal, relic, herb/grove and journal tests; campaign/boss, save/backup/autosave and travel; cave floor, collision, accessibility, river escape, camera and enemy navigation; repeated boar attacks and ordinary/heavy combat; HUD layout/customization, safe areas, Settings, sprint and pinch multitouch. Raw stdout, stderr and exact argument/exit metadata are in `logs/`. `test_results.json` consolidates the final runs, not just assertions reported by the UI.

Two intermediate checks needed correction. The older save fixture killed the optional Boar alongside required wolves, producing 100 shards while asserting only the 80-shard boss payout. Diagnostic stdout confirms `completed=true shards=100 save_failed=true`. The fixture now isolates required wolves; all save-failure/retry assertions remain. The completed-journey HUD text was also adjusted to retain clear “explore” guidance, satisfying its existing semantic regression. Initial diagnostic errors are retained separately in `diagnostics/`; final test logs are clean. The existing filled `draw_rect` width warning occurs in some HUD tests and is unchanged.

Eleven actual Windows Godot screenshots show fresh HUD, the parchment objective/reward/next step, bounty acceptance, optional rewards, future prerequisites, fragment feedback, the cave relic with dark floor, partial progress, grove reward and lantern-ready/secured-bounty state. PNGs are original 1600×720 captures. Actors are held for reproducible framing; capture helpers teleport between views and use controlled completion for the final two screenshots. They do not demonstrate a continuous combat playthrough or Android usability. Actual collection and reward APIs are used, and separate functional tests validate the state transitions.

## Preservation and exact files

The baseline includes 576 runtime/test/configuration files. SHA-256 comparison permits changes only to:

- `scripts/campaign.gd`
- `scripts/island_candidate.gd`
- `scripts/premium_hud.gd`
- `scripts/shore_keeper.gd`
- `tests/save_check.gd`

The first four contain only quest presentation and bounty membership changes. `tests/save_check.gd` changes the optional-Boar fixture described above. New source files:

- `scripts/chapter_one_quests.gd`
- `tests/quest_progression_check.gd`
- `tests/quest_save_compatibility_check.gd`

`docs/phase61_quest_foundation/` adds this audit, dependency diagram, gallery, screenshots, raw logs, preservation hashes, source diff and reproduction evidence. `changed_files.json` lists source changes precisely. No assets, scenes, shaders, terrain, river, cave floor, camera, settings/control layout, player/combat, enemy/Dragon visuals, placements, save store, Android bootstrap or export preset changed. `project.godot` still selects `res://scenes/main.tscn`.

## Remaining limitations

- The future deep-cave thread is a dependency foundation, not playable lantern/awakening content. The existing Tidewraith loop is retained separately.
- The approved parchment remains a scroll. Current guidance/reward/next step are visible at its initial position; optional details and lore require scrolling. Physical Samsung A37 integrated usability/performance testing remains postponed.
- Legacy full-map regional camp symbols are unchanged; the live bounty count and compass use existing current targets. No new map-marker system or quests were added.
- No Android performance or thermal result is claimed. No new APK was requested for this phase. No asset/rendering additions were made, but input/rendering cost was not profiled in this quest-only phase.
- Existing stylized cave/environment limitations are outside this scope. No claim of commercial completion.

## Review package

The complete ZIP includes this evidence and a standalone `project/` with current runtime assets, scenes, scripts and regression fixtures. Open `gallery.html` after extracting; all links are relative and need no network. `REVIEW.md` explains candidate launch and isolated testing. Original map sources remain intact in the project/repository. No Git staging, commit or push was performed.

**Stop here for visual and functional approval. Do not start Phase 6.2 or activate the candidate.**

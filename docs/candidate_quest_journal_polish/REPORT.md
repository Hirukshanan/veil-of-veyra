# Interactive Quest Journal — final parchment polish

The candidate journal now restores the original ornate rollers, torn parchment edges and medieval corner decoration around the accepted interactive two-column layout. Existing Main, Side, Completed, tracking and bounty actions remain available. Actual before/after Godot views and interaction evidence accompany this report.

## Visual and input changes

The original `assets/ui/quest_parchment.jpg` supplies the paper body and two rollers through three atlas regions. The existing white-background material provides their silhouette. No new downloaded or generated art is used. Cinzel headings, Crimson Text body copy, warm ink, fine ornament dividers, restrained progress fills, original quest/action icons, a drawn shard symbol and an understated completion seal restore the manuscript presentation.

Opening moves the two rollers apart over **0.28 seconds** while revealing the paper and clipped contents. Closing brings them together over **0.20 seconds**. Content changes fade over **0.10 seconds**. Return to hunt, journal toggle and pause/back shortcuts use the animated close. Existing internal resume calls retain their established synchronous behavior. Closing disables journal buttons until the animation finishes. There is no continuous animation once the page settles.

Touch targets have a minimum height of 48 logical units; quest entries use 58. Both columns reuse the existing Settings TouchScroll. The journal lives inside the existing safe-area control. Captures/checks cover 1280×720, 1600×720, 800×450, and a synthetic 732×360 safe rectangle. Compact landscapes require more detail scrolling. Android/iOS journal copy replaces `COLLECT / E` with **Pick / Interact**, and `LIGHT / E` with **Interact**, reusing the current action semantics. Windows captures explicitly enable the mobile-copy flag for this verification. Native desktop copy retains keyboard instructions.

## Preserved behavior

The existing quest `entry` and `row` projection is retained byte-for-byte. No objective, gate, collection, reward amount or payment flag was added or changed. Version-4 campaign data and the existing separate tracking preference continue to be used. Bounty acceptance/reporting call the original campaign methods. The reserved future story, production map, 720p render configuration, gameplay controls, terrain, actors and combat remain at their baseline values.

SHA-256 checks cover **581 existing source/configuration/asset/test files**. Only `scripts/candidate_journal.gd` and the journal closing hooks in `scripts/island_candidate.gd` differ from the pre-polish baseline. Two new native Godot evidence tests are `tests/candidate_journal_polish_check.gd` and `tests/candidate_journal_motion_check.gd`. This documentation/evidence directory is also new. The earlier Android-build and journal-foundation changes already in the working tree were retained. `preservation.json` records every baseline hash.

## Verification

**14/14 programs pass**, all with exit code 0 and no script, shader or engine errors in the final logs. The two native UI runs verify real synthetic touch events, intermediate roller positions, opening/closing, selection, Main/Side/Completed, bounty acceptance/reporting, Track Quest, actual HUD contents, finger swipe, safe bounds, compact/wide sizes, journal/pause shortcuts and save/reload. Existing quest, HUD/customization, multitouch/controls/Settings, save/backup, persistent world, pause and candidate campaign tests also pass.

The completed view is earned with the existing grove interaction for plant IDs 8, 9 and 10. It awards 25 shards and sets the normal one-time flag. Western wolf IDs 0 and 1 are defeated using the existing damage method to exercise reporting. The bounty still defers its 15-shard payment until victory. After reload, the tracked relic, reported bounty, grove reward and 25-shard balance persist. The focused quest/save tests also cover seal/cave relic collection, the existing lantern/boss chain, old version-4 equipment/inventory progress, migrations and duplicate-payment prevention.

Raw stdout, stderr and run metadata are in `logs/`. Some existing HUD tests emit the previously recorded filled `draw_rect` width warning. No audio resource-release error occurred. The before PNG is the accepted interactive foundation captured before this task. After PNGs are actual Godot output. The video contains actual frame captures of opening/closing and the touch interaction sequence, followed by a labeled three-second hold on the actual post-reload capture. The capture fixture holds actor physics and relocates the player between existing herb interactions. Its 20/30 fps fixed-step playback is a UI recording and supplies no phone FPS measurement.

## Mobile cost and limitations

The paper uses three atlas draws from one existing texture. Decoration uses small native 2D primitives and existing icons. The short tweens modify geometry/opacity without additional 3D render effects. Android rendering configuration and HUD resolution code are hash-identical. Physical Samsung A37 touch feel, texture clarity and animation timing remain pending owner testing. No new APK or device performance claim is supplied in this focused visual pass. The original JPEG silhouette retains small bright edge pixels in a few places, and the rollers are widened for landscape presentation.

## Review

Extract the ZIP and open `gallery.html`; all media links are local. `source/` contains the changed candidate scripts and native test scripts. To reproduce, run the tests from the existing Godot 4.7.2 project with `VEYRA_TEST=1`, a fresh temporary APPDATA directory and an output directory as the final user argument. The polish test uses `--fixed-fps 20`; the motion test uses `--fixed-fps 30`. Run them with a graphical Compatibility renderer. Headless regressions are listed with their arguments in `test_results.json`.

The candidate remains pending final visual approval. No Git staging, commit or push was performed in this task. Phase 6.2 and production activation remain pending.

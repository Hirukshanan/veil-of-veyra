# Phase 3.4 — Boar audio and contact feedback

Status: implemented for user review. Stop here before another subphase. No APK, branch, commit, push or private upload was performed.

## Delivered behavior

- Dedicated spatial warning grunt, charge vocal, hurt/death vocal, grounded hoof beats, warning scrape, successful charge contact, light/heavy sword contacts and death landing.
- Warning starts on commitment. Scrape crosses the approved warning pose at 0.65 s. Death thud crosses the approved fall at 1.25 s. Walk contacts follow 0.3 s intervals; running paired contacts follow 0.3 s; charging pairs follow 0.25 s. No hoof events while stationary, airborne, distant or dead.
- A charge plays the body-hit cue only when the target's health actually falls. Dodge/invulnerability, misses and walls do not produce successful-contact audio. One successful impact per charge remains enforced by the existing hit guard.
- Normal and heavy sword contacts carry explicit context from the existing player attack path. A damage-5 upgraded normal swing remains light; the starter heavy remains heavy at damage 4. Other enemies retain their existing take_damage fallback. Spirit Burst still uses the existing generic damage path.
- Two short crossed gold contact strokes last 0.10 s (light) or 0.16 s (heavy), capped at two instances. They have no collision, shadows, lights, particles, hit stop, camera shake or gameplay effect. Existing hit flash and damage numbers remain intact.
- The existing sword movement beep is replaced with a short CC0 knife-derived movement cue. Existing dodge and player-hurt sounds remain unchanged. Existing sword-cue consumers (including parry/burst) still use the same binding. There is no new global combat/audio framework.

## Preservation and cost

The approved boar GLB and all Stage A/B delivery-manifest files are byte-identical. HUD positions, mirrored joystick/attack sizes, target-lock removal, hero, environment, quests, old enemy controller, dragon, save code and export/release files are unchanged. Boar HP 24, charge damage 18, 1.8 s warning, 3.12 m/s charge, 1.4 s recovery, heavy interruption and 20-shard one-time reward are unchanged.

13 short mono 24 kHz 16-bit PCM WAV effects add **504,098 source bytes**. Godot imports explicitly use uncompressed PCM and no loops, avoiding per-cue Vorbis decoding. Three AudioStreamPlayer3D channels (voice/hoof/contact) each allow one voice; sounds attenuate with distance, with 18 m hoof / 26 m other maximum range and a 0 dB ceiling. Existing Master volume/mute governs every new sound. Hurt vocal restarts are rate limited on game time; motion cues use the physics/animation clock. Two brief contact meshes are the only additional rendering work. No phone FPS, memory or latency target is claimed.

## Sources and asset assessment

All new source audio is free CC0 commercial-use material. [fvcalderan's Boar](https://opengameart.org/content/boar-0) is a human-voiced, EQ-processed fantasy boar grunt; warning/charge/hurt/death derive from that single short performance with pitch/layer changes. These are not four independently recorded real animals. [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds) provides dry footstep and body-impact layers; [Kenney RPG Audio](https://kenney.nl/assets/rpg-audio) provides knife movement texture. Original Kenney licenses, source links, exact file recipes and hashes are in `assets/audio/demon_boar/README.md` and `audio_manifest.json`. Model credit remains Hirukshanan using Tripo3D.

These are functional, small fantasy sound-design derivatives for in-game review. Their single-vocal family can sound repetitive; dedicated multi-take boar recordings, surface-specific hoof libraries and a final listening mix remain potential art upgrades. No paid asset, generative sound service or project upload was used. WAV suits short repetitive effects according to [Godot's audio import guidance](https://docs.godotengine.org/en/4.5/tutorials/assets_pipeline/importing_audio_samples.html).

## Actual gameplay review

Native Godot 4.7.2 Compatibility-renderer 1280×720 / 30 fps offline captures, using the real campaign scene, unchanged HUD, world, hero and existing action signals. The review fixture isolates the boar by pausing other camp enemies only in the fixture. It does not claim physical-touch testing. The initial setup frame alone is removed from the review encodes. All audio is native game output; no microphone, external soundtrack or post-added combat sounds.

- [Combined gameplay with sound](phase3_4/boar_audio_showcase.mp4)
- [Dodge and committed miss](phase3_4/boar_dodge.mp4): hero stays 100 HP; no charge impact cue.
- [Valid charge contact](phase3_4/boar_hit.mp4): hero 100 → 82 HP; one body-impact event.
- [Heavy, sword follow-up, death and reward](phase3_4/boar_defeat.mp4): boar starts at the unchanged 24 HP. The fixture uses the existing maximum blade upgrade, then earns/saves exactly 20 shards. One heavy cue, one light cue, one death vocal and one delayed landing.
- A fourth native capture runs with Master muted: combat still resolves to 82 HP and the entire decoded stereo game mix is exactly zero. Unmuted capture peaks/RMS and event timings are recorded in verification.json. No decoded capture reaches clipping.

Screenshots: [warning](phase3_4/boar_warning.png), [charge contact](phase3_4/boar_charge_hit.png), [heavy contact](phase3_4/boar_heavy_hit.png), [death/reward](phase3_4/boar_death.png).

## Verification and limitations

15 functional regression scripts passed: boar_feedback_check, boar_check, boar_campaign_check, heavy_attack_check, combat_check, enemy_check, free_combat_check, campaign_smoke, chapter_route_check, fast_travel_check, autosave_check, persistent_world_check, jump_check, hud_customization_check and quest_hud_check. New assertions cover warning/scrape timing, grounded/distant foot gating, misses/iframes/walls without impact, real normal/heavy distinction, bounded contacts/voices, unchanged combat costs, one death/landing and Master mute. Existing save, reward, quest, old-enemy and HUD checks stay intact.

**Remaining engine diagnostic:** intermittent Godot AudioStream/Playback objects/resources-still-in-use warnings occur at immediate process shutdown, also reproduced with a tiny standalone playback/free/quit diagnostic. PCM reduces decoding work but is not claimed to fix that engine teardown behavior. No runtime assertion, parse/load failure, clipping or observed encounter/save corruption occurred. Exact affected runs and diagnostic text are retained in `phase3_4/verification.json`. Any existing premium_hud draw_rect warning is also retained; HUD code was not changed to hide it. This delivery is not presented as warning-free engine teardown.

No Android device, thermal, physical-touch, loudspeaker/headphone listening approval or commercial final-mix certification was performed. Offline capture render/encoding timings are not gameplay FPS benchmarks. Wider wolf/fox combat polish and subsequent phases remain separate.

## Files and commands

Modified existing sources: scripts/demon_boar.gd, scripts/player.gd, tests/boar_check.gd. Added: scripts/boar_feedback.gd, tests/boar_feedback_check.gd, tests/boar_audio_review.gd and associated Godot UIDs; assets/audio/demon_boar/ effects, import metadata, licenses and manifest; this report and docs/phase3_4/ evidence. docs/.gdignore prevents documentation screenshots from becoming game imports. Godot-generated UID metadata for existing boar review tests is included where created by the editor.

Executed locally: public URL downloads with Python urllib (download only); FFmpeg mono/pitch/layer/fade processing and PCM conversion; Godot `--headless --editor --import --quit`; Godot `--headless --script res://tests/<name>.gd` for the 15 checks; native Godot `--script res://tests/boar_audio_review.gd --write-movie <case>.avi --fixed-fps 30 --resolution 1280x720 -- --case=dodge|hit|defeat|muted`; FFmpeg native-capture encoding/frame extraction and decoded-mix measurement; SHA-256 preservation checks; `git diff --check`.

All tests use VEYRA_TEST=1 and unique APPDATA directories inside .validation/phase3_4_2026-11-15. The audio replay refuses a non-validation profile before deleting its own three save files. Personal progress is never used. Logs/source downloads/local processing helpers and a separately verified backup are retained outside the review media; no session trace or private source was sent to a third party.

## Independent local checkpoint

Backup: `C:/Users/Dark/Documents/Codex/Backups/Veil_of_Vera_Phase3_4_2026-11-15_014931`. This separate directory contains the delivered code, tests, audio/licenses, review media, original downloaded CC0 packs, local processing helpers, and a copy of the unchanged approved runtime boar GLB. Its CHECKPOINT_MANIFEST.json records SHA-256 values and was independently rechecked. It is outside the repository, so undoing repository edits does not remove this checkpoint. Editable Stage A/B sources remain in their existing locations and earlier backups; they were not edited or copied again here.

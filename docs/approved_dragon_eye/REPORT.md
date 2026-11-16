# Approved Dragon eye integration

The artificial 3D oval and its custom shader were removed. The existing cinematic now draws the owner's approved eye imagery with an ordinary full-screen TextureRect. The approved MP4 was inspected; the realistic reveal starts at approximately 15.65 seconds. Six frames were extracted at 0.20-second intervals into one lossless 3840×1440 atlas. No new imagery was generated and no full Dragon model was modified.

## Timing and presentation

The supplied GIF contains six 0.35-second frames. At the approved 1.75× speed, each lasts 0.20 seconds: a 1.20-second sequence. Runtime opening starts at the existing 13.30-second breathing/eye cue. Frame six is visible from 14.30 seconds and held until the existing 15.70-second music cut/fade. No additional speed multiplier is applied. Other event cues, camera movement, lantern, pedestal, wall, roar, Skip, control restoration and progression remain unchanged.

The 16:9 reference framing is preserved with aspect-fit black margins on wider landscapes. The live Skip button remains above the imagery. The single atlas avoids per-frame file loads and video decoding; six AtlasTexture regions share the same texture. No new spatial shader, shader warmup or background preparation was introduced. Lossless import has no mipmaps. RGBA8 allocation is at most 21.1 MiB, before driver overhead; Android texture-limit and actual memory verification remain pending.

## Evidence and tests

The focused check verifies every frame boundary and the shared atlas, then exercises the entire cinematic, gate collision/traversal, protection, no duplicate rewards, camera/HUD restoration, Skip and save/reload. The existing version-4 quest/save compatibility test also passes. All recorded runs exit 0 with no script/shader errors. The pre-existing HUD draw_rect warning remains.

The matched Godot screenshot versus the extracted approved last frame scores SSIM **1.000000** over the image below the Skip corner. Both original PNGs are included. The movie is a new actual Godot movie-writer recording with engine audio at fixed 20 FPS. It demonstrates integration and audio cue order, not live FPS.

## Desktop live measurement

One on-screen, uncapped Windows Intel Iris Xe / native OpenGL Compatibility run uses an isolated save, shadows off before scene creation, 1280×720 and V-Sync disabled. Existing actors are held for repeatability.

| Window | p95 ms | p99 ms | Maximum ms | Mean draw calls | Mean submitted primitives |
| --- | ---: | ---: | ---: | ---: | ---: |
| Eye, 13.3–15.7 s | 2.936 | 3.503 | 9.527 | 4.0 | 82 |
| Whole cinematic | 4.730 | 5.956 | 3855.408 | 16.9 | 13087 |

The existing Windows linking issue is **not claimed fixed**. These are desktop results, not Samsung A37 performance. Raw frames, counters, commands and exit codes are included. The source asset has six authored frames; no interpolated in-between motion was invented. Physical Android playback, GPU texture limits and memory still need testing.

## Changed files

- scripts/lantern_awakening.gd: approved atlas overlay replaces the cropped 3D mesh/shader, with timeline-driven frame selection.
- assets/environment/lantern_awakening/approved_eye/: atlas, import settings and owner-source provenance.
- tests/lantern_awakening_check.gd: updated eye representation assertion.
- tests/approved_eye_check.gd: focused frame/timing and existing event regressions.
- docs/approved_dragon_eye/: actual captures, comparison, movie, metrics and logs.

Original staged Phase 6.2.1 changes remain staged; these new changes were not staged or committed. Production remains unchanged. No APK, Phase 6.3 or Chapter II work was performed. Stop for visual approval.

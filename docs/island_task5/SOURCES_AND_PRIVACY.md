# Task 5 sources and privacy

No new art assets, SDK downloads or third-party libraries were added. Existing project asset licenses and owner attribution are unchanged. New scripts are original local project tooling using Python standard library and Godot APIs. Existing Godot/Android SDK tools and FFmpeg-independent PNG evidence are used locally.

Public documentation consulted (generic queries only): [Godot Android export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html), [Godot command line](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html), [Android game profiling tools](https://developer.android.com/games/tools), [Android game system tracing](https://developer.android.com/games/optimize). No private source, model, screenshot, phone serial, credential or session trace was sent to these sites or other external services.

Only an isolated debug test APK is supplied. Private signing material stays in the local export profile and is excluded from source/archive. Measurements and future phone traces remain local. The supplied collector whitelists app/battery/thermal statistics and copies only the profiling CSV/JSON files; it does not collect saves, production data, global logcat, accounts or unrelated phone files.

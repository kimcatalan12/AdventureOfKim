# The Adventure of Kim

A 2D educational game that teaches Grade 5 students decimals and fractions. Built with Godot 4.7 and GDScript.

## Run it

Open this folder in Godot and press **Play** (F5).

## Change the design

- **Art:** replace any file in `art/`, keeping the same name.
- **Sound:** replace any file in `audio/`, keeping the same name.
- **Colors and buttons:** edit the top of `scripts/ui.gd`.
- **Maps, facts, lessons, questions:** edit `data/stage1.json`, `stage2.json`, `stage3.json`.
- **Story:** edit `data/story.json`.

`tools/gen_art.js` and `tools/gen_audio.js` created the starting art and sound. Running them again overwrites those files.

## Test it

```bash
godot --headless --path . -s tests/run_tests.gd
godot --headless --path . -- --bot
```

The first checks the rules, every question's answer, and the maps. The second plays the whole game through its real screens.

## Export

Presets for Web, Windows and Android are in `export_presets.cfg`. Android also needs Java and the Android SDK set in Godot's Editor Settings.

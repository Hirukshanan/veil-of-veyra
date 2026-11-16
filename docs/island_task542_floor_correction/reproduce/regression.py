from pathlib import Path
import json
import sys

W = Path(__file__).parent.resolve()
sys.path.insert(0, str(W.parent))
import run_island_polish as r
r.E = W / 'logs'
tests = ['cave_floor_material_check', 'island_river_escape_check', 'island_accessibility_collision_check', 'island_collision_check', 'island_campaign_check', 'island_enemy_navigation_check', 'boar_repeated_cycle_check', 'boar_check', 'boar_feedback_check', 'boar_campaign_check', 'enemy_check', 'combat_check', 'heavy_attack_check', 'campaign_smoke', 'autosave_check', 'persistent_world_check', 'fast_travel_check', 'mobile_controls_check', 'mobile_gestures_check', 'mobile_hud_layout_check', 'hud_customization_check', 'mobile_settings_touch_check', 'settings_check', 'pause_check', 'sprint_check', 'quest_hud_check', 'safe_area_check', 'layout_check']
if len(sys.argv) > 1:
    tests = sys.argv[1:]
for name in tests:
    try:
        r.run(name, ['--headless', '--verbose', '--path', r.R, '--script', 'res://tests/' + name + '.gd', '--', r.E], 300)
    except (SystemExit, Exception) as error:
        print('FAILED: ' + name + ' ' + type(error).__name__)
rows = []
for name in tests:
    row = json.loads((r.E / (name + '.run.json')).read_text())
    err = (r.E / (name + '.stderr.log')).read_text()
    row['engine_errors'] = [line for line in err.splitlines() if line.startswith(('ERROR:', 'SCRIPT ERROR:', 'SHADER ERROR:'))]
    row['passed'] = row['exit_code'] == 0 and not row['script_error'] and not row['engine_errors']
    rows.append(row)
(W / ('retest_results.json' if len(sys.argv) > 1 else 'test_results.json')).write_text(json.dumps(rows, indent=2))
print(json.dumps({'total': len(rows), 'passed': sum(row['passed'] for row in rows), 'failed': [row['name'] for row in rows if not row['passed']]}))

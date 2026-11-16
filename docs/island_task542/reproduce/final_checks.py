from pathlib import Path
import json
import sys

W = Path(__file__).parent.resolve()
sys.path.insert(0, str(W.parent))
import run_island_polish as r
r.E = W / 'logs'
r.run('cave_geometry', ['--headless', '--path', r.R, '--script', W / 'cave_geometry_check.gd', '--', r.E], 180)
for iteration in range(5):
    r.run('audio_after_%02d' % iteration, ['--headless', '--verbose', '--path', r.R, '--script', 'res://tests/heavy_attack_check.gd'], 60)
    err = (r.E / ('audio_after_%02d.stderr.log' % iteration)).read_text()
    assert not any(line.startswith(('ERROR:', 'SCRIPT ERROR:', 'SHADER ERROR:')) for line in err.splitlines())
print('PASS: cave geometry and five clean heavy-attack shutdowns')

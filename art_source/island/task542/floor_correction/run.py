from pathlib import Path
import sys
W = Path(__file__).parent.resolve()
sys.path.insert(0, str(W.parent))
import run_island_polish as r
r.E = W / 'logs'
r.E.mkdir(exist_ok=True)
mode = sys.argv[1]
if mode == 'diagnose':
    r.run('diagnose_' + sys.argv[2], ['--headless', '--path', r.R, '--script', W / 'diagnose.gd', '--', W / ('diagnosis_' + sys.argv[2] + '.json')], 180)
elif mode in ['before', 'after']:
    project = W / 'baseline_project' if mode == 'before' else r.R
    r.run('capture_' + mode, ['--path', project, '--position', '-20000,-20000', '--script', W / 'views.gd', '--', W / mode], 240, root=project)

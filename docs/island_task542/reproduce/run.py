from pathlib import Path
import sys

W = Path(__file__).parent.resolve()
sys.path.insert(0, str(W.parent))
import run_island_polish as runner
runner.E = W / 'logs'
runner.E.mkdir(exist_ok=True)
if sys.argv[1] in ['before', 'after']:
    project = W / 'baseline_project' if sys.argv[1] == 'before' else runner.R
    runner.run('capture_' + sys.argv[1], ['--path', project, '--position', '-20000,-20000', '--script', W / 'views.gd', '--', W / sys.argv[1]], 300, root=project)
else:
    for name in sys.argv[1:]:
        runner.run(name, ['--headless', '--verbose', '--path', runner.R, '--script', 'res://tests/' + name + '.gd', '--', runner.E], 300)

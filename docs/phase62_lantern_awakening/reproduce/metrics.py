from pathlib import Path
import shutil,sys
W=Path(__file__).parent.resolve()
R=Path('C:/Users/Dark/Desktop/Projects/veil-of-veyra')
baseline=W/'baseline_project'
if not baseline.exists():
    baseline.mkdir()
    for name in ['scripts','scenes','assets']:
        shutil.copytree(R/name,baseline/name)
    shutil.copy2(R/'project.godot',baseline/'project.godot')
    shutil.copytree(R/'.godot/imported',baseline/'.godot/imported')
    for name in ['uid_cache.bin','global_script_class_cache.cfg']:
        if (R/'.godot'/name).exists():shutil.copy2(R/'.godot'/name,baseline/'.godot'/name)
    for name in ['island_candidate.gd','candidate_journal.gd','campaign_store.gd']:
        shutil.copy2(W/'baseline'/name,baseline/'scripts'/name)
sys.path.insert(0,str(W.parent));import run_island_polish as r
r.E=W/'logs'
for label,project in [('baseline',baseline),('candidate',R)]:
    r.run('render_cost_'+label,['--path',project,'--script',W/'metrics.gd','--position','-20000,-20000','--rendering-method','gl_compatibility','--',W/(label+'_metrics.json'),label],300,root=project)

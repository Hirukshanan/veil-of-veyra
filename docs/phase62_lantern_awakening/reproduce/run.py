from pathlib import Path
import sys
W=Path(__file__).parent.resolve()
sys.path.insert(0,str(W.parent));import run_island_polish as r
r.E=W/'logs';r.E.mkdir(exist_ok=True)
if len(sys.argv)==1:
    r.run('awakening_check',['--headless','--path',r.R,'--script',W/'check.gd','--fixed-fps','60','--',r.E],360)
elif sys.argv[1]=='import':
    r.run('phase62_import',['--headless','--editor','--path',r.R,'--import'],240)
else:
    for name in sys.argv[1:]:
        try:r.run(name,['--headless','--path',r.R,'--script','res://tests/'+name+'.gd','--',r.E],240)
        except SystemExit:pass

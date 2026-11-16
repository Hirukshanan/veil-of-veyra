from pathlib import Path
import sys
W=Path(__file__).parent.resolve()
sys.path.insert(0,str(W.parent));import run_island_polish as r
r.E=W/'logs'
out=W/'capture';out.mkdir(exist_ok=True)
r.run('cinematic_movie',['--path',r.R,'--script',W/'capture.gd','--position','-20000,-20000','--resolution','1280x720','--rendering-method','gl_compatibility','--fixed-fps','20','--write-movie',out/'cinematic.avi','--',out],600)

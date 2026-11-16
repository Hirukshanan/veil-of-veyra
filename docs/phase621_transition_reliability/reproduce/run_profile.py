from pathlib import Path
import sys,os
W=Path(__file__).parent.resolve()
sys.path.insert(0,str(W.parent));import run_island_polish as r
r.E=W/'logs'
os.environ['VEYRA_PROFILE_CINEMATIC']='1'
for mode in sys.argv[1:]:
    args=['--headless'] if mode=='headless' else ['--position','50,50' if mode.startswith('visible') else '-20000,-20000','--rendering-method','gl_compatibility']
    if mode.startswith('angle'):args+=['--rendering-driver','opengl3_angle']
    r.run(mode,['--path',r.R,'--script',W/'profile.gd',*args,'--',W/(mode+'.json'),mode],300)

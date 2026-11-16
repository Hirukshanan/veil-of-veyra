from pathlib import Path
import os,sys,subprocess,time,json,datetime
R=Path('C:/Users/Dark/Desktop/Projects/veil-of-veyra');E=R/'.validation/island_polish_task1';E.mkdir(parents=True,exist_ok=True)
G=Path('C:/Users/Dark/Documents/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe')
def run(name,args,timeout=300,root=R):
 env=os.environ.copy();env['VEYRA_TEST']='1';env['APPDATA']=str(E/('profile_'+name+'_'+str(time.time_ns())))
 start=datetime.datetime.now(datetime.timezone.utc).isoformat();t=time.monotonic();script_error=False
 with (E/(name+'.stdout.log')).open('w') as out,(E/(name+'.stderr.log')).open('w') as err:
  p=subprocess.Popen([str(G),*map(str,args)],env=env,stdout=out,stderr=err,creationflags=subprocess.CREATE_NO_WINDOW);(E/(name+'.pid')).write_text(str(p.pid))
  while p.poll() is None:
   time.sleep(.25)
   if 'SCRIPT ERROR:' in (E/(name+'.stderr.log')).read_text(errors='replace'):
    script_error=True;p.terminate();p.wait(10);break
   if time.monotonic()-t>timeout:
    subprocess.run(['taskkill','/PID',str(p.pid),'/T','/F'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL);raise TimeoutError(name)
  code=p.returncode
 meta={'name':name,'started_utc':start,'duration_s':round(time.monotonic()-t,3),'exit_code':code,'script_error':script_error,'arguments':[str(a).replace(str(root),'PROJECT_ROOT').replace(str(E),'EVIDENCE_ROOT') for a in args],'profile':'unique isolated APPDATA; VEYRA_TEST=1'}
 (E/(name+'.run.json')).write_text(json.dumps(meta,indent=2)+'\n');print(json.dumps(meta),flush=True)
 if code or script_error:raise SystemExit(1)
if __name__=='__main__':
 mode=sys.argv[1]
 if mode=='test':
  for name in sys.argv[2:]:run(name,['--headless','--path',R,'--script','res://tests/'+name+'.gd'])
 if mode=='capture':run('visual_capture',['--path',R,'--script','res://tests/island_visual_capture.gd','--resolution','1280x720','--position','-20000,-20000','--rendering-method','gl_compatibility'],600)


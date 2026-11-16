from pathlib import Path
import datetime,hashlib,json,os,shutil,subprocess,time,sys
W=Path(__file__).parent.resolve();R=Path('C:/Users/Dark/Desktop/Projects/veil-of-veyra')
G='C:/Users/Dark/Documents/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe'
out=W/'import_probe';out.mkdir(exist_ok=True)
rows=[]
for threaded in [True,False]:
    for trial in range(1,7):
        root=out/('fonts_'+str(threaded)+'_'+str(trial));root.mkdir()
        (root/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Local font import diagnostic"\n[editor]\nimport/use_multiple_threads='+str(threaded).lower()+'\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
        fonts=[p for p in (R/'assets').rglob('*') if p.suffix.lower() in ['.ttf','.otf']]
        for p in fonts:shutil.copy2(p,root/p.name)
        assert not (root/'.godot').exists()
        env=os.environ.copy();env['APPDATA']=str(root/'isolated_profile');env['VEYRA_TEST']='1'
        start=time.monotonic()
        with (out/(root.name+'.stdout.log')).open('w') as stdout,(out/(root.name+'.stderr.log')).open('w') as stderr:
            p=subprocess.run([G,'--headless','--editor','--path',str(root),'--import'],stdout=stdout,stderr=stderr,env=env,timeout=120,creationflags=subprocess.CREATE_NO_WINDOW)
        row={'trial':trial,'threaded':threaded,'fresh_cache':True,'files':len(fonts),'exit_code':p.returncode,'seconds':round(time.monotonic()-start,3),'only_fonts_no_game_scripts':True}
        rows.append(row);print(json.dumps(row),flush=True)
        (out/'results.json').write_text(json.dumps(rows,indent=2))

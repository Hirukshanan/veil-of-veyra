from pathlib import Path
import hashlib,json,os,subprocess,time,zipfile,sys
W=Path(__file__).parent.resolve()
archive=W.parents[1]/'deliverables/Veil_of_Vera_Phase62_Lantern_Awakening_Review.zip'
out=W/'fresh_imports';out.mkdir(exist_ok=True)
G='C:/Users/Dark/Documents/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe'
rows=[]
for mode in sys.argv[1:]:
    root=out/mode;root.mkdir()
    with zipfile.ZipFile(archive) as z:
        for name in z.namelist():
            if name.startswith('project/'):
                target=root/name[8:]
                assert target.resolve().is_relative_to(root.resolve())
                target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(z.read(name))
    p=root/'project.godot'
    threaded=not mode.startswith('serial')
    if not threaded:p.write_text(p.read_text()+'\n[editor]\nimport/use_multiple_threads=false\n')
    assert not (root/'.godot').exists()
    source_files=sum(1 for p in root.rglob('*') if p.is_file())
    env=os.environ.copy();env['APPDATA']=str(out/('profile_'+mode));env['VEYRA_TEST']='1'
    begin=time.monotonic()
    with (out/(mode+'.stdout.log')).open('w') as stdout,(out/(mode+'.stderr.log')).open('w') as stderr:
        run=subprocess.run([G,'--headless','--editor','--path',str(root),'--import'],stdout=stdout,stderr=stderr,env=env,timeout=300,creationflags=subprocess.CREATE_NO_WINDOW)
    row={'mode':mode,'threaded':threaded,'fresh_extraction':True,'cache_absent_before_run':True,'partial_cache_reused':False,'source_files':source_files,'seconds':round(time.monotonic()-begin,3),'exit_code':run.returncode,'source_ZIP_sha256':hashlib.sha256(archive.read_bytes()).hexdigest()}
    rows.append(row);print(json.dumps(row),flush=True)
    (out/(mode+'.run.json')).write_text(json.dumps(row,indent=2))

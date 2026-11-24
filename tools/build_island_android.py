"""Build an isolated candidate-only Android APK; original project files stay untouched."""
from pathlib import Path
import argparse,hashlib,json,os,re,shutil,subprocess,time,datetime

def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def run(cmd,logs,label,env,timeout=1200):
 start=time.monotonic();p=subprocess.run([str(a) for a in cmd],env=env,capture_output=True,timeout=timeout,creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
 for suffix,data in [('stdout',p.stdout),('stderr',p.stderr)]:
  text=data.decode('utf-8',errors='replace');text=re.sub(r'(?im)^.*(?:password|storepass|keypass|token|secret|credential).*$','[sensitive signing detail omitted]',text)
  (logs/f'{label}.{suffix}.log').write_text(text,encoding='utf-8')
 meta={'name':label,'exit_code':p.returncode,'duration_s':round(time.monotonic()-start,3)};(logs/f'{label}.run.json').write_text(json.dumps(meta,indent=2));print(json.dumps(meta),flush=True)
 if p.returncode:raise RuntimeError(label+' failed; inspect sanitized local logs')
 return p.stdout.decode('utf-8',errors='replace')
def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--task',choices=['5.1','5.2','5.3','5.4','6.1'],default='5.1');parser.add_argument('--render-height',type=int,choices=[0,720],default=0,help='0=native baseline; 720=3D-only capped-resolution trial');parser.add_argument('--repo',type=Path,default=Path(__file__).resolve().parents[1]);parser.add_argument('--godot',type=Path,required=True);parser.add_argument('--sdk',type=Path,required=True);parser.add_argument('--java',type=Path,required=True);parser.add_argument('--templates',type=Path,required=True);parser.add_argument('--staging',type=Path,required=True);parser.add_argument('--output',type=Path,required=True);args=parser.parse_args()
 assert args.task not in ['5.2','5.3','5.4','6.1'] or args.render_height==720,'Task 5.2 and later must preserve the accepted 720p cap'
 R=args.repo.resolve();stage=args.staging.resolve();out=args.output.resolve()
 assert not stage.exists(),'Use a new staging directory; no recursive deletion is performed'
 assert not stage.is_relative_to(R) and not R.is_relative_to(stage),'Stage outside the source repository'
 out.mkdir(parents=True,exist_ok=True);logs=out/'logs';logs.mkdir(exist_ok=True);stage.mkdir(parents=True)
 originals={p.relative_to(R).as_posix():digest(p) for folder in ['scripts','scenes','assets'] for p in (R/folder).rglob('*') if p.is_file()}
 originals.update({n:digest(R/n) for n in ['project.godot','export_presets.cfg']})
 for folder in ['scripts','scenes','assets']:shutil.copytree(R/folder,stage/folder)
 # Imported caches are copies, never links: staging import cannot modify approved caches.
 if (R/'.godot/imported').exists():shutil.copytree(R/'.godot/imported',stage/'.godot/imported')
 for n in ['uid_cache.bin','global_script_class_cache.cfg']:
  p=R/'.godot'/n
  if p.exists():shutil.copy2(p,stage/'.godot'/n)
 project=(R/'project.godot').read_text(encoding='utf-8')
 source_main=re.search(r'(?m)^run/main_scene="([^"\r\n]+)"[ \t]*$',project)
 if source_main is None:raise ValueError('Project must declare a default scene')
 production_main=source_main.group(1)
 project=project[:source_main.start()]+'run/main_scene="res://mobile_test/main.tscn"'+project[source_main.end():]
 project=project.replace('config/name="Veil of Veyra"','config/name="Veil of Veyra Island Test"')
 (stage/'project.godot').write_text(project)
 source=Path(__file__).parent
 # Script lives under tools/ in the repository; deployed copies live in mobile_test/ only in staging.
 (stage/'mobile_test').mkdir()
 (stage/'mobile_test/performance_config.json').write_text(json.dumps({'task':args.task,'experiment':('accepted_cap720' if args.task in ['5.2','5.3','5.4','6.1'] else 'cap720_trial') if args.render_height else 'native_baseline','render_height':args.render_height,'single_changed_variable':'Phase 6.1 quests with approved cave refinements and mobile controls; accepted 720p rendering preserved' if args.task=='6.1' else 'Task 5.4 mobile controls/settings; accepted 720p rendering preserved' if args.task=='5.4' else ('Task 5.3 encounters/navigation and repeating boar combat; accepted 720p preserved' if args.task=='5.3' else 'Task 5.2 geometry/collisions; accepted 720p rendering preserved') if args.task in ['5.2','5.3'] else '3D rendering resolution only','phone_improvement_verified':False},indent=2))
 for src,dst in [('mobile_bootstrap.gd','bootstrap.gd'),('mobile_probe.gd','probe.gd')]:shutil.copy2(source/(src+".template"),stage/'mobile_test'/dst)
 (stage/'mobile_test/main.tscn').write_text('[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://mobile_test/bootstrap.gd" id="1"]\n\n[node name="IslandAndroidTest" type="Node"]\nscript = ExtResource("1")\n')
 preset=(R/'export_presets.cfg').read_text().replace('name="Android Debug"','name="Island Android Test"').replace('export_path="builds/android/veyra-debug.apk"','export_path=""').replace('package/unique_name="com.hirukshanan.veilofveyra.dev"','package/unique_name="com.hirukshanan.veilofveyra.islandtest"').replace('package/name="Veil of Veyra"','package/name="Veil of Veyra Island Test"')
 preset=preset.replace('include_filter=""','include_filter="mobile_test/*.json,assets/**/*.json,assets/**/*.bin,*.json,*.bin"')
 preset=preset.replace('exclude_filter="','exclude_filter="art_source/*,docs/*,tests/*,tools/*,.validation/*,builds/*,',1)
 assert 'com.hirukshanan.veilofveyra.islandtest' in preset
 if args.task=='6.1':
  preset=re.sub(r'(?m)^version/code=(\d+)$',lambda match:'version/code='+str(int(match[1])+1),preset)
  preset=re.sub(r'(?m)^version/name=.*$', 'version/name="0.12.2-phase6.1-test"',preset)
 (stage/'export_presets.cfg').write_text(preset)
 profile=stage.parent/'island_android_export_profile';godot_profile=profile/'Godot';godot_profile.mkdir(parents=True,exist_ok=True)
 target=godot_profile/'export_templates'/args.templates.name;shutil.copytree(args.templates,target,dirs_exist_ok=True)
 # Minimal isolated editor settings: no user editor settings or signing credentials copied.
 settings='[gd_resource type="EditorSettings" format=3]\n\n[resource]\nexport/android/java_sdk_path='+json.dumps(args.java.as_posix())+'\nexport/android/android_sdk_path='+json.dumps(args.sdk.as_posix())+'\n'
 (godot_profile/'editor_settings-4.7.tres').write_text(settings)
 env=os.environ.copy();env['APPDATA']=str(profile);env['JAVA_HOME']=str(args.java);env['ANDROID_HOME']=str(args.sdk);env['PATH']=str(args.java/'bin')+os.pathsep+env.get('PATH','')
 run([args.godot,'--headless','--editor','--path',stage,'--import'],logs,'import',env)
 apk=out/('Veil_of_Veyra_Phase61_720p_Candidate.apk' if args.task=='6.1' else 'Veil_of_Veyra_Task54_720p_Candidate.apk' if args.task=='5.4' else ('Veil_of_Veyra_Task53_720p_Candidate.apk' if args.task=='5.3' else ('Veil_of_Veyra_Task52_720p_Candidate.apk' if args.task=='5.2' else ('Veil_of_Veyra_Task51_Native_Baseline.apk' if args.render_height==0 else 'Veil_of_Veyra_Task51_720p_Trial.apk'))))
 run([args.godot,'--headless','--path',stage,'--export-debug','Island Android Test',apk],logs,'export',env)
 assert apk.exists() and apk.stat().st_size>1000000
 assert all(digest(R/n)==h for n,h in originals.items()),'Source changed during build'
 manifest={'created_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'apk':apk.name,'apk_bytes':apk.stat().st_size,'apk_sha256':digest(apk),'package':'com.hirukshanan.veilofveyra.islandtest','candidate':'res://scenes/island_candidate.tscn','staged_main':'res://mobile_test/main.tscn','production_main':production_main,'source_project_and_export_unchanged':True,'runtime_assets_and_scripts_unchanged':True,'source_hashes':originals,'quality_defaults':{'frame_limit':30,'shadows':False,'renderer':'gl_compatibility','design_viewport':[1280,720],'render_height_cap':args.render_height,'hud_resolution':'native; Task 5.4 enlarged matched controls' if args.task in ['5.4','6.1'] else 'native; unchanged layout','saved_preferences':'retained; defaults apply only to a fresh install'},'debug_build':True,'network_permission_requested':False,'instrumentation':'schema 2 local frame intervals, physical viewport/3D scale, CPU/GPU render timers, physics/collision counters and memory; unsupported timings are unavailable, not inferred','staging_path':str(stage)}
 (out/'build_manifest.json').write_text(json.dumps(manifest,indent=2));print(json.dumps({k:v for k,v in manifest.items() if k!='source_hashes'}),flush=True)
if __name__=='__main__':main()

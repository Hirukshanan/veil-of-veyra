from pathlib import Path
import sys,json
sys.path.insert(0,str(Path(__file__).parent))
import run_island_polish as r
r.E=r.R/'.validation/island_task54';r.E.mkdir(parents=True,exist_ok=True)
tests=['mobile_gestures_check','mobile_settings_touch_check','mobile_hud_layout_check','mobile_controls_check','settings_check','sprint_check','pause_check','layout_check','safe_area_check','boar_repeated_cycle_check','island_enemy_navigation_check','island_accessibility_collision_check','island_river_escape_check','island_atmosphere_check','island_rock_water_check','island_forest_refinement_check','island_vegetation_check','island_terrain_polish_check','island_check','island_campaign_check','island_collision_check','island_connections_review','boar_feedback_check','boar_check','boar_campaign_check','heavy_attack_check','combat_check','enemy_check','campaign_smoke','autosave_check','persistent_world_check','fast_travel_check','hud_customization_check','quest_hud_check']
if len(sys.argv)>1:tests=sys.argv[1:]
records=[]
for name in tests:
 args=['--path',r.R,'--script','res://tests/'+name+'.gd','--resolution','1280x720','--position','-20000,-20000','--rendering-method','gl_compatibility'] if name=='island_forest_refinement_check' else ['--headless','--path',r.R,'--script','res://tests/'+name+'.gd']
 if name in ['mobile_gestures_check','mobile_settings_touch_check','mobile_hud_layout_check','boar_repeated_cycle_check','island_enemy_navigation_check','island_accessibility_collision_check','island_river_escape_check']:args+=['--',r.E]
 try:r.run('final_'+name,args,600)
 except (SystemExit,Exception) as err:print('FAILED_CHECK '+name+' '+type(err).__name__,flush=True)
 p=r.E/('final_'+name+'.run.json');row=json.loads(p.read_text()) if p.exists() else {'name':name,'exit_code':None,'script_error':True}
 err=(r.E/('final_'+name+'.stderr.log')).read_text(errors='replace');row['engine_errors']=[line for line in err.splitlines() if line.startswith(('SCRIPT ERROR:','SHADER ERROR:','ERROR:'))];row['passed']=row['exit_code']==0 and not row['script_error'] and not row['engine_errors'];records.append(row)
(r.E/('test_results.json' if len(sys.argv)==1 else 'retest_results.json')).write_text(json.dumps(records,indent=2));print(json.dumps({'total':len(records),'passed':sum(row['passed'] for row in records),'failed':[row['name'] for row in records if not row['passed']]}),flush=True)

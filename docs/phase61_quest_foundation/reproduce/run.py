from pathlib import Path
import sys, json
W=Path(__file__).parent.resolve();sys.path.insert(0,str(W.parent));import run_island_polish as r
r.E=W/'logs';r.E.mkdir(exist_ok=True)
rows=[]
for name in sys.argv[1:]:
 try:r.run(name,['--headless','--verbose','--path',r.R,'--script','res://tests/'+name+'.gd','--',r.E],240)
 except (SystemExit,Exception) as error:print('FAILED '+name+' '+type(error).__name__,flush=True)
 row=json.loads((r.E/(name+'.run.json')).read_text());err=(r.E/(name+'.stderr.log')).read_text(errors='replace');row['engine_errors']=[line for line in err.splitlines() if line.startswith(('SCRIPT ERROR:','SHADER ERROR:','ERROR:'))];row['passed']=row['exit_code']==0 and not row['script_error'] and not row['engine_errors'];rows.append(row)
(W/'latest_tests.json').write_text(json.dumps(rows,indent=2));print(json.dumps({'total':len(rows),'passed':sum(row['passed'] for row in rows),'failed':[row['name'] for row in rows if not row['passed']]}),flush=True)

"""Local-only measurements for the isolated island test APK. Never claims desktop data is Android."""
from pathlib import Path
import argparse,csv,io,json,math,re,subprocess,time,datetime,tarfile,statistics
PACKAGE='com.hirukshanan.veilofveyra.islandtest'
def adb(args,command,binary=False,timeout=25):
 p=subprocess.run([str(args.adb),*command],capture_output=True,timeout=timeout,creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
 if p.returncode:raise RuntimeError('ADB operation unavailable; no measurement inferred')
 return p.stdout if binary else p.stdout.decode('utf-8',errors='replace')
def availability(args):
 lines=adb(args,['devices']).splitlines()[1:]
 rows=[line.split() for line in lines if len(line.split())>=2]
 physical=[r for r in rows if not r[0].startswith('emulator-')]
 count=sum(r[1]=='device' for r in physical)
 if sum(r[1]=='device' for r in rows)!=1:count=0
 return {'checked_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'physical_devices':len(physical),'authorized_physical_devices':count,'device_identifiers_recorded':False,'android_test_status':'available' if count==1 else 'pending: connect exactly one authorized physical phone','device_model':None,'android_version':None,'actual_fps':None,'frame_times':None,'thermal':None,'battery':None}
def phone(args):
 row=availability(args)
 if row['authorized_physical_devices']!=1:return row
 for name,key in [('manufacturer','ro.product.manufacturer'),('device_model','ro.product.model'),('android_version','ro.build.version.release'),('android_api','ro.build.version.sdk'),('abi','ro.product.cpu.abi')]:row[name]=adb(args,['shell','getprop',key]).strip()
 return row
def snapshot(args):
 battery=adb(args,['shell','dumpsys','battery'])
 allowed=['AC powered','USB powered','Wireless powered','level','scale','temperature','voltage','Charge counter','status']
 fields={}
 for line in battery.splitlines():
  if ':' not in line:continue
  key,value=line.strip().split(':',1)
  if key in allowed:fields[key]=value.strip()
 result={'monotonic_s':time.monotonic(),'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'battery_reported_fields':fields,'battery_units':'temperature is tenths C; voltage mV; Charge counter uAh where supplied; not CPU/GPU temperature'}
 try:
  text=adb(args,['shell','dumpsys','meminfo',PACKAGE]);match=re.search(r'TOTAL PSS:\s*(\d+)',text)
  if not match:match=re.search(r'^\s*TOTAL\s+(\d+)',text,re.M)
  result['app_total_pss_kib']=int(match[1]) if match else None
  result['meminfo_available']=bool(match)
 except RuntimeError:result['meminfo_available']=False
 try:
  text=adb(args,['shell','dumpsys','thermalservice']);status=re.search(r'Thermal Status:\s*(\d+)',text)
  result['thermal_status']=int(status[1]) if status else None
  result['thermal_temperatures']=[{'celsius':float(a),'android_sensor_type':int(b),'status':int(c)} for a,b,c in re.findall(r'mValue=([-\d.]+).*?mType=(\d+).*?mStatus=(\d+)',text)]
 except RuntimeError:result['thermal_status']=None
 # No complete system dumps, sensor names, logcat, account fields or identifiers are retained.
 return result
def quantile(values,p):return sorted(values)[max(0,math.ceil(len(values)*p)-1)]
def summarize(folder,warmup,synthetic=False):
 metadata=json.loads((folder/'session.json').read_text())
 if not synthetic and metadata.get('platform')!='Android':raise ValueError('This is not an Android recording; desktop and synthetic files cannot be reported as phone results')
 intervals=[];prior_active=False;first_active=None
 with (folder/'frames.csv').open(newline='') as f:
  reader=csv.DictReader(f)
  if reader.fieldnames!=['monotonic_us','interval_us','active_gameplay']:raise ValueError('Unexpected frame CSV schema')
  for row in reader:
   stamp=int(row['monotonic_us']);interval=int(row['interval_us']);active=row['active_gameplay']=='1'
   if active and first_active is None:first_active=stamp
   if active and prior_active and stamp>=first_active+warmup*1000000 and interval>0:intervals.append(interval/1000)
   prior_active=active
 if not intervals:raise ValueError('No foreground gameplay samples after the requested warm-up')
 result={'measurement_kind':'synthetic parser test' if synthetic else 'Android engine callback intervals','platform':metadata['platform'],'model':metadata.get('model'),'discarded_warmup_seconds':warmup,'foreground_intervals':len(intervals),'sampled_gameplay_seconds':sum(intervals)/1000,'mean_callback_fps':1000/statistics.mean(intervals),'p50_ms':quantile(intervals,.50),'p95_ms':quantile(intervals,.95),'p99_ms':quantile(intervals,.99),'max_ms':max(intervals),'over_50ms':sum(v>50 for v in intervals),'over_100ms':sum(v>100 for v in intervals),'display_present_fps':None,'gpu_time':None,'note':'Engine callback intervals include CPU/driver/observer overhead; verify actual SurfaceView presentation with device-local tools. No automatic mobile-readiness verdict.'}
 counters=folder/'counters.csv'
 if counters.exists():
  rows=list(csv.DictReader(counters.open()))
  result['engine_counter_maxima']={key:max((float(r[key]) for r in rows),default=None) for key in ['static_bytes','video_bytes','texture_bytes','draw_calls','primitives']}
 result['experiment']=metadata.get('experiment',{})
 result['initial_resolution']={k:metadata.get(k) for k in ['physical_window_pixels','root_viewport_pixels','scaling_3d','estimated_3d_buffer_pixels','bootstrap_to_placement_ready_ms']}
 if counters.exists():
  valid=[r for r in rows if r.get('paused')=='0' and float(r['monotonic_us'])>=first_active+warmup*1000000]
  result['backend_timing_samples']={}
  for key in ['render_cpu_ms','gpu_ms','physics_ms','process_ms','csv_flush_ms']:
   values=[float(r[key]) for r in valid if key in r and float(r[key])>0]
   result['backend_timing_samples'][key]={'mean_ms':statistics.mean(values),'max_ms':max(values),'five_second_samples':len(values)} if values else None
  result['gpu_time']=result['backend_timing_samples']['gpu_ms']
  result['gpu_time_note']='Backend timer if positive; null means unavailable. Aggregates five-second averages, not per-frame GPU p95 or display-present timing.'
 return result
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('action',choices=['check','collect','pull','analyze','self-test']);p.add_argument('--adb',type=Path,default=Path('adb'));p.add_argument('--output',type=Path,required=True);p.add_argument('--minutes',type=float,default=30);p.add_argument('--interval',type=float,default=30);p.add_argument('--session',type=Path);p.add_argument('--warmup',type=float,default=300);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
 if a.action=='self-test':
  from tempfile import TemporaryDirectory
  with TemporaryDirectory() as temp:
   d=Path(temp);(d/'session.json').write_text(json.dumps({'platform':'Synthetic'}))
   (d/'frames.csv').write_text('monotonic_us,interval_us,active_gameplay\n0,1,0\n1,900000,1\n33334,33333,1\n66667,33333,1\n166668,100001,1\n900000,700000,0\n900001,733332,1\n933334,33333,1\n')
   row=summarize(d,0,True);assert row['foreground_intervals']==4 and row['p50_ms']==33.333 and row['p99_ms']==100.001 and row['over_100ms']==1
   (d/'counters.csv').write_text('monotonic_us,draw_calls,primitives,static_bytes,video_bytes,texture_bytes,paused,render_cpu_ms,gpu_ms,physics_ms,process_ms,csv_flush_ms\n933334,10,200,1000,2000,1000,0,2,0,1,4,0.2\n')
   upgraded=summarize(d,0,True);assert upgraded['gpu_time'] is None and upgraded['backend_timing_samples']['render_cpu_ms']['mean_ms']==2
   try:summarize(d,0)
   except ValueError:pass
   else:raise AssertionError('Synthetic data must never be accepted as Android data')
   row={'passed':True,'checks':['pause/resume boundary intervals excluded','long genuine hitch retained','nearest-rank quantiles','synthetic/desktop rejected as Android','schema 2 CPU timing and unavailable zero GPU handling'],'phone_results':False}
  (a.output/'profiler_self_test.json').write_text(json.dumps(row,indent=2));print(json.dumps(row));return
 if a.action=='analyze':
  assert a.session is not None,'Pass the extracted local session folder'
  row=summarize(a.session,a.warmup);(a.output/'frame_summary.json').write_text(json.dumps(row,indent=2));print(json.dumps(row,indent=2));return
 row=phone(a);(a.output/'device_check.json').write_text(json.dumps(row,indent=2));print(json.dumps(row),flush=True)
 if row['authorized_physical_devices']!=1:return
 if a.action=='check':return
 if a.action=='pull':
  names=[n.strip() for n in adb(a,['shell','run-as',PACKAGE,'ls','files']).splitlines() if re.fullmatch(r'mobile_profile_\d+',n.strip())]
  for name in names:
   payload=adb(a,['exec-out','run-as',PACKAGE,'tar','-cf','-','files/'+name],True)
   with tarfile.open(fileobj=io.BytesIO(payload)) as tar:
    for entry in tar.getmembers():
     if entry.isfile() and Path(entry.name).name in ['session.json','frames.csv','counters.csv']:
      target=a.output/name/Path(entry.name).name;target.parent.mkdir(exist_ok=True);target.write_bytes(tar.extractfile(entry).read())
  print(json.dumps({'local_profile_sessions_pulled':len(names),'campaign_saves_and_settings_copied':False}));return
 assert 0<a.minutes<=120 and 5<=a.interval<=60
 duration=a.minutes*60;start=time.monotonic();rows=[]
 while time.monotonic()-start<=duration:
  item=snapshot(a);item['elapsed_s']=round(time.monotonic()-start,2);rows.append(item)
  (a.output/'device_samples.json').write_text(json.dumps({'device':row,'package':PACKAGE,'sampling_interval_s':a.interval,'samples':rows,'cpu_gpu_timing':'not collected; use on-device profiler','note':'Battery changes are observational; controlled unplugged repeats needed for drain estimates.'},indent=2))
  print(json.dumps({'elapsed_s':item['elapsed_s'],'pss_kib':item.get('app_total_pss_kib'),'thermal_status':item.get('thermal_status')}),flush=True)
  remaining=duration-(time.monotonic()-start)
  if remaining<=0:break
  time.sleep(min(a.interval,remaining))
if __name__=='__main__':main()

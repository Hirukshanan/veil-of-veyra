"""Author five combat clips on the approved, seam-corrected quadruped rig.

All forward travel belongs to the future Godot movement controller. The death
roll is internal skeletal displacement; the exported actor object stays fixed.
"""
import bpy,sys,json,math
from pathlib import Path
from mathutils import Vector,Matrix,Quaternion
import numpy as np
out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
stage_a=out.parent/'stage_a'
rig=bpy.data.objects['DemonBoarRig'];low=bpy.data.objects['DemonBoar_LOD0']
scene=bpy.context.scene;scene.render.fps=30
legs=json.loads((out/'rig_definition.json').read_text())['legs']
specs=json.loads((stage_a/'animation_metrics.json').read_text())['clips']
for spec in specs.values():spec['loop']=True
specs.update({
 'charge_warning':{'frames':54,'seconds':1.8,'speed_mps':0.0,'loop':False},
 'charge_attack':{'frames':15,'seconds':.5,'speed_mps':3.12,'loop':True},
 'charge_recovery':{'frames':42,'seconds':1.4,'speed_mps':0.0,'initial_speed_mps':3.12,'stop_seconds':.5,'loop':False},
 'hit_reaction':{'frames':24,'seconds':.8,'speed_mps':0.0,'loop':False},
 'death':{'frames':84,'seconds':2.8,'speed_mps':0.0,'loop':False,'hold_final_pose':True}})
actions={name:bpy.data.actions[name] for name in ['idle','walk','run']}
inverse={pb.name:pb.bone.matrix_local.to_3x3().inverted() for pb in rig.pose.bones}
def smooth(a,b,t):
 x=max(0,min(1,(t-a)/(b-a)));return x*x*(3-2*x)
def move(name,delta):rig.pose.bones[name].location+=inverse[name]@Vector(delta)
def turn(name,axis,angle):
 pb=rig.pose.bones[name];pb.rotation_quaternion=Quaternion((inverse[name]@Vector(axis)).normalized(),angle)@pb.rotation_quaternion
def sample(action,frame):
 rig.animation_data.action=action
 whole=int(math.floor(frame));scene.frame_set(whole,subframe=frame-whole);bpy.context.view_layer.update()
 return {pb.name:pb.matrix_basis.copy() for pb in rig.pose.bones}
def set_pose(snapshot):
 for name,matrix in snapshot.items():rig.pose.bones[name].matrix_basis=matrix
def mix(a,b,t):
 result={}
 for name in a:
  la,qa,sa=a[name].decompose();lb,qb,sb=b[name].decompose()
  result[name]=Matrix.LocRotScale(la.lerp(lb,t),qa.slerp(qb,t),sa.lerp(sb,t))
 return result
neutral=sample(actions['idle'],1)
def sole(tag):
 leg=legs[tag];pb=rig.pose.bones[leg['hoof']]
 return pb.matrix@pb.bone.matrix_local.inverted()@Vector(leg['sole_rest'])
def mesh_points():
 evaluated=low.evaluated_get(bpy.context.evaluated_depsgraph_get());mesh=evaluated.to_mesh()
 points=np.empty(len(mesh.vertices)*3,dtype=np.float32);mesh.vertices.foreach_get('co',points)
 evaluated.to_mesh_clear();return points.reshape(-1,3)
def key_pose(action,frame,snapshot):
 rig.animation_data.action=action;scene.frame_set(frame);set_pose(snapshot)
def stop_travel(t):
 t=min(max(t,0),.5);return 3.12*(t-t*t)
metrics={};all_samples={};deform_names=[pb.name for pb in rig.pose.bones if pb.bone.use_deform]
for name in list(specs)[3:]:
 spec=specs[name];action=bpy.data.actions.new(name);action.use_fake_user=True;actions[name]=action
 previous={};root_previous=None
 measurements={'maximum_ik_error_m':0.0,'maximum_leg_length_relative_error':0.0,'minimum_mesh_z_m':1e9,'maximum_support_sole_error_m':0.0,'maximum_support_slip_m_per_frame':0.0,'maximum_floor_correction_change_m':0.0}
 clip_samples=[];first=None;final_hold=[]
 if name=='charge_recovery':
  start=sample(actions['charge_attack'],1);set_pose(start);bpy.context.view_layer.update();start_soles={tag:sole(tag).copy() for tag in legs}
  set_pose(neutral);bpy.context.view_layer.update();end_soles={tag:sole(tag).copy() for tag in legs}
 for index in range(spec['frames']+1):
  frame=index+1;t=index/30;p=index/spec['frames'];contacts={tag:True for tag in legs};travel=0.0
  snapshot=sample(actions['run'],1+18*(p%1)) if name=='charge_attack' else neutral
  if name=='charge_recovery':
   virtual_time=min(t,.5)-min(t,.5)**2
   snapshot=mix(sample(actions['charge_attack'],1+15*((virtual_time/.5)%1)),neutral,smooth(0,.75,t))
  key_pose(action,frame,snapshot)
  if name=='charge_warning':
   brace=smooth(0,.45,t)
   move('pelvis',(.012*math.sin(t*5)*brace,0,-.045*brace))
   turn('neck',(1,0,0),-.20*brace);turn('head',(1,0,0),-.14*brace)
   turn('chest',(1,0,0),-.015*brace)
   turn('head',(0,0,1),.025*math.sin(t*15)*math.sin(math.pi*p)**2)
   tension=.007*brace*math.sin(t*11);rig.pose.bones['chest'].scale=Vector((1+tension,)*3)
   # Lift, deliberately scrape backwards, then return the right hoof.
   y=z=pitch=0.0
   if .40<t<.65:
    u=smooth(.40,.65,t);y=.11*u;z=.065*math.sin(math.pi*u);pitch=.10*math.sin(math.pi*u)
   elif .65<=t<1.08:
    u=smooth(.65,1.08,t);y=.11-.24*u;z=.003;pitch=-.025*math.sin(math.pi*u)
   elif 1.08<=t<1.40:
    u=smooth(1.08,1.40,t);y=-.13*(1-u);z=.055*math.sin(math.pi*u)
   move(legs['front.R']['controller'],(0,y,z));turn(legs['front.R']['controller'],(1,0,0),pitch)
   contacts['front.R']=not (.40<t<1.40)
   turn('ear.L',(0,1,0),-.07*brace);turn('ear.R',(0,1,0),.07*brace)
   for number in range(1,4):turn('tail_%02d'%number,(0,0,1),.025*math.sin(t*7-number)*math.sin(math.pi*p)**2)
  elif name=='charge_attack':
   turn('neck',(1,0,0),-.14);turn('head',(1,0,0),-.10)
   turn('chest',(1,0,0),-.018);move('pelvis',(0,0,-.006))
   travel=t*3.12
   for tag in legs:
    offset=0 if tag in ['front.L','rear.R'] else .5
    contacts[tag]=((p-offset)%1)<=.42
  elif name=='charge_recovery':
   # Stance anchors remain fixed in the world while the preview decelerates.
   travel=stop_travel(t);distance=stop_travel(.5)
   bpy.context.view_layer.update();desired={}
   for tag,leg in legs.items():
    start_pos=start_soles[tag];end_pos=end_soles[tag]
    first_pair=tag in ['front.L','rear.R']
    release=.27 if first_pair else 0.0;land=.65 if first_pair else .355
    if first_pair and t<=release:world=start_pos.copy();contacts[tag]=True
    elif t<land:
     u=(t-release)/(land-release);s=smooth(0,1,u)
     world=start_pos.lerp(end_pos+Vector((0,distance,0)),s)
     world.z=max(0,start_pos.z)*(1-s)+.12*math.sin(math.pi*u)**2
     contacts[tag]=False
    else:world=end_pos+Vector((0,distance,0));contacts[tag]=True
    target=world-Vector((0,travel,0));desired[tag]=target
    move(leg['controller'],target-sole(tag))
   bpy.context.view_layer.update()
   # A second correction removes the small sole offset from rotating hooves.
   for tag,leg in legs.items():move(leg['controller'],desired[tag]-sole(tag))
   breath=.008*math.sin(t*13)*math.sin(math.pi*p)**2
   rig.pose.bones['chest'].scale=Vector((1+breath,)*3)
  elif name=='hit_reaction':
   impact=smooth(0,.10,t)*(1-smooth(.14,.8,t))
   overshoot=.12*math.sin((t-.16)*13)*math.exp(-max(0,t-.16)*8) if t>.16 else 0
   response=impact+overshoot*math.sin(math.pi*p)**2
   move('pelvis',(-.018*response,-.040*response,-.050*response))
   turn('chest',(1,0,0),.075*response);turn('spine_02',(0,1,0),.025*response)
   turn('neck',(1,0,0),.09*response);turn('head',(0,0,1),-.13*response)
   turn('ear.L',(0,1,0),.08*response);turn('ear.R',(0,1,0),-.05*response)
  else:
   collapse=smooth(.12,1.05,t);fall=smooth(.30,1.35,t)
   # Settle is exactly zero after 2.2 s, so the last 0.6 s holds still.
   settle=(.022*math.sin((t-1.35)*15)*math.exp(-(t-1.35)*5)*(1-smooth(1.85,2.2,t))) if t>1.35 else 0
   roll=math.radians(76)*fall+settle
   move('pelvis',(.015*math.sin(t*14)*(1-collapse),0,-.22*collapse))
   turn('chest',(1,0,0),.045*collapse);turn('neck',(1,0,0),-.07*collapse)
   turn('head',(0,0,1),.07*collapse);turn('jaw',(1,0,0),-.055*collapse)
   for tag,leg in legs.items():
    front=tag.startswith('front');side=-1 if tag.endswith('L') else 1
    move(leg['controller'],(side*.015*collapse,(-.14 if front else .08)*collapse,.20*collapse))
    turn(leg['controller'],(1,0,0),(-.30 if front else .32)*collapse)
   # Ground-side limbs fold under the body instead of propping it up.
   for end in ['front','rear']:
    move('CTRL_foot_'+end+'.R',(-.30*collapse,0,0))
    move('CTRL_pole_'+end+'.R',(-.50*collapse,0,0))
   for number in range(1,4):turn('tail_%02d'%number,(0,0,1),-.06*collapse)
   rotation=Quaternion((0,1,0),roll);pivot=Vector((0,0,.8))
   turn('root',(0,1,0),roll)
   shift=pivot-rotation@pivot+Vector((.30*fall,.035*collapse,0));move('root',shift)
   bpy.context.view_layer.update();minimum=float(mesh_points()[:,2].min())
   correction=.003-minimum;move('root',(0,0,correction))
   if root_previous is not None:measurements['maximum_floor_correction_change_m']=max(measurements['maximum_floor_correction_change_m'],abs(correction-root_previous))
   root_previous=correction;contacts={tag:False for tag in legs}
  bpy.context.view_layer.update()
  points=mesh_points();assert np.isfinite(points).all()
  measurements['minimum_mesh_z_m']=min(measurements['minimum_mesh_z_m'],float(points[:,2].min()))
  for tag,leg in legs.items():
   pb=rig.pose.bones[leg['hoof']];target=rig.pose.bones[leg['controller']].matrix.translation
   measurements['maximum_ik_error_m']=max(measurements['maximum_ik_error_m'],(pb.head-target).length)
   for bone in [leg['upper'],leg['lower']]:
    bp=rig.pose.bones[bone];measurements['maximum_leg_length_relative_error']=max(measurements['maximum_leg_length_relative_error'],abs((bp.tail-bp.head).length/bp.bone.length-1))
   current=sole(tag)+Vector((0,travel,0))
   if contacts[tag]:
    measurements['maximum_support_sole_error_m']=max(measurements['maximum_support_sole_error_m'],abs(current.z))
    if tag in previous and previous[tag][0]:measurements['maximum_support_slip_m_per_frame']=max(measurements['maximum_support_slip_m_per_frame'],(current-previous[tag][1]).length)
   previous[tag]=(contacts[tag],current)
  for pb in rig.pose.bones:
   for prop in ['location','rotation_quaternion','scale']:pb.keyframe_insert(prop,frame=frame,group=pb.name)
  matrices=np.array([rig.pose.bones[bone].matrix@rig.data.bones[bone].matrix_local.inverted() for bone in deform_names],dtype=np.float32)
  clip_samples.append(matrices)
  if index==0:first=matrices
  if t>=2.2 and name=='death':final_hold.append(matrices)
 measurements['endpoint_matrix_difference']=float(np.abs(matrices-first).max())
 if final_hold:
  measurements['final_hold_matrix_difference']=float(np.abs(np.stack(final_hold)-final_hold[0]).max())
  rest=np.empty(len(low.data.vertices)*3,dtype=np.float32);low.data.vertices.foreach_get('co',rest);rest=rest.reshape(-1,3)
  flank=(np.abs(rest[:,1])<.6)&(rest[:,2]>.6)
  measurements['final_flank_clearance_m']=float(points[flank,2].min()-points[:,2].min())
  assert measurements['final_flank_clearance_m']<.025,('corpse supported by a limb rather than its flank',measurements)
 for curve in action.fcurves:
  for key in curve.keyframe_points:key.interpolation='LINEAR'
 for key,value in {'loop':spec['loop'],'nominal_speed_mps':spec['speed_mps'],'root_motion':'actor_in_place'}.items():action[key]=value
 metrics[name]=measurements;all_samples[name]=np.stack(clip_samples)
 print('COMBAT_CLIP_METRICS '+name+' '+json.dumps(measurements),flush=True)
 assert measurements['maximum_ik_error_m']<.012,(name,'unreachable foot target',measurements)
 assert measurements['maximum_leg_length_relative_error']<.002,(name,'joint stretch',measurements)
 assert measurements['minimum_mesh_z_m']>-.001,(name,'floor penetration',measurements)
 if name!='death':
  assert measurements['maximum_support_sole_error_m']<.003
  assert measurements['maximum_support_slip_m_per_frame']<.004
 if spec['loop']:assert measurements['endpoint_matrix_difference']<1e-5
 if name=='death':assert measurements['final_hold_matrix_difference']<1e-5

# Independently preserve all original locomotion key samples, not just names.
reference=np.load(stage_a/'reference_deformation.npz');preserved={}
for name in ['idle','walk','run']:
 actual=[];rig.animation_data.action=actions[name]
 for frame in range(specs[name]['frames']+1):
  scene.frame_set(frame+1);bpy.context.view_layer.update()
  actual.append(np.array([rig.pose.bones[bone].matrix@rig.data.bones[bone].matrix_local.inverted() for bone in deform_names],dtype=np.float32))
 actual=np.stack(actual);difference=float(np.abs(actual-reference[name]).max());assert difference<1e-7
 preserved[name]=difference;all_samples[name]=actual
(out/'animation_metrics.json').write_text(json.dumps({'clips':specs,'measurements':metrics,'stage_a_deformation_difference':preserved,'notes':'Death displaces the skeleton internally but the actor object stays fixed. Recovery stance slip compensates the declared deceleration path. Warning scrape intentionally moves one supporting hoof.'},indent=2))
np.savez_compressed(out/'reference_deformation.npz',**all_samples)
(out/'reference_bones.json').write_text(json.dumps(deform_names))
rig.animation_data.action=actions['idle'];scene.frame_set(1);bpy.context.view_layer.update()
scene.frame_start=1;scene.frame_end=121
bpy.context.preferences.filepaths.save_version=0

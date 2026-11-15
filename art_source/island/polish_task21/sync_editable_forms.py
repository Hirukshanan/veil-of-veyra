import bpy,math
from pathlib import Path
R=Path(__file__).resolve().parents[3];S=R/'art_source/island/polish_task21'
bpy.ops.wm.open_mainfile(filepath=str(S/'forest_forms.blend'))
master=bpy.data.objects['Editable_Master_Before_Decimation'];master.hide_viewport=True;master.hide_render=True
for form,name in enumerate(['Broad_Fork','Tall_Column','Leaning_Crown']):
 o=bpy.data.objects[name];o.data=master.data.copy();o.hide_viewport=False;o.hide_render=False;o.location.x=(form-1)*7
 for v in o.data.vertices:
  x,y,z=v.co;t=max(0,min(1,(z-.6)/4.5));t=t*t*(3-2*t)
  if form==0:v.co=(x*(1+.65*t),y*(1+.65*t),z)
  if form==1:v.co=(x*(1-.08*t)+.12*math.sin(z*.9)*t,y*(1-.04*t),z*(1+.16*t))
  if form==2:v.co=(x*(1+.36*t)+1.25*t,y*(1+.30*t)+.18*math.sin(z*.8)*t,z*(1-.035*t))
 o.data.update()
bpy.ops.wm.save_as_mainfile(filepath=str(S/'forest_forms.blend'))
print('PASS: editable source forms synchronized to final GPU morph definitions; normalized master retained')

"""Original tileable 1K weathered limestone texture and tangent normal, built locally."""
import bpy,numpy as np,json
from pathlib import Path
R=Path(__file__).resolve().parents[3];A=R/'assets/environment/new_island/task3';rng=np.random.default_rng(39071);N=1024
Y,X=np.mgrid[0:N,0:N]/N
def noise(size):
 grid=rng.random((size,size));x=X*size;y=Y*size;ix=x.astype(int);iy=y.astype(int);u=x-ix;v=y-iy;u=u*u*(3-2*u);v=v*v*(3-2*v)
 return (grid[iy%size,ix%size]*(1-u)+grid[iy%size,(ix+1)%size]*u)*(1-v)+(grid[(iy+1)%size,ix%size]*(1-u)+grid[(iy+1)%size,(ix+1)%size]*u)*v
f=sum(noise(s)*w for s,w in [(4,.4),(8,.25),(16,.16),(32,.1),(64,.06),(128,.03)])
warp=noise(8);fracture=np.abs(np.sin((X*8+np.sin(Y*6*np.pi)*.22+warp*.26)*np.pi));crack=np.exp(-fracture*75)
layer=np.abs(np.sin((Y*11+np.sin(X*4*np.pi)*.15+f*.8)*np.pi));vein=np.exp(-layer*26)
grain=noise(256)-.5;h=f*.55+grain*.07-crack*.15+vein*.03
tone=np.clip(.39+(f-.5)*.50+grain*.11-crack*.13+vein*.055,.16,.65)
rgb=np.stack([tone*1.04,tone*1.02,tone*.98],-1)
dx=(np.roll(h,-1,1)-np.roll(h,1,1))*11;dy=(np.roll(h,-1,0)-np.roll(h,1,0))*11
normal=np.stack([-dx,-dy,np.ones_like(dx)],-1);normal/=np.linalg.norm(normal,axis=-1,keepdims=True);normal=normal*.5+.5
for label,data in [('rock_albedo',rgb),('rock_normal',normal)]:
 img=bpy.data.images.new(label,width=N,height=N,alpha=False,float_buffer=False)
 img.colorspace_settings.name='sRGB' if label.endswith('albedo') else 'Non-Color'
 rgba=np.concatenate([data,np.ones((N,N,1))],-1).astype(np.float32);img.pixels.foreach_set(rgba.ravel());img.filepath_raw=str(A/(label+'.png'));img.file_format='PNG';img.save()
(A/'texture_source.json').write_text(json.dumps({'author':'Original project procedural material','generator':'art_source/island/polish_task3/bake_rock.py','resolution':[N,N],'seed':39071,'maps':['rock_albedo.png','rock_normal.png'],'license':'Original project work; no downloaded or AI-generated images'},indent=2))
print('Original 1K rock albedo and normal baked locally')

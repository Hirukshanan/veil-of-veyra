"""Convert saved local deformation references into Godot coordinates."""
from pathlib import Path
import numpy as np, json, sys
out=Path(sys.argv[1]).resolve()
reference=np.load(out/'reference_deformation.npz')
bones=json.loads((out/'reference_bones.json').read_text())
c=np.array([[1,0,0,0],[0,0,1,0],[0,-1,0,0],[0,0,0,1]],dtype=float)
metrics=json.loads((out/'animation_metrics.json').read_text())
data={'bones':bones,'fps':30,'clips':{name:{'spec':metrics['clips'][name],'deformation':(c@reference[name]@np.linalg.inv(c)).tolist()} for name in reference.files}}
(out/'reference_godot.json').write_text(json.dumps(data,separators=(',',':')),encoding='utf-8')
print('GODOT_REFERENCE_READY '+str(len(bones))+' deformation bones')

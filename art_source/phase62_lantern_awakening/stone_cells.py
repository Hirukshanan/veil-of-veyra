from pathlib import Path
import json,random
R=Path('C:/Users/Dark/Desktop/Projects/veil-of-veyra')
rng=random.Random(6202)
sites=[(-4.7+(x+.5)*1.88+rng.uniform(-.4,.4),(y+.5)*1.375+rng.uniform(-.3,.3)) for y in range(4) for x in range(5)]
cells=[]
for x,y in sites:
    poly=[(-4.7,0),(4.7,0),(4.7,5.5),(-4.7,5.5)]
    for ox,oy in sites:
        if (x,y)==(ox,oy):continue
        nx,ny=ox-x,oy-y
        bound=(ox*ox+oy*oy-x*x-y*y)/2
        clipped=[]
        for a,b in zip(poly,poly[1:]+poly[:1]):
            da=a[0]*nx+a[1]*ny-bound;db=b[0]*nx+b[1]*ny-bound
            if da<=0:clipped.append(a)
            if (da<=0)!=(db<=0):
                t=da/(da-db);clipped.append((a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t))
        poly=clipped
        if not poly:break
    cells.append(poly)
D=R/'assets/environment/lantern_awakening';D.mkdir(parents=True,exist_ok=True)
(D/'seal_cells.json').write_text(json.dumps(cells))
print('20 fitted original fracture cells generated')

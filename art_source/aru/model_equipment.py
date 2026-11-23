"""Model Aru's equipment in metres. Coordinates below match Godot's axes."""
import bpy
import math
import os
import sys
from mathutils import Vector

output, blend_path = sys.argv[sys.argv.index("--") + 1:]
os.makedirs(output, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

def material(name, rgb, metal, roughness):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.diffuse_color = (*rgb, 1)
    node = mat.node_tree.nodes.get("Principled BSDF")
    node.inputs["Base Color"].default_value = mat.diffuse_color
    node.inputs["Metallic"].default_value = metal
    node.inputs["Roughness"].default_value = roughness
    return mat

iron = material("Tempered blue iron", (.095,.134,.161), .78, .34)
edge = material("Honed steel", (.43,.49,.50), .89, .27)
bronze = material("Aged bronze inlay", (.43,.24,.087), .73, .34)
hide = material("Oxblood leather", (.058,.018,.014), 0, .83)
wood = material("Charred narrow grain oak", (.050,.030,.024), 0, .92)
black = material("Recessed engraving", (.027,.021,.022), .24, .55)
red = material("Garnet", (.39,.033,.020), .32, .29)
ember = material("Banked ember inlay", (.41,.070,.020), .42, .38)
emission = ember.node_tree.nodes.get("Principled BSDF").inputs
emission["Emission Color"].default_value = (.46,.031,.005,1)
emission["Emission Strength"].default_value = .19
rim = material("Blackened forged iron", (.056,.076,.087), .69, .40)
oak = material("Oil-darkened oak staves", (.076,.043,.026), 0, .87)
groups = {}

def coords(v):
    x,y,z=v
    return (x,-z,y)

def mesh(group, name, pts, faces, materials, indices=None):
    data = bpy.data.meshes.new(name)
    data.from_pydata([coords(v) for v in pts], [], faces)
    data.update()
    obj = bpy.data.objects.new(name,data)
    bpy.context.collection.objects.link(obj)
    groups.setdefault(group,[]).append(obj)
    for mat in materials:
        data.materials.append(mat)
    if indices is not None:
        for poly, mat_index in zip(data.polygons,indices):
            poly.material_index=mat_index
    bpy.context.view_layer.objects.active=obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.uv.smart_project(island_margin=.035)
    bpy.ops.object.mode_set(mode='OBJECT')
    obj.select_set(False)
    return obj

def line(group, name, points, width, mat, depth=.005):
    pts=[]
    for i,(x,y,z) in enumerate(points):
        a=Vector(points[max(i-1,0)])
        b=Vector(points[min(i+1,len(points)-1)])
        tangent=(b-a).normalized()
        perp=Vector((-tangent.y,tangent.x,0)).normalized()*width/(2 if i in (0,len(points)-1) else 1)
        c=Vector((x,y,z))
        pts.extend([c+perp,c-perp,c+perp-Vector((0,0,depth)),c-perp-Vector((0,0,depth))])
    faces=[]
    for i in range(0,len(pts)-4,4):
        faces.extend([(i,i+4,i+5,i+1),(i,i+2,i+6,i+4),(i+1,i+5,i+7,i+3),(i+2,i+3,i+7,i+6)])
    faces.extend([(0,1,3,2),tuple(range(len(pts)-4,len(pts)))])
    mesh(group,name,pts,faces,[mat])

def bezel(group, name, center, radius, height, mat, count=10):
    x,y,z=center
    pts=[(x,y,z+height)]
    for i in range(count):
        a=2*math.pi*i/count
        pts.append((x+radius*math.cos(a),y+radius*math.sin(a),z))
    return mesh(group,name,pts,[(0,1+i,1+(i+1)%count) for i in range(count)]+[tuple(range(1,count+1))],[mat])

def panel(group,name,outline,crown,body,trim,thickness=.027,domed=False):
    n=len(outline)
    x,y,z=crown
    pts=[crown]
    rings = [(.46,0),(.72,0),(.86,.003),(.94,.009),(1.0,0)] if domed else [(.86,.006),(.94,.012),(1.0,0)]
    for t,lift in rings:
        pts += [(x+(px-x)*t,y+(py-y)*t,z+(pz-z)*t*t+lift if domed else pz+lift) for px,py,pz in outline]
    pts += [(px,py,pz-thickness) for px,py,pz in outline]
    faces=[]
    mats=[]
    for i in range(n):
        j=(i+1)%n
        faces.append((0,1+i,1+j))
        mats.append(0)
    for k in range(len(rings)):
        a=1+k*n
        b=a+n
        for i in range(n):
            j=(i+1)%n
            faces.append((a+i,b+i,b+j,a+j))
            mats.append(1 if k in (len(rings)-3,len(rings)-2) else 0)
    faces.append(tuple(range(1+len(rings)*n,1+(len(rings)+1)*n)))
    mats.append(0)
    return mesh(group,name,pts,faces,[body,trim],mats)

def profile(group,name,levels,mats,metal=True,n=8):
    pts=[]
    for y,x,w,d in levels:
        for i in range(n):
            a=2*math.pi*i/n
            pts.append((x+math.cos(a)*w,y,math.sin(a)*d))
    faces=[]
    ids=[]
    for k in range(len(levels)-1):
        for i in range(n):
            j=(i+1)%n
            faces.append((k*n+i,k*n+j,(k+1)*n+j,(k+1)*n+i))
            ids.append(int(metal and len(mats) > 1 and i%4 in (0,3)))
    faces += [tuple(range(n)),tuple(range(len(pts)-n,len(pts)))]
    mesh(group,name,pts,faces,mats,ids+[0,0])

s="ember_sword"
# The fuller is part of the blade cross-section, with narrow cutting bevels.
stations = [(.008,-.004,.039,.019),(.076,.002,.055,.019),(.145,.006,.061,.017),
    (.246,.019,.055,.016),(.362,.037,.050,.014),(.492,.061,.044,.013),(.610,.091,.036,.011),
    (.711,.119,.027,.008),(.787,.136,.015,.005),(.846,.143,.0008,.0008)]
cross_section = [(-1,0),(-.78,.70),(-.36,1),(-.20,.56),(.20,.56),(.36,1),(.78,.70),(1,0),
                 (.78,-.70),(.36,-1),(.20,-.56),(-.20,-.56),(-.36,-1),(-.78,-.70)]
points = [(x+u*w,y,v*d) for y,x,w,d in stations for u,v in cross_section]
n = len(cross_section)
faces = [tuple(range(n)),tuple(range(len(points)-n,len(points)))]
indices = [0,0]
for i in range(len(stations)-1):
    for j in range(n):
        k=(j+1)%n
        faces.append((i*n+j,i*n+k,(i+1)*n+k,(i+1)*n+j))
        indices.append(1 if j in (0,1,5,6,7,8,12,13) else 2 if j in (3,10) else 0)
mesh(s,"Double fuller and swept cutting bevels",points,faces,[iron,edge,rim],indices)
for sign in (-1,1):
    for i in range(5):
        y,x,w,d=stations[i+2]
        line(s,"Etched ember fleck",[(x-.010,y-.012,sign*.011),(x-.003,y+.007,sign*.011),
             (x+.009,y+.017,sign*.011)],.0034 if i>1 else .0055,ember,.002)
panel(s,"Winged crossguard",[(-.163,-.013,.027),(-.108,-.007,.03),(-.056,-.049,.028),(.049,-.045,.028),
    (.093,.017,.028),(.144,.041,.022),(.114,-.033,.022),(.066,-.076,.025),(-.078,-.077,.025),(-.125,-.055,.022)],(0,-.039,.048),iron,bronze)
profile(s,"Leather hilt", [(-.224,0,.027,.027),(-.194,0,.028,.025),(-.105,0,.024,.025),(-.053,0,.029,.027)],[hide])
for y in [-.207,-.18,-.154,-.128,-.102,-.075]:
    profile(s,"Hilt binding",[(y-.004,0,.028,.027),(y+.001,0,.030,.029),(y+.006,0,.026,.026)],[bronze],False)
profile(s,"Faceted pommel",[(-.282,0,.015,.016),(-.255,0,.042,.029),(-.221,0,.028,.025)],[bronze,iron])
bezel(s,"Guard garnet",(0,-.045,.047),.025,.016,red,8)

h="ward_shield"
outline=[(-.228,.145,.030),(-.242,.204,.032),(-.229,.271,.034),(-.194,.322,.035),
    (-.133,.340,.035),(-.078,.332,.035),(-.038,.350,.036),(0,.390,.038),(.038,.350,.036),
    (.078,.332,.035),(.133,.340,.035),(.194,.322,.035),(.229,.271,.034),(.242,.204,.032),
    (.228,.145,.030),(.220,.039,.034),(.192,-.105,.038),(.153,-.214,.042),(.082,-.301,.047),
    (0,-.374,.050),(-.082,-.301,.047),(-.153,-.214,.042),(-.192,-.105,.038),(-.220,.039,.034)]
shield_board = panel(h,"Crowned stave shield and continuous steel edging",outline,(0,.045,.121),oak,edge,.055,True)

def shield_face(x,y):
    hit, point, _, _ = shield_board.ray_cast(Vector((x,-.5,y)),Vector((0,1,0)))
    return -point.y if hit else .043

def stamp(name,path,width,mat):
    # Project the inlay at close intervals so it follows the domed staves.
    samples=[]
    lift=.0037 if mat == bronze else .0021 if mat == black else .007
    for a,b in zip(path,path[1:]):
        steps=max(1,math.ceil(math.dist(a,b)/.038))
        for i in range(steps):
            t=i/steps
            x=a[0]+(b[0]-a[0])*t
            y=a[1]+(b[1]-a[1])*t
            samples.append((x,y,shield_face(x,y)+lift))
    x,y=path[-1]
    samples.append((x,y,shield_face(x,y)+lift))
    line(h,name,samples,width,mat,.006)
for j,x in enumerate([-.168,-.118,-.068,.065,.114,.164]):
    stamp("Hand-cut stave seam",[(x,.265-j*.008),(x*.96,.15),(x,.02),(x*.76,-.117),(x*.42,-.226)],.004,black)
for sign in (-1,1):
    for y in (.19,-.098):
        stamp("Tapered forged reinforcement",[(0,y-.029),(sign*.07,y-.012),(sign*.14,y+.013),(sign*.196,y+.038)],.017,rim)
    stamp("Thorn vine engraved in bronze",[(0,-.263),(sign*.066,-.174),(sign*.082,-.083),
        (sign*.055,.004),(sign*.115,.106),(sign*.108,.171),(sign*.151,.235)],.0063,bronze)
    for x,y in [(.070,-.158),(.076,-.048),(.098,.073),(.111,.147)]:
        stamp("Thorn branch",[(sign*x,y),(sign*(x+.036),y+.025),(sign*(x+.053),y+.017)],.0048,bronze)
    for i in (1,3,5,9,12,15,18,21):
        if sign == -1:
            continue
        x,y,z=outline[i]
        bezel(h,"Hammered rim rivet",(x*.924,.045+(y-.045)*.924,z+.018),.010,.006,bronze,8)
    line(h,"Leather forearm strap",[(sign*.102,-.145,-.008),(sign*.102,-.100,-.044),
        (sign*.102,.087,-.044),(sign*.102,.137,-.008)],.026,hide)
bezel(h,"Flanged central boss",(0,.071,.125),.061,.034,edge,16)
bezel(h,"Quenched bronze boss ring",(0,.071,.156),.038,.010,bronze,12)
bezel(h,"Bloodstone boss rivet",(0,.071,.166),.022,.010,red,10)

g="ranger_chest"
panel(g,"Folded breastplate",[(-.191,1.414,.104),(-.128,1.478,.133),(-.077,1.473,.147),(0,1.415,.16),
    (.077,1.473,.147),(.128,1.478,.133),(.191,1.414,.104),(.17,1.30,.126),(.12,1.22,.139),
    (0,1.185,.156),(-.12,1.22,.139),(-.17,1.30,.126)],(0,1.35,.216),iron,bronze)
for sign in (-1,1):
    line(g,"Chest ridge",[(0,1.233,.184),(sign*.073,1.276,.195),(sign*.127,1.351,.178),(sign*.145,1.402,.141)],.009,edge)
    line(g,"Drop seal engraving",[(0,1.29,.215),(sign*.033,1.334,.215),(sign*.039,1.369,.213),(0,1.397,.194)],.0045,bronze,.003)
    bezel(g,"Harness pin",(sign*.115,1.42,.155),.013,.009,bronze)
    for j in range(3):
        y=1.303+j*.027
        line(g,"Feathered seal incision",[(sign*.026,y,.215),(sign*.061,y+.009,.196),
             (sign*.091,y+.033,.181)],.0043,bronze,.004)
bezel(g,"Chest inset",(0,1.347,.219),.012,.008,red,8)
panel(g,"Overlapping lower chest lame",[(-.133,1.271,.133),(-.082,1.241,.154),(0,1.195,.170),
    (.082,1.241,.154),(.133,1.271,.133),(.107,1.215,.127),(0,1.163,.140),(-.107,1.215,.127)],
    (0,1.218,.185),rim,edge,.015)

for side,sign in [("l",1),("r",-1)]:
    g="ranger_shoulder_"+side
    # Riveted lames wrap over the Ranger shoulder and stop before the elbow.
    for i in range(3):
        start=.17 + i*.049
        end=start+.067
        points=[]
        radius=(.133 if side=="l" else .116)-.012*i
        for x,r in [(start,radius*.95),(start+.019,radius),(end,radius*.89)]:
            for j in range(10):
                angle=-.95+j*.35
                points.append((sign*x,1.453+math.cos(angle)*r,-.052+math.sin(angle)*r))
        count=len(points)
        points += [(x,1.453+(y-1.453)*.89,-.052+(z+.052)*.89) for x,y,z in points]
        faces=[]
        indices=[]
        for row in (0,1):
            for j in range(9):
                a=row*10+j
                faces.append((a,a+1,a+11,a+10))
                faces.append((count+a,count+a+10,count+a+11,count+a+1))
                indices.extend((1 if row==0 else 0,0))
        perimeter=list(range(10))+[19]+list(range(29,19,-1))+[10]
        for j,a in enumerate(perimeter):
            b=perimeter[(j+1)%len(perimeter)]
            faces.append((a,b,count+b,count+a))
            indices.append(1)
        mesh(g,"Rolled and overlapping shoulder lame",points,faces,[iron,bronze if i==0 else edge],indices)
        bezel(g,"Peened shoulder rivet",(sign*(start+.024),1.492-i*.006,.057-i*.011),.009,.005,bronze,8)
    g="ranger_bracer_"+side
    panel(g,"Tapered forearm plate",[(sign*x,y,z) for x,y,z in [
        (.498,1.504,-.025),(.545,1.516,.010),(.645,1.490,.006),(.672,1.455,-.013),
        (.641,1.417,-.018),(.534,1.421,-.021),(.493,1.457,-.028)]],
        (sign*.573,1.47,.039),iron,bronze)
    line(g,"Bracer crest",[(sign*.528,1.46,.014),(sign*.572,1.48,.045),(sign*.631,1.465,.027)],.008,edge)
    for offset in (-.032,.027):
        line(g,"Raised bracer edge",[(sign*.508,1.461+offset,.003),(sign*.56,1.471+offset,.035),
             (sign*.63,1.458+offset,.026),(sign*.656,1.451+offset,.011)],.006,bronze,.003)
    for x in (.532,.638):
        bezel(g,"Bracer pin",(sign*x,1.457,.030),.011,.008,bronze,8)

# Join each independently attachable piece and then export one GLB per attachment.
bpy.ops.object.select_all(action='DESELECT')
for name,objects in groups.items():
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.object.join()
    obj=bpy.context.object
    obj.name=name
    obj.data.name=name
    bpy.ops.export_scene.gltf(filepath=os.path.join(output,name+".glb"),export_format="GLB",
        use_selection=True,export_animations=False,export_apply=True)
    print("EQUIPMENT",name,sum(len(p.vertices)-2 for p in obj.data.polygons))
    obj.select_set(False)
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=blend_path)

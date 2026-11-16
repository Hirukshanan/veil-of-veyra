from pathlib import Path
import array,hashlib,json,math,random,wave
W=Path(__file__).parent
R=Path('C:/Users/Dark/Desktop/Projects/veil-of-veyra')
D=R/'assets/audio/lantern_awakening';D.mkdir(parents=True,exist_ok=True)
RATE=24000
rng=random.Random(6201)
def save(name,samples):
    peak=max(abs(x) for x in samples) or 1
    samples=[x*.72/peak for x in samples]
    pcm=array.array('h',(int(max(-1,min(1,x))*32767) for x in samples))
    with wave.open(str(D/name),'wb') as f:f.setparams((1,2,RATE,0,'NONE','not compressed'));f.writeframes(pcm.tobytes())
    return {'file':name,'duration_s':len(samples)/RATE,'peak':.72,'sha256':hashlib.sha256((D/name).read_bytes()).hexdigest()}
rows=[]
for name,length in [('stone.wav',4.2),('fracture.wav',3.2),('breathing.wav',4.0),('tension.wav',32.0)]:
    samples=[];brown=0.0
    for i in range(int(length*RATE)):
        t=i/RATE;brown=.985*brown+.015*rng.uniform(-1,1)
        envelope=min(1,t/.12)*min(1,(length-t)/.4)
        if name=='stone.wav':v=brown*3+math.sin(2*math.pi*43*t)*.14*(.7+.3*math.sin(t*18))
        elif name=='fracture.wav':
            impact=sum(math.exp(-max(0,t-k*.19)*14) if t>=k*.19 else 0 for k in range(9))
            v=(brown*3+rng.uniform(-.08,.08)+math.sin(t*2*math.pi*58)*.2)*impact
        elif name=='breathing.wav':v=(brown*4+math.sin(t*2*math.pi*32)*.08)*(math.sin(t/4*math.pi)**2)
        else:
            build=min(1,t/14)
            chord=[55,65.406,82.407,110,130.813,164.814]
            v=sum(math.sin(2*math.pi*f*t+.3*math.sin(t*.5+j))*(1+.2*math.sin(t*.8+j)) for j,f in enumerate(chord))*.05
            v+=math.sin(2*math.pi*(220+24*build)*t)*.025*build+brown*.3
            envelope*=.15+.85*build
        samples.append(v*envelope)
    rows.append(save(name,samples))
# A CC0 vocal from the existing approved audio, layered into a distant creature roar.
source=R/'assets/audio/demon_boar/warning.wav'
with wave.open(str(source),'rb') as f:
    rate=f.getframerate();raw=array.array('h',f.readframes(f.getnframes()))
samples=[];brown=0
for i in range(RATE*6):
    t=i/RATE;brown=.99*brown+.01*rng.uniform(-1,1)
    phase=t*rate*.48
    idx=int(phase)%len(raw)
    vocal=raw[idx]/32768
    envelope=min(1,t/.35)*min(1,(6-t)/1.8)
    samples.append((vocal*.7+brown*2+math.sin(2*math.pi*(49-2*t)*t)*.12)*envelope)
rows.append(save('dragon_roar.wav',samples))
(D/'LICENSE.md').write_text('''# Lantern Awakening audio

Stone movement, fractures, breathing and tension music are original deterministic procedural compositions created for Veil of Vera. Their generator is included in the Phase 6.2 source evidence. Commercial use within the project is permitted by the owner.

Dragon roar layers a pitched copy of the existing CC0 warning vocal with original synthesis. Source vocal is fvcalderan, Boar, https://opengameart.org/content/boar-0, CC0-1.0. Existing provenance is retained in assets/audio/demon_boar/README.md and audio_manifest.json. This uses a local existing asset and does not upload project material.

All outputs are mono 24 kHz / 16-bit PCM WAV, peak limited to 0.72 before in-game attenuation. Godot cave reverb is applied at runtime. No external music, paid asset or voice service is used.
''')
(D/'manifest.json').write_text(json.dumps({'sample_rate':RATE,'files':rows,'roar_source_sha256':hashlib.sha256(source.read_bytes()).hexdigest()},indent=2))
print('Five bounded original/CC0-derived cave audio files generated')

from pathlib import Path
root=Path(__file__).resolve().parents[2]
assets=(root/'assets/environment/new_island').resolve()
for sidecar in assets.glob('*_albedo.jpg.import'):
    if not sidecar.name[0].isupper():
        image=sidecar.with_suffix('')
        assert image.resolve().parent==assets
        if image.exists():image.unlink()
        sidecar.unlink()
    else:
        sidecar.write_text(sidecar.read_text().replace('compress/mode=0','compress/mode=2').replace('mipmaps/generate=false','mipmaps/generate=true'))

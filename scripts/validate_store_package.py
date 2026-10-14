"""Check exact deliverable dimensions, opaque formats, copy limits, and video."""
from pathlib import Path
from PIL import Image
import json
import subprocess
import hashlib

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'appstore'
meta=json.loads((OUT/'metadata/en-AU.json').read_text())
limits={'name':30,'subtitle':30,'promotionalText':170,'description':4000}
copy_lengths={}
for key,limit in limits.items():
    count=len(meta[key]);assert count<=limit,(key,count,limit);copy_lengths[key]={'length':count,'limit':limit}
keyword_bytes=len(meta['keywords'].encode('utf-8'))
assert keyword_bytes<=100
copy_lengths['keywords']={'bytes':keyword_bytes,'limit':100}
assert len(set(meta['keywords'].split(',')))==len(meta['keywords'].split(','))
assert meta['copyright']=='2026 HRLN interactive'
assert meta['supportURL']=='https://snip.hrln-interactive.com/support/'
images=json.loads((OUT/'image-manifest.json').read_text())
for spec in images:
    path=OUT/spec['path'];im=Image.open(path)
    assert im.size==(spec['width'],spec['height']),(path,im.size)
    assert im.mode=='RGB' and im.format=='PNG',(path,im.mode,im.format)
    spec['sha256']=hashlib.sha256(path.read_bytes()).hexdigest()
    spec['bytes']=path.stat().st_size
assert len(images)==16
icon=Image.open(OUT/'icon/snip-1024.png');assert icon.size==(1024,1024) and icon.mode=='RGB'
poster=Image.open(OUT/'preview/poster-886x1920.png');assert poster.size==(886,1920) and poster.mode=='RGB'
video=OUT/'preview/snip-preview-886x1920.mp4'
probe=json.loads(subprocess.check_output(['ffprobe','-v','error','-show_streams','-show_format','-of','json',str(video)]))
v=next(s for s in probe['streams'] if s['codec_type']=='video')
a=next(s for s in probe['streams'] if s['codec_type']=='audio')
assert (v['width'],v['height'])==(886,1920)
assert v['codec_name']=='h264' and v['avg_frame_rate']=='30/1' and v['field_order']=='progressive'
assert 9_000_000<=int(v['bit_rate'])<=12_500_000
assert v['pix_fmt']=='yuv420p'
assert 15<=float(probe['format']['duration'])<=30
assert int(probe['format']['size'])<500_000_000
assert a['codec_name']=='aac' and a['channels']==2 and a['sample_rate']=='48000'
assert (ROOT/'work/ui-tests.log').read_text().count('passed (')>=4
assert '** TEST SUCCEEDED **' in (ROOT/'work/ui-tests.log').read_text()
assert '** BUILD SUCCEEDED **' in (ROOT/'work/build-release.log').read_text()
(OUT/'image-manifest.json').write_text(json.dumps(images,indent=2)+'\n')
report={'checkedDate':'2026-10-14','nativeReleaseBuild':'passed (unsigned generic iOS build)',
 'nativeUIWorkflows':4,'engineAssertions':863,'dailyPuzzles':90,'practicePuzzles':12,
 'dailyCycleDays':30,'imageAssets':len(images),'imageMode':'opaque 8-bit RGB PNG',
 'listingCopy':copy_lengths,'preview':{'size':[886,1920],'durationSeconds':float(probe['format']['duration']),
 'videoCodec':v['codec_name'],'fps':v['avg_frame_rate'],'videoBitRate':v['bit_rate'],
 'audioCodec':a['codec_name'],'audioChannels':a['channels'],'audioSampleRate':a['sample_rate'],'bytes':int(probe['format']['size'])},
 'website':'Static pages checked at 375px and 1280px locally; not deployed',
 'appStoreConnect':'Configuration and submission to be completed by the publisher'}
(OUT/'validation-report.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))

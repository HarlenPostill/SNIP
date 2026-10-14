"""Record real simulator interactions; export an Apple-sized portrait preview."""
from pathlib import Path
import os
import signal
import subprocess
import json
import sys

ROOT=Path(__file__).resolve().parents[1]
DEVICE='E70E5A65-132F-42E9-8B5A-ABA522AD8A61'
raw=ROOT/'work/native-preview.mov'
export_only='--export-only' in sys.argv
if raw.exists() and not export_only:raw.unlink()
env=os.environ.copy();env['TEST_RUNNER_SNIP_RECORD_PREVIEW']='1'
cmd=['xcodebuild','-project','sol-word-test.xcodeproj','-scheme','SNIP','-configuration','Debug','-sdk','iphonesimulator','-destination',f'platform=iOS Simulator,id={DEVICE}','-derivedDataPath','work/build','-parallel-testing-enabled','NO','-only-testing:SNIPUITests/SNIPUITests/testRecordPreview','CODE_SIGNING_ALLOWED=NO','test']
recorder=None
code=0
if not export_only:
    process=subprocess.Popen(cmd,cwd=ROOT,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,bufsize=1)
    with (ROOT/'work/recording-test.log').open('w') as log:
        for line in process.stdout:
            log.write(line);log.flush()
            if 'SNIP_VIDEO_BEGIN' in line and recorder is None:
                recorder=subprocess.Popen(['xcrun','simctl','io',DEVICE,'recordVideo','--codec=h264',str(raw)],stdout=subprocess.DEVNULL,stderr=(ROOT/'work/recorder.log').open('w'))
                print('Recording real gameplay',flush=True)
            if 'SNIP_VIDEO_END' in line and recorder is not None:
                recorder.send_signal(signal.SIGINT);recorder.wait(timeout=15)
                print('Gameplay recording complete',flush=True)
        code=process.wait()
if recorder is not None and recorder.poll() is None:recorder.send_signal(signal.SIGINT);recorder.wait(timeout=15)
assert code==0, 'Recording test failed; inspect work/recording-test.log'
assert raw.exists(), 'Recording test was skipped or start marker missing'
probe=json.loads(subprocess.check_output(['ffprobe','-v','error','-show_format','-of','json',str(raw)]))
source_duration=float(probe['format']['duration'])
assert source_duration>=8,source_duration
duration=max(18,min(29.5,source_duration))
out=ROOT/'appstore/preview';out.mkdir(parents=True,exist_ok=True)
target=out/'snip-preview-886x1920.mp4'
video_filter=f'scale=886:1920:force_original_aspect_ratio=decrease,pad=886:1920:(ow-iw)/2:(oh-ih)/2:color=0xf6f1e6,tpad=stop_mode=clone:stop_duration={max(0,duration-source_duration)+0.5}'
subprocess.run(['ffmpeg','-y','-v','error','-i',str(raw),'-f','lavfi','-i','anullsrc=r=48000:cl=stereo','-t',str(duration),'-vf',video_filter,'-r','30','-c:v','libx264','-preset','medium','-profile:v','high','-level:v','4.0','-b:v','10M','-minrate','10M','-maxrate','10M','-bufsize','20M','-x264-params','nal-hrd=cbr:force-cfr=1','-pix_fmt','yuv420p','-c:a','aac','-b:a','256k','-ar','48000','-ac','2','-movflags','+faststart',str(target)],check=True)
subprocess.run(['ffmpeg','-y','-v','error','-ss','5','-i',str(target),'-frames:v','1',str(out/'poster-886x1920.png')],check=True)
print('Exported portrait preview:',round(duration,2),'seconds at 886×1920, H.264, 30 fps',flush=True)

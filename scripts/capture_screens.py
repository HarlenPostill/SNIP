"""Capture the real native app's reproducible practice screens."""
from pathlib import Path
from PIL import Image
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
DEVICE = 'E70E5A65-132F-42E9-8B5A-ABA522AD8A61'
BUNDLE = 'com.hrln-interactive.snip'
APP = ROOT / 'work/build/Build/Products/Debug-iphonesimulator/sol-word-test.app'
def run(*args, check=True): return subprocess.run(args, check=check, capture_output=True, text=True)
run('xcrun', 'simctl', 'install', DEVICE, str(APP))
run('xcrun', 'simctl', 'status_bar', DEVICE, 'override', '--time', '9:41', '--dataNetwork', 'wifi', '--wifiMode', 'active', '--wifiBars', '3', '--cellularMode', 'active', '--cellularBars', '4', '--batteryState', 'charged', '--batteryLevel', '100')
folder = ROOT / 'appstore/raw'
folder.mkdir(parents=True, exist_ok=True)
for screen in ['home', 'game', 'selected', 'solved', 'receipt', 'practice', 'stats']:
    run('xcrun', 'simctl', 'terminate', DEVICE, BUNDLE, check=False)
    run('xcrun', 'simctl', 'launch', DEVICE, BUNDLE, '-ui-testing', '-reset-state', '-capture-screen', screen)
    time.sleep(2)
    path = folder / f'{screen}.png'
    run('xcrun', 'simctl', 'io', DEVICE, 'screenshot', str(path))
    image = Image.open(path).convert('RGB')
    assert image.size == (1206,2622), image.size
    image.save(path)
    print('Captured', screen, image.size, flush=True)
run('xcrun', 'simctl', 'terminate', DEVICE, BUNDLE, check=False)
run('xcrun', 'simctl', 'launch', DEVICE, BUNDLE, '-ui-testing', '-reset-state', '-capture-screen', 'home')

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json

ROOT = Path(__file__).resolve().parents[1]
image = Image.new('RGB', (1024, 1024), '#c43b21')
draw = ImageDraw.Draw(image)
font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Georgia Italic.ttf', 900)
bbox = draw.textbbox((0,0), 's', font=font)
x = (1024 - (bbox[2]-bbox[0]))/2 - bbox[0] - 32
y = (1024 - (bbox[3]-bbox[1]))/2 - bbox[1] - 18
draw.text((x,y), 's', font=font, fill='#f6f1e6')
draw.polygon([(180,605),(820,456),(820,480),(180,629)], fill='#c43b21')
draw.ellipse((728,728,784,784), fill='#f6f1e6')
folder = ROOT / 'sol-word-test/Assets.xcassets/AppIcon.appiconset'
folder.mkdir(parents=True, exist_ok=True)
image.save(folder/'AppIcon.png')
(folder/'Contents.json').write_text(json.dumps({'images':[{'filename':'AppIcon.png','idiom':'universal','platform':'ios','size':'1024x1024'}],'info':{'author':'xcode','version':1}}, indent=2)+'\n')
out = ROOT / 'appstore/icon'
out.mkdir(parents=True, exist_ok=True)
image.save(out/'snip-1024.png')
print('Exported opaque 1024×1024 app icon')

"""Render original typographic campaign layouts around genuine native captures."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import json
import math

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'appstore'
PAPER = '#f6f1e6'
INK = '#292b24'
RED = '#c43b21'
QUIET = '#65675b'
FONTS = Path('/System/Library/Fonts/Supplemental')
SERIF = FONTS / 'Georgia Italic.ttf'
SANS = Path('/System/Library/Fonts/Helvetica.ttc')
MONO = FONTS / 'Courier New Bold.ttf'

def font(size, face=SERIF): return ImageFont.truetype(str(face), max(10,int(size)))
def text(image, xy, content, size, fill=INK, face=SERIF):
    draw=ImageDraw.Draw(image)
    draw.text(tuple(map(int,xy)), content, font=font(size,face), fill=fill, anchor='lt')
def lines(image, xy, content, size, fill=INK, width=None, face=SERIF, leading=1.08):
    if width:
        while max(ImageDraw.Draw(image).textlength(line,font=font(size,face)) for line in content.split('\n'))>width: size-=1
    for i,line in enumerate(content.split('\n')): text(image,(xy[0],xy[1]+i*size*leading),line,size,fill,face)
    return len(content.split('\n'))*size*leading
def dashed(image,a,b,fill=QUIET,width=2,dash=10,gap=12):
    draw=ImageDraw.Draw(image);dx=b[0]-a[0];dy=b[1]-a[1];dist=math.hypot(dx,dy)
    for start in range(0,int(dist),int(dash+gap)):
        end=min(dist,start+dash)
        draw.line([(a[0]+dx*start/dist,a[1]+dy*start/dist),(a[0]+dx*end/dist,a[1]+dy*end/dist)],fill=fill,width=width)
def paste_shadow(image,layer,xy,blur=22,opacity=45):
    layer=layer.convert('RGBA');shadow=Image.new('RGBA',image.size)
    mask=layer.getchannel('A').point(lambda v:int(v*opacity/255))
    shadow.paste((10,10,8,255),(int(xy[0]+8),int(xy[1]+16)),mask)
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(blur)))
    image.alpha_composite(layer,(int(xy[0]),int(xy[1])))
def scrap(word, width, accent=True, angle=-7):
    h=int(width*.39);im=Image.new('RGBA',(int(width),h), RED if accent else '#fffaf1')
    draw=ImageDraw.Draw(im);f=font(h*.47,MONO);box=draw.textbbox((0,0),word,font=f)
    draw.text(((width-(box[2]-box[0]))/2,h*.23),word,font=f,fill=PAPER if accent else INK,anchor='lt')
    dashed(im,(0,3),(width,3),INK if accent else QUIET,2,8,8)
    dashed(im,(0,h-3),(width,h-3),INK if accent else QUIET,2,8,8)
    return im.rotate(angle,resample=Image.Resampling.BICUBIC,expand=True)
def phone(screen, width, angle=0):
    raw=Image.open(OUT/'raw'/f'{screen}.png').convert('RGB')
    w=int(width);border=max(10,int(w*.019));sw=w-border*2;sh=round(sw*raw.height/raw.width);h=sh+border*2
    im=Image.new('RGBA',(w+10,h),(0,0,0,0));d=ImageDraw.Draw(im)
    radius=int(w*.135)
    d.rounded_rectangle((0,0,w,h-1),radius=radius,fill='#272724',outline='#777973',width=max(2,int(w*.005)))
    d.rounded_rectangle((border*.48,border*.48,w-border*.48,h-border*.48),radius=radius*.91,outline='#10110f',width=max(2,int(w*.006)))
    capture=raw.resize((sw,sh),Image.Resampling.LANCZOS)
    mask=Image.new('L',(sw,sh));ImageDraw.Draw(mask).rounded_rectangle((0,0,sw-1,sh-1),radius=max(4,radius-border),fill=255)
    im.paste(capture,(border,border),mask)
    # Physical housing; the capture itself is untouched. Hardware isn't in simctl frames.
    pillw=sw*.29;pillh=sw*.074;pillx=border+(sw-pillw)/2;pilly=border+sw*.028
    d.rounded_rectangle((pillx,pilly,pillx+pillw,pilly+pillh),radius=pillh/2,fill='#050605')
    d.rounded_rectangle((w+1,h*.29,w+6,h*.41),radius=3,fill='#373932')
    return im.rotate(angle,resample=Image.Resampling.BICUBIC,expand=True) if angle else im

def panorama(W,H):
    im=Image.new('RGBA',(W*2,H),PAPER);d=ImageDraw.Draw(im)
    d.ellipse((W*.28,H*.84,W*1.8,H*1.55),fill=RED)
    dashed(im,(-100,H*.76),(W*2+100,H*.64),'#d6d0bf',max(2,int(W*.002)),W*.016,W*.014)
    for i,title in enumerate(['A little\ncut.','Two hidden\nwords.']):
        x=W*i+W*.075
        text(im,(x,H*.035),'snip.',W*.064)
        text(im,(x,H*.106),'THE DAILY WORD CUT' if i==0 else 'ONE CUT. BOTH ANSWERS.',W*.021,RED,MONO)
        lines(im,(x,H*.153),title,W*.156,INK,width=W*.85)
        lines(im,(x,H*.337),'Your new daily\nword ritual.' if i==0 else 'Keep both pieces.\nFind the little aha.',W*.036,QUIET,width=W*.72,face=SANS,leading=1.22)
    device=phone('selected',W*.69,angle=-9)
    paste_shadow(im,device,(W-device.width/2,H*.435),blur=W*.023,opacity=65)
    paste_shadow(im,scrap('PIE',W*.27,False,9),(W*.06,H*.635),blur=12,opacity=28)
    paste_shadow(im,scrap('RAT',W*.27,True,-7),(W*1.65,H*.655),blur=12,opacity=28)
    text(im,(W*.075,H*.895),'THREE DAILY PUZZLES',W*.020,PAPER,MONO)
    lines(im,(W*1.67,H*.894),'NO LETTERS\nWASTED',W*.018,INK,face=MONO)
    return [im.crop((0,0,W,H)).convert('RGB'),im.crop((W,0,W*2,H)).convert('RGB')]

def slide(W,H,index,title,subtitle,screen,bg=PAPER):
    im=Image.new('RGBA',(W,H),bg);d=ImageDraw.Draw(im);fg=PAPER if bg in [RED,INK] else INK
    accent=PAPER if bg==RED else RED
    text(im,(W*.075,H*.035),'snip.',W*.064,fg)
    text(im,(W*.77,H*.046),f'0{index} / 06',W*.018,fg,MONO)
    used=lines(im,(W*.075,H*.13),title,W*.133,fg,width=W*.85)
    lines(im,(W*.075,H*.13+used+H*.021),subtitle,W*.031,fg if bg!=PAPER else QUIET,width=W*.85,face=SANS,leading=1.25)
    dashed(im,(-50,H*.64),(W+50,H*.74),PAPER if bg!=PAPER else '#d6d0bf',max(2,int(W*.002)),W*.012,W*.01)
    device=phone(screen,W*.72,angle=0)
    paste_shadow(im,device,((W-device.width)/2,H*.32),blur=W*.03,opacity=65)
    return im.convert('RGB')

records=[]
for W,H in [(1206,2622),(1179,2556)]:
    folder=OUT/'screenshots'/f'{W}x{H}';folder.mkdir(parents=True,exist_ok=True)
    first,second=panorama(W,H)
    images=[first,second,
      slide(W,H,3,'Follow\nthat aha.','Two clues. One satisfying snip.','solved'),
      slide(W,H,4,'Small wins.\nBig grins.','Spoiler-free receipts made to share.','receipt',RED),
      slide(W,H,5,'Keep your\nscissors sharp.','Twelve puzzles. Four little collections.','practice'),
      slide(W,H,6,'A little time.\nJust for you.','Offline wordplay, at your own pace.','home',INK)]
    slugs=['little-cut','hidden-words','the-aha','little-receipt','practice','offline']
    for i,(im,slug) in enumerate(zip(images,slugs),1):
        p=folder/f'{i:02d}-{slug}.png';im.save(p)
        records.append({'path':str(p.relative_to(OUT)),'width':W,'height':H,'format':'PNG','mode':'RGB','placement':'screenshot','order':i,'source':'raw/'+(['selected','selected','solved','receipt','practice','home'][i-1])+'.png'})
    sheet=Image.new('RGB',(W*3,H*2),PAPER)
    for i,im in enumerate(images):sheet.paste(im,((i%3)*W,(i//3)*H))
    sheet.thumbnail((1440,2200),Image.Resampling.LANCZOS);sheet.save(OUT/f'contact-sheet-{W}x{H}.jpg',quality=94)

def creative(W,H,kind):
    im=Image.new('RGBA',(W,H),PAPER);d=ImageDraw.Draw(im)
    wide=W/H>2
    universal=kind=='universal'
    d.ellipse((W*.6,-H*.7,W*1.45,H*1.5),fill=RED)
    x=W*.075
    text(im,(x,H*.29 if wide else H*.245),'snip.',W*.142,INK)
    lines(im,(x,H*.60 if wide else H*.565),'One cut.\nTwo hidden words.',W*.032,INK,width=W*.47,face=SANS,leading=1.3)
    text(im,(x,H*.82),'A SMALL DAILY PLEASURE',W*.017,RED,MONO)
    targetw=W*(.172 if wide else .25)
    device=phone('selected',targetw,angle=-7)
    paste_shadow(im,device,(W*.625,(H-device.height)/2),blur=W*.008,opacity=65)
    piece=scrap('RAT',W*.128,True,-11)
    paste_shadow(im,piece,(W*.46,H*.38),blur=18,opacity=32)
    return im.convert('RGB')

folder=OUT/'creative';folder.mkdir(parents=True,exist_ok=True)
for W,H,kind,name in [(5244,2950,'universal','universal-header-search-5244x2950.png'),(3840,1646,'header','header-3840x1646.png'),(3840,2560,'search','search-3840x2560.png'),(1920,1280,'search','search-1920x1280.png')]:
    im=creative(W,H,kind);p=folder/name;im.save(p)
    records.append({'path':str(p.relative_to(OUT)),'width':W,'height':H,'format':'PNG','mode':'RGB','placement':kind,'source':'raw/selected.png'})
(OUT/'image-manifest.json').write_text(json.dumps(records,indent=2)+'\n')
print(f'Rendered {len(records)} opaque image assets, plus two contact sheets.')

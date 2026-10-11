# view3d.py PICTURE OUT.png [YAW_DEGREES] [DUMP] - one picture of an SW_DUMP3D dump (sw_sdl built
# with SW_3D): the original, the same lines redrawn from their 3-D points, the
# camera turned by YAW about the scene, and a top-down view.  Needs Pillow.
import sys, math
from PIL import Image, ImageDraw
P=int(sys.argv[1]); out=sys.argv[2]; yawdeg=float(sys.argv[3]) if len(sys.argv)>3 else 30
L=[]; pic=0
for line in open(sys.argv[4] if len(sys.argv) > 4 else 'd3.txt'):
    if line[0]=='P':
        pic=int(line.split()[1])
        if pic>P: break
        continue
    if pic!=P: continue
    a=line.split()
    L.append(dict(x0=float(a[0]),y0=float(a[1]),x1=float(a[2]),y1=float(a[3]),rgb=int(a[4],16),z=int(a[5]),
        s=(int(a[7]),int(a[8]),int(a[9]),int(a[10])), t=(int(a[12]),int(a[13]),int(a[14]),int(a[15])), sck=a[11], tck=a[16]))
W,H=700,600
def col(l,k=1.0):
    c=l['rgb']; return (int((c&255)*k),int(((c>>8)&255)*k),int(((c>>16)&255)*k))
ims=[]
im=Image.new('RGB',(W,H)); d=ImageDraw.Draw(im)
for l in L: d.line([(l['x0']/250*W,l['y0']/280*H),(l['x1']/250*W,l['y1']/280*H)],fill=col(l),width=2)
ims.append(im)
GOOD={'683F'}
three=[l for l in L if l['s'][0] and l['t'][0] and l['tck'] in GOOD and l['sck'] in GOOD]
print('lines',len(L),'with 3D both ends',len(three))
pts=[p for l in three for p in (l['s'],l['t'])]
if pts:
    xs=[p[1] for p in pts]; print('depth range',min(xs),max(xs))
# reprojection with a rotated camera: rotate around the vertical (z) axis by yaw about the scene centroid
def rot(p,yaw,cx):
    x,y,z=p[1]-cx,p[2],p[3]
    c,s=math.cos(yaw),math.sin(yaw)
    return (x*c - y*s + cx, x*s + y*c, z)
for yaw in (0.0, math.radians(yawdeg)):
    im=Image.new('RGB',(W,H)); d=ImageDraw.Draw(im)
    cx=sum(p[1] for p in pts)/len(pts) if pts else 0
    for l in three:
        a=rot(l['s'],yaw,cx); b=rot(l['t'],yaw,cx)
        if a[0]<=8 or b[0]<=8: continue
        f=1.0
        KX=127/250*W; KY=124/280*H; CY=166/280*H
        pa=(W/2 + a[1]/a[0]*KX, CY - a[2]/a[0]*KY); pb=(W/2 + b[1]/b[0]*KX, CY - b[2]/b[0]*KY)
        d.line([pa,pb],fill=col(l),width=2)
    ims.append(im)
# top-down: across vs depth
im=Image.new('RGB',(W,H)); d=ImageDraw.Draw(im)
if pts:
    mx=max(abs(p[2]) for p in pts)+1; md=max(p[1] for p in pts)+1
    for l in three:
        a,b=l['s'],l['t']
        d.line([(W/2+a[2]/mx*W/2*0.9, H-a[1]/md*H*0.95),(W/2+b[2]/mx*W/2*0.9, H-b[1]/md*H*0.95)],fill=col(l),width=1)
ims.append(im)
sheet=Image.new('RGB',(W*2,H*2))
for k,im in enumerate(ims): sheet.paste(im,((k%2)*W,(k//2)*H))
sheet.save(out)

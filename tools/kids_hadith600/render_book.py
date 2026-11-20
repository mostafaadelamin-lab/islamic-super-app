import sys,subprocess,os,glob,json
from PIL import Image
pdf,outdir,W=sys.argv[1],sys.argv[2],int(sys.argv[3])
os.makedirs(outdir,exist_ok=True)
tmp=outdir+'/_tmp'; os.makedirs(tmp,exist_ok=True)
info=subprocess.run(['pdfinfo',pdf],capture_output=True,text=True).stdout
w=float([l for l in info.splitlines() if l.startswith('Page size')][0].split()[2])
dpi=max(40,int(W/w*72)+1)
subprocess.run(['pdftoppm','-r',str(dpi),'-jpeg','-jpegopt','quality=95',pdf,tmp+'/p'],stderr=subprocess.DEVNULL)
fs=sorted(glob.glob(tmp+'/p-*.jpg'))
dims=[]
for k,f in enumerate(fs,1):
    im=Image.open(f).convert('RGB')
    if im.width>W: im=im.resize((W,round(im.height*W/im.width)),Image.LANCZOS)
    im.save(f'{outdir}/{k}.webp','WEBP',quality=60,method=5); dims.append([im.width,im.height]); os.remove(f)
os.rmdir(tmp)
json.dump(dims,open(outdir+'/dims.json','w'))
print(pdf,len(fs),sum(os.path.getsize(f'{outdir}/{k}.webp') for k in range(1,len(fs)+1))//1024,'KB')

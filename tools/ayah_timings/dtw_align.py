import json,sys,os,subprocess,urllib.request,numpy as np,librosa,concurrent.futures as cf
S=int(sys.argv[1]); REF=sys.argv[2]; TARGET=sys.argv[3]  # target url
HOP=0.1; SR=16000
q=json.load(open('/home/user/app/content/quran/dist/quran.v1.json'))['surahs'][S-1]['ayahCount']
d=f'/tmp/claude-0/dtw/{REF}_{S}'; os.makedirs(d,exist_ok=True)
def get(a):
  p=f'{d}/{a:03d}.mp3'
  if not os.path.exists(p): urllib.request.urlretrieve(f'https://everyayah.com/data/{REF}/{S:03d}{a:03d}.mp3',p)
  return p
with cf.ThreadPoolExecutor(8) as ex: files=list(ex.map(get,range(1,q+1)))
def load(path):
  raw=subprocess.run(['ffmpeg','-v','error','-i',path,'-ac','1','-ar',str(SR),'-f','s16le','-'],capture_output=True).stdout
  return np.frombuffer(raw,dtype=np.int16).astype(np.float32)/32768
ref=[];bounds=[];t=0
for f in files:
  x=load(f); ref.append(x); t+=len(x)/SR; bounds.append(t)
ref=np.concatenate(ref)
tgt=load(TARGET)
def feat(x):
  m=librosa.feature.mfcc(y=x,sr=SR,n_mfcc=20,hop_length=int(SR*HOP),n_fft=2048)[1:]
  m=(m-m.mean(1,keepdims=True))/(m.std(1,keepdims=True)+1e-6)
  return m
A=feat(ref); B=feat(tgt)
D,wp=librosa.sequence.dtw(X=A,Y=B,metric='cosine',global_constraints=True,band_rad=0.3,backtrack=True)
wp=wp[::-1]
# map each ref boundary to target time
out=[]
for bt in bounds:
  i=int(bt/HOP); js=wp[wp[:,0]==min(i,A.shape[1]-1),1]
  out.append(float(js.mean())*HOP if len(js) else None)
# first ayah start
i0=0
print(json.dumps({'ends':out,'tdur':len(tgt)/SR}))

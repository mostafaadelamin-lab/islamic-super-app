"""Rewrite ToUnicode CMaps: multi-char (ligature) entries were exported in visual order -> reverse them."""
import re,sys
from pypdf import PdfReader,PdfWriter
src,dst=sys.argv[1],sys.argv[2]
r=PdfReader(src); w=PdfWriter(clone_from=r)
def parse(d):
    m={}
    for blk in re.findall(r'beginbfchar(.*?)endbfchar',d,re.S):
        for s,t in re.findall(r'<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>',blk): m[int(s,16)]=t
    for blk in re.findall(r'beginbfrange(.*?)endbfrange',d,re.S):
        for a,b,rest in re.findall(r'<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>\s*(\[[^\]]*\]|<[0-9A-Fa-f]+>)',blk):
            a,b=int(a,16),int(b,16)
            if rest.startswith('['):
                for i,t in enumerate(re.findall(r'<([0-9A-Fa-f]+)>',rest)): m[a+i]=t
            else:
                t=rest[1:-1]; base=int(t,16)
                for i in range(b-a+1): m[a+i]=format(base+i,'0%dX'%len(t))
    return m
n=0; seen=set()
for page in w.pages:
    fonts=page.get('/Resources',{}).get('/Font',{})
    for k in fonts:
        f=fonts[k].get_object(); tu=f.get('/ToUnicode')
        if tu is None: continue
        o=tu.get_object()
        if id(o) in seen: continue
        seen.add(id(o))
        d=o.get_data().decode('latin1'); m=parse(d)
        out=[]
        for s,t in sorted(m.items()):
            if len(t)>4 and len(t)%4==0:
                t=''.join(reversed([t[i:i+4] for i in range(0,len(t),4)])); n+=1
            out.append('<%04X> <%s>'%(s,t))
        body=''
        for i in range(0,len(out),100):
            ch=out[i:i+100]; body+='%d beginbfchar\n%s\nendbfchar\n'%(len(ch),'\n'.join(ch))
        head=d[:d.index('endcodespacerange')+len('endcodespacerange')]
        o.set_data((head+'\n'+body+'endcmap\nCMapName currentdict /CMap defineresource pop\nend\nend\n').encode('latin1'))
w.write(dst); print('reversed',n)

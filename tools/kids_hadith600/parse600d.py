import re,json,sys,unicodedata,html
SYM={'':'ﷺ','':'رضي الله عنه','':'رضي الله عنها','':'رضي الله عنهما','':'رضي الله عنهن'}
def ismark(s): return s and all(unicodedata.category(c)=='Mn' for c in s)
def fixword(w):
    w=w[::-1]; w=re.sub(r'[0-9]+',lambda m:m.group(0)[::-1],w)
    return ''.join(SYM.get(c,c) for c in w)
W=re.compile(r'<word xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">(.*?)</word>')
t=open(sys.argv[1],encoding='utf-8').read()
out={};marks={};last=None;log=[]
def btext(b):
    ws=[(float(a),float(b_),float(c),float(d),html.unescape(e)) for a,b_,c,d,e in W.findall(b)]
    base=[w for w in ws if not ismark(w[4])]; mk=[w[4] for w in ws if ismark(w[4])]
    lines=[]
    for w in sorted(base,key=lambda w:w[1]):
        cy=(w[1]+w[3])/2
        for L in lines:
            if abs(L[0]-cy)<8: L[1].append(w);break
        else: lines.append([cy,[w]])
    lines.sort(key=lambda L:L[0])
    outl=[]
    for LL in lines:
        ws2=sorted(LL[1],key=lambda q:-q[0]); acc=''; prev=None
        for q in ws2:
            if prev is not None and prev[0]-q[2] < 1.6: acc+=fixword(q[4])
            else: acc+=(' ' if acc else '')+fixword(q[4])
            prev=q
        outl.append(acc)
    s=' '.join(outl)
    return s,mk,ws
for pi,p in enumerate(t.split('<page')[1:]):
    blocks=re.findall(r'<block xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">(.*?)</block>',p,re.S)
    nums=[];texts=[]
    for x0,y0,x1,y1,b in blocks:
        x0,y0,x1,y1=map(float,(x0,y0,x1,y1))
        nw=[m for m in W.finditer(b) if float(m.group(1))>505 and m.group(5).isdigit()]
        if nw and x0<505:
            for m in nw:
                nums.append(((float(m.group(2))+float(m.group(4)))/2,int(fixword(m.group(5)))))
                b=b.replace(m.group(0),'')
            x1=500
        s,mk,ws=btext(b)
        if x0>505 and s.strip().isdigit() and y1<790: nums.append(((y0+y1)/2,int(s)))
        elif x1<505 and y0>60 and y1<790: texts.append((y0,y1,s,mk))
    if not nums: continue
    texts.sort()
    asg=[]
    for y0,y1,s,mk in texts:
        if s.strip() in ('الحديث','م'): continue
        cand=[n for c,n in nums if y0-3<=c<=y1+3]
        asg.append([y0,y1,s,mk,cand[0] if cand else None])
        if len(cand)>1: log.append(('multi',pi+1,cand))
    END=re.compile(r'(متفق عليه|رواه البخاري|رواه مسلم|رواه مالك)\s*$')
    # top continuation
    prevdone = last is None or END.search(' '.join(out[last]['parts']))
    i=0
    while i<len(asg) and asg[i][4] is None and not prevdone:
        asg[i][4]=last; log.append(('cont',pi+1,last)); 
        if END.search(asg[i][2]): prevdone=True
        i+=1
    for k,a in enumerate(asg):
        if a[4] is not None: continue
        up=next((b for b in reversed(asg[:k]) if b[4] is not None),None)
        dn=next((b for b in asg[k+1:] if b[4] is not None),None)
        gu=a[0]-up[1] if up else 1e9; gd=dn[0]-a[1] if dn else 1e9
        a[4]=(up if gu<=gd else dn)[4]; log.append(('gap',pi+1,a[4],round(gu),round(gd)))
    for y0,y1,s,mk,n in asg:
        o=out.setdefault(n,{'n':n,'page':pi+1,'parts':[]}); o['parts'].append(s)
        if mk: marks.setdefault(n,[]).extend(mk)
    last=max(nums,key=lambda t:t[0])[1]
END2=re.compile(r'(متفق عليه|رواه البخاري|رواه مسلم|رواه مالك)\s*$')
for n in range(1,600):
    a=out.get(n); b=out.get(n+1)
    if not a or not b: continue
    while not END2.search(' '.join(a['parts'])) and b['parts'] and not b['parts'][0].startswith('عن'):
        a['parts'].append(b['parts'].pop(0)); log.append(('move',n+1,n))
res=[]
for n in range(1,601):
    o=out.get(n)
    if not o: log.append(('missing',n)); continue
    s=' '.join(o['parts']); s=re.sub(r'\s+',' ',s).strip()
    s=re.sub(r'\s+([:،.؟!»)\]])',r'\1',s); s=re.sub(r'([«(\[])\s+',r'\1',s); s=re.sub(r':(?=[«\w])',': ',s)
    lv=1 if n<=200 else 2 if n<=350 else 3 if n<=500 else 4
    r={'n':n,'level':lv,'page':o['page'],'text':s}
    if n in marks: r['marks']=marks[n]
    res.append(r)
json.dump(res,open(sys.argv[2],'w',encoding='utf-8'),ensure_ascii=False,indent=1)
for l in log: print(l,file=sys.stderr)

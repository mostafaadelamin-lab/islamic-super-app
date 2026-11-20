import json,re,sys
d=json.load(open(sys.argv[1]))
allt=' '.join(x['text'] for x in d if x['text'])
allt=allt.replace('«والصغير على الكبير» عن أبي موسى','«والصغير على الكبير» ||عن أبي موسى')
allt=re.sub(r'(متفق عليه|رواه البخاري|رواه مسلم|رواه مالك) (?=عن |عبد الله بن عمر)',r'\1 ||',allt)
parts=[p.strip() for p in allt.split('||')]
assert len(parts)==600,len(parts)
marks={x['n']:x.get('marks') for x in d}
res=[]
for i,p in enumerate(parts,1):
    lv=1 if i<=200 else 2 if i<=350 else 3 if i<=500 else 4
    m=re.search(r'(متفق عليه|رواه البخاري|رواه مسلم|رواه مالك)$',p)
    r={'n':i,'level':lv,'text':p}
    res.append(r)
json.dump(res,open(sys.argv[2],'w',encoding='utf-8'),ensure_ascii=False,indent=0)
# compare with numbered parse for sanity
diff=[x['n'] for x,y in zip(d,res) if x['text']!=y['text']]
print('changed vs numbered',diff)

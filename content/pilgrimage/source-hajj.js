/* ---- Hajj & Umrah ---- */
const TALBIYA="لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لَا شَرِيكَ لَكَ لَبَّيْكَ، إِنَّ الْحَمْدَ وَالنِّعْمَةَ لَكَ وَالْمُلْكَ، لَا شَرِيكَ لَكَ";
const UMRAH=[
 {t:"الإحرام من الميقات",p:["اغتسل وتطيّب في بدنك قبل الإحرام، والبس الإزار والرداء الأبيضين للرجل، وتلبس المرأة ثيابها المعتادة الساترة دون نقاب أو قفازين.","انوِ الدخول في النسك وقل عند الميقات: «لَبَّيْكَ عُمْرَةً».","أكثِر من التلبية حتى تبدأ الطواف."],z:TALBIYA},
 {t:"الطواف حول الكعبة",p:["ابدأ من الحجر الأسود واجعل الكعبة عن يسارك، وطُف سبعة أشواط كاملة.","استلم الحجر الأسود أو أشر إليه في بداية كل شوط وقل: «بسم الله، والله أكبر».","يُسنّ للرجل الاضطباع (كشف الكتف الأيمن) في طواف العمرة كله، والرَّمَل (الإسراع مع تقارب الخطى) في الأشواط الثلاثة الأولى.","ادعُ بما شئت، وبين الركن اليماني والحجر الأسود قل الدعاء المذكور أدناه.","بعد الطواف صلِّ ركعتين خلف مقام إبراهيم إن تيسّر، تقرأ فيهما «الكافرون» و«الإخلاص»، ثم اشرب من ماء زمزم."],z:"رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ",tool:"tawaf"},
 {t:"السعي بين الصفا والمروة",p:["اصعد الصفا واقرأ: «إِنَّ الصَّفَا وَالْمَرْوَةَ مِنْ شَعَائِرِ اللَّهِ»، واستقبل القبلة وكبّر وادعُ.","امشِ إلى المروة، ويُسنّ للرجل الإسراع بين العلامتين الخضراوين.","الذهاب من الصفا إلى المروة شوط، والرجوع شوط آخر. أكمل سبعة أشواط تنتهي عند المروة."],z:"لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ، أَنْجَزَ وَعْدَهُ، وَنَصَرَ عَبْدَهُ، وَهَزَمَ الْأَحْزَابَ وَحْدَهُ",tool:"sai"},
 {t:"الحلق أو التقصير",p:["يحلق الرجل رأسه أو يقصّر من جميع شعره، والحلق أفضل.","تقصّر المرأة من أطراف شعرها قدر أنملة.","بذلك تتم عمرتك ويحلّ لك كل ما حُرّم بالإحرام. تقبّل الله منك."]}
];
const HAJJ_DAYS=[
 {d:"٨ ذو الحجة · يوم التروية",p:["يُحرم المتمتع بالحج من مكانه في مكة ضحى، ويبقى القارن والمفرد على إحرامهما.","التوجه إلى منى، وصلاة الظهر والعصر والمغرب والعشاء وفجر اليوم التاسع فيها، كل صلاة في وقتها مع قصر الرباعية دون جمع.","الإكثار من التلبية."]},
 {d:"٩ ذو الحجة · يوم عرفة",p:["بعد شروق الشمس يتوجه الحاج إلى عرفة.","يصلّي الظهر والعصر جمع تقديم وقصرًا بأذان وإقامتين.","الوقوف بعرفة ركن الحج الأعظم: يتفرغ للذكر والدعاء مستقبلًا القبلة حتى غروب الشمس، ويتأكد أنه داخل حدود عرفة.","بعد الغروب يدفع إلى مزدلفة بسكينة، فيصلي بها المغرب والعشاء جمعًا ويبيت فيها، ويجوز للضعفاء الدفع بعد منتصف الليل."],z:"خَيْرُ الدُّعَاءِ دُعَاءُ يَوْمِ عَرَفَةَ: لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ"},
 {d:"١٠ ذو الحجة · يوم النحر (العيد)",p:["يصلي الفجر في مزدلفة ويذكر الله حتى يُسفر جدًا، ثم يدفع إلى منى قبل طلوع الشمس.","رمي جمرة العقبة بسبع حصيات متعاقبات، يكبّر مع كل حصاة، ويقطع التلبية.","ذبح الهدي للمتمتع والقارن.","الحلق أو التقصير، وبه يحصل التحلل الأول فيحل له كل شيء إلا النساء.","طواف الإفاضة، ثم السعي للمتمتع، وللقارن والمفرد إن لم يسعيا بعد طواف القدوم. وبه يحصل التحلل الثاني.","الترتيب بين هذه الأعمال سنة، ولا حرج في تقديم بعضها على بعض."],tool:"jamarat"},
 {d:"١١ و١٢ و١٣ ذو الحجة · أيام التشريق",p:["المبيت بمنى ليالي أيام التشريق.","رمي الجمرات الثلاث كل يوم بعد الزوال: الصغرى ثم الوسطى ثم الكبرى (العقبة)، سبع حصيات لكل جمرة مع التكبير.","يقف بعد الصغرى والوسطى مستقبلًا القبلة ويدعو طويلًا، ولا يقف بعد جمرة العقبة.","من تعجّل خرج من منى قبل غروب شمس اليوم الثاني عشر، ومن تأخر رمى اليوم الثالث عشر."]},
 {d:"قبل السفر · طواف الوداع",p:["إذا أراد الحاج الخروج من مكة طاف بالبيت سبعة أشواط للوداع، ويكون آخر عهده بالبيت.","يسقط طواف الوداع عن الحائض والنفساء."]}
];
const HAJJ_TYPES=[["التمتع","يُحرم بالعمرة وحدها في أشهر الحج ويؤديها ثم يتحلل، ثم يُحرم بالحج يوم الثامن من ذي الحجة. وعليه الهدي. وهو أفضل الأنساك عند كثير من العلماء لمن لم يسق الهدي."],["القِران","يُحرم بالعمرة والحج معًا ويقول: «لبيك عمرةً وحجًا»، ويبقى على إحرامه حتى يوم النحر. يكفيه طواف واحد وسعي واحد، وعليه الهدي."],["الإفراد","يُحرم بالحج وحده ويقول: «لبيك حجًا»، ويبقى على إحرامه حتى يوم النحر، ولا هدي عليه."]];
const MIQAT=[["ذو الحليفة (أبيار علي)","لأهل المدينة ومن مرّ بها"],["الجحفة (ويُحرم الناس اليوم من رابغ)","لأهل الشام ومصر والمغرب"],["قرن المنازل (السيل الكبير)","لأهل نجد والطائف"],["يلملم (السعدية)","لأهل اليمن"],["ذات عرق (الضريبة)","لأهل العراق"]];
const IHRAM_NO=["إزالة الشعر من الرأس أو البدن","تقليم الأظفار","استعمال الطيب في البدن أو الثوب","تغطية الرأس بملاصق (للرجل)","لبس المخيط المفصّل على البدن كالقميص والسراويل (للرجل)","لبس النقاب والقفازين (للمرأة)","قتل الصيد البري أو التعرض له","عقد النكاح","الجماع ومقدماته"];
const MADINAH=["زيارة المسجد النبوي سنة مستقلة وليست من أعمال الحج، والصلاة فيه خير من ألف صلاة فيما سواه إلا المسجد الحرام.","يُسن عند الزيارة السلام على النبي ﷺ ثم على صاحبيه أبي بكر وعمر رضي الله عنهما بأدب وخفض صوت.","يُستحب الصلاة في مسجد قباء، وزيارة البقيع وشهداء أحد للسلام عليهم والدعاء لهم."];

function hijriMonthDay(date=new Date()){ try{ const p=new Intl.DateTimeFormat("en-u-ca-islamic-umalqura-nu-latn",{month:"numeric",day:"numeric",timeZone:"Asia/Riyadh"}).formatToParts(date); return {m:+p.find(x=>x.type==="month").value,d:+p.find(x=>x.type==="day").value}; }catch(e){ return {m:0,d:0}; } }
/* rough crowd model for Masjid al-Haram, Makkah local time */
function crowdLevel(date){
  const MK=CITIES.find(c=>c[0]==="مكة المكرمة"); const {y,m,d}=partsInTZ(date,"Asia/Riyadh");
  const t=prayerTimes(y,m,d,MK[2],MK[3],"makkah",1); const base=Date.UTC(y,m-1,d);
  const hm=new Intl.DateTimeFormat("en-GB",{hour:"numeric",minute:"numeric",hourCycle:"h23",timeZone:"Asia/Riyadh"}).formatToParts(date); const hour=+hm.find(x=>x.type==="hour").value+(+hm.find(x=>x.type==="minute").value)/60;
  const wd=new Date(base+12*3600e3).getUTCDay(); const H=hijriMonthDay(date);
  let s=0.32; // baseline
  if(hour>=1&&hour<4) s-=0.08; if(hour>=9&&hour<12) s-=0.1;
  for(const k of ["fajr","dhuhr","asr","maghrib","isha"]){ const ph=fix(t[k]+3,24); const dt=hour-ph; if(dt>-0.75&&dt<0.5) s+=k==="maghrib"||k==="isha"?0.32:k==="fajr"?0.24:0.2; else if(dt>-1.5&&dt<1) s+=0.08; }
  if(wd===5&&hour>=10&&hour<14) s+=0.3; if(wd===4||wd===5) s+=0.08;
  if(H.m===9){ s+=0.22; if(H.d>=20) s+=0.25; if(hour>=21||hour<4) s+=0.12; }
  if(H.m===12&&H.d<=14) s+=0.35; if(H.m===8&&H.d>=15) s+=0.06; if(H.m===10&&H.d<=3) s+=0.15;
  return Math.max(0,Math.min(1,s));
}
const CROWD_NAMES=[["خفيف","var(--ok)"],["متوسط","var(--saffron)"],["مزدحم","var(--warn)"],["مزدحم جدًا","var(--warn)"]];
const crowdName=v=>CROWD_NAMES[v<0.4?0:v<0.6?1:v<0.8?2:3];

VIEWS.hajj=(tab)=>{
  const v=el("main",{class:"view"}); const cur=tab||store.get("hajjTab","u");
  const seg=el("div",{class:"seg",role:"tablist"}); const body=el("div",{style:"display:flex;flex-direction:column;gap:12px"});
  const draw=m=>{ store.set("hajjTab",m); [...seg.children].forEach(b=>b.setAttribute("aria-selected",b.dataset.m===m)); body.innerHTML=""; body.append(...(m==="u"?umrahView():m==="h"?hajjView():m==="c"?crowdView():ihramView())); };
  [["u","العمرة"],["h","الحج"],["i","الإحرام"],["c","الزحام"]].forEach(([m,n])=>seg.append(el("button",{role:"tab","data-m":m,onclick:()=>draw(m)},n)));
  v.append(seg, body); draw(cur);
  return [topbar("الحج والعمرة","دليل المناسك خطوة بخطوة",null), v];
};
function stepCard(n,s){ const c=el("section",{class:"card",style:"display:flex;flex-direction:column;gap:8px"}, el("span",{class:"label"},n), el("h2",{},s.t||s.d), el("ul",{style:"margin:0;padding-inline-start:20px;display:flex;flex-direction:column;gap:6px"},s.p.map(x=>el("li",{},x))));
  if(s.z) c.append(el("div",{class:"example"},s.z));
  if(s.tool) c.append(el("a",{class:"btn small",style:"align-self:flex-start",href:"#counter-"+s.tool},s.tool==="tawaf"?"عدّاد أشواط الطواف":s.tool==="sai"?"عدّاد أشواط السعي":"عدّاد حصى الجمرات"));
  return c; }
function umrahView(){ return [el("p",{class:"muted",style:"margin:0"},"العمرة أربعة أعمال: الإحرام، ثم الطواف، ثم السعي، ثم الحلق أو التقصير."), ...UMRAH.map((s,i)=>stepCard("الخطوة "+ar(i+1),s)), madinahCard()]; }
function hajjView(){ const types=el("section",{class:"card",style:"display:flex;flex-direction:column;gap:10px"},el("h2",{},"أنواع النسك"),...HAJJ_TYPES.map(([n,d])=>el("div",{},el("b",{},n+": "),d)));
  return [types, ...HAJJ_DAYS.map((s,i)=>stepCard("المرحلة "+ar(i+1),s)), el("section",{class:"card"},el("h2",{},"أركان الحج"),el("p",{style:"margin:6px 0 0"},"الإحرام، والوقوف بعرفة، وطواف الإفاضة، والسعي. ومن ترك ركنًا لم يتم حجه حتى يأتي به.")), madinahCard()]; }
function ihramView(){ return [
  el("section",{class:"card",style:"display:flex;flex-direction:column;gap:8px"},el("h2",{},"المواقيت المكانية"),el("div",{class:"list"},MIQAT.map(([a,b])=>el("div",{class:"item"},el("div",{class:"t"},el("b",{},a),el("div",{class:"small muted"},b))))),el("p",{class:"small muted",style:"margin:0"},"من كان دون المواقيت أحرم من مكانه، وأهل مكة يُحرمون بالحج من مكة وبالعمرة من الحِل كالتنعيم.")),
  el("section",{class:"card",style:"display:flex;flex-direction:column;gap:8px"},el("h2",{},"محظورات الإحرام"),el("ul",{style:"margin:0;padding-inline-start:20px"},IHRAM_NO.map(x=>el("li",{},x))),el("p",{class:"small muted",style:"margin:0"},"من فعل شيئًا منها ناسيًا أو جاهلًا فلا شيء عليه، ومن تعمّد فعليه الفدية على تفصيل عند أهل العلم.")),
  el("section",{class:"card"},el("h2",{},"التلبية"),el("div",{class:"example",style:"margin-top:8px"},TALBIYA),el("div",{class:"row",style:"margin-top:8px"},el("button",{class:"btn ghost small",onclick:()=>copyText(TALBIYA)},"نسخ")))]; }
function madinahCard(){ return el("section",{class:"card",style:"display:flex;flex-direction:column;gap:8px"},el("h2",{},"زيارة المدينة المنورة"),el("ul",{style:"margin:0;padding-inline-start:20px"},MADINAH.map(x=>el("li",{},x)))); }
function crowdView(){
  const now=new Date(); const lv=crowdLevel(now); const [nm,col]=crowdName(lv);
  const card=el("section",{class:"card",style:"display:flex;flex-direction:column;gap:8px"},
    el("div",{class:"label"},"المسجد الحرام · الآن بتوقيت مكة "+new Intl.DateTimeFormat("ar-EG",{hour:"numeric",minute:"2-digit",timeZone:"Asia/Riyadh"}).format(now)),
    el("h2",{style:`font-size:26px;color:${col}`},"الزحام المتوقع: "+nm),
    el("div",{class:"ring",style:"height:10px"},el("i",{style:`width:${Math.round(lv*100)}%;background:${col}`})));
  // 24h forecast bars
  const W=360,Hh=120; let bars=""; const start=new Date(now); start.setMinutes(0,0,0);
  let best=[];
  for(let i=0;i<24;i++){ const d=new Date(start.getTime()+i*3600e3); const c=crowdLevel(new Date(d.getTime()+30*60e3)); const h=Math.max(4,c*(Hh-24)); const [,cc]=crowdName(c);
    bars+=`<rect x="${W-(i+1)*15+2}" y="${Hh-18-h}" width="11" height="${h}" rx="2" fill="${cc}" opacity="${i===0?1:.75}"/>`;
    if(i%3===0) bars+=`<text x="${W-(i+1)*15+7.5}" y="${Hh-4}" font-size="9" text-anchor="middle" fill="var(--muted)">${new Intl.DateTimeFormat("ar-EG",{hour:"numeric",timeZone:"Asia/Riyadh"}).format(d).replace(/\s/g,"")}</text>`;
    best.push([c,d]); }
  best=best.sort((a,b)=>a[0]-b[0]).slice(0,3).sort((a,b)=>a[1]-b[1]).map(([,d])=>new Intl.DateTimeFormat("ar-EG",{hour:"numeric",timeZone:"Asia/Riyadh"}).format(d));
  const chart=el("section",{class:"card"},el("h3",{},"توقّع الساعات القادمة"),el("div",{style:"overflow-x:auto"},el("div",{html:`<svg viewBox="0 0 ${W} ${Hh}" style="width:100%;min-width:300px;height:auto" role="img" aria-label="توقع الزحام خلال ٢٤ ساعة">${bars}</svg>`})),el("p",{class:"small",style:"margin:6px 0 0"},"أنسب الأوقات المتوقعة للطواف: "+best.join("، ")));
  const links=el("section",{class:"card",style:"display:flex;flex-direction:column;gap:8px"},el("h3",{},"مشاهدة مباشرة ومصادر رسمية"),
    el("a",{class:"btn ghost",href:"https://www.youtube.com/results?search_query=%D8%A8%D8%AB+%D9%85%D8%A8%D8%A7%D8%B4%D8%B1+%D9%85%D9%83%D8%A9+%D8%A7%D9%84%D9%85%D9%83%D8%B1%D9%85%D8%A9+%D9%82%D9%86%D8%A7%D8%A9+%D8%A7%D9%84%D9%82%D8%B1%D8%A2%D9%86",target:"_blank",rel:"noopener"},"البث المباشر من المسجد الحرام ↗"),
    el("a",{class:"btn ghost",href:"https://www.youtube.com/results?search_query=%D8%A8%D8%AB+%D9%85%D8%A8%D8%A7%D8%B4%D8%B1+%D8%A7%D9%84%D9%85%D8%B3%D8%AC%D8%AF+%D8%A7%D9%84%D9%86%D8%A8%D9%88%D9%8A+%D9%82%D9%86%D8%A7%D8%A9+%D8%A7%D9%84%D8%B3%D9%86%D8%A9",target:"_blank",rel:"noopener"},"البث المباشر من المسجد النبوي ↗"),
    el("a",{class:"btn ghost",href:"https://www.nusuk.sa/",target:"_blank",rel:"noopener"},"منصة نُسك الرسمية (تصاريح العمرة والروضة) ↗"));
  return [card, chart, el("p",{class:"notice",style:"margin:0"},"هذا تقدير تقريبي مبني على أوقات الصلاة في مكة ويوم الأسبوع والمواسم (رمضان والحج)، وليس قياسًا مباشرًا من الحرم. للتأكد شاهد البث المباشر."), links];
}
VIEWS.counter=(kind)=>{
  kind=["tawaf","sai","jamarat"].includes(kind)?kind:"tawaf";
  const max=7; const st=store.get("cnt."+kind,0); let n=st;
  const names={tawaf:"عدّاد أشواط الطواف",sai:"عدّاد أشواط السعي",jamarat:"عدّاد حصى الجمرة"};
  const hint=el("div",{class:"dhikr-text",style:"font-size:20px"}); const bead=el("button",{class:"bead","aria-label":"أضف شوطًا"}); const ring=el("i");
  const draw=()=>{ store.set("cnt."+kind,n); bead.textContent=ar(n); ring.style.width=n/max*100+"%";
    hint.textContent= n>=max?(kind==="tawaf"?"أتممت الطواف ✓ صلِّ ركعتين خلف المقام":kind==="sai"?"أتممت السعي ✓ انتهيت عند المروة":"أتممت سبع حصيات ✓"):
      kind==="sai"?`الشوط ${ar(n+1)}: من ${n%2===0?"الصفا إلى المروة":"المروة إلى الصفا"}`: kind==="tawaf"?`الشوط ${ar(n+1)}${n<3?" · يُسنّ الرَّمَل للرجال":""}`:`الحصاة ${ar(n+1)} · الله أكبر`; };
  bead.onclick=()=>{ if(n<max){ n++; try{ navigator.vibrate&&navigator.vibrate(n===max?[80,50,80]:25);}catch(e){} draw(); } };
  const v=el("main",{class:"view"}, el("div",{class:"tasbih"}, hint, bead, el("div",{class:"ring",style:"max-width:260px"},ring),
    el("div",{class:"row"}, el("button",{class:"btn ghost small",onclick:()=>{ if(n>0){ n--; draw(); } }},"تراجع شوط"), el("button",{class:"btn ghost small",onclick:()=>{ n=0; draw(); }},"البدء من جديد"))),
    el("p",{class:"small muted",style:"margin:0;text-align:center"},"اضغط الدائرة بعد إتمام كل شوط. يبقى العدد محفوظًا حتى لو أُغلق التطبيق."));
  draw(); return [topbar(names[kind],null,"hajj"), v];
};

"""Builds assets/content/nasheeds.v2.json from the anasheed.info singer pages
(scraped in the owner's browser, 2026-11-11). Keeps only links that answered
HTTP 200 (archive.org, https). Leaves out battle/war/militant anthems (store
policy on violent content) by title and by archive collection."""
import json, re, sys

src, check, out = sys.argv[1:4]
d = json.load(open(src)); d = json.loads(d) if isinstance(d, str) else d
c = json.load(open(check)); c = json.loads(c) if isinstance(c, str) else c

BAD_COLLECTIONS = re.compile(r'jihad|baghd|mujahid|dawla', re.I)
BAD_WORDS = ['أجاهد', 'جهاد', 'بالدم', 'الدماء', 'بالدماء', 'سيوف', 'سيفي', 'الكتائب', 'الحرب', 'قتال', 'يهود', 'جند الله',
             'شهيد', 'السجون', 'السدود', 'قضبان', 'الأسود', 'أسود', 'الأبطال', 'الابطال', 'خيبر', 'المنية', 'العسكرية',
             'قعقعات', 'فلوجة', 'هتكوا', 'المعتدين', 'سيهزم', 'لا نحيد', 'الصين لنا', 'أنصار الحجة', 'عصفت بنا الأهواء',
             'كسرنا قوس', 'لن نحيد', 'يحكون في بلادنا', 'بدمي', 'أماه لا تبكيني', 'قامت تخوض', 'أجناده', 'الفدا', 'أنت سيوف', 'خندقي', 'جمر المخاطر', 'ينادون', 'زأر', 'تلتهب', 'عزمي',
             'الأمجاد', 'قصة المجد', 'ملكنا هذه الدنيا', 'بغداد', 'بدنا نعيش الحرية', 'يا دمشق', 'أين الأسد',
             'نحن طلائع', 'جواد الفجر', 'بدأ المسير', 'لأني مضيت', 'سأحيا بالكرامة', 'تهون الحياة', 'في سبيل الله نمضي',
             'أي جرح', 'يا فتى الإسـلام', 'قف يا تاريخ', 'صرخة', 'أراكان', 'سوريا', 'شفت الخيول', 'حساس يا جرح']
SKIP_SINGERS = {40}  # "members' uploads": unknown origin

ALLOW = {'أشد الجهاد جهاد الهوى', 'اشد الجهاد', 'لما رحلت (أبكيك بالدمع)', 'ياخاطري كل ضيقة'}

def bad(title, url):
    if title in ALLOW:
        return False
    if BAD_COLLECTIONS.search(url.split('/')[4] if 'archive.org/' in url else ''):
        return True
    return any(w in title for w in BAD_WORDS)

singers, dropped, broken = [], [], 0
for s in d:
    if s['id'] in SKIP_SINGERS: continue
    items = []
    for i in s['items']:
        u, t = i['url'], re.sub(r'\s+', ' ', i['title']).strip()
        if not u.startswith('https://archive.org/') or c.get(u, [0])[0] != 200:
            broken += 1; continue
        if bad(t, u):
            dropped.append(f"{s['name']}: {t}"); continue
        items.append({'id': i['id'], 'title': t, 'url': u, 'bytes': c[u][1]})
    if items:
        singers.append({'id': s['id'], 'name': s['name'].strip(), 'items': items})
singers.sort(key=lambda s: -len(s['items']))
json.dump({'version': 2, 'singers': singers}, open(out, 'w'), ensure_ascii=False, indent=0)
print('singers', len(singers), 'items', sum(len(s['items']) for s in singers), 'broken', broken, 'dropped', len(dropped))
open(out + '.dropped.txt', 'w').write('\n'.join(dropped))

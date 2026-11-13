import json
def vr(vid,title,ch,cid,dur):
    return '"videoRenderer":{"videoId":"%s","thumbnail":{},"title":{"runs":[{"text":%s}]},"longBylineText":{"runs":[{"text":%s,"navigationEndpoint":{"browseEndpoint":{"browseId":"%s"}}}]},"lengthText":{"accessibility":{},"simpleText":"%s"}}' % (vid, json.dumps(title), json.dumps(ch), cid, dur)
trusted="UCYuUcfXvsHapABTcPRWCEoQ"
other="UC"+"a"*22
s = '<html>var ytInitialData = {' + ','.join([
 vr("aaaaaaaaaa1","أغنية جميلة \"رائعة\"","قناة",other,"3:10"),
 vr("aaaaaaaaaa2","سورة الكهف كاملة","قناة عامة",other,"45:01"),
 vr("aaaaaaaaaa3","Funny cats","Cats",other,"1:00"),
 vr("aaaaaaaaaa4","تلاوة خاشعة","الشيخ ياسر الدوسري",trusted,"10:00"),
 vr("aaaaaaaaaa2","dup","x",other,"1:00"),
 vr("aaaaaaaaaa5","والقرآنِ الكريم \\u0026 more","ch",other,"2:00"),
 vr("aaaaaaaaaa6","Random vlog","ch",other,"2:00"),
]) + '}</html>'
open('search.html','w').write(s)
feed = '<feed>' + ''.join('<entry><yt:videoId>bbbbbbbbbb%d</yt:videoId><title>%s</title><link rel="alternate" href="https://www.youtube.com/%s/bbbbbbbbbb%d"/><published>2026-11-%02dT00:00:00+00:00</published></entry>' % (i, t, p, i, 10-i) for i,(t,p) in enumerate([("تلاوة &amp; ذكر","shorts"),("<![CDATA[درس]]>","watch"),("&#1575;&#1604;&#1604;&#1607;","shorts")])) + '</feed>'
open('feed.xml','w').write(feed)
cp = ''.join('"lockupViewModel":{"contentImage":{"thumbnailViewModel":{"image":{"sources":[{"url":"https://i.ytimg.com/vi/cccccccccc%d/hq.jpg"}]}}},"metadata":{"title":{"content":"فيديو %d \\"x\\""}}}' % (i,i) for i in range(3))
open('chan.html','w').write(cp)
open('handle.html','w').write('<link rel="canonical" href="https://www.youtube.com/channel/UC'+'b'*22+'">')

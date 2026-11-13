<?php
/**
 * Islamic videos for the website on ordinary PHP hosting (Bluehost): the trusted channels' feed and video search.
 * PHP port of netlify/lib/videos-core.mjs + netlify/functions/videos.mjs, same rules and same JSON:
 *  - GET /api/v1/reels/feed            -> newest videos of the trusted channels (schema reels-feed.v1)
 *  - GET /api/videos/search?q=...      -> Islamic videos only, trusted channels first (schema video-search.v1)
 * Browsers cannot read YouTube directly (no CORS), so this file does it on the server. No API key, no account.
 * Results are cached in api/cache/ (feed 3 h, search 1 h); when YouTube cannot be reached the last good copy is served.
 */

declare(strict_types=1);

const PER_SOURCE = 15;
const FEED_TTL = 3 * 60 * 60;
const SEARCH_TTL = 60 * 60;
const VIDEO_ID = '/^[A-Za-z0-9_-]{11}$/';
const CHANNEL_ID = '/^UC[A-Za-z0-9_-]{22}$/';

/** Lower-case, no tashkeel/tatweel, one form of alef/yaa/taa marbuta: so "القرآن" matches "القران". */
function normalize(string $s): string
{
    $s = mb_strtolower($s, 'UTF-8');
    $s = preg_replace('/[\x{064B}-\x{0670}\x{065F}\x{0640}]/u', '', $s) ?? $s;
    $s = preg_replace('/[أإآٱ]/u', 'ا', $s) ?? $s;
    $s = str_replace(['ى', 'ة'], ['ي', 'ه'], $s);
    $s = preg_replace('/\s+/u', ' ', $s) ?? $s;
    return trim($s);
}

const ISLAMIC_WORDS = [
    'قران', 'سوره', 'تلاوه', 'تلاوات', 'ترتيل', 'تجويد', 'مصحف', 'ايات', 'قارئ', 'القارئ', 'مقرئ', 'الشيخ', 'شيخ',
    'مشايخ', 'درس', 'دروس', 'محاضره', 'خطبه', 'موعظه', 'مواعظ', 'نصيحه', 'نصائح', 'تذكير', 'رقائق', 'تفسير', 'حديث',
    'احاديث', 'السنه', 'النبي', 'الرسول', 'صلي الله عليه وسلم', 'سيره', 'الصحابه', 'فقه', 'فتوي', 'الله', 'اسلام',
    'اسلامي', 'اسلاميه', 'الايمان', 'التوبه', 'الجنه', 'الاخره', 'الصلاه', 'الدعاء', 'دعاء', 'اذكار', 'رمضان', 'الحج',
    'العمره', 'الزكاه', 'التوحيد', 'العقيده', 'القيامه', 'استغفار', 'الصبر',
    'quran', 'koran', 'recitation', 'surah', 'surat', 'tilawat', 'tajweed', 'islam', 'islamic', 'muslim', 'sheikh',
    'shaykh', 'tafsir', 'hadith', 'prophet', 'sunnah', 'allah', 'dua', 'lecture', 'khutbah', 'reminder', 'imam',
];

/** Never shown, even from a search the viewer typed (music, entertainment, mockery). */
const BLOCKED_WORDS = [
    'اغنيه', 'اغاني', 'اغنية', 'موسيقي', 'موسيقى', 'مهرجان', 'كليب', 'رقص', 'فيلم', 'افلام', 'مسلسل', 'حلقه مسلسل',
    'مقلب', 'مقالب', 'ضحك', 'كوميدي', 'نكت', 'العاب', 'لعبه', 'ريمكس', 'شيله', 'غناء', 'طرب', 'ديسكو', 'تيك توك ترند',
    'song', 'songs', 'music', 'remix', 'dance', 'dancing', 'movie', 'film', 'trailer', 'prank', 'funny', 'comedy',
    'gaming', 'gameplay', 'lyrics', 'karaoke', 'beat', 'rap', 'concert', 'dj ',
];

/** Arabic words may carry a joined prefix (و، ف، ب، ل، ال، وال، بال، فال، لل). */
function stripPrefix(string $w): string
{
    return preg_replace('/^(?:و|ف|ب|ل|ك)?(?:ال|ل)?/u', '', $w, 1) ?? $w;
}

function hasWord(string $text, array $words): bool
{
    $t = normalize($text);
    $tokens = [];
    foreach (preg_split('/[^\p{L}\p{N}]+/u', $t, -1, PREG_SPLIT_NO_EMPTY) ?: [] as $w) {
        $tokens[$w] = true;
        $tokens[stripPrefix($w)] = true;
    }
    foreach ($words as $w) {
        $n = normalize($w);
        if (str_contains($n, ' ')) {
            if (str_contains(" $t ", " $n ") || str_contains($t, $n)) return true;
        } elseif (isset($tokens[$n]) || isset($tokens[stripPrefix($n)])) {
            return true;
        }
    }
    return false;
}

function isBlocked(string $text): bool { return hasWord($text, BLOCKED_WORDS); }
function looksIslamic(string $text): bool { return hasWord($text, ISLAMIC_WORDS); }

/** A search result may be shown: never a blocked title; trusted channels always; others only clearly Islamic. */
function allowedVideo(array $hit, array $trusted): bool
{
    $channel = $hit['channel'] ?? '';
    if (isBlocked($hit['title']) || isBlocked($channel)) return false;
    if ($hit['channelId'] && isset($trusted[$hit['channelId']])) return true;
    return looksIslamic($hit['title']) || looksIslamic($channel);
}

function shortsFeed(string $cid): string { return 'https://www.youtube.com/feeds/videos.xml?playlist_id=UUSH' . substr($cid, 2); }
function channelFeed(string $cid): string { return "https://www.youtube.com/feeds/videos.xml?channel_id=$cid"; }
function channelVideosPage(string $cid): string { return "https://www.youtube.com/channel/$cid/videos?hl=ar"; }
function handlePage(string $h): string { return 'https://www.youtube.com/@' . rawurlencode($h); }
function searchPage(string $q): string
{
    return 'https://www.youtube.com/results?' . http_build_query(['search_query' => $q, 'sp' => 'EgIQAQ==', 'hl' => 'ar']);
}

function decodeXml(string $s): string
{
    $s = preg_replace('/<!\[CDATA\[([\s\S]*?)\]\]>/', '$1', $s) ?? $s;
    $s = str_replace(['&lt;', '&gt;', '&quot;', '&#39;', '&apos;'], ['<', '>', '"', "'", "'"], $s);
    $s = preg_replace_callback('/&#(\d+);/', fn($m) => mb_chr((int) $m[1], 'UTF-8') ?: '', $s) ?? $s;
    return str_replace('&amp;', '&', $s);
}

/** Entries of a YouTube Atom feed. */
function parseFeed(string $xml, bool $shortsOnly = false): array
{
    $out = [];
    preg_match_all('/<entry>([\s\S]*?)<\/entry>/', $xml, $entries);
    foreach ($entries[1] as $e) {
        $vid = preg_match('/<yt:videoId>([^<]+)<\/yt:videoId>/', $e, $m) ? trim($m[1]) : '';
        $title = trim(decodeXml(preg_match('/<title>([\s\S]*?)<\/title>/', $e, $m) ? $m[1] : ''));
        $href = preg_match('/<link[^>]*href="([^"]+)"/', $e, $m) ? $m[1] : '';
        $published = preg_match('/<published>([^<]+)<\/published>/', $e, $m) ? trim($m[1]) : null;
        if (!preg_match(VIDEO_ID, $vid) || $title === '' || ($shortsOnly && !str_contains($href, '/shorts/'))) continue;
        $out[] = ['ref' => $vid, 'title' => $title, 'published' => $published];
    }
    return $out;
}

function channelIdFromPage(string $html): ?string
{
    $rx = [
        '/<link rel="canonical" href="https:\/\/www\.youtube\.com\/channel\/(UC[A-Za-z0-9_-]{22})"/',
        '/<meta itemprop="identifier" content="(UC[A-Za-z0-9_-]{22})"/',
        '/"externalId":"(UC[A-Za-z0-9_-]{22})"/',
        '/"browseId":"(UC[A-Za-z0-9_-]{22})"/',
    ];
    foreach ($rx as $r) {
        if (preg_match($r, $html, $m)) return $m[1];
    }
    return null;
}

function jsonString(string $raw): string
{
    $v = json_decode('"' . $raw . '"');
    return is_string($v) ? $v : $raw;
}

/** Videos on YouTube's results page (the page embeds its data as JSON; no API key needed). */
function parseVideoSearch(string $page, int $max = 30): array
{
    $out = [];
    $seen = [];
    preg_match_all('/"videoRenderer":\{"videoId":"([A-Za-z0-9_-]{11})"/', $page, $ms, PREG_OFFSET_CAPTURE);
    foreach ($ms[1] as $i => [$id]) {
        if (count($out) >= $max) break;
        if (isset($seen[$id])) continue;
        $chunk = substr($page, $ms[0][$i][1], 8000);
        if (!preg_match('/"title":\{"runs":\[\{"text":"((?:[^"\\\\]|\\\\.)*)"/', $chunk, $title)
            && !preg_match('/"title":\{"simpleText":"((?:[^"\\\\]|\\\\.)*)"/', $chunk, $title)) continue;
        $owner = preg_match(
            '/"(?:ownerText|longBylineText)":\{"runs":\[\{"text":"((?:[^"\\\\]|\\\\.)*)"[\s\S]{0,600}?"browseId":"(UC[A-Za-z0-9_-]{22})"/',
            $chunk,
            $o,
        ) ? $o : null;
        $length = preg_match('/"lengthText":\{[\s\S]{0,400}?"simpleText":"([0-9:]+)"/', $chunk, $l) ? $l[1] : null;
        $seen[$id] = true;
        $out[] = [
            'ref' => $id,
            'title' => jsonString($title[1]),
            'channel' => $owner ? jsonString($owner[1]) : null,
            'channelId' => $owner ? $owner[2] : null,
            'duration' => $length,
        ];
    }
    return $out;
}

/** Videos tab of a channel page (newest first), "lockupViewModel" layout; used when the public feeds fail. */
function parseChannelVideos(string $page, int $max = 30): array
{
    $out = [];
    $seen = [];
    preg_match_all(
        '/"lockupViewModel":\{"contentImage":\{"thumbnailViewModel":\{"image":\{"sources":\[\{"url":"https:\/\/i\.ytimg\.com\/vi\/([A-Za-z0-9_-]{11})\//',
        $page,
        $ms,
        PREG_OFFSET_CAPTURE,
    );
    foreach ($ms[1] as $i => [$id]) {
        if (count($out) >= $max) break;
        if (isset($seen[$id])) continue;
        if (!preg_match('/"title":\{"content":"((?:[^"\\\\]|\\\\.)*)"/', substr($page, $ms[0][$i][1], 12000), $t)) continue;
        $seen[$id] = true;
        $out[] = ['ref' => $id, 'title' => jsonString($t[1]), 'published' => null];
    }
    return $out;
}

/** Each channel newest first, then one per channel in turn; duplicates dropped. */
function mix(array $perSource): array
{
    $queues = [];
    foreach ($perSource as $q) {
        if (!$q) continue;
        usort($q, fn($a, $b) => strcmp($b['published'] ?? '', $a['published'] ?? ''));
        $queues[] = $q;
    }
    $longest = $queues ? max(array_map('count', $queues)) : 0;
    $seen = [];
    $out = [];
    for ($i = 0; $i < $longest; $i++) {
        foreach ($queues as $q) {
            $r = $q[$i] ?? null;
            if ($r && !isset($seen[$r['id']])) {
                $seen[$r['id']] = true;
                $out[] = $r;
            }
        }
    }
    return $out;
}

/** Fetches several URLs at once; each value is the body, or null when unreachable / not 200. */
function getMany(array $urls): array
{
    $out = [];
    if (!$urls) return $out;
    $mh = curl_multi_init();
    $handles = [];
    foreach ($urls as $key => $url) {
        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_MAXREDIRS => 4,
            CURLOPT_CONNECTTIMEOUT => 6,
            CURLOPT_TIMEOUT => 10,
            CURLOPT_ENCODING => '',
            CURLOPT_HTTPHEADER => ['User-Agent: Mozilla/5.0 (rattil-videos)', 'Accept-Language: ar,en;q=0.8'],
            // YouTube's consent page would hide the results; this cookie says "already answered".
            CURLOPT_COOKIE => 'CONSENT=YES+1; SOCS=CAI',
        ]);
        curl_multi_add_handle($mh, $ch);
        $handles[$key] = $ch;
    }
    do {
        $status = curl_multi_exec($mh, $running);
        if ($running) curl_multi_select($mh, 1.0);
    } while ($running && $status === CURLM_OK);
    foreach ($handles as $key => $ch) {
        $body = curl_multi_getcontent($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $out[$key] = ($code === 200 && is_string($body)) ? substr($body, 0, 3000000) : null;
        curl_multi_remove_handle($mh, $ch);
        curl_close($ch);
    }
    curl_multi_close($mh);
    return $out;
}

function toReel(array $src, array $r): array
{
    return [
        'id' => 'yt-' . $r['ref'],
        'platform' => 'youtube',
        'ref' => $r['ref'],
        'url' => 'https://www.youtube.com/watch?v=' . $r['ref'],
        'title' => ['ar' => $r['title'], 'en' => $r['title']],
        'speaker' => $src['name'],
        'category' => $src['category'],
        'source' => null,
        'status' => 'auto',
        'reviewer' => null,
        'reviewedAt' => null,
        'sourceId' => $src['id'],
        'published' => $r['published'] ?? null,
    ];
}

/** GET /api/v1/reels/feed. $get = fn(array $urls): array (see getMany), so tests can feed saved pages. */
function buildFeed(array $sources, callable $get): array
{
    // 1. Channel ids (sources listed by @handle are looked up on their channel page).
    $cids = [];
    $handles = [];
    foreach ($sources as $k => $s) {
        if (!empty($s['channelId'])) $cids[$k] = $s['channelId'];
        elseif (!empty($s['handle'])) $handles[$k] = handlePage($s['handle']);
    }
    foreach ($get($handles) as $k => $page) {
        $cid = $page ? channelIdFromPage($page) : null;
        if ($cid) $cids[$k] = $cid;
    }
    $cids = array_filter($cids, fn($c) => (bool) preg_match(CHANNEL_ID, $c));

    // 2. Shorts first; else the channel feed (Shorts entries, else every upload); else the channel's videos page.
    $items = [];
    $todo = [];
    foreach ($get(array_map('shortsFeed', $cids)) as $k => $xml) {
        $list = $xml ? parseFeed($xml) : [];
        if ($list) $items[$k] = $list;
        else $todo[$k] = $cids[$k];
    }
    $next = [];
    foreach ($get(array_map('channelFeed', $todo)) as $k => $xml) {
        $list = [];
        if ($xml !== null) $list = parseFeed($xml, true) ?: parseFeed($xml);
        if ($list) $items[$k] = $list;
        else $next[$k] = $todo[$k];
    }
    foreach ($get(array_map('channelVideosPage', $next)) as $k => $page) {
        if ($page !== null) $items[$k] = parseChannelVideos($page);
    }

    $lists = [];
    foreach ($sources as $k => $s) {
        $lists[] = array_map(fn($r) => toReel($s, $r), array_slice($items[$k] ?? [], 0, PER_SOURCE));
    }
    return [
        'schema' => 'reels-feed.v1',
        'sources' => array_map(
            fn($s) => array_intersect_key($s, array_flip(['id', 'channelId', 'handle', 'name', 'category'])),
            $sources,
        ),
        'items' => mix($lists),
    ];
}

/** GET /api/videos/search?q=…: Islamic videos only (see allowedVideo); trusted channels first. */
function searchVideos(string $query, callable $get, array $trusted): array
{
    $q = mb_substr(trim($query), 0, 120, 'UTF-8');
    if ($q === '' || isBlocked($q)) return ['schema' => 'video-search.v1', 'query' => $q, 'items' => []];
    $page = $get(['s' => searchPage($q)])['s'] ?? null;
    if ($page === null) throw new RuntimeException('youtube unreachable');
    $hits = array_values(array_filter(parseVideoSearch($page), fn($h) => allowedVideo($h, $trusted)));
    $rank = fn($h) => ($h['channelId'] && isset($trusted[$h['channelId']])) ? 0 : 1;
    // Stable sort: trusted first, otherwise YouTube's order.
    $indexed = array_map(null, $hits, array_keys($hits));
    usort($indexed, fn($a, $b) => [$rank($a[0]), $a[1]] <=> [$rank($b[0]), $b[1]]);
    return [
        'schema' => 'video-search.v1',
        'query' => $q,
        'items' => array_map(fn($p) => $p[0] + ['trusted' => $rank($p[0]) === 0], $indexed),
    ];
}

// ---------------------------------------------------------------------------------------------------------------
// HTTP entry point (skipped when a test includes this file).

function cacheFile(string $key): string
{
    $dir = __DIR__ . '/cache';
    if (!is_dir($dir)) @mkdir($dir, 0755, true);
    return $dir . '/' . sha1($key) . '.json';
}

/** Cached value when fresh; otherwise make a new one (kept only when $keep says so); stale copy if making fails. */
function cached(string $key, int $ttl, callable $make, callable $keep): array
{
    $file = cacheFile($key);
    $old = is_file($file) ? json_decode((string) @file_get_contents($file), true) : null;
    if (is_array($old) && time() - (int) @filemtime($file) < $ttl) return $old;
    try {
        $value = $make();
    } catch (Throwable $e) {
        if (is_array($old)) return $old;
        throw $e;
    }
    if ($keep($value)) {
        @file_put_contents($file, json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES), LOCK_EX);
    } elseif (is_array($old)) {
        return $old;
    }
    return $value;
}

function send(array $body, int $status, int $seconds): void
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: ' . ($status === 200 ? 'public, max-age=' . min($seconds, 600) : 'no-store'));
    header('X-Content-Type-Options: nosniff');
    echo json_encode($body, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}

if (realpath($_SERVER['SCRIPT_FILENAME'] ?? '') === __FILE__) {
    @set_time_limit(60);
    if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'GET') {
        send(['error' => 'method'], 405, 0);
        exit;
    }
    $sources = json_decode((string) @file_get_contents(__DIR__ . '/reel-sources.json'), true) ?: [];
    $feedSources = $sources['feed'] ?? [];
    $route = $_GET['route'] ?? '';
    try {
        if ($route === 'feed') {
            $body = cached('feed', FEED_TTL, fn() => buildFeed($feedSources, 'getMany'), fn($b) => count($b['items']) > 0);
            send($body, 200, FEED_TTL);
        } elseif ($route === 'search') {
            $q = is_string($_GET['q'] ?? null) ? $_GET['q'] : '';
            $trusted = [];
            foreach (array_merge($feedSources, $sources['suggested'] ?? []) as $s) {
                if (!empty($s['channelId'])) $trusted[$s['channelId']] = true;
            }
            $key = 'q:' . mb_strtolower(trim($q), 'UTF-8');
            send(cached($key, SEARCH_TTL, fn() => searchVideos($q, 'getMany', $trusted), fn() => true), 200, SEARCH_TTL);
        } else {
            send(['error' => 'not found'], 404, 0);
        }
    } catch (Throwable $e) {
        send(['error' => 'unreachable'], 502, 0);
    }
}

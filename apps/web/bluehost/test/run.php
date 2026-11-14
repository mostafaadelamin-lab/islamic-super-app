<?php
require $argv[1];
$sources = json_decode(file_get_contents("reel-sources.json"), true);
$one = function($u) {
  if (str_contains($u,"results")) return file_get_contents("search.html");
  if (str_contains($u,"/@")) return file_get_contents("handle.html");
  if (str_contains($u,"playlist_id=UUSHYu")) return file_get_contents("feed.xml");
  if (str_contains($u,"channel_id=")) return str_contains($u,"UCbbb") ? str_replace("shorts","watch",file_get_contents("feed.xml")) : null;
  if (str_contains($u,"/videos?")) return file_get_contents("chan.html");
  return null;
};
$get = fn($urls) => array_map($one, $urls);
$trusted = [];
foreach (array_merge($sources['feed'], $sources['suggested']) as $s) if (!empty($s['channelId'])) $trusted[$s['channelId']] = true;
$out = ['feed' => buildFeed($sources['feed'], $get)];
foreach (["قرآن","اغنية","  ","test"] as $q) $out["q$q"] = searchVideos($q, $get, $trusted);
$out['ch'] = [channelReels('UCYuUcfXvsHapABTcPRWCEoQ', $get), channelReels('bad', $get)];
$out['cs'] = searchChannels('قرآن', $get);
$out['norm'] = array_map('normalize', ["القُرْآنُ الكريمـ", "إيمانٌ ةى"]);
echo json_encode($out, JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);

/// Nasheeds and adhkar recordings played from the artists' own official
/// YouTube channels through YouTube's embedded player (nothing is copied or
/// downloaded). Every nasheed was picked as a voice-only version; the owner
/// listen-checks them. Channel ids and video ids were checked on 2026-11-10
/// (all embeddable). Sources: docs/CONTENT_SOURCES.md.
library;

class MediaItem {
  const MediaItem(this.videoId, this.titleAr, [this.titleEn]);
  final String videoId;
  final String titleAr;
  final String? titleEn;

  static final idPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');
}

enum MunshidRegion { egypt, arab }

class Munshid {
  const Munshid({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.region,
    required this.channelId,
    required this.items,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final MunshidRegion region;

  /// The official (or label-run) channel every item comes from.
  final String channelId;
  final List<MediaItem> items;
}

const munshidin = <Munshid>[
  Munshid(
    id: 'mohamed-tarek',
    nameAr: 'محمد طارق',
    nameEn: 'Mohamed Tarek',
    region: MunshidRegion.egypt,
    channelId: 'UCPp0_tTnE3DUJmUmcLMfOyg',
    items: [
      MediaItem('jglgBhl9zI0', 'صلّ يا ربّ وسلّم'),
      MediaItem('faO7FNKSjO4', 'نبيٌّ بالهدى'),
      MediaItem('HQopReLRmOY', 'الصبح بدا من طلعته'),
      MediaItem('KFdyC6Sxu4A', 'حبيبي حبيبي'),
      MediaItem('XVc1YJJMk5c', 'رمضان يا رمضان'),
      MediaItem('wDg_ef0Rn48', 'رمضان جئت'),
    ],
  ),
  Munshid(
    id: 'mohamed-youssef',
    nameAr: 'محمد يوسف',
    nameEn: 'Mohamed Youssef',
    region: MunshidRegion.egypt,
    channelId: 'UCeHKDFxsQXWxCYO-EXeBl_A',
    items: [
      MediaItem('MsATC6IJv5M', 'تسمعني رباه'),
      MediaItem('T9ihKBIvFSc', 'هدي القرآن'),
      MediaItem('XVPDf92bkZ0', 'يا ربّ العالمين'),
      MediaItem('vN-UwsYMAzI', 'سبحان الله'),
      MediaItem('r6-d3Ul_NYo', 'يا رسول الله'),
      MediaItem('3l1s7LXFntE', 'أنت حبيبي'),
      MediaItem('LiU8Xz2ABug', 'الهجرة'),
      MediaItem('k-wFsH4c_Fw', 'مكة'),
      MediaItem('cb8_XWyyNSs', 'لاح الفجر'),
      MediaItem('AmnXOwjMWKg', 'أمي'),
    ],
  ),
  Munshid(
    id: 'tobar',
    nameAr: 'الشيخ نصر الدين طوبار',
    nameEn: 'Sheikh Nasr el-Din Tobar',
    region: MunshidRegion.egypt,
    channelId: 'UCM8T0Re5FfFnYEvQOfTQHOw',
    items: [
      MediaItem('xh06O11EKrI', 'هو الله'),
      MediaItem('B2V1BtiCvBY', 'مالك الملك'),
      MediaItem('kmI8kUy2F3k', 'يا مالك الملك أنت المستجار به'),
      MediaItem('a6oKg1pXujI', 'يا من هداه أضاء كل مكان'),
      MediaItem('vdxMWnIKO4w', 'عدت إلى رحابك تائبًا'),
      MediaItem('h4Kpe6NdM2Y', 'لا إله إلا الله'),
      MediaItem('Vv3UtaFlDUA', 'يا ربّ'),
    ],
  ),
  Munshid(
    id: 'naqshbandi',
    nameAr: 'الشيخ سيد النقشبندي',
    nameEn: 'Sheikh Sayed al-Naqshbandi',
    region: MunshidRegion.egypt,
    channelId: 'UCurG_RKCM6Cg1doqYa2mp4A',
    items: [
      MediaItem('w8bpAZGAGps', 'قصدتك من كل الجهات'),
      MediaItem('7UJkxTYMW4g', 'عالم أنت بحالي'),
      MediaItem('ARC3LdIjLLw', 'إلهي هو الخالق الواحد'),
    ],
  ),
  Munshid(
    id: 'alafasy',
    nameAr: 'مشاري راشد العفاسي',
    nameEn: 'Mishary Rashid Alafasy',
    region: MunshidRegion.arab,
    channelId: 'UCzuEc6pl59Z-lADI3ceQK1w',
    items: [
      MediaItem('YSCKKNTZr3w', 'أراك مليكي'),
      MediaItem('C5XX9-6QV9E', 'لا إله إلا الله'),
      MediaItem('6oYxPo30Hm0', 'بك نلتجي'),
      MediaItem('z7OiTpznjKc', 'رحماك يا ربّ السماء'),
      MediaItem('qbbTMu91qoU', 'جهرًا دعوتك'),
      MediaItem('sYSXkKtMUFk', 'صلّوا عليه وسلّموا'),
      MediaItem('IDLB2p9H4pM', 'الصلاة على النبي ﷺ'),
      MediaItem('olbeCLfiQJE', 'إذا كنت في نعمة فارعها'),
    ],
  ),
  Munshid(
    id: 'bukhatir',
    nameAr: 'أحمد بوخاطر',
    nameEn: 'Ahmed Bukhatir',
    region: MunshidRegion.arab,
    channelId: 'UC-2pqFUafqKCnACEfQasZGg',
    items: [
      MediaItem('r3NFwDRsS3Y', 'يا من يرى'),
      MediaItem('cV2RFv9EsbI', 'شكرًا لك ربي'),
      MediaItem('RWNXTSUChTo', 'قرآني'),
      MediaItem('Tzywwlcialg', 'طال شوقي'),
      MediaItem('1vGA1UIWMQ4', 'صدقات'),
      MediaItem('4etkgtraTIw', 'كيف أنزعه'),
      MediaItem('xIZtunlWEjc', 'لسوف أعود يا أمي'),
    ],
  ),
  Munshid(
    id: 'abu-ali',
    nameAr: 'أبو علي (موسى العميرة)',
    nameEn: 'Abu Ali (Mosa Alomairah)',
    region: MunshidRegion.arab,
    channelId: 'UCQQCG2_xVTC6CYwobudUTLQ',
    items: [
      MediaItem('sJ256vazSBY', 'سبحانه'),
      MediaItem('U5n9WZFUNnI', 'حتى أحبه'),
      MediaItem('TIU7awg6c2E', 'فيض معين'),
      MediaItem('_ldSKMEKTo4', 'يا طالب العلم صبرًا'),
      MediaItem('z7QPk5d_KxQ', 'عطاء أمي'),
      MediaItem('3l99fgMdBEU', 'أهلًا يا رمضان'),
    ],
  ),
  Munshid(
    id: 'muqit',
    nameAr: 'محمد المقيط',
    nameEn: 'Muhammad Al Muqit',
    region: MunshidRegion.arab,
    channelId: 'UCheBIbE_7Trrhatjt9LIteQ',
    items: [
      MediaItem('mjmxu6zYaBM', 'إلى ربي'),
      MediaItem('ZR92k-hBdn0', 'سيد الشفعاء'),
      MediaItem('Bhv8pTuVKjk', 'يا بارئ لطفك يشملنا'),
      MediaItem('zgr1LbxBuwQ', 'سماء الإحسان'),
      MediaItem('_Oi3pfslWN0', 'أمتي فاستبشري'),
      MediaItem('vetv8XIz_IM', 'الخلفاء الراشدون'),
    ],
  ),
];

/// Mishary Rashid Alafasy's adhkar from his official channel (UCmMcOjsVehVlEOteyrhjI2Q).
enum AdhkarAudio { morning, evening, afterPrayer, sleep }

const alafasyAdhkarChannel = 'UCmMcOjsVehVlEOteyrhjI2Q';

const adhkarAudioVideo = <AdhkarAudio, String>{
  AdhkarAudio.morning: 'V2Brp_esIVI',
  AdhkarAudio.evening: 'TGtdZmxsM5Q',
  AdhkarAudio.afterPrayer: 'BQxnb6DzyzI',
  AdhkarAudio.sleep: '5HmvokzY3Jg',
};

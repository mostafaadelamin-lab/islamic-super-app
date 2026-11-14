/// Live crowd levels at Masjid al-Haram (owner, 2026-11-14). The app never shows crowd numbers of its
/// own: the official sources publish them and offer no public data feed, so we only open them.
/// Same links as the website: apps/web/src/lib/haram-crowd.ts.
abstract final class HaramCrowdLinks {
  /// General Authority for the Care of the Two Holy Mosques: live Mataf / Mas'a crowd density (SPA, 2025-06-05).
  static final official = Uri.parse('https://alharamain.gov.sa/public/?module=module_794625');

  /// Nusuk, the official Hajj and Umrah platform (its app shows tawaf and sa'i occupancy).
  static final nusuk = Uri.parse('https://www.nusuk.sa/');
}

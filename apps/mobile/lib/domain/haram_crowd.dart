/// Live crowd levels at Masjid al-Haram (owner, 2026-11-14). The app never shows crowd numbers of its
/// own: the official sources publish them and offer no public data feed, so we only open them.
/// Same links as the website: apps/web/src/lib/haram-crowd.ts.
abstract final class HaramCrowdLinks {
  /// Hidden for now (owner 2026-11-15): no public live feed of the Mataf / Mas'a crowd levels was found, so
  /// the crowd card stays out of the app and the website until one is. Set to true to show the links again.
  static const visible = false;

  /// General Authority for the Care of the Two Holy Mosques: live Mataf / Mas'a crowd density (SPA, 2025-06-05).
  static final official = Uri.parse('https://alharamain.gov.sa/public/?module=module_794625');

  /// Nusuk, the official Hajj and Umrah platform (its app shows tawaf and sa'i occupancy).
  static final nusuk = Uri.parse('https://www.nusuk.sa/');
}

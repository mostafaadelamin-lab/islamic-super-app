import 'package:flutter/material.dart';

import 'quran_index.dart';

/// Opens the Quran index (الفهرس) from the Mushaf reader's bottom bar, scrolled
/// to the current page's surah/quarter. Returns the page the reader chose.
Future<int?> showQuranIndex(BuildContext context, {int? currentPage}) =>
    showQuranIndexSheet(context, currentPage: currentPage);

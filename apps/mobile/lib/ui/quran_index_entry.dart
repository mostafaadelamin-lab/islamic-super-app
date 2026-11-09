import 'package:flutter/material.dart';

import 'surah_list_screen.dart';

/// Opens the Quran index (الفهرس) from the Mushaf reader's bottom bar.
/// The "Redesign Quran index" work replaces this body with its index sheet
/// (showQuranIndexSheet); until then it opens the surah list.
Future<void> showQuranIndex(BuildContext context, {int? currentPage}) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SurahListScreen()));

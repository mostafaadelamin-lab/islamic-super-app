import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/quran.dart';
import 'l10n_ext.dart';
import 'widgets.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.navBookmarks)),
      body: ListenableBuilder(
        listenable: s.bookmarks,
        builder: (context, _) {
          final items = s.bookmarks.active;
          return ListView(
            key: const Key('bookmarkList'),
            children: [
              const ContinueReadingTile(),
              const Divider(),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text(l.bookmarksEmpty, key: const Key('bookmarksEmpty'))),
                ),
              for (final b in items)
                Builder(
                  builder: (context) {
                    final ref = AyahRef(b.surah, b.ayah);
                    final valid = s.content.quran.isValid(ref);
                    final label = ayahLabel(context, ref);
                    return ListTile(
                      key: Key('bm-${b.id}'),
                      leading: const Icon(Icons.bookmark),
                      title: Text(label),
                      subtitle: valid ? QuranText(s.content.quran.text(ref), size: 20, maxLines: 2) : null,
                      onTap: valid ? () => openSurah(context, b.surah, ayah: b.ayah) : null,
                      trailing: IconButton(
                        key: Key('bmDelete-${b.id}'),
                        tooltip: l.bookmarksDelete(label),
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => s.bookmarks.remove(b.id),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

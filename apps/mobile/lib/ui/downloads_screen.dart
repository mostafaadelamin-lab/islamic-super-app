import 'package:flutter/material.dart';

import '../app_services.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'widgets.dart';
import 'adaptive.dart';

/// Recitations saved on the device: download a surah for the chosen reciter,
/// see how much space they use, delete one or all.
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  Future<({Set<int> done, int bytes})>? _info;
  String? _error;

  Future<({Set<int> done, int bytes})> _load() async {
    final s = context.services;
    final folder = s.recitation.reciter.folder;
    final list = await s.downloads.list();
    return (
      done: {
        for (final e in list)
          if (e.reciter == folder) e.surah,
      },
      bytes: await s.downloads.totalBytes(),
    );
  }

  void _refresh() {
    final f = _load();
    setState(() {
      _info = f;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _info ??= _load();
  }

  String _size(int bytes) {
    final mb = bytes / (1024 * 1024);
    return context.num(mb < 10 ? mb.toStringAsFixed(1) : mb.round().toString());
  }

  Future<void> _download(int surah) async {
    final s = context.services;
    setState(() => _error = null);
    try {
      await s.downloads.downloadSurah(s.recitation.reciter.folder, surah);
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.downloadsFailed);
    }
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.services;
    final reciter = s.recitation.reciter;
    return Scaffold(
      appBar: AppBar(title: Text(l.downloadsTitle)),
      body: ReadableWidth(
        child: ListenableBuilder(
          listenable: s.downloads,
          builder: (context, _) => FutureBuilder(
            future: _info,
            builder: (context, snap) {
              final info = snap.data;
              return ListView(
                key: const Key('downloadsList'),
                padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
                children: [
                  ListTile(
                    title: Text(l.downloadsReciter(reciter.name(context.isArabic))),
                    subtitle: Text(
                      info == null ? '…' : l.downloadsUsed(_size(info.bytes)),
                      key: const Key('downloadsUsed'),
                    ),
                    trailing: info != null && info.bytes > 0
                        ? TextButton(
                            key: const Key('downloadsDeleteAll'),
                            onPressed: () async {
                              await s.downloads.deleteAll();
                              _refresh();
                            },
                            child: Text(l.downloadsDeleteAll),
                          )
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
                    child: Text(l.downloadsNote, style: Theme.of(context).textTheme.bodySmall),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(DesignTokens.spaceLg),
                      child: Text(
                        _error!,
                        key: const Key('downloadsError'),
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  const Divider(),
                  for (final surah in s.content.quran.surahs)
                    () {
                      final n = surah.n;
                      final busy = s.downloads.progress['${reciter.folder}/$n'];
                      final done = info?.done.contains(n) ?? false;
                      return ListTile(
                        key: Key('download-$n'),
                        title: Text(surahName(context, surah)),
                        subtitle: busy != null
                            ? LinearProgressIndicator(value: busy)
                            : Text(l.quranAyahCount(context.num(surah.ayahCount))),
                        trailing: busy != null
                            ? IconButton(
                                tooltip: l.downloadsCancel,
                                icon: const Icon(Icons.close),
                                onPressed: () => s.downloads.cancel(reciter.folder, n),
                              )
                            : done
                            ? IconButton(
                                key: Key('downloadDelete-$n'),
                                tooltip: l.downloadsDelete,
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await s.downloads.deleteSurah(reciter.folder, n);
                                  _refresh();
                                },
                              )
                            : IconButton(
                                key: Key('downloadStart-$n'),
                                tooltip: l.downloadsDownload,
                                icon: const Icon(Icons.download_outlined),
                                onPressed: () => _download(n),
                              ),
                      );
                    }(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

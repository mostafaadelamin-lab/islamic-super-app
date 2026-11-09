import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_services.dart';
import '../data/mosques.dart';
import '../domain/mosques.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'prayer_model.dart';

/// Nearby mosques from OpenStreetMap around the prayer city, nearest first.
/// Tapping a mosque opens directions in the phone's maps app.
class MosquesScreen extends StatefulWidget {
  const MosquesScreen({super.key, this.client});

  /// For tests; the app uses a plain http client.
  final http.Client? client;

  @override
  State<MosquesScreen> createState() => _MosquesScreenState();
}

class _MosquesScreenState extends State<MosquesScreen> {
  late final http.Client _client = widget.client ?? http.Client();
  int _radius = defaultMosqueRadius;
  MosqueResult? _result;
  bool _loading = false;
  bool _error = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _search();
  }

  @override
  void dispose() {
    if (widget.client == null) _client.close();
    super.dispose();
  }

  Future<void> _search() async {
    final city = PrayerView.compute(context.services).city;
    final arabic = context.isArabic;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final finder = MosqueFinder(_client, await SharedPreferences.getInstance());
      final r = await finder.find(city.lat, city.lng, _radius, arabic: arabic);
      if (mounted) setState(() => _result = r);
    } catch (_) {
      if (mounted) {
        setState(() {
          _result = null;
          _error = true;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _distance(BuildContext context, double m) => m < 1000
      ? context.l10n.mosquesMeters(context.num(m.round()))
      : context.l10n.mosquesKm(context.num((m / 1000).toStringAsFixed(1)));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final city = PrayerView.compute(context.services).city;
    final r = _result;
    return Scaffold(
      appBar: AppBar(title: Text(l.mosquesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.spaceLg),
        children: [
          Text(l.mosquesAround(city.name(context.isArabic)), style: theme.textTheme.titleMedium),
          const SizedBox(height: DesignTokens.spaceSm),
          Wrap(
            spacing: DesignTokens.spaceSm,
            children: [
              for (final rad in mosqueRadii)
                ChoiceChip(
                  key: Key('mosquesRadius-$rad'),
                  label: Text(_distance(context, rad.toDouble())),
                  selected: _radius == rad,
                  onSelected: (_) {
                    if (_radius == rad) return;
                    setState(() => _radius = rad);
                    _search();
                  },
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceMd),
          if (_loading)
            Row(
              key: const Key('mosquesLoading'),
              children: [
                const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: DesignTokens.spaceSm),
                Text(l.mosquesLoading),
              ],
            )
          else if (_error) ...[
            Text(l.mosquesError, key: const Key('mosquesError')),
            const SizedBox(height: DesignTokens.spaceSm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton(key: const Key('mosquesRetry'), onPressed: _search, child: Text(l.mosquesRetry)),
            ),
          ] else if (r != null) ...[
            Text(
              r.mosques.isEmpty
                  ? l.mosquesNone
                  : '${l.mosquesCount(context.num(r.mosques.length))}${r.offline ? ' ${l.mosquesOffline}' : ''}',
              key: const Key('mosquesStatus'),
              style: theme.textTheme.bodySmall,
            ),
            for (final m in r.mosques)
              ListTile(
                key: Key('mosque-${m.id}'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.mosque_outlined),
                title: Text(m.name ?? l.mosquesUnnamed),
                trailing: Text(_distance(context, m.distance)),
                onTap: () => launchUrl(
                  directionsUri(m, ios: defaultTargetPlatform == TargetPlatform.iOS),
                  mode: LaunchMode.externalApplication,
                ),
              ),
          ],
          const SizedBox(height: DesignTokens.spaceLg),
          Text('${l.mosquesNote} © OpenStreetMap contributors', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_services.dart';
import '../data/location.dart';
import '../data/mosques.dart';
import '../domain/mosques.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'prayer_model.dart';
import 'adaptive.dart';
import 'r_icon.dart';

/// Nearby mosques from OpenStreetMap around the device position, nearest
/// first; around the prayer city only when the position is not available.
/// Tapping a mosque opens it in Google Maps.
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

  /// Device position for this visit; null = not asked yet or not available.
  ({double lat, double lng})? _here;
  bool _locating = false;
  bool _geoFailed = false;
  bool _loading = false;
  bool _error = false;
  bool _started = false;

  /// Quick list shown while the fuller search is still running.
  MosqueResult? _early;

  /// Nothing within the chosen distance on the first search: the screen moved
  /// to the next one by itself; this is the distance it started from.
  int? _widenedFrom;

  /// Each search has a number, so an older, slower answer never replaces a newer one.
  int _searchId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _locateAndSearch();
  }

  /// Asks the device where it is, then searches around that point.
  Future<void> _locateAndSearch() async {
    setState(() {
      _locating = true;
      _geoFailed = false;
    });
    final r = await context.services.location.current(precise: true);
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (r case LocationFound(:final lat, :final lng)) {
        _here = (lat: lat, lng: lng);
      } else {
        _geoFailed = _here == null;
      }
    });
    await _search(widen: true);
  }

  @override
  void dispose() {
    if (widget.client == null) _client.close();
    super.dispose();
  }

  /// With [widen], an empty answer moves on to the next distance by itself,
  /// so the nearest mosques always show (owner 2026-11-24).
  Future<void> _search({bool widen = false, int? from}) async {
    final city = PrayerView.compute(context.services).city;
    final lat = _here?.lat ?? city.lat;
    final lng = _here?.lng ?? city.lng;
    final arabic = context.isArabic;
    final id = ++_searchId;
    setState(() {
      _loading = true;
      _error = false;
      _early = null;
      _widenedFrom = from;
    });
    try {
      final finder = MosqueFinder(_client, await SharedPreferences.getInstance());
      final r = await finder.find(
        lat,
        lng,
        _radius,
        arabic: arabic,
        onEarly: (e) {
          if (mounted && id == _searchId) setState(() => _early = e);
        },
      );
      if (!mounted || id != _searchId) return;
      final next = mosqueRadii.where((x) => x > _radius).firstOrNull;
      if (widen && r.mosques.isEmpty && !r.offline && next != null) {
        final start = from ?? _radius;
        setState(() => _radius = next);
        await _search(widen: true, from: start);
        return;
      }
      setState(() => _result = r);
    } catch (_) {
      if (mounted && id == _searchId) {
        setState(() {
          _result = null;
          _error = true;
        });
      }
    } finally {
      if (mounted && id == _searchId) {
        setState(() {
          _loading = false;
          _early = null;
        });
      }
    }
  }

  String _distance(BuildContext context, double m) => m < 1000
      ? context.l10n.mosquesMeters(context.num(m.round()))
      : context.l10n.mosquesKm(context.num((m / 1000).toStringAsFixed(1)));

  /// «٥٠٠ م»، «١ كم»، «٢ كم» (no «٢٫٠»).
  String _radiusLabel(BuildContext context, int m) =>
      m < 1000 ? context.l10n.mosquesMeters(context.num(m)) : context.l10n.mosquesKm(context.num(m ~/ 1000));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final city = PrayerView.compute(context.services).city;
    // While searching, the quick list (if any) is shown instead of a bare spinner.
    final r = _loading ? _early : _result;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.mosquesTitle),
        actions: [
          // Labelled, not a bare arrow (owner 2026-11-24: the corner icon was not clear).
          Padding(
            padding: const EdgeInsetsDirectional.only(end: DesignTokens.spaceSm),
            child: OutlinedButton.icon(
              key: const Key('mosquesGoogleMaps'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: theme.colorScheme.primary),
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceSm),
              ),
              icon: const RIcon(RIcons.location, size: 18),
              label: Text(l.mosquesGoogleMapsShort, style: const TextStyle(fontWeight: FontWeight.w600)),
              onPressed: () => launchUrl(
                googleMapsNearbyUri(_here?.lat ?? city.lat, _here?.lng ?? city.lng, arabic: context.isArabic),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ),
        ],
      ),
      body: ReadableWidth(
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          children: [
            // The fullest list (with photos and ratings) is Google's own: one big button to it, at the top
            // (owner 2026-11-20; showing Google's results inside the app would need the paid Places API).
            FilledButton.icon(
              key: const Key('mosquesGoogleMapsBig'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              icon: const RIcon(RIcons.location),
              label: Text(l.mosquesOnGoogleMaps),
              onPressed: () => launchUrl(
                googleMapsNearbyUri(_here?.lat ?? city.lat, _here?.lng ?? city.lng, arabic: context.isArabic),
                mode: LaunchMode.externalApplication,
              ),
            ),
            const SizedBox(height: DesignTokens.spaceLg),
            Text(
              l.mosquesAround(_here != null ? l.mosquesMyLocation : city.name(context.isArabic)),
              key: const Key('mosquesAround'),
              style: theme.textTheme.titleMedium,
            ),
            if (_geoFailed) ...[
              const SizedBox(height: DesignTokens.spaceXs),
              Text(l.mosquesGeoFallback, key: const Key('mosquesGeoFallback'), style: theme.textTheme.bodySmall),
            ],
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const Key('mosquesLocate'),
                onPressed: _locating || _loading ? null : _locateAndSearch,
                icon: const RIcon(RIcons.myLocation),
                label: Text(l.mosquesLocate),
              ),
            ),
            Wrap(
              spacing: DesignTokens.spaceSm,
              children: [
                for (final rad in mosqueRadii)
                  ChoiceChip(
                    key: Key('mosquesRadius-$rad'),
                    label: Text(_radiusLabel(context, rad)),
                    selected: _radius == rad,
                    onSelected: (_) {
                      if (_radius == rad || _locating) return;
                      setState(() => _radius = rad);
                      _search();
                    },
                  ),
              ],
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            if (_locating || (_loading && r == null))
              Row(
                key: const Key('mosquesLoading'),
                children: [
                  const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: DesignTokens.spaceSm),
                  Text(_locating ? l.mosquesLocating : l.mosquesLoading),
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
              if (_loading)
                // The quick list is already here; the fuller one is still coming.
                Row(
                  key: const Key('mosquesCompleting'),
                  children: [
                    const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: DesignTokens.spaceSm),
                    Expanded(child: Text(l.mosquesCompleting, style: theme.textTheme.bodySmall)),
                  ],
                )
              else ...[
                if (_widenedFrom != null && r.mosques.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.spaceXs),
                    child: Text(
                      l.mosquesWidened(_radiusLabel(context, _widenedFrom!), _radiusLabel(context, _radius)),
                      key: const Key('mosquesWidened'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                Text(
                  r.mosques.isEmpty
                      ? l.mosquesNone
                      : '${l.mosquesCount(context.num(r.mosques.length))}${r.offline ? ' ${l.mosquesOffline}' : ''}',
                  key: const Key('mosquesStatus'),
                  style: theme.textTheme.bodySmall,
                ),
              ],
              for (final m in r.mosques)
                Card(
                  key: Key('mosque-${m.id}'),
                  margin: const EdgeInsets.symmetric(vertical: DesignTokens.spaceXs),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: RIcon(RIcons.kaaba, color: theme.colorScheme.primary),
                    ),
                    title: Text(m.name ?? l.mosquesUnnamed),
                    subtitle: Text(_distance(context, m.distance)),
                    trailing: IconButton(
                      key: Key('mosqueMap-${m.id}'),
                      tooltip: l.mosquesOnGoogleMaps,
                      icon: const RIcon(RIcons.location),
                      onPressed: () => launchUrl(googleMapsMosqueUri(m), mode: LaunchMode.externalApplication),
                    ),
                    onTap: () => launchUrl(googleMapsMosqueUri(m), mode: LaunchMode.externalApplication),
                  ),
                ),
            ],
            if (r != null && !r.fromGoogle && r.mosques.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.spaceLg),
              // Required by the map data's licence (ODbL).
              Text('© OpenStreetMap contributors', key: const Key('mosquesCredit'), style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../app_services.dart';
import '../data/location.dart';
import '../domain/mosques.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'prayer_model.dart';
import 'r_icon.dart';

/// Replaced in widget tests, where a WebView cannot run.
@visibleForTesting
Widget Function(BuildContext context, Uri url)? debugMapBuilder;

/// Map zoom that shows about [radius] metres around the centre.
int mosqueZoom(int radius) => radius <= 2000 ? 15 : (radius <= 5000 ? 14 : 13);

/// Google Maps' mosque search around a point, as shown inside the app.
Uri googleMapsMosquesInApp(double lat, double lng, int radius, {required bool arabic}) => Uri.parse(
  'https://www.google.com/maps/search/${Uri.encodeComponent(arabic ? 'مسجد' : 'mosque')}/'
  '@${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)},${mosqueZoom(radius)}z?hl=${arabic ? 'ar' : 'en'}',
);

/// Google pages that may load inside the map view; anything else (app links,
/// other sites) opens outside the app.
bool mosqueMapNavigationAllowed(Uri u) {
  if (u.scheme == 'about' || u.scheme == 'data' || u.scheme == 'blob') return true;
  if (u.scheme != 'https') return false;
  final h = u.host;
  return h == 'www.google.com' || h == 'google.com' || h == 'maps.google.com' || h == 'consent.google.com' ||
      h.endsWith('.google.com') || h.endsWith('.gstatic.com') || h.endsWith('.googleapis.com');
}

/// Nearby mosques on Google Maps, inside the app, around the phone's position
/// (or the prayer city when the position is not available). Tapping a mosque
/// shows its details and directions in the same view.
class MosquesScreen extends StatefulWidget {
  const MosquesScreen({super.key});

  @override
  State<MosquesScreen> createState() => _MosquesScreenState();
}

class _MosquesScreenState extends State<MosquesScreen> {
  int _radius = defaultMosqueRadius;
  ({double lat, double lng})? _here;
  bool _locating = false;
  bool _geoFailed = false;
  bool _started = false;
  WebViewController? _web;
  Uri? _shown;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _locate();
  }

  Future<void> _locate() async {
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
    _load();
  }

  Uri _url() {
    final city = PrayerView.compute(context.services).city;
    return googleMapsMosquesInApp(_here?.lat ?? city.lat, _here?.lng ?? city.lng, _radius, arabic: context.isArabic);
  }

  void _load() {
    final u = _url();
    setState(() => _shown = u);
    if (debugMapBuilder != null) return;
    final c = _web ??= WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (req) {
            final x = Uri.tryParse(req.url);
            if (x != null && mosqueMapNavigationAllowed(x)) return NavigationDecision.navigate;
            if (x != null) launchUrl(x, mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          },
        ),
      );
    c.loadRequest(u);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final city = PrayerView.compute(context.services).city;
    final shown = _shown;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.mosquesTitle),
        actions: [
          IconButton(
            key: const Key('mosquesGoogleMaps'),
            tooltip: l.mosquesOnGoogleMaps,
            icon: const RIcon(RIcons.external),
            onPressed: shown == null ? null : () => launchUrl(shown, mode: LaunchMode.externalApplication),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceSm, DesignTokens.spaceLg, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.mosquesAround(_here != null ? l.mosquesMyLocation : city.name(context.isArabic)),
                    key: const Key('mosquesAround'),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (_locating)
                  const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  IconButton(
                    key: const Key('mosquesLocate'),
                    tooltip: l.mosquesLocate,
                    icon: const RIcon(RIcons.myLocation),
                    onPressed: _locate,
                  ),
              ],
            ),
          ),
          if (_geoFailed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
              child: Text(l.mosquesGeoFallback, key: const Key('mosquesGeoFallback'), style: theme.textTheme.bodySmall),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
            child: Wrap(
              spacing: DesignTokens.spaceSm,
              children: [
                for (final rad in mosqueRadii)
                  ChoiceChip(
                    key: Key('mosquesRadius-$rad'),
                    label: Text(l.mosquesKm(context.num((rad / 1000).toStringAsFixed(rad % 1000 == 0 ? 0 : 1)))),
                    selected: _radius == rad,
                    onSelected: (_) {
                      setState(() => _radius = rad);
                      if (!_locating) _load();
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: shown == null
                ? Center(
                    key: const Key('mosquesLoading'),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [const CircularProgressIndicator(), const SizedBox(height: DesignTokens.spaceSm), Text(l.mosquesLocating)],
                    ),
                  )
                : KeyedSubtree(
                    key: const Key('mosquesMap'),
                    child: debugMapBuilder?.call(context, shown) ?? WebViewWidget(controller: _web!),
                  ),
          ),
        ],
      ),
    );
  }
}

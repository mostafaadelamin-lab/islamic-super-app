import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Owner 2026-11-27: «المصادر والإثبات» and the privacy policy open inside the app (offline), not on the website.
/// The pages are the website's own files, bundled by tool/sync_assets.sh (assets/content/*.html), so the app and
/// the site always show the same text.
class InAppDocScreen extends StatefulWidget {
  const InAppDocScreen({super.key, required this.title, required this.asset, this.anchor});

  static const site = 'https://rattilwasalli.com/';
  static const sourcesAsset = 'assets/content/sources.html';
  static const privacyAsset = 'assets/content/privacy-policy.html';

  final String title;
  final String asset;
  final String? anchor;

  @override
  State<InAppDocScreen> createState() => _InAppDocScreenState();
}

enum DocLink { stay, back, external }

/// What a tap on a link inside the page does: anchors stay in the page, «رجوع للتطبيق» (/ar/) closes the screen,
/// anything else opens in the browser.
@visibleForTesting
DocLink docLinkAction(Uri u) {
  final base = Uri.parse(InAppDocScreen.site);
  if (u.scheme == 'about' || u.scheme == 'data') return DocLink.stay;
  if (u.host == base.host && (u.path == '/' || u.path.isEmpty)) return DocLink.stay;
  if (u.host == base.host && (u.path == '/ar/' || u.path == '/ar' || u.path == '/en/')) return DocLink.back;
  return DocLink.external;
}

class _InAppDocScreenState extends State<InAppDocScreen> {
  WebViewController? _c;

  @override
  void initState() {
    super.initState();
    if (WebViewPlatform.instance == null) return; // widget tests: no platform web view
    final c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (req) {
            final u = Uri.tryParse(req.url);
            if (u == null) return NavigationDecision.prevent;
            switch (docLinkAction(u)) {
              case DocLink.stay:
                return NavigationDecision.navigate;
              case DocLink.back:
                if (mounted) Navigator.of(context).maybePop();
              case DocLink.external:
                launchUrl(u, mode: LaunchMode.externalApplication);
            }
            return NavigationDecision.prevent;
          },
          onPageFinished: (_) {
            // The page's own «رجوع للتطبيق» bar is for the website; the app has its back arrow.
            _c?.runJavaScript(
              "document.querySelectorAll('header.back-bar,.back-end').forEach(e=>e.style.display='none');"
              "${widget.anchor == null ? '' : "document.getElementById('${widget.anchor}')?.scrollIntoView();"}",
            );
          },
        ),
      );
    _c = c;
    rootBundle.loadString(widget.asset).then((html) {
      if (mounted) c.loadHtmlString(html, baseUrl: InAppDocScreen.site);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    return Scaffold(
      key: const Key('inAppDoc'),
      appBar: AppBar(title: Text(widget.title)),
      body: c == null ? const SizedBox.shrink() : WebViewWidget(controller: c),
    );
  }
}

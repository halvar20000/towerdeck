import 'dart:math';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../widgets/common.dart';

/// Unraid ≥ 7.2 ships an "API Key Authorization" page: an app sends the user
/// to `/Tools/ApiKeyAuthorize`, the user logs in and approves, and the page
/// redirects to `redirect_uri?api_key=…&state=…`.
///
/// The page only accepts https or `http://localhost` redirect URIs, so we use
/// a localhost URL and intercept it inside the WebView before it loads.
class AuthorizeScreen extends StatefulWidget {
  const AuthorizeScreen({super.key, required this.baseUrl, required this.readOnly});

  final Uri baseUrl;
  final bool readOnly;

  /// Returns the created API key, or null if the user backed out.
  static Future<String?> open(BuildContext context, Uri baseUrl, {required bool readOnly}) =>
      Navigator.of(context).push<String>(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AuthorizeScreen(baseUrl: baseUrl, readOnly: readOnly),
      ));

  @override
  State<AuthorizeScreen> createState() => _AuthorizeScreenState();
}

const _callbackHost = 'localhost';
const _callbackPath = '/towerdeck-callback';

class _AuthorizeScreenState extends State<AuthorizeScreen> {
  late final String _state = _randomToken();
  late final WebViewController _controller;
  int _progress = 0;
  String? _error;

  static String _randomToken() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  @override
  void initState() {
    super.initState();
    // Key names may only contain letters, numbers and spaces; a suffix keeps
    // several devices from colliding.
    final suffix = Random().nextInt(9000) + 1000;
    final url = widget.baseUrl.replace(
      path: '/Tools/ApiKeyAuthorize',
      queryParameters: {
        'name': 'TowerDeck $suffix',
        'description': 'TowerDeck mobile app',
        'scopes': widget.readOnly ? 'role:viewer' : 'role:admin',
        'redirect_uri': 'http://$_callbackHost$_callbackPath',
        'state': _state,
      },
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => setState(() => _progress = p),
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri != null && uri.host == _callbackHost && uri.path == _callbackPath) {
            _handleCallback(uri);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onWebResourceError: (e) {
          if (e.isForMainFrame ?? true) setState(() => _error = e.description);
        },
      ))
      ..loadRequest(url);
  }

  void _handleCallback(Uri uri) {
    final key = uri.queryParameters['api_key'];
    final error = uri.queryParameters['error'];
    if (uri.queryParameters['state'] != _state) {
      setState(() => _error = 'State mismatch – please try again.');
      return;
    }
    if (key != null && key.isNotEmpty) {
      Navigator.of(context).pop(key);
    } else {
      setState(() => _error = error ?? 'Authorization was cancelled.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.authorizeTitle),
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(value: _progress / 100, minHeight: 2),
              )
            : null,
      ),
      body: Column(
        children: [
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() => _error = null);
                    _controller.reload();
                  },
                  child: Text(context.l10n.retry),
                ),
              ],
            ),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}

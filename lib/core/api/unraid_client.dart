import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

enum ApiErrorKind { network, timeout, tls, unauthorized, forbidden, graphql, redirect, unsupported }

class UnraidApiException implements Exception {
  UnraidApiException(this.kind, this.message, {this.redirectTo});

  final ApiErrorKind kind;
  final String message;

  /// Set when the server answered with a redirect (typically http → https).
  final Uri? redirectTo;

  @override
  String toString() => message;
}

/// Minimal GraphQL-over-HTTP client for the Unraid API.
///
/// Authentication uses the `x-api-key` header. Self-signed certificates are
/// only accepted when [allowSelfSigned] is set, and then pinned by their
/// SHA-256 fingerprint (trust on first use).
class UnraidClient {
  UnraidClient({
    required this.baseUrl,
    required this.apiKey,
    this.allowSelfSigned = false,
    this.pinnedFingerprint,
    this.timeout = const Duration(seconds: 15),
  }) {
    _http = HttpClient()
      ..connectionTimeout = timeout
      ..badCertificateCallback = _onBadCertificate;
  }

  final Uri baseUrl;
  final String apiKey;
  final bool allowSelfSigned;
  final String? pinnedFingerprint;
  final Duration timeout;

  late final HttpClient _http;

  /// Fingerprint of the self-signed certificate seen during the last request,
  /// so the caller can pin it after a successful first connection.
  String? observedFingerprint;

  Uri get endpoint => baseUrl.replace(path: '/graphql');

  bool _onBadCertificate(X509Certificate cert, String host, int port) {
    if (!allowSelfSigned) return false;
    final fp = certificateFingerprint(cert);
    observedFingerprint = fp;
    return pinnedFingerprint == null || pinnedFingerprint == fp;
  }

  static String certificateFingerprint(X509Certificate cert) =>
      sha256.convert(cert.der).toString();

  /// Runs a query or mutation and returns its `data` object.
  Future<Map<String, dynamic>> execute(
    String document, {
    Map<String, dynamic>? variables,
  }) async {
    final body = jsonEncode({
      'query': document,
      'variables': ?variables,
    });

    final HttpClientResponse response;
    final String text;
    try {
      final request = await _http.postUrl(endpoint).timeout(timeout);
      request.followRedirects = false;
      request.headers
        ..contentType = ContentType.json
        ..set(HttpHeaders.acceptHeader, 'application/json')
        ..set('x-api-key', apiKey);
      request.write(body);
      response = await request.close().timeout(timeout);
      text = await response.transform(utf8.decoder).join().timeout(timeout);
    } on TimeoutException {
      throw UnraidApiException(ApiErrorKind.timeout, 'Server did not respond in time');
    } on HandshakeException catch (e) {
      throw UnraidApiException(ApiErrorKind.tls, 'TLS error: ${e.message}');
    } on SocketException catch (e) {
      throw UnraidApiException(ApiErrorKind.network, e.message);
    } on HttpException catch (e) {
      throw UnraidApiException(ApiErrorKind.network, e.message);
    }

    // HttpClientResponse.isRedirect ignores 301/302 for POST, so check codes.
    if (const {301, 302, 303, 307, 308}.contains(response.statusCode)) {
      final location = response.headers.value(HttpHeaders.locationHeader);
      throw UnraidApiException(
        ApiErrorKind.redirect,
        'Server redirects to $location',
        redirectTo: location == null ? null : endpoint.resolve(location),
      );
    }
    if (response.statusCode == 401) {
      throw UnraidApiException(ApiErrorKind.unauthorized, 'Invalid API key');
    }
    if (response.statusCode == 403) {
      throw UnraidApiException(ApiErrorKind.forbidden, 'Access denied');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(text) as Map<String, dynamic>;
    } on FormatException {
      throw UnraidApiException(
        ApiErrorKind.network,
        'Unexpected response (HTTP ${response.statusCode}) – is this an Unraid server?',
      );
    }

    final errors = json['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first as Map<String, dynamic>;
      final code = (first['extensions'] as Map?)?['code'];
      final message = first['message']?.toString() ?? 'Unknown error';
      if (code == 'UNAUTHENTICATED') {
        throw UnraidApiException(ApiErrorKind.unauthorized, message);
      }
      if (code == 'FORBIDDEN' || message.toLowerCase().contains('forbidden')) {
        throw UnraidApiException(ApiErrorKind.forbidden, message);
      }
      // Validation errors mean the server's API predates a field we use.
      if (code == 'GRAPHQL_VALIDATION_FAILED' || message.startsWith('Cannot query field')) {
        throw UnraidApiException(ApiErrorKind.unsupported, message);
      }
      // Partial data is still useful (e.g. one disk failing to report);
      // only fail when nothing came back.
      if (json['data'] == null) {
        throw UnraidApiException(ApiErrorKind.graphql, message);
      }
    }
    return (json['data'] as Map<String, dynamic>?) ?? const {};
  }

  void close() => _http.close(force: true);
}

/// Normalises user input such as `tower.local` or `192.168.1.10:8080`
/// to a base URL. Defaults to http, which is what a fresh Unraid uses.
Uri? parseServerAddress(String input) {
  var text = input.trim();
  if (text.isEmpty) return null;
  if (!text.contains('://')) text = 'http://$text';
  final uri = Uri.tryParse(text);
  if (uri == null || uri.host.isEmpty) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  return Uri(scheme: uri.scheme, host: uri.host, port: uri.hasPort ? uri.port : null);
}

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A saved server. The API key lives in the platform keystore
/// (Keychain / Android Keystore), never in shared preferences.
class ServerConfig {
  const ServerConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    this.allowSelfSigned = false,
    this.certFingerprint,
  });

  final String id;
  final String name;
  final Uri baseUrl;
  final String apiKey;
  final bool allowSelfSigned;
  final String? certFingerprint;

  ServerConfig copyWith({
    String? name,
    Uri? baseUrl,
    String? apiKey,
    bool? allowSelfSigned,
    String? certFingerprint,
  }) =>
      ServerConfig(
        id: id,
        name: name ?? this.name,
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
        allowSelfSigned: allowSelfSigned ?? this.allowSelfSigned,
        certFingerprint: certFingerprint ?? this.certFingerprint,
      );

  Map<String, dynamic> _toPrefs() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl.toString(),
        'allowSelfSigned': allowSelfSigned,
        if (certFingerprint != null) 'certFingerprint': certFingerprint,
      };
}

class ServerStore {
  ServerStore({FlutterSecureStorage? secure}) : _secure = secure ?? const FlutterSecureStorage();

  static const _serversKey = 'servers';
  static const _activeKey = 'activeServer';

  final FlutterSecureStorage _secure;

  String _keyFor(String id) => 'apikey_$id';

  Future<List<ServerConfig>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_serversKey);
    if (raw == null) return [];
    final result = <ServerConfig>[];
    for (final e in (jsonDecode(raw) as List).cast<Map<String, dynamic>>()) {
      final id = e['id'] as String;
      final key = await _secure.read(key: _keyFor(id));
      if (key == null) continue; // keystore was wiped (e.g. restored backup)
      result.add(ServerConfig(
        id: id,
        name: e['name'] as String,
        baseUrl: Uri.parse(e['baseUrl'] as String),
        apiKey: key,
        allowSelfSigned: e['allowSelfSigned'] == true,
        certFingerprint: e['certFingerprint'] as String?,
      ));
    }
    return result;
  }

  Future<void> save(List<ServerConfig> servers) async {
    final prefs = await SharedPreferences.getInstance();
    final previous = (jsonDecode(prefs.getString(_serversKey) ?? '[]') as List)
        .map((e) => (e as Map)['id'] as String)
        .toSet();
    for (final s in servers) {
      await _secure.write(key: _keyFor(s.id), value: s.apiKey);
      previous.remove(s.id);
    }
    for (final removed in previous) {
      await _secure.delete(key: _keyFor(removed));
    }
    await prefs.setString(_serversKey, jsonEncode(servers.map((s) => s._toPrefs()).toList()));
  }

  Future<String?> loadActiveId() async =>
      (await SharedPreferences.getInstance()).getString(_activeKey);

  Future<void> saveActiveId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_activeKey);
    } else {
      await prefs.setString(_activeKey, id);
    }
  }
}

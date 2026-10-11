import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/demo_api.dart';
import '../core/api/unraid_api.dart';
import '../core/api/unraid_client.dart';
import '../core/models/models.dart';
import 'server_store.dart';

// ---------------------------------------------------------------------------
// Servers
// ---------------------------------------------------------------------------

final serverStoreProvider = Provider((ref) => ServerStore());

class ServersState {
  const ServersState(this.servers, this.activeId);

  final List<ServerConfig> servers;
  final String? activeId;

  ServerConfig? get active {
    for (final s in servers) {
      if (s.id == activeId) return s;
    }
    return null;
  }
}

class ServersNotifier extends AsyncNotifier<ServersState> {
  ServerStore get _store => ref.read(serverStoreProvider);

  @override
  Future<ServersState> build() async {
    final servers = await _store.load();
    var activeId = await _store.loadActiveId();
    if (!servers.any((s) => s.id == activeId)) {
      activeId = servers.isEmpty ? null : servers.first.id;
    }
    return ServersState(servers, activeId);
  }

  Future<void> upsert(ServerConfig server, {bool select = true}) async {
    final current = await future;
    final servers = [
      for (final s in current.servers)
        if (s.id != server.id) s,
      server,
    ];
    await _store.save(servers);
    final activeId = select ? server.id : current.activeId;
    await _store.saveActiveId(activeId);
    state = AsyncData(ServersState(servers, activeId));
  }

  Future<void> remove(String id) async {
    final current = await future;
    final servers = current.servers.where((s) => s.id != id).toList();
    await _store.save(servers);
    final activeId = current.activeId == id
        ? (servers.isEmpty ? null : servers.first.id)
        : current.activeId;
    await _store.saveActiveId(activeId);
    state = AsyncData(ServersState(servers, activeId));
  }

  Future<void> select(String id) async {
    final current = await future;
    await _store.saveActiveId(id);
    state = AsyncData(ServersState(current.servers, id));
  }
}

final serversProvider =
    AsyncNotifierProvider<ServersNotifier, ServersState>(ServersNotifier.new);

final activeServerProvider =
    Provider<ServerConfig?>((ref) => ref.watch(serversProvider).value?.active);

UnraidClient clientFor(ServerConfig s) => UnraidClient(
      baseUrl: s.baseUrl,
      apiKey: s.apiKey,
      allowSelfSigned: s.allowSelfSigned,
      pinnedFingerprint: s.certFingerprint,
    );

/// API for the currently selected server. Screens below the server shell
/// can rely on it being present.
final apiProvider = Provider<UnraidApi>((ref) {
  final server = ref.watch(activeServerProvider);
  if (server == null) throw StateError('No active server');
  if (server.id == demoServerId) return ref.watch(_demoApiProvider);
  final client = clientFor(server);
  ref.onDispose(client.close);
  return UnraidApi(client);
});

/// Kept alive so demo state (stopped containers etc.) survives tab switches.
final _demoApiProvider = Provider((ref) => DemoApi());

ServerConfig demoServer() => ServerConfig(
      id: demoServerId,
      name: 'Demo-Tower',
      baseUrl: Uri.parse('http://demo.invalid'),
      apiKey: 'demo',
    );

// ---------------------------------------------------------------------------
// Server data (polled while visible)
// ---------------------------------------------------------------------------

void _pollEvery(Ref ref, Duration interval) {
  final timer = Timer(interval, ref.invalidateSelf);
  ref.onDispose(timer.cancel);
}

final dashboardProvider = FutureProvider.autoDispose<Dashboard>((ref) {
  _pollEvery(ref, const Duration(seconds: 5));
  return ref.watch(apiProvider).dashboard();
});

final containersProvider = FutureProvider.autoDispose<List<DockerContainer>>((ref) {
  _pollEvery(ref, const Duration(seconds: 10));
  return ref.watch(apiProvider).containers();
});

final containerLogsProvider =
    FutureProvider.autoDispose.family<List<LogLine>, String>((ref, id) {
  return ref.watch(apiProvider).containerLogs(id, tail: 300);
});

final vmsProvider = FutureProvider.autoDispose<List<VirtualMachine>>((ref) {
  _pollEvery(ref, const Duration(seconds: 10));
  return ref.watch(apiProvider).vms();
});

final storageProvider = FutureProvider.autoDispose<StorageInfo>((ref) {
  _pollEvery(ref, const Duration(seconds: 15));
  return ref.watch(apiProvider).storage();
});

final notificationsProvider =
    FutureProvider.autoDispose.family<List<UnraidNotification>, bool>((ref, archived) {
  return ref.watch(apiProvider).notifications(archived: archived);
});

/// Roles of the API key. Only ADMIN may change containers, VMs and the
/// array (VIEWER, GUEST and CONNECT keys get "Forbidden resource"), so the UI
/// hides action buttons instead of failing on tap.
final rolesProvider = FutureProvider<List<String>>((ref) async {
  final probe = await ref.watch(apiProvider).probe();
  return probe.roles;
});

final readOnlyProvider = Provider<bool>((ref) {
  final roles = ref.watch(rolesProvider).value ?? const [];
  if (roles.isEmpty) return false; // custom permissions – let the server decide
  return !roles.contains('ADMIN');
});

// ---------------------------------------------------------------------------
// App settings
// ---------------------------------------------------------------------------

class AppSettings {
  const AppSettings({this.themeMode = ThemeMode.system, this.locale});

  final ThemeMode themeMode;

  /// null = follow the system language.
  final Locale? locale;
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = ThemeMode.values.asNameMap()[prefs.getString('themeMode')] ?? ThemeMode.system;
    final lang = prefs.getString('locale');
    state = AppSettings(themeMode: theme, locale: lang == null ? null : Locale(lang));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AppSettings(themeMode: mode, locale: state.locale);
    await (await SharedPreferences.getInstance()).setString('themeMode', mode.name);
  }

  Future<void> setLocale(Locale? locale) async {
    state = AppSettings(themeMode: state.themeMode, locale: locale);
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove('locale');
    } else {
      await prefs.setString('locale', locale.languageCode);
    }
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

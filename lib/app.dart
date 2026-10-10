import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/providers.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/docker/container_detail_screen.dart';
import 'features/docker/docker_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/servers/server_form_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/shell/home_shell.dart';
import 'features/storage/storage_screen.dart';
import 'features/vms/vms_screen.dart';
import 'l10n/app_localizations.dart';

/// Unraid orange.
const _seed = Color(0xFFF15A2C);

final routerProvider = Provider<GoRouter>((ref) {
  // Re-evaluate redirects whenever the server list changes.
  final refresh = ValueNotifier(0);
  ref.listen(serversProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: refresh,
    redirect: (context, state) {
      final servers = ref.read(serversProvider);
      if (servers.isLoading && !servers.hasValue) return '/loading';
      final hasActive = servers.value?.active != null;
      final loc = state.matchedLocation;
      if (!hasActive && !loc.startsWith('/servers')) return '/servers/add';
      if (loc == '/loading') return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (_, _) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/servers/add', builder: (_, _) => const ServerFormScreen()),
      GoRoute(
        path: '/servers/:id',
        builder: (_, state) => ServerFormScreen(serverId: state.pathParameters['id']),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/docker',
              builder: (_, _) => const DockerScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) => ContainerDetailScreen(id: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/vms', builder: (_, _) => const VmsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/storage', builder: (_, _) => const StorageScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
          ]),
        ],
      ),
    ],
  );
});

class TowerDeckApp extends ConsumerWidget {
  const TowerDeckApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      themeMode: settings.themeMode,
      theme: ThemeData(colorSchemeSeed: _seed, brightness: Brightness.light),
      darkTheme: ThemeData(colorSchemeSeed: _seed, brightness: Brightness.dark),
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

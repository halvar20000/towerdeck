import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../widgets/common.dart';

/// Bottom navigation for the per-server tabs.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    // Unread badge comes from the dashboard poll if it is alive; no extra request.
    final unread = ref.watch(dashboardProvider.select((d) => d.value?.unread));
    final alerts = (unread?.alert ?? 0) + (unread?.warning ?? 0);

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.space_dashboard_outlined), selectedIcon: const Icon(Icons.space_dashboard), label: l.navDashboard),
          NavigationDestination(icon: const Icon(Icons.view_in_ar_outlined), selectedIcon: const Icon(Icons.view_in_ar), label: l.navDocker),
          NavigationDestination(icon: const Icon(Icons.computer_outlined), selectedIcon: const Icon(Icons.computer), label: l.navVms),
          NavigationDestination(icon: const Icon(Icons.storage_outlined), selectedIcon: const Icon(Icons.storage), label: l.navStorage),
          NavigationDestination(
            icon: Badge(isLabelVisible: alerts > 0, label: Text('$alerts'), child: const Icon(Icons.notifications_outlined)),
            selectedIcon: const Icon(Icons.notifications),
            label: l.navNotifications,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../shell/server_app_bar.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final readOnly = ref.watch(readOnlyProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: ServerAppBar(
          actions: [
            if (!readOnly)
              IconButton(
                tooltip: l.archiveAll,
                icon: const Icon(Icons.done_all),
                onPressed: () async {
                  if (!await confirm(context, '${l.archiveAll}?', action: l.archiveAll)) return;
                  if (!context.mounted) return;
                  await runAction(context, ref, (api) => api.archiveAll(),
                      refresh: [notificationsProvider, dashboardProvider]);
                },
              ),
          ],
          bottom: TabBar(tabs: [Tab(text: l.unread), Tab(text: l.archived)]),
        ),
        body: const TabBarView(
          children: [_NotificationList(archived: false), _NotificationList(archived: true)],
        ),
      ),
    );
  }
}

class _NotificationList extends ConsumerWidget {
  const _NotificationList({required this.archived});

  final bool archived;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final readOnly = ref.watch(readOnlyProvider);
    final provider = notificationsProvider(archived);
    return AsyncBody(
      value: ref.watch(provider),
      onRefresh: () => ref.refresh(provider.future),
      builder: (items) {
        if (items.isEmpty) {
          return EmptyState(icon: Icons.notifications_none, text: l.notificationsEmpty);
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final n = items[i];
            final tile = _NotificationTile(n);
            if (readOnly) return tile;
            return Dismissible(
              key: ValueKey(n.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                color: archived ? Theme.of(context).colorScheme.error : Colors.blueGrey,
                child: Icon(archived ? Icons.delete : Icons.archive, color: Colors.white),
              ),
              confirmDismiss: (_) => runAction(
                context,
                ref,
                (api) => archived
                    ? api.deleteNotification(n.id, archived: true)
                    : api.archiveNotification(n.id),
                successMessage: archived ? l.delete : l.archive,
                refresh: [notificationsProvider, dashboardProvider],
              ),
              child: tile,
            );
          },
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile(this.n);

  final UnraidNotification n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = switch (n.importance) {
      'ALERT' => (Icons.error, theme.colorScheme.error),
      'WARNING' => (Icons.warning_amber, Colors.orange),
      _ => (Icons.info_outline, theme.colorScheme.primary),
    };
    final when = n.timestamp == null
        ? ''
        : DateFormat.yMd(Localizations.localeOf(context).toString()).add_Hm().format(n.timestamp!);
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(n.subject.isEmpty ? n.title : n.subject),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (n.description.isNotEmpty) Text(n.description),
          const SizedBox(height: 2),
          Text('${n.title} · $when', style: theme.textTheme.bodySmall),
        ],
      ),
      isThreeLine: n.description.isNotEmpty,
    );
  }
}

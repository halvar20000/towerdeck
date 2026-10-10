import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/demo_api.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

/// App bar used on every server tab: server switcher, WebGUI shortcut,
/// settings, and a banner when the key is read-only.
class ServerAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ServerAppBar({super.key, this.actions = const [], this.bottom});

  final List<Widget> actions;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final server = ref.watch(activeServerProvider);
    final readOnly = ref.watch(readOnlyProvider);
    return AppBar(
      title: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showSwitcher(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(server?.name ?? '', overflow: TextOverflow.ellipsis)),
              const Icon(Icons.arrow_drop_down),
              if (server?.id == demoServerId)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Tooltip(
                    message: context.l10n.demoBanner,
                    child: const Icon(Icons.science_outlined, size: 18),
                  ),
                ),
              if (readOnly)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Tooltip(
                    message: context.l10n.readOnlyBanner,
                    child: const Icon(Icons.visibility_outlined, size: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        ...actions,
        PopupMenuButton<String>(
          onSelected: (v) {
            switch (v) {
              case 'webgui':
                if (server != null) {
                  launchUrl(server.baseUrl, mode: LaunchMode.externalApplication);
                }
              case 'settings':
                context.push('/settings');
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'webgui', child: Text(context.l10n.webGui)),
            PopupMenuItem(value: 'settings', child: Text(context.l10n.settings)),
          ],
        ),
      ],
      bottom: bottom,
    );
  }

  void _showSwitcher(BuildContext context, WidgetRef ref) {
    final state = ref.read(serversProvider).value;
    if (state == null) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in state.servers)
              ListTile(
                leading: const Icon(Icons.dns_outlined),
                title: Text(s.name),
                subtitle: Text(s.baseUrl.toString()),
                trailing: s.id == state.activeId ? const Icon(Icons.check) : null,
                onTap: () {
                  Navigator.pop(sheetContext);
                  ref.read(serversProvider.notifier).select(s.id);
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(context.l10n.addServer),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/servers/add');
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: Text(context.l10n.servers),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/settings');
              },
            ),
          ],
        ),
      ),
    );
  }
}

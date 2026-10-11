import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/unraid_api.dart';
import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import 'container_actions.dart';
import 'docker_screen.dart';

class ContainerDetailScreen extends ConsumerWidget {
  const ContainerDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final containers = ref.watch(containersProvider);
    final c = containers.value?.where((c) => c.id == id).firstOrNull;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(c?.name ?? ''),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Info'),
              Tab(text: l.logs),
            ],
          ),
        ),
        body: c == null
            ? AsyncBody(
                value: containers,
                onRefresh: () => ref.refresh(containersProvider.future),
                builder: (_) => EmptyState(icon: Icons.help_outline, text: l.dockerEmpty),
              )
            : TabBarView(children: [_InfoTab(c), _LogsTab(c.id)]),
      ),
    );
  }
}

class _InfoTab extends ConsumerWidget {
  const _InfoTab(this.c);

  final DockerContainer c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final readOnly = ref.watch(readOnlyProvider);
    final busy = isContainerBusy(ref.watch(busyProvider), c.id);
    final theme = Theme.of(context);

    Future<void> act(ContainerAction a) => runAction(
      context,
      ref,
      (api) => api.containerAction(c.id, a),
      refresh: [containersProvider],
      busyKey: containerBusyKey(c.id),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            ContainerIcon(c, size: 56),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name, style: theme.textTheme.titleLarge),
                  Row(
                    children: [
                      StatusDot(
                        c.running
                            ? Health.good
                            : c.paused
                            ? Health.warning
                            : Health.idle,
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: Text(c.status)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!readOnly && busy)
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: LinearProgressIndicator()),
        if (!readOnly && !busy)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!c.running && !c.paused)
                FilledButton.icon(
                  onPressed: () => act(ContainerAction.start),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l.start),
                ),
              if (c.paused)
                FilledButton.icon(
                  onPressed: () => act(ContainerAction.unpause),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l.resume),
                ),
              if (c.running) ...[
                FilledButton.tonalIcon(
                  onPressed: () => stopContainer(context, ref, c),
                  icon: const Icon(Icons.stop),
                  label: Text(l.stop),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => act(ContainerAction.restart),
                  icon: const Icon(Icons.restart_alt),
                  label: Text(l.restart),
                ),
                OutlinedButton.icon(
                  onPressed: () => act(ContainerAction.pause),
                  icon: const Icon(Icons.pause),
                  label: Text(l.pause),
                ),
              ],
              if (c.updateAvailable)
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () => runAction(
                    context,
                    ref,
                    (api) => api.updateContainer(c.id),
                    refresh: [containersProvider],
                    busyKey: containerBusyKey(c.id),
                  ),
                  icon: const Icon(Icons.system_update_alt),
                  label: Text(l.update),
                ),
            ],
          ),
        if (c.webUiUrl != null && c.running) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => launchUrl(Uri.parse(c.webUiUrl!), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new),
            label: Text(l.openWebUi),
          ),
        ],
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text(l.image),
                subtitle: Text(c.image),
                trailing: IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => Clipboard.setData(ClipboardData(text: c.image)),
                ),
              ),
              ListTile(
                title: Text(l.autostart),
                trailing: Icon(c.autoStart ? Icons.check_circle : Icons.cancel_outlined),
              ),
              if (c.updateAvailable)
                ListTile(
                  title: Text(l.updateAvailable),
                  trailing: const Icon(Icons.upgrade, color: Colors.orange),
                ),
              if (c.ports.isNotEmpty)
                ListTile(title: Text(l.ports), subtitle: Text(c.ports.map((p) => p.toString()).toSet().join('\n'))),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogsTab extends ConsumerWidget {
  const _LogsTab(this.id);

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(containerLogsProvider(id));
    final time = DateFormat.Hms();
    return AsyncBody(
      value: value,
      onRefresh: () => ref.refresh(containerLogsProvider(id).future),
      builder: (lines) {
        if (lines.isEmpty) return EmptyState(icon: Icons.notes, text: context.l10n.logsEmpty);
        // Newest at the bottom, list starts scrolled to the end.
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.all(12),
          itemCount: lines.length,
          itemBuilder: (context, i) {
            final line = lines[lines.length - 1 - i];
            return SelectableText.rich(
              TextSpan(
                children: [
                  if (line.timestamp != null)
                    TextSpan(
                      text: '${time.format(line.timestamp!)}  ',
                      style: TextStyle(color: Theme.of(context).colorScheme.outline),
                    ),
                  TextSpan(text: line.message),
                ],
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            );
          },
        );
      },
    );
  }
}

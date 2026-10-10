import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/unraid_api.dart';
import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../shell/server_app_bar.dart';
import 'container_actions.dart';

enum _Filter { all, running, stopped }

class DockerScreen extends ConsumerStatefulWidget {
  const DockerScreen({super.key});

  @override
  ConsumerState<DockerScreen> createState() => _DockerScreenState();
}

class _DockerScreenState extends ConsumerState<DockerScreen> {
  String _query = '';
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final value = ref.watch(containersProvider);
    final readOnly = ref.watch(readOnlyProvider);
    final updates = value.value?.where((c) => c.updateAvailable).length ?? 0;

    return Scaffold(
      appBar: ServerAppBar(
        actions: [
          if (updates > 0 && !readOnly)
            IconButton(
              tooltip: l.updateAll,
              icon: Badge(label: Text('$updates'), child: const Icon(Icons.system_update_alt)),
              onPressed: () async {
                if (!await confirm(context, l.updateAllConfirm, action: l.updateAll)) return;
                if (!context.mounted) return;
                await runAction(context, ref, (api) => api.updateAllContainers(),
                    refresh: [containersProvider]);
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              children: [
                SearchBar(
                  hintText: l.search,
                  leading: const Icon(Icons.search),
                  elevation: const WidgetStatePropertyAll(0),
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                ),
                const SizedBox(height: 8),
                SegmentedButton<_Filter>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: _Filter.all, label: Text(l.filterAll)),
                    ButtonSegment(value: _Filter.running, label: Text(l.filterRunning)),
                    ButtonSegment(value: _Filter.stopped, label: Text(l.filterStopped)),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) => setState(() => _filter = s.first),
                ),
              ],
            ),
          ),
        ),
      ),
      body: AsyncBody(
        value: value,
        onRefresh: () => ref.refresh(containersProvider.future),
        builder: (all) {
          final items = all.where((c) {
            if (_query.isNotEmpty &&
                !c.name.toLowerCase().contains(_query) &&
                !c.image.toLowerCase().contains(_query)) {
              return false;
            }
            return switch (_filter) {
              _Filter.all => true,
              _Filter.running => c.running || c.paused,
              _Filter.stopped => !c.running && !c.paused,
            };
          }).toList();
          if (items.isEmpty) return EmptyState(icon: Icons.view_in_ar, text: l.dockerEmpty);
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) => _ContainerTile(items[i], readOnly: readOnly),
          );
        },
      ),
    );
  }
}

class _ContainerTile extends ConsumerWidget {
  const _ContainerTile(this.c, {required this.readOnly});

  final DockerContainer c;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return ListTile(
      leading: ContainerIcon(c),
      title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Row(
        children: [
          StatusDot(c.running ? Health.good : c.paused ? Health.warning : Health.idle, size: 8),
          const SizedBox(width: 6),
          Expanded(child: Text(c.status, maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (c.updateAvailable)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.upgrade, size: 16, color: Colors.orange, semanticLabel: l.updateAvailable),
            ),
        ],
      ),
      trailing: readOnly
          ? null
          : IconButton(
              tooltip: c.running ? l.stop : l.start,
              icon: Icon(c.running ? Icons.stop_circle_outlined : Icons.play_circle_outline),
              onPressed: () => c.running
                  ? stopContainer(context, ref, c)
                  : runAction(context, ref,
                      (api) => api.containerAction(c.id, c.paused ? ContainerAction.unpause : ContainerAction.start),
                      refresh: [containersProvider]),
            ),
      onTap: () => context.push('/docker/${Uri.encodeComponent(c.id)}'),
    );
  }
}

class ContainerIcon extends StatelessWidget {
  const ContainerIcon(this.c, {super.key, this.size = 40});

  final DockerContainer c;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      radius: size / 2,
      child: Text(c.name.isEmpty ? '?' : c.name[0].toUpperCase()),
    );
    if (c.iconUrl == null) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        c.iconUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

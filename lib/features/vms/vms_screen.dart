import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/unraid_api.dart';
import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../shell/server_app_bar.dart';

class VmsScreen extends ConsumerWidget {
  const VmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(vmsProvider);
    final readOnly = ref.watch(readOnlyProvider);
    return Scaffold(
      appBar: const ServerAppBar(),
      body: AsyncBody(
        value: value,
        onRefresh: () => ref.refresh(vmsProvider.future),
        builder: (vms) {
          if (vms.isEmpty) return EmptyState(icon: Icons.computer, text: context.l10n.vmsEmpty);
          return ListView(
            children: [for (final vm in vms) _VmTile(vm, readOnly: readOnly)],
          );
        },
      ),
    );
  }
}

class _VmTile extends ConsumerWidget {
  const _VmTile(this.vm, {required this.readOnly});

  final VirtualMachine vm;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;

    Future<void> act(VmAction a) =>
        runAction(context, ref, (api) => api.vmAction(vm.id, a), refresh: [vmsProvider]);

    return ListTile(
      leading: CircleAvatar(child: Icon(vm.running ? Icons.computer : Icons.desktop_access_disabled)),
      title: Text(vm.name),
      subtitle: Row(children: [
        StatusDot(vm.running ? Health.good : vm.paused ? Health.warning : Health.idle, size: 8),
        const SizedBox(width: 6),
        Text(vm.state.toLowerCase()),
      ]),
      trailing: readOnly
          ? null
          : PopupMenuButton<VmAction>(
              onSelected: (a) async {
                if (a == VmAction.stop &&
                    !await confirm(context, l.stopConfirm(vm.name), action: l.stop)) {
                  return;
                }
                if (!context.mounted) return;
                if (a == VmAction.forceStop &&
                    !await confirm(context, l.forceStopConfirm(vm.name),
                        action: l.forceStop, destructive: true)) {
                  return;
                }
                if (context.mounted) await act(a);
              },
              itemBuilder: (context) => [
                if (!vm.running && !vm.paused) PopupMenuItem(value: VmAction.start, child: Text(l.start)),
                if (vm.paused) PopupMenuItem(value: VmAction.resume, child: Text(l.resume)),
                if (vm.running) ...[
                  PopupMenuItem(value: VmAction.stop, child: Text(l.stop)),
                  PopupMenuItem(value: VmAction.reboot, child: Text(l.reboot)),
                  PopupMenuItem(value: VmAction.pause, child: Text(l.pause)),
                ],
                if (vm.running || vm.paused)
                  PopupMenuItem(value: VmAction.forceStop, child: Text(l.forceStop)),
              ],
            ),
    );
  }
}

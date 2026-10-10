import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/unraid_api.dart';
import '../../core/format.dart';
import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../shell/server_app_bar.dart';

class StorageScreen extends ConsumerWidget {
  const StorageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(storageProvider);
    final readOnly = ref.watch(readOnlyProvider);
    final l = context.l10n;
    return Scaffold(
      appBar: const ServerAppBar(),
      body: AsyncBody(
        value: value,
        onRefresh: () => ref.refresh(storageProvider.future),
        builder: (s) => ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _ArrayCard(s, readOnly: readOnly),
            if (s.parities.isNotEmpty) ...[
              SectionHeader(l.parityDisks),
              for (final d in s.parities) _DiskTile(d),
            ],
            if (s.disks.isNotEmpty) ...[
              SectionHeader(l.dataDisks),
              for (final d in s.disks) _DiskTile(d),
            ],
            if (s.caches.isNotEmpty) ...[
              SectionHeader(l.cachePools),
              for (final d in s.caches) _DiskTile(d),
            ],
            if (s.shares.isNotEmpty) ...[
              SectionHeader(l.shares),
              for (final sh in s.shares)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.folder_shared_outlined),
                  title: Text(sh.name),
                  subtitle: sh.comment == null ? null : Text(sh.comment!),
                  trailing: Text(
                    '${formatKiB(sh.usedKiB)}\n${l.free(formatKiB(sh.freeKiB))}',
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ArrayCard extends ConsumerWidget {
  const _ArrayCard(this.s, {required this.readOnly});

  final StorageInfo s;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final p = s.parity;
    final fraction = (s.usedKiB != null && (s.totalKiB ?? 0) > 0) ? s.usedKiB! / s.totalKiB! : null;

    Future<void> parity(ParityAction a, {bool correct = false}) => runAction(
        context, ref, (api) => api.parityCheck(a, correct: correct),
        refresh: [storageProvider, dashboardProvider]);

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              StatusDot(s.started ? Health.good : Health.bad),
              const SizedBox(width: 8),
              Text(l.array, style: theme.textTheme.titleMedium),
              const Spacer(),
              Text(s.started ? l.arrayStarted : l.arrayStopped),
            ]),
            const SizedBox(height: 12),
            UsageBar(fraction: fraction),
            const SizedBox(height: 6),
            Text(l.used(formatKiB(s.usedKiB), formatKiB(s.totalKiB)), style: theme.textTheme.bodySmall),
            const Divider(height: 28),
            Text(l.parityCheck, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            if (p.active) ...[
              Text(p.paused ? l.parityPaused(p.progress ?? 0) : l.parityRunning(p.progress ?? 0)),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: (p.progress ?? 0) / 100),
              if (p.speed != null) Text(p.speed!, style: theme.textTheme.bodySmall),
            ] else
              Text(
                p.date == null
                    ? l.parityNever
                    : '${l.parityLast(DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(p.date!))}'
                        '${(p.errors ?? 0) > 0 ? ' · ${l.parityErrors(p.errors!)}' : ''}',
                style: theme.textTheme.bodySmall,
              ),
            if (!readOnly) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (!p.active && s.started)
                  FilledButton.tonal(
                    onPressed: () => _startParity(context, parity),
                    child: Text(l.parityStart),
                  ),
                if (p.running && !p.paused)
                  OutlinedButton(onPressed: () => parity(ParityAction.pause), child: Text(l.pause)),
                if (p.paused)
                  OutlinedButton(onPressed: () => parity(ParityAction.resume), child: Text(l.resume)),
                if (p.active)
                  OutlinedButton(onPressed: () => parity(ParityAction.cancel), child: Text(l.parityCancel)),
                if (!p.active)
                  OutlinedButton(
                    style: s.started
                        ? OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error)
                        : null,
                    onPressed: () async {
                      final ok = await confirm(
                        context,
                        s.started ? l.stopArrayConfirm : l.startArrayConfirm,
                        action: s.started ? l.stopArray : l.startArray,
                        destructive: s.started,
                      );
                      if (!ok || !context.mounted) return;
                      await runAction(context, ref, (api) => api.setArrayState(start: !s.started),
                          refresh: [storageProvider, dashboardProvider]);
                    },
                    child: Text(s.started ? l.stopArray : l.startArray),
                  ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startParity(
    BuildContext context,
    Future<void> Function(ParityAction, {bool correct}) run,
  ) async {
    final l = context.l10n;
    var correct = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l.parityCheck),
          content: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: correct,
            onChanged: (v) => setState(() => correct = v ?? false),
            title: Text(l.parityStartCorrecting),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.parityStart)),
          ],
        ),
      ),
    );
    if (ok == true) await run(ParityAction.start, correct: correct);
  }
}

class _DiskTile extends StatelessWidget {
  const _DiskTile(this.d);

  final ArrayDisk d;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final hot = (d.temp ?? 0) >= 50;
    final health = !d.healthy || (d.errors ?? 0) > 0
        ? Health.bad
        : d.spinning == false
            ? Health.idle
            : Health.good;
    final details = [
      if (d.device != null) d.device!,
      if (d.fsType != null) d.fsType!,
      formatKiB(d.fsSizeKiB ?? d.sizeKiB),
      if (d.spinning == false) l.spunDown,
      if ((d.errors ?? 0) > 0) l.diskErrors(d.errors!),
      if (!d.healthy && d.status != null) d.status!.replaceFirst('DISK_', ''),
    ].join(' · ');

    return ListTile(
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(d.type == 'CACHE' ? Icons.memory : Icons.album_outlined),
          const SizedBox(height: 4),
          StatusDot(health, size: 8),
        ],
      ),
      title: Text(d.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(details, maxLines: 2),
          if (d.usedFraction != null) ...[
            const SizedBox(height: 4),
            UsageBar(fraction: d.usedFraction, height: 5),
          ],
        ],
      ),
      trailing: d.temp == null
          ? null
          : Text('${d.temp} °C',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: hot ? theme.colorScheme.error : null,
                fontWeight: hot ? FontWeight.bold : null,
              )),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../shell/server_app_bar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(dashboardProvider);
    return Scaffold(
      appBar: const ServerAppBar(),
      body: AsyncBody(
        value: value,
        onRefresh: () => ref.refresh(dashboardProvider.future),
        builder: (d) => _DashboardView(d),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView(this.d);

  final Dashboard d;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final started = d.arrayState == 'STARTED';
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        _Card(
          child: Row(
            children: [
              Icon(Icons.dns_rounded, size: 40, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.hostname, style: theme.textTheme.titleLarge),
                    Text(
                      [
                        if (d.unraidVersion != null) 'Unraid ${d.unraidVersion}',
                        if (d.cpuBrand != null) d.cpuBrand!,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (d.uptime != null)
                      Text('${l.uptime}: ${formatDuration(d.uptime!)}',
                          style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _GaugeCard(
                label: l.cpu,
                fraction: d.cpuPercent == null ? null : d.cpuPercent! / 100,
                subtitle: d.threads == null ? null : '${d.threads} Threads',
              ),
            ),
            Expanded(
              child: _GaugeCard(
                label: l.memory,
                fraction: d.memPercent == null ? null : d.memPercent! / 100,
                subtitle: d.memTotal == null ? null : formatBytes(d.memTotal),
              ),
            ),
          ],
        ),
        _Card(
          onTap: () => context.go('/storage'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusDot(started ? Health.good : Health.bad),
                  const SizedBox(width: 8),
                  Text(l.array, style: theme.textTheme.titleMedium),
                  const Spacer(),
                  Text(started ? l.arrayStarted : l.arrayStopped),
                ],
              ),
              const SizedBox(height: 12),
              UsageBar(fraction: d.arrayFraction),
              const SizedBox(height: 6),
              Text(l.used(formatKiB(d.arrayUsedKiB), formatKiB(d.arrayTotalKiB)),
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              _ParityLine(d.parity),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _CountCard(
                icon: Icons.view_in_ar_rounded,
                label: 'Docker',
                text: l.containersSummary(d.containersRunning, d.containersTotal),
                badge: d.updatesAvailable > 0 ? l.updatesAvailable(d.updatesAvailable) : null,
                onTap: () => context.go('/docker'),
              ),
            ),
            Expanded(
              child: _CountCard(
                icon: Icons.computer_rounded,
                label: 'VMs',
                text: l.containersSummary(d.vmsRunning, d.vmsTotal),
                onTap: () => context.go('/vms'),
              ),
            ),
          ],
        ),
        _Card(
          onTap: () => context.go('/notifications'),
          child: Row(
            children: [
              Icon(
                d.unread.alert > 0
                    ? Icons.error_rounded
                    : d.unread.warning > 0
                        ? Icons.warning_rounded
                        : Icons.notifications_none_rounded,
                color: d.unread.alert > 0
                    ? theme.colorScheme.error
                    : d.unread.warning > 0
                        ? Colors.orange
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(l.unreadSummary(d.unread.total))),
              if (d.unread.alert > 0) _Pill('${d.unread.alert}', theme.colorScheme.error),
              if (d.unread.warning > 0) _Pill('${d.unread.warning}', Colors.orange),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ],
    );
  }
}

class _ParityLine extends StatelessWidget {
  const _ParityLine(this.p);

  final ParityStatus p;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final style = Theme.of(context).textTheme.bodySmall;
    if (p.running && !p.paused) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.parityRunning(p.progress ?? 0), style: style),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: (p.progress ?? 0) / 100),
        ],
      );
    }
    if (p.paused) return Text(l.parityPaused(p.progress ?? 0), style: style);
    if (p.date == null) return Text(l.parityNever, style: style);
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(p.date!);
    final errors = (p.errors ?? 0) > 0 ? ' · ${l.parityErrors(p.errors!)}' : '';
    return Text('${l.parityLast(date)}$errors', style: style);
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}

class _GaugeCard extends StatelessWidget {
  const _GaugeCard({required this.label, required this.fraction, this.subtitle});

  final String label;
  final double? fraction;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Card(
      child: Column(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: fraction ?? 0,
                  strokeWidth: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: (fraction ?? 0) > 0.9 ? theme.colorScheme.error : null,
                ),
                Center(
                  child: Text(formatPercent(fraction), style: theme.textTheme.titleMedium),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(label, style: theme.textTheme.titleSmall),
          if (subtitle != null) Text(subtitle!, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.icon,
    required this.label,
    required this.text,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String text;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Card(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(label, style: theme.textTheme.titleMedium),
          Text(text, style: theme.textTheme.bodySmall),
          if (badge != null) ...[
            const SizedBox(height: 6),
            Text(badge!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange)),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}

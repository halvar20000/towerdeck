import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../core/api/unraid_api.dart';
import '../core/api/unraid_client.dart';
import '../data/providers.dart';
import '../l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

String describeError(BuildContext context, Object error) {
  final l = context.l10n;
  if (error is UnraidApiException) {
    return switch (error.kind) {
      ApiErrorKind.unauthorized => l.errorUnauthorized,
      ApiErrorKind.forbidden => l.errorForbidden,
      ApiErrorKind.network || ApiErrorKind.timeout => l.errorNetwork,
      ApiErrorKind.tls => l.errorTls,
      ApiErrorKind.unsupported => l.errorUnsupported,
      _ => error.message,
    };
  }
  return error.toString();
}

/// Renders an [AsyncValue] with consistent loading / error states and
/// pull-to-refresh. Data stays visible while a background poll is running.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.value,
    required this.onRefresh,
    required this.builder,
  });

  final AsyncValue<T> value;
  final Future<void> Function() onRefresh;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (data) => RefreshIndicator(onRefresh: onRefresh, child: builder(data)),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 48),
            Icon(Icons.cloud_off, size: 56, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(context.l10n.errorLoading,
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(describeError(context, error), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Center(
              child: FilledButton.tonal(onPressed: onRefresh, child: Text(context.l10n.retry)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Runs a mutation, shows a snackbar with the result and refreshes [refresh].
Future<bool> runAction(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function(UnraidApi api) action, {
  List<ProviderOrFamily> refresh = const [],
  String? successMessage,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l = context.l10n;
  String failText(Object e) => l.actionFailed(describeError(context, e));
  try {
    await action(ref.read(apiProvider));
    messenger.showSnackBar(SnackBar(content: Text(successMessage ?? l.actionDone)));
    return true;
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(failText(e))));
    return false;
  } finally {
    for (final p in refresh) {
      ref.invalidate(p);
    }
  }
}

Future<bool> confirm(BuildContext context, String message, {String? action, bool destructive = false}) async {
  final l = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error)
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(action ?? l.confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

class UsageBar extends StatelessWidget {
  const UsageBar({super.key, required this.fraction, this.height = 8});

  final double? fraction;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final f = (fraction ?? 0).clamp(0.0, 1.0);
    final color = f > 0.9
        ? scheme.error
        : f > 0.75
            ? Colors.orange
            : scheme.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: fraction == null ? 0 : f,
        minHeight: height,
        color: color,
        backgroundColor: scheme.surfaceContainerHighest,
      ),
    );
  }
}

enum Health { good, warning, bad, idle }

class StatusDot extends StatelessWidget {
  const StatusDot(this.health, {super.key, this.size = 10});

  final Health health;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = switch (health) {
      Health.good => Colors.green,
      Health.warning => Colors.orange,
      Health.bad => Theme.of(context).colorScheme.error,
      Health.idle => Theme.of(context).colorScheme.outline,
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(title.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 1.1,
                    )),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center),
      ],
    );
  }
}

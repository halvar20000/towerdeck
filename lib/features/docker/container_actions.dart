import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/unraid_api.dart';
import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

Future<void> stopContainer(BuildContext context, WidgetRef ref, DockerContainer c) async {
  final l = context.l10n;
  if (!await confirm(context, l.stopConfirm(c.name), action: l.stop, destructive: true)) return;
  if (!context.mounted) return;
  await runAction(
    context,
    ref,
    (api) => api.containerAction(c.id, ContainerAction.stop),
    refresh: [containersProvider],
    busyKey: containerBusyKey(c.id),
  );
}

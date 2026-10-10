// Read-only smoke test against a real server:
//   UNRAID_URL=http://192.168.1.10 UNRAID_API_KEY=... dart run tool/smoke.dart
// Runs every query the app uses and prints a short summary.
import 'dart:io';

import 'package:towerdeck/core/api/unraid_api.dart';
import 'package:towerdeck/core/api/unraid_client.dart';

Future<void> main() async {
  final url = parseServerAddress(Platform.environment['UNRAID_URL'] ?? '');
  final key = Platform.environment['UNRAID_API_KEY'];
  if (url == null || key == null) {
    stderr.writeln('Set UNRAID_URL and UNRAID_API_KEY');
    exit(2);
  }
  final client = UnraidClient(baseUrl: url, apiKey: key);
  final api = UnraidApi(client);
  var failed = false;
  Future<void> check(String name, Future<String> Function() run) async {
    try {
      stdout.writeln('OK   $name: ${await run()}');
    } catch (e) {
      failed = true;
      stdout.writeln('FAIL $name: $e');
    }
  }

  await check('probe', () async => (await api.probe()).toString());
  await check('dashboard', () async {
    final d = await api.dashboard();
    return '${d.hostname} cpu=${d.cpuPercent?.toStringAsFixed(1)}% mem=${d.memPercent?.toStringAsFixed(1)}% '
        'array=${d.arrayState} docker=${d.containersRunning}/${d.containersTotal} vms=${d.vmsRunning}/${d.vmsTotal} '
        'unread=${d.unread.total} uptime=${d.uptime}';
  });
  String? firstContainer;
  await check('containers', () async {
    final c = await api.containers();
    firstContainer = c.where((c) => c.running).firstOrNull?.id;
    return '${c.length} containers, updates=${c.where((c) => c.updateAvailable).length}';
  });
  if (firstContainer != null) {
    await check('logs', () async => '${(await api.containerLogs(firstContainer!, tail: 5)).length} lines');
  }
  await check('vms', () async => (await api.vms()).map((v) => '${v.name}:${v.state}').join(', '));
  await check('storage', () async {
    final s = await api.storage();
    return '${s.state} parity=${s.parities.length} disks=${s.disks.length} pools=${s.caches.length} '
        'shares=${s.shares.length} check=${s.parity.status}';
  });
  await check('notifications', () async =>
      'unread=${(await api.notifications(archived: false)).length} archived=${(await api.notifications(archived: true, limit: 5)).length}');
  client.close();
  exit(failed ? 1 : 0);
}

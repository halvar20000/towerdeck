// Prints every GraphQL document the app sends (queries and mutations) as
// JSON, without contacting a server. Used by tool/validate_graphql.sh.
import 'dart:convert';
import 'dart:io';

import 'package:towerdeck/core/api/unraid_api.dart';
import 'package:towerdeck/core/api/unraid_client.dart';

class _RecordingClient extends UnraidClient {
  _RecordingClient() : super(baseUrl: Uri.parse('http://invalid'), apiKey: '');

  final docs = <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>> execute(String document, {Map<String, dynamic>? variables}) async {
    docs.add({'document': document, 'variables': variables});
    return const {};
  }
}

Future<void> main() async {
  final c = _RecordingClient();
  final api = UnraidApi(c);
  Future<void> run(Future<Object?> Function() f) async {
    try {
      await f();
    } catch (_) {/* parsing empty data may fail – only the document matters */}
  }

  await run(api.probe);
  await run(api.dashboard);
  await run(api.containers);
  await run(() => api.containerLogs('x'));
  await run(api.vms);
  await run(api.storage);
  await run(() => api.notifications(archived: false));
  for (final a in ContainerAction.values) {
    await run(() => api.containerAction('x', a));
  }
  await run(() => api.updateContainer('x'));
  await run(api.updateAllContainers);
  for (final a in VmAction.values) {
    await run(() => api.vmAction('x', a));
  }
  await run(() => api.setArrayState(start: true));
  for (final a in ParityAction.values) {
    await run(() => api.parityCheck(a));
  }
  await run(() => api.archiveNotification('x'));
  await run(api.archiveAll);
  await run(() => api.deleteNotification('x', archived: true));
  stdout.writeln(jsonEncode(c.docs));
}

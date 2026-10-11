import '../models/models.dart';
import 'unraid_client.dart';

/// Typed wrapper around the Unraid GraphQL API.
///
/// Requires Unraid API 4.29 or newer (validated by tool/validate_graphql.sh).
class UnraidApi {
  UnraidApi(this.client);

  final UnraidClient client;

  /// The server pulls the image before answering, which can take minutes.
  static const updateTimeout = Duration(minutes: 10);

  // ---- Queries ------------------------------------------------------------

  /// Cheap call used to validate a connection; returns hostname and roles.
  Future<({String hostname, List<String> roles, String? version})> probe() async {
    final d = await client.execute('''
      query Probe {
        info { os { hostname } versions { core { unraid } } }
        me { roles }
      }''');
    final info = d['info'] as Map<String, dynamic>? ?? const {};
    final os = info['os'] as Map<String, dynamic>? ?? const {};
    final core = (info['versions'] as Map?)?['core'] as Map?;
    final roles = ((d['me'] as Map?)?['roles'] as List?)?.map((e) => e.toString()).toList();
    return (
      hostname: os['hostname']?.toString() ?? 'Unraid',
      roles: roles ?? const <String>[],
      version: core?['unraid']?.toString(),
    );
  }

  Future<Dashboard> dashboard() async {
    final d = await client.execute('''
      query Dashboard {
        info {
          os { hostname uptime }
          cpu { brand threads }
          versions { core { unraid api } }
        }
        metrics {
          cpu { percentTotal }
          memory { total available percentTotal }
        }
        array {
          state
          capacity { kilobytes { used total } }
          parityCheckStatus { status progress running paused errors date }
        }
        docker { containers { state isUpdateAvailable } }
        vms { domains { state } }
        notifications { overview { unread { info warning alert } } }
        me { roles }
      }''');
    return Dashboard.fromJson(d);
  }

  Future<List<DockerContainer>> containers() async {
    final d = await client.execute('''
      query Containers {
        docker {
          containers {
            id names image state status autoStart isUpdateAvailable
            webUiUrl iconUrl projectUrl supportUrl
            ports { privatePort publicPort type }
          }
        }
      }''');
    final list = ((d['docker'] as Map?)?['containers'] as List?) ?? const [];
    final result = list.cast<Map<String, dynamic>>().map(DockerContainer.fromJson).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  Future<List<LogLine>> containerLogs(String id, {int tail = 200}) async {
    final d = await client.execute(
      r'''
      query Logs($id: PrefixedID!, $tail: Int) {
        docker { logs(id: $id, tail: $tail) { lines { timestamp message } } }
      }''',
      variables: {'id': id, 'tail': tail},
    );
    final lines = (((d['docker'] as Map?)?['logs'] as Map?)?['lines'] as List?) ?? const [];
    return lines.cast<Map<String, dynamic>>().map(LogLine.fromJson).toList();
  }

  Future<List<VirtualMachine>> vms() async {
    final d = await client.execute('query Vms { vms { domains { id name state } } }');
    final list = ((d['vms'] as Map?)?['domains'] as List?) ?? const [];
    return list.cast<Map<String, dynamic>>().map(VirtualMachine.fromJson).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<StorageInfo> storage() async {
    const diskFields =
        'id name type device size fsSize fsUsed status temp isSpinning numErrors fsType';
    final d = await client.execute('''
      query Storage {
        array {
          state
          capacity { kilobytes { used total } }
          parityCheckStatus { status progress running paused correcting errors date duration speed }
          parities { $diskFields }
          disks { $diskFields }
          caches { $diskFields }
        }
        shares { name used free comment }
      }''');
    return StorageInfo.fromJson(d);
  }

  Future<List<UnraidNotification>> notifications({
    required bool archived,
    int offset = 0,
    int limit = 50,
  }) async {
    final d = await client.execute(
      r'''
      query Notifications($filter: NotificationFilter!) {
        notifications {
          list(filter: $filter) { id title subject description importance timestamp link }
        }
      }''',
      variables: {
        'filter': {'type': archived ? 'ARCHIVE' : 'UNREAD', 'offset': offset, 'limit': limit},
      },
    );
    final list = ((d['notifications'] as Map?)?['list'] as List?) ?? const [];
    return list.cast<Map<String, dynamic>>().map(UnraidNotification.fromJson).toList();
  }

  // ---- Mutations ----------------------------------------------------------

  Future<void> containerAction(String id, ContainerAction action) async {
    try {
      await client.execute(
        'mutation(\$id: PrefixedID!) { docker { ${action.name}(id: \$id) { id state } } }',
        variables: {'id': id},
      );
    } on UnraidApiException catch (e) {
      // `restart` only exists since API 4.36.
      if (action != ContainerAction.restart || e.kind != ApiErrorKind.unsupported) rethrow;
      await containerAction(id, ContainerAction.stop);
      await containerAction(id, ContainerAction.start);
    }
  }

  Future<void> updateContainer(String id) => client.execute(
        r'mutation($id: PrefixedID!) { docker { updateContainer(id: $id) { id } } }',
        variables: {'id': id},
        timeout: updateTimeout,
      );

  Future<void> updateAllContainers() =>
      client.execute('mutation { docker { updateAllContainers { id } } }',
          timeout: updateTimeout * 4);

  Future<void> vmAction(String id, VmAction action) => client.execute(
        'mutation(\$id: PrefixedID!) { vm { ${action.name}(id: \$id) } }',
        variables: {'id': id},
      );

  Future<void> setArrayState({required bool start}) => client.execute(
        r'mutation($input: ArrayStateInput!) { array { setState(input: $input) { state } } }',
        variables: {
          'input': {'desiredState': start ? 'START' : 'STOP'},
        },
      );

  Future<void> parityCheck(ParityAction action, {bool correct = false}) => client.execute(
        action == ParityAction.start
            ? 'mutation(\$c: Boolean!) { parityCheck { start(correct: \$c) } }'
            : 'mutation { parityCheck { ${action.name} } }',
        variables: action == ParityAction.start ? {'c': correct} : null,
      );

  Future<void> archiveNotification(String id) => client.execute(
        r'mutation($id: PrefixedID!) { archiveNotification(id: $id) { id } }',
        variables: {'id': id},
      );

  Future<void> archiveAll() => client.execute('mutation { archiveAll { unread { total } } }');

  Future<void> deleteNotification(String id, {required bool archived}) => client.execute(
        r'mutation($id: PrefixedID!, $type: NotificationType!) { deleteNotification(id: $id, type: $type) { archive { total } } }',
        variables: {'id': id, 'type': archived ? 'ARCHIVE' : 'UNREAD'},
      );
}

enum ContainerAction { start, stop, restart, pause, unpause }

enum VmAction { start, stop, pause, resume, forceStop, reboot }

enum ParityAction { start, pause, resume, cancel }

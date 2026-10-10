import 'dart:math';

import '../models/models.dart';
import 'unraid_api.dart';
import 'unraid_client.dart';

const demoServerId = 'demo';

/// Offline stand-in for [UnraidApi] with realistic sample data. Used for
/// App Store / Play review (reviewers have no Unraid server) and screenshots.
/// Actions mutate the in-memory state so the UI reacts as it would for real.
class DemoApi extends UnraidApi {
  DemoApi() : super(UnraidClient(baseUrl: Uri.parse('http://demo.invalid'), apiKey: ''));

  final _rnd = Random();
  final _boot = DateTime.now().subtract(const Duration(days: 12, hours: 7));

  final Map<String, String> _containerState = {
    for (final c in _containers) c.$1: c.$4 ? 'RUNNING' : 'EXITED',
  };
  final Set<String> _updates = {'jellyfin', 'nextcloud', 'homeassistant'};
  final Map<String, String> _vmState = {'vm-ha': 'RUNNING', 'vm-win': 'SHUTOFF'};
  bool _arrayStarted = true;
  int? _parityProgress;
  final List<UnraidNotification> _unread = [
    UnraidNotification(
      id: 'n1',
      title: 'Unraid Status',
      subject: 'Docker updates available',
      description: '3 container updates are available.',
      importance: 'WARNING',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    UnraidNotification(
      id: 'n2',
      title: 'Unraid Status',
      subject: 'Backup Notification',
      description: 'Appdata backup finished successfully.',
      importance: 'INFO',
      timestamp: DateTime.now().subtract(const Duration(hours: 9)),
    ),
    UnraidNotification(
      id: 'n3',
      title: 'Unraid Parity check',
      subject: 'Parity check finished (0 errors)',
      description: 'Duration: 19 hours, 42 minutes. Average speed: 169.3 MB/s',
      importance: 'INFO',
      timestamp: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];
  final List<UnraidNotification> _archive = [];

  // (id, name, image, autostart, port)
  static const _containers = [
    ('c1', 'plex', 'plexinc/pms-docker', true, 32400),
    ('c2', 'jellyfin', 'jellyfin/jellyfin', true, 8096),
    ('c3', 'nextcloud', 'lscr.io/linuxserver/nextcloud', true, 443),
    ('c4', 'homeassistant', 'ghcr.io/home-assistant/home-assistant', true, 8123),
    ('c5', 'vaultwarden', 'vaultwarden/server', true, 4743),
    ('c6', 'immich', 'ghcr.io/immich-app/immich-server', true, 2283),
    ('c7', 'paperless-ngx', 'ghcr.io/paperless-ngx/paperless-ngx', true, 8000),
    ('c8', 'syncthing', 'lscr.io/linuxserver/syncthing', false, 8384),
    ('c9', 'speedtest-tracker', 'lscr.io/linuxserver/speedtest-tracker', false, 8765),
  ];

  Future<T> _delay<T>(T value) =>
      Future.delayed(Duration(milliseconds: 150 + _rnd.nextInt(250)), () => value);

  int get _unreadWarnings => _unread.where((n) => n.importance == 'WARNING').length;

  ParityStatus get _parity => _parityProgress == null
      ? ParityStatus(status: 'COMPLETED', errors: 0, date: DateTime.now().subtract(const Duration(days: 4)))
      : ParityStatus(status: 'RUNNING', running: true, progress: _parityProgress, speed: '182.4 MB/s');

  @override
  Future<({String hostname, List<String> roles, String? version})> probe() =>
      _delay((hostname: 'Demo-Tower', roles: const ['ADMIN'], version: '7.3.1'));

  @override
  Future<Dashboard> dashboard() {
    if (_parityProgress != null) _parityProgress = min(99, _parityProgress! + 1);
    final running = _containerState.values.where((s) => s == 'RUNNING').length;
    return _delay(Dashboard(
      hostname: 'Demo-Tower',
      unraidVersion: '7.3.1',
      apiVersion: '4.37.4',
      cpuBrand: 'AMD Ryzen 7 5700G',
      threads: 16,
      bootTime: _boot,
      cpuPercent: 8 + _rnd.nextDouble() * 20,
      memPercent: 41 + _rnd.nextDouble() * 4,
      memTotal: 64 * 1000 * 1000 * 1000,
      memAvailable: 36 * 1000 * 1000 * 1000,
      arrayState: _arrayStarted ? 'STARTED' : 'STOPPED',
      arrayUsedKiB: 31250000000,
      arrayTotalKiB: 46875000000,
      parity: _parity,
      unread: NotificationCounts(info: _unread.length - _unreadWarnings, warning: _unreadWarnings),
      containersRunning: running,
      containersTotal: _containers.length,
      updatesAvailable: _updates.length,
      vmsRunning: _vmState.values.where((s) => s == 'RUNNING').length,
      vmsTotal: _vmState.length,
      roles: const ['ADMIN'],
    ));
  }

  @override
  Future<List<DockerContainer>> containers() => _delay([
        for (final c in _containers)
          DockerContainer(
            id: c.$1,
            name: c.$2,
            image: c.$3,
            state: _containerState[c.$1]!,
            status: switch (_containerState[c.$1]) {
              'RUNNING' => 'Up 12 days (healthy)',
              'PAUSED' => 'Up 12 days (Paused)',
              _ => 'Exited (0) 3 days ago',
            },
            autoStart: c.$4,
            updateAvailable: _updates.contains(c.$2),
            webUiUrl: 'http://demo.invalid:${c.$5}',
            ports: [ContainerPort(privatePort: c.$5, publicPort: c.$5, type: 'TCP')],
          ),
      ]..sort((a, b) => a.name.compareTo(b.name)));

  @override
  Future<List<LogLine>> containerLogs(String id, {int tail = 200}) {
    final now = DateTime.now();
    return _delay([
      for (var i = 30; i > 0; i--)
        LogLine(now.subtract(Duration(minutes: i * 3)),
            i.isEven ? '[INFO] Health check OK' : '[INFO] GET /api/status 200 (${4 + i % 7} ms)'),
    ]);
  }

  @override
  Future<List<VirtualMachine>> vms() => _delay([
        VirtualMachine(id: 'vm-ha', name: 'HomeAssistant OS', state: _vmState['vm-ha']!),
        VirtualMachine(id: 'vm-win', name: 'Windows 11', state: _vmState['vm-win']!),
      ]);

  @override
  Future<StorageInfo> storage() {
    ArrayDisk disk(String name, String type, int sizeTb, double used, int temp, {bool spinning = true}) {
      final kib = sizeTb * 976562500;
      return ArrayDisk(
        id: name,
        name: name,
        type: type,
        device: 'sd${String.fromCharCode(97 + name.hashCode % 8)}',
        sizeKiB: kib,
        fsSizeKiB: type == 'PARITY' ? null : kib,
        fsUsedKiB: type == 'PARITY' ? null : (kib * used).round(),
        status: 'DISK_OK',
        temp: spinning ? temp : null,
        spinning: spinning,
        errors: 0,
        fsType: type == 'PARITY' ? null : (type == 'CACHE' ? 'zfs' : 'xfs'),
      );
    }

    return _delay(StorageInfo(
      state: _arrayStarted ? 'STARTED' : 'STOPPED',
      parity: _parity,
      usedKiB: 31250000000,
      totalKiB: 46875000000,
      parities: [disk('parity', 'PARITY', 16, 0, 38)],
      disks: [
        disk('disk1', 'DATA', 16, 0.82, 36),
        disk('disk2', 'DATA', 16, 0.74, 35),
        disk('disk3', 'DATA', 16, 0.41, 0, spinning: false),
      ],
      caches: [disk('cache', 'CACHE', 2, 0.37, 44)],
      shares: const [
        Share(name: 'appdata', usedKiB: 180000000, freeKiB: 1100000000),
        Share(name: 'media', usedKiB: 24000000000, freeKiB: 15600000000, comment: 'Movies & TV'),
        Share(name: 'photos', usedKiB: 2100000000, freeKiB: 15600000000),
        Share(name: 'backup', usedKiB: 4800000000, freeKiB: 15600000000),
      ],
    ));
  }

  @override
  Future<List<UnraidNotification>> notifications({required bool archived, int offset = 0, int limit = 50}) =>
      _delay(List.of(archived ? _archive : _unread));

  @override
  Future<void> containerAction(String id, ContainerAction action) async {
    _containerState[id] = switch (action) {
      ContainerAction.stop => 'EXITED',
      ContainerAction.pause => 'PAUSED',
      _ => 'RUNNING',
    };
    await _delay(null);
  }

  @override
  Future<void> updateContainer(String id) async {
    _updates.remove(_containers.firstWhere((c) => c.$1 == id).$2);
    await Future<void>.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> updateAllContainers() async {
    _updates.clear();
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  @override
  Future<void> vmAction(String id, VmAction action) async {
    _vmState[id] = switch (action) {
      VmAction.stop || VmAction.forceStop => 'SHUTOFF',
      VmAction.pause => 'PAUSED',
      _ => 'RUNNING',
    };
    await _delay(null);
  }

  @override
  Future<void> setArrayState({required bool start}) async {
    _arrayStarted = start;
    if (!start) {
      for (final id in _containerState.keys) {
        _containerState[id] = 'EXITED';
      }
      _vmState.updateAll((_, _) => 'SHUTOFF');
    }
    await Future<void>.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> parityCheck(ParityAction action, {bool correct = false}) async {
    _parityProgress = action == ParityAction.start ? 0 : (action == ParityAction.cancel ? null : _parityProgress);
    await _delay(null);
  }

  @override
  Future<void> archiveNotification(String id) async {
    final n = _unread.firstWhere((n) => n.id == id);
    _unread.remove(n);
    _archive.insert(0, n);
    await _delay(null);
  }

  @override
  Future<void> archiveAll() async {
    _archive.insertAll(0, _unread);
    _unread.clear();
    await _delay(null);
  }

  @override
  Future<void> deleteNotification(String id, {required bool archived}) async {
    (archived ? _archive : _unread).removeWhere((n) => n.id == id);
    await _delay(null);
  }
}

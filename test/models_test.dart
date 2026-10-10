import 'package:flutter_test/flutter_test.dart';
import 'package:towerdeck/core/api/unraid_client.dart';
import 'package:towerdeck/core/format.dart';
import 'package:towerdeck/core/models/models.dart';

void main() {
  group('Dashboard.fromJson', () {
    // Shape taken from a real Unraid 7.3.1 / API 4.37.4 response.
    final json = {
      'info': {
        'os': {'hostname': 'Tower', 'uptime': '2026-09-26T19:36:31.199Z'},
        'cpu': {'brand': 'Ryzen 9 7900X 12-Core Processor', 'threads': 24},
        'versions': {
          'core': {'unraid': '7.3.1', 'api': '4.37.4+ad268301'},
        },
      },
      'metrics': {
        'cpu': {'percentTotal': 13.43},
        'memory': {'total': 66549534720, 'available': 35000000000, 'percentTotal': 46.96},
      },
      'array': {
        'state': 'STARTED',
        'capacity': {
          'kilobytes': {'used': '51918076944', 'total': '67398805590'},
        },
        'parityCheckStatus': {'status': 'COMPLETED', 'progress': 0, 'running': null, 'date': '2026-09-27T07:24:22.000Z'},
      },
      'docker': {
        'containers': [
          {'state': 'RUNNING', 'isUpdateAvailable': true},
          {'state': 'RUNNING', 'isUpdateAvailable': false},
          {'state': 'EXITED', 'isUpdateAvailable': null},
        ],
      },
      'vms': {
        'domains': [
          {'state': 'RUNNING'},
          {'state': 'SHUTOFF'},
        ],
      },
      'notifications': {
        'overview': {
          'unread': {'info': 29, 'warning': 1, 'alert': 0},
        },
      },
      'me': {
        'roles': ['VIEWER'],
      },
    };

    test('parses all sections', () {
      final d = Dashboard.fromJson(json);
      expect(d.hostname, 'Tower');
      expect(d.unraidVersion, '7.3.1');
      expect(d.threads, 24);
      expect(d.arrayState, 'STARTED');
      expect(d.arrayUsedKiB, 51918076944); // string BigInt
      expect(d.arrayFraction, closeTo(0.77, 0.01));
      expect(d.parity.status, 'COMPLETED');
      expect(d.parity.active, isFalse);
      expect(d.containersRunning, 2);
      expect(d.containersTotal, 3);
      expect(d.updatesAvailable, 1);
      expect(d.vmsRunning, 1);
      expect(d.unread.total, 30);
      expect(d.roles, ['VIEWER']);
      expect(d.uptime, isNotNull);
    });

    test('tolerates missing sections', () {
      final d = Dashboard.fromJson(const {});
      expect(d.hostname, 'Unraid');
      expect(d.arrayFraction, isNull);
      expect(d.containersTotal, 0);
    });
  });

  test('DockerContainer strips leading slash and parses ports', () {
    final c = DockerContainer.fromJson({
      'id': 'abc:123',
      'names': ['/bitwarden'],
      'image': 'vaultwarden/server',
      'state': 'RUNNING',
      'status': 'Up 2 days (healthy)',
      'autoStart': true,
      'isUpdateAvailable': false,
      'webUiUrl': 'http://192.168.86.230:4743/admin',
      'iconUrl': '',
      'ports': [
        {'privatePort': 80, 'publicPort': 4743, 'type': 'TCP'},
      ],
    });
    expect(c.name, 'bitwarden');
    expect(c.running, isTrue);
    expect(c.iconUrl, isNull);
    expect(c.ports.single.toString(), '4743 → 80/TCP');
  });

  test('ArrayDisk usage and health', () {
    final d = ArrayDisk.fromJson({
      'name': 'disk1',
      'type': 'DATA',
      'fsSize': 11998001574,
      'fsUsed': 10501015052,
      'status': 'DISK_OK',
      'temp': 37,
      'isSpinning': true,
    });
    expect(d.healthy, isTrue);
    expect(d.usedFraction, closeTo(0.875, 0.001));
    expect(ArrayDisk.fromJson({'name': 'disk2', 'status': 'DISK_DSBL'}).healthy, isFalse);
  });

  group('format', () {
    test('formatBytes uses SI units', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(1500), '1.5 KB');
      expect(formatBytes(12e12), '12.0 TB');
      expect(formatBytes(null), '–');
    });

    test('formatKiB converts from KiB', () {
      // 12 TB drive as reported by Unraid.
      expect(formatKiB(11718885324), '12.0 TB');
    });

    test('formatDuration', () {
      expect(formatDuration(const Duration(days: 13, hours: 5)), '13d 5h');
      expect(formatDuration(const Duration(hours: 3, minutes: 7)), '3h 7m');
      expect(formatDuration(const Duration(minutes: 9)), '9m');
    });
  });

  group('parseServerAddress', () {
    test('adds http by default', () {
      expect(parseServerAddress('192.168.1.10').toString(), 'http://192.168.1.10');
      expect(parseServerAddress(' tower.local:8080 ').toString(), 'http://tower.local:8080');
    });

    test('keeps https and strips paths', () {
      expect(parseServerAddress('https://tower.local/Dashboard').toString(), 'https://tower.local');
    });

    test('rejects garbage', () {
      expect(parseServerAddress(''), isNull);
      expect(parseServerAddress('ftp://x'), isNull);
    });
  });
}

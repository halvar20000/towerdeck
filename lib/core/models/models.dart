import '../format.dart';

typedef Json = Map<String, dynamic>;

List<Json> _list(Object? v) =>
    v is List ? v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList() : const [];

Json _map(Object? v) => v is Map ? v.cast<String, dynamic>() : const {};

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------

class NotificationCounts {
  const NotificationCounts({this.info = 0, this.warning = 0, this.alert = 0});

  factory NotificationCounts.fromJson(Json j) => NotificationCounts(
        info: asInt(j['info']) ?? 0,
        warning: asInt(j['warning']) ?? 0,
        alert: asInt(j['alert']) ?? 0,
      );

  final int info;
  final int warning;
  final int alert;

  int get total => info + warning + alert;
}

class ParityStatus {
  const ParityStatus({
    required this.status,
    this.progress,
    this.running = false,
    this.paused = false,
    this.correcting = false,
    this.errors,
    this.date,
    this.duration,
    this.speed,
  });

  factory ParityStatus.fromJson(Json j) => ParityStatus(
        status: j['status']?.toString() ?? 'NEVER_RUN',
        progress: asInt(j['progress']),
        running: j['running'] == true || j['status'] == 'RUNNING',
        paused: j['paused'] == true || j['status'] == 'PAUSED',
        correcting: j['correcting'] == true,
        errors: asInt(j['errors']),
        date: asDate(j['date']),
        duration: asInt(j['duration']),
        speed: j['speed']?.toString(),
      );

  final String status;
  final int? progress;
  final bool running;
  final bool paused;
  final bool correcting;
  final int? errors;
  final DateTime? date;
  final int? duration;
  final String? speed;

  bool get active => running || paused;
}

class Dashboard {
  const Dashboard({
    required this.hostname,
    required this.unraidVersion,
    required this.apiVersion,
    required this.cpuBrand,
    required this.threads,
    required this.bootTime,
    required this.cpuPercent,
    required this.memPercent,
    required this.memTotal,
    required this.memAvailable,
    required this.arrayState,
    required this.arrayUsedKiB,
    required this.arrayTotalKiB,
    required this.parity,
    required this.unread,
    required this.containersRunning,
    required this.containersTotal,
    required this.updatesAvailable,
    required this.vmsRunning,
    required this.vmsTotal,
    required this.roles,
  });

  factory Dashboard.fromJson(Json d) {
    final info = _map(d['info']);
    final os = _map(info['os']);
    final cpu = _map(info['cpu']);
    final core = _map(_map(info['versions'])['core']);
    final metrics = _map(d['metrics']);
    final mem = _map(metrics['memory']);
    final array = _map(d['array']);
    final kb = _map(_map(array['capacity'])['kilobytes']);
    final containers = _list(_map(d['docker'])['containers']);
    final vms = _list(_map(d['vms'])['domains']);
    return Dashboard(
      hostname: os['hostname']?.toString() ?? 'Unraid',
      unraidVersion: core['unraid']?.toString(),
      apiVersion: core['api']?.toString(),
      cpuBrand: cpu['brand']?.toString(),
      threads: asInt(cpu['threads']),
      bootTime: asDate(os['uptime']),
      cpuPercent: asDouble(_map(metrics['cpu'])['percentTotal']),
      memPercent: asDouble(mem['percentTotal']),
      memTotal: asInt(mem['total']),
      memAvailable: asInt(mem['available']),
      arrayState: array['state']?.toString() ?? 'UNKNOWN',
      arrayUsedKiB: asInt(kb['used']),
      arrayTotalKiB: asInt(kb['total']),
      parity: ParityStatus.fromJson(_map(array['parityCheckStatus'])),
      unread: NotificationCounts.fromJson(_map(_map(_map(d['notifications'])['overview'])['unread'])),
      containersRunning: containers.where((c) => c['state'] == 'RUNNING').length,
      containersTotal: containers.length,
      updatesAvailable: containers.where((c) => c['isUpdateAvailable'] == true).length,
      vmsRunning: vms.where((v) => v['state'] == 'RUNNING').length,
      vmsTotal: vms.length,
      roles: (_map(d['me'])['roles'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  final String hostname;
  final String? unraidVersion;
  final String? apiVersion;
  final String? cpuBrand;
  final int? threads;
  final DateTime? bootTime;
  final double? cpuPercent;
  final double? memPercent;
  final int? memTotal;
  final int? memAvailable;
  final String arrayState;
  final int? arrayUsedKiB;
  final int? arrayTotalKiB;
  final ParityStatus parity;
  final NotificationCounts unread;
  final int containersRunning;
  final int containersTotal;
  final int updatesAvailable;
  final int vmsRunning;
  final int vmsTotal;
  final List<String> roles;

  Duration? get uptime => bootTime == null ? null : DateTime.now().difference(bootTime!);

  double? get arrayFraction => (arrayUsedKiB != null && (arrayTotalKiB ?? 0) > 0)
      ? arrayUsedKiB! / arrayTotalKiB!
      : null;
}

// ---------------------------------------------------------------------------
// Docker
// ---------------------------------------------------------------------------

class ContainerPort {
  const ContainerPort({this.privatePort, this.publicPort, required this.type});

  factory ContainerPort.fromJson(Json j) => ContainerPort(
        privatePort: asInt(j['privatePort']),
        publicPort: asInt(j['publicPort']),
        type: j['type']?.toString() ?? 'TCP',
      );

  final int? privatePort;
  final int? publicPort;
  final String type;

  @override
  String toString() =>
      publicPort == null ? '$privatePort/$type' : '$publicPort → $privatePort/$type';
}

class DockerContainer {
  const DockerContainer({
    required this.id,
    required this.name,
    required this.image,
    required this.state,
    required this.status,
    required this.autoStart,
    required this.updateAvailable,
    this.webUiUrl,
    this.iconUrl,
    this.ports = const [],
    this.projectUrl,
    this.supportUrl,
  });

  factory DockerContainer.fromJson(Json j) {
    final names = (j['names'] as List?)?.map((e) => e.toString()).toList() ?? const [];
    final raw = names.isEmpty ? j['id'].toString() : names.first;
    return DockerContainer(
      id: j['id'].toString(),
      name: raw.startsWith('/') ? raw.substring(1) : raw,
      image: j['image']?.toString() ?? '',
      state: j['state']?.toString() ?? 'EXITED',
      status: j['status']?.toString() ?? '',
      autoStart: j['autoStart'] == true,
      updateAvailable: j['isUpdateAvailable'] == true,
      webUiUrl: _nonEmpty(j['webUiUrl']),
      iconUrl: _nonEmpty(j['iconUrl']),
      ports: _list(j['ports']).map(ContainerPort.fromJson).toList(),
      projectUrl: _nonEmpty(j['projectUrl']),
      supportUrl: _nonEmpty(j['supportUrl']),
    );
  }

  final String id;
  final String name;
  final String image;
  final String state;
  final String status;
  final bool autoStart;
  final bool updateAvailable;
  final String? webUiUrl;
  final String? iconUrl;
  final List<ContainerPort> ports;
  final String? projectUrl;
  final String? supportUrl;

  bool get running => state == 'RUNNING';
  bool get paused => state == 'PAUSED';
}

class LogLine {
  const LogLine(this.timestamp, this.message);

  factory LogLine.fromJson(Json j) =>
      LogLine(asDate(j['timestamp']), j['message']?.toString() ?? '');

  final DateTime? timestamp;
  final String message;
}

// ---------------------------------------------------------------------------
// VMs
// ---------------------------------------------------------------------------

class VirtualMachine {
  const VirtualMachine({required this.id, required this.name, required this.state});

  factory VirtualMachine.fromJson(Json j) => VirtualMachine(
        id: j['id'].toString(),
        name: j['name']?.toString() ?? j['id'].toString(),
        state: j['state']?.toString() ?? 'NOSTATE',
      );

  final String id;
  final String name;
  final String state;

  bool get running => state == 'RUNNING' || state == 'IDLE';
  bool get paused => state == 'PAUSED' || state == 'PMSUSPENDED';
}

// ---------------------------------------------------------------------------
// Storage
// ---------------------------------------------------------------------------

class ArrayDisk {
  const ArrayDisk({
    required this.id,
    required this.name,
    required this.type,
    this.device,
    this.sizeKiB,
    this.fsSizeKiB,
    this.fsUsedKiB,
    this.status,
    this.temp,
    this.spinning,
    this.errors,
    this.fsType,
  });

  factory ArrayDisk.fromJson(Json j) => ArrayDisk(
        id: j['id']?.toString() ?? j['name'].toString(),
        name: j['name']?.toString() ?? '?',
        type: j['type']?.toString() ?? 'DATA',
        device: j['device']?.toString(),
        sizeKiB: asInt(j['size']),
        fsSizeKiB: asInt(j['fsSize']),
        fsUsedKiB: asInt(j['fsUsed']),
        status: j['status']?.toString(),
        temp: asInt(j['temp']),
        spinning: j['isSpinning'] as bool?,
        errors: asInt(j['numErrors']),
        fsType: _nonEmpty(j['fsType']),
      );

  final String id;
  final String name;
  final String type;
  final String? device;
  final int? sizeKiB;
  final int? fsSizeKiB;
  final int? fsUsedKiB;
  final String? status;
  final int? temp;
  final bool? spinning;
  final int? errors;
  final String? fsType;

  bool get healthy => status == null || status == 'DISK_OK';

  double? get usedFraction =>
      (fsUsedKiB != null && (fsSizeKiB ?? 0) > 0) ? fsUsedKiB! / fsSizeKiB! : null;
}

class Share {
  const Share({required this.name, this.usedKiB, this.freeKiB, this.comment});

  factory Share.fromJson(Json j) => Share(
        name: j['name']?.toString() ?? '?',
        usedKiB: asInt(j['used']),
        freeKiB: asInt(j['free']),
        comment: _nonEmpty(j['comment']),
      );

  final String name;
  final int? usedKiB;
  final int? freeKiB;
  final String? comment;
}

class StorageInfo {
  const StorageInfo({
    required this.state,
    required this.parities,
    required this.disks,
    required this.caches,
    required this.parity,
    required this.shares,
    this.usedKiB,
    this.totalKiB,
  });

  factory StorageInfo.fromJson(Json d) {
    final a = _map(d['array']);
    final kb = _map(_map(a['capacity'])['kilobytes']);
    return StorageInfo(
      state: a['state']?.toString() ?? 'UNKNOWN',
      parities: _list(a['parities']).map(ArrayDisk.fromJson).toList(),
      disks: _list(a['disks']).map(ArrayDisk.fromJson).toList(),
      caches: _list(a['caches']).map(ArrayDisk.fromJson).toList(),
      parity: ParityStatus.fromJson(_map(a['parityCheckStatus'])),
      shares: _list(d['shares']).map(Share.fromJson).toList(),
      usedKiB: asInt(kb['used']),
      totalKiB: asInt(kb['total']),
    );
  }

  final String state;
  final List<ArrayDisk> parities;
  final List<ArrayDisk> disks;
  final List<ArrayDisk> caches;
  final ParityStatus parity;
  final List<Share> shares;
  final int? usedKiB;
  final int? totalKiB;

  bool get started => state == 'STARTED';
}

// ---------------------------------------------------------------------------
// Notifications
// ---------------------------------------------------------------------------

class UnraidNotification {
  const UnraidNotification({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.importance,
    this.timestamp,
    this.link,
  });

  factory UnraidNotification.fromJson(Json j) => UnraidNotification(
        id: j['id'].toString(),
        title: j['title']?.toString() ?? '',
        subject: j['subject']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        importance: j['importance']?.toString() ?? 'INFO',
        timestamp: asDate(j['timestamp']),
        link: _nonEmpty(j['link']),
      );

  final String id;
  final String title;
  final String subject;
  final String description;
  final String importance;
  final DateTime? timestamp;
  final String? link;
}

String? _nonEmpty(Object? v) {
  final s = v?.toString();
  return (s == null || s.isEmpty) ? null : s;
}

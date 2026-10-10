/// Formatting helpers shared across screens.
library;

/// Parses numbers that the API may deliver as int, double or string
/// (BigInt scalars are sometimes serialised as strings).
int? asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt();
  return null;
}

double? asDouble(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

DateTime? asDate(Object? v) =>
    v is String && v.isNotEmpty ? DateTime.tryParse(v)?.toLocal() : null;

const _units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];

/// Formats bytes with decimal (SI) units, like the Unraid WebGUI does.
String formatBytes(num? bytes, {int decimals = 1}) {
  if (bytes == null) return '–';
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1000 && unit < _units.length - 1) {
    value /= 1000;
    unit++;
  }
  final digits = unit == 0 ? 0 : decimals;
  return '${value.toStringAsFixed(digits)} ${_units[unit]}';
}

/// Unraid reports array and share sizes in KiB.
String formatKiB(num? kib) => formatBytes(kib == null ? null : kib * 1024);

String formatPercent(double? fraction) =>
    fraction == null ? '–' : '${(fraction * 100).toStringAsFixed(0)} %';

/// Compact duration such as "12d 4h" or "3h 12m".
String formatDuration(Duration d) {
  if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
  if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
  return '${d.inMinutes}m';
}

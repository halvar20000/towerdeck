// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TowerDeck';

  @override
  String get navDashboard => 'Overview';

  @override
  String get navDocker => 'Docker';

  @override
  String get navVms => 'VMs';

  @override
  String get navStorage => 'Storage';

  @override
  String get navNotifications => 'Alerts';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get search => 'Search';

  @override
  String get settings => 'Settings';

  @override
  String get servers => 'Servers';

  @override
  String get readOnlyBanner =>
      'API key without Admin role – actions are disabled.';

  @override
  String get errorLoading => 'Could not load data';

  @override
  String get errorUnauthorized =>
      'The API key was rejected. Reconnect the server.';

  @override
  String get errorForbidden =>
      'This API key is not allowed to do that. Actions need a key with the Admin role: edit the server and use “Sign in via WebGUI”.';

  @override
  String get errorNetwork =>
      'Server not reachable. Are you in the right network or VPN?';

  @override
  String get errorTls =>
      'Secure connection failed. The certificate may have changed.';

  @override
  String get actionDone => 'Done';

  @override
  String actionFailed(String message) {
    return 'Failed: $message';
  }

  @override
  String get welcomeTitle => 'Manage your Unraid server';

  @override
  String get welcomeBody =>
      'Requires Unraid 7.2 or newer (or the Unraid Connect plugin on older versions).';

  @override
  String get addServer => 'Add server';

  @override
  String get editServer => 'Edit server';

  @override
  String get serverAddress => 'Server address';

  @override
  String get serverAddressHint => 'e.g. 192.168.1.10 or https://tower.local';

  @override
  String get serverAddressInvalid => 'Enter a valid address';

  @override
  String get serverName => 'Display name (optional)';

  @override
  String get apiKey => 'API key';

  @override
  String get apiKeyHelp =>
      'Create one in the WebGUI under Settings → Management Access → API Keys, or with: unraid-api apikey --create';

  @override
  String get connectWithWebGui => 'Sign in via WebGUI';

  @override
  String get connectWithWebGuiHelp =>
      'Log in to your server and approve access – the key is created automatically.';

  @override
  String get orEnterKey => 'or paste an existing API key';

  @override
  String get accessLevel => 'Access';

  @override
  String get accessFull => 'Full control';

  @override
  String get accessReadOnly => 'Read only';

  @override
  String get allowSelfSigned => 'Accept self-signed certificate';

  @override
  String get allowSelfSignedHelp =>
      'The certificate is pinned on first connect.';

  @override
  String get testAndSave => 'Connect';

  @override
  String get connecting => 'Connecting…';

  @override
  String connectedTo(String host) {
    return 'Connected to $host';
  }

  @override
  String get switchedToHttps => 'Server uses HTTPS – address updated.';

  @override
  String get removeServer => 'Remove server';

  @override
  String removeServerConfirm(String name) {
    return 'Remove $name from this device?';
  }

  @override
  String get authorizeTitle => 'Approve access';

  @override
  String get uptime => 'Uptime';

  @override
  String get cpu => 'CPU';

  @override
  String get memory => 'Memory';

  @override
  String get array => 'Array';

  @override
  String get arrayStarted => 'Started';

  @override
  String get arrayStopped => 'Stopped';

  @override
  String containersSummary(int running, int total) {
    return '$running of $total running';
  }

  @override
  String updatesAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count updates available',
      one: '1 update available',
    );
    return '$_temp0';
  }

  @override
  String unreadSummary(int count) {
    return '$count unread';
  }

  @override
  String get parity => 'Parity';

  @override
  String parityRunning(int progress) {
    return 'Parity check running – $progress %';
  }

  @override
  String parityPaused(int progress) {
    return 'Parity check paused – $progress %';
  }

  @override
  String parityLast(String date) {
    return 'Last check: $date';
  }

  @override
  String get parityNever => 'Never checked';

  @override
  String parityErrors(int count) {
    return '$count errors';
  }

  @override
  String used(String used, String size) {
    return '$used of $size used';
  }

  @override
  String get dockerEmpty => 'No containers';

  @override
  String get start => 'Start';

  @override
  String get stop => 'Stop';

  @override
  String get restart => 'Restart';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get update => 'Update';

  @override
  String get updateAll => 'Update all';

  @override
  String get updateAllConfirm =>
      'Update all containers with available updates?';

  @override
  String get openWebUi => 'Open WebUI';

  @override
  String get logs => 'Logs';

  @override
  String get logsEmpty => 'No log output';

  @override
  String get ports => 'Ports';

  @override
  String get image => 'Image';

  @override
  String get autostart => 'Autostart';

  @override
  String get updateAvailable => 'Update available';

  @override
  String get filterAll => 'All';

  @override
  String get filterRunning => 'Running';

  @override
  String get filterStopped => 'Stopped';

  @override
  String stopConfirm(String name) {
    return 'Stop $name?';
  }

  @override
  String get vmsEmpty => 'No virtual machines (or VM service disabled)';

  @override
  String get forceStop => 'Force stop';

  @override
  String get reboot => 'Reboot';

  @override
  String forceStopConfirm(String name) {
    return 'Force stop $name? Unsaved data in the VM is lost.';
  }

  @override
  String get parityDisks => 'Parity';

  @override
  String get dataDisks => 'Array disks';

  @override
  String get cachePools => 'Pools';

  @override
  String get shares => 'Shares';

  @override
  String get spunDown => 'Spun down';

  @override
  String diskErrors(int count) {
    return '$count errors';
  }

  @override
  String get startArray => 'Start array';

  @override
  String get stopArray => 'Stop array';

  @override
  String get stopArrayConfirm =>
      'Stop the array? All Docker containers and VMs that use it will be stopped.';

  @override
  String get startArrayConfirm => 'Start the array?';

  @override
  String get parityCheck => 'Parity check';

  @override
  String get parityStart => 'Start check';

  @override
  String get parityStartCorrecting => 'Write corrections to parity';

  @override
  String get parityCancel => 'Cancel check';

  @override
  String free(String free) {
    return '$free free';
  }

  @override
  String get unread => 'Unread';

  @override
  String get archived => 'Archive';

  @override
  String get archive => 'Archive';

  @override
  String get archiveAll => 'Archive all';

  @override
  String get notificationsEmpty => 'No notifications';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get about => 'About';

  @override
  String get aboutBody =>
      'Open-source community app. Not affiliated with Lime Technology, Inc. Unraid is a trademark of Lime Technology, Inc.';

  @override
  String get sourceCode => 'Source code';

  @override
  String get webGui => 'Open WebGUI';

  @override
  String get errorUnsupported =>
      'This server\'s Unraid API is too old. Update Unraid (7.2+) or the Unraid Connect plugin – API 4.29 or newer is required.';

  @override
  String get tryDemo => 'Try the demo';

  @override
  String get tryDemoHelp =>
      'Explore the app with sample data – no server needed.';

  @override
  String get demoBanner => 'Demo mode – sample data';
}

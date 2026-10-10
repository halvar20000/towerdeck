import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'TowerDeck'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get navDashboard;

  /// No description provided for @navDocker.
  ///
  /// In en, this message translates to:
  /// **'Docker'**
  String get navDocker;

  /// No description provided for @navVms.
  ///
  /// In en, this message translates to:
  /// **'VMs'**
  String get navVms;

  /// No description provided for @navStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get navStorage;

  /// No description provided for @navNotifications.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navNotifications;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @servers.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get servers;

  /// No description provided for @readOnlyBanner.
  ///
  /// In en, this message translates to:
  /// **'Read-only API key – actions are disabled.'**
  String get readOnlyBanner;

  /// No description provided for @errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Could not load data'**
  String get errorLoading;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'The API key was rejected. Reconnect the server.'**
  String get errorUnauthorized;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'This API key is not allowed to do that.'**
  String get errorForbidden;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Server not reachable. Are you in the right network or VPN?'**
  String get errorNetwork;

  /// No description provided for @errorTls.
  ///
  /// In en, this message translates to:
  /// **'Secure connection failed. The certificate may have changed.'**
  String get errorTls;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {message}'**
  String actionFailed(String message);

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your Unraid server'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Requires Unraid 7.2 or newer (or the Unraid Connect plugin on older versions).'**
  String get welcomeBody;

  /// No description provided for @addServer.
  ///
  /// In en, this message translates to:
  /// **'Add server'**
  String get addServer;

  /// No description provided for @editServer.
  ///
  /// In en, this message translates to:
  /// **'Edit server'**
  String get editServer;

  /// No description provided for @serverAddress.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get serverAddress;

  /// No description provided for @serverAddressHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 192.168.1.10 or https://tower.local'**
  String get serverAddressHint;

  /// No description provided for @serverAddressInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid address'**
  String get serverAddressInvalid;

  /// No description provided for @serverName.
  ///
  /// In en, this message translates to:
  /// **'Display name (optional)'**
  String get serverName;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get apiKey;

  /// No description provided for @apiKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'Create one in the WebGUI under Settings → Management Access → API Keys, or with: unraid-api apikey --create'**
  String get apiKeyHelp;

  /// No description provided for @connectWithWebGui.
  ///
  /// In en, this message translates to:
  /// **'Sign in via WebGUI'**
  String get connectWithWebGui;

  /// No description provided for @connectWithWebGuiHelp.
  ///
  /// In en, this message translates to:
  /// **'Log in to your server and approve access – the key is created automatically.'**
  String get connectWithWebGuiHelp;

  /// No description provided for @orEnterKey.
  ///
  /// In en, this message translates to:
  /// **'or paste an existing API key'**
  String get orEnterKey;

  /// No description provided for @accessLevel.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get accessLevel;

  /// No description provided for @accessFull.
  ///
  /// In en, this message translates to:
  /// **'Full control'**
  String get accessFull;

  /// No description provided for @accessReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get accessReadOnly;

  /// No description provided for @allowSelfSigned.
  ///
  /// In en, this message translates to:
  /// **'Accept self-signed certificate'**
  String get allowSelfSigned;

  /// No description provided for @allowSelfSignedHelp.
  ///
  /// In en, this message translates to:
  /// **'The certificate is pinned on first connect.'**
  String get allowSelfSignedHelp;

  /// No description provided for @testAndSave.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get testAndSave;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @connectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected to {host}'**
  String connectedTo(String host);

  /// No description provided for @switchedToHttps.
  ///
  /// In en, this message translates to:
  /// **'Server uses HTTPS – address updated.'**
  String get switchedToHttps;

  /// No description provided for @removeServer.
  ///
  /// In en, this message translates to:
  /// **'Remove server'**
  String get removeServer;

  /// No description provided for @removeServerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this device?'**
  String removeServerConfirm(String name);

  /// No description provided for @authorizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve access'**
  String get authorizeTitle;

  /// No description provided for @uptime.
  ///
  /// In en, this message translates to:
  /// **'Uptime'**
  String get uptime;

  /// No description provided for @cpu.
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get cpu;

  /// No description provided for @memory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get memory;

  /// No description provided for @array.
  ///
  /// In en, this message translates to:
  /// **'Array'**
  String get array;

  /// No description provided for @arrayStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get arrayStarted;

  /// No description provided for @arrayStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get arrayStopped;

  /// No description provided for @containersSummary.
  ///
  /// In en, this message translates to:
  /// **'{running} of {total} running'**
  String containersSummary(int running, int total);

  /// No description provided for @updatesAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 update available} other{{count} updates available}}'**
  String updatesAvailable(int count);

  /// No description provided for @unreadSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String unreadSummary(int count);

  /// No description provided for @parity.
  ///
  /// In en, this message translates to:
  /// **'Parity'**
  String get parity;

  /// No description provided for @parityRunning.
  ///
  /// In en, this message translates to:
  /// **'Parity check running – {progress} %'**
  String parityRunning(int progress);

  /// No description provided for @parityPaused.
  ///
  /// In en, this message translates to:
  /// **'Parity check paused – {progress} %'**
  String parityPaused(int progress);

  /// No description provided for @parityLast.
  ///
  /// In en, this message translates to:
  /// **'Last check: {date}'**
  String parityLast(String date);

  /// No description provided for @parityNever.
  ///
  /// In en, this message translates to:
  /// **'Never checked'**
  String get parityNever;

  /// No description provided for @parityErrors.
  ///
  /// In en, this message translates to:
  /// **'{count} errors'**
  String parityErrors(int count);

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'{used} of {size} used'**
  String used(String used, String size);

  /// No description provided for @dockerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No containers'**
  String get dockerEmpty;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @updateAll.
  ///
  /// In en, this message translates to:
  /// **'Update all'**
  String get updateAll;

  /// No description provided for @updateAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Update all containers with available updates?'**
  String get updateAllConfirm;

  /// No description provided for @openWebUi.
  ///
  /// In en, this message translates to:
  /// **'Open WebUI'**
  String get openWebUi;

  /// No description provided for @logs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs;

  /// No description provided for @logsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No log output'**
  String get logsEmpty;

  /// No description provided for @ports.
  ///
  /// In en, this message translates to:
  /// **'Ports'**
  String get ports;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @autostart.
  ///
  /// In en, this message translates to:
  /// **'Autostart'**
  String get autostart;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get filterRunning;

  /// No description provided for @filterStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get filterStopped;

  /// No description provided for @stopConfirm.
  ///
  /// In en, this message translates to:
  /// **'Stop {name}?'**
  String stopConfirm(String name);

  /// No description provided for @vmsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No virtual machines (or VM service disabled)'**
  String get vmsEmpty;

  /// No description provided for @forceStop.
  ///
  /// In en, this message translates to:
  /// **'Force stop'**
  String get forceStop;

  /// No description provided for @reboot.
  ///
  /// In en, this message translates to:
  /// **'Reboot'**
  String get reboot;

  /// No description provided for @forceStopConfirm.
  ///
  /// In en, this message translates to:
  /// **'Force stop {name}? Unsaved data in the VM is lost.'**
  String forceStopConfirm(String name);

  /// No description provided for @parityDisks.
  ///
  /// In en, this message translates to:
  /// **'Parity'**
  String get parityDisks;

  /// No description provided for @dataDisks.
  ///
  /// In en, this message translates to:
  /// **'Array disks'**
  String get dataDisks;

  /// No description provided for @cachePools.
  ///
  /// In en, this message translates to:
  /// **'Pools'**
  String get cachePools;

  /// No description provided for @shares.
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get shares;

  /// No description provided for @spunDown.
  ///
  /// In en, this message translates to:
  /// **'Spun down'**
  String get spunDown;

  /// No description provided for @diskErrors.
  ///
  /// In en, this message translates to:
  /// **'{count} errors'**
  String diskErrors(int count);

  /// No description provided for @startArray.
  ///
  /// In en, this message translates to:
  /// **'Start array'**
  String get startArray;

  /// No description provided for @stopArray.
  ///
  /// In en, this message translates to:
  /// **'Stop array'**
  String get stopArray;

  /// No description provided for @stopArrayConfirm.
  ///
  /// In en, this message translates to:
  /// **'Stop the array? All Docker containers and VMs that use it will be stopped.'**
  String get stopArrayConfirm;

  /// No description provided for @startArrayConfirm.
  ///
  /// In en, this message translates to:
  /// **'Start the array?'**
  String get startArrayConfirm;

  /// No description provided for @parityCheck.
  ///
  /// In en, this message translates to:
  /// **'Parity check'**
  String get parityCheck;

  /// No description provided for @parityStart.
  ///
  /// In en, this message translates to:
  /// **'Start check'**
  String get parityStart;

  /// No description provided for @parityStartCorrecting.
  ///
  /// In en, this message translates to:
  /// **'Write corrections to parity'**
  String get parityStartCorrecting;

  /// No description provided for @parityCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel check'**
  String get parityCancel;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'{free} free'**
  String free(String free);

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archived;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @archiveAll.
  ///
  /// In en, this message translates to:
  /// **'Archive all'**
  String get archiveAll;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notificationsEmpty;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Open-source community app. Not affiliated with Lime Technology, Inc. Unraid is a trademark of Lime Technology, Inc.'**
  String get aboutBody;

  /// No description provided for @sourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get sourceCode;

  /// No description provided for @webGui.
  ///
  /// In en, this message translates to:
  /// **'Open WebGUI'**
  String get webGui;

  /// No description provided for @errorUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This server\'s Unraid API is too old. Update Unraid (7.2+) or the Unraid Connect plugin – API 4.29 or newer is required.'**
  String get errorUnsupported;

  /// No description provided for @tryDemo.
  ///
  /// In en, this message translates to:
  /// **'Try the demo'**
  String get tryDemo;

  /// No description provided for @tryDemoHelp.
  ///
  /// In en, this message translates to:
  /// **'Explore the app with sample data – no server needed.'**
  String get tryDemoHelp;

  /// No description provided for @demoBanner.
  ///
  /// In en, this message translates to:
  /// **'Demo mode – sample data'**
  String get demoBanner;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

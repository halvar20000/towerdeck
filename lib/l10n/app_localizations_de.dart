// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'TowerDeck';

  @override
  String get navDashboard => 'Übersicht';

  @override
  String get navDocker => 'Docker';

  @override
  String get navVms => 'VMs';

  @override
  String get navStorage => 'Speicher';

  @override
  String get navNotifications => 'Meldungen';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get search => 'Suchen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get servers => 'Server';

  @override
  String get readOnlyBanner =>
      'Schlüssel ohne Admin-Rolle – Aktionen sind deaktiviert.';

  @override
  String get errorLoading => 'Daten konnten nicht geladen werden';

  @override
  String get errorUnauthorized =>
      'Der API-Schlüssel wurde abgelehnt. Verbinde den Server neu.';

  @override
  String get errorForbidden =>
      'Dieser API-Schlüssel darf das nicht. Aktionen brauchen einen Schlüssel mit der Rolle Admin – bearbeite den Server und nutze „Über WebGUI anmelden“.';

  @override
  String get errorNetwork =>
      'Server nicht erreichbar. Bist du im richtigen Netz bzw. VPN?';

  @override
  String get errorTls =>
      'Sichere Verbindung fehlgeschlagen. Das Zertifikat hat sich evtl. geändert.';

  @override
  String get actionDone => 'Erledigt';

  @override
  String actionFailed(String message) {
    return 'Fehlgeschlagen: $message';
  }

  @override
  String get welcomeTitle => 'Verwalte deinen Unraid-Server';

  @override
  String get welcomeBody =>
      'Benötigt Unraid 7.2 oder neuer (bei älteren Versionen das Unraid-Connect-Plugin).';

  @override
  String get addServer => 'Server hinzufügen';

  @override
  String get editServer => 'Server bearbeiten';

  @override
  String get serverAddress => 'Server-Adresse';

  @override
  String get serverAddressHint => 'z. B. 192.168.1.10 oder https://tower.local';

  @override
  String get serverAddressInvalid => 'Gib eine gültige Adresse ein';

  @override
  String get serverName => 'Anzeigename (optional)';

  @override
  String get apiKey => 'API-Schlüssel';

  @override
  String get apiKeyHelp =>
      'Erstelle ihn in der WebGUI unter Einstellungen → Management Access → API Keys oder per: unraid-api apikey --create';

  @override
  String get connectWithWebGui => 'Über WebGUI anmelden';

  @override
  String get connectWithWebGuiHelp =>
      'Melde dich am Server an und erlaube den Zugriff – der Schlüssel wird automatisch erstellt.';

  @override
  String get orEnterKey => 'oder vorhandenen API-Schlüssel einfügen';

  @override
  String get accessLevel => 'Zugriff';

  @override
  String get accessFull => 'Volle Kontrolle';

  @override
  String get accessReadOnly => 'Nur lesen';

  @override
  String get allowSelfSigned => 'Selbstsigniertes Zertifikat akzeptieren';

  @override
  String get allowSelfSignedHelp =>
      'Das Zertifikat wird bei der ersten Verbindung fest hinterlegt.';

  @override
  String get testAndSave => 'Verbinden';

  @override
  String get connecting => 'Verbinde…';

  @override
  String connectedTo(String host) {
    return 'Verbunden mit $host';
  }

  @override
  String get switchedToHttps => 'Server nutzt HTTPS – Adresse wurde angepasst.';

  @override
  String get removeServer => 'Server entfernen';

  @override
  String removeServerConfirm(String name) {
    return '$name von diesem Gerät entfernen?';
  }

  @override
  String get authorizeTitle => 'Zugriff erlauben';

  @override
  String get uptime => 'Laufzeit';

  @override
  String get cpu => 'CPU';

  @override
  String get memory => 'RAM';

  @override
  String get array => 'Array';

  @override
  String get arrayStarted => 'Gestartet';

  @override
  String get arrayStopped => 'Gestoppt';

  @override
  String containersSummary(int running, int total) {
    return '$running von $total laufen';
  }

  @override
  String updatesAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Updates verfügbar',
      one: '1 Update verfügbar',
    );
    return '$_temp0';
  }

  @override
  String unreadSummary(int count) {
    return '$count ungelesen';
  }

  @override
  String get parity => 'Parität';

  @override
  String parityRunning(int progress) {
    return 'Paritätsprüfung läuft – $progress %';
  }

  @override
  String parityPaused(int progress) {
    return 'Paritätsprüfung pausiert – $progress %';
  }

  @override
  String parityLast(String date) {
    return 'Letzte Prüfung: $date';
  }

  @override
  String get parityNever => 'Noch nie geprüft';

  @override
  String parityErrors(int count) {
    return '$count Fehler';
  }

  @override
  String used(String used, String size) {
    return '$used von $size belegt';
  }

  @override
  String get dockerEmpty => 'Keine Container';

  @override
  String get start => 'Starten';

  @override
  String get stop => 'Stoppen';

  @override
  String get restart => 'Neu starten';

  @override
  String get pause => 'Pausieren';

  @override
  String get resume => 'Fortsetzen';

  @override
  String get update => 'Aktualisieren';

  @override
  String get updateAll => 'Alle aktualisieren';

  @override
  String get updateAllConfirm =>
      'Alle Container mit verfügbaren Updates aktualisieren?';

  @override
  String get openWebUi => 'WebUI öffnen';

  @override
  String get logs => 'Logs';

  @override
  String get logsEmpty => 'Keine Log-Ausgabe';

  @override
  String get ports => 'Ports';

  @override
  String get image => 'Image';

  @override
  String get autostart => 'Autostart';

  @override
  String get updateAvailable => 'Update verfügbar';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterRunning => 'Laufend';

  @override
  String get filterStopped => 'Gestoppt';

  @override
  String stopConfirm(String name) {
    return '$name stoppen?';
  }

  @override
  String get vmsEmpty =>
      'Keine virtuellen Maschinen (oder VM-Dienst deaktiviert)';

  @override
  String get forceStop => 'Hart ausschalten';

  @override
  String get reboot => 'Neustarten';

  @override
  String forceStopConfirm(String name) {
    return '$name hart ausschalten? Ungespeicherte Daten in der VM gehen verloren.';
  }

  @override
  String get parityDisks => 'Parität';

  @override
  String get dataDisks => 'Array-Disks';

  @override
  String get cachePools => 'Pools';

  @override
  String get shares => 'Shares';

  @override
  String get spunDown => 'Im Standby';

  @override
  String diskErrors(int count) {
    return '$count Fehler';
  }

  @override
  String get startArray => 'Array starten';

  @override
  String get stopArray => 'Array stoppen';

  @override
  String get stopArrayConfirm =>
      'Array stoppen? Alle Docker-Container und VMs, die es nutzen, werden gestoppt.';

  @override
  String get startArrayConfirm => 'Array starten?';

  @override
  String get parityCheck => 'Paritätsprüfung';

  @override
  String get parityStart => 'Prüfung starten';

  @override
  String get parityStartCorrecting => 'Korrekturen in Parität schreiben';

  @override
  String get parityCancel => 'Prüfung abbrechen';

  @override
  String free(String free) {
    return '$free frei';
  }

  @override
  String get unread => 'Ungelesen';

  @override
  String get archived => 'Archiv';

  @override
  String get archive => 'Archivieren';

  @override
  String get archiveAll => 'Alle archivieren';

  @override
  String get notificationsEmpty => 'Keine Meldungen';

  @override
  String get appearance => 'Darstellung';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'Systemsprache';

  @override
  String get about => 'Über';

  @override
  String get aboutBody =>
      'Open-Source-Community-App. Nicht verbunden mit Lime Technology, Inc. Unraid ist eine Marke von Lime Technology, Inc.';

  @override
  String get sourceCode => 'Quellcode';

  @override
  String get webGui => 'WebGUI öffnen';

  @override
  String get errorUnsupported =>
      'Die Unraid-API dieses Servers ist zu alt. Aktualisiere Unraid (7.2+) bzw. das Unraid-Connect-Plugin – benötigt wird API 4.29 oder neuer.';

  @override
  String get tryDemo => 'Demo ausprobieren';

  @override
  String get tryDemoHelp =>
      'Die App mit Beispieldaten erkunden – ganz ohne Server.';

  @override
  String get demoBanner => 'Demo-Modus – Beispieldaten';

  @override
  String get actionRunning => 'Läuft … das kann ein paar Minuten dauern.';

  @override
  String get checkForUpdates => 'Nach Updates suchen';
}

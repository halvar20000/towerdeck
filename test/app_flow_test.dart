import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:towerdeck/app.dart';
import 'package:towerdeck/data/providers.dart';

/// End-to-end flow through the real widget tree, backed by the demo API.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'locale': 'en'});
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<void> settle(WidgetTester tester) async {
    // Demo responses are delayed by up to 400 ms; polling timers never settle.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('onboarding → demo → dashboard → docker → stop container', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    await tester.pumpWidget(const ProviderScope(child: TowerDeckApp()));
    await settle(tester);

    // Onboarding is shown when no server is configured.
    expect(find.text('Manage your Unraid server'), findsOneWidget);
    await tester.ensureVisible(find.text('Try the demo'));
    await tester.tap(find.text('Try the demo'));
    await settle(tester);

    // Dashboard.
    expect(find.text('Demo-Tower'), findsWidgets);
    expect(find.text('Started'), findsOneWidget);
    expect(find.text('7 of 9 running'), findsOneWidget);
    expect(find.text('3 updates available'), findsOneWidget);

    // Docker tab.
    await tester.tap(find.text('Docker').last);
    await settle(tester);
    expect(find.text('plex'), findsOneWidget);
    expect(find.text('syncthing'), findsOneWidget);

    // Stop plex via the list action, confirm the dialog.
    final plexTile = find.ancestor(of: find.text('plex'), matching: find.byType(ListTile));
    await tester.tap(find.descendant(of: plexTile, matching: find.byIcon(Icons.stop_circle_outlined)));
    await settle(tester);
    expect(find.text('Stop plex?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Stop'));
    await settle(tester);
    expect(find.descendant(of: plexTile, matching: find.byIcon(Icons.play_circle_outline)), findsOneWidget);

    // Filter: running only hides plex now.
    await tester.tap(find.text('Running'));
    await settle(tester);
    expect(find.text('plex'), findsNothing);

    // Storage tab lists disks.
    await tester.tap(find.text('Storage'));
    await settle(tester);
    expect(find.text('disk1'), findsOneWidget);

    // Tear down so polling timers are cancelled.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('German locale', (tester) async {
    SharedPreferences.setMockInitialValues({'locale': 'de'});
    await tester.pumpWidget(const ProviderScope(child: TowerDeckApp()));
    await settle(tester);
    expect(find.text('Verwalte deinen Unraid-Server'), findsOneWidget);
    expect(find.text('Demo ausprobieren'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  test('demo server id is stable', () => expect(demoServer().id, 'demo'));
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/providers.dart';
import '../../widgets/common.dart';

const sourceCodeUrl = 'https://github.com/halvar20000/towerdeck';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final settings = ref.watch(settingsProvider);
    final servers = ref.watch(serversProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        children: [
          SectionHeader(l.servers),
          for (final s in servers?.servers ?? const [])
            ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: Text(s.name),
              subtitle: Text(s.baseUrl.toString()),
              trailing: s.id == servers?.activeId ? const Icon(Icons.check) : null,
              onTap: () => context.push('/servers/${s.id}'),
            ),
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(l.addServer),
            onTap: () => context.push('/servers/add'),
          ),
          SectionHeader(l.appearance),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(value: ThemeMode.system, label: Text(l.themeSystem)),
                ButtonSegment(value: ThemeMode.light, label: Text(l.themeLight)),
                ButtonSegment(value: ThemeMode.dark, label: Text(l.themeDark)),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => ref.read(settingsProvider.notifier).setThemeMode(s.first),
            ),
          ),
          ListTile(
            title: Text(l.language),
            trailing: DropdownButton<String>(
              value: settings.locale?.languageCode ?? '',
              underline: const SizedBox(),
              items: [
                DropdownMenuItem(value: '', child: Text(l.languageSystem)),
                const DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                const DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .setLocale(v == null || v.isEmpty ? null : Locale(v)),
            ),
          ),
          SectionHeader(l.about),
          ListTile(title: Text(l.appTitle), subtitle: Text(l.aboutBody)),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(l.sourceCode),
            subtitle: const Text(sourceCodeUrl),
            onTap: () => launchUrl(Uri.parse(sourceCodeUrl), mode: LaunchMode.externalApplication),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Licenses'),
            onTap: () => showLicensePage(context: context, applicationName: l.appTitle),
          ),
        ],
      ),
    );
  }
}

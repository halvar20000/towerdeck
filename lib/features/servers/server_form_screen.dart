import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/demo_api.dart';
import '../../core/api/unraid_api.dart';
import '../../core/api/unraid_client.dart';
import '../../data/providers.dart';
import '../../data/server_store.dart';
import '../../widgets/common.dart';
import 'authorize_screen.dart';

/// Add a new server (onboarding) or edit an existing one.
class ServerFormScreen extends ConsumerStatefulWidget {
  const ServerFormScreen({super.key, this.serverId});

  final String? serverId;

  @override
  ConsumerState<ServerFormScreen> createState() => _ServerFormScreenState();
}

class _ServerFormScreenState extends ConsumerState<ServerFormScreen> {
  final _address = TextEditingController();
  final _name = TextEditingController();
  final _key = TextEditingController();
  bool _allowSelfSigned = false;
  bool _readOnly = false;
  bool _busy = false;
  bool _showKeyField = false;
  String? _error;
  ServerConfig? _existing;

  @override
  void initState() {
    super.initState();
    final servers = ref.read(serversProvider).value?.servers ?? const [];
    _existing = servers.where((s) => s.id == widget.serverId).firstOrNull;
    if (_existing != null) {
      _address.text = _existing!.baseUrl.toString();
      _name.text = _existing!.name;
      _allowSelfSigned = _existing!.allowSelfSigned;
      _showKeyField = true;
    }
  }

  @override
  void dispose() {
    _address.dispose();
    _name.dispose();
    _key.dispose();
    super.dispose();
  }

  Uri? get _baseUrl => parseServerAddress(_address.text);

  Future<void> _authorizeViaWebGui() async {
    final base = _baseUrl;
    if (base == null) return setState(() => _error = context.l10n.serverAddressInvalid);
    final key = await AuthorizeScreen.open(context, base, readOnly: _readOnly);
    if (key == null || !mounted) return;
    _key.text = key;
    await _connect();
  }

  Future<void> _connect() async {
    final l = context.l10n;
    var base = _baseUrl;
    if (base == null) return setState(() => _error = l.serverAddressInvalid);
    final apiKey = _key.text.trim().isNotEmpty ? _key.text.trim() : _existing?.apiKey;
    if (apiKey == null) return setState(() => _error = l.apiKey);

    setState(() {
      _busy = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);

    // Keep the pinned certificate only if the address did not change.
    String? pinned = _existing?.baseUrl == base ? _existing?.certFingerprint : null;
    try {
      ({String hostname, List<String> roles, String? version}) probe;
      UnraidClient client;
      try {
        client = _client(base, apiKey, pinned);
        probe = await UnraidApi(client).probe();
      } on UnraidApiException catch (e) {
        // A WebGUI with "Use SSL" redirects http → https; follow it once.
        final target = e.redirectTo;
        if (e.kind != ApiErrorKind.redirect || target == null || target.scheme != 'https') rethrow;
        base = Uri(scheme: 'https', host: target.host, port: target.hasPort ? target.port : null);
        _address.text = base.toString();
        messenger.showSnackBar(SnackBar(content: Text(l.switchedToHttps)));
        pinned = null;
        client = _client(base, apiKey, pinned);
        probe = await UnraidApi(client).probe();
      }
      final fingerprint = client.observedFingerprint ?? pinned;
      client.close();

      final server = ServerConfig(
        id: _existing?.id ?? _newId(),
        name: _name.text.trim().isEmpty ? probe.hostname : _name.text.trim(),
        baseUrl: base,
        apiKey: apiKey,
        allowSelfSigned: _allowSelfSigned,
        certFingerprint: _allowSelfSigned ? fingerprint : null,
      );
      await ref.read(serversProvider.notifier).upsert(server);
      ref.invalidate(rolesProvider);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l.connectedTo(probe.hostname))));
      context.go('/dashboard');
    } catch (e) {
      if (mounted) setState(() => _error = describeError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  UnraidClient _client(Uri base, String key, String? pinned) => UnraidClient(
        baseUrl: base,
        apiKey: key,
        allowSelfSigned: _allowSelfSigned,
        pinnedFingerprint: pinned,
      );

  static String _newId() {
    final r = Random.secure();
    return List.generate(8, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> _remove() async {
    final s = _existing!;
    final l = context.l10n;
    if (!await confirm(context, l.removeServerConfirm(s.name), action: l.delete, destructive: true)) {
      return;
    }
    await ref.read(serversProvider.notifier).remove(s.id);
    if (!mounted) return;
    final remaining = ref.read(serversProvider).value?.servers ?? const [];
    context.go(remaining.isEmpty ? '/servers/add' : '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final editing = _existing != null;
    final canPop = context.canPop();

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? l.editServer : l.addServer),
        automaticallyImplyLeading: canPop,
        actions: [
          if (editing)
            IconButton(tooltip: l.removeServer, onPressed: _remove, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!editing) ...[
              Icon(Icons.dns_rounded, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(l.welcomeTitle, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(l.welcomeBody, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
              const SizedBox(height: 24),
            ],
            TextField(
              controller: _address,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l.serverAddress,
                hintText: l.serverAddressHint,
                prefixIcon: const Icon(Icons.lan_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: l.serverName,
                prefixIcon: const Icon(Icons.label_outline),
                border: const OutlineInputBorder(),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.allowSelfSigned),
              subtitle: Text(l.allowSelfSignedHelp),
              value: _allowSelfSigned,
              onChanged: (v) => setState(() => _allowSelfSigned = v),
            ),
            const SizedBox(height: 8),
            if (!_showKeyField) ...[
              Text(l.accessLevel, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(l.accessFull), icon: const Icon(Icons.admin_panel_settings_outlined)),
                  ButtonSegment(value: true, label: Text(l.accessReadOnly), icon: const Icon(Icons.visibility_outlined)),
                ],
                selected: {_readOnly},
                onSelectionChanged: (s) => setState(() => _readOnly = s.first),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _busy ? null : _authorizeViaWebGui,
                icon: const Icon(Icons.login),
                label: Text(l.connectWithWebGui),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
              const SizedBox(height: 6),
              Text(l.connectWithWebGuiHelp, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _showKeyField = true),
                child: Text(l.orEnterKey),
              ),
            ] else ...[
              TextField(
                controller: _key,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: l.apiKey,
                  hintText: editing ? '••••••••' : null,
                  prefixIcon: const Icon(Icons.key_outlined),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 6),
              Text(l.apiKeyHelp, style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _connect,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: Text(editing ? l.save : l.testAndSave),
              ),
              if (!editing)
                TextButton(
                  onPressed: () => setState(() => _showKeyField = false),
                  child: Text(l.connectWithWebGui),
                ),
            ],
            if (!editing && !(ref.watch(serversProvider).value?.servers.any((s) => s.id == demoServerId) ?? false)) ...[
              const Divider(height: 40),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        await ref.read(serversProvider.notifier).upsert(demoServer());
                        if (context.mounted) context.go('/dashboard');
                      },
                icon: const Icon(Icons.play_circle_outline),
                label: Text(l.tryDemo),
              ),
              const SizedBox(height: 6),
              Text(l.tryDemoHelp, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            ],
            if (_busy) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              Text(l.connecting, textAlign: TextAlign.center),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

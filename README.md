# TowerDeck

Open-source app for Android and iOS to manage [Unraid](https://unraid.net) servers from your phone, built with Flutter on the official Unraid GraphQL API.

> TowerDeck is a community project. It is not affiliated with or endorsed by Lime Technology, Inc. Unraid is a trademark of Lime Technology, Inc.

## Features

| Area | What you can do |
|---|---|
| **Overview** | Hostname, Unraid version, uptime, live CPU/RAM, array usage, parity status, unread alerts, Docker/VM counts. Refreshes every 5 s. |
| **Docker** | Search and filter containers; start, stop, restart, pause; update a single container or all of them; open the WebUI; view logs. |
| **VMs** | Start, stop, pause/resume, reboot, force stop. |
| **Storage** | Array start/stop; parity check start (optionally correcting), pause, resume, cancel; per disk: temperature, spin state, errors, fill level; pools and shares. |
| **Alerts** | Unread and archived notifications; swipe to archive or delete; archive all. |
| **Multi-server** | Several servers. API keys are stored in the iOS Keychain or Android Keystore. |
| **Security** | Read-only keys are detected and action buttons are hidden for them. Self-signed certificates are opt-in and pinned on first use. |
| **Languages** | English and German; light and dark mode. |

## Requirements

- Unraid **7.2 or newer**, or an older Unraid with the Unraid Connect plugin, with **Unraid API ≥ 4.29**
  (container restart needs API ≥ 4.36; on older versions the app does stop + start instead)
- The phone must reach the server: same LAN, Tailscale, WireGuard, or another VPN

## Connecting a server

**Recommended: sign in via WebGUI.** Enter the server address and tap *Sign in via WebGUI*. Log in to Unraid and approve the access request. The app gets its own API key automatically (Unraid's built-in *API Key Authorization* flow). You can revoke it any time under *Settings → Management Access → API Keys*.

**Alternative: paste an API key.** Create a key on the server:

```sh
unraid-api apikey --create --name "TowerDeck" --roles ADMIN      # full control
unraid-api apikey --create --name "TowerDeck RO" --roles VIEWER  # read only
```

## Development

```sh
flutter pub get
flutter run                        # device or simulator
flutter analyze && flutter test
./tool/validate_graphql.sh         # check all GraphQL documents against docs/unraid-schema.graphql

# read-only smoke test against a real server
UNRAID_URL=http://192.168.1.10 UNRAID_API_KEY=... dart run tool/smoke.dart
```

`docs/unraid-schema.graphql` is the schema of Unraid API v4.37.4 (from [unraid/api](https://github.com/unraid/api)). Update it when you adopt newer API features.

### Project layout

```
lib/
  core/api/        GraphQL client (auth, TLS pinning, error mapping) and typed API
  core/models/     Data models parsed from API responses
  data/            Server storage (prefs + secure storage) and Riverpod providers
  features/        One folder per screen: dashboard, docker, vms, storage, notifications, servers, settings
  l10n/            ARB translation files (en, de)
  widgets/         Shared UI pieces
tool/              Smoke test and GraphQL validation scripts
```

## Roadmap

See [docs/ROADMAP.md](docs/ROADMAP.md).

## Contributing

Issues and pull requests are welcome. Run `flutter analyze`, `flutter test` and `./tool/validate_graphql.sh` before opening a PR.

## License

[MIT](LICENSE)

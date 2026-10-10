# Roadmap

## v0.1: MVP (this release)
- [x] Server onboarding through the WebGUI authorization flow, or a pasted API key
- [x] Several servers; keys kept in Keychain/Keystore; certificate pinning for self-signed TLS
- [x] Dashboard, Docker (actions, updates, logs), VMs, storage/array/parity, notifications
- [x] German and English UI; dark mode
- [x] Detection of read-only keys

## v0.2: Live and convenient
- [ ] Live CPU/RAM/network metrics over GraphQL subscriptions (`systemMetricsCpu`, `systemMetricsMemory`, …) instead of polling
- [ ] Live container logs (`logFile` subscription / log cursor)
- [ ] Container stats (`dockerContainerStats`)
- [ ] System log viewer (`logFiles`, `logFile`)
- [ ] Docker folders, matching the WebGUI organizer
- [ ] Biometric app lock (Face ID / fingerprint)

## v0.3: Push and widgets
- [ ] Push notifications for Unraid alerts. Options: a small companion Unraid plugin/agent that forwards `notificationAdded` to ntfy/APNs/FCM, or background polling
- [ ] Home-screen widgets (iOS WidgetKit and Android Glance) for array status and alerts
- [ ] Quick actions: long-press the app icon to restart a favourite container

## Later
- [ ] UPS status, temperatures/fans
- [ ] Mover and User Scripts (needs API support or a WebGUI fallback)
- [ ] Embedded WebGUI fallback for anything the API does not cover
- [ ] Tablet layout
- [ ] More languages (community translations)

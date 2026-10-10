# Releasing TowerDeck

## Before the first release

1. **Choose the final name.** "TowerDeck" is a working title. Check that it is free in both stores and as a GitHub repo. Do not put "Unraid" in the app name: it is a Lime Technology trademark. A subtitle such as "for Unraid servers" is the usual way to mention it.
2. **App ID:** `io.github.halvar20000.towerdeck`, set in `android/app/build.gradle.kts` and as the iOS bundle ID in Xcode. It can't be changed after the first store upload.
3. **App icon:** add `flutter_launcher_icons` and a 1024×1024 PNG.
4. **GitHub repo:** create it, push the code, and update `sourceCodeUrl` in `lib/features/settings/settings_screen.dart`.
5. **Privacy policy URL** (both stores require one). The app collects no data, contains no tracking, and talks only to the user's own server. A short page on GitHub Pages is enough.

## Android (Google Play)

```sh
# one time: create the upload keystore (keep it and the passwords safe!)
keytool -genkey -v -keystore ~/towerdeck-upload.jks -keyalg RSA -keysize 2048 \
        -validity 10000 -alias upload

cat > android/key.properties <<EOF
storeFile=/Users/<you>/towerdeck-upload.jks
storePassword=...
keyAlias=upload
keyPassword=...
EOF

flutter build appbundle --release      # → build/app/outputs/bundle/release/app-release.aab
```

- Play Console: a one-time fee of 25 USD. Create the app and upload the `.aab` to *Internal testing* first.
- New personal developer accounts must run a closed test with at least 12 testers for 14 days before production.
- Data safety form: "No data collected or shared".
- **App access** (review instructions): "Tap *Try the demo* on the first screen. The app manages self-hosted Unraid servers on the user's own network."

Optional: publish on F-Droid / IzzyOnDroid as well. The app has no proprietary dependencies.

## iOS (App Store), on the Mac

```sh
flutter build ipa --release            # → build/ios/ipa/*.ipa
```

1. Apple Developer Program: 99 USD per year.
2. Open `ios/Runner.xcworkspace` in Xcode. Under *Signing & Capabilities*, choose your team and set the bundle ID.
3. In App Store Connect, create the app, then upload with Xcode → *Product → Archive → Distribute*, or with the *Transporter* app.
4. Test with TestFlight first.
5. **Review notes:**
   > TowerDeck manages self-hosted Unraid servers on the user's local network or VPN.
   > Reviewers can explore every feature without a server: tap "Try the demo" on the first screen.
   > NSAllowsArbitraryLoads is required because Unraid servers are typically reached over plain HTTP or self-signed HTTPS on private networks.
6. App Privacy: "Data Not Collected".

## Every release

1. Bump `version:` in `pubspec.yaml` (e.g. `0.2.0+3`; the build number must increase).
2. `flutter analyze && flutter test && ./tool/validate_graphql.sh`
3. Smoke test against a real server: `dart run tool/smoke.dart` (see README).
4. Build and upload as described above. Tag the release: `git tag v0.2.0 && git push --tags`

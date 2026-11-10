# iOS Firebase Setup

## Apps to register in Firebase Console

Go to **Firebase Console → Project settings → General → Your apps** and add these two iOS apps:

| Config | Bundle ID | Name |
|--------|-----------|------|
| Development (debug/profile) | `com.GrullonDev.memory_arcade.dev` | Memory Arcade Dev (iOS) |
| Production (release) | `com.GrullonDev.memory_arcade` | Memory Arcade (iOS) |

## Download and place the plist files

1. Download `GoogleService-Info.plist` for each app from Firebase Console.
2. Rename and place them:

```
ios/Runner/Firebase/GoogleService-Info-Dev.plist    ← from the .dev app
ios/Runner/Firebase/GoogleService-Info-Prod.plist   ← from the production app
```

These files are gitignored and must be placed manually on each machine.

## Add Xcode build phase

In Xcode, open **Runner → Build Phases** and add a **New Run Script Phase** called "Copy Firebase Config". Place it **before** "Copy Bundle Resources":

```bash
${PROJECT_DIR}/scripts/copy_firebase_config.sh
```

The script copies the right plist into the app bundle based on the build configuration (Release → Prod, everything else → Dev).

## Google Sign-In

For Google Sign-In on iOS, you also need to:

1. Add the `REVERSED_CLIENT_ID` from each `GoogleService-Info.plist` as a URL scheme in Xcode → Runner → Info → URL Types.
2. This is different for dev and prod, so you may need a build-phase approach or use the dev one for local testing.

## Verify

After setup, `flutter run` on an iOS simulator should initialize Firebase without errors. Check the debug console for `Firebase initialized` or similar logs.

## How it works

`firebase_initialization.dart` uses native SDK config on both Android and iOS (no `FirebaseOptions` needed). The iOS SDK reads `GoogleService-Info.plist` from the app bundle, which the build script places per configuration.

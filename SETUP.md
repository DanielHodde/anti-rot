# Anti-Rot — Mac Setup Guide

This guide covers everything you need to do on your Mac to go from this repo to a running app on your iPhone.

---

## Step 1 — Install XcodeGen

XcodeGen generates the `.xcodeproj` from `project.yml`. You only need to do this once, and again any time you add new source files.

```bash
brew install xcodegen
```

---

## Step 2 — Set Your Team ID

Open `project.yml` and fill in your Team ID (found at developer.apple.com/account under Membership):

```yaml
settings:
  base:
    DEVELOPMENT_TEAM: "XXXXXXXXXX"  # ← paste yours here
```

---

## Step 3 — Generate the Xcode Project

From the repo root:

```bash
xcodegen generate
```

This creates `AntiRot.xcodeproj`. Open it:

```bash
open AntiRot.xcodeproj
```

---

## Step 4 — Add Family Controls Capability in Xcode

XcodeGen handles App Groups automatically. Family Controls is a restricted entitlement and must be added manually once your entitlement request is approved.

For each of the 4 targets (AntiRot, DeviceActivityMonitorExtension, ShieldConfigurationExtension, ShieldActionHandlerExtension):

1. Select the target in Xcode's Project Navigator
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Search for and add **Family Controls**

> Note: This will fail to build until Apple approves your entitlement request (see Step 6).

---

## Step 5 — Connect Your iPhone and Run

1. Connect your iPhone via USB
2. Select your iPhone as the run destination in Xcode
3. Press **Cmd+R** to build and run

The app will install directly on your device. You don't need the App Store for personal use.

---

## Step 6 — Request the Family Controls Entitlement

This is the only step with a wait time. Do it today.

1. Go to [developer.apple.com](https://developer.apple.com)
2. Sign in → Certificates, Identifiers & Profiles → Identifiers
3. Find or create your App ID: `com.daniel.antirot`
4. Under **Additional Capabilities**, click **Configure** next to Family Controls
5. Select your use case and submit

Apple typically approves in 3–7 business days, occasionally up to 33 days.

While you wait, the app will build but the Screen Time features won't work until the entitlement is active.

---

## After Adding New Source Files

Any time you add a new `.swift` file, re-run:

```bash
xcodegen generate
```

This updates the `.xcodeproj` to include the new file. **Do not edit the `.xcodeproj` directly** — your changes will be overwritten next time you run XcodeGen.

---

## Project Structure Reference

```
AntiRot/                              ← Main app
  AntiRotApp.swift                    ← Entry point, handles FamilyControls auth
  ContentView.swift                   ← Tab bar (Home | Apps | Schedule)
  Views/
    AuthorizationView.swift           ← First-launch permission screen
    HomeView.swift                    ← Status + "I'm Eating" override button
    AppSelectionView.swift            ← FamilyActivityPicker wrapper
    ScheduleView.swift                ← Add/remove allowed time windows
  Models/
    TimeWindow.swift                  ← Allowed window data model
    OverrideState.swift               ← Tracks daily override usage
  Services/
    SharedStorage.swift               ← UserDefaults via App Groups
    ScreenTimeService.swift           ← Orchestrates scheduling and shields

DeviceActivityMonitorExtension/       ← Background; applies/removes shields
ShieldConfigurationExtension/         ← Customizes the blocked-app screen
ShieldActionHandlerExtension/         ← Handles taps on the shield
```

# Anti-Rot — Implementation Plan

A personal iOS screen time limiting app built with Swift/SwiftUI using Apple's Screen Time API.

---

## App Overview

Anti-Rot is a personal screen time limiting app for iPhone. It has no backend — everything runs entirely on-device.

**Core features:**
- Pick specific apps to restrict using Apple's native app picker
- Schedule daily time windows when those apps are **allowed** (apps are blocked outside those windows)
- One daily override: a button that grants 45 minutes of access, intended for use while eating
- No other bypass mechanism — the shield cannot be dismissed without using the daily override

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift |
| UI | SwiftUI |
| Min iOS | iOS 16.0 |
| Authorization | FamilyControls framework |
| Shield enforcement | ManagedSettings framework |
| Schedule monitoring | DeviceActivity framework |
| Shared storage | App Groups (UserDefaults suite) |
| Backend | None — fully on-device |

---

## Pre-Requisite Checklist

Complete these before writing any code. Some steps have multi-day lead times.

- [ ] Enroll in Apple Developer Program ($99/year) at developer.apple.com
- [ ] Create App ID `com.daniel.antirot` in the developer portal
- [ ] **Request the Family Controls entitlement** via the developer portal — takes 3–33 days, do this on day one
- [ ] Install latest stable Xcode
- [ ] Have a **physical iPhone** available — the simulator does not support the Screen Time API

---

## Xcode Project — 4 Targets

| # | Target Name | Type | Role |
|---|---|---|---|
| 1 | `AntiRot` | iOS App | Main UI: configuration, app selection, schedule editing, override button |
| 2 | `DeviceActivityMonitorExtension` | Device Activity Monitor Extension | Applies/removes shields when schedules fire |
| 3 | `ShieldConfigurationExtension` | Shield Configuration Extension | Customizes the blocked-app screen appearance |
| 4 | `ShieldActionHandlerExtension` | Shield Action Handler Extension | Handles button taps on the blocked-app screen |

**All 4 targets** need these two capabilities:
- **Family Controls** — entitlement key: `com.apple.developer.family-controls`
- **App Groups** — identifier: `group.com.daniel.antirot`

Main app only:
- **URL Scheme**: `antirot` (for the shield "Open Anti-Rot" button)

---

## Shared Data Model

All data lives in `UserDefaults(suiteName: "group.com.daniel.antirot")` — accessible from all 4 targets.

```swift
struct TimeWindow: Codable {
    var id: UUID
    var label: String       // e.g. "Lunch", "Dinner"
    var startHour: Int      // 0–23
    var startMinute: Int    // 0–59
    var endHour: Int
    var endMinute: Int
}

struct OverrideState: Codable {
    var lastUsedDate: Date?       // nil if never used
    var overrideExpiresAt: Date?  // nil if no active override
}
```

### Storage Keys

| Key | Type | Description |
|---|---|---|
| `"selectedApps"` | `Data` (encoded `FamilyActivitySelection`) | The apps chosen to block |
| `"allowedWindows"` | `Data` (encoded `[TimeWindow]`) | Daily windows when apps are accessible |
| `"overrideState"` | `Data` (encoded `OverrideState`) | Override usage tracking |

### SharedStorage Helper

This file is copied (not shared via Swift package) into both the main app target and the DeviceActivityMonitorExtension target — extensions cannot import modules from the main app.

```swift
struct SharedStorage {
    static let defaults = UserDefaults(suiteName: "group.com.daniel.antirot")!

    static func saveSelection(_ selection: FamilyActivitySelection) {
        defaults.set(try? PropertyListEncoder().encode(selection), forKey: "selectedApps")
    }
    static func loadSelection() -> FamilyActivitySelection? {
        guard let data = defaults.data(forKey: "selectedApps") else { return nil }
        return try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
    }
    static func saveWindows(_ windows: [TimeWindow]) {
        defaults.set(try? JSONEncoder().encode(windows), forKey: "allowedWindows")
    }
    static func loadWindows() -> [TimeWindow] {
        guard let data = defaults.data(forKey: "allowedWindows") else { return [] }
        return (try? JSONDecoder().decode([TimeWindow].self, from: data)) ?? []
    }
    static func saveOverrideState(_ state: OverrideState) {
        defaults.set(try? JSONEncoder().encode(state), forKey: "overrideState")
    }
    static func loadOverrideState() -> OverrideState {
        guard let data = defaults.data(forKey: "overrideState") else { return OverrideState() }
        return (try? JSONDecoder().decode(OverrideState.self, from: data)) ?? OverrideState()
    }
}
```

---

## Scheduling Logic

The user defines **allowed windows** (times when apps ARE accessible). Everything outside those windows is blocked.

**Algorithm — convert allowed windows to blocked periods:**

1. Sort allowed windows by start time
2. Validate no overlaps
3. Compute the gaps: midnight→first window, between consecutive windows, last window→midnight
4. Each gap becomes a `DeviceActivitySchedule` with `repeats: true`

**Example:** Allowed windows are Lunch (12:00–13:00) and Dinner (18:00–19:00)

Blocked periods:
- `blocked-period-0`: 00:00 → 12:00
- `blocked-period-1`: 13:00 → 18:00
- `blocked-period-2`: 19:00 → 23:59

`intervalDidStart` on any `blocked-period-*` → apply shields
`intervalDidEnd` on any `blocked-period-*` → remove shields

DeviceActivity schedules survive device reboots — Apple's daemon re-fires them automatically.

---

## Override Logic (45 min, Once Per Day)

1. User taps **"I'm Eating"** in the main app
2. Read `OverrideState` — if `lastUsedDate` is today, show "Already used today" and stop
3. If eligible:
   - Clear `ManagedSettingsStore().shield.applications = nil` immediately
   - Write `OverrideState(lastUsedDate: .now, overrideExpiresAt: .now + 2700)` to SharedStorage
   - Start a one-shot DeviceActivity named `"override"` with `intervalEnd = now + 45min`, `repeats: false`
4. `DeviceActivityMonitorExtension.intervalDidEnd` for `"override"`:
   - Re-read selected apps from SharedStorage
   - Re-apply shields
   - Clear `overrideExpiresAt` (keep `lastUsedDate`) in SharedStorage
5. Main app shows a countdown timer while override is active

---

## File Structure

```
AntiRot.xcodeproj
├── AntiRot/
│   ├── AntiRotApp.swift
│   ├── ContentView.swift               ← TabView: Home | Apps | Schedule
│   ├── Views/
│   │   ├── HomeView.swift              ← Status + override button
│   │   ├── AppSelectionView.swift      ← FamilyActivityPicker wrapper
│   │   └── ScheduleView.swift          ← Add/remove time windows
│   ├── Models/
│   │   ├── TimeWindow.swift
│   │   └── OverrideState.swift
│   ├── Services/
│   │   ├── ScreenTimeService.swift     ← Orchestrates scheduling + shields
│   │   └── SharedStorage.swift
│   └── AntiRot.entitlements
├── DeviceActivityMonitorExtension/
│   ├── DeviceActivityMonitorExtension.swift
│   ├── SharedStorage.swift             ← Copy of shared file
│   ├── TimeWindow.swift                ← Copy of shared file
│   ├── OverrideState.swift             ← Copy of shared file
│   └── DeviceActivityMonitorExtension.entitlements
├── ShieldConfigurationExtension/
│   ├── ShieldConfigurationExtension.swift
│   └── ShieldConfigurationExtension.entitlements
└── ShieldActionHandlerExtension/
    ├── ShieldActionHandlerExtension.swift
    └── ShieldActionHandlerExtension.entitlements
```

---

## Implementation Phases

### Phase 1 — Xcode Project Setup

1. New Xcode project: iOS App, SwiftUI, Swift, bundle ID `com.daniel.antirot`
2. Set deployment target to **iOS 16.0** on all targets
3. Add 3 extension targets via File → New → Target:
   - "Device Activity Monitor Extension" → `DeviceActivityMonitorExtension`
   - "Shield Configuration Extension" → `ShieldConfigurationExtension`
   - "Shield Action Handler Extension" → `ShieldActionHandlerExtension`
4. For all 4 targets, Signing & Capabilities → add:
   - App Groups → `group.com.daniel.antirot`
   - Family Controls
5. Main app only: Info tab → URL Types → add scheme `antirot`
6. Verify all `.entitlements` files contain both keys

### Phase 2 — Shared Models & Storage

Create these files and add them to both the main app and `DeviceActivityMonitorExtension` targets:
- `TimeWindow.swift` — Codable struct
- `OverrideState.swift` — Codable struct
- `SharedStorage.swift` — UserDefaults wrapper

The shield extensions only need to read the shield configuration, not app selection — so they don't need shared storage.

### Phase 3 — Authorization

`AntiRotApp.swift`:

```swift
@main
struct AntiRotApp: App {
    @StateObject var authState = AuthState()

    var body: some Scene {
        WindowGroup {
            if authState.isAuthorized {
                ContentView()
            } else {
                AuthorizationView(authState: authState)
            }
        }
    }
}

class AuthState: ObservableObject {
    @Published var isAuthorized = false

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            await MainActor.run { isAuthorized = true }
        } catch {
            // Show error — user must authorize in Settings → Screen Time
        }
    }
}
```

`AuthorizationView` shows a brief explanation and a "Get Started" button that calls `requestAuthorization()`. If denied, shows instructions to go to Settings → Screen Time.

### Phase 4 — ContentView (Tab Structure)

```swift
struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
            AppSelectionView()
                .tabItem { Label("Apps", systemImage: "square.grid.2x2") }
            ScheduleView()
                .tabItem { Label("Schedule", systemImage: "clock") }
        }
    }
}
```

### Phase 5 — HomeView

State driven by `OverrideState` from SharedStorage, refreshed via a 1-second `Timer`.

UI elements:
- **Status badge**: "BLOCKED" (red) or "ALLOWED" (green) based on current time vs allowed windows
- **Override button** ("I'm Eating 🍕"):
  - Normal: large prominent button
  - Override active: disabled, shows "Override active — Xm remaining"
  - Already used today: disabled, shows "Used today — resets at midnight"
- On button tap: calls `ScreenTimeService.shared.activateOverride()`

### Phase 6 — AppSelectionView

```swift
struct AppSelectionView: View {
    @State private var selection = FamilyActivitySelection()
    @State private var isPickerPresented = false

    var body: some View {
        VStack(spacing: 24) {
            Text("\(selection.applicationTokens.count) apps selected")
                .font(.title2)
            Button("Choose Apps to Block") {
                isPickerPresented = true
            }
            .buttonStyle(.borderedProminent)
        }
        .familyActivityPicker(isPresented: $isPickerPresented, selection: $selection)
        .onChange(of: selection) { newVal in
            SharedStorage.saveSelection(newVal)
            ScreenTimeService.shared.reapplyShieldsIfCurrentlyBlocked()
        }
        .onAppear {
            if let saved = SharedStorage.loadSelection() {
                selection = saved
            }
        }
    }
}
```

Note: app names are not shown — only the count. Tokens are opaque by Apple's design (privacy). This is expected behavior.

### Phase 7 — ScheduleView

- List of `TimeWindow` items with swipe-to-delete
- "Add Window" button → sheet with:
  - Text field for label (e.g. "Lunch")
  - Two `DatePicker` controls in `.hourAndMinute` mode for start and end
- Validation: warn if windows overlap
- Warn if no windows exist ("Apps will be blocked all day")
- On any change: `ScreenTimeService.shared.applySchedules()`

### Phase 8 — ScreenTimeService

Core orchestration in the main app:

```swift
class ScreenTimeService {
    static let shared = ScreenTimeService()
    private let center = DeviceActivityCenter()

    func applySchedules() {
        let windows = SharedStorage.loadWindows()
        let blockedPeriods = computeBlockedPeriods(from: windows)
        center.stopMonitoring()
        for (i, period) in blockedPeriods.enumerated() {
            let schedule = DeviceActivitySchedule(
                intervalStart: period.start,
                intervalEnd: period.end,
                repeats: true
            )
            try? center.startMonitoring(
                DeviceActivityName("blocked-period-\(i)"),
                during: schedule
            )
        }
    }

    func activateOverride() {
        let state = SharedStorage.loadOverrideState()
        let alreadyUsed = state.lastUsedDate.map {
            Calendar.current.isDateInToday($0)
        } ?? false
        guard !alreadyUsed else { return }

        // Remove shields immediately
        ManagedSettingsStore().shield.applications = nil

        // Record state
        let expiry = Date.now.addingTimeInterval(45 * 60)
        SharedStorage.saveOverrideState(
            OverrideState(lastUsedDate: .now, overrideExpiresAt: expiry)
        )

        // Start one-shot 45-min DeviceActivity
        let startComponents = Calendar.current.dateComponents([.hour, .minute], from: .now)
        let endComponents = Calendar.current.dateComponents([.hour, .minute], from: expiry)
        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false
        )
        try? center.startMonitoring(DeviceActivityName("override"), during: schedule)
    }

    func reapplyShieldsIfCurrentlyBlocked() {
        let windows = SharedStorage.loadWindows()
        guard isCurrentlyBlocked(windows: windows) else { return }
        guard let selection = SharedStorage.loadSelection() else { return }
        ManagedSettingsStore().shield.applications = selection.applicationTokens
    }

    private func isCurrentlyBlocked(windows: [TimeWindow]) -> Bool {
        let now = Calendar.current.dateComponents([.hour, .minute], from: .now)
        let nowMinutes = (now.hour ?? 0) * 60 + (now.minute ?? 0)
        for w in windows {
            let start = w.startHour * 60 + w.startMinute
            let end = w.endHour * 60 + w.endMinute
            if nowMinutes >= start && nowMinutes < end { return false }
        }
        return true
    }

    private func computeBlockedPeriods(from windows: [TimeWindow]) -> [(start: DateComponents, end: DateComponents)] {
        // Sort windows, find gaps, return as (start, end) DateComponents pairs
        // Include gap from 00:00 to first window start
        // Include gaps between consecutive windows
        // Include gap from last window end to 23:59
        // Return empty array if no windows (caller should warn user)
    }
}
```

### Phase 9 — DeviceActivityMonitorExtension

```swift
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    override func intervalDidStart(for activity: DeviceActivityName) {
        guard activity.rawValue.hasPrefix("blocked-period") else { return }
        applyShields()
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        if activity.rawValue.hasPrefix("blocked-period") {
            removeShields()
        }
        if activity.rawValue == "override" {
            applyShields()
            var state = SharedStorage.loadOverrideState()
            state.overrideExpiresAt = nil
            SharedStorage.saveOverrideState(state)
        }
    }

    private func applyShields() {
        guard let selection = SharedStorage.loadSelection() else { return }
        ManagedSettingsStore().shield.applications = selection.applicationTokens
    }

    private func removeShields() {
        ManagedSettingsStore().shield.applications = nil
    }
}
```

Memory limit: extensions are capped at **5 MB**. Keep SharedStorage and models minimal, no large dependencies.

### Phase 10 — ShieldConfigurationExtension

```swift
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application)
        -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            title: ShieldConfiguration.Label(text: "Anti-Rot", color: .white),
            subtitle: ShieldConfiguration.Label(
                text: "This app is blocked right now.",
                color: UIColor(white: 1, alpha: 0.7)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Open Anti-Rot",
                color: .black
            ),
            primaryButtonBackgroundColor: .white,
            secondaryButtonLabel: nil  // No secondary button — no easy escape
        )
    }
}
```

### Phase 11 — ShieldActionHandlerExtension

The shield action handler cannot directly launch another app. The "Open Anti-Rot" button closes the shield; the user then manually opens the Anti-Rot app to use their daily override.

```swift
class ShieldActionHandlerExtension: ShieldActionDelegate {

    override func handle(
        action: ShieldAction,
        for application: Application,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(.close)
    }
}
```

---

## Edge Cases

| Case | Handling |
|---|---|
| First launch, nothing configured | Prompt to visit Apps tab and Schedule tab before restrictions take effect |
| FamilyControls authorization denied | Show message with Settings → Screen Time navigation instructions |
| Override already active | "I'm Eating" button disabled, shows countdown |
| Override used today | "I'm Eating" button disabled, shows "Resets at midnight" |
| No allowed windows set | Warn user "Your apps will be blocked all day" before saving empty schedule |
| App selection changed while currently blocked | `reapplyShieldsIfCurrentlyBlocked()` updates the shield token set immediately |
| Schedule changed mid-day | `applySchedules()` stops all monitoring and restarts — state adjusts to current time |
| Overlapping time windows | Validate in UI and reject with inline error before saving |
| Windows crossing midnight | Not supported in v1 — validate and reject; day boundary is 23:59→00:00 |

---

## Key API Reference

```swift
// Authorization
try await AuthorizationCenter.shared.requestAuthorization(for: .individual)

// App picker (SwiftUI)
.familyActivityPicker(isPresented: $bool, selection: $familyActivitySelection)

// Apply / remove shield
ManagedSettingsStore().shield.applications = selection.applicationTokens  // block
ManagedSettingsStore().shield.applications = nil                           // unblock

// Start monitoring a schedule
try DeviceActivityCenter().startMonitoring(
    DeviceActivityName("blocked-period-0"),
    during: DeviceActivitySchedule(
        intervalStart: DateComponents(hour: 0, minute: 0),
        intervalEnd: DateComponents(hour: 12, minute: 0),
        repeats: true
    )
)

// Stop all monitoring
DeviceActivityCenter().stopMonitoring()

// Monitor extension callbacks
class MyMonitor: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) { }
    override func intervalDidEnd(for activity: DeviceActivityName) { }
}
```

---

## App Store Notes (When Ready)

- Category: **Productivity** or **Utilities**
- Privacy policy required — since no data leaves the device, a one-liner "we collect nothing" suffices. Host for free on GitHub Pages.
- In App Store Connect → App Privacy: declare "Data Not Collected"
- The Family Controls entitlement must be approved before you can submit
- Age rating: 4+
- Take screenshots on a physical device (simulator won't work)
- Small Business Program: if revenue is under $1M/year, Apple's cut is 15% not 30%

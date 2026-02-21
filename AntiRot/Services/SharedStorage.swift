import Foundation
import FamilyControls

// SharedStorage is compiled into both AntiRot and DeviceActivityMonitorExtension.
// Do not import anything that isn't available in app extensions.

struct SharedStorage {
    private static let suiteName = "group.com.daniel.antirot"
    static let defaults = UserDefaults(suiteName: suiteName)!

    // MARK: - Selected Apps

    static func saveSelection(_ selection: FamilyActivitySelection) {
        let data = try? PropertyListEncoder().encode(selection)
        defaults.set(data, forKey: "selectedApps")
    }

    static func loadSelection() -> FamilyActivitySelection? {
        guard let data = defaults.data(forKey: "selectedApps") else { return nil }
        return try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
    }

    // MARK: - Allowed Windows

    static func saveWindows(_ windows: [TimeWindow]) {
        let data = try? JSONEncoder().encode(windows)
        defaults.set(data, forKey: "allowedWindows")
    }

    static func loadWindows() -> [TimeWindow] {
        guard let data = defaults.data(forKey: "allowedWindows") else { return [] }
        return (try? JSONDecoder().decode([TimeWindow].self, from: data)) ?? []
    }

    // MARK: - Override State

    static func saveOverrideState(_ state: OverrideState) {
        let data = try? JSONEncoder().encode(state)
        defaults.set(data, forKey: "overrideState")
    }

    static func loadOverrideState() -> OverrideState {
        guard let data = defaults.data(forKey: "overrideState") else { return OverrideState() }
        return (try? JSONDecoder().decode(OverrideState.self, from: data)) ?? OverrideState()
    }
}

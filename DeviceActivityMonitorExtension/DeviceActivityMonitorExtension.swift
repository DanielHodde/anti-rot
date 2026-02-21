import DeviceActivity
import ManagedSettings
import Foundation

// This extension runs in the background. Apple calls intervalDidStart / intervalDidEnd
// when the schedules fire. It has a strict 5 MB memory limit.

class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    override func intervalDidStart(for activity: DeviceActivityName) {
        guard activity.rawValue.hasPrefix("blocked-period") else { return }
        applyShields()
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        if activity.rawValue.hasPrefix("blocked-period") {
            removeShields()
        } else if activity.rawValue == "override" {
            // The 45-minute override just ended — re-block
            applyShields()
            clearOverrideExpiry()
        }
    }

    // MARK: - Private

    private func applyShields() {
        guard let selection = SharedStorage.loadSelection() else { return }
        ManagedSettingsStore().shield.applications = selection.applicationTokens
    }

    private func removeShields() {
        ManagedSettingsStore().shield.applications = nil
    }

    private func clearOverrideExpiry() {
        var state = SharedStorage.loadOverrideState()
        state.overrideExpiresAt = nil
        SharedStorage.saveOverrideState(state)
    }
}

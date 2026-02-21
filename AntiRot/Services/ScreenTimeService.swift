import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings

@MainActor
class ScreenTimeService {
    static let shared = ScreenTimeService()
    private let center = DeviceActivityCenter()

    private init() {}

    // MARK: - Scheduling

    func applySchedules() {
        let windows = SharedStorage.loadWindows()
        let blockedPeriods = computeBlockedPeriods(from: windows)

        center.stopMonitoring()
        guard !blockedPeriods.isEmpty else { return }

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

        reapplyShieldsIfCurrentlyBlocked()
    }

    // MARK: - Override

    func activateOverride() {
        let state = SharedStorage.loadOverrideState()
        guard !state.isActiveToday else { return }

        // Remove shields immediately
        ManagedSettingsStore().shield.applications = nil

        // Record the override
        let expiry = Date.now.addingTimeInterval(45 * 60)
        SharedStorage.saveOverrideState(
            OverrideState(lastUsedDate: .now, overrideExpiresAt: expiry)
        )

        // Start a one-shot DeviceActivity for 45 minutes so the monitor
        // extension can re-apply shields exactly when time is up.
        let startComponents = Calendar.current.dateComponents([.hour, .minute], from: .now)
        let endComponents = Calendar.current.dateComponents([.hour, .minute], from: expiry)
        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false
        )
        try? center.startMonitoring(DeviceActivityName("override"), during: schedule)
    }

    // MARK: - Shield Management

    func reapplyShieldsIfCurrentlyBlocked() {
        let windows = SharedStorage.loadWindows()
        let overrideState = SharedStorage.loadOverrideState()
        guard isCurrentlyBlocked(windows: windows),
              !overrideState.isOverrideCurrentlyActive else { return }
        guard let selection = SharedStorage.loadSelection() else { return }
        ManagedSettingsStore().shield.applications = selection.applicationTokens
    }

    // MARK: - Helpers (internal, also used by HomeViewModel)

    func isCurrentlyBlocked(windows: [TimeWindow]) -> Bool {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: .now)
        let nowMinutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        for w in windows {
            if nowMinutes >= w.startTotalMinutes && nowMinutes < w.endTotalMinutes {
                return false
            }
        }
        return true
    }

    // MARK: - Private

    private func computeBlockedPeriods(
        from windows: [TimeWindow]
    ) -> [(start: DateComponents, end: DateComponents)] {
        guard !windows.isEmpty else { return [] }

        let sorted = windows.sorted { $0.startTotalMinutes < $1.startTotalMinutes }
        var periods: [(start: DateComponents, end: DateComponents)] = []
        var cursor = 0  // minutes from midnight

        for window in sorted {
            if cursor < window.startTotalMinutes {
                periods.append((
                    start: minutesToComponents(cursor),
                    end: minutesToComponents(window.startTotalMinutes)
                ))
            }
            cursor = window.endTotalMinutes
        }

        // Final blocked period from last window end to end of day
        let endOfDay = 23 * 60 + 59
        if cursor < endOfDay {
            periods.append((
                start: minutesToComponents(cursor),
                end: minutesToComponents(endOfDay)
            ))
        }

        return periods
    }

    private func minutesToComponents(_ totalMinutes: Int) -> DateComponents {
        DateComponents(hour: totalMinutes / 60, minute: totalMinutes % 60)
    }
}

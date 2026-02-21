import Foundation

struct OverrideState: Codable {
    var lastUsedDate: Date?
    var overrideExpiresAt: Date?

    init(lastUsedDate: Date? = nil, overrideExpiresAt: Date? = nil) {
        self.lastUsedDate = lastUsedDate
        self.overrideExpiresAt = overrideExpiresAt
    }

    var isActiveToday: Bool {
        guard let lastUsed = lastUsedDate else { return false }
        return Calendar.current.isDateInToday(lastUsed)
    }

    var isOverrideCurrentlyActive: Bool {
        guard let expiry = overrideExpiresAt else { return false }
        return expiry > .now
    }

    var remainingSeconds: TimeInterval {
        guard let expiry = overrideExpiresAt else { return 0 }
        return max(0, expiry.timeIntervalSinceNow)
    }
}

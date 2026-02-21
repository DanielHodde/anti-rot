import Foundation

struct TimeWindow: Codable, Identifiable {
    var id: UUID = UUID()
    var label: String
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int

    var startTotalMinutes: Int { startHour * 60 + startMinute }
    var endTotalMinutes: Int { endHour * 60 + endMinute }

    var startTimeString: String { formatTime(hour: startHour, minute: startMinute) }
    var endTimeString: String { formatTime(hour: endHour, minute: endMinute) }

    private func formatTime(hour: Int, minute: Int) -> String {
        let period = hour < 12 ? "AM" : "PM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }
}

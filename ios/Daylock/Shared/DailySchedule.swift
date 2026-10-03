import Foundation

/// One chosen photo per local day, in library order.
enum DailySchedule {
    /// Index of the photo to show on `date`. The anchor day shows the first photo.
    static func index(for date: Date, count: Int, anchor: Date, calendar: Calendar = .current) -> Int {
        guard count > 0 else { return 0 }
        let start = calendar.startOfDay(for: anchor)
        let day = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: start, to: day).day ?? 0
        let remainder = days % count
        return remainder >= 0 ? remainder : remainder + count
    }

    /// The next local midnight, when the scheduled photo advances.
    static func nextChange(after date: Date, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: start) ?? date.addingTimeInterval(86_400)
    }
}

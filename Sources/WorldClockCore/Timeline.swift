import Foundation

/// Entry dates for a widget timeline: one per minute, starting at the start of the current
/// minute. Never in the future: a timeline whose first entry hasn't arrived draws a placeholder.
public func minuteTimeline(from now: Date, count: Int, calendar: Calendar = .current) -> [Date] {
    let start = calendar.dateInterval(of: .minute, for: now)?.start ?? now
    return (0..<count).map { start.addingTimeInterval(Double($0) * 60) }
}

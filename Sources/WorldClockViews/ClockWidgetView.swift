import SwiftUI
import WorldClockCore

/// The whole widget body. Everything time-dependent is computed from `date`, so each
/// timeline entry draws its own time, day word and sky band.
public struct ClockWidgetView: View {
    let rows: [ClockRow]
    let date: Date
    let userZone: TimeZone
    let size: WidgetSize
    let monochrome: Bool
    let locale: Locale
    let hourCycle: HourCycle

    public init(rows: [ClockRow], date: Date, userZone: TimeZone, size: WidgetSize, monochrome: Bool, locale: Locale,
                hourCycle: HourCycle) {
        self.rows = rows
        self.date = date
        self.userZone = userZone
        self.size = size
        self.monochrome = monochrome
        self.locale = locale
        self.hourCycle = hourCycle
    }

    public var body: some View {
        let plan = layout(rowCount: rows.count, size: size)
        VStack(spacing: plan.style == .full ? 6 : 4) {
            ForEach(Array(rows.prefix(plan.visibleCount).enumerated()), id: \.offset) { _, row in
                AnyClockRow(row: row, date: date, userZone: userZone, style: plan.style, monochrome: monochrome,
                            locale: locale, hourCycle: hourCycle)
            }
            if plan.overflowCount > 0 {
                NoteRow(text: "+\(plan.overflowCount) more", monochrome: monochrome)
            }
            if rows.count == 1 {
                NoteRow(text: "Add cities from the menu bar 🌐", monochrome: monochrome)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

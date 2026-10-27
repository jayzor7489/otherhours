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

    public init(rows: [ClockRow], date: Date, userZone: TimeZone, size: WidgetSize, monochrome: Bool, locale: Locale) {
        self.rows = rows
        self.date = date
        self.userZone = userZone
        self.size = size
        self.monochrome = monochrome
        self.locale = locale
    }

    public var body: some View {
        let plan = layout(rowCount: rows.count, size: size)
        VStack(spacing: plan.style == .full ? 6 : 4) {
            ForEach(Array(rows.prefix(plan.visibleCount).enumerated()), id: \.offset) { _, row in
                rowView(row, style: plan.style)
            }
            if plan.overflowCount > 0 {
                NoteRow(text: "+\(plan.overflowCount) more", monochrome: monochrome)
            }
            if rows.count == 1 {
                NoteRow(text: "Right-click › Edit Widget to add cities", monochrome: monochrome)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder private func rowView(_ row: ClockRow, style: RowStyle) -> some View {
        switch row {
        case .you(let name, let flag, let zone):
            PlaceRow(name: name, flag: flag, zone: zone, isYou: true, date: date, userZone: userZone,
                     style: style, monochrome: monochrome, locale: locale)
        case .city(let name, let flag, let zone):
            PlaceRow(name: name, flag: flag, zone: zone, isYou: false, date: date, userZone: userZone,
                     style: style, monochrome: monochrome, locale: locale)
        case .unknown(let typed):
            UnknownRow(typed: typed, style: style, monochrome: monochrome)
        }
    }
}

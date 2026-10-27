import SwiftUI
import WorldClockCore

/// Mockup A: a clean list with thin dividers and light, large times. Uses semantic colours, so it
/// reads on the white card, the dark card and in the system's monochrome and tinted styles.
struct ListThemeView: View {
    let rows: [ClockRow]
    let date: Date
    let userZone: TimeZone
    let size: WidgetSize?  // nil in the panel: every row, full size
    let locale: Locale
    let hourCycle: HourCycle
    let emptyNote: String

    var body: some View {
        let plan = size.map { layout(rowCount: rows.count, size: $0, theme: .list) }
            ?? RowLayout(style: .full, visibleCount: rows.count, overflowCount: 0)
        let full = plan.style == .full
        VStack(spacing: 0) {
            ForEach(Array(rows.prefix(plan.visibleCount).enumerated()), id: \.offset) { index, row in
                if index > 0 { Divider().opacity(0.6) }
                ListRow(place: Place(row), date: date, userZone: userZone, full: full, locale: locale, hourCycle: hourCycle)
                    .frame(maxHeight: size == nil ? nil : .infinity)
                    .padding(.vertical, size == nil ? 7 : 0)
            }
            if plan.overflowCount > 0 {
                Divider().opacity(0.6)
                note("+\(plan.overflowCount) more")
            }
            if rows.count == 1 {
                Divider().opacity(0.6)
                note(emptyNote)
            }
        }
        .padding(.horizontal, 9)
        .frame(maxWidth: .infinity, maxHeight: size == nil ? nil : .infinity)
    }

    private func note(_ text: String) -> some View {
        Text(text).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: size == nil ? nil : .infinity, alignment: .leading)
            .padding(.vertical, size == nil ? 7 : 4)
    }
}

private struct ListRow: View {
    let place: Place
    let date: Date
    let userZone: TimeZone
    let full: Bool
    let locale: Locale
    let hourCycle: HourCycle

    var body: some View {
        let parts = timeParts(date, in: place.zone, locale: locale, hourCycle: hourCycle)
        HStack(spacing: 10) {
            Text(place.flag).font(.system(size: full ? 22 : 18)).fixedSize()
            VStack(alignment: .leading, spacing: 1) {
                NameWithDifference(name: Text(place.name).fontWeight(.semibold)
                                       + Text(place.isYou ? " · you" : "").foregroundColor(.secondary),
                                   nameSize: 14,
                                   difference: full || place.isYou ? nil : compactDifference(at: date, cityZone: place.zone, userZone: userZone),
                                   differenceSize: 11, differenceStyle: AnyShapeStyle(.secondary))
                if full {
                    Text(subLine(for: place, date: date, userZone: userZone, locale: locale))
                        .font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            .layoutPriority(1)
            Spacer(minLength: 4)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(parts.time).font(.system(size: full ? 24 : 20, weight: .light)).monospacedDigit()
                if let period = parts.period {
                    Text(period).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                }
            }
            .fixedSize()
        }
    }
}

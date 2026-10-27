import SwiftUI
import WorldClockCore

/// Mockup D: own time large on the left, the cities listed on the right with their hour
/// difference. In the panel (`size` nil) the hero sits on top and every city is listed below.
struct SpotlightThemeView: View {
    let rows: [ClockRow]
    let date: Date
    let userZone: TimeZone
    let size: WidgetSize?
    let locale: Locale
    let hourCycle: HourCycle
    let emptyNote: String

    var body: some View {
        let plan = size.map { layout(rowCount: rows.count, size: $0, theme: .spotlight) }
            ?? RowLayout(style: .full, visibleCount: rows.count, overflowCount: 0)
        let cities = Array(rows.prefix(plan.visibleCount).dropFirst())
        if size == nil {
            VStack(alignment: .leading, spacing: 12) {
                hero
                Divider()
                list(cities, overflow: 0)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
        } else {
            // The hero takes only what its time needs; names get the rest.
            HStack(spacing: 10) {
                hero.fixedSize()
                Divider()
                list(cities, overflow: plan.overflowCount).frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 9)
            .frame(maxHeight: .infinity)
        }
    }

    private var hero: some View {
        let own = Place(rows[0])
        let parts = timeParts(date, in: own.zone, locale: locale, hourCycle: hourCycle)
        return VStack(alignment: .leading, spacing: 2) {
            Text("\(own.flag) \(own.name) · you").font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(parts.time).font(.system(size: 40, weight: .thin)).monospacedDigit()
                if let period = parts.period {
                    Text(period).font(.system(size: 14, weight: .medium)).foregroundStyle(.secondary)
                }
            }
            .lineLimit(1).minimumScaleFactor(0.7)
            Text(dateLine(date, zone: own.zone, locale: locale, template: "EEEEMMMd"))
                .font(.system(size: 11)).foregroundStyle(.secondary)
        }
    }

    private func list(_ cities: [ClockRow], overflow: Int) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            ForEach(Array(cities.enumerated()), id: \.offset) { _, row in
                let place = Place(row)
                let parts = timeParts(date, in: place.zone, locale: locale, hourCycle: hourCycle)
                HStack(spacing: 6) {
                    Text(place.flag)
                    Text(place.name).fontWeight(.semibold).lineLimit(1).minimumScaleFactor(0.8).layoutPriority(1)
                    Spacer(minLength: 2)
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text(parts.time).fontWeight(.medium).monospacedDigit()
                        if let period = parts.period { Text(period).font(.system(size: 9, weight: .medium)) }
                    }
                    .fixedSize()
                    Text(shortOffset(at: date, cityZone: place.zone, userZone: userZone))
                        .font(.system(size: 10)).foregroundStyle(.secondary).frame(width: 28, alignment: .trailing)
                }
                .font(.system(size: 12.5))
            }
            if overflow > 0 {
                Text("+\(overflow) more").font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
            }
            if cities.isEmpty {
                Text(emptyNote).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
            }
        }
    }
}

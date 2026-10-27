import SwiftUI
import WorldClockCore

/// The widget's own card colour in full-colour mode (mockup B).
public let widgetBackground = Color(red: 0x0F / 255, green: 0x14 / 255, blue: 0x20 / 255)

private func hex(_ value: UInt32) -> Color {
    Color(red: Double((value >> 16) & 0xFF) / 255, green: Double((value >> 8) & 0xFF) / 255, blue: Double(value & 0xFF) / 255)
}

extension SkyBand {
    var gradient: LinearGradient {
        LinearGradient(colors: [hex(gradientHex.leading), hex(gradientHex.trailing)], startPoint: .leading, endPoint: .trailing)
    }

    /// Monochrome/tinted mode loses hue, so bands differ by brightness instead.
    var monochromeOpacity: Double {
        switch self {
        case .night: 0.08
        case .dawn, .dusk: 0.20
        case .day: 0.34
        }
    }

    var emoji: String {
        switch self {
        case .night: "🌙"
        case .dawn: "🌅"
        case .day: "☀️"
        case .dusk: "🌇"
        }
    }

    var symbol: String {
        switch self {
        case .night: "moon.stars.fill"
        case .dawn: "sunrise.fill"
        case .day: "sun.max.fill"
        case .dusk: "sunset.fill"
        }
    }
}

/// Shared look for every bar: rounded, full width, filled by band or a neutral tint.
struct Bar<Content: View>: View {
    let band: SkyBand?
    let style: RowStyle
    let monochrome: Bool
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: style == .full ? 9 : 8) { content }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, maxHeight: style == .full ? 56 : 40)
            .background { fill.clipShape(RoundedRectangle(cornerRadius: style == .full ? 12 : 10, style: .continuous)) }
    }

    @ViewBuilder private var fill: some View {
        if let band, !monochrome {
            Rectangle().fill(band.gradient)
        } else {
            Rectangle().fill(Color.white.opacity(band?.monochromeOpacity ?? 0.06))
        }
    }
}

struct SkyIcon: View {
    let band: SkyBand
    let monochrome: Bool
    let size: CGFloat

    var body: some View {
        if monochrome {
            Image(systemName: band.symbol).font(.system(size: size - 1))
        } else {
            Text(band.emoji).font(.system(size: size))
        }
    }
}

/// A city (or the user's own) row in full or compact style.
struct PlaceRow: View {
    let name: String
    let flag: String
    let zone: TimeZone
    let isYou: Bool
    let date: Date
    let userZone: TimeZone
    let style: RowStyle
    let monochrome: Bool
    let locale: Locale
    let hourCycle: HourCycle

    var body: some View {
        let band = SkyBand.at(date, in: zone)
        let parts = timeParts(date, in: zone, locale: locale, hourCycle: hourCycle)
        let full = style == .full
        Bar(band: band, style: style, monochrome: monochrome) {
            Text(flag).font(.system(size: full ? 18 : 16)).fixedSize()  // a flag never gives way to a long name
            VStack(alignment: .leading, spacing: 1) {
                // Compact rows have no second line, so the difference sits beside the name.
                NameWithDifference(name: Text(name).fontWeight(.semibold)
                                       + Text(isYou ? " · you" : "").fontWeight(.regular).foregroundColor(.white.opacity(0.7)),
                                   nameSize: full ? 13 : 14,
                                   difference: full || isYou ? nil : compactDifference(at: date, cityZone: zone, userZone: userZone),
                                   differenceSize: 10.5, differenceStyle: AnyShapeStyle(.white.opacity(0.78)))
                if full {
                    Text(WorldClockViews.subLine(for: Place(name: name, flag: flag, zone: zone, isYou: isYou), date: date, userZone: userZone, locale: locale))
                        .font(.system(size: 10)).opacity(0.78).lineLimit(1)
                }
            }
            .layoutPriority(1)
            Spacer(minLength: 4)
            SkyIcon(band: band, monochrome: monochrome, size: full ? 13 : 12).fixedSize()  // flag, icon and time never give way
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(parts.time).font(.system(size: full ? 20 : 18, weight: .medium)).monospacedDigit()
                if let period = parts.period {
                    Text(period).font(.system(size: 10, weight: .medium)).opacity(0.8)
                }
            }
            .fixedSize()
        }
    }
}

/// Any ClockRow, drawn the same way in the widget and the menu bar panel.
struct AnyClockRow: View {
    let row: ClockRow
    let date: Date
    let userZone: TimeZone
    let style: RowStyle
    let monochrome: Bool
    let locale: Locale
    let hourCycle: HourCycle

    var body: some View {
        switch row {
        case .you(let name, let flag, let zone):
            PlaceRow(name: name, flag: flag, zone: zone, isYou: true, date: date, userZone: userZone,
                     style: style, monochrome: monochrome, locale: locale, hourCycle: hourCycle)
        case .city(let name, let flag, let zone):
            PlaceRow(name: name, flag: flag, zone: zone, isYou: false, date: date, userZone: userZone,
                     style: style, monochrome: monochrome, locale: locale, hourCycle: hourCycle)
        }
    }
}

struct NoteRow: View {
    let text: String
    let monochrome: Bool

    var body: some View {
        Bar(band: nil, style: .compact, monochrome: monochrome) {
            Text(text).font(.system(size: 12, weight: .medium)).opacity(0.8).lineLimit(1)
            Spacer(minLength: 0)
        }
    }
}

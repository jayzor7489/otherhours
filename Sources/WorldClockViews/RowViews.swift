import SwiftUI
import WorldClockCore

/// The widget's own card colour in full-colour mode (mockup B).
public let widgetBackground = Color(red: 0x0F / 255, green: 0x14 / 255, blue: 0x20 / 255)

private func hex(_ value: UInt32) -> Color {
    Color(red: Double((value >> 16) & 0xFF) / 255, green: Double((value >> 8) & 0xFF) / 255, blue: Double(value & 0xFF) / 255)
}

extension SkyBand {
    var gradient: LinearGradient {
        let (from, to): (UInt32, UInt32) = switch self {
        case .night: (0x1B2340, 0x2B2F5C)
        case .dawn: (0x3D4F86, 0xE59B74)
        case .day: (0x3F8FE0, 0x8CC8F5)
        case .dusk: (0x4A8FD8, 0xF2B45C)
        }
        return LinearGradient(colors: [hex(from), hex(to)], startPoint: .leading, endPoint: .trailing)
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

    var body: some View {
        let band = SkyBand.at(date, in: zone)
        let parts = timeParts(date, in: zone, locale: locale)
        let full = style == .full
        Bar(band: band, style: style, monochrome: monochrome) {
            Text(flag).font(.system(size: full ? 18 : 16))
            VStack(alignment: .leading, spacing: 1) {
                (Text(name).fontWeight(.semibold)
                    + Text(isYou ? " · you" : "").fontWeight(.regular).foregroundColor(.white.opacity(0.7)))
                    .font(.system(size: full ? 13 : 14))
                    .lineLimit(1)
                if full {
                    Text(subLine).font(.system(size: 10)).opacity(0.78).lineLimit(1)
                }
            }
            .layoutPriority(1)
            Spacer(minLength: 4)
            SkyIcon(band: band, monochrome: monochrome, size: full ? 13 : 12)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(parts.time).font(.system(size: full ? 20 : 18, weight: .medium)).monospacedDigit()
                if let period = parts.period {
                    Text(period).font(.system(size: 10, weight: .medium)).opacity(0.8)
                }
            }
            .fixedSize()
        }
    }

    private var subLine: String {
        if isYou {
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.timeZone = zone
            formatter.setLocalizedDateFormatFromTemplate("EEEMMMd")
            return formatter.string(from: date)
        }
        let day = dayRelation(at: date, cityZone: zone, userZone: userZone).label
        return "\(day) · \(offsetLabel(at: date, cityZone: zone, userZone: userZone))"
    }
}

struct UnknownRow: View {
    let typed: String
    let style: RowStyle
    let monochrome: Bool

    var body: some View {
        Bar(band: nil, style: style, monochrome: monochrome) {
            Text("❓").font(.system(size: style == .full ? 16 : 14))
            Text(typed).font(.system(size: style == .full ? 13 : 14, weight: .semibold)).opacity(0.6).lineLimit(1)
            Spacer(minLength: 0)
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

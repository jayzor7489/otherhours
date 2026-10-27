import SwiftUI
import WorldClockCore

/// Mockup C: analog faces, black at night and white otherwise, with the flag and name under each.
/// Widget: medium is one row of up to 4 faces, large a 3 × 3 grid; the panel (`size` nil) shows
/// every place, 3 per row.
struct ClocksThemeView: View {
    let rows: [ClockRow]
    let date: Date
    let userZone: TimeZone
    let size: WidgetSize?
    let monochrome: Bool
    let locale: Locale
    let emptyNote: String

    var body: some View {
        let plan = size.map { layout(rowCount: rows.count, size: $0, theme: .clocks) }
            ?? RowLayout(style: .full, visibleCount: rows.count, overflowCount: 0)
        let perRow = size == .medium ? 4 : 3
        let cells: [Cell] = rows.prefix(plan.visibleCount).map { .place(Place($0)) }
            + (plan.overflowCount > 0 ? [.note("+\(plan.overflowCount) more")] : [])
            + (rows.count == 1 ? [.note(emptyNote)] : [])
        let diameter: CGFloat = size == .medium ? 64 : 70
        VStack(spacing: size == nil ? 14 : 8) {
            ForEach(Array(stride(from: 0, to: cells.count, by: perRow)), id: \.self) { start in
                HStack(alignment: .top, spacing: 0) {
                    ForEach(start..<min(start + perRow, cells.count), id: \.self) { index in
                        cellView(cells[index], diameter: diameter).frame(maxWidth: .infinity)
                    }
                    // Keep a short last row aligned to the grid.
                    ForEach(0..<(perRow - min(perRow, cells.count - start)), id: \.self) { _ in
                        Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: size == nil ? nil : .infinity)
    }

    private enum Cell {
        case place(Place)
        case note(String)
    }

    @ViewBuilder private func cellView(_ cell: Cell, diameter: CGFloat) -> some View {
        switch cell {
        case .place(let place):
            VStack(spacing: 4) {
                AnalogFace(zone: place.zone, date: date, diameter: diameter, monochrome: monochrome)
                Text("\(place.flag) \(place.name)").font(.system(size: 12, weight: .semibold)).lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(place.isYou ? "you" : subLine(for: place, date: date, userZone: userZone, locale: locale))
                    .font(.system(size: 10)).foregroundStyle(Color(white: 0.6)).lineLimit(1).minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 2)
        case .note(let text):
            Text(text).font(.system(size: 11, weight: .medium)).foregroundStyle(Color(white: 0.6))
                .multilineTextAlignment(.center)
                .frame(height: diameter)
        }
    }
}

/// One face. Night: black face, grey marks, white hands and numbers. Dawn to dusk: white face, dark hands.
struct AnalogFace: View {
    let zone: TimeZone
    let date: Date
    let diameter: CGFloat
    let monochrome: Bool

    var body: some View {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let c = calendar.dateComponents([.hour, .minute], from: date)
        let minutes = Double((c.hour ?? 0) % 12 * 60 + (c.minute ?? 0))
        let band = SkyBand.at(date, in: zone)
        let night = band == .night
        let face: Color = monochrome ? .white.opacity(band.monochromeOpacity) : (night ? .black : .white)
        let ink: Color = monochrome || night ? .white : Color(white: 0.07)
        let ticks: Color = monochrome ? .white.opacity(0.5) : (night ? Color(white: 0.56) : Color(white: 0.78))

        return Canvas { context, size in
            let r = size.width / 2
            let centre = CGPoint(x: r, y: r)
            context.fill(Circle().path(in: CGRect(origin: .zero, size: size).insetBy(dx: r * 0.02, dy: r * 0.02)), with: .color(face))
            if night && !monochrome {
                context.stroke(Circle().path(in: CGRect(origin: .zero, size: size).insetBy(dx: r * 0.02, dy: r * 0.02)),
                               with: .color(Color(white: 0.23)), lineWidth: r * 0.04)
            }
            // Hour marks, with 12, 3, 6 and 9 as numbers (Jason picked this over ticks only or all twelve).
            for hour in 0..<12 {
                let angle = Double(hour) / 12 * 2 * .pi
                if hour % 3 == 0 {
                    context.draw(Text("\(hour == 0 ? 12 : hour)").font(.system(size: r * 0.26, weight: .semibold)).foregroundColor(ink),
                                 at: point(centre, r * 0.70, angle))
                } else {
                    var tick = Path()
                    tick.move(to: point(centre, r * 0.92, angle))
                    tick.addLine(to: point(centre, r * 0.80, angle))
                    context.stroke(tick, with: .color(ticks), style: StrokeStyle(lineWidth: r * 0.045, lineCap: .round))
                }
            }
            hand(&context, centre, length: r * 0.48, width: r * 0.10, angle: minutes / 720 * 2 * .pi, colour: ink)
            hand(&context, centre, length: r * 0.72, width: r * 0.06, angle: minutes.truncatingRemainder(dividingBy: 60) / 60 * 2 * .pi, colour: ink)
            context.fill(Circle().path(in: CGRect(x: r - r * 0.07, y: r - r * 0.07, width: r * 0.14, height: r * 0.14)),
                         with: .color(monochrome ? .white : Color(red: 1, green: 0.62, blue: 0.04)))
        }
        .frame(width: diameter, height: diameter)
    }

    /// Angle 0 is 12 o'clock, clockwise.
    private func point(_ centre: CGPoint, _ length: CGFloat, _ angle: Double) -> CGPoint {
        CGPoint(x: centre.x + length * CGFloat(sin(angle)), y: centre.y - length * CGFloat(cos(angle)))
    }

    private func hand(_ context: inout GraphicsContext, _ centre: CGPoint, length: CGFloat, width: CGFloat, angle: Double, colour: Color) {
        var path = Path()
        path.move(to: centre)
        path.addLine(to: point(centre, length, angle))
        context.stroke(path, with: .color(colour), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }
}

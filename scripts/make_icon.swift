// Draws the app icon: a clock face split diagonally into day (blue, sun) and night (navy, moon),
// with the Clocks theme's hour marks and orange centre dot, on a macOS-style rounded square.
//
//     SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk swift scripts/make_icon.swift Resources/AppIcon.icns
import AppKit

func colour(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

func drawIcon(size s: CGFloat) -> NSImage {
    NSImage(size: NSSize(width: s, height: s), flipped: false) { _ in
        let ctx = NSGraphicsContext.current!.cgContext
        // macOS icon grid: the shape is 824/1024 of the canvas, centred.
        let inset = s * 100 / 1024
        let plate = NSRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
        let plateShape = NSBezierPath(roundedRect: plate, xRadius: plate.width * 0.225, yRadius: plate.width * 0.225)
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = .black.withAlphaComponent(0.35)
        shadow.shadowBlurRadius = s * 0.02
        shadow.shadowOffset = NSSize(width: 0, height: -s * 0.01)
        shadow.set()
        colour(0x0F1420).setFill()
        plateShape.fill()
        NSGraphicsContext.restoreGraphicsState()

        // Face: day in the upper left, night in the lower right.
        let centre = CGPoint(x: s / 2, y: s / 2)
        let r = plate.width * 0.36
        let face = NSBezierPath(ovalIn: NSRect(x: centre.x - r, y: centre.y - r, width: 2 * r, height: 2 * r))
        NSGraphicsContext.saveGraphicsState()
        face.addClip()
        NSGradient(starting: colour(0x6FB2F2), ending: colour(0x3F8FE0))!.draw(in: face, angle: -45)
        let night = NSBezierPath()
        night.move(to: CGPoint(x: centre.x - 2 * r, y: centre.y - 2 * r))
        night.line(to: CGPoint(x: centre.x + 2 * r, y: centre.y + 2 * r))
        night.line(to: CGPoint(x: centre.x + 2 * r, y: centre.y - 2 * r))
        night.close()
        NSGradient(starting: colour(0x2B2F5C), ending: colour(0x1B2340))!.draw(in: night, angle: -45)
        // Dawn/dusk: a warm line exactly on the edge between day and night.
        let edge = NSBezierPath()
        edge.move(to: CGPoint(x: centre.x - 2 * r, y: centre.y - 2 * r))
        edge.line(to: CGPoint(x: centre.x + 2 * r, y: centre.y + 2 * r))
        edge.lineWidth = r * 0.07
        colour(0xF2B45C, 0.9).setStroke()
        edge.stroke()
        // Sun (day side) and a crescent moon (night side).
        colour(0xFFD25A).setFill()
        NSBezierPath(ovalIn: NSRect(x: centre.x - r * 0.62, y: centre.y + r * 0.30, width: r * 0.30, height: r * 0.30)).fill()
        let moonRect = CGRect(x: centre.x + r * 0.32, y: centre.y - r * 0.62, width: r * 0.30, height: r * 0.30)
        ctx.saveGState()
        ctx.addEllipse(in: moonRect)
        ctx.clip()
        ctx.addRect(moonRect)
        ctx.addEllipse(in: moonRect.offsetBy(dx: r * 0.10, dy: r * 0.07))
        ctx.setFillColor(colour(0xEDEFF7).cgColor)
        ctx.fillPath(using: .evenOdd)
        ctx.restoreGState()
        NSGraphicsContext.restoreGraphicsState()
        colour(0xFFFFFF, 0.9).setStroke()
        face.lineWidth = r * 0.05
        face.stroke()

        // Hour marks, longer at 12, 3, 6, 9.
        for hour in 0..<12 {
            let angle = CGFloat(hour) / 12 * 2 * .pi
            let major = hour % 3 == 0
            let mark = NSBezierPath()
            mark.move(to: CGPoint(x: centre.x + sin(angle) * r * 0.90, y: centre.y + cos(angle) * r * 0.90))
            mark.line(to: CGPoint(x: centre.x + sin(angle) * r * (major ? 0.72 : 0.80), y: centre.y + cos(angle) * r * (major ? 0.72 : 0.80)))
            mark.lineWidth = r * (major ? 0.07 : 0.04)
            mark.lineCapStyle = .round
            colour(0xFFFFFF, major ? 0.95 : 0.7).setStroke()
            mark.stroke()
        }

        // Hands at 10:10, white, with the Clocks theme's orange centre.
        func hand(_ angle: CGFloat, _ length: CGFloat, _ width: CGFloat) {
            let path = NSBezierPath()
            path.move(to: centre)
            path.line(to: CGPoint(x: centre.x + sin(angle) * length, y: centre.y + cos(angle) * length))
            path.lineWidth = width
            path.lineCapStyle = .round
            NSColor.white.setStroke()
            path.stroke()
        }
        hand((10 + 10.0 / 60) / 12 * 2 * .pi, r * 0.48, r * 0.10)
        hand(10.0 / 60 * 2 * .pi, r * 0.70, r * 0.065)
        colour(0xFF9F0A).setFill()
        NSBezierPath(ovalIn: NSRect(x: centre.x - r * 0.08, y: centre.y - r * 0.08, width: r * 0.16, height: r * 0.16)).fill()
        return true
    }
}

let out = URL(fileURLWithPath: CommandLine.arguments[1])
let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon-\(UUID()).iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let px = CGFloat(base * scale)
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(px), pixelsHigh: Int(px), bitsPerSample: 8,
                                   samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        drawIcon(size: px).draw(in: NSRect(x: 0, y: 0, width: px, height: px))
        NSGraphicsContext.restoreGraphicsState()
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        try rep.representation(using: .png, properties: [:])!.write(to: iconset.appendingPathComponent(name))
    }
}
let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", out.path]
try iconutil.run()
iconutil.waitUntilExit()
let preview = out.deletingPathExtension().appendingPathExtension("png")  // 1024 px, for READMEs and checks
try? FileManager.default.removeItem(at: preview)
try FileManager.default.copyItem(at: iconset.appendingPathComponent("icon_512x512@2x.png"), to: preview)
print(iconutil.terminationStatus == 0 ? "wrote \(out.path)" : "iconutil failed")

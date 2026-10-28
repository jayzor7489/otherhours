// The menu bar icon: a globe whose face carries clock hands. It is a template image, so macOS
// tints it to match the menu bar (dark on light, light on dark, and when highlighted).
import AppKit

func menuBarIcon() -> NSImage {
    let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
        let ctx = NSGraphicsContext.current!.cgContext
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let r: CGFloat = 7.6
        let face = CGRect(x: centre.x - r, y: centre.y - r, width: 2 * r, height: 2 * r)

        // Globe: outline, a meridian and two latitudes, thin so the hands stand out.
        ctx.setLineWidth(1.3)
        ctx.strokeEllipse(in: face.insetBy(dx: 0.65, dy: 0.65))
        ctx.saveGState()
        ctx.addEllipse(in: face)
        ctx.clip()
        ctx.setLineWidth(0.8)
        ctx.strokeEllipse(in: face.insetBy(dx: r * 0.52, dy: 0.65))
        for y in [centre.y + r * 0.45, centre.y - r * 0.45] {
            ctx.move(to: CGPoint(x: face.minX, y: y))
            ctx.addLine(to: CGPoint(x: face.maxX, y: y))
        }
        ctx.strokePath()
        ctx.restoreGState()

        // Hands at 4:00, the usual clock-symbol pose (10:10 reads as a tick mark at this size).
        // A clear gap is erased around them first, so they don't merge with the grid lines.
        func hands(width extra: CGFloat) {
            func hand(_ angle: CGFloat, _ length: CGFloat, _ width: CGFloat) {
                ctx.setLineWidth(width + extra)
                ctx.move(to: centre)
                ctx.addLine(to: CGPoint(x: centre.x + sin(angle) * length, y: centre.y + cos(angle) * length))
                ctx.strokePath()
            }
            ctx.setLineCap(.round)
            hand(4.0 / 12 * 2 * .pi, r * 0.50, 1.5)
            hand(0, r * 0.70, 1.3)
        }
        ctx.setBlendMode(.clear)
        hands(width: 1.6)
        ctx.setBlendMode(.normal)
        hands(width: 0)
        return true
    }
    image.isTemplate = true
    image.accessibilityDescription = "World Clock"
    return image
}

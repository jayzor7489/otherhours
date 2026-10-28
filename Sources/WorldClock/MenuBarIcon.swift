// The menu bar icon: the app icon's day/night clock in one colour. It is a template image, so
// macOS tints it to match the menu bar (dark on light, light on dark, and when highlighted).
import AppKit

func menuBarIcon() -> NSImage {
    let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
        let ctx = NSGraphicsContext.current!.cgContext
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let r: CGFloat = 7.4
        let face = CGRect(x: centre.x - r, y: centre.y - r, width: 2 * r, height: 2 * r)

        // Night: the lower-right half of the face, filled, as on the app icon.
        ctx.saveGState()
        ctx.addEllipse(in: face)
        ctx.clip()
        ctx.move(to: CGPoint(x: centre.x - 2 * r, y: centre.y - 2 * r))
        ctx.addLine(to: CGPoint(x: centre.x + 2 * r, y: centre.y + 2 * r))
        ctx.addLine(to: CGPoint(x: centre.x + 2 * r, y: centre.y - 2 * r))
        ctx.closePath()
        ctx.fillPath()
        ctx.restoreGState()

        ctx.setLineWidth(1.4)
        ctx.strokeEllipse(in: face.insetBy(dx: 0.7, dy: 0.7))

        // Hands at 10:10, drawn as one layer and XORed in: solid on the day half, cut out of the
        // night half. (XORing each hand on its own would also cut out the spot where they cross.)
        ctx.setBlendMode(.xor)
        ctx.beginTransparencyLayer(auxiliaryInfo: nil)
        ctx.setBlendMode(.normal)
        ctx.setLineCap(.round)
        defer { ctx.endTransparencyLayer() }
        func hand(_ angle: CGFloat, _ length: CGFloat, _ width: CGFloat) {
            ctx.setLineWidth(width)
            ctx.move(to: centre)
            ctx.addLine(to: CGPoint(x: centre.x + sin(angle) * length, y: centre.y + cos(angle) * length))
            ctx.strokePath()
        }
        hand((10 + 10.0 / 60) / 12 * 2 * .pi, r * 0.50, 1.6)
        hand(10.0 / 60 * 2 * .pi, r * 0.72, 1.3)
        return true
    }
    image.isTemplate = true
    image.accessibilityDescription = "World Clock"
    return image
}

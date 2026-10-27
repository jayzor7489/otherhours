import Foundation
import Testing
@testable import WorldClockCore

/// WCAG relative luminance of an sRGB colour given as 0xRRGGBB.
private func luminance(_ hex: UInt32) -> Double {
    func channel(_ shift: UInt32) -> Double {
        let c = Double((hex >> shift) & 0xFF) / 255
        return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0)
}

private func contrastWithWhite(_ hex: UInt32) -> Double { 1.05 / (luminance(hex) + 0.05) }

/// The time sits on the bar's right-hand end, so every stop must keep white text readable
/// (3:1, the large-text level; times are 18-20 pt medium). Review finding: day/dusk were ~1.8:1.
@Test func whiteTextIsReadableOnEveryBandStop() {
    for band in SkyBand.allCases {
        let (leading, trailing) = band.gradientHex
        #expect(contrastWithWhite(leading) >= 3.0, "\(band) leading \(String(leading, radix: 16))")
        #expect(contrastWithWhite(trailing) >= 3.0, "\(band) trailing \(String(trailing, radix: 16))")
    }
}

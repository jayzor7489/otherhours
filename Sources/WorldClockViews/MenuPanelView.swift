import SwiftUI
import WorldClockCore

/// The menu bar panel: the widget's rows, all full size and never "+N more", ticking each
/// minute while it is open. Long lists scroll.
public struct MenuPanelView: View {
    static let rowHeight: CGFloat = 52
    static let rowsBeforeScrolling = 8

    let rows: [ClockRow]
    let userZone: TimeZone
    let locale: Locale
    let hourCycle: HourCycle
    let theme: Theme
    let note: String
    @Binding var openAtLogin: Bool
    let onHowTo: () -> Void
    let onQuit: () -> Void
    let fixedDate: Date?

    /// `fixedDate` is for preview renders; the app leaves it nil to follow the clock.
    public init(rows: [ClockRow], userZone: TimeZone, locale: Locale, hourCycle: HourCycle, theme: Theme, note: String, openAtLogin: Binding<Bool>,
                onHowTo: @escaping () -> Void, onQuit: @escaping () -> Void, fixedDate: Date? = nil) {
        self.rows = rows
        self.userZone = userZone
        self.locale = locale
        self.hourCycle = hourCycle
        self.theme = theme
        self.note = note
        self._openAtLogin = openAtLogin
        self.onHowTo = onHowTo
        self.onQuit = onQuit
        self.fixedDate = fixedDate
    }

    public var body: some View {
        VStack(spacing: 10) {
            if theme == .clocks && rows.count > 9 {
                ScrollView { content }.frame(height: 3 * 120)  // 3 rows of faces, then scroll
            } else if theme != .clocks && rows.count > Self.rowsBeforeScrolling {
                ScrollView { content }
                    .frame(height: CGFloat(Self.rowsBeforeScrolling) * (Self.rowHeight + 6) - 6)
            } else {
                content
            }
            footer
        }
        .padding(10)
        .frame(width: 330)
        .foregroundStyle(theme.followsAppearance ? AnyShapeStyle(.primary) : AnyShapeStyle(.white))
        .background(MenuPanelView.background(theme))
        .environment(\.colorScheme, theme.followsAppearance ? colorScheme : .dark)
    }

    @Environment(\.colorScheme) private var colorScheme

    private static func background(_ theme: Theme) -> some View {
        AppearanceBackground(theme: theme)
    }

    @ViewBuilder private var content: some View {
        switch theme {
        case .dayNight: list
        case .clocks:
            TimelineView(.everyMinute) { context in
                ClocksThemeView(rows: rows, date: fixedDate ?? context.date, userZone: userZone, size: nil, monochrome: false,
                                locale: locale, emptyNote: "Add cities in Settings")
            }
            .padding(.vertical, 6)
        case .list:
            TimelineView(.everyMinute) { context in
                ListThemeView(rows: rows, date: fixedDate ?? context.date, userZone: userZone, size: nil, locale: locale,
                              hourCycle: hourCycle, emptyNote: "Add cities in Settings")
            }
        case .spotlight:
            TimelineView(.everyMinute) { context in
                SpotlightThemeView(rows: rows, date: fixedDate ?? context.date, userZone: userZone, size: nil, locale: locale,
                                   hourCycle: hourCycle, emptyNote: "Add cities in Settings")
            }
        }
    }

    private var list: some View {
        TimelineView(.everyMinute) { context in
            VStack(spacing: 6) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    AnyClockRow(row: row, date: fixedDate ?? context.date, userZone: userZone,
                                style: .full, monochrome: false, locale: locale, hourCycle: hourCycle)
                        .frame(height: Self.rowHeight)
                }
                if rows.count == 1 {
                    NoteRow(text: "Add cities in Settings", monochrome: false)
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Text(note).font(.system(size: 11)).opacity(0.6).lineLimit(2)
            Spacer(minLength: 4)
            Menu {
                Toggle("Open at Login", isOn: $openAtLogin)
                Button("How to Use", action: onHowTo)
                Divider()
                Button("Quit World Clock", action: onQuit)
            } label: {
                Image(systemName: "gearshape")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.horizontal, 4)
    }
}

/// The panel's card, reading the appearance it is drawn in.
private struct AppearanceBackground: View {
    let theme: Theme
    @Environment(\.colorScheme) private var colorScheme
    var body: some View { widgetBackground(theme: theme, colorScheme: colorScheme) }
}

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
    let note: String
    @Binding var openAtLogin: Bool
    let onHowTo: () -> Void
    let onQuit: () -> Void
    let fixedDate: Date?

    /// `fixedDate` is for preview renders; the app leaves it nil to follow the clock.
    public init(rows: [ClockRow], userZone: TimeZone, locale: Locale, hourCycle: HourCycle, note: String, openAtLogin: Binding<Bool>,
                onHowTo: @escaping () -> Void, onQuit: @escaping () -> Void, fixedDate: Date? = nil) {
        self.rows = rows
        self.userZone = userZone
        self.locale = locale
        self.hourCycle = hourCycle
        self.note = note
        self._openAtLogin = openAtLogin
        self.onHowTo = onHowTo
        self.onQuit = onQuit
        self.fixedDate = fixedDate
    }

    public var body: some View {
        VStack(spacing: 10) {
            if rows.count > Self.rowsBeforeScrolling {
                ScrollView { list }
                    .frame(height: CGFloat(Self.rowsBeforeScrolling) * (Self.rowHeight + 6) - 6)
            } else {
                list
            }
            footer
        }
        .padding(10)
        .frame(width: 330)
        .foregroundStyle(.white)
        .background(widgetBackground)
        .environment(\.colorScheme, .dark)
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

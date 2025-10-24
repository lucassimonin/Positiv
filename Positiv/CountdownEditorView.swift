import SwiftUI
import WidgetKit

struct CountdownEditorView: View {
    @State private var title: String = loadTitle()
    @State private var date: Date   = loadDate()

    var body: some View {
        Form {
            TextField("Event title", text: $title)
            DatePicker("Event date", selection: $date, displayedComponents: [.date, .hourAndMinute])
            Button("Save to widget") { save() }
        }
        .navigationTitle("Countdown")
    }

    private func save() {
        let ud = UserDefaults(suiteName: AppConfig.appGroup)!
        ud.set(title, forKey: AppConfig.Keys.countdownTitle)
        ud.set(date.timeIntervalSince1970, forKey: AppConfig.Keys.countdownDate)
        WidgetCenter.shared.reloadTimelines(ofKind: "EventCountdownWidget")
    }

    static func loadTitle() -> String {
        let ud = UserDefaults(suiteName: AppConfig.appGroup)
        return ud?.string(forKey: AppConfig.Keys.countdownTitle) ?? "Lancement BeHere"
    }
    static func loadDate() -> Date {
        let ud = UserDefaults(suiteName: AppConfig.appGroup)
        let t = ud?.double(forKey: AppConfig.Keys.countdownDate)
        return t.map(Date.init(timeIntervalSince1970:)) ?? Calendar.current.date(byAdding: .day, value: 30, to: .now)!
    }
}

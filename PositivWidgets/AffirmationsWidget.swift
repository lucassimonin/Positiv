import WidgetKit
import SwiftUI

struct AffirmationEntry: TimelineEntry {
    let date: Date
    let text: String
}

// MARK: - Provider
struct AffirmationProvider: TimelineProvider {
    func placeholder(in context: Context) -> AffirmationEntry {
        AffirmationEntry(date: .now, text: "Tu es capable de grandes choses ✨")
    }

    func getSnapshot(in context: Context, completion: @escaping (AffirmationEntry) -> Void) {
        completion(entryForNow())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AffirmationEntry>) -> Void) {
        var entries: [AffirmationEntry] = []
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        for i in 0..<7 {
            let day = cal.date(byAdding: .day, value: i, to: start)!
            entries.append(AffirmationEntry(date: day, text: pick(for: day)))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    // helpers
    private func entryForNow() -> AffirmationEntry {
        AffirmationEntry(date: .now, text: pick(for: Date()))
    }

    private func loadList() -> [String] {
        let ud = UserDefaults(suiteName: AppConfig.appGroup)
        // Nouveau format: [AffirmationItem]
        if let data = ud?.data(forKey: AppConfig.Keys.affirmations),
           let items = try? JSONDecoder().decode([AffirmationItem].self, from: data),
           !items.isEmpty {
            return items.map { $0.text }
        }
        // Ancien format: [String]
        if let arr = ud?.stringArray(forKey: AppConfig.Keys.affirmations), !arr.isEmpty {
            return arr
        }
        return ["Je progresse chaque jour ✨", "Je mérite le meilleur 💖"]
    }

    private func pick(for date: Date) -> String {
        let list = loadList(); guard !list.isEmpty else { return "…" }
        let idx = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return list[idx % list.count]
    }
}


struct AffirmationCardView: View {
    let entry: AffirmationEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AFFIRMATION DU JOUR")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)

            Text(entry.text)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
        // ✅ même fond que le countdown
        .containerBackground(for: .widget) {
            Rectangle().fill(.ultraThinMaterial)
        }
    }
}

struct LockScreenAffirmationView: View {
    let entry: AffirmationEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Affirmation du jour")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)

            Text(entry.text)
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            EmptyView() // fond système lock screen
        }
    }
}

struct AffirmationRootView: View {
    @Environment(\.widgetFamily) private var family
    let entry: AffirmationEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                LockScreenAffirmationView(entry: entry)
            default:
                AffirmationCardView(entry: entry)
            }
        }
    }
}

struct AffirmationsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: AppConfig.WidgetKind.affirmations,
                            provider: AffirmationProvider()) { entry in
            AffirmationRootView(entry: entry)
        }
        .configurationDisplayName("Affirmation positive")
        .description("Affiche une phrase motivante pour bien commencer la journée.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

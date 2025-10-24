import WidgetKit
import SwiftUI

let affirmationsKey = "affirmations"

struct AffirmationEntry: TimelineEntry {
    let date: Date
    let text: String
}

struct AffirmationsProvider: TimelineProvider {
    static let affirmations = [
        "Je progresse un peu chaque jour."
    ]

    func placeholder(in context: Context) -> AffirmationEntry {
        AffirmationEntry(date: .now, text: "Je suis serein·e et présent·e.")
    }

    func getSnapshot(in context: Context, completion: @escaping (AffirmationEntry) -> Void) {
        completion(AffirmationEntry(date: .now, text: Self.affirmations.randomElement() ?? "Je m’autorise à réussir."))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AffirmationEntry>) -> Void) {
        
        let now = Date()
        let ud  = UserDefaults(suiteName: AppConfig.appGroup)
        let list = ud?.stringArray(forKey: affirmationsKey) ?? Self.affirmations
        let text = list.randomElement() ?? "Je m’autorise à réussir."
        let entry = AffirmationEntry(date: .now, text: text)
        // Prochain refresh à minuit
        let cal = Calendar.current
        let nextMidnight = cal.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0, second: 0), matchingPolicy: .nextTime) ?? now.addingTimeInterval(86_400)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}

struct AffirmationsWidgetView: View {
    var entry: AffirmationEntry

    var body: some View {
        ZStack {
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Affirmation")
                    .font(.caption).bold().opacity(0.6)
                Text(entry.text)
                    .font(.headline)
                    .minimumScaleFactor(0.85)
                    .lineLimit(4)
            }
            
        }
    }
}

struct AffirmationsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AffirmationsWidget", provider: AffirmationsProvider()) { entry in
            // Adaptation minimaliste pour Lock Screen
            Link(destination: URL(string: "myapp://affirmations")!) {
                AffirmationsWidgetView(entry: entry)
            }
            
        }
        .configurationDisplayName("Affirmations (pastel)")
        .description("Une affirmation positive, renouvelée chaque jour.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

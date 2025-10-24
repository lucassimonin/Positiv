import WidgetKit
import SwiftUI

// MARK: - Entry
struct CountdownEntry: TimelineEntry {
    let date: Date          // instant d'affichage
    let title: String
    let eventDate: Date
}

// MARK: - Provider (lit depuis l’App Group)
struct CountdownProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(date: .now,
                       title: "🌴 Vacances d'été",
                       eventDate: Calendar.current.date(byAdding: .day, value: 42, to: .now)!)
    }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        completion(loadCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        let now = Date()
        let entry = loadCurrentEntry()
        var entries: [CountdownEntry] = []

        entries.append(entry) // maintenant

        let seconds = max(0, entry.eventDate.timeIntervalSince(now))
        let step: TimeInterval
        if seconds > 7 * 86_400 {        // > 7 jours : toutes les 3 h
            step = 3 * 3_600
        } else if seconds > 86_400 {     // 1–7 jours : toutes les 60 min
            step = 3_600
        } else {                         // < 24 h : toutes les 60 s
            step = 60
        }

        var t = now.addingTimeInterval(step)
        while t < entry.eventDate {
            entries.append(.init(date: t, title: entry.title, eventDate: entry.eventDate))
            t = t.addingTimeInterval(step)
        }
        entries.append(.init(date: entry.eventDate, title: entry.title, eventDate: entry.eventDate))

        completion(Timeline(entries: entries, policy: .atEnd))
    }

    // Lecture des valeurs partagées
    private func loadCurrentEntry() -> CountdownEntry {
        let ud = UserDefaults(suiteName: AppConfig.appGroup)
        let title = ud?.string(forKey: AppConfig.Keys.countdownTitle) ?? "🌴 Vacances d'été"
        let tEvent = ud?.double(forKey: AppConfig.Keys.countdownDate)
        let event = tEvent.map(Date.init(timeIntervalSince1970:))
            ?? Calendar.current.date(byAdding: .day, value: 42, to: .now)! // fallback

        return CountdownEntry(date: .now, title: title, eventDate: event)
    }
}

// MARK: - Vue (design de la capture)
struct CountdownCardView: View {
    let entry: CountdownEntry

    private let cardPink = Color(red: 1.00, green: 0.78, blue: 0.86)
    private let textPrimary = Color(red: 0.12, green: 0.16, blue: 0.22)
    private let textSecondary = Color.black.opacity(0.55)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: [cardPink, cardPink.opacity(0.92)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))

            HStack(alignment: .top, spacing: 10) {     // ⬅️ moins d’espace entre colonnes
                // Gauche
                VStack(alignment: .leading, spacing: 6) { // ⬅️ stack plus serré
                    Text("COMPTE À REBOURS")
                        .font(.caption2).bold()
                        .foregroundStyle(textSecondary)

                    Text(entry.title)
                        .font(.headline).bold()
                        .foregroundStyle(textPrimary)
                        .lineLimit(2)                    // ⬅️ autorise 2 lignes
                        .minimumScaleFactor(0.9)

                    Text(formatDate(entry.eventDate))
                        .font(.caption)
                        .foregroundStyle(textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Droite : J / h / min
                VStack(alignment: .trailing, spacing: 6) {
                    let c = componentsLeft(now: entry.date, to: entry.eventDate)
                    // Ligne 1 : JOURS gros
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(c.days)")
                            .font(.system(size: 42, weight: .heavy, design: .rounded)) // ⬅️ un poil plus petit
                            .monospacedDigit()
                        Text("JOURS")
                            .font(.caption2).bold()
                            .foregroundStyle(textSecondary)
                    }

                    // Ligne 2 : heures · minutes
                    HStack(spacing: 8) {
                        Label("\(c.hours)h", systemImage: "clock")
                            .labelStyle(.titleOnly)
                        Text("·")
                        Text("\(c.minutes)min")
                    }
                    .font(.caption2)
                    .foregroundStyle(textSecondary)
                }
                .frame(minWidth: 108, alignment: .trailing) // ⬅️ colonne droite un peu plus fine
            }
            .padding(.horizontal, 14)  // ⬅️ padding latéral réduit
            .padding(.vertical, 2)    // ⬅️ padding vertical réduit
        }
    }

    // Helpers
    private func componentsLeft(now: Date, to target: Date) -> (days: Int, hours: Int, minutes: Int) {
        let cal = Calendar.current
        // Jours calculés à J minuit pour éviter les off-by-one
        let d = max(0, cal.dateComponents([.day], from: cal.startOfDay(for: now),
                                          to: cal.startOfDay(for: target)).day ?? 0)

        // Heures/min restant dans la journée courante vers la cible
        let comps = cal.dateComponents([.hour, .minute], from: now, to: target)
        let h = max(0, comps.hour ?? 0) % 24
        let m = max(0, comps.minute ?? 0) % 60
        return (d, h, m)
    }

    private func formatDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "d MMMM yyyy"
        return f.string(from: d)
    }
}


// MARK: - Widget
struct EventCountdownWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: AppConfig.WidgetKind.countdown, provider: CountdownProvider()) { entry in
            // Si tu veux ouvrir l'app au tap, entoure par un Link(…)
            CountdownCardView(entry: entry)
        }
        .configurationDisplayName("Compte à rebours")
        .description("Affiche le titre, la date et les jours restants.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()                  // iOS 17+ : pas de marges
    }
}

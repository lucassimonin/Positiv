import WidgetKit
import SwiftUI

// MARK: - Entry
struct CountdownEntry: TimelineEntry {
    let date: Date          // instant d'affichage
    let title: String
    let eventDate: Date
}

fileprivate func componentsLeft(now: Date, to target: Date) -> (days: Int, hours: Int, minutes: Int) {
    let cal = Calendar.current
    let d = max(0, cal.dateComponents([.day], from: cal.startOfDay(for: now),
                                      to: cal.startOfDay(for: target)).day ?? 0)
    let comps = cal.dateComponents([.hour, .minute], from: now, to: target)
    let h = max(0, comps.hour ?? 0) % 24
    let m = max(0, comps.minute ?? 0) % 60
    return (d, h, m)
}

fileprivate func formatDate(_ d: Date) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "fr_FR")
    f.dateFormat = "d MMMM yyyy"
    return f.string(from: d)
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

struct LockScreenCountdownView: View {
    let entry: CountdownEntry

    var body: some View {
        let c = componentsLeft(now: entry.date, to: entry.eventDate)

        VStack(alignment: .leading, spacing: 2) {
            // Titre
            Text(entry.title)
                .font(.caption2).bold()
                .lineLimit(1)

            // Date
            Text(formatDate(entry.eventDate))
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Ligne jours + heures/min
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                HStack(spacing: 3) {
                    Text("\(c.days)")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                    Text("j").font(.caption2).bold()
                }

                Spacer(minLength: 6)

                HStack(spacing: 6) {
                    Text("\(c.hours)h")
                    Text("·")
                    Text("\(c.minutes)min")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .containerBackground(for: .widget) {
                    EmptyView()  // fond géré par le système (verre lock screen)
                }
    }
}

// MARK: - Vue (design de la capture)
struct CountdownCardView: View {
    let entry: CountdownEntry

    
    private let textPrimary   = Color.black.opacity(0.85)
    private let textSecondary = Color.black.opacity(0.55)

    var body: some View {
            HStack(alignment: .top, spacing: 10) {
                // Gauche
                VStack(alignment: .leading, spacing: 6) {
                    Text("COMPTE À REBOURS").font(.caption2).bold().foregroundStyle(.secondary)
                    Text(entry.title).font(.headline).bold().foregroundStyle(.primary)
                    Text(formatDate(entry.eventDate)).font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Droite centrée
                VStack(alignment: .center, spacing: 6) {
                    let c = componentsLeft(now: entry.date, to: entry.eventDate)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(c.days)")
                            .font(.system(size: 44, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                        Text("JOURS")
                            .font(.caption2).bold()
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 8) {
                        Text("\(c.hours)h"); Text("·"); Text("\(c.minutes)min")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                }
                .frame(minWidth: 108, alignment: .center)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
}


// MARK: - Widget

struct EventCountdownWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: AppConfig.WidgetKind.countdown,
                            provider: CountdownProvider()) { entry in
            CountdownRootView(entry: entry)
        }
        .configurationDisplayName("Compte à rebours")
        .description("Affiche le titre, la date et les jours restants.")
        .supportedFamilies([.systemMedium, .accessoryRectangular])   // ⬅️ Lock Screen
        .contentMarginsDisabled()
    }
}


struct CountdownRootView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CountdownEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            LockScreenCountdownView(entry: entry)
        default:
            // Home Screen (ta vue existante)
            CountdownCardView(entry: entry)
                .containerBackground(for: .widget) {    // verre système
                    Rectangle().fill(.ultraThinMaterial)
                }
        }
    }
}

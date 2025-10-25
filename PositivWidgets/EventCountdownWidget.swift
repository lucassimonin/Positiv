import WidgetKit
import SwiftUI

// MARK: - Entry
struct CountdownEntry: TimelineEntry {
    let date: Date          // instant d'affichage
    let title: String
    let eventDate: Date
}

fileprivate func componentsLeft(now rawNow: Date, to target: Date, rounding: Bool = false)
-> (days: Int, hours: Int, minutes: Int, seconds: Int)
{
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = .current // timezone du téléphone

    // Option A: arrondir l’affichage à la minute (si rounding = true)
    let now: Date
    if rounding {
        // Arrondi à la minute la plus proche
        let s = cal.component(.second, from: rawNow)
        let adjust = s >= 30 ? 60 - s : -s
        now = rawNow.addingTimeInterval(TimeInterval(adjust))
    } else {
        // Option B: tronquer à la minute (supprimer les secondes)
        now = cal.date(bySetting: .second, value: 0, of: rawNow) ?? rawNow
    }

    // Calcul direct des composantes (DST-safe)
    let comps = cal.dateComponents([.day, .hour, .minute, .second], from: now, to: target)

    // Normalisation (évite les négatifs)
    let d = max(0, comps.day ?? 0)
    let h = max(0, comps.hour ?? 0)
    let m = max(0, comps.minute ?? 0)
    let s = max(0, comps.second ?? 0)

    return (d, h, m, s)
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
        } else {                         // < 24 h : toutes les 30 s
            step = 30
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
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                HStack(spacing: 3) {
                    Text("\(c.days)")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                    Text("j").font(.caption2).bold()
                    Text("")
                }

            
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
                VStack(alignment: .center, spacing: 4) {
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
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(c.hours)h"); Text("·"); Text("\(c.minutes)min"); Text("·"); Text("\(c.seconds)sec")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                }
                .frame(minWidth: 150, alignment: .center)
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

import WidgetKit
import SwiftUI
import UIKit

// MARK: - Entry
struct CountdownEntry: TimelineEntry {
    let date: Date
    let title: String
    let eventDate: Date
    let emoji: String
    let isLocked: Bool
}

// MARK: - Provider
struct CountdownProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(date: .now, title: String(localized: "hub_unknown"), eventDate: Date().addingTimeInterval(86400*10), emoji: "🌴", isLocked: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        completion(CountdownEntry(date: .now, title: String(localized: "hub_unknown"), eventDate: Date().addingTimeInterval(86400*10), emoji: "🌴", isLocked: false))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        // 🔒 VÉRIFICATION SPÉCIFIQUE
        let ud = UserDefaults(suiteName: AppConfig.appGroup) ?? UserDefaults.standard
        // On vérifie UNIQUEMENT la clé du Countdown
        let isPremium = ud.bool(forKey: "isCountdownPremium")
        
        let entry = loadCurrentEntry(locked: !isPremium)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadCurrentEntry(locked: Bool) -> CountdownEntry {
        let ud = UserDefaults(suiteName: AppConfig.appGroup)
        let title = ud?.string(forKey: AppConfig.Keys.countdownTitle) ?? "countdown_event"
        let tEvent = ud?.double(forKey: AppConfig.Keys.countdownDate) ?? 0
        let emojiRaw = ud?.string(forKey: AppConfig.Keys.countdownEmoji) ?? "🗓️"
        let emoji = emojiRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "🗓️" : emojiRaw
        let eventDate = tEvent > 0 ? Date(timeIntervalSince1970: tEvent) : Date().addingTimeInterval(86400*7)
        return CountdownEntry(date: .now, title: title, eventDate: eventDate, emoji: emoji, isLocked: locked)
    }
}

// MARK: - Helpers
fileprivate func componentsLeft(now: Date, to target: Date) -> (days: Int, hours: Int, minutes: Int) {
    let cal = Calendar.current
    let comps = cal.dateComponents([.day, .hour, .minute], from: now, to: target)
    return (max(0, comps.day ?? 0), max(0, comps.hour ?? 0), max(0, comps.minute ?? 0))
}

fileprivate func formatDate(_ d: Date) -> String {
    let f = DateFormatter(); f.locale = Locale(identifier: "fr_FR"); f.dateFormat = "d MMM yyyy"
    return f.string(from: d)
}

// MARK: - Vue du Widget
struct CountdownCardView: View {
    let entry: CountdownEntry
    @Environment(\.widgetFamily) var family
    @Environment(\.widgetRenderingMode) var renderingMode

    var body: some View {
        let c = componentsLeft(now: entry.date, to: entry.eventDate)
        let textColor: Color = (renderingMode == .fullColor) ? .white : .primary
        
        HStack(spacing: 0) {
            
            // ------------------------------------------------
            // PARTIE GAUCHE : TITRE + EMOJI DE FOND (Inchangé)
            // ------------------------------------------------
            ZStack(alignment: .leading) {
                
                // 1. L'EMOJI DE FOND
                GeometryReader { geo in
                    if let bgImage = entry.emoji.toImage(fontSize: 120) {
                        Image(uiImage: bgImage)
                            .resizable()
                            .widgetAccentedRenderingMode(.fullColor)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 130, height: 130)
                            
                            .widgetAccentable(false)
                            .opacity(0.15)
                            .position(x: 50, y: geo.size.height / 2)
                    }
                }
                
                // 2. LE TITRE
                VStack(alignment: .leading) {
                    Spacer()
                    Text(entry.title.uppercased())
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .lineLimit(3)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(textColor)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // ------------------------------------------------
            // PARTIE DROITE : DONNÉES
            // ------------------------------------------------
            VStack(alignment: .trailing, spacing: 0) {
                
                // A. La Date (MONTÉE EN HAUT)
                Text(formatDate(entry.eventDate).uppercased())
                    .font(.caption2.bold())
                    .foregroundStyle(textColor.opacity(0.8))
                    .padding(.bottom, 2) // Un peu d'espace sous la date
                
                Spacer()
                
                // B. Le Groupe Compteur + Jours
                VStack(alignment: .trailing, spacing: -6) { // Spacing négatif pour coller
                    
                    // Le Gros Chiffre
                    Text("\(c.days)")
                        .font(.system(size: 54, weight: .black, design: .rounded))
                        .foregroundStyle(textColor)
                        .contentTransition(.numericText())
                        .shadow(color: renderingMode == .fullColor ? .black.opacity(0.2) : .clear, radius: 4, x: 0, y: 4)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    // Le Label "JOURS" (PLUS PETIT & PROCHE)
                    Text(String(localized: "countdown_days_label").uppercased())
                        .font(.system(size: 11, weight: .bold, design: .rounded)) // Réduit à 11
                        .foregroundStyle(textColor.opacity(0.9))
                }
                
                
                // C. L'heure (En bas)
                Text("\(c.hours)h \(c.minutes)min \(String(localized: "countdown_remaining"))")
                    .font(.caption2)
                    .foregroundStyle(textColor.opacity(0.6))
                Spacer()
                Spacer()
            }
            .frame(width: 130) // Largeur fixe colonne de droite
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            if renderingMode == .fullColor {
                LinearGradient(colors: [Color.orange, Color.red], startPoint: .topLeading, endPoint: .bottomTrailing)
            } else {
                Color.clear
            }
        }
        .widgetURL(URL(string: "prism://countdown"))
    }
}

// MARK: - Main Widget
struct EventCountdownWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: AppConfig.WidgetKind.countdown, provider: CountdownProvider()) { entry in
            CountdownRootView(entry: entry)
        }
        .configurationDisplayName("countdown_widget_name")
        .description("countdown_widget_description")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

struct CountdownRootView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CountdownEntry

    var body: some View {
        // 🔒 3. Le Switch de sécurité
        if entry.isLocked {
            LockedView() // On affiche le cadenas
        } else {
            // On affiche le vrai contenu
            if family == .accessoryRectangular {
                Text("\(entry.emoji) \(entry.title)")
            } else if family == .systemMedium {
                CountdownCardView(entry: entry)
            }
        }
    }
}

// MARK: - Extension Image
extension String {
    func toImage(fontSize: CGFloat) -> UIImage? {
        let nsString = self as NSString
        let font = UIFont.systemFont(ofSize: fontSize)
        let attributes = [NSAttributedString.Key.font: font]
        let imageSize = nsString.size(withAttributes: attributes)
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        return renderer.image { _ in nsString.draw(at: .zero, withAttributes: attributes) }
    }
}

import WidgetKit
import SwiftUI

// MARK: - Entry
struct AffirmationEntry: TimelineEntry {
    let date: Date
    let text: String
    let isLocked: Bool
}

// MARK: - Provider
struct AffirmationProvider: TimelineProvider {
    func placeholder(in context: Context) -> AffirmationEntry {
        AffirmationEntry(date: .now, text: String(localized: "affimation_not_found"), isLocked: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (AffirmationEntry) -> Void) {
        completion(entryForNow(locked: false))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AffirmationEntry>) -> Void) {
        Task {
            // 👇 LE CHANGEMENT EST ICI : On appelle fetchCombined()
            let phrases = await AffirmationDataLoader.fetchCombined()
            
            // ... (Le reste de ta logique de sécurité Premium reste identique) ...
            let ud = UserDefaults(suiteName: AppConfig.appGroup) ?? UserDefaults.standard
            let isPremium = ud.bool(forKey: "isAffirmationPremium")
            let lockedStatus = !isPremium
            
            var entries: [AffirmationEntry] = []
            let cal = Calendar.current
            let start = cal.startOfDay(for: Date())
            
            for i in 0..<7 {
                if let day = cal.date(byAdding: .day, value: i, to: start) {
                    // On pioche dans la liste combinée
                    let index = Calendar.current.ordinality(of: .day, in: .era, for: day) ?? 0
                    // Le modulo (%) assure qu'on ne plante pas même si la liste est courte
                    let textOfTheDay = phrases[index % phrases.count]
                    
                    entries.append(AffirmationEntry(date: day, text: textOfTheDay, isLocked: lockedStatus))
                }
            }
            
            let nextUpdate = cal.date(byAdding: .hour, value: 4, to: .now)!
            completion(Timeline(entries: entries, policy: .after(nextUpdate)))
        }
    }

    // --- Helpers ---
    private func entryForNow(locked: Bool) -> AffirmationEntry {
        AffirmationEntry(date: .now, text: pick(for: Date()), isLocked: locked)
    }

    private func loadList() -> [String] {
        let ud = UserDefaults(suiteName: AppConfig.appGroup)
        
        if let data = ud?.data(forKey: AppConfig.Keys.affirmations),
           let items = try? JSONDecoder().decode([AffirmationItem].self, from: data),
           !items.isEmpty {
            return items.map { $0.text }
        }
        
        if let arr = ud?.stringArray(forKey: AppConfig.Keys.affirmations), !arr.isEmpty {
            return arr
        }
        
        return [String(localized: "affimation_not_found")]
    }

    private func pick(for date: Date) -> String {
        let list = loadList()
        guard !list.isEmpty else { return "..." }
        let idx = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return list[idx % list.count]
    }
}

// MARK: - Vue du Widget
struct AffirmationCardView: View {
    let entry: AffirmationEntry
    @Environment(\.widgetRenderingMode) var renderingMode

    // ✨ MAGIE ICI : Calcul de la taille selon la longueur
    var dynamicFontSize: CGFloat {
        let count = entry.text.count
        switch count {
        case 0..<30: return 32  // Très court : Très gros
        case 30..<80: return 24 // Moyen : Normal
        default: return 18      // Long : Petit
        }
    }

    var body: some View {
        let textColor: Color = (renderingMode == .fullColor) ? .white : .primary
        
        VStack(alignment: .leading, spacing: 0) {
            
            // 1. EN-TÊTE
            HStack(spacing: 6) {
                Text("affirmation_widget_title")
                    .font(.system(size: 7, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(1)
            }
            .foregroundStyle(textColor.opacity(0.7))
            .padding(.bottom, 12)
            
            // 2. LE TEXTE
            Text(entry.text)
                // 👇 On utilise la variable dynamicFontSize ici
                .font(.system(size: dynamicFontSize, weight: .thin, design: .serif))
                .italic()
                .foregroundStyle(textColor)
                .lineSpacing(1)
                .lineLimit(6) // J'ai augmenté un peu la limite de lignes
                .minimumScaleFactor(0.6) // Autorise à réduire encore un peu si vraiment trop long
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            if renderingMode == .fullColor {
                LinearGradient(
                    colors: [Color.purple, Color.blue.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color.clear
            }
        }
        .widgetURL(URL(string: "prism://positiv"))
    }
}

// MARK: - Lock Screen
struct LockScreenAffirmationView: View {
    let entry: AffirmationEntry
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.text)
                .font(.caption)
                .lineLimit(2)
        }
        .containerBackground(for: .widget) { EmptyView() }
        .widgetURL(URL(string: "prism://positiv"))
    }
}

// MARK: - Root View (Switch Sécurité)
struct AffirmationRootView: View {
    @Environment(\.widgetFamily) private var family
    let entry: AffirmationEntry

    var body: some View {
        // 🔒 SÉCURITÉ
        if entry.isLocked {
            LockedView() // On affiche le cadenas
        } else {
            // Contenu normal
            if family == .accessoryRectangular {
                LockScreenAffirmationView(entry: entry)
            } else {
                AffirmationCardView(entry: entry)
            }
        }
    }
}

// MARK: - Main Widget
struct AffirmationsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: AppConfig.WidgetKind.affirmations,
                            provider: AffirmationProvider()) { entry in
            AffirmationRootView(entry: entry)
        }
        .configurationDisplayName("affirmation_widget_name")
        .description("affirmation_widget_description")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

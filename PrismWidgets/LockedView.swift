import SwiftUI
import WidgetKit

struct LockedView: View {
    var body: some View {
        // Pas de ZStack ici, juste le contenu vertical
        VStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 24))
                .foregroundStyle(.orange)
                .padding(10)
                .background(.white.opacity(0.1))
                .clipShape(Circle())
            
            Text("lock_premium")
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
        // ✅ C'EST ICI LA RÉPARATION MAGIQUE :
        // On définit le fond noir via l'API officielle d'Apple
        .containerBackground(for: .widget) {
            Color.black.opacity(0.9)
        }
        // Redirection vers la boutique
        .widgetURL(URL(string: "prism://shop"))
    }
}

// Extension pour vérifier le paiement (inchangée)
extension UserDefaults {
    static var isPremium: Bool {
        return UserDefaults(suiteName: AppConfig.appGroup)?.bool(forKey: "isPremium") ?? false
    }
}

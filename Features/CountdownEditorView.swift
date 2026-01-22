import SwiftUI
import WidgetKit

struct CountdownEditorView: View {
    @State private var title: String = loadTitle()
    @State private var date: Date = loadDate()
    @State private var emoji: String = loadEmoji()
    
    @State private var isSaving = false
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            // FOND D'ÉCRAN GLOBAL
            Color.black.ignoresSafeArea()
            
            VStack() {
                
                // ====================================================
                // 1. LA NOUVELLE PRÉVISUALISATION (Copie conforme du Widget)
                // ====================================================
                VStack(spacing: 10) {
                    Text(String(localized: "countdown_preview").uppercased())
                        .font(.caption2).fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.5))
                    
                    // --- CARTE WIDGET ---
                    HStack(spacing: 0) {
                        
                        // PARTIE GAUCHE : TITRE + EMOJI FOND
                        ZStack(alignment: .leading) {
                            // Emoji Fond
                            if let bgImage = emoji.toImagePreview(fontSize: 90) {
                                Image(uiImage: bgImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 90, height: 90)
                                    .opacity(0.15) // Effet discret
                                    .position(x: 40, y: 75) // Position ajustée pour la preview
                            }
                            
                            // Titre
                            VStack(alignment: .leading) {
                                Spacer()
                                Text(title.isEmpty ? "countdown_title".uppercased() : title.uppercased())
                                    .font(.system(size: 26, weight: .black, design: .rounded))
                                    .lineLimit(3)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // PARTIE DROITE : DONNÉES
                        VStack(alignment: .trailing, spacing: 0) {
                            
                            // Date (Haut)
                            Text(date.formatted(.dateTime.day().month().year()).uppercased())
                                .font(.caption2.bold())
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.bottom, 2)
                            
                            Spacer()
                            
                            // Compteur
                            VStack(alignment: .trailing, spacing: -6) {
                                Text(daysRemaining)
                                    .font(.system(size: 54, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text(String(localized: "countdown_days_label").uppercased())
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            Spacer()
                            
                            // Heure (Bas)
                            Text("hub_unknown")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .frame(width: 130)
                    }
                    // --- FIN CARTE WIDGET ---
                    .padding(16)
                    .frame(height: 160) // Hauteur fixe d'un widget medium
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                    .shadow(color: .orange.opacity(0.3), radius: 20, x: 0, y: 10)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // ====================================================
                // 2. FORMULAIRE
                // ====================================================
                VStack(spacing: 20) {
                    
                    // CHOIX EMOJI
                    HStack {
                        Text("countdown_emoji")
                            .font(.headline).foregroundColor(.white)
                        Spacer()
                        TextField("😃", text: $emoji)
                            .font(.system(size: 40))
                            .multilineTextAlignment(.center)
                            .frame(width: 60, height: 60)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                            .onChange(of: emoji) { _, newValue in
                                if newValue.count > 1 { emoji = String(newValue.prefix(1)) }
                            }
                    }
                    .padding(.horizontal, 10)

                    // TITRE
                    TextField("countdown_title", text: $title)
                        .focused($isFocused)
                        .padding()
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                    
                    // DATE
                    DatePicker("countdown_date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .padding()
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                        .colorScheme(.dark)
                }
                .padding(.horizontal, 30)
                
                // BOUTON SAUVEGARDER
                Button(action: save) {
                    HStack {
                        if isSaving { ProgressView().tint(.white) }
                        Text(isSaving ? "countdown_updated" : "countdown_validate")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .clipShape(Capsule())
                    .shadow(radius: 5)
                }
                .padding(30)
                .disabled(isSaving)
            }
        }
        .navigationTitle("countdown_widget_name")
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture { isFocused = false }
    }

    // --- LOGIQUE ---

    var daysRemaining: String {
        let components = Calendar.current.dateComponents([.day], from: Date(), to: date)
        return "\(max(0, components.day ?? 0))"
    }

    private func save() {
        isFocused = false
        withAnimation { isSaving = true }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let ud = UserDefaults(suiteName: AppConfig.appGroup)!
            ud.set(title, forKey: AppConfig.Keys.countdownTitle)
            ud.set(date.timeIntervalSince1970, forKey: AppConfig.Keys.countdownDate)
            ud.set(emoji, forKey: AppConfig.Keys.countdownEmoji)
            
            WidgetCenter.shared.reloadTimelines(ofKind: AppConfig.WidgetKind.countdown)
            withAnimation { isSaving = false }
        }
    }

    // Chargeurs
    static func loadTitle() -> String { UserDefaults(suiteName: AppConfig.appGroup)?.string(forKey: AppConfig.Keys.countdownTitle) ?? "" }
    static func loadDate() -> Date {
        let t = UserDefaults(suiteName: AppConfig.appGroup)?.double(forKey: AppConfig.Keys.countdownDate) ?? 0
        return t > 0 ? Date(timeIntervalSince1970: t) : Date().addingTimeInterval(86400 * 30)
    }
    static func loadEmoji() -> String { UserDefaults(suiteName: AppConfig.appGroup)?.string(forKey: AppConfig.Keys.countdownEmoji) ?? "🗓️" }
}

// Petite extension locale pour la preview (copie de celle du widget)
extension String {
    func toImagePreview(fontSize: CGFloat) -> UIImage? {
        let nsString = self as NSString
        let font = UIFont.systemFont(ofSize: fontSize)
        let attributes = [NSAttributedString.Key.font: font]
        let imageSize = nsString.size(withAttributes: attributes)
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        return renderer.image { _ in nsString.draw(at: .zero, withAttributes: attributes) }
    }
}

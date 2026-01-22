import SwiftUI
import WidgetKit // 👈 1. IMPORT OBLIGATOIRE

struct HubView: View {
    @EnvironmentObject var storeManager: StoreManager
    
    // Une grille avec un peu plus d'espace
    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // 1. Fond d'écran global (Noir très doux)
                Color(red: 0.1, green: 0.1, blue: 0.12)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        
                        // 2. En-tête stylisé
                        VStack(alignment: .leading, spacing: 5) {
                            Text("hub_app_name")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                
                            Text("hub_my_apps")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // 3. La Grille
                        LazyVGrid(columns: columns, spacing: 20) {
                            ModuleCard(
                                module: .countdown,
                                isUnlocked: storeManager.isCountdownUnlocked,
                                color: Color.orange
                            )
                            
                            ModuleCard(
                                module: .affirmation,
                                isUnlocked: storeManager.isAffirmationUnlocked,
                                color: Color.purple
                            )
                            
                            ModuleCard(
                                module: .art,
                                isUnlocked: storeManager.isArtUnlocked,
                                color: Color.pink
                            )
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct ModuleCard: View {
    let module: ModuleType
    let isUnlocked: Bool
    let color: Color
    @EnvironmentObject var storeManager: StoreManager
    
    // État pour afficher ou non la fenêtre de paiement
    @State private var showPaymentAlert = false
    
    var body: some View {
        VStack(alignment: .leading) {
            // Icône et Header
            HStack {
                Image(systemName: module.iconName)
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                Spacer()
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption)
                }
            }
            .padding(.bottom, 10)
            
            Spacer()
            
            // Titre
            VStack(alignment: .leading, spacing: 2) {
                Text(module.localizedName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(module.subtitle)
                    .font(.system(size: 10, weight: .thin, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Bouton d'action
            if isUnlocked {
                // CAS 1 : C'est payé -> On ouvre l'app
                NavigationLink(destination: destinationView()) {
                    Text("hub_open")
                        .font(.caption2).fontWeight(.bold)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(20)
                        .foregroundColor(.white)
                }
                .padding(.top, 10)
            } else {
                // CAS 2 : Pas payé -> On propose l'achat
                Button(action: {
                    // Au lieu d'acheter tout de suite, on demande confirmation
                    showPaymentAlert = true
                }) {
                    Text(module.price)
                        .font(.caption2).fontWeight(.bold)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(20)
                        .foregroundColor(.white)
                }
                .padding(.top, 10)
                // Voici la fausse fenêtre de paiement Apple
                .alert("hub_popup_title", isPresented: $showPaymentAlert) {
                    Button("hub_popup_cancel", role: .cancel) { }
                    Button("hub_popup_confirm") {
                        // 1. Débloque dans l'App (StoreManager)
                        storeManager.purchase(module: module)
                        print(module)
                        // 2. SAUVEGARDE SPÉCIFIQUE (C'est ici qu'on sépare !)
                        // On choisit la clé en fonction du module
                        let key: String
                        switch module {
                        case .countdown: key = "isCountdownPremium"
                        case .affirmation: key = "isAffirmationPremium"
                        case .art: key = "isArtPremium"
                        }
                        
                        // On enregistre "true" pour CETTE clé seulement
                        // (Si tu as remis les App Groups, remets suiteName, sinon garde standard)
                        if let ud = UserDefaults(suiteName: AppConfig.appGroup) {
                            ud.set(true, forKey: key)
                            ud.synchronize()
                        } else {
                            // Fallback si pas d'App Group
                            UserDefaults.standard.set(true, forKey: key)
                        }
                        
                        if module == .art {
                            // On lance une tâche asynchrone pour télécharger l'image
                            Task {
                                // On vérifie s'il y a déjà une image, sinon on en charge une
                                if ArtCache.load() == nil {
                                    await ArtFetcher.fetchAndCache()
                                }
                                // Une fois fini, on recharge les widgets
                                WidgetCenter.shared.reloadAllTimelines()
                            }
                        } else {
                            // Pour les autres widgets (Countdown, Affirmation), pas besoin d'attendre
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                    }
                } message: {
                    Text("shop_unlock_desc \(module.localizedName)")
                }
            }
        }
        .padding(20)
        .frame(height: 180)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [color.opacity(0.8), color.opacity(0.5)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(25)
        .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    @ViewBuilder
    func destinationView() -> some View {
        switch module {
        case .affirmation:
            if #available(iOS 15.0, *) {
                AffirmationsEditorView()
            } else {
                Text("hub_update_ios")
            }
        case .art:
            if #available(iOS 15.0, *) {
                ArtEditorView()
            } else {
                Text("hub_update_ios")
            }
        case .countdown:
            if #available(iOS 15.0, *) {
                CountdownEditorView()
            } else {
                Text("hub_update_ios")
            }
        }
    }
}

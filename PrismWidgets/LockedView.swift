// A mettre tout en bas du fichier, hors des autres structs
struct LockedView: View {
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color.black.opacity(0.8))
            
            VStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.orange)
                    .padding(12)
                    .background(.white.opacity(0.1))
                    .clipShape(Circle())
                
                Text("Premium requis")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
        }
        // Redirige vers la page d'achat de l'app
        .widgetURL(URL(string: "prism://shop")) 
    }
}

// Petite extension pour vérifier le Premium facilement
extension UserDefaults {
    static var isPremium: Bool {
        // Remplace "isPremium" par la clé exacte que tu utilises dans ton StoreManager
        return UserDefaults(suiteName: AppConfig.appGroup)?.bool(forKey: "isPremium") ?? false
    }
}
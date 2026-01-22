import SwiftUI
import WidgetKit

struct ArtEditorView: View {
    @Environment(\.openURL) private var openURL
    
    // État de l'interface
    @State private var currentItem: ArtItem? = ArtCache.load()
    @State private var isLoading = false
    @State private var uiImage: UIImage? = nil
    
    var body: some View {
        ZStack {
            // 1. FOND D'ÉCRAN (L'œuvre floutée)
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .blur(radius: 30) // Flou plus fort pour bien détacher les textes
                    .overlay(Color.black.opacity(0.4)) // Assombrir pour le contraste
            } else {
                Color(red: 0.1, green: 0.1, blue: 0.15).ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                // 2. CADRE DE L'ŒUVRE
                ZStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                    } else if let uiImage = uiImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(16)
                            // Une ombre portée plus douce et diffuse
                            .shadow(color: .black.opacity(0.6), radius: 25, x: 0, y: 15)
                            .padding(.horizontal, 35)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else {
                        VStack(spacing: 15) {
                            Image(systemName: "paintpalette.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("art_no_works_uploaded")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(maxHeight: 450)
                
                Spacer()
                
                // 3. INFOS DE L'ŒUVRE (Titre et Artiste seulement ici)
                if let item = currentItem, !isLoading {
                    VStack(spacing: 6) {
                        Text(item.title)
                            .font(.title3).bold() // Un peu plus petit pour l'élégance
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                        
                        Text(item.artist ?? "Artiste inconnu")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        if let year = item.year {
                            Text(year)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20) // Un peu d'espace avant les boutons
                }
                
                // 4. LES DEUX BOUTONS (Regroupés en bas)
                HStack(spacing: 15) {
                                    
                    // A. Bouton Met (Plus petit)
                    if let item = currentItem, let url = URL(string: item.articleUrl) {
                        Button(action: { openURL(url) }) {
                            HStack(spacing: 6) {
                                Image(systemName: "building.columns.fill")
                                    .font(.system(size: 18))
                                Text("art_learn_more")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.white) // Texte blanc
                            .padding(.vertical, 14)
                            .padding(.horizontal, 24)
                            .background(.ultraThinMaterial) // Le même effet verre
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1) // Contour fin
                            )
                        }
                    }
                    
                    // B. Bouton Inspiration (Large et Élégant)
                    Button(action: loadNewArt) {
                        HStack(spacing: 10) {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            Text(isLoading ? "art_loading" : "art_new")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white) // Texte blanc
                        .padding(.vertical, 14)
                        .padding(.horizontal, 24)
                        .background(.ultraThinMaterial) // Le même effet verre
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1) // Contour fin
                        )
                    }
                    .disabled(isLoading)
                }
                .padding(.bottom, 30)    // Marge du bas
            }
        }
        .navigationTitle("art_widget_name")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Charge l'image locale existante
            loadImageFromDisk()
            
            // 👇 AJOUT : Si c'est vide (premier lancement), on en charge une nouvelle
            if currentItem == nil {
                loadNewArt()
            }
        }
    }
    
    // --- LOGIQUE (Identique à avant) ---
    private func loadImageFromDisk() {
        guard let item = currentItem, let path = item.localImagePath else { return }
        if let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let img = UIImage(data: data) {
            withAnimation { self.uiImage = img }
        }
    }
    
    private func loadNewArt() {
        withAnimation { isLoading = true }
        Task {
            await ArtFetcher.fetchAndCache()
            let newItem = ArtCache.load()
            await MainActor.run {
                withAnimation(.spring()) {
                    self.currentItem = newItem
                    self.loadImageFromDisk()
                    self.isLoading = false
                }
            }
        }
    }
}

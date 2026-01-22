import SwiftUI

@main
struct PrismApp: App {
    // On initialise le manager ici pour qu'il soit vivant dans toute l'app
    @StateObject var storeManager = StoreManager()
    
    var body: some Scene {
        WindowGroup {
            // Au lieu de ContentView, on lance le Hub
            HubView()
                .environmentObject(storeManager)
        }
    }
}

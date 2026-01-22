import SwiftUI

// Ce manager gère l'état "verrouillé/déverrouillé" des apps
class StoreManager: ObservableObject {
    @Published var isCountdownUnlocked: Bool = false
    @Published var isAffirmationUnlocked: Bool = false
    @Published var isArtUnlocked: Bool = false
    
    // Simule un achat pour l'instant
    func purchase(module: ModuleType) {
        withAnimation {
            switch module {
            case .countdown: isCountdownUnlocked = true
            case .affirmation: isAffirmationUnlocked = true
            case .art: isArtUnlocked = true
            }
        }
    }
}

enum ModuleType: String, CaseIterable {
    case countdown = "Countdown"
    case affirmation = "Positiv"
    case art = "Art Gallery"
    
    var iconName: String {
        switch self {
        case .countdown: return "timer"
        case .affirmation: return "quote.bubble"
        case .art: return "paintpalette"
        }
    }
    
    var price: String { return "0.99 €" }
}
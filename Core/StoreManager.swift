//
//  StoreManager.swift
//  Prism
//
//  Created by DnD-Luk on 21/01/2026.
//


import SwiftUI
import Combine

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
    case countdown = "countdown"
    case affirmation = "affirmation"
    case art = "art"
    
    var localizedName: String {
            switch self {
            case .countdown:
                return String(localized: "countdown_widget_name")
            case .affirmation:
                return String(localized: "affirmation_widget_name")
            case .art:
                return String(localized: "art_widget_name")
            }
        }
    
    var iconName: String {
        switch self {
        case .countdown: return "timer"
        case .affirmation: return "quote.bubble"
        case .art: return "paintpalette"
        }
    }
    
    var price: String { return "0.99 €" }
    
    var subtitle: String {
            switch self {
            case .countdown: return String(localized: "countdown_widget_description")
            case .affirmation: return String(localized: "affirmation_widget_description")
            case .art: return String(localized: "art_widget_description")
            }
        }
}

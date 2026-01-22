import Foundation
import WidgetKit

// 1. On définit les structures ici pour que le Widget les comprenne
// (Doit être identique à celle de ton App)

struct RemoteAffirmation: Codable {
    let text: String
}

struct AffirmationDataLoader {
    
    // 🌍 PARTIE DISTANTE (GitHub)
    static let jsonURL = URL(string: "https://gist.githubusercontent.com/lucassimonin/ff2f7f12336937ac7fc005f47bb3759b/raw/affirmations.json")!
    static let remoteCacheKey = "cached_affirmations_remote"
    
    // 🚀 FONCTION PRINCIPALE (Appelle ça depuis le Provider)
    static func fetchCombined() async -> [String] {
            
            // 👇 1. ON VÉRIFIE L'INTERRUPTEUR
            // On lit la même clé que dans la Vue ("includeRemoteAffirmations")
            // Si elle n'existe pas encore, on considère que c'est "true" par défaut.
            let includeRemote = UserDefaults.standard.object(forKey: "includeRemoteAffirmations") as? Bool ?? true
            
            // 👇 2. LOGIQUE CONDITIONNELLE
            let remotePhrases: [String]
            if includeRemote {
                // Si l'utilisateur veut le cloud, on charge !
                remotePhrases = await fetchRemote()
            } else {
                // Sinon, on renvoie une liste vide
                remotePhrases = []
            }
            
            // 3. On charge les phrases de l'utilisateur
            let userPhrases = fetchUserCustom()
            
            // 4. On fusionne
            let allPhrases = userPhrases + remotePhrases
            
            // 5. Nettoyage et mélange
            let uniquePhrases = Array(Set(allPhrases)).shuffled()
            
            // Petit message si l'utilisateur a tout désactivé et n'a rien écrit
            if uniquePhrases.isEmpty {
                return ["Ajoute une phrase pour commencer ! ✏️", "Active le cloud pour des idées 💡"]
            }
            
            return uniquePhrases
        }
    
    // --- LOGIQUE INTERNE ---
    
    static private func fetchRemote() async -> [String] {
        if let (data, _) = try? await URLSession.shared.data(from: jsonURL),
           let decoded = try? JSONDecoder().decode([RemoteAffirmation].self, from: data) {
            let phrases = decoded.map { $0.text }
            print(phrases)
            UserDefaults.standard.set(phrases, forKey: remoteCacheKey)
            return phrases
        }
        return UserDefaults.standard.stringArray(forKey: remoteCacheKey) ?? []
    }
    
    // 👇 C'EST ICI LA MAGIE POUR LIRE TON STORE
    static private func fetchUserCustom() -> [String] {
        // ⚠️ IMPORTANT : On essaie de lire exactement comme ton Store.
        // Si tu utilises AppConfig.appGroup dans le Store, on l'utilise ici aussi.
        // Si ça renvoie nil (car pas d'entitlement), on fallback sur standard.
        let ud = UserDefaults(suiteName: AppConfig.appGroup) ?? UserDefaults.standard
        
        // On utilise la même clé que dans AffirmationStore.swift
        // (Vérifie que AppConfig est bien accessible au Widget, sinon mets la string "affirmations" à la place)
        guard let data = ud.data(forKey: AppConfig.Keys.affirmations) else {
            return []
        }
        
        // On décode le JSON sauvegardé par l'App
        if let items = try? JSONDecoder().decode([AffirmationItem].self, from: data) {
            return items.map { $0.text }
        }
        
        return []
    }
}

import Foundation
import WidgetKit

struct RemoteAffirmation: Codable {
    let text: String
}

struct AffirmationDataLoader {
    // 1. Tes sources
    static let jsonURL = URL(string: "https://gist.githubusercontent.com/TON_LIEN_ICI/raw/affirmations.json")!
    static let remoteCacheKey = "cached_affirmations_remote"
    
    // 2. La fonction principale qui combine tout
    static func fetchCombined() async -> [String] {
        // A. On récupère les phrases de GitHub (ou du cache si pas internet)
        let remotePhrases = await fetchRemote()
        
        // B. On récupère les phrases ajoutées par l'utilisateur (Local)
        let userPhrases = fetchUserCustom()
        
        // C. On fusionne les deux
        // On met les phrases de l'utilisateur EN PREMIER (priorité)
        let allPhrases = userPhrases + remotePhrases
        
        // D. On nettoie (pas de doublons) et on mélange si tu veux
        let uniquePhrases = Array(Set(allPhrases)).shuffled()
        
        // Si vraiment vide (ni internet, ni user), phrase de secours
        if uniquePhrases.isEmpty {
            return ["Ajoute tes propres phrases ! ✏️", "Connecte-toi pour la mise à jour 📡"]
        }
        
        return uniquePhrases
    }
    
    // --- LOGIQUE INTERNE ---
    
    // Récupérer depuis GitHub
    static private func fetchRemote() async -> [String] {
        if let (data, _) = try? await URLSession.shared.data(from: jsonURL),
           let decoded = try? JSONDecoder().decode([RemoteAffirmation].self, from: data) {
            
            let phrases = decoded.map { $0.text }
            // On sauvegarde UNIQUEMENT la partie distante dans le cache distant
            UserDefaults.standard.set(phrases, forKey: remoteCacheKey)
            return phrases
        }
        
        // Si échec, on lit le cache distant
        return UserDefaults.standard.stringArray(forKey: remoteCacheKey) ?? []
    }
    
    // Récupérer depuis l'App (Ce que l'utilisateur a tapé)
    static private func fetchUserCustom() -> [String] {
        // ⚠️ Assure-toi que c'est bien la même clé que dans ton AffirmationsEditorView
        // Si tu as supprimé les App Groups, utilise standard, sinon suiteName
        let ud = UserDefaults(suiteName: AppConfig.appGroup) ?? UserDefaults.standard
        
        // Cas 1 : Si tu sauvegardes des objets complexes (AffirmationItem)
        if let data = ud.data(forKey: AppConfig.Keys.affirmations),
           let items = try? JSONDecoder().decode([AffirmationItem].self, from: data) {
            return items.map { $0.text }
        }
        
        // Cas 2 : Si tu sauvegardes juste un tableau de Strings
        if let arr = ud.stringArray(forKey: AppConfig.Keys.affirmations) {
            return arr
        }
        
        return []
    }
}
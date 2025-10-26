//
//  ArtIShared.swift
//  Positiv
//
//  Created by DnD-Luk on 25/10/2025.
//

import Foundation
import WidgetKit

// Modèle partagé App ↔︎ Widget
public struct ArtItem: Codable {
    public let title: String
    public let artist: String?
    public let year: String?
    public let articleUrl: String
    public let imageUrl: String              // URL distante (Met small)
    public let localImagePath: String?       // chemin absolu App Group (si présent)

    public init(title: String, artist: String?, year: String?,
                articleUrl: String, imageUrl: String, localImagePath: String? = nil) {
        self.title = title
        self.artist = artist
        self.year = year
        self.articleUrl = articleUrl
        self.imageUrl = imageUrl
        self.localImagePath = localImagePath
    }
}

// Cache UserDefaults (App Group)
public enum ArtCache {
    private static let suite = UserDefaults(suiteName: AppConfig.appGroup)!
    private static let key = "art_item_cache"

    public static func save(_ item: ArtItem) {
        do {
            let data = try JSONEncoder().encode(item)
            suite.set(data, forKey: key)
            suite.synchronize()
            print("💾 ArtCache saved:", item.title)
        } catch {
            print("⚠️ ArtCache save failed:", error)
        }
    }

    public static func load() -> ArtItem? {
        guard let data = suite.data(forKey: key) else { return nil }
        do { return try JSONDecoder().decode(ArtItem.self, from: data) }
        catch { print("⚠️ ArtCache load failed:", error); return nil }
    }

    public static func clear() {
        suite.removeObject(forKey: key)
        suite.synchronize()
        print("🧹 ArtCache cleared")

        // supprime aussi les fichiers d’image App Group
        if let dir = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppConfig.appGroup)?
            .appendingPathComponent("artwidget") {
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
                for f in contents { try? FileManager.default.removeItem(at: f); print("🗑️ Deleted:", f.lastPathComponent) }
            } catch { print("⚠️ clear files failed:", error.localizedDescription) }
        }
    }
}

public enum ArtWidgetAppearance: String, Codable {
    case auto       // blur + semi-opaque
    case transparent
    case opaque
}

public enum ArtPrefs {
    private static let suite = UserDefaults(suiteName: AppConfig.appGroup)!
    

    public static func setAppearance(_ value: ArtWidgetAppearance) {
        suite.set(value.rawValue, forKey: AppConfig.Keys.artAppearance)
    }

    public static func getAppearance() -> ArtWidgetAppearance {
        if let raw = suite.string(forKey: AppConfig.Keys.artAppearance), let v = ArtWidgetAppearance(rawValue: raw) {
            return v
        }
        return .auto
    }
}

func pushWidgetReloadSafely() async {
    await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
        WidgetCenter.shared.getCurrentConfigurations { result in
            if case .success(let widgets) = result, !widgets.isEmpty {
                WidgetCenter.shared.reloadAllTimelines()
                print("🔁 Widget timelines reloaded (\(widgets.count))")
            } else {
                print("ℹ️ Aucun widget installé, pas de reload.")
            }
            cont.resume()
        }
    }
}

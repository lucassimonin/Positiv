//
//  ArtWidget.swift
//  Prism
//
//  Created by DnD-Luk on 25/10/2025.
//

import WidgetKit
import SwiftUI

// MARK: - Entry
struct ArtEntry: TimelineEntry {
    let date: Date
    let item: ArtItem?
    let isLocked: Bool // 🔒 Ajouté
}

// MARK: - Provider
struct ArtProvider: TimelineProvider {
    func placeholder(in: Context) -> ArtEntry {
        ArtEntry(date: .now, item: nil, isLocked: false)
    }
    
    func getSnapshot(in: Context, completion: @escaping (ArtEntry)->Void) {
        // Snapshot toujours débloqué pour la galerie
        completion(ArtEntry(date: .now, item: ArtCache.load(), isLocked: false))
    }
    
    func getTimeline(in: Context, completion: @escaping (Timeline<ArtEntry>)->Void) {
        let ud = UserDefaults(suiteName: AppConfig.appGroup) ?? UserDefaults.standard
        // On vérifie UNIQUEMENT la clé Art
        let isPremium = ud.bool(forKey: "isArtPremium")
        
        let item = ArtCache.load()
        let next = Calendar.current.date(byAdding: .hour, value: 6, to: .now)!
        
        // On crée l'entrée avec le statut locked
        let entry = ArtEntry(date: .now, item: item, isLocked: !isPremium)
        
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Vue du contenu (Carte)
struct ArtCardView: View {
    let entry: ArtEntry

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                // IMAGE
                if let path = entry.item?.localImagePath,
                   FileManager.default.fileExists(atPath: path),
                   let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                   let uiimg = UIImage(data: data) {

                    Image(uiImage: uiimg)
                        .resizable()
                        .widgetAccentedRenderingMode(.fullColor)
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    Color.secondary.opacity(0.2)
                }

                // TEXTE + bandeau fin
                VStack(alignment: .leading, spacing: 2) {
                    Spacer(minLength: 0)

                    // Texte
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.item?.title ?? String(localized: "art_radom"))
                            .font(.footnote).fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .lineLimit(2).minimumScaleFactor(0.7)

                        HStack(spacing: 4) {
                            Text(entry.item?.artist ?? String(localized: "art_unknown_artist"))
                            if let y = entry.item?.year, !y.isEmpty { Text("· \(y)") }
                        }
                        .font(.caption2)
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .widgetAccentable(false)
        .containerBackground(Color.black.opacity(0.01), for: .widget)
        // Redirection vers l'app avec un signal "art"
        .widgetURL(URL(string: "prism://art"))
    }
}

// MARK: - Root View (Switch Sécurité)
struct ArtRootView: View {
    let entry: ArtEntry
    
    var body: some View {
        if entry.isLocked {
            LockedView() // 🔒 Le cadenas
        } else {
            ArtCardView(entry: entry) // Le contenu
        }
    }
}

// MARK: - Main Widget
struct ArtWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: AppConfig.WidgetKind.art, provider: ArtProvider()) { entry in
            ArtRootView(entry: entry)
        }
        .configurationDisplayName("art_widget_name")
        .description("art_widget_description")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

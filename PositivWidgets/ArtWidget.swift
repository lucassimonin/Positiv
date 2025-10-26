//
//  ArtWidget.swift
//  Positiv
//
//  Created by DnD-Luk on 25/10/2025.
//

import WidgetKit
import SwiftUI

struct ArtEntry: TimelineEntry { let date: Date; let item: ArtItem? }

struct ArtProvider: TimelineProvider {
    func placeholder(in: Context) -> ArtEntry { .init(date: .now, item: nil) }
    func getSnapshot(in: Context, completion: @escaping (ArtEntry)->Void) {
        completion(.init(date: .now, item: ArtCache.load()))
    }
    func getTimeline(in: Context, completion: @escaping (Timeline<ArtEntry>)->Void) {
        let item = ArtCache.load()
        let next = Calendar.current.date(byAdding: .hour, value: 6, to: .now)!
        completion(Timeline(entries: [.init(date: .now, item: item)], policy: .after(next)))
    }
}

struct ArtWidgetEntryView: View {
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
                        .frame(width: geo.size.width, height: geo.size.height) // 👈 pile la taille du widget
                        .clipped()
                } else {
                    Color.secondary.opacity(0.2)
                }

                // TEXTE + bandeau fin
                VStack(alignment: .leading, spacing: 2) {
                    Spacer(minLength: 0)

                    // Texte
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.item?.title ?? "Œuvre aléatoire")
                            .font(.footnote).fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .lineLimit(2).minimumScaleFactor(0.7)

                        HStack(spacing: 4) {
                            Text(entry.item?.artist ?? "Artiste inconnu")
                            if let y = entry.item?.year, !y.isEmpty { Text("· \(y)") }
                        }
                        .font(.caption2)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)                      // ← remonte/descend le bloc texte
                }
            }
            .frame(width: geo.size.width, height: geo.size.height) // 👈 colle tout à la taille
        }
        .widgetAccentable(false)
        .containerBackground(Color.black.opacity(0.01), for: .widget)            // host sans carte
        .widgetURL(URL(string: entry.item?.articleUrl ?? "https://www.metmuseum.org"))
    }
}


struct ArtWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ArtWidgetV2", provider: ArtProvider()) { entry in
            ArtWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Art aléatoire")
        .description("Une œuvre (The Met).")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

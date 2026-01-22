//
//  ArtFetcher.swift
//  Prism
//
//  Created by DnD-Luk on 25/10/2025.
//

import Foundation
import UIKit
import ImageIO
import WidgetKit

// ===== MET models =====
private struct MetObjectList: Decodable { let objectIDs: [Int]? }
private struct MetObject: Decodable {
    let objectID: Int
    let title: String
    let primaryImageSmall: String
    let objectDate: String
    let artistDisplayName: String
    let objectURL: String
}

enum ArtFetcher {

    // API The Met — une peinture aléatoire
    private static func fetchRandomFromMet() async throws -> ArtItem {
        // 1) Liste d'IDs (département Peintures = 11)
        let idsURL = URL(string: "https://collectionapi.metmuseum.org/public/collection/v1/objects?departmentIds=11")!
        let (idsData, _) = try await URLSession.shared.data(from: idsURL)
        let list = try JSONDecoder().decode(MetObjectList.self, from: idsData)
        guard let ids = list.objectIDs, let id = ids.randomElement() else {
            throw URLError(.badServerResponse)
        }

        // 2) Détail d'un objet
        let objURL = URL(string: "https://collectionapi.metmuseum.org/public/collection/v1/objects/\(id)")!
        let (data, _) = try await URLSession.shared.data(from: objURL)
        let o = try JSONDecoder().decode(MetObject.self, from: data)

        // 3) Map → ArtItem (image déjà "small")
        return ArtItem(
            title: o.title,
            artist: o.artistDisplayName.isEmpty ? nil : o.artistDisplayName,
            year: o.objectDate.isEmpty ? nil : o.objectDate,
            articleUrl: o.objectURL,
            imageUrl: o.primaryImageSmall
        )
    }

    // ===== Public: fetch + cache + image locale + reload widget =====
    static func fetchAndCache() async {
        print("fetchAndCache")
        do {
            var item = try await fetchRandomFromMet()
            // Télécharge + downsample + sauvegarde localement (≤ 1024 px)
            if let localPath = try await downloadAndSaveImage(item.imageUrl) {
                item = ArtItem(title: item.title,
                               artist: item.artist,
                               year: item.year,
                               articleUrl: item.articleUrl,
                               imageUrl: item.imageUrl,
                               localImagePath: localPath)
            }
            ArtCache.save(item)
            await pushWidgetReloadSafely()

        } catch {
            print("⚠️ fetch error:", error.localizedDescription)
        }
    }

    // ===== Files (App Group) =====
    private static func appGroupImageDir() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConfig.appGroup)?
            .appendingPathComponent("artwidget")
    }

    // Downsample efficace (évite "image too large" de WidgetKit)
    private static func downloadAndSaveImage(_ urlString: String) async throws -> String? {
        guard let url = URL(string: urlString), !urlString.isEmpty else { return nil }
        let (data, resp) = try await URLSession.shared.data(from: url)
        guard (resp as? HTTPURLResponse)?.statusCode == 200, !data.isEmpty else { return nil }

        // downsample max 1024 px
        let maxPixels: CGFloat = 1024
        guard let down = downsampledJPEGData(from: data, maxPixelSize: Int(maxPixels)) else { return nil }
        if let img = UIImage(data: down) {
            print("✅ Downsampled:", Int(img.size.width), "x", Int(img.size.height))
        }

        guard let dir = appGroupImageDir() else { return nil }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileURL = dir.appendingPathComponent("latest.jpg")
        try? FileManager.default.removeItem(at: fileURL)
        try down.write(to: fileURL, options: .atomic)
        return fileURL.path
    }

    private static func downsampledJPEGData(from data: Data, maxPixelSize: Int) -> Data? {
        let cfData = data as CFData
        guard let src = CGImageSourceCreateWithData(cfData, nil) else { return nil }
        let opts: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCache: false,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else { return nil }
        return UIImage(cgImage: cg).jpegData(compressionQuality: 0.85)
    }
}




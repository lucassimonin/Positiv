//
//  ArtFetcher.swift
//  Positiv
//
//  Created by DnD-Luk on 25/10/2025.
//

import Foundation
import WidgetKit
import UIKit
import ImageIO
import MobileCoreServices

enum ArtFetcher {
    static let wikidataEndpoint = "https://query.wikidata.org/sparql"

    static let sparql = """
    SELECT ?item ?itemLabel ?image ?creatorLabel ?inception ?article WHERE {
      ?item wdt:P31/wdt:P279* wd:Q3305213.
      ?item wdt:P18 ?image.
      OPTIONAL { ?item wdt:P170 ?creator. }
      OPTIONAL { ?item wdt:P571 ?inception. }
      OPTIONAL { ?article schema:about ?item ;
                         schema:isPartOf <https://fr.wikipedia.org/> . }
      OPTIONAL { ?articleEN schema:about ?item ;
                            schema:isPartOf <https://en.wikipedia.org/> . }
      BIND(COALESCE(?article, ?articleEN) AS ?article)
      SERVICE wikibase:label { bd:serviceParam wikibase:language "fr,en". }
    }
    ORDER BY RAND()
    LIMIT 1
    """

    /// Appelle ça au lancement (et périodiquement) pour remplir le cache partagé
    static func fetchAndCache() async {
        print("fetchAndCache")
        do {
            var item = try await fetchRandomArtWithRetry()

            // ✅ Téléchargement et sauvegarde locale compressée
            if let localPath = try await downloadAndSaveImage(item.imageUrl) {
                item = ArtItem(
                    title: item.title,
                    artist: item.artist,
                    year: item.year,
                    articleUrl: item.articleUrl,
                    imageUrl: item.imageUrl,
                    localImagePath: localPath  // ← important !
                )
                print("💾 Image resized & saved:", localPath)
            } else {
                print("⚠️ Pas de localImagePath généré")
            }

            ArtCache.save(item)
            await pushWidgetReloadSafely()
            print("✅ Fetched:", item.title)
        } catch {
            print("⚠️ fetch error:", error.localizedDescription)
        }
    }
    
    

    // MARK: - Implémentation

    private static func fetchRandomArtWithRetry(maxAttempts: Int = 3) async throws -> ArtItem {
        var last: Error?
        for attempt in 1...maxAttempts {
            do { return try await fetchRandomArt() }
            catch {
                last = error
                // backoff: 0.4s, 0.8s
                if attempt < maxAttempts {
                    try? await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt-1)) * 0.4 * 1_000_000_000))
                }
            }
        }
        throw last ?? URLError(.timedOut)
    }

    private static func fetchRandomArt() async throws -> ArtItem {
        // Session avec timeouts courts
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        config.timeoutIntervalForResource = 12
        let session = URLSession(configuration: config)

        // 1) SPARQL
        var components = URLComponents(string: wikidataEndpoint)!
        components.queryItems = [
            .init(name: "format", value: "json"),
            .init(name: "query", value: sparql)
        ]
        var req = URLRequest(url: components.url!)
        req.setValue("application/sparql-results+json", forHTTPHeaderField: "Accept")
        req.setValue("Positiv Art Widget/1.0 (lsimonin2@gmail.com)", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await session.data(for: req)
        struct SPARQLResponse: Decodable {
            struct V: Decodable { let value: String? }
            struct B: Decodable {
                let itemLabel: V?; let image: V?
                let creatorLabel: V?; let inception: V?
                let article: V?; let articleEN: V?
            }
            struct R: Decodable { let bindings: [B] }
            let results: R
        }
        let parsed = try JSONDecoder().decode(SPARQLResponse.self, from: data)
        guard let b = parsed.results.bindings.first,
              let article = b.article?.value ?? b.articleEN?.value,
              let title = b.itemLabel?.value
        else { throw URLError(.badServerResponse) }

        let artist = b.creatorLabel?.value
        let year: String? = {
            guard let raw = b.inception?.value else { return nil }
            let clean = raw.trimmingCharacters(in: CharacterSet(charactersIn: "+"))
            let y4 = String(clean.prefix(4))
            return Int(y4).map(String.init)
        }()

        // 2) Wikipedia Summary → thumbnail
        let lang = article.contains("fr.wikipedia.org") ? "fr" : "en"
        let slug = article.split(separator: "/").last.map(String.init) ?? ""
        let summaryURL = URL(string: "https://\(lang).wikipedia.org/api/rest_v1/page/summary/\(slug.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)")!

        let (sdata, sresp) = try await session.data(from: summaryURL)
        let ok = (sresp as? HTTPURLResponse)?.statusCode == 200
        let summary = ok ? (try? JSONSerialization.jsonObject(with: sdata) as? [String: Any]) : nil
        let thumb = (summary?["thumbnail"] as? [String: Any])?["source"] as? String

        let imageUrl = Self.bestImageURL(
            summaryThumb: thumb,
            p18: b.image?.value
        )

        return ArtItem(title: title, artist: artist, year: year, articleUrl: article, imageUrl: imageUrl)
        }

        // Ajoute ceci dans ArtFetcher :
        private static func bestImageURL(summaryThumb: String?, p18: String?) -> String {
            // 1) Summary thumbnail si dispo
            if let u = summaryThumb, !u.isEmpty { return u }

            // 2) P18 peut être :
            //    - une URL "https://upload.wikimedia.org/..." (parfait)
            //    - une URL "https://commons.wikimedia.org/wiki/Special:FilePath/File.jpg" (OK)
            //    - parfois juste un titre de fichier "File:MonImage.jpg"
            if let p = p18, !p.isEmpty {
                if p.hasPrefix("http") {
                    return p
                } else {
                    // Construit une URL Special:FilePath à partir d'un titre "File:...".
                    let fileName = p.replacingOccurrences(of: "File:", with: "")
                    let encoded = fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? fileName
                    return "https://commons.wikimedia.org/wiki/Special:FilePath/\(encoded)?width=800"
                }
            }

            // 3) Dernier recours : une image publique sûre (évite string vide)
            return "https://upload.wikimedia.org/wikipedia/commons/6/6a/Mona_Lisa.jpg"
        }
    
    private static func appGroupImageURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppConfig.appGroup)?
            .appendingPathComponent("artwidget")
    }

    private static func downloadAndSaveImage(_ urlString: String) async throws -> String? {
        guard let url = URL(string: urlString) else { return nil }
        let (data, resp) = try await URLSession.shared.data(from: url)
        guard (resp as? HTTPURLResponse)?.statusCode == 200, !data.isEmpty else { return nil }

        // Downsample efficace (ne charge pas le full-res en mémoire)
        let maxPixels: CGFloat = 1024 // < 1.1 Mpx (limite WidgetKit)
        guard let down = downsampledJPEGData(from: data, maxPixelSize: Int(maxPixels)) else { return nil }

        // Log taille & dimensions pour vérif
        if let img = UIImage(data: down) {
            print("✅ Downsampled:", Int(img.size.width), "x", Int(img.size.height))
        }

        // Écrit dans l’App Group
        guard let dir = appGroupImageURL() else { return nil }
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
        guard let thumb = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else { return nil }
        let ui = UIImage(cgImage: thumb)
        return ui.jpegData(compressionQuality: 0.85)
    }
}

extension UIImage {
    func resized(maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        if maxSide <= maxDimension { return self } // déjà assez petit

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

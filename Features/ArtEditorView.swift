//
//  ArtSettingsView.swift
//  Prism
//
//  Created by DnD-Luk on 25/10/2025.
//

import SwiftUI
import WidgetKit

struct ArtSettingsView: View {
    @Environment(\.openURL) private var openURL
        @State private var status = "Idle"
        @State private var appearance = ArtPrefs.getAppearance()
        @State private var current: ArtItem? = ArtCache.load()

    var body: some View {
        NavigationStack {
            Form {
                if let item = current, let url = URL(string: item.articleUrl) {
                    Section("Œuvre actuelle") {
                        Text(item.title).font(.subheadline)
                        Button("🔎 Ouvrir la fiche") { openURL(url) }
                    }
                }
                

                Section {
                    
                    Button("🔄 Rafraîchir l’œuvre") {
                        _Concurrency.Task {
                            status = "⏳ Fetch…"
                            await ArtFetcher.fetchAndCache()
                            current = ArtCache.load()
                            status = "✅ Fait"
                            
                        }
                    }
                    Button("🧹 Vider le cache") {
                        ArtCache.clear()
                        _Concurrency.Task { await pushWidgetReloadSafely() }
                        status = "🧹 Cache vidé"
                    }
                }

                Text("Status: \(status)")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .navigationTitle("Widget Art")
            .onAppear { current = ArtCache.load() }
        }
    }
}

@MainActor
func pushWidgetReloadNow() {
    WidgetCenter.shared.getCurrentConfigurations { result in
        if case .success(let widgets) = result, !widgets.isEmpty {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

struct PillButtonStyle: ButtonStyle {
    var color: Color = .blue
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(color.opacity(configuration.isPressed ? 0.75 : 1))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: color.opacity(0.25), radius: configuration.isPressed ? 0 : 8, x: 0, y: 4)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

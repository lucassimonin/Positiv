//
//  AffirmationsView.swift
//  Positiv
//
//  Created by DnD-Luk on 23/10/2025.
//

import SwiftUI
import WidgetKit

let affirmationsKey = "affirmations"

func saveAffirmations(_ list: [String]) {
    let ud = UserDefaults(suiteName: AppConfig.appGroup)!
    ud.set(list, forKey: affirmationsKey)
    // avertir le widget que le contenu a changé
    WidgetCenter.shared.reloadTimelines(ofKind: "AffirmationsWidget")
}

struct AffirmationsEditorView: View {
    @State private var items: [String] = loadInitial()

        var body: some View {
            List {
                ForEach(items.indices, id: \.self) { i in
                    TextField("Affirmation", text: Binding(
                        get: { items[i] },
                        set: { items[i] = $0 }
                    ))
                }
                .onDelete { items.remove(atOffsets: $0) }

                Button("Ajouter") { items.append("Nouvelle affirmation") }
            }
            .toolbar {
                Button("Enregistrer") { saveAffirmations(items) }
            }
        }

        static func loadInitial() -> [String] {
            let ud = UserDefaults(suiteName: AppConfig.appGroup)
            return ud?.stringArray(forKey: affirmationsKey) ?? [
                "Je progresse chaque jour."
            ]
        }
}

//
//  AffirmationStore.swift
//  Prism
//
//  Created by DnD-Luk on 24/10/2025.
//

import Foundation
import Combine
import WidgetKit
import SwiftUI 

final class AffirmationStore: ObservableObject {
    @Published var items: [AffirmationItem] = []
    private var ud: UserDefaults { UserDefaults(suiteName: AppConfig.appGroup)! }

    init() { load() }

    func load() {
        if let data = ud.data(forKey: AppConfig.Keys.affirmations),
           let decoded = try? JSONDecoder().decode([AffirmationItem].self, from: data) {
            items = decoded; return
        }
        if let legacy = ud.stringArray(forKey: AppConfig.Keys.affirmations) { // migration
            items = legacy.map { AffirmationItem(text: $0) }
            save(); ud.removeObject(forKey: AppConfig.Keys.affirmations)
            return
        }
        items = [
        ]
    }

    func save() {
        if let data = try? JSONEncoder().encode(items) {
            ud.set(data, forKey: AppConfig.Keys.affirmations)
            WidgetCenter.shared.reloadTimelines(ofKind: AppConfig.WidgetKind.affirmations)
        }
    }

    // Actions
    func add(_ text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        items.insert(AffirmationItem(text: t), at: 0); save()
    }
    func delete(at offsets: IndexSet) { items.remove(atOffsets: offsets); save() }
    func move(from s: IndexSet, to d: Int) { items.move(fromOffsets: s, toOffset: d); save() }
    func update(_ item: AffirmationItem, text: String) {
        if let i = items.firstIndex(where: { $0.id == item.id }) {
            items[i].text = text; save()
        }
    }
}

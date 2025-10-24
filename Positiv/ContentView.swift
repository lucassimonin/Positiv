//
//  ContentView.swift
//  Positiv
//
//  Created by DnD-Luk on 23/10/2025.
//

import SwiftUI
import WidgetKit

struct MainTabs: View {
    var body: some View {
        TabView {
            AffirmationsEditorView()
                .tabItem { Label("Affirmations", systemImage: "text.quote") }

            NavigationStack {
                CountdownEditorView()
            }
            .tabItem { Label("Countdown", systemImage: "calendar.badge.clock") }
        }
    }
}

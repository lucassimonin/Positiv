//
//  ContentView.swift
//  Prism
//
//  Created by DnD-Luk on 23/10/2025.
//

import SwiftUI
import WidgetKit

struct MainTabs: View {
    var body: some View {
        TabView {
            AffirmationsEditorView()
                .tabItem { Label("affirmation_widget_name", systemImage: "text.quote") }

            NavigationStack {
                CountdownEditorView()
            }
            .tabItem { Label("countdown_widget_name", systemImage: "calendar.badge.clock") }
            
            NavigationStack {
                ArtEditorView()
            }
            .tabItem { Label("art_widget_name", systemImage: "paintpalette.fill") }
        }
    }
}

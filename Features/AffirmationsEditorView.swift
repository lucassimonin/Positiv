import SwiftUI
import WidgetKit

struct AffirmationsEditorView: View {
    @StateObject private var store = AffirmationStore()
    @State private var draft = ""
    
    // 👇 1. LA MAGIE : Cette variable se sauvegarde toute seule !
    // Par défaut, elle vaut "true" (activé).
    @AppStorage("includeRemoteAffirmations") private var includeRemote = true

    var body: some View {
        List {
            // 👇 2. NOUVELLE SECTION : LE RÉGLAGE
            Section {
                Toggle(isOn: $includeRemote) {
                    HStack {
                        Image(systemName: "cloud.fill")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            Text("Inspirations du cloud")
                                .font(.headline)
                            Text("Mélanger avec les phrases d'Internet")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                // Quand on change l'interrupteur, on recharge le widget immédiatement
                .onChange(of: includeRemote) { _, _ in
                    WidgetCenter.shared.reloadTimelines(ofKind: AppConfig.WidgetKind.affirmations)
                }
            } header: {
                Text("Réglages")
            }

            // --- Ta section d'ajout (inchangée) ---
            Section {
                HStack(spacing: 8) {
                    TextField("affirmation_placeholder", text: $draft, axis: .vertical)
                        .lineLimit(1...3)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                        .onChange(of: draft) { oldValue, newValue in
                            if newValue.last == "\n" {
                                let cleanText = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !cleanText.isEmpty { store.add(cleanText) }
                                draft = ""
                            }
                        }
                    Button {
                        store.add(draft); draft = ""
                    } label: { Image(systemName: "plus.circle.fill") }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            // --- Ta liste de phrases (inchangée) ---
            Section("affirmation_title") {
                ForEach($store.items) { $item in
                    TextField("affirmation_item", text: $item.text, axis: .vertical)
                        .lineLimit(1...3)
                        .textInputAutocapitalization(.sentences)
                        .onChange(of: item.text) { _, new in
                            store.update(item, text: new)
                        }
                }
                .onDelete(perform: store.delete)
                .onMove(perform: store.move)
            }
        }
        .scrollContentBackground(.hidden)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.2), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("affirmation_widget_name")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
    }
}

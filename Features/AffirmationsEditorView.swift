import SwiftUI

struct AffirmationsEditorView: View {
    @StateObject private var store = AffirmationStore()
    @State private var draft = ""

    var body: some View {
        List {
            Section {
                HStack(spacing: 8) {
                    TextField("affirmation_placeholder", text: $draft, axis: .vertical)
                        .lineLimit(1...3)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                        .onChange(of: draft) { oldValue, newValue in
                            // Si le dernier caractère est un saut de ligne...
                            if newValue.last == "\n" {
                                // 1. On nettoie le texte (on enlève le saut de ligne)
                                let cleanText = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                
                                // 2. On sauvegarde si ce n'est pas vide
                                if !cleanText.isEmpty {
                                    store.add(cleanText)
                                }
                                
                                // 3. On vide le champ
                                draft = ""
                            }
                        }
                    Button {
                        store.add(draft); draft = ""
                    } label: { Image(systemName: "plus.circle.fill") }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

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
        .scrollContentBackground(.hidden) // 1. On rend la liste transparente
        .background( // 2. On met notre beau dégradé derrière
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

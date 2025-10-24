import SwiftUI

struct AffirmationsEditorView: View {
    @StateObject private var store = AffirmationStore()
    @State private var draft = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 8) {
                        TextField("Ajouter une affirmation…", text: $draft, axis: .vertical)
                            .lineLimit(1...3)
                            .textInputAutocapitalization(.sentences)
                        Button {
                            store.add(draft); draft = ""
                        } label: { Image(systemName: "plus.circle.fill") }
                        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                Section("Mes affirmations") {
                    ForEach($store.items) { $item in    // ✅ ID stable → clavier OK
                        TextField("Affirmation", text: $item.text, axis: .vertical)
                            .lineLimit(1...3)
                            .textInputAutocapitalization(.sentences)
                            .onChange(of: item.text) { _, new in           // ⬅️ nouvelle API iOS 17
                                store.update(item, text: new)
                            }
                    }
                    .onDelete(perform: store.delete)
                    .onMove(perform: store.move)
                }
            }
            .navigationTitle("Affirmations")
            .toolbar { EditButton() }
        }
    }
}

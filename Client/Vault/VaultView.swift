import SwiftUI

struct VaultView: View {
    @EnvironmentObject private var store: AppStore
    @State private var search = ""
    @State private var category = "Tout"
    @State private var roomID: UUID?
    @State private var onlyToConfirm = false
    @State private var showAdd = false

    private var filtered: [VaultItem] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return store.items.filter { item in
            let searchOK = query.isEmpty
                || item.name.localizedCaseInsensitiveContains(query)
                || item.category.localizedCaseInsensitiveContains(query)
            let categoryOK = category == "Tout" || item.category == category
            let roomOK = roomID == nil || item.roomID == roomID
            let confirmOK = !onlyToConfirm || item.needsConfirmation
            return searchOK && categoryOK && roomOK && confirmOK
        }
        .sorted { $0.lastSeenAt > $1.lastSeenAt }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                summary
                searchBar
                filters
                content
            }
            .padding(18)
        }
        .owniqBackground()
        .navigationTitle("Mes objets")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .accessibilityLabel("Ajouter un objet")
            }
        }
        .sheet(isPresented: $showAdd) {
            ManualObjectAddView()
                .environmentObject(store)
        }
    }

    private var summary: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(store.items.isEmpty ? "Tout commence par un scan." : "\(store.items.count) objet\(store.items.count > 1 ? "s" : "")")
                    .font(.title2.bold())
                Text("Inventaire local sur cet appareil")
                    .font(.caption)
                    .foregroundStyle(Color.owniqSecondary)
            }
            Spacer()
            Image(systemName: "shippingbox.fill")
                .font(.title2)
                .foregroundStyle(Color.owniqViolet)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.owniqSecondary)
            TextField("Rechercher un objet…", text: $search)
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 52)
        .background(Color.owniqSurface, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
    }

    private var filters: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Menu {
                    Button("Toutes") { category = "Tout" }
                    ForEach(store.allCategories, id: \.self) { value in
                        Button(value) { category = value }
                    }
                } label: {
                    Label(category == "Tout" ? "Catégories" : category, systemImage: "square.grid.2x2")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)

                Menu {
                    Button("Toutes les pièces") { roomID = nil }
                    ForEach(store.rooms) { room in
                        Button(room.name) { roomID = room.id }
                    }
                } label: {
                    Label(roomName, systemImage: "house")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .disabled(store.rooms.isEmpty)
            }

            Toggle(isOn: $onlyToConfirm) {
                Label("Seulement les objets à confirmer", systemImage: "questionmark.circle")
                    .font(.subheadline)
            }
            .tint(Color.owniqSignal)
        }
    }

    @ViewBuilder
    private var content: some View {
        if filtered.isEmpty {
            ContentUnavailableView(
                store.items.isEmpty ? "Aucun objet" : "Aucun résultat",
                systemImage: "shippingbox",
                description: Text(store.items.isEmpty ? "Utilise le scan vidéo ou photo pour créer ton inventaire." : "Essaie une autre recherche ou enlève un filtre.")
            )
            .frame(minHeight: 300)
        } else {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(filtered) { item in
                    NavigationLink {
                        VaultItemDetailView(itemID: item.id)
                    } label: {
                        VaultItemTile(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var roomName: String {
        guard let roomID, let room = store.rooms.first(where: { $0.id == roomID }) else { return "Pièces" }
        return room.name
    }
}

struct VaultItemTile: View {
    let item: VaultItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.owniqSurface2)
                if let data = item.photoData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: icon(for: item.category))
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(Color.owniqSignal)
                }
            }
            .frame(height: 132)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(item.name)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(2)

            Text(item.category)
                .font(.caption)
                .foregroundStyle(Color.owniqSecondary)

            if item.needsConfirmation {
                Label("À confirmer", systemImage: "questionmark.circle.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.orange)
            }
        }
        .padding(10)
        .background(Color.owniqSurface, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        }
    }

    private func icon(for category: String) -> String {
        switch category {
        case "Informatique": return "laptopcomputer"
        case "Téléphonie": return "iphone"
        case "Jeux": return "gamecontroller.fill"
        case "Cuisine": return "fork.knife"
        case "Maison": return "lamp.floor.fill"
        case "Mode": return "tshirt.fill"
        case "Livres": return "book.fill"
        case "Sport": return "figure.run"
        case "Collection": return "sparkles"
        default: return "shippingbox.fill"
        }
    }
}

struct VaultItemDetailView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let itemID: UUID

    @State private var name = ""
    @State private var category = "Autres"
    @State private var needsConfirmation = true
    @State private var roomID: UUID?

    private var current: VaultItem? { store.items.first(where: { $0.id == itemID }) }

    var body: some View {
        Form {
            if let data = current?.photoData, let image = UIImage(data: data) {
                Section {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }

            Section("Objet") {
                TextField("Nom", text: $name)
                Picker("Catégorie", selection: $category) {
                    ForEach(AppStore.defaultCategories, id: \.self) { Text($0).tag($0) }
                }
                Toggle("À confirmer", isOn: $needsConfirmation)
            }

            if !store.rooms.isEmpty {
                Section("Pièce") {
                    Picker("Localisation", selection: $roomID) {
                        Text("Aucune").tag(UUID?.none)
                        ForEach(store.rooms) { room in
                            Text(room.name).tag(UUID?.some(room.id))
                        }
                    }
                }
            }

            if let current {
                Section("Scan") {
                    LabeledContent("Source", value: current.source.rawValue)
                    if let confidence = current.confidence {
                        LabeledContent("Confiance fallback", value: "\(Int((confidence * 100).rounded())) %")
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    if let current { store.delete(current) }
                    dismiss()
                } label: {
                    Label("Supprimer l'objet", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Détails")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Enregistrer") { save() }
            }
        }
    }

    private func load() {
        guard let current else { return }
        name = current.name
        category = current.category
        needsConfirmation = current.needsConfirmation
        roomID = current.roomID
    }

    private func save() {
        guard var current else { return }
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        current.name = clean
        current.category = category
        current.needsConfirmation = needsConfirmation
        current.roomID = roomID
        current.lastSeenAt = Date()
        store.update(current)
        dismiss()
    }
}

struct ManualObjectAddView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var category = "Autres"

    var body: some View {
        NavigationStack {
            Form {
                Section("Objet") {
                    TextField("Nom", text: $name)
                    Picker("Catégorie", selection: $category) {
                        ForEach(AppStore.defaultCategories, id: \.self) { Text($0).tag($0) }
                    }
                }
            }
            .navigationTitle("Ajouter")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !clean.isEmpty else { return }
                        store.add(VaultItem(name: clean, category: category, needsConfirmation: false, source: .manual))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

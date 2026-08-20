import SwiftUI
import UIKit

struct ObjectsView: View {
    @EnvironmentObject private var store: PublicStore

    var body: some View {
        NavigationStack {
            Group {
                if store.items.isEmpty {
                    ContentUnavailableView {
                        Label("Aucun objet", systemImage: "shippingbox")
                    } description: {
                        Text("Scanne un objet pour le retrouver ici.")
                    }
                } else {
                    List {
                        ForEach(store.items) { item in
                            HStack(spacing: 14) {
                                thumbnail(for: item)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.headline)
                                    Text(item.valueText)
                                        .font(.subheadline)
                                    Text(item.conditionText)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Mes objets")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileDestinationButton()
                }
            }
        }
    }

    @ViewBuilder
    private func thumbnail(for item: PublicItem) -> some View {
        if let data = item.imageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 62, height: 62)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityHidden(true)
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(OwnIQTheme.softAccent)
                .frame(width: 62, height: 62)
                .overlay {
                    Image(systemName: "shippingbox")
                        .foregroundStyle(OwnIQTheme.accent)
                }
                .accessibilityHidden(true)
        }
    }
}

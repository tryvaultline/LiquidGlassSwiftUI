import SwiftUI

struct CreateMediaPicker: View {
    @EnvironmentObject private var store: MaxPrototypeStore
    @Environment(\.dismiss) private var dismiss

    let kind: MediaKind
    @Binding var selectedIDs: Set<String>
    @Binding var mediaAccessBlocked: Bool

    private var options: [MaxMediaItem] {
        store.media.filter { $0.kind == kind && !$0.isLocked && $0.owner != "You" }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(options) { item in
                            Button {
                                HapticFeedback.selection()
                                if selectedIDs.contains(item.id) {
                                    selectedIDs.remove(item.id)
                                } else {
                                    selectedIDs.insert(item.id)
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    ZStack(alignment: .topTrailing) {
                                        MaxMediaArtwork(item: item, height: 148)
                                        Image(systemName: selectedIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                            .font(.title3)
                                            .foregroundStyle(selectedIDs.contains(item.id) ? .black : .white)
                                            .padding(9)
                                            .background(selectedIDs.contains(item.id) ? .white : .black.opacity(0.35), in: Circle())
                                            .padding(8)
                                    }
                                    Text(item.title)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                }
                                .padding(8)
                                .maxSurface(cornerRadius: 20, emphasized: selectedIDs.contains(item.id))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Select \(kind.title)s")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Preview Denied State") {
                        mediaAccessBlocked = true
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.72))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

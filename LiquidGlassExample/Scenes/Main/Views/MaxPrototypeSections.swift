import SwiftUI

struct MaxLibraryView: View {
    private let entries = [
        ("Afterlight", "Saved series", "moon.stars.fill"),
        ("Paper Cities", "Film", "building.2.fill"),
        ("Northbound", "Documentary", "mountain.2.fill"),
        ("Orbit", "Saved series", "sparkles")
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                sectionHeader(
                    title: "Library",
                    subtitle: "Everything you deliberately kept"
                )

                HStack(spacing: 9) {
                    filter("Saved", active: true)
                    filter("History", active: false)
                    filter("Ratings", active: false)
                }

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 13),
                        GridItem(.flexible(), spacing: 13)
                    ],
                    spacing: 13
                ) {
                    ForEach(entries.indices, id: \.self) { index in
                        let entry = entries[index]

                        Button {
                            HapticFeedback.tap()
                        } label: {
                            VStack(alignment: .leading, spacing: 11) {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(.white.opacity(0.08))
                                    .frame(height: 188)
                                    .overlay {
                                        Image(systemName: entry.2)
                                            .font(.largeTitle.weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.76))
                                    }

                                Text(entry.0)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)

                                Text(entry.1)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.52))
                            }
                            .padding(10)
                            .denseGlassPanel(cornerRadius: 24)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 116)
        }
    }

    private func filter(_ title: String, active: Bool) -> some View {
        Button {
            HapticFeedback.selection()
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(active ? .black : .white.opacity(0.74))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(active ? .white : .black.opacity(0.7), in: Capsule())
                .overlay {
                    Capsule().strokeBorder(.white.opacity(0.14), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

struct MaxChatsView: View {
    private let conversations = [
        ("Noura", "That last scene was unreal", "2m", "person.fill"),
        ("Movie night", "Raied: I rated it an 8", "18m", "person.3.fill"),
        ("Max team", "Draft playback screen is ready", "1h", "rectangle.3.group.fill")
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(
                    title: "Chats",
                    subtitle: "Private conversations only"
                )

                Text("DIRECT & GROUP MESSAGES")
                    .font(.caption2.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(.white.opacity(0.46))

                ForEach(conversations.indices, id: \.self) { index in
                    let conversation = conversations[index]

                    Button {
                        HapticFeedback.tap()
                    } label: {
                        HStack(spacing: 13) {
                            Circle()
                                .fill(.white.opacity(0.12))
                                .frame(width: 48, height: 48)
                                .overlay {
                                    Image(systemName: conversation.3)
                                        .foregroundStyle(.white.opacity(0.8))
                                }

                            VStack(alignment: .leading, spacing: 5) {
                                Text(conversation.0)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)

                                Text(conversation.1)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.55))
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text(conversation.2)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.42))
                        }
                        .padding(13)
                        .denseGlassPanel(cornerRadius: 22)
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Prototype constraint")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.82))

                    Text("Public channels, bots, calls, and communities are intentionally excluded from the first Max release.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(15)
                .denseGlassPanel(cornerRadius: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 116)
        }
    }
}

struct MaxDownloadsView: View {
    private let downloads = [
        ("Afterlight · Episode 4", 0.74, "1.2 GB"),
        ("Northbound", 0.42, "680 MB"),
        ("Paper Cities", 1.0, "Ready offline")
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 17) {
                sectionHeader(
                    title: "Downloads",
                    subtitle: "Watch on your own terms"
                )

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("2.6 GB of 10 GB")
                                .font(.headline)

                            Text("Offline storage on this device")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.52))
                        }

                        Spacer()

                        Image(systemName: "internaldrive.fill")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.78))
                    }

                    ProgressView(value: 0.26)
                        .tint(.white)
                }
                .padding(16)
                .denseGlassPanel(cornerRadius: 24)

                Text("IN PROGRESS")
                    .font(.caption2.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(.white.opacity(0.46))

                ForEach(downloads.indices, id: \.self) { index in
                    let item = downloads[index]

                    HStack(spacing: 13) {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(.white.opacity(0.1))
                            .frame(width: 62, height: 62)
                            .overlay {
                                Image(systemName: item.1 == 1 ? "checkmark" : "arrow.down")
                                    .foregroundStyle(.white.opacity(0.78))
                            }

                        VStack(alignment: .leading, spacing: 7) {
                            Text(item.0)
                                .font(.subheadline.weight(.semibold))

                            ProgressView(value: item.1)
                                .tint(.white)

                            Text(item.2)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        Spacer()

                        Button {
                            HapticFeedback.tap()
                        } label: {
                            Image(systemName: "ellipsis")
                                .actionIcon(font: .body)
                        }
                        .buttonStyle(.plain)
                        .glassCircleButton(diameter: 38)
                    }
                    .padding(12)
                    .denseGlassPanel(cornerRadius: 22)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 116)
        }
    }
}

private func sectionHeader(title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 5) {
        Text(title)
            .font(.largeTitle.weight(.bold))

        Text(subtitle)
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.56))
    }
}

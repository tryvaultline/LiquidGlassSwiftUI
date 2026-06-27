import SwiftUI

struct MaxHomeView: View {
    @EnvironmentObject private var store: MaxPrototypeStore

    let openSearch: () -> Void
    let openMedia: (String) -> Void
    let selectTab: (MaxTab) -> Void

    @State private var isLoading = true

    private var hero: MaxMediaItem? {
        store.mediaItem(id: "afterlight")
    }

    private var continueWatching: [MaxMediaItem] {
        let watched = store.watchedMedia
        return watched.isEmpty ? store.media.filter { !$0.isLocked }.prefix(3).map { $0 } : Array(watched.prefix(3))
    }

    private var sharedWithYou: [MaxMediaItem] {
        store.media.filter { $0.owner != "You" && !$0.isLocked }.prefix(3).map { $0 }
    }

    private var circleMedia: [MaxMediaItem] {
        store.media.filter { $0.privacy == .group && !$0.isLocked }.prefix(3).map { $0 }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                homeHeader

                MaxOfflineBanner()

                if isLoading {
                    HomeSkeleton()
                } else {
                    if let hero {
                        HomeHeroCard(item: hero, openMedia: openMedia)

                        HomeHeroActions(item: hero)
                    }

                    activityCard

                    mediaShelf(
                        title: "Continue Watching",
                        subtitle: "Resume your private viewing",
                        items: continueWatching,
                        emptyTitle: "Nothing to resume yet",
                        emptyDetail: "Play a private video and it will appear here."
                    )

                    mediaShelf(
                        title: "Shared Privately With You",
                        subtitle: "Direct shares from people you trust",
                        items: sharedWithYou,
                        emptyTitle: "No direct shares yet",
                        emptyDetail: "Private media sent to you will appear here."
                    )

                    mediaShelf(
                        title: "Recent From Your Circles",
                        subtitle: "Your private groups, not a public feed",
                        items: circleMedia,
                        emptyTitle: "Your circles are quiet",
                        emptyDetail: "Create a private group to begin sharing."
                    )

                    if let locked = store.media.first(where: \.isLocked) {
                        HomeLockedCard(item: locked)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 112)
        }
        .task {
            try? await Task.sleep(nanoseconds: 480_000_000)
            withAnimation(.easeOut(duration: 0.24)) {
                isLoading = false
            }
        }
    }

    private var homeHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("MAX")
                    .font(.title2.weight(.black))
                    .tracking(4)
                    .foregroundStyle(.white)

                Text("Private media room")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.56))
            }

            Spacer()

            Button(action: openSearch) {
                Image(systemName: "magnifyingglass")
                    .actionIcon(font: .body)
            }
            .buttonStyle(.plain)
            .glassCircleButton(diameter: 42)
            .accessibilityLabel("Search private media")

            Button {
                HapticFeedback.tap()
                selectTab(.profile)
            } label: {
                Text("R")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(width: 42, height: 42)
                    .background(.white, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open profile")
        }
    }

    private var activityCard: some View {
        Button {
            HapticFeedback.tap()
            selectTab(.chats)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.3.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.black)
                    .frame(width: 42, height: 42)
                    .background(.white, in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("3 new clips from Weekend Group")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Open the private group to see what changed.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.54))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(13)
            .maxSurface(cornerRadius: 22, emphasized: true)
        }
        .buttonStyle(.plain)
    }

    private func mediaShelf(
        title: String,
        subtitle: String,
        items: [MaxMediaItem],
        emptyTitle: String,
        emptyDetail: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            MaxSectionTitle(
                title: title,
                subtitle: subtitle,
                actionTitle: "Library"
            ) {
                selectTab(.library)
            }

            if items.isEmpty {
                MaxEmptyState(
                    symbol: "rectangle.stack.badge.plus",
                    title: emptyTitle,
                    detail: emptyDetail,
                    actionTitle: "Open Library"
                ) {
                    selectTab(.library)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(items) { item in
                            MaxMediaCard(item: item, isCompact: true) {
                                HapticFeedback.tap()
                                openMedia(item.id)
                            }
                            .frame(width: 184)
                        }
                    }
                    .padding(.vertical, 1)
                }
            }
        }
    }
}

private struct HomeHeroCard: View {
    let item: MaxMediaItem
    let openMedia: (String) -> Void

    var body: some View {
        Button {
            HapticFeedback.tap()
            openMedia(item.id)
        } label: {
            VStack(alignment: .leading, spacing: 13) {
                ZStack(alignment: .bottomLeading) {
                    MaxMediaArtwork(item: item, height: 236, showsProgress: true)

                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.caption.weight(.bold))
                        Text(item.isWatched ? "Resume private video" : "Watch private video")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(.white, in: Capsule())
                    .padding(14)
                }

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(item.title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                        Spacer()
                        Text(item.duration)
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Text(item.caption)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(2)

                    HStack(spacing: 7) {
                        Label(item.owner, systemImage: item.privacy.icon)
                        Text("·")
                        Text(item.privacy.rawValue)
                        Text("·")
                        Text(item.dateLabel)
                        Text("·")
                        Text(item.sizeLabel)
                    }
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.49))

                    if item.isWatched {
                        HStack(spacing: 8) {
                            ProgressView(value: 0.48)
                                .tint(.white)
                            Text("48% watched")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.54))
                        }
                    }
                }
            }
            .padding(10)
            .maxSurface(cornerRadius: 29, emphasized: true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open \(item.title) player")
    }
}

private struct HomeHeroActions: View {
    @EnvironmentObject private var store: MaxPrototypeStore
    let item: MaxMediaItem

    var body: some View {
        HStack(spacing: 9) {
            HomeAction(title: item.isSaved ? "Saved" : "Save", symbol: item.isSaved ? "bookmark.fill" : "bookmark", isActive: item.isSaved) {
                store.toggleSaved(item.id)
            }
            HomeAction(title: item.isLiked ? "Liked" : "Like", symbol: item.isLiked ? "heart.fill" : "heart", isActive: item.isLiked) {
                store.toggleLiked(item.id)
            }
            HomeAction(title: item.rating.map { "\($0)/10" } ?? "Rate", symbol: item.rating == nil ? "star" : "star.fill", isActive: item.rating != nil) {
                let nextRating = item.rating == nil ? 8 : min(10, (item.rating ?? 7) + 1)
                HapticFeedback.selection()
                store.setRating(nextRating, for: item.id)
            }
            HomeAction(title: item.downloadState == .completed ? "Offline" : "Download", symbol: item.downloadState == .completed ? "checkmark.circle.fill" : "arrow.down.circle", isActive: item.downloadState == .completed) {
                store.toggleDownload(for: item.id)
            }
        }
    }
}

private struct HomeAction: View {
    let title: String
    let symbol: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button {
            HapticFeedback.selection()
            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.body.weight(.semibold))
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isActive ? .black : .white.opacity(0.78))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isActive ? .white : .clear, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
        .maxControlSurface(cornerRadius: 15)
    }
}

private struct HomeLockedCard: View {
    @EnvironmentObject private var store: MaxPrototypeStore
    let item: MaxMediaItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))
                .frame(width: 46, height: 46)
                .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(item.requestAccessSent ? "Access request sent to \(item.owner)" : "Private to \(item.owner) · \(item.sizeLabel)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.53))
            }

            Spacer(minLength: 0)

            Button(item.requestAccessSent ? "Sent" : "Request Access") {
                HapticFeedback.tap()
                store.requestAccess(for: item.id)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(item.requestAccessSent ? .white.opacity(0.55) : .black)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(item.requestAccessSent ? .white.opacity(0.08) : .white, in: Capsule())
            .buttonStyle(.plain)
            .disabled(item.requestAccessSent)
        }
        .padding(12)
        .maxSurface(cornerRadius: 22)
    }
}

private struct HomeSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white.opacity(0.1))
                .frame(height: 328)
            ForEach(0..<2, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 10) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white.opacity(0.11))
                        .frame(width: 150, height: 14)
                    HStack(spacing: 12) {
                        ForEach(0..<2, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(.white.opacity(0.08))
                                .frame(width: 184, height: 202)
                        }
                    }
                }
            }
        }
        .redacted(reason: .placeholder)
    }
}

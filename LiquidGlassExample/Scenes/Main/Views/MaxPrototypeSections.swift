import SwiftUI

private enum LibrarySegment: String, CaseIterable, Identifiable {
    case media = "Media"
    case collections = "Collections"
    case downloads = "Downloads"

    var id: String { rawValue }
}

private enum LibraryFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case photos = "Photos"
    case videos = "Videos"
    case shared = "Shared"
    case saved = "Saved"
    case offline = "Offline"
    case locked = "Locked"

    var id: String { rawValue }

    var icon: String? {
        switch self {
        case .all: nil
        case .photos: "photo.fill"
        case .videos: "play.rectangle.fill"
        case .shared: "person.2.fill"
        case .saved: "bookmark.fill"
        case .offline: "arrow.down.circle.fill"
        case .locked: "lock.fill"
        }
    }
}

private enum LibrarySort: String, CaseIterable, Identifiable {
    case newest = "Newest"
    case name = "Name"
    case size = "Size"

    var id: String { rawValue }
}

struct MaxLibraryView: View {
    @EnvironmentObject private var store: MaxPrototypeStore

    let openMedia: (String) -> Void

    @State private var segment: LibrarySegment = .media
    @State private var filter: LibraryFilter = .all
    @State private var sort: LibrarySort = .newest
    @State private var gridMode = true
    @State private var showEmptyLibrary = false
    @State private var showEmptyDownloads = false

    private var filteredMedia: [MaxMediaItem] {
        guard !showEmptyLibrary else { return [] }
        var items = store.media

        switch filter {
        case .all:
            break
        case .photos:
            items = items.filter { $0.kind == .photo }
        case .videos:
            items = items.filter { $0.kind == .video }
        case .shared:
            items = items.filter { $0.owner != "You" }
        case .saved:
            items = items.filter(\.isSaved)
        case .offline:
            items = items.filter { $0.downloadState == .completed }
        case .locked:
            items = items.filter(\.isLocked)
        }

        switch sort {
        case .newest:
            return items
        case .name:
            return items.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .size:
            return items.sorted { $0.sizeLabel.localizedStandardCompare($1.sizeLabel) == .orderedDescending }
        }
    }

    private var activeDownloads: [MaxMediaItem] {
        store.downloads
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                MaxOfflineBanner()
                MaxStorageCard()
                segmentControl

                switch segment {
                case .media:
                    mediaContent
                case .collections:
                    collectionsContent
                case .downloads:
                    downloadsContent
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 112)
        }
    }

    private var header: some View {
        MaxPageHeader(
            title: "Library",
            subtitle: "Private media, kept intentionally",
            trailing: AnyView(
                Menu {
                    Button("Show Empty Library") {
                        showEmptyLibrary = true
                        segment = .media
                    }
                    Button("Restore Library") {
                        showEmptyLibrary = false
                    }
                    Button("Show No Downloads") {
                        showEmptyDownloads = true
                        segment = .downloads
                    }
                    Button("Restore Downloads") {
                        showEmptyDownloads = false
                    }
                    Divider()
                    Button(store.isOfflineMode ? "Turn Offline Mode Off" : "Turn Offline Mode On") {
                        store.isOfflineMode.toggle()
                        store.showSuccess(store.isOfflineMode ? "Offline Mode On" : "Online Mode", detail: store.isOfflineMode ? "Only completed downloads can play." : "Private media can refresh again.", symbol: store.isOfflineMode ? "wifi.slash" : "wifi")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .actionIcon(font: .body.weight(.bold))
                }
                .glassCircleButton(diameter: 42)
            )
        )
    }

    private var segmentControl: some View {
        HStack(spacing: 7) {
            ForEach(LibrarySegment.allCases) { value in
                Button {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
                        segment = value
                    }
                } label: {
                    Text(value.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(segment == value ? .black : .white.opacity(0.68))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(segment == value ? .white : .clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .maxControlSurface(cornerRadius: 18)
    }

    private var mediaContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(LibraryFilter.allCases) { value in
                        MaxPill(title: value.rawValue, systemImage: value.icon, isSelected: filter == value) {
                            filter = value
                        }
                    }
                }
                .padding(.vertical, 1)
            }

            HStack {
                Text("\(filteredMedia.count) items")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.52))

                Spacer()

                Menu {
                    ForEach(LibrarySort.allCases) { value in
                        Button(value.rawValue) {
                            HapticFeedback.selection()
                            sort = value
                        }
                    }
                } label: {
                    Label(sort.rawValue, systemImage: "arrow.up.arrow.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.73))
                }
                .buttonStyle(.plain)

                Button {
                    HapticFeedback.selection()
                    gridMode.toggle()
                } label: {
                    Image(systemName: gridMode ? "list.bullet" : "square.grid.2x2")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.78))
                }
                .buttonStyle(.plain)
                .padding(.leading, 12)
            }

            if filteredMedia.isEmpty {
                MaxEmptyState(
                    symbol: "rectangle.stack.badge.plus",
                    title: "Your Library is Empty",
                    detail: "Saved, shared, and uploaded private media will stay here.",
                    actionTitle: "Restore Demo Library"
                ) {
                    showEmptyLibrary = false
                    filter = .all
                }
            } else if gridMode {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 13), GridItem(.flexible(), spacing: 13)], spacing: 13) {
                    ForEach(filteredMedia) { item in
                        MaxMediaCard(item: item, showsDownloadStatus: item.downloadState != nil) {
                            HapticFeedback.tap()
                            openMedia(item.id)
                        }
                    }
                }
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(filteredMedia) { item in
                        LibraryListRow(item: item) {
                            HapticFeedback.tap()
                            openMedia(item.id)
                        }
                    }
                }
            }

            if filter == .all && !showEmptyLibrary {
                savedAndHistory
            }
        }
    }

    private var savedAndHistory: some View {
        VStack(alignment: .leading, spacing: 20) {
            libraryShelf(
                title: "Saved Media",
                subtitle: "Available in your personal list",
                items: store.savedMedia,
                emptyTitle: "Nothing saved yet",
                emptyDetail: "Save a video from Home or the player."
            )

            libraryShelf(
                title: "Watch History",
                subtitle: "Only visible to you",
                items: store.watchedMedia,
                emptyTitle: "No watch history yet",
                emptyDetail: "Private playback appears here after you press play."
            )
        }
    }

    private var collectionsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            MaxSectionTitle(title: "Private Albums", subtitle: "Organized for you and your circles")

            CollectionRow(
                title: "Private albums",
                detail: "\(store.media.filter { $0.kind == .photo }.count) photo collections",
                symbol: "photo.on.rectangle.angled"
            ) {
                segment = .media
                filter = .photos
            }

            CollectionRow(
                title: "Saved media",
                detail: "\(store.savedMedia.count) items kept for later",
                symbol: "bookmark.fill"
            ) {
                segment = .media
                filter = .saved
            }

            CollectionRow(
                title: "Shared group media",
                detail: "\(store.media.filter { $0.privacy == .group }.count) private group items",
                symbol: "person.3.fill"
            ) {
                segment = .media
                filter = .shared
            }

            CollectionRow(
                title: "Watch history",
                detail: "\(store.watchedMedia.count) recently viewed items",
                symbol: "clock.arrow.circlepath"
            ) {
                segment = .media
                filter = .all
            }
        }
    }

    private var downloadsContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Downloads")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("\(store.storageCapacityText) total · 6.2 GB remaining")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.52))
                }
                Spacer()
                Button(store.isOfflineMode ? "Online" : "Offline") {
                    store.isOfflineMode.toggle()
                    store.showSuccess(store.isOfflineMode ? "Offline Mode On" : "Online Mode", detail: "Library playback state updated.", symbol: store.isOfflineMode ? "wifi.slash" : "wifi")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(store.isOfflineMode ? .black : .white.opacity(0.76))
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(store.isOfflineMode ? .white : .white.opacity(0.08), in: Capsule())
                .buttonStyle(.plain)
            }

            if activeDownloads.isEmpty || showEmptyDownloads {
                MaxEmptyState(
                    symbol: "arrow.down.circle",
                    title: "No Downloads",
                    detail: "Choose Download on private media to keep it on this iPhone.",
                    actionTitle: "Restore Download Queue"
                ) {
                    showEmptyDownloads = false
                }
            } else {
                ForEach(activeDownloads) { item in
                    DownloadRow(item: item, openMedia: openMedia)
                }
            }
        }
    }

    private func libraryShelf(
        title: String,
        subtitle: String,
        items: [MaxMediaItem],
        emptyTitle: String,
        emptyDetail: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            MaxSectionTitle(title: title, subtitle: subtitle)
            if items.isEmpty {
                MaxEmptyState(
                    symbol: "bookmark",
                    title: emptyTitle,
                    detail: emptyDetail,
                    actionTitle: "Browse Media"
                ) {
                    segment = .media
                    filter = .all
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(items) { item in
                            MaxMediaCard(item: item, isCompact: true) {
                                openMedia(item.id)
                            }
                            .frame(width: 184)
                        }
                    }
                }
            }
        }
    }
}

private struct LibraryListRow: View {
    let item: MaxMediaItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                MaxMediaArtwork(item: item, height: 68, showsProgress: item.downloadState != nil)
                    .frame(width: 104)
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(item.metadataLine)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.54))
                    HStack(spacing: 5) {
                        Label(item.privacy.rawValue, systemImage: item.privacy.icon)
                        if let state = item.downloadState {
                            Text("·")
                            Text(state.title)
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.43))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.36))
            }
            .padding(9)
            .maxSurface(cornerRadius: 20)
        }
        .buttonStyle(.plain)
    }
}

private struct CollectionRow: View {
    let title: String
    let detail: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 46, height: 46)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.53))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.38))
            }
            .padding(12)
            .maxSurface(cornerRadius: 22)
        }
        .buttonStyle(.plain)
    }
}

private struct DownloadRow: View {
    @EnvironmentObject private var store: MaxPrototypeStore

    let item: MaxMediaItem
    let openMedia: (String) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                HapticFeedback.tap()
                openMedia(item.id)
            } label: {
                MaxMediaArtwork(item: item, height: 72, showsProgress: true)
                    .frame(width: 106)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                if let state = item.downloadState {
                    HStack(spacing: 5) {
                        Image(systemName: state.icon)
                        Text(state.title)
                        if state != .completed {
                            Text("· \(Int(item.downloadProgress * 100))%")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.57))
                }

                if item.downloadState != .completed {
                    ProgressView(value: item.downloadProgress)
                        .tint(.white)
                }
            }

            Spacer()

            Menu {
                if item.downloadState == .failed {
                    Button("Retry") { store.retryDownload(for: item.id) }
                } else if item.downloadState == .downloading {
                    Button("Pause") { store.toggleDownload(for: item.id) }
                } else if item.downloadState == .paused || item.downloadState == .queued {
                    Button("Resume") { store.toggleDownload(for: item.id) }
                }
                if item.downloadState != .failed && item.downloadState != .completed {
                    Button("Simulate Failure") { store.simulateDownloadFailure(for: item.id) }
                }
                Button("Delete Local Download", role: .destructive) {
                    store.deleteLocalDownload(for: item.id)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.08), in: Circle())
            }
            .accessibilityLabel("Download options for \(item.title)")
        }
        .padding(10)
        .maxSurface(cornerRadius: 22)
    }
}

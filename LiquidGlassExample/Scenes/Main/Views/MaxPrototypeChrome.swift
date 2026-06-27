import SwiftUI

extension View {
    func maxSurface(cornerRadius: CGFloat = 24, emphasized: Bool = false) -> some View {
        self
            .background(emphasized ? Color.white.opacity(0.12) : Color.white.opacity(0.075), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(emphasized ? 0.18 : 0.09), lineWidth: 1)
            }
    }

    func maxControlSurface(cornerRadius: CGFloat = 22) -> some View {
        self
            .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.16), lineWidth: 1)
            }
    }
}

struct MaxPageHeader: View {
    let title: String
    let subtitle: String
    var trailing: AnyView?

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.56))
            }

            Spacer(minLength: 0)

            if let trailing {
                trailing
            }
        }
    }
}

struct MaxSectionTitle: View {
    let title: String
    let subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.52))
                }
            }

            Spacer()

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct MaxPill: View {
    let title: String
    let systemImage: String?
    var isSelected = false
    var action: () -> Void

    var body: some View {
        Button {
            HapticFeedback.selection()
            action()
        } label: {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.caption.weight(.bold))
                }

                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .black : .white.opacity(0.78))
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(isSelected ? .white : .white.opacity(0.075), in: Capsule())
            .overlay {
                Capsule().strokeBorder(.white.opacity(isSelected ? 0.28 : 0.11), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct MaxMediaArtwork: View {
    let item: MaxMediaItem
    var height: CGFloat = 156
    var showsProgress = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.14),
                            Color.white.opacity(0.055),
                            Color.black.opacity(0.75)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: height * 0.76, height: height * 0.76)
                .blur(radius: 3)
                .offset(x: height * 0.18, y: -height * 0.2)

            Image(systemName: item.icon)
                .font(.system(size: min(height * 0.30, 42), weight: .semibold))
                .foregroundStyle(.white.opacity(0.86))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 7) {
                Label(item.kind.title, systemImage: item.kind.icon)
                if item.isLocked {
                    Image(systemName: "lock.fill")
                }
                if item.downloadState == .completed {
                    Image(systemName: "checkmark.circle.fill")
                }
            }
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white.opacity(0.88))
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(.black.opacity(0.66), in: Capsule())
            .padding(10)

            if showsProgress, item.downloadProgress > 0, item.downloadProgress < 1 {
                VStack(spacing: 0) {
                    Spacer()
                    ProgressView(value: item.downloadProgress)
                        .tint(.white)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 8)
                }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
    }
}

struct MaxMediaCard: View {
    let item: MaxMediaItem
    var isCompact = false
    var showsDownloadStatus = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                MaxMediaArtwork(item: item, height: isCompact ? 112 : 165, showsProgress: showsDownloadStatus)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Spacer(minLength: 2)

                        if let rating = item.rating {
                            Text("\(rating)")
                                .font(.caption2.weight(.bold).monospacedDigit())
                                .foregroundStyle(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.white, in: Capsule())
                        }
                    }

                    Text(item.metadataLine)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Label(item.privacy.rawValue, systemImage: item.privacy.icon)
                        Text("·")
                        Text(item.dateLabel)
                        if item.isDownloadAvailable {
                            Text("·")
                            Image(systemName: "arrow.down.circle")
                        }
                    }
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.46))

                    if showsDownloadStatus, let state = item.downloadState {
                        HStack(spacing: 5) {
                            Image(systemName: state.icon)
                            Text(state.title)
                            if state == .downloading || state == .paused {
                                Text("\(Int(item.downloadProgress * 100))%")
                            }
                        }
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(state == .failed ? .white.opacity(0.72) : .white.opacity(0.58))
                    }
                }
            }
            .padding(10)
            .maxSurface(cornerRadius: 24)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open \(item.title)")
    }
}

struct MaxEmptyState: View {
    let symbol: String
    let title: String
    let detail: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(.white.opacity(0.82))
                .frame(width: 70, height: 70)
                .background(.white.opacity(0.08), in: Circle())

            Text(title)
                .font(.headline)
                .foregroundStyle(.white)

            Text(detail)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.53))

            Button(action: action) {
                Text(actionTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(.white, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .maxSurface(cornerRadius: 26)
    }
}

struct MaxStorageCard: View {
    @EnvironmentObject private var store: MaxPrototypeStore

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: store.storageProgress)
                    .stroke(.white, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(store.storageProgress * 100))%")
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(store.usedStorageText) of \(store.storageCapacityText)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Private media stored on this iPhone")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.52))
            }

            Spacer()

            Image(systemName: "internaldrive.fill")
                .foregroundStyle(.white.opacity(0.74))
        }
        .padding(15)
        .maxSurface(cornerRadius: 23)
    }
}

struct MaxOfflineBanner: View {
    @EnvironmentObject private var store: MaxPrototypeStore

    var body: some View {
        if store.isOfflineMode {
            HStack(spacing: 9) {
                Image(systemName: "wifi.slash")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Offline Mode")
                        .font(.caption.weight(.bold))
                    Text("Only completed local downloads can play.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.58))
                }
                Spacer()
                Button("Turn Off") {
                    HapticFeedback.selection()
                    store.isOfflineMode = false
                    store.showSuccess("Online Mode", detail: "Private content can refresh again.", symbol: "wifi")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .buttonStyle(.plain)
            }
            .padding(12)
            .maxSurface(cornerRadius: 18, emphasized: true)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

struct MaxToastView: View {
    let toast: PrototypeToast

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: toast.symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.black)
                .frame(width: 34, height: 34)
                .background(.white, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title)
                    .font(.subheadline.weight(.semibold))
                Text(toast.detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(12)
        .maxControlSurface(cornerRadius: 21)
        .shadow(color: .black.opacity(0.5), radius: 18, y: 10)
    }
}

struct MaxSearchOverlay: View {
    @EnvironmentObject private var store: MaxPrototypeStore
    @Binding var isPresented: Bool
    var selectMedia: (String) -> Void

    @State private var query = ""
    @State private var isSearching = false

    private var results: [MaxMediaItem] {
        guard !query.isEmpty else { return store.media.prefix(4).map { $0 } }
        return store.media.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.owner.localizedCaseInsensitiveContains(query) ||
            $0.privacy.rawValue.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 18) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.white.opacity(0.6))
                        TextField("Search your private media", text: $query)
                            .textInputAutocapitalization(.never)
                            .foregroundStyle(.white)
                            .submitLabel(.search)
                        if !query.isEmpty {
                            Button {
                                query = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(14)
                    .maxControlSurface(cornerRadius: 18)
                    .padding(.horizontal, 20)

                    if isSearching {
                        MaxSearchSkeleton()
                            .padding(.horizontal, 20)
                    } else if results.isEmpty {
                        MaxEmptyState(
                            symbol: "magnifyingglass",
                            title: "No Results",
                            detail: "Nothing in your private library matches \"\(query)\".",
                            actionTitle: "Clear Search"
                        ) {
                            query = ""
                        }
                        .padding(.horizontal, 20)
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                Text(query.isEmpty ? "RECENT PRIVATE MEDIA" : "RESULTS")
                                    .font(.caption2.weight(.bold))
                                    .tracking(1.1)
                                    .foregroundStyle(.white.opacity(0.46))
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                ForEach(results) { item in
                                    MaxSearchResult(item: item) {
                                        isPresented = false
                                        selectMedia(item.id)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                        }
                    }
                }
                .padding(.top, 10)
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: query) { _, newValue in
            guard !newValue.isEmpty else {
                isSearching = false
                return
            }
            isSearching = true
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 320_000_000)
                guard query == newValue else { return }
                isSearching = false
            }
        }
    }
}

private struct MaxSearchResult: View {
    let item: MaxMediaItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                MaxMediaArtwork(item: item, height: 66)
                    .frame(width: 102)

                VStack(alignment: .leading, spacing: 5) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(item.metadataLine)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                    Label(item.privacy.rawValue, systemImage: item.privacy.icon)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.46))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.36))
            }
            .padding(9)
            .maxSurface(cornerRadius: 19)
        }
        .buttonStyle(.plain)
    }
}

private struct MaxSearchSkeleton: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<4, id: \.self) { _ in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.white.opacity(0.1))
                        .frame(width: 102, height: 66)
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(.white.opacity(0.12))
                            .frame(width: 126, height: 12)
                        RoundedRectangle(cornerRadius: 5)
                            .fill(.white.opacity(0.08))
                            .frame(width: 172, height: 9)
                    }
                    Spacer()
                }
                .padding(9)
                .maxSurface(cornerRadius: 19)
            }
        }
        .redacted(reason: .placeholder)
    }
}

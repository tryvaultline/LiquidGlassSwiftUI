import SwiftUI

@MainActor
final class PlaybackModel: ObservableObject {
    static let demoVideoURL = URL(string: "https://max.local/private-media-preview")!

    @Published var isPlaying = false
    @Published var isMuted = false
    @Published var progress = 0.18
    @Published var speed = 1.0

    func togglePlayPause() {
        isPlaying.toggle()
    }

    func seek(by seconds: Double) {
        let duration = 1_122.0
        progress = min(1, max(0, progress + seconds / duration))
    }

    func pause() {
        isPlaying = false
    }

    func tick() {
        guard isPlaying else { return }
        progress = min(1, progress + (speed / 1_122) * 0.35)
        if progress >= 1 {
            isPlaying = false
        }
    }

    func reset() {
        isPlaying = false
        progress = 0
    }
}

struct VideoPlayerCard: View {
    @ObservedObject var playback: PlaybackModel

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.16), .white.opacity(0.05), .black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 46, weight: .semibold))
                .foregroundStyle(.white.opacity(0.84))

            VStack {
                HStack {
                    Label("PRIVATE PREVIEW", systemImage: "lock.fill")
                        .font(.caption2.weight(.bold))
                        .tracking(0.9)
                        .foregroundStyle(.white.opacity(0.88))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.black.opacity(0.68), in: Capsule())
                    Spacer()
                }
                Spacer()
                ProgressView(value: playback.progress)
                    .tint(.white)
                    .padding(14)
            }
        }
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
        }
        .accessibilityLabel("Private media preview")
    }
}

struct MaxPlayerScreen: View {
    @EnvironmentObject private var store: MaxPrototypeStore

    let mediaID: String
    let dismiss: () -> Void

    @StateObject private var playback = PlaybackModel()
    @State private var controlsVisible = true
    @State private var captionsEnabled = false
    @State private var showSpeedPicker = false
    @State private var showRatingPicker = false
    @State private var isBuffering = false
    @State private var hasFailed = false
    @State private var cinemaMode = false

    private var item: MaxMediaItem? {
        store.mediaItem(id: mediaID)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let item {
                if item.isLocked {
                    lockedContent(item)
                } else if store.isOfflineMode && item.downloadState != .completed {
                    offlineContent(item)
                } else {
                    playerContent(item)
                }
            } else {
                missingContent
            }
        }
        .preferredColorScheme(.dark)
        .task(id: playback.isPlaying) {
            while playback.isPlaying && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 350_000_000)
                playback.tick()
            }
        }
        .sheet(isPresented: $showRatingPicker) {
            MaxRatingSheet(currentRating: item?.rating) { value in
                store.setRating(value, for: mediaID)
                showRatingPicker = false
            }
            .presentationDetents([.medium])
        }
        .confirmationDialog("Playback options", isPresented: $showSpeedPicker, titleVisibility: .visible) {
            ForEach([0.5, 1.0, 1.25, 1.5, 2.0], id: \.self) { speed in
                Button("\(speed.formatted(.number.precision(.fractionLength(0...2))))×") {
                    HapticFeedback.selection()
                    playback.speed = speed
                    store.showSuccess("Playback speed", detail: "\(speed.formatted(.number.precision(.fractionLength(0...2))))× selected", symbol: "speedometer")
                }
            }
        }
    }

    @ViewBuilder
    private func playerContent(_ item: MaxMediaItem) -> some View {
        VStack(spacing: 0) {
            if !cinemaMode {
                playerHeader(item)
            }

            Spacer(minLength: cinemaMode ? 0 : 18)

            ZStack {
                playerCanvas(item)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            controlsVisible.toggle()
                        }
                    }

                if controlsVisible && !hasFailed {
                    playerControls(item)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }

                if isBuffering {
                    bufferingOverlay
                }

                if hasFailed {
                    failedOverlay(item)
                }
            }
            .padding(.horizontal, cinemaMode ? 0 : 16)
            .animation(.easeInOut(duration: 0.22), value: controlsVisible)

            if !cinemaMode {
                details(item)
                    .padding(.top, 18)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
            }

            Spacer(minLength: cinemaMode ? 0 : 6)
        }
        .padding(.top, cinemaMode ? 0 : 6)
        .animation(.spring(response: 0.34, dampingFraction: 0.9), value: cinemaMode)
    }

    private func playerHeader(_ item: MaxMediaItem) -> some View {
        HStack(spacing: 12) {
            Button {
                playback.pause()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .actionIcon(font: .body.weight(.bold))
            }
            .buttonStyle(.plain)
            .glassCircleButton(diameter: 42)
            .accessibilityLabel("Close player")

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Label("\(item.owner) · \(item.privacy.rawValue)", systemImage: item.privacy.icon)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.54))
            }

            Spacer()

            Menu {
                Button("Show Buffering") {
                    playback.pause()
                    isBuffering = true
                    hasFailed = false
                }
                Button("Show Failed Loading") {
                    playback.pause()
                    hasFailed = true
                    isBuffering = false
                }
                Button("Reset Player") {
                    playback.reset()
                    hasFailed = false
                    isBuffering = false
                }
            } label: {
                Image(systemName: "ellipsis")
                    .actionIcon(font: .body.weight(.bold))
            }
            .glassCircleButton(diameter: 42)
            .accessibilityLabel("Player state options")
        }
        .padding(.horizontal, 20)
    }

    private func playerCanvas(_ item: MaxMediaItem) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cinemaMode ? 0 : 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.14), .white.opacity(0.04), .black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(.white.opacity(0.07))
                .frame(width: 210, height: 210)
                .blur(radius: 2)
                .offset(x: 55, y: -32)

            Image(systemName: item.icon)
                .font(.system(size: 58, weight: .semibold))
                .foregroundStyle(.white.opacity(0.84))

            if captionsEnabled {
                Text("Private captions prototype")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.76), in: Capsule())
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 54)
            }
        }
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cinemaMode ? 0 : 28, style: .continuous))
        .overlay {
            if !cinemaMode {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
            }
        }
    }

    private func playerControls(_ item: MaxMediaItem) -> some View {
        VStack(spacing: 14) {
            HStack {
                Label(item.privacy.rawValue.uppercased(), systemImage: item.privacy.icon)
                    .font(.caption2.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.88))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.black.opacity(0.65), in: Capsule())
                Spacer()
                Text(item.duration)
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.78))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .background(.black.opacity(0.65), in: Capsule())
            }

            Spacer()

            HStack(spacing: 24) {
                controlButton("gobackward.10", label: "Rewind") {
                    HapticFeedback.tap()
                    playback.seek(by: -10)
                }

                controlButton(playback.isPlaying ? "pause.fill" : "play.fill", label: playback.isPlaying ? "Pause" : "Play", large: true) {
                    HapticFeedback.tap()
                    playback.togglePlayPause()
                    if playback.isPlaying {
                        store.markWatched(item.id)
                    }
                }

                controlButton("goforward.10", label: "Forward") {
                    HapticFeedback.tap()
                    playback.seek(by: 10)
                }
            }

            HStack(spacing: 10) {
                Button {
                    HapticFeedback.selection()
                    playback.isMuted.toggle()
                } label: {
                    Label(playback.isMuted ? "Unmute" : "Mute", systemImage: playback.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                }
                .buttonStyle(.plain)

                Button {
                    HapticFeedback.selection()
                    captionsEnabled.toggle()
                    store.showSuccess(captionsEnabled ? "Captions On" : "Captions Off", detail: "Prototype captions control", symbol: "captions.bubble.fill")
                } label: {
                    Label("CC", systemImage: captionsEnabled ? "captions.bubble.fill" : "captions.bubble")
                }
                .buttonStyle(.plain)

                Button {
                    showSpeedPicker = true
                } label: {
                    Text("\(playback.speed.formatted(.number.precision(.fractionLength(0...2))))×")
                        .monospacedDigit()
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    HapticFeedback.selection()
                    cinemaMode.toggle()
                } label: {
                    Image(systemName: cinemaMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.plain)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.black.opacity(0.7), in: Capsule())

            HStack(spacing: 8) {
                Text(timeString(for: playback.progress))
                Slider(value: $playback.progress, in: 0...1)
                    .tint(.white)
                    .onChange(of: playback.progress) { _, _ in
                        store.markWatched(item.id)
                    }
                Text(item.duration)
            }
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.white.opacity(0.82))
        }
        .padding(15)
    }

    private func details(_ item: MaxMediaItem) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text("\(item.kind.title) · \(item.owner) · \(item.dateLabel) · \(item.sizeLabel)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.53))
                }
                Spacer()
                if let rating = item.rating {
                    Text("\(rating)/10")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(.white, in: Capsule())
                }
            }

            Text(item.caption)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.62))

            HStack(spacing: 9) {
                PlayerAction(symbol: item.isSaved ? "bookmark.fill" : "bookmark", title: item.isSaved ? "Saved" : "Save", active: item.isSaved) {
                    store.toggleSaved(item.id)
                }
                PlayerAction(symbol: item.isLiked ? "heart.fill" : "heart", title: item.isLiked ? "Liked" : "Like", active: item.isLiked) {
                    store.toggleLiked(item.id)
                }
                ShareLink(item: PlaybackModel.demoVideoURL, subject: Text(item.title), message: Text("Private Max media preview")) {
                    VStack(spacing: 5) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.body.weight(.semibold))
                        Text("Share")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(.white.opacity(0.78))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .maxControlSurface(cornerRadius: 16)
                }
                .accessibilityLabel("Share media link")
                PlayerAction(symbol: item.downloadState == .completed ? "checkmark.circle.fill" : "arrow.down.circle", title: item.downloadState == .completed ? "Offline" : "Download", active: item.downloadState == .completed) {
                    store.toggleDownload(for: item.id)
                }
                PlayerAction(symbol: item.rating == nil ? "star" : "star.fill", title: item.rating.map { "\($0)/10" } ?? "Rate", active: item.rating != nil) {
                    showRatingPicker = true
                }
            }
        }
    }

    private func lockedContent(_ item: MaxMediaItem) -> some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "lock.fill")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 88, height: 88)
                .background(.white.opacity(0.1), in: Circle())
            Text(item.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text(item.requestAccessSent ? "Your access request is waiting with \(item.owner)." : "This private media is owned by \(item.owner). Request access to continue.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.58))
                .padding(.horizontal, 32)
            Button(item.requestAccessSent ? "Request Sent" : "Request Access") {
                store.requestAccess(for: item.id)
            }
            .font(.headline.weight(.semibold))
            .foregroundStyle(item.requestAccessSent ? .white.opacity(0.6) : .black)
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .background(item.requestAccessSent ? .white.opacity(0.1) : .white, in: Capsule())
            .buttonStyle(.plain)
            .disabled(item.requestAccessSent)
            Button("Back") { dismiss() }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
                .buttonStyle(.plain)
            Spacer()
        }
    }

    private func offlineContent(_ item: MaxMediaItem) -> some View {
        VStack(spacing: 17) {
            Spacer()
            Image(systemName: "wifi.slash")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.white)
            Text("Offline right now")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text("\(item.title) has not finished downloading. Turn off Offline Mode or complete its local download.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.58))
                .padding(.horizontal, 30)
            Button("Turn Off Offline Mode") {
                store.isOfflineMode = false
                store.showSuccess("Online Mode", detail: "You can stream private media again.", symbol: "wifi")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.white, in: Capsule())
            .buttonStyle(.plain)
            Button("Back") { dismiss() }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
                .buttonStyle(.plain)
            Spacer()
        }
    }

    private var missingContent: some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
            Text("Media unavailable")
                .font(.title3.weight(.bold))
            Button("Back") { dismiss() }
                .buttonStyle(.bordered)
        }
        .foregroundStyle(.white)
    }

    private var bufferingOverlay: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(.white)
                .controlSize(.large)
            Text("Buffering private media")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Button("Continue") {
                isBuffering = false
                playback.togglePlayPause()
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white, in: Capsule())
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func failedOverlay(_ item: MaxMediaItem) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.white)
            Text("Couldn’t load \(item.title)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Text("This is a visible prototype failure state.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
            Button("Retry") {
                hasFailed = false
                playback.reset()
                playback.togglePlayPause()
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white, in: Capsule())
            .buttonStyle(.plain)
        }
        .multilineTextAlignment(.center)
        .padding(20)
        .background(.black.opacity(0.84), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    @ViewBuilder
    private func controlButton(_ symbol: String, label: String, large: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(large ? .title2.weight(.bold) : .title3.weight(.semibold))
        }
        .buttonStyle(.plain)
        .glassCircleButton(diameter: large ? 66 : 48, isActive: large && playback.isPlaying)
        .accessibilityLabel(label)
    }

    private func timeString(for progress: Double) -> String {
        let totalSeconds = 1_122.0
        let seconds = Int(totalSeconds * progress)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private struct PlayerAction: View {
    let symbol: String
    let title: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button {
            HapticFeedback.selection()
            action()
        } label: {
            VStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.body.weight(.semibold))
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(active ? .black : .white.opacity(0.78))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(active ? .white : .clear, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .maxControlSurface(cornerRadius: 16)
    }
}

private struct MaxRatingSheet: View {
    let currentRating: Int?
    let choose: (Int) -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text("Rate this private media")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Text(currentRating.map { "Current rating: \($0) / 10" } ?? "Choose a rating from 1 to 10")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.57))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                ForEach(1...10, id: \.self) { value in
                    Button {
                        HapticFeedback.selection()
                        choose(value)
                    } label: {
                        Text("\(value)")
                            .glassRatingCell(isSelected: currentRating == value)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(24)
        .presentationBackground(.black)
    }
}

import SwiftUI

struct MediaControlsView: View {
    @ObservedObject var playback: PlaybackModel
    @Binding var isSaved: Bool
    @Binding var isLiked: Bool

    let rating: Int?
    @Binding var showRatingSheet: Bool

    @Namespace private var namespace

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            VStack(spacing: 15) {
                HStack(spacing: 16) {
                    iconButton(
                        id: "rewind",
                        symbol: "gobackward.10",
                        label: "Rewind ten seconds"
                    ) {
                        HapticFeedback.tap()
                        playback.seek(by: -10)
                    }

                    iconButton(
                        id: "playback",
                        symbol: playback.isPlaying ? "pause.fill" : "play.fill",
                        label: playback.isPlaying ? "Pause video" : "Play video",
                        diameter: 68,
                        isActive: playback.isPlaying
                    ) {
                        HapticFeedback.tap()
                        playback.togglePlayPause()
                    }

                    iconButton(
                        id: "forward",
                        symbol: "goforward.10",
                        label: "Forward ten seconds"
                    ) {
                        HapticFeedback.tap()
                        playback.seek(by: 10)
                    }

                    iconButton(
                        id: "mute",
                        symbol: playback.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                        label: playback.isMuted ? "Unmute video" : "Mute video",
                        isActive: playback.isMuted
                    ) {
                        HapticFeedback.tap()
                        playback.isMuted.toggle()
                    }
                }

                Divider()
                    .overlay(.white.opacity(0.12))

                HStack(spacing: 12) {
                    iconButton(
                        id: "save",
                        symbol: isSaved ? "bookmark.fill" : "bookmark",
                        label: isSaved ? "Remove saved video" : "Save video",
                        diameter: 50,
                        isActive: isSaved
                    ) {
                        HapticFeedback.selection()
                        isSaved.toggle()
                    }

                    iconButton(
                        id: "like",
                        symbol: isLiked ? "heart.fill" : "heart",
                        label: isLiked ? "Unlike video" : "Like video",
                        diameter: 50,
                        isActive: isLiked
                    ) {
                        HapticFeedback.selection()
                        isLiked.toggle()
                    }

                    ShareLink(
                        item: PlaybackModel.demoVideoURL,
                        subject: Text("Max demo video"),
                        message: Text("A Max Liquid Glass prototype preview.")
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .actionIcon(font: .title3)
                    }
                    .buttonStyle(.plain)
                    .glassCircleButton(diameter: 50)
                    .glassEffectID("share", in: namespace)
                    .accessibilityLabel("Share video")

                    Button {
                        HapticFeedback.selection()
                        showRatingSheet = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: rating == nil ? "star" : "star.fill")
                                .actionIcon(font: .title3)

                            if let rating {
                                Text("\(rating)")
                                    .font(.caption2.weight(.bold).monospacedDigit())
                                    .foregroundStyle(.black)
                                    .padding(3)
                                    .background(.white, in: Circle())
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .glassCircleButton(diameter: 50, isActive: rating != nil)
                    .glassEffectID("rate", in: namespace)
                    .accessibilityLabel(rating.map { "Change rating, \($0) out of ten" } ?? "Rate video")
                }
            }
        }
        .padding(14)
        .denseGlassPanel(cornerRadius: 28)
    }

    @ViewBuilder
    private func iconButton(
        id: String,
        symbol: String,
        label: String,
        diameter: CGFloat = 56,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .actionIcon(font: diameter >= 64 ? .title2 : .title3)
        }
        .buttonStyle(.plain)
        .glassCircleButton(diameter: diameter, isActive: isActive)
        .glassEffectID(id, in: namespace)
        .accessibilityLabel(label)
    }
}

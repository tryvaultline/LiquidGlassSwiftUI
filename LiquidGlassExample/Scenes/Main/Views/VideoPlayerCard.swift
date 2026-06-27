import AVFoundation
import AVKit
import SwiftUI

@MainActor
final class PlaybackModel: ObservableObject {
    static let demoVideoURL = URL(
        string: "https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4"
    )!

    let player: AVPlayer

    @Published private(set) var isPlaying = false
    @Published var isMuted = false {
        didSet {
            player.isMuted = isMuted
        }
    }

    init() {
        player = AVPlayer(url: Self.demoVideoURL)
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            player.play()
            isPlaying = true
        }
    }

    func seek(by seconds: Double) {
        let currentSeconds = player.currentTime().seconds
        let safeCurrentSeconds = currentSeconds.isFinite ? currentSeconds : 0
        let destination = max(0, safeCurrentSeconds + seconds)

        player.seek(
            to: CMTime(seconds: destination, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
    }

    func pause() {
        player.pause()
        isPlaying = false
    }
}

struct VideoPlayerCard: View {
    @ObservedObject var playback: PlaybackModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            VideoPlayer(player: playback.player)
                .allowsHitTesting(false)
                .aspectRatio(16 / 9, contentMode: .fit)
                .background(.black)

            HStack(spacing: 7) {
                Circle()
                    .fill(.white)
                    .frame(width: 6, height: 6)

                Text("MAX ORIGINAL PREVIEW")
                    .font(.caption2.weight(.bold))
                    .tracking(1.1)
            }
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(.black.opacity(0.72), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(.white.opacity(0.16), lineWidth: 1)
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.72), radius: 24, y: 14)
        .accessibilityLabel("Max demo video player")
    }
}

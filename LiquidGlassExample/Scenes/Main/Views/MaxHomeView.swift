import SwiftUI

struct MaxHomeView: View {
    let seedMessage: String

    @StateObject private var playback = PlaybackModel()
    @State private var isSaved = false
    @State private var isLiked = false
    @State private var isRatingPresented = false
    @State private var rating: Int?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                header

                VideoPlayerCard(playback: playback)

                TypingStatusView(seedMessage: seedMessage)

                MediaControlsView(
                    playback: playback,
                    isSaved: $isSaved,
                    isLiked: $isLiked,
                    rating: rating,
                    showRatingSheet: $isRatingPresented
                )

                shelf(
                    title: "Continue watching",
                    subtitle: "Picked up from your last session",
                    items: [
                        ("Afterlight", "S1 · E4", "moon.stars.fill"),
                        ("The Driver", "42 min left", "car.fill"),
                        ("Low Signal", "S2 · E1", "antenna.radiowaves.left.and.right")
                    ]
                )

                shelf(
                    title: "For tonight",
                    subtitle: "A quieter selection",
                    items: [
                        ("Paper Cities", "Film", "building.2.fill"),
                        ("Orbit", "Series", "sparkles"),
                        ("Northbound", "Documentary", "mountain.2.fill")
                    ]
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 116)
        }
        .sheet(isPresented: $isRatingPresented) {
            RatingSheet(rating: $rating)
        }
        .onDisappear {
            playback.pause()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("MAX")
                    .font(.title2.weight(.black))
                    .tracking(4)

                Text("A private media room")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.56))
            }

            Spacer()

            Button {
                HapticFeedback.tap()
            } label: {
                Image(systemName: "magnifyingglass")
                    .actionIcon(font: .body)
            }
            .buttonStyle(.plain)
            .glassCircleButton(diameter: 42)
            .accessibilityLabel("Search")

            Circle()
                .fill(.white.opacity(0.9))
                .frame(width: 42, height: 42)
                .overlay {
                    Text("R")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.black)
                }
                .overlay {
                    Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1)
                }
        }
    }

    private func shelf(
        title: String,
        subtitle: String,
        items: [(String, String, String)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.56))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(items, id: \.0) { item in
                        Button {
                            HapticFeedback.tap()
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(.white.opacity(0.08))
                                    .frame(width: 172, height: 104)
                                    .overlay {
                                        Image(systemName: item.2)
                                            .font(.title2.weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.76))
                                    }
                                    .overlay(alignment: .bottom) {
                                        Capsule()
                                            .fill(.white.opacity(0.8))
                                            .frame(width: 72, height: 3)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(10)
                                    }

                                Text(item.0)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)

                                Text(item.1)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.52))
                            }
                            .frame(width: 172, alignment: .leading)
                            .padding(10)
                            .denseGlassPanel(cornerRadius: 23)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

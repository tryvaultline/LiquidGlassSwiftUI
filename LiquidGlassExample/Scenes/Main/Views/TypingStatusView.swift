import SwiftUI

struct TypingStatusView: View {
    let seedMessage: String

    @State private var displayedText = ""
    @State private var messageIndex = 0
    @State private var isCursorVisible = true

    private var messages: [String] {
        [
            seedMessage,
            "Private media moves with you.",
            "Rate every title from one to ten.",
            "Your library stays personal."
        ]
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white.opacity(0.74))

            Text(displayedText + (isCursorVisible ? "▍" : " "))
                .font(.subheadline.monospaced())
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .maxSurface(cornerRadius: 20)
        .task {
            await runTypingLoop()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.52).repeatForever(autoreverses: true)) {
                isCursorVisible.toggle()
            }
        }
        .accessibilityLabel(displayedText)
    }

    @MainActor
    private func runTypingLoop() async {
        while !Task.isCancelled {
            let message = messages[messageIndex]
            HapticFeedback.typing()

            for character in message {
                guard !Task.isCancelled else { return }
                displayedText.append(character)
                try? await Task.sleep(nanoseconds: 55_000_000)
            }

            HapticFeedback.typing()
            try? await Task.sleep(nanoseconds: 1_250_000_000)

            HapticFeedback.erase()
            while !displayedText.isEmpty {
                guard !Task.isCancelled else { return }
                displayedText.removeLast()
                try? await Task.sleep(nanoseconds: 34_000_000)
            }
            HapticFeedback.erase()

            messageIndex = (messageIndex + 1) % messages.count
            try? await Task.sleep(nanoseconds: 340_000_000)
        }
    }
}

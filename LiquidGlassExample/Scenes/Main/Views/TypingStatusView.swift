import SwiftUI

struct TypingStatusView: View {
    let seedMessage: String

    @State private var displayedText = ""
    @State private var messageIndex = 0
    @State private var isCursorVisible = true

    private var messages: [String] {
        [
            seedMessage,
            "Writing. Erasing. Repeating.",
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
        .denseGlassPanel(cornerRadius: 20)
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

            for (index, character) in message.enumerated() {
                guard !Task.isCancelled else { return }

                displayedText.append(character)

                if character != " ", index.isMultiple(of: 2) {
                    HapticFeedback.typing()
                }

                try? await Task.sleep(nanoseconds: 55_000_000)
            }

            try? await Task.sleep(nanoseconds: 1_250_000_000)

            while !displayedText.isEmpty {
                guard !Task.isCancelled else { return }

                displayedText.removeLast()

                if displayedText.count.isMultiple(of: 2) {
                    HapticFeedback.erase()
                }

                try? await Task.sleep(nanoseconds: 34_000_000)
            }

            messageIndex = (messageIndex + 1) % messages.count
            try? await Task.sleep(nanoseconds: 340_000_000)
        }
    }
}

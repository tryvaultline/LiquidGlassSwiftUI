import SwiftUI

struct BackgroundView: View {
    var body: some View {
        ZStack {
            Color.black

            RadialGradient(
                colors: [
                    .white.opacity(0.06),
                    .clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 560
            )

            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.82)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

#Preview {
    BackgroundView()
}

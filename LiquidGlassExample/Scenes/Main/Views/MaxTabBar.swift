import SwiftUI

struct MaxTabBar: View {
    @Binding var selection: MaxTab

    var body: some View {
        GlassEffectContainer(spacing: 7) {
            HStack(spacing: 6) {
                ForEach(MaxTab.allCases) { tab in
                    Button {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                            selection = tab
                        }
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: tab.icon)
                                .font(tab == .create ? .title3.weight(.bold) : .body.weight(.semibold))
                                .contentTransition(.symbolEffect(.replace))

                            Text(tab.title)
                                .font(.caption2.weight(.semibold))
                        }
                        .foregroundStyle(selection == tab ? .black : .white.opacity(0.73))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, tab == .create ? 8 : 10)
                        .background(selection == tab ? .white : .black.opacity(0.56), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.title)
                }
            }
        }
        .padding(6)
        .maxControlSurface(cornerRadius: 24)
    }
}

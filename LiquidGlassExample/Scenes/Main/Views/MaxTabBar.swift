import SwiftUI

struct MaxTabBar: View {
    @Binding var selection: MainView.AppSection

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(MainView.AppSection.allCases) { section in
                    Button {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            selection = section
                        }
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: section.icon)
                                .font(.body.weight(.semibold))
                                .contentTransition(.symbolEffect(.replace))

                            Text(section.title)
                                .font(.caption2.weight(.semibold))
                        }
                        .foregroundStyle(selection == section ? .black : .white.opacity(0.74))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selection == section ? .white : .black.opacity(0.64))
                        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(section.title)
                }
            }
        }
        .padding(7)
        .denseGlassPanel(cornerRadius: 24)
    }
}

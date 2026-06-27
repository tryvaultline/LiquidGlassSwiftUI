import SwiftUI

extension View {
    func glassCircleButton(
        diameter: CGFloat = 56,
        tint: Color = .white,
        isActive: Bool = false
    ) -> some View {
        self
            .foregroundStyle(tint)
            .frame(width: diameter, height: diameter)
            .background(isActive ? .white.opacity(0.18) : .black.opacity(0.76))
            .glassEffect(.clear.interactive())
            .clipShape(Circle())
            .overlay {
                Circle()
                    .strokeBorder(.white.opacity(isActive ? 0.36 : 0.14), lineWidth: 1)
            }
            .contentShape(Circle())
    }

    func denseGlassPanel(cornerRadius: CGFloat = 26) -> some View {
        self
            .background(.black.opacity(0.78))
            .glassEffect(.clear.interactive())
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.14), lineWidth: 1)
            }
    }

    func glassRatingCell(isSelected: Bool) -> some View {
        self
            .font(.headline.monospacedDigit())
            .foregroundStyle(isSelected ? .black : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(isSelected ? .white : .black.opacity(0.76))
            .glassEffect(.clear.interactive())
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(.white.opacity(isSelected ? 0.42 : 0.14), lineWidth: 1)
            }
    }

    func actionIcon(font: Font = .title3) -> some View {
        self
            .font(font)
            .contentTransition(.symbolEffect(.replace))
    }
}

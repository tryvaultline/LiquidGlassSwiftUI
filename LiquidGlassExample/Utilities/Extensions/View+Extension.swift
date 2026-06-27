import SwiftUI

/// Local compatibility primitives used by the prototype while the build runner ships the iOS 18 SDK.
/// They intentionally preserve the visual hierarchy without relying on iOS 26-only Liquid Glass APIs.
struct MaxFallbackGlassEffect {
    static let clear = MaxFallbackGlassEffect()

    func interactive() -> MaxFallbackGlassEffect {
        self
    }
}

struct GlassEffectContainer<Content: View>: View {
    let spacing: CGFloat
    private let content: () -> Content

    init(spacing: CGFloat = 0, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        content()
    }
}

extension View {
    func glassEffect(_ effect: MaxFallbackGlassEffect) -> some View {
        self
            .background(.ultraThinMaterial)
            .overlay {
                Rectangle()
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }
    }

    func glassEffect<S: Shape>(_ effect: MaxFallbackGlassEffect, in shape: S) -> some View {
        self
            .background(.ultraThinMaterial, in: shape)
            .overlay {
                shape.stroke(.white.opacity(0.13), lineWidth: 1)
            }
    }

    func glassEffectID<ID: Hashable>(_ id: ID, in namespace: Namespace.ID) -> some View {
        self
    }

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

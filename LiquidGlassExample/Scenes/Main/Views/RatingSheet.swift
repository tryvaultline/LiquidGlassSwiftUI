import SwiftUI

struct RatingSheet: View {
    @Binding var rating: Int?

    @Environment(\.dismiss) private var dismiss
    @State private var selection: Int?

    init(rating: Binding<Int?>) {
        _rating = rating
        _selection = State(initialValue: rating.wrappedValue)
    }

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 10),
        count: 5
    )

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(.white.opacity(0.2))
                .frame(width: 38, height: 5)
                .padding(.top, 8)

            VStack(spacing: 8) {
                Text("Rate this title")
                    .font(.title3.weight(.bold))

                Text(selection.map { "Your score: \($0) / 10" } ?? "Choose a score from 1 to 10")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.58))
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(1...10, id: \.self) { value in
                    Button {
                        HapticFeedback.selection()
                        selection = value
                    } label: {
                        Text("\(value)")
                    }
                    .buttonStyle(.plain)
                    .glassRatingCell(isSelected: selection == value)
                    .accessibilityLabel("Rate \(value) out of ten")
                }
            }

            Button {
                guard let selection else { return }

                rating = selection
                HapticFeedback.success()
                dismiss()
            } label: {
                Text(selection == nil ? "Choose a rating" : "Save \(selection) / 10")
                    .font(.headline)
                    .foregroundStyle(selection == nil ? .white.opacity(0.36) : .black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(selection == nil ? .black.opacity(0.7) : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(.white.opacity(0.16), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .disabled(selection == nil)

            Button("Not now") {
                dismiss()
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white.opacity(0.58))
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.black)
        .preferredColorScheme(.dark)
    }
}

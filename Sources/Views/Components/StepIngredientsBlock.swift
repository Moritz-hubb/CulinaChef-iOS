import SwiftUI

/// Compact ingredient list for a single cooking step (same layout as the recipe overview).
/// Long lists scroll inside a fixed height instead of expanding the whole step.
struct StepIngredientsBlock: View {
    let items: [StepIngredientDisplay]

    private let maxVisibleRows = 4
    private let rowHeight: CGFloat = 34

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(L.recipe_zutaten_für_diesen_schritt.localized)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))

                if items.count > maxVisibleRows {
                    ScrollView {
                        ingredientRows
                    }
                    .frame(height: CGFloat(maxVisibleRows) * rowHeight)
                    .scrollIndicators(.visible)
                } else {
                    ingredientRows
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        }
    }

    private var ingredientRows: some View {
        VStack(spacing: 0) {
            ForEach(items) { item in
                HStack {
                    Text(item.name)
                        .font(.body)
                        .foregroundStyle(.white)
                    Spacer()
                    if let qty = item.quantity, !qty.isEmpty {
                        Text(qty)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(.vertical, 4)
                .frame(minHeight: rowHeight - 8, alignment: .center)
                .overlay(Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1), alignment: .bottom)
            }
        }
    }
}

import SwiftUI

struct RecipeRowView: View {
    let meal: MealSummary
    let isFavourite: Bool
    let onToggleFavourite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AsyncMealImage(
                url: meal.thumbnailURL,
                accessibilityLabel: "Thumbnail for \(meal.name)"
            )
            .frame(width: AppTheme.rowImageSize, height: AppTheme.rowImageSize)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))

            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                if let category = meal.category {
                    Text(category)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            FavouriteButton(isFavourite: isFavourite, action: onToggleFavourite)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

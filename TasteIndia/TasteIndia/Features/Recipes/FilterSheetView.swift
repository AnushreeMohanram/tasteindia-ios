import SwiftUI

struct FilterSheetView: View {
    @Binding var filters: FilterCriteria
    let categories: [String]
    let onApply: () -> Void
    let onClearAll: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Sort") {
                    Picker("Sort order", selection: $filters.sortOrder) {
                        ForEach(SortOrder.allCases) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    .accessibilityLabel("Sort order")
                }

                Section("Category") {
                    Picker("Category", selection: $filters.category) {
                        Text("Any").tag(String?.none)
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(Optional(category))
                        }
                    }
                    .accessibilityLabel("Category filter")
                }

                Section("Main ingredient") {
                    Picker("Ingredient", selection: $filters.ingredient) {
                        Text("Any").tag(String?.none)
                        ForEach(IngredientOptions.common, id: \.self) { ingredient in
                            Text(ingredient).tag(Optional(ingredient))
                        }
                    }
                    .accessibilityLabel("Main ingredient filter")
                }

                Section("Favourites") {
                    Toggle("Show favourites only", isOn: $filters.favouritesOnly)
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear all") {
                        onClearAll()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                }
            }
        }
    }
}

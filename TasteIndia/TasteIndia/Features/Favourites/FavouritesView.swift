import SwiftUI

struct FavouritesView: View {
    @Environment(FavouritesViewModel.self) private var viewModel
    @Environment(RecipesViewModel.self) private var recipesViewModel
    @Environment(FavouritesStore.self) private var favouritesStore
    @Environment(\.mealRepository) private var mealRepository

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 0) {
            switch viewModel.loadState {
            case .idle, .loading:
                ProgressView("Loading favourites…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .empty:
                EmptyStateView(
                    title: "No favourites yet",
                    message: "Save recipes from the list or detail screen to see them here."
                )
            case .failed(let message):
                EmptyStateView(
                    title: "Couldn’t load favourites",
                    message: message
                )
            case .loaded, .stale:
                favouritesList
            }
        }
        .navigationTitle("Favourites")
        .onChange(of: favouritesStore.favouriteIDs) { _, _ in
            viewModel.refresh(from: recipesViewModel.baseMeals)
        }
        .onChange(of: recipesViewModel.baseMeals) { _, newMeals in
            viewModel.refresh(from: newMeals)
        }
    }

    private var favouritesList: some View {
        @Bindable var viewModel = viewModel

        return ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.favouriteMeals) { meal in
                    NavigationLink(value: meal.id) {
                        RecipeRowView(
                            meal: meal,
                            isFavourite: viewModel.isFavourite(id: meal.id),
                            onToggleFavourite: {
                                viewModel.toggleFavourite(id: meal.id, baseMeals: recipesViewModel.baseMeals)
                            }
                        )
                        .padding(.horizontal)
                    }
                    .buttonStyle(.plain)
                    .id(meal.id)
                    Divider()
                        .padding(.leading, AppTheme.rowImageSize + 24)
                }
            }
            .padding(.vertical, 8)
        }
        .scrollPosition(id: $viewModel.scrollPositionID)
        .navigationDestination(for: String.self) { mealID in
            RecipeDetailView(
                mealID: mealID,
                repository: mealRepository,
                favouritesStore: favouritesStore
            )
        }
    }
}

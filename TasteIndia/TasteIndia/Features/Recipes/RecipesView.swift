import SwiftUI

struct RecipesView: View {
    @Environment(RecipesViewModel.self) private var viewModel
    @Environment(FavouritesStore.self) private var favouritesStore
    @Environment(\.mealRepository) private var mealRepository

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 0) {
            content
        }
        .navigationTitle("TasteIndia")
        .searchable(
            text: Binding(
                get: { viewModel.filters.searchText },
                set: { viewModel.updateSearchText($0) }
            ),
            prompt: "Search Indian recipes"
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showFilters = true
                } label: {
                    Label("Filters", systemImage: viewModel.filters.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
                .accessibilityLabel("Show filters")
            }
        }
        .sheet(isPresented: $viewModel.showFilters) {
            FilterSheetView(
                filters: $viewModel.filters,
                categories: viewModel.categoryOptions,
                onApply: { viewModel.applyFiltersImmediately() },
                onClearAll: { viewModel.clearAllFilters() }
            )
        }
    }

    @ViewBuilder
    private var content: some View {
        ActiveFiltersBar(
            labels: viewModel.filters.activeFilterLabels,
            resultCount: viewModel.displayedMeals.count,
            onClearAll: { viewModel.clearAllFilters() }
        )

        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView("Loading Indian recipes…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            VStack(spacing: 16) {
                EmptyStateView(
                    title: "Couldn’t load recipes",
                    message: message,
                    actionTitle: "Retry",
                    action: { Task { await viewModel.reloadIndianMeals() } }
                )
            }
        case .empty:
            EmptyStateView(
                title: "No matching recipes",
                message: "Try adjusting your search or filters.",
                actionTitle: viewModel.filters.hasActiveFilters ? "Clear all" : nil,
                action: viewModel.filters.hasActiveFilters ? { viewModel.clearAllFilters() } : nil
            )
        case .loaded, .stale:
            recipeList
        }

        if case .stale(_, let message) = viewModel.loadState, !message.isEmpty {
            StatusBanner(message: message, systemImage: "exclamationmark.triangle.fill", tint: .orange)
        }

        if viewModel.isApplyingRemoteFilters {
            ProgressView("Applying filters…")
                .padding(.bottom, 8)
        }
    }

    private var recipeList: some View {
        @Bindable var viewModel = viewModel

        return ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.displayedMeals) { meal in
                    NavigationLink(value: meal.id) {
                        RecipeRowView(
                            meal: meal,
                            isFavourite: viewModel.isFavourite(id: meal.id),
                            onToggleFavourite: { viewModel.toggleFavourite(id: meal.id) }
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
        .refreshable {
            await viewModel.reloadIndianMeals()
        }
        .onAppear {
            Task { await viewModel.refreshCachedEnrichment() }
        }
    }
}

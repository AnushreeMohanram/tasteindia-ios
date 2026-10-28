import SwiftUI

@main
struct TasteIndiaApp: App {
    @State private var dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            RootTabView(dependencies: dependencies)
                .environment(dependencies.recipesViewModel)
                .environment(dependencies.favouritesViewModel)
                .environment(dependencies.favouritesStore)
                .environment(\.mealRepository, dependencies.mealRepository)
        }
    }
}

struct RootTabView: View {
    let dependencies: AppDependencies
    @Environment(RecipesViewModel.self) private var recipesViewModel
    @Environment(FavouritesViewModel.self) private var favouritesViewModel

    var body: some View {
        TabView {
            NavigationStack {
                RecipesView()
            }
            .tabItem {
                Label("Recipes", systemImage: "list.bullet")
            }

            NavigationStack {
                FavouritesView()
            }
            .tabItem {
                Label("Favourites", systemImage: "heart.fill")
            }
        }
        .task {
            await recipesViewModel.bootstrapIfNeeded()
            await favouritesViewModel.bootstrapIfNeeded(from: recipesViewModel.baseMeals)
        }
    }
}

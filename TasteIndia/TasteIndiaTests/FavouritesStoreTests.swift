import XCTest
@testable import TasteIndia

@MainActor
final class FavouritesStoreTests: XCTestCase {
    func testPersistenceAcrossInstances() {
        let suiteName = "FavouritesStoreTestsPersistence"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let first = FavouritesStore(userDefaults: defaults)
        first.toggleFavourite(id: "52795")
        first.toggleFavourite(id: "52805")

        let second = FavouritesStore(userDefaults: defaults)
        XCTAssertTrue(second.isFavourite(id: "52795"))
        XCTAssertTrue(second.isFavourite(id: "52805"))
        XCTAssertFalse(second.isFavourite(id: "999"))
    }

    func testToggleRemovesFavourite() {
        let suiteName = "FavouritesStoreTestsToggle"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = FavouritesStore(userDefaults: defaults)
        XCTAssertTrue(store.toggleFavourite(id: "1"))
        XCTAssertFalse(store.toggleFavourite(id: "1"))
    }

    func testNavigationStatePropertiesPersistOnViewModel() {
        let repository = MockMealRepository()
        let store = FavouritesStore(userDefaults: UserDefaults(suiteName: "FavouritesStoreTestsNav")!)
        let viewModel = RecipesViewModel(repository: repository, favouritesStore: store)

        viewModel.filters.searchText = "Biryani"
        viewModel.filters.sortOrder = .nameDescending
        viewModel.scrollPositionID = "52805"

        XCTAssertEqual(viewModel.filters.searchText, "Biryani")
        XCTAssertEqual(viewModel.scrollPositionID, "52805")
        XCTAssertEqual(viewModel.filters.sortOrder, .nameDescending)
    }
}

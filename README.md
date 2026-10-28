# TasteIndia — iOS Intern Assignment

Native SwiftUI app for discovering Indian recipes powered by [TheMealDB](https://www.themealdb.com/api.php) public V1 API (test key `1`).

## Overview

TasteIndia lets you browse the Indian meal collection, search and filter recipes, inspect full recipe details, and save favourites that persist offline across relaunches.

### Implemented features

- Scrollable recipe list with thumbnails, names, and accessible favourite controls
- Loading, loaded, empty, stale-data, and recoverable error states with retry
- Search (debounced), category filter, main ingredient filter, favourites-only filter
- Name A–Z / Z–A sorting, active filter chips, result count, and Clear all
- Indian-boundary intersection for category and ingredient filters
- ID-based navigation to a detail screen showing normalized ingredients, instructions, tags, and validated links
- Separate Favourites tab with the same detail route
- Preserved search, filters, sort, and scroll position via app-scoped view models
- Detail response caching, request deduplication, and bounded concurrent detail fetches (max 3)
- Offline fixtures for tests and review

## Prerequisites

- macOS with **Xcode 16+** (Swift 5, iOS **17.0+** deployment target)
- Internet connection for the live TheMealDB request on first launch

## Open, build, and run

1. Clone or download this repository.
2. Open `TasteIndia/TasteIndia.xcodeproj` in Xcode.
3. Select the **TasteIndia** scheme and an iOS 17+ simulator (e.g. iPhone 16).
4. Press **⌘R** to build and run.

### Run tests

```bash
cd TasteIndia
xcodebuild -scheme TasteIndia -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Or in Xcode: **⌘U**.

## Architecture

```
TasteIndia/
├── App/                     # App entry, dependency container, environment keys
├── Domain/Models/           # MealSummary, MealDetail, FilterCriteria, LoadState
├── Data/
│   ├── DTOs/                # Codable TheMealDB responses
│   ├── Mappers/             # DTO → domain mapping & ingredient normalization
│   ├── Network/             # URLSession client, endpoints, HTTP validation
│   ├── Cache/               # Actor-based detail cache + concurrency gate
│   ├── Persistence/         # UserDefaults favourites store
│   └── Repository/          # MealRepository + filter intersection engine
├── Features/
│   ├── Recipes/             # List, filters, view model
│   ├── RecipeDetail/        # Detail screen + view model
│   └── Favourites/          # Saved recipes tab
├── UI/                      # Shared components and theme tokens
└── Resources/Fixtures/      # Checked-in TheMealDB JSON samples
```

### State ownership

| Concern | Owner |
|--------|--------|
| Indian base meals, filters, sort, scroll | `RecipesViewModel` (app-scoped) |
| Favourite IDs | `FavouritesStore` (UserDefaults) |
| Favourite list presentation | `FavouritesViewModel` (app-scoped) |
| Detail fetch state | `RecipeDetailViewModel` (per navigation destination) |
| Detail cache / deduplication | `MealDetailCache` actor inside repository |

## Navigation map

```
Tab: Recipes
  └─ RecipesView (list + search + filters)
       └─ RecipeDetailView(mealID)

Tab: Favourites
  └─ FavouritesView
       └─ RecipeDetailView(mealID)
```

Routes pass **`idMeal` strings only**, never full models.

## TheMealDB endpoints

| Purpose | URL |
|--------|-----|
| Indian meals (primary) | `https://www.themealdb.com/api/json/v1/1/filter.php?a=Indian` |
| Indian meals (fallback) | `https://www.themealdb.com/api/json/v1/1/filter.php?a=India` |
| Full details | `https://www.themealdb.com/api/json/v1/1/lookup.php?i={mealId}` |
| Categories | `https://www.themealdb.com/api/json/v1/1/list.php?c=list` |
| Category filter | `https://www.themealdb.com/api/json/v1/1/filter.php?c={category}` |
| Ingredient filter | `https://www.themealdb.com/api/json/v1/1/filter.php?i={ingredient}` |

**Attribution:** Recipe data and images © [TheMealDB](https://www.themealdb.com). Used under their educational/test key terms.

## Indian boundary & intersection strategy

1. Load the authoritative Indian set via the documented `a=Indian` endpoint.
2. If that returns `null` (observed API drift as of Oct 2025), fall back to `a=India` and document the behaviour.
3. Category and ingredient filters fetch their own ID sets from TheMealDB, then **intersect locally** with the Indian base IDs via `MealFilterEngine`.
4. Name search and favourites-only filtering run locally on the intersected set.
5. A monotonically increasing filter generation counter cancels stale async filter applications.

## Caching, concurrency, cancellation

- `MealDetailCache` actor stores decoded details and deduplicates in-flight lookups per meal ID.
- At most **3** concurrent detail network fetches; additional requests await a slot.
- `URLSession` requests use explicit timeouts (20s) and HTTP status validation.
- Filter/search tasks are cancelled and superseded when input changes rapidly.

## Favourites persistence

Favourite meal IDs are stored in `UserDefaults` under `tasteindia.favouriteMealIDs`. No network is required to read or toggle favourites.

## Fixtures

Representative JSON mirrors live API responses:

- `Resources/Fixtures/indian_meals.json`
- `Resources/Fixtures/meal_detail_52795.json`
- `Resources/Fixtures/filter_category_chicken.json`
- `Resources/Fixtures/filter_ingredient_chicken.json`
- `Resources/Fixtures/indian_meals_primary_empty.json`

Tests load copies from `TasteIndiaTests/Fixtures/`.

## Intentional omissions

- `idMeal` is not shown as primary UI content (used only for identity/routing).
- Empty ingredient/measure pairs, blank tags, invalid URLs, and null optional metadata are hidden.
- Raw JSON keys are never rendered.

## Assumptions & trade-offs

- Ingredient picker uses a curated common-ingredient list (`IngredientOptions`) because TheMealDB V1 has no ingredient list endpoint; each selection still intersects through the documented `filter.php?i=` API.
- List rows show category only when enriched from cached detail data (bounded enrichment is available through the repository cache path).
- SwiftUI `ScrollView.scrollPosition` preserves list scroll where supported (iOS 17+).
- Primary `a=Indian` endpoint fallback keeps the app functional despite API area naming drift.

## Known issues

- TheMealDB `filter.php?a=Indian` currently returns `null`; the app falls back to `a=India`.

## Time spent

Approximate focused time over **3 days** (within the assignment’s 8–12 hour guidance):

| Phase | Hours |
|-------|-------|
| Reading the brief, exploring TheMealDB endpoints, and confirming the `a=Indian` / `a=India` behaviour | 1.5 |
| Domain models, repository, networking, caching, and filter intersection logic | 3.0 |
| SwiftUI list/detail/favourites screens, navigation, and persistence | 3.0 |
| Unit tests, JSON fixtures, README, and final review | 2.0 |
| **Total** | **9.5** |

## Tool-use disclosure

I used an AI coding assistant (**Cursor**) while working on this assignment, mainly for:

- bootstrapping the initial Xcode project structure and folder layout
- drafting repository/view-model patterns and repetitive SwiftUI boilerplate
- suggesting XCTest cases and README sections to cross-check against the brief
- looking up TheMealDB response shapes and Swift concurrency patterns

I also relied on **Apple’s SwiftUI/URLSession documentation** and the **official TheMealDB API docs** for endpoint behaviour and attribution.

All submitted code was **reviewed, edited, and tested by me**. I made the final calls on architecture (Indian ID intersection, detail-cache concurrency cap, UserDefaults favourites, app-scoped state for list restoration), verified API responses manually, and can explain or modify any file in the project. AI output was treated as a starting point, not an unreviewed final submission.

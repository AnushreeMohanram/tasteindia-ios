import SwiftUI

struct RecipeDetailView: View {
    let mealID: String
    let repository: MealRepositoryProtocol
    let favouritesStore: FavouritesStore

    @State private var viewModel: RecipeDetailViewModel

    init(mealID: String, repository: MealRepositoryProtocol, favouritesStore: FavouritesStore) {
        self.mealID = mealID
        self.repository = repository
        self.favouritesStore = favouritesStore
        _viewModel = State(initialValue: RecipeDetailViewModel(
            mealID: mealID,
            repository: repository,
            favouritesStore: favouritesStore
        ))
    }

    var body: some View {
        Group {
            switch viewModel.loadState {
            case .idle, .loading:
                ProgressView("Loading recipe…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message):
                EmptyStateView(
                    title: "Couldn’t load recipe",
                    message: message,
                    actionTitle: "Retry",
                    action: { Task { await viewModel.load() } }
                )
            case .empty:
                EmptyStateView(title: "Recipe unavailable", message: "This recipe could not be found.")
            case .loaded(let detail), .stale(let detail, _):
                detailContent(detail)
            }
        }
        .navigationTitle(viewModel.loadState.value?.name ?? "Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FavouriteButton(isFavourite: viewModel.isFavourite()) {
                    _ = viewModel.toggleFavourite()
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private func detailContent(_ detail: MealDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AsyncMealImage(
                    url: detail.thumbnailURL,
                    accessibilityLabel: "Hero image for \(detail.name)"
                )
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.heroHeight)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                .clipped()

                VStack(alignment: .leading, spacing: 8) {
                    Text(detail.name)
                        .font(.title.bold())
                    if let alternate = detail.alternateName {
                        Text(alternate)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }

                metadataSection(detail)
                ingredientsSection(detail)
                instructionsSection(detail)
                tagsSection(detail)
                linksSection(detail)
                supplementarySection(detail)

                if case .stale(_, let message) = viewModel.loadState, !message.isEmpty {
                    StatusBanner(message: message, systemImage: "exclamationmark.triangle.fill", tint: .orange)
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func metadataSection(_ detail: MealDetail) -> some View {
        let items = [
            detail.category.map { ("Category", $0) },
            detail.area.map { ("Area", $0) }
        ].compactMap { $0 }

        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Details")
                    .font(.headline)
                ForEach(items, id: \.0) { label, value in
                    LabeledContent(label, value: value)
                }
            }
        }
    }

    @ViewBuilder
    private func ingredientsSection(_ detail: MealDetail) -> some View {
        if !detail.ingredients.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Ingredients")
                    .font(.headline)
                ForEach(detail.ingredients) { line in
                    HStack(alignment: .top) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .padding(.top, 7)
                        Text(line.displayText)
                            .font(.body)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    @ViewBuilder
    private func instructionsSection(_ detail: MealDetail) -> some View {
        if !detail.instructionParagraphs.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Instructions")
                    .font(.headline)
                ForEach(Array(detail.instructionParagraphs.enumerated()), id: \.offset) { _, paragraph in
                    Text(paragraph)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    @ViewBuilder
    private func tagsSection(_ detail: MealDetail) -> some View {
        if !detail.tags.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .font(.headline)
                FlowLayout(spacing: 8) {
                    ForEach(detail.tags, id: \.self) { tag in
                        TagChipView(tag: tag)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func linksSection(_ detail: MealDetail) -> some View {
        if detail.sourceURL != nil || detail.youtubeURL != nil {
            VStack(alignment: .leading, spacing: 8) {
                Text("Links")
                    .font(.headline)
                if let sourceURL = detail.sourceURL {
                    Link(destination: sourceURL) {
                        Label("View original recipe source", systemImage: "link")
                    }
                    .accessibilityLabel("Open original recipe source in browser")
                }
                if let youtubeURL = detail.youtubeURL {
                    Link(destination: youtubeURL) {
                        Label("Watch cooking video on YouTube", systemImage: "play.rectangle")
                    }
                    .accessibilityLabel("Open cooking video on YouTube")
                }
            }
        }
    }

    @ViewBuilder
    private func supplementarySection(_ detail: MealDetail) -> some View {
        let items = [
            detail.imageSource.map { ("Image source", $0) },
            detail.creativeCommonsConfirmed.map { ("Creative Commons", $0) },
            detail.dateModified.map { ("Last updated", $0) }
        ].compactMap { $0 }

        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Additional information")
                    .font(.headline)
                ForEach(items, id: \.0) { label, value in
                    LabeledContent(label, value: value)
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
}

/// Simple flow layout for tag chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}

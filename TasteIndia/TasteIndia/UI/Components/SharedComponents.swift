import SwiftUI

struct AsyncMealImage: View {
    let url: URL?
    var accessibilityLabel: String

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholder
                            .overlay { ProgressView() }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            }
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private var placeholder: some View {
        Rectangle()
            .fill(Color(.secondarySystemFill))
    }
}

struct FavouriteButton: View {
    let isFavourite: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavourite ? "heart.fill" : "heart")
                .foregroundStyle(isFavourite ? .red : .secondary)
                .symbolRenderingMode(.multicolor)
                .imageScale(.large)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFavourite ? "Remove from favourites" : "Add to favourites")
        .accessibilityAddTraits(isFavourite ? .isSelected : [])
    }
}

struct TagChipView: View {
    let tag: String

    var body: some View {
        Text(tag)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.15), in: Capsule())
            .accessibilityLabel("Tag: \(tag)")
    }
}

struct ActiveFiltersBar: View {
    let labels: [String]
    let resultCount: Int
    let onClearAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(resultCount) recipe\(resultCount == 1 ? "" : "s")")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if !labels.isEmpty {
                    Button("Clear all", action: onClearAll)
                        .font(.subheadline)
                }
            }

            if !labels.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(labels, id: \.self) { label in
                            Text(label)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.tertiarySystemFill), in: Capsule())
                                .accessibilityLabel("Active filter: \(label)")
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }
}

import ComposableArchitecture
import DesignSystem
import L10n
import SwiftUI

public struct ExerciseLibraryView: View {
    @Bindable var store: StoreOf<ExerciseLibrary>
    
    public init(store: StoreOf<ExerciseLibrary>) {
        self.store = store
    }
    
    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14, pinnedViews: []) {
                header
                SearchField(L10n.searchExercises, text: $store.searchText)
                filters
                ForEach(store.sections) { section in
                    Kicker(L10n.muscle(section.id), size: 11, spacing: 2)
                        .padding(.leading, 6)
                        .padding(.top, 4)
                    VStack(spacing: 0) {
                        ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, row in
                            if index > 0 {
                                Rectangle().fill(GymColor.border).frame(height: 1).padding(.leading, 98)
                            }
                            ExerciseRow(row: row) {
                                store.send(.exerciseTapped(id: row.id))
                            } onFavourite: {
                                store.send(.favouriteButtonTapped(id: row.id))
                            }
                        }
                    }
                    .background(GymColor.bgRaised, in: .rect(cornerRadius: 24))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .gymBackground()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $store.scope(state: \.editor, action: \.editor)) { editorStore in
            NavigationStack {
                ExerciseEditorView(store: editorStore)
            }
        }
    }
    
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                ScreenTitle(L10n.exercises, size: 28)
                Text(L10n.libraryCount(store.libraryCount))
                    .font(.gym(14, .medium))
                    .foregroundStyle(GymColor.textSecondary)
            }
            Spacer()
            RoundButton(.plus, label: L10n.newExercise.titleCased, size: 52) {
                store.send(.addButtonTapped)
            }
        }
        .padding(.top, 8)
    }
    
    private var filters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                Pill(L10n.filters) { store.send(.filtersButtonTapped) }
                Pill("\(L10n.favouritesOnly) · \(store.favouriteCount)", selected: store.favouritesOnly) {
                    store.favouritesOnly.toggle()
                }
                Pill(L10n.noGearOnly, selected: store.noKitOnly) {
                    store.noKitOnly.toggle()
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

/// Library row: art thumbnail, name, "Barbell · Intermediate" and a favourite star.
struct ExerciseRow: View {
    let row: ExerciseRowState
    let onTap: () -> Void
    let onFavourite: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onTap) {
                HStack(spacing: 16) {
                    ExerciseArtView(art: row.art)
                        .frame(width: 66, height: 66)
                        .background(GymColor.bgRaised2, in: .rect(cornerRadius: 16))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(row.name)
                            .font(.gym(16, .bold))
                            .foregroundStyle(GymColor.text)
                            .lineLimit(1)
                        Text(row.detail)
                            .font(.gym(13.5, .medium))
                            .foregroundStyle(GymColor.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.pressable(scale: 0.98))
            Button(action: onFavourite) {
                GymIcon(.star, weight: row.isFavourite ? .fill : .regular, size: 20)
                    .foregroundStyle(row.isFavourite ? GymColor.accent : GymColor.textSecondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(L10n.favouritesOnly)
            .accessibilityAddTraits(row.isFavourite ? .isSelected : [])
        }
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .padding(.vertical, 12)
    }
}

#Preview {
    ExerciseLibraryView(store: Store(initialState: ExerciseLibrary.State()) { ExerciseLibrary() })
}

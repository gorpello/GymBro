import ComposableArchitecture
import Database
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
                SearchField(L10n.searchExercises, text: $store.filter.search)
                filters
                if store.listing.sections.isEmpty {
                    emptyState
                }
                ForEach(store.listing.sections) { section in
                    Kicker(L10n.muscle(section.id.rawValue), size: 11, spacing: 2)
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
        .task { await store.send(.task).finish() }
        .sheet(item: $store.scope(state: \.editor, action: \.editor)) { editorStore in
            NavigationStack {
                ExerciseEditorView(store: editorStore)
            }
        }
        .sheet(isPresented: $store.showsFilters) {
            NavigationStack {
                ExerciseFiltersView(store: store)
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text(L10n.noExercisesFound)
                .font(.gym(17, .bold))
                .foregroundStyle(GymColor.text)
            Text(L10n.noExercisesHint)
                .font(.gym(13.5, .medium))
                .foregroundStyle(GymColor.textSecondary)
                .multilineTextAlignment(.center)
            Button(L10n.clearFilters) { store.send(.clearFiltersButtonTapped) }
                .buttonStyle(.ghost)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                ScreenTitle(L10n.exercises, size: 28)
                Text(L10n.libraryCount(store.listing.exerciseCount))
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
                let sheetCount = store.filter.sheetCount
                Pill(sheetCount > 0 ? "\(L10n.filters) · \(sheetCount)" : L10n.filters, selected: sheetCount > 0) {
                    store.send(.filtersButtonTapped)
                }
                Pill(
                    "\(L10n.favouritesOnly) · \(store.listing.favouriteCount)",
                    selected: store.filter.favouritesOnly
                ) {
                    store.filter.favouritesOnly.toggle()
                }
                Pill(L10n.noGearOnly, selected: store.filter.noKitOnly) {
                    store.filter.noKitOnly.toggle()
                }
                Pill(L10n.mineOnly, selected: store.filter.customOnly) {
                    store.filter.customOnly.toggle()
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
                        Text("\(L10n.equipment(row.equipment.rawValue)) · \(L10n.difficulty(row.difficulty.rawValue))")
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

/// Muscle, equipment and level, plus the archive.
struct ExerciseFiltersView: View {
    @Bindable var store: StoreOf<ExerciseLibrary>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                section(L10n.muscleFilter) {
                    FlowLayout {
                        ForEach(Muscle.all, id: \.self) { muscle in
                            Pill(L10n.muscle(muscle.rawValue), selected: store.filter.muscle == muscle) {
                                store.filter.muscle = store.filter.muscle == muscle ? nil : muscle
                            }
                        }
                    }
                }
                section(L10n.equipmentLabel) {
                    FlowLayout {
                        ForEach(Equipment.all, id: \.self) { equipment in
                            Pill(L10n.equipment(equipment.rawValue), selected: store.filter.equipment == equipment) {
                                store.filter.equipment = store.filter.equipment == equipment ? nil : equipment
                            }
                        }
                    }
                }
                section(L10n.levelFilter) {
                    FlowLayout {
                        ForEach(Difficulty.all, id: \.self) { difficulty in
                            Pill(
                                L10n.difficulty(difficulty.rawValue),
                                selected: store.filter.difficulty == difficulty
                            ) {
                                store.filter.difficulty = store.filter.difficulty == difficulty ? nil : difficulty
                            }
                        }
                    }
                }
                if store.listing.hasArchived || store.filter.archivedOnly {
                    Pill(L10n.archivedFilter, selected: store.filter.archivedOnly) {
                        store.filter.archivedOnly.toggle()
                    }
                }
            }
            .padding(20)
        }
        .gymScreen(L10n.filters)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.clearFilters) { store.send(.clearFiltersButtonTapped) }
                    .disabled(store.filter == ExerciseFilter())
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .confirm) { store.showsFilters = false }
            }
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Kicker(title, size: 11, spacing: 2)
            content()
        }
    }
}

#Preview {
    ExerciseLibraryView(store: previewStore())
}

/// A store backed by a database seeded with a month of training.
@MainActor
private func previewStore() -> StoreOf<ExerciseLibrary> {
    prepareDependencies {
        // swiftlint:disable:next force_try
        try! $0.bootstrapDatabase()
        // swiftlint:disable:next force_try
        try! $0.seedDatabaseForPreviews()
    }
    return Store(initialState: ExerciseLibrary.State()) { ExerciseLibrary() }
}
